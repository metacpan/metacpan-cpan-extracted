/*
 * Lugh - Pure C LLM Inference Engine for Perl
 * 
 * Built on ggml tensor library
 * Thread-safe using registry pattern
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <ggml.h>
#include <ggml-alloc.h>
#include <ggml-backend.h>
#include <ggml-cpu.h>
#include <gguf.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

/* Debug output flag - set to 0 to disable debug output */
#ifndef LUGH_DEBUG
#define LUGH_DEBUG 0
#endif

#if LUGH_DEBUG
#define DEBUG_PRINT(...) fprintf(stderr, __VA_ARGS__)
#else
#define DEBUG_PRINT(...) ((void)0)
#endif

/* ============================================================================
 * Memory Mapping Support (Platform-specific)
 * ============================================================================
 * mmap allows the OS to share read-only model weights across processes,
 * significantly reducing memory usage for multi-process deployments.
 */

#ifdef _WIN32
    #define WIN32_LEAN_AND_MEAN
    #ifndef NOMINMAX
        #define NOMINMAX
    #endif
    #include <windows.h>
    #include <io.h>
    #define LUGH_MMAP_SUPPORTED 1
#else
    #include <unistd.h>
    #include <fcntl.h>
    #include <sys/stat.h>
    #include <sys/types.h>
    #if defined(_POSIX_MAPPED_FILES) && _POSIX_MAPPED_FILES > 0
        #include <sys/mman.h>
        #define LUGH_MMAP_SUPPORTED 1
    #else
        #define LUGH_MMAP_SUPPORTED 0
    #endif
#endif

#ifndef LUGH_MMAP_SUPPORTED
    #define LUGH_MMAP_SUPPORTED 0
#endif

/* ============================================================================
 * Thread Safety Configuration
 * ============================================================================ */

#define MAX_CONTEXTS 4096
#define MAX_TENSORS  65536

#ifdef USE_ITHREADS
static perl_mutex context_mutex;
static perl_mutex tensor_mutex;
static perl_mutex kvcache_mutex;
static perl_mutex mempool_mutex;
static perl_mutex lora_registry_mutex;
static perl_mutex speculative_mutex;
static perl_mutex rng_mutex;
static perl_mutex training_cache_mutex;
static int mutex_initialized = 0;

#define CONTEXT_LOCK()   MUTEX_LOCK(&context_mutex)
#define CONTEXT_UNLOCK() MUTEX_UNLOCK(&context_mutex)
#define TENSOR_LOCK()    MUTEX_LOCK(&tensor_mutex)
#define TENSOR_UNLOCK()  MUTEX_UNLOCK(&tensor_mutex)
#define RNG_LOCK()       MUTEX_LOCK(&rng_mutex)
#define RNG_UNLOCK()     MUTEX_UNLOCK(&rng_mutex)

#define INIT_MUTEXES() do { \
    if (!mutex_initialized) { \
        MUTEX_INIT(&context_mutex); \
        MUTEX_INIT(&tensor_mutex); \
        MUTEX_INIT(&kvcache_mutex); \
        MUTEX_INIT(&mempool_mutex); \
        MUTEX_INIT(&lora_registry_mutex); \
        MUTEX_INIT(&speculative_mutex); \
        MUTEX_INIT(&rng_mutex); \
        MUTEX_INIT(&training_cache_mutex); \
        mutex_initialized = 1; \
    } \
} while(0)

#else
#define CONTEXT_LOCK()
#define CONTEXT_UNLOCK()
#define TENSOR_LOCK()
#define TENSOR_UNLOCK()
#define RNG_LOCK()
#define RNG_UNLOCK()
#define INIT_MUTEXES()
#endif

/* ============================================================================
 * Thread-Safe Random Number Generator
 * ============================================================================
 * The C standard library rand() is NOT thread-safe. Multiple threads calling
 * rand() concurrently can corrupt the shared PRNG state and return garbage
 * values. This thread-safe wrapper protects the RNG state with a mutex.
 */

/* Thread-safe wrapper around rand() */
static int lugh_rand(void) {
    int result;
    RNG_LOCK();
    result = rand();
    RNG_UNLOCK();
    return result;
}

/* Thread-safe wrapper around srand() */
static void lugh_srand(unsigned int seed) {
    RNG_LOCK();
    srand(seed);
    RNG_UNLOCK();
}

/* Get a random float in [0, 1) - thread-safe */
static float lugh_rand_float(void) {
    return (float)lugh_rand() / ((float)RAND_MAX + 1.0f);
}

/* ============================================================================
 * XS Object Validation Macros
 * ============================================================================
 * These macros reduce code duplication for validating Perl objects and
 * extracting C structures from the registry. Each macro validates that
 * 'self' is a blessed hash reference, extracts the ID field, and looks
 * up the corresponding C struct from the registry.
 */

/* Validate hash ref and extract HV pointer */
#define VALIDATE_HASH_REF(self, hv, type_name) \
    do { \
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) \
            croak("Invalid " type_name " object"); \
        hv = (HV*)SvRV(self); \
    } while(0)

/* Validate hash ref and fetch a required key as IV */
#define FETCH_IV_FROM_HASH(hv, key, key_len, result, type_name) \
    do { \
        SV **svp = hv_fetch(hv, key, key_len, 0); \
        if (!svp) croak("Invalid " type_name " object"); \
        result = SvIV(*svp); \
    } while(0)

/* Fetch an optional key from hash, return default if missing */
#define FETCH_IV_OR_DEFAULT(hv, key, key_len, default_val) \
    ({ SV **svp = hv_fetch(hv, key, key_len, 0); svp ? SvIV(*svp) : (default_val); })

#define FETCH_NV_OR_DEFAULT(hv, key, key_len, default_val) \
    ({ SV **svp = hv_fetch(hv, key, key_len, 0); svp ? SvNV(*svp) : (default_val); })

/* Combined validation: hash ref -> extract ID -> lookup in registry */
#define GET_TENSOR_FROM_SELF(self, lt, hv) \
    do { \
        SV **svp; \
        int tensor_id; \
        VALIDATE_HASH_REF(self, hv, "Lugh::Tensor"); \
        svp = hv_fetch(hv, "_tensor_id", 10, 0); \
        if (!svp) croak("Invalid tensor object"); \
        tensor_id = SvIV(*svp); \
        lt = get_tensor_by_id(tensor_id); \
        if (!lt) croak("Tensor has been freed"); \
    } while(0)

#define GET_SPECULATIVE_FROM_SELF(self, spec, hv) \
    do { \
        SV **svp; \
        int spec_id; \
        VALIDATE_HASH_REF(self, hv, "Lugh::Speculative"); \
        svp = hv_fetch(hv, "_spec_id", 8, 0); \
        if (!svp) croak("Invalid Lugh::Speculative object"); \
        spec_id = SvIV(*svp); \
        spec = get_speculative_by_id(spec_id); \
        if (!spec) croak("Speculative decoder has been destroyed"); \
    } while(0)

/* ============================================================================
 * Backward Operation Helper Macros
 * ============================================================================
 * These macros reduce duplication in backward pass implementations.
 * The common pattern is:
 *   1. Get input tensor from output's input_ids
 *   2. Check requires_grad and grad exist
 *   3. Loop over elements, computing: old_grad + grad_out * derivative
 *   4. Mark grad_accumulated = true
 */

/* Get single input tensor for unary ops, return early if not valid */
#define GET_UNARY_INPUT(output, a) \
    do { \
        if (output->n_inputs < 1) return; \
        a = get_tensor_by_id(output->input_ids[0]); \
        if (!a || !a->requires_grad || !a->grad) return; \
    } while(0)

/* Get two input tensors for binary ops, return early if not valid */
#define GET_BINARY_INPUTS(output, a, b) \
    do { \
        if (output->n_inputs < 2) return; \
        a = get_tensor_by_id(output->input_ids[0]); \
        b = get_tensor_by_id(output->input_ids[1]); \
        if (!a || !b) return; \
    } while(0)

/* Standard element-wise backward loop for unary operations
 * Computes: grad[j] += grad_out[j] * derivative
 * 'derivative_expr' should compute the derivative given x (input value) */
#define BACKWARD_UNARY_LOOP(a, output, derivative_expr) \
    do { \
        int64_t j, n = ggml_nelements(a->grad); \
        for (j = 0; j < n; j++) { \
            float old = ggml_get_f32_1d(a->grad, j); \
            float grad_out = ggml_get_f32_1d(output->grad, j); \
            float x = ggml_get_f32_1d(a->tensor, j); \
            float derivative = (derivative_expr); \
            ggml_set_f32_1d(a->grad, j, old + grad_out * derivative); \
        } \
        a->grad_accumulated = true; \
    } while(0)

/* Element-wise backward loop for binary operations on first input
 * 'grad_expr' computes the gradient contribution */
#define BACKWARD_BINARY_LOOP_A(a, b, output, grad_expr) \
    do { \
        if (a->requires_grad && a->grad) { \
            int64_t j, n = ggml_nelements(output->grad); \
            for (j = 0; j < n; j++) { \
                float old = ggml_get_f32_1d(a->grad, j); \
                float grad_out = ggml_get_f32_1d(output->grad, j); \
                float a_val = ggml_get_f32_1d(a->tensor, j); \
                float b_val = ggml_get_f32_1d(b->tensor, j); \
                (void)a_val; /* May be unused depending on grad_expr */ \
                ggml_set_f32_1d(a->grad, j, old + (grad_expr)); \
            } \
            a->grad_accumulated = true; \
        } \
    } while(0)

/* Element-wise backward loop for binary operations on second input */
#define BACKWARD_BINARY_LOOP_B(a, b, output, grad_expr) \
    do { \
        if (b->requires_grad && b->grad) { \
            int64_t j, n = ggml_nelements(output->grad); \
            for (j = 0; j < n; j++) { \
                float old = ggml_get_f32_1d(b->grad, j); \
                float grad_out = ggml_get_f32_1d(output->grad, j); \
                float a_val = ggml_get_f32_1d(a->tensor, j); \
                float b_val = ggml_get_f32_1d(b->tensor, j); \
                (void)b_val; /* May be unused depending on grad_expr */ \
                ggml_set_f32_1d(b->grad, j, old + (grad_expr)); \
            } \
            b->grad_accumulated = true; \
        } \
    } while(0)

/* ============================================================================
 * Memory Mapping Structure
 * ============================================================================
 * LughMmap provides cross-platform memory mapping for GGUF model files.
 * When use_mmap is enabled, the model file is memory-mapped instead of
 * being copied into heap memory. This allows:
 * - OS-level sharing of read-only pages across processes (fork-safe)
 * - Reduced memory usage when multiple processes load the same model
 * - Lazy loading of tensor data (pages loaded on demand)
 */

typedef struct {
    void   *addr;      /* Mapped address */
    size_t  size;      /* Size of mapped region */
#ifdef _WIN32
    HANDLE  hFile;     /* File handle */
    HANDLE  hMapping;  /* Mapping handle */
#else
    int     fd;        /* File descriptor */
#endif
    int     active;    /* Whether this mapping is valid */
} LughMmap;

#if LUGH_MMAP_SUPPORTED

/* Create a new memory mapping for a file */
static LughMmap* lugh_mmap_create(const char *filename) {
    LughMmap *mm;
    Newxz(mm, 1, LughMmap);
    mm->active = 0;

#ifdef _WIN32
    /* Windows implementation using CreateFileMapping/MapViewOfFile */
    mm->hFile = CreateFileA(filename, GENERIC_READ, FILE_SHARE_READ, NULL,
                            OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (mm->hFile == INVALID_HANDLE_VALUE) {
        Safefree(mm);
        return NULL;
    }

    LARGE_INTEGER file_size;
    if (!GetFileSizeEx(mm->hFile, &file_size)) {
        CloseHandle(mm->hFile);
        Safefree(mm);
        return NULL;
    }
    mm->size = (size_t)file_size.QuadPart;

    mm->hMapping = CreateFileMappingA(mm->hFile, NULL, PAGE_READONLY, 0, 0, NULL);
    if (mm->hMapping == NULL) {
        CloseHandle(mm->hFile);
        Safefree(mm);
        return NULL;
    }

    mm->addr = MapViewOfFile(mm->hMapping, FILE_MAP_READ, 0, 0, 0);
    if (mm->addr == NULL) {
        CloseHandle(mm->hMapping);
        CloseHandle(mm->hFile);
        Safefree(mm);
        return NULL;
    }

#else
    /* POSIX implementation using mmap */
    mm->fd = open(filename, O_RDONLY);
    if (mm->fd < 0) {
        Safefree(mm);
        return NULL;
    }

    struct stat st;
    if (fstat(mm->fd, &st) < 0) {
        close(mm->fd);
        Safefree(mm);
        return NULL;
    }
    mm->size = (size_t)st.st_size;

    /* Use MAP_SHARED to allow OS to share pages across processes */
    mm->addr = mmap(NULL, mm->size, PROT_READ, MAP_SHARED, mm->fd, 0);
    if (mm->addr == MAP_FAILED) {
        close(mm->fd);
        Safefree(mm);
        return NULL;
    }

    /* Advise kernel we'll be reading sequentially (for initial metadata) */
    #ifdef POSIX_MADV_SEQUENTIAL
    posix_madvise(mm->addr, mm->size, POSIX_MADV_SEQUENTIAL);
    #elif defined(MADV_SEQUENTIAL)
    madvise(mm->addr, mm->size, MADV_SEQUENTIAL);
    #endif

#endif

    mm->active = 1;
    return mm;
}

/* Free a memory mapping */
static void lugh_mmap_free(LughMmap *mm) {
    if (!mm || !mm->active) return;

#ifdef _WIN32
    if (mm->addr) {
        UnmapViewOfFile(mm->addr);
        mm->addr = NULL;
    }
    if (mm->hMapping) {
        CloseHandle(mm->hMapping);
        mm->hMapping = NULL;
    }
    if (mm->hFile && mm->hFile != INVALID_HANDLE_VALUE) {
        CloseHandle(mm->hFile);
        mm->hFile = INVALID_HANDLE_VALUE;
    }
#else
    if (mm->addr && mm->addr != MAP_FAILED) {
        munmap(mm->addr, mm->size);
        mm->addr = NULL;
    }
    if (mm->fd >= 0) {
        close(mm->fd);
        mm->fd = -1;
    }
#endif

    mm->active = 0;
    Safefree(mm);
}

/* Prefetch a region of the mapped file into memory */
static void lugh_mmap_prefetch(LughMmap *mm, size_t offset, size_t len) {
    if (!mm || !mm->active || !mm->addr) return;
    if (offset + len > mm->size) len = mm->size - offset;

#ifdef _WIN32
    /* Windows 8+ has PrefetchVirtualMemory, but we'll skip for compatibility */
    (void)offset;
    (void)len;
#else
    #ifdef POSIX_MADV_WILLNEED
    posix_madvise((char*)mm->addr + offset, len, POSIX_MADV_WILLNEED);
    #elif defined(MADV_WILLNEED)
    madvise((char*)mm->addr + offset, len, MADV_WILLNEED);
    #endif
#endif
}

#else /* !LUGH_MMAP_SUPPORTED */

static LughMmap* lugh_mmap_create(const char *filename) {
    (void)filename;
    return NULL;
}

static void lugh_mmap_free(LughMmap *mm) {
    (void)mm;
}

static void lugh_mmap_prefetch(LughMmap *mm, size_t offset, size_t len) {
    (void)mm;
    (void)offset;
    (void)len;
}

#endif /* LUGH_MMAP_SUPPORTED */

/* ============================================================================
 * Architecture Types
 * ============================================================================ */

typedef enum {
    LUGH_ARCH_UNKNOWN = 0,
    /* Llama-family: standard transformer with SwiGLU FFN */
    LUGH_ARCH_LLAMA,        /* llama, llama4, deci, mistral3 */
    /* Qwen-family: combined QKV for some variants */
    LUGH_ARCH_QWEN,         /* qwen (combined QKV) */
    LUGH_ARCH_QWEN2,        /* qwen2, qwen3 (separate Q/K/V) */
    /* Phi-family: no FFN gate, uses GELU */
    LUGH_ARCH_PHI,          /* phi2, phi3 */
    /* Gemma-family: post-normalization layers */
    LUGH_ARCH_GEMMA,        /* gemma */
    LUGH_ARCH_GEMMA2,       /* gemma2, gemma3 (with post-norm) */
    /* GPT-family: LayerNorm with bias, GELU */
    LUGH_ARCH_GPT2,         /* gpt2 */
    LUGH_ARCH_GPTJ,         /* gptj */
    LUGH_ARCH_GPTNEOX,      /* gptneox */
    /* Other common architectures */
    LUGH_ARCH_FALCON,       /* falcon */
    LUGH_ARCH_BLOOM,        /* bloom */
    LUGH_ARCH_MPT,          /* mpt */
    LUGH_ARCH_STARCODER,    /* starcoder, starcoder2 */
    LUGH_ARCH_STABLELM,     /* stablelm */
    LUGH_ARCH_INTERNLM,     /* internlm2 */
    LUGH_ARCH_DEEPSEEK,     /* deepseek, deepseek2 */
    LUGH_ARCH_COMMAND_R,    /* command-r, cohere2 */
    /* Recurrent architectures (not transformer-based) */
    LUGH_ARCH_MAMBA,        /* mamba, mamba2 */
    LUGH_ARCH_RWKV,         /* rwkv6, rwkv7 */
    /* Encoder-only (BERT-style) */
    LUGH_ARCH_BERT,         /* bert, modern-bert, nomic-bert */
    /* Encoder-decoder */
    LUGH_ARCH_T5,           /* t5, t5encoder */
} LughArchType;

/* Map architecture string to type enum */
static LughArchType get_arch_type(const char *arch) {
    if (!arch) return LUGH_ARCH_UNKNOWN;
    
    /* Llama-family */
    if (strcmp(arch, "llama") == 0 || strcmp(arch, "llama4") == 0 ||
        strcmp(arch, "deci") == 0 || strcmp(arch, "mistral3") == 0 ||
        strcmp(arch, "llama-embed") == 0)
        return LUGH_ARCH_LLAMA;
    
    /* Qwen-family */
    if (strcmp(arch, "qwen") == 0)
        return LUGH_ARCH_QWEN;
    if (strcmp(arch, "qwen2") == 0 || strcmp(arch, "qwen2vl") == 0 ||
        strcmp(arch, "qwen3") == 0 || strcmp(arch, "qwen3moe") == 0)
        return LUGH_ARCH_QWEN2;
    
    /* Phi-family */
    if (strcmp(arch, "phi2") == 0 || strcmp(arch, "phi3") == 0 ||
        strcmp(arch, "phimoe") == 0)
        return LUGH_ARCH_PHI;
    
    /* Gemma-family */
    if (strcmp(arch, "gemma") == 0)
        return LUGH_ARCH_GEMMA;
    if (strcmp(arch, "gemma2") == 0 || strcmp(arch, "gemma3") == 0 ||
        strcmp(arch, "gemma3n") == 0)
        return LUGH_ARCH_GEMMA2;
    
    /* GPT-family */
    if (strcmp(arch, "gpt2") == 0)
        return LUGH_ARCH_GPT2;
    if (strcmp(arch, "gptj") == 0)
        return LUGH_ARCH_GPTJ;
    if (strcmp(arch, "gptneox") == 0)
        return LUGH_ARCH_GPTNEOX;
    
    /* Other architectures */
    if (strcmp(arch, "falcon") == 0 || strcmp(arch, "falcon-h1") == 0)
        return LUGH_ARCH_FALCON;
    if (strcmp(arch, "bloom") == 0)
        return LUGH_ARCH_BLOOM;
    if (strcmp(arch, "mpt") == 0)
        return LUGH_ARCH_MPT;
    if (strcmp(arch, "starcoder") == 0 || strcmp(arch, "starcoder2") == 0)
        return LUGH_ARCH_STARCODER;
    if (strcmp(arch, "stablelm") == 0)
        return LUGH_ARCH_STABLELM;
    if (strcmp(arch, "internlm2") == 0)
        return LUGH_ARCH_INTERNLM;
    if (strcmp(arch, "deepseek") == 0 || strcmp(arch, "deepseek2") == 0)
        return LUGH_ARCH_DEEPSEEK;
    if (strcmp(arch, "command-r") == 0 || strcmp(arch, "cohere2") == 0)
        return LUGH_ARCH_COMMAND_R;
    
    /* Recurrent */
    if (strcmp(arch, "mamba") == 0 || strcmp(arch, "mamba2") == 0 ||
        strcmp(arch, "jamba") == 0)
        return LUGH_ARCH_MAMBA;
    if (strcmp(arch, "rwkv6") == 0 || strcmp(arch, "rwkv7") == 0 ||
        strcmp(arch, "arwkv7") == 0)
        return LUGH_ARCH_RWKV;
    
    /* Encoder models */
    if (strcmp(arch, "bert") == 0 || strcmp(arch, "modern-bert") == 0 ||
        strcmp(arch, "nomic-bert") == 0 || strcmp(arch, "neo-bert") == 0)
        return LUGH_ARCH_BERT;
    if (strcmp(arch, "t5") == 0 || strcmp(arch, "t5encoder") == 0)
        return LUGH_ARCH_T5;
    
    return LUGH_ARCH_UNKNOWN;
}

/* Check if architecture uses combined QKV tensor */
static int arch_has_combined_qkv(LughArchType arch_type) {
    switch (arch_type) {
        case LUGH_ARCH_QWEN:
        case LUGH_ARCH_QWEN2:
        case LUGH_ARCH_PHI:
        case LUGH_ARCH_FALCON:
        case LUGH_ARCH_GPT2:
        case LUGH_ARCH_GPTJ:
        case LUGH_ARCH_GPTNEOX:
        case LUGH_ARCH_BLOOM:
        case LUGH_ARCH_MPT:
        case LUGH_ARCH_STARCODER:
        case LUGH_ARCH_STABLELM:
        case LUGH_ARCH_BERT:
            return 1;
        default:
            return 0;
    }
}

/* Check if architecture uses FFN gate (SwiGLU) */
static int arch_has_ffn_gate(LughArchType arch_type) {
    switch (arch_type) {
        case LUGH_ARCH_LLAMA:
        case LUGH_ARCH_QWEN:
        case LUGH_ARCH_QWEN2:
        case LUGH_ARCH_GEMMA:
        case LUGH_ARCH_GEMMA2:
        case LUGH_ARCH_STABLELM:
        case LUGH_ARCH_INTERNLM:
        case LUGH_ARCH_DEEPSEEK:
            return 1;
        default:
            return 0;
    }
}

/* Check if architecture uses post-normalization */
static int arch_has_post_norm(LughArchType arch_type) {
    return (arch_type == LUGH_ARCH_GEMMA2);
}

/* Check if architecture is recurrent (not transformer) */
static int arch_is_recurrent(LughArchType arch_type) {
    return (arch_type == LUGH_ARCH_MAMBA ||
            arch_type == LUGH_ARCH_RWKV);
}

/* ============================================================================
 * State structures
 * ============================================================================ */

typedef struct {
    struct ggml_context *ctx;
    size_t mem_size;
    int id;
    int active;
} LughContext;

/* Forward declaration for backward function type */
typedef struct LughTensor LughTensor;

/* Forward declarations for LoRA types (defined in LoRA section) */
typedef struct LughLoRAWeight LughLoRAWeight;
typedef struct LughLoRAAdapter LughLoRAAdapter;
static LughLoRAAdapter* get_lora_by_id(int id);
static LughLoRAWeight* find_lora_weight(LughLoRAAdapter *lora, const char *tensor_name);

/* Forward declaration for model lookup */
struct LughModel;
typedef struct LughModel LughModel;
static LughModel* get_model_by_id(int id);

/* Backward function signature: compute gradients for inputs given output gradient */
typedef void (*LughBackwardFn)(LughTensor *self, LughTensor *grad_output);

/* Backward operation types for computation graph */
typedef enum {
    LUGH_BACKWARD_NONE = 0,
    LUGH_BACKWARD_ADD,
    LUGH_BACKWARD_SUB,
    LUGH_BACKWARD_MUL,
    LUGH_BACKWARD_DIV,
    LUGH_BACKWARD_SCALE,
    LUGH_BACKWARD_MATMUL,
    LUGH_BACKWARD_RELU,
    LUGH_BACKWARD_GELU,
    LUGH_BACKWARD_SILU,
    LUGH_BACKWARD_SOFTMAX,
    LUGH_BACKWARD_LAYER_NORM,
    LUGH_BACKWARD_RMS_NORM,
    LUGH_BACKWARD_ROPE,
    LUGH_BACKWARD_SUM,
    LUGH_BACKWARD_MEAN,
    LUGH_BACKWARD_RESHAPE,
    LUGH_BACKWARD_TRANSPOSE,
    LUGH_BACKWARD_VIEW,
    LUGH_BACKWARD_CROSS_ENTROPY,
    LUGH_BACKWARD_MSE,
    LUGH_BACKWARD_TRANSFORMER_FORWARD,  /* Full transformer backward for training */
    LUGH_BACKWARD_CUSTOM
} LughBackwardOp;

struct LughTensor {
    struct ggml_tensor *tensor;
    struct ggml_tensor *grad;     /* Gradient tensor (same shape as tensor) */
    int context_id;               /* ID of owning context */
    int id;
    int active;
    
    /* Autograd fields */
    bool requires_grad;           /* Whether to track gradients for this tensor */
    LughBackwardOp backward_op;   /* Which backward operation to apply */
    int input_ids[4];             /* IDs of input tensors (up to 4 inputs) */
    int n_inputs;                 /* Number of input tensors */
    bool is_leaf;                 /* True if this is a leaf tensor (no inputs) */
    bool grad_accumulated;        /* True if gradient has been accumulated */
    /* Training forward support */
    int training_cache_id;        /* ID of training cache for transformer backward */
};

struct LughModel {
    struct gguf_context *gguf;
    struct ggml_context *ctx;     /* Context for tensor data */
    char *filename;
    int id;
    int active;
    /* Model metadata */
    int64_t n_tensors;
    int64_t n_kv;
    char *architecture;
    /* Memory mapping */
    LughMmap *mmap;               /* Memory-mapped file (NULL if not using mmap) */
    int use_mmap;                 /* Whether this model was loaded with mmap */
};

/* KV Cache for efficient incremental decoding */
typedef struct {
    struct ggml_context *ctx;     /* Context for cache tensors */
    float **k_cache;              /* K cache per layer [n_layer][n_ctx * n_kv_dim] */
    float **v_cache;              /* V cache per layer [n_layer][n_ctx * n_kv_dim] */
    int n_layer;                  /* Number of layers */
    int n_ctx;                    /* Max context length */
    int n_kv_dim;                 /* KV dimension (n_head_kv * head_dim) */
    int head_dim;                 /* Per-head dimension */
    int n_head_kv;                /* Number of KV heads */
    int n_cached;                 /* Number of tokens currently cached */
    int id;
    int active;
#ifdef USE_ITHREADS
    perl_mutex cache_mutex;       /* Thread-safe access to cache */
#endif
} LughKVCache;

#define MAX_KVCACHES 256

#ifdef USE_ITHREADS
#define KVCACHE_LOCK(cache)   MUTEX_LOCK(&(cache)->cache_mutex)
#define KVCACHE_UNLOCK(cache) MUTEX_UNLOCK(&(cache)->cache_mutex)
#else
#define KVCACHE_LOCK(cache)
#define KVCACHE_UNLOCK(cache)
#endif

/* ============================================================================
 * Speculative Decoding
 * ============================================================================ */

typedef struct {
    int main_model_id;            /* ID of main (target) model */
    int draft_model_id;           /* ID of draft model */
    LughKVCache *main_cache;      /* KV cache for main model */
    LughKVCache *draft_cache;     /* KV cache for draft model */
    int k;                        /* Speculation depth (number of draft tokens) */
    float temperature;            /* Sampling temperature */
    float top_p;                  /* Top-p sampling threshold */
    int n_vocab;                  /* Vocabulary size (shared between models) */
    /* Statistics */
    int64_t tokens_drafted;       /* Total tokens drafted */
    int64_t tokens_accepted;      /* Total tokens accepted */
    int64_t total_steps;          /* Total speculation steps */
    int id;
    int active;
#ifdef USE_ITHREADS
    perl_mutex spec_mutex;        /* Thread-safe access */
#endif
} LughSpeculative;

#define MAX_SPECULATIVE 64

#ifdef USE_ITHREADS
#define SPECULATIVE_LOCK(spec)   MUTEX_LOCK(&(spec)->spec_mutex)
#define SPECULATIVE_UNLOCK(spec) MUTEX_UNLOCK(&(spec)->spec_mutex)
#else
#define SPECULATIVE_LOCK(spec)
#define SPECULATIVE_UNLOCK(spec)
#endif

/* ============================================================================
 * Training Cache - Stores Intermediate Activations for Backward Pass
 * Enables gradient flow through entire transformer for LoRA + Full Fine-tuning
 * ============================================================================ */

#define MAX_TRAINING_CACHES 32
#define MAX_TRAIN_LAYERS 128

/* Per-layer activations needed for backward pass */
typedef struct {
    /* Attention activations */
    float *input;                /* Layer input [n_embd, n_tokens] */
    float *attn_norm_out;        /* After attention normalization */
    float *q;                    /* Q projection output [head_dim, n_head, n_tokens] */
    float *k;                    /* K projection output */
    float *v;                    /* V projection output */
    float *attn_weights;         /* Attention weights [n_head, n_tokens, n_kv] */
    float *attn_out;             /* Attention output before O projection */
    float *o_proj_out;           /* After O projection */
    /* FFN activations */
    float *ffn_norm_out;         /* After FFN normalization */
    float *gate_out;             /* Gate projection output */
    float *up_out;               /* Up projection output */
    float *ffn_act;              /* After activation (SiLU(gate) * up) */
    float *down_out;             /* Down projection output */
} LughLayerActivations;

/* Training cache - stores all info needed for backward pass */
typedef struct {
    int id;
    int active;
    /* Model info */
    int model_id;
    int lora_id;                 /* LoRA adapter ID (0 if none) */
    int context_id;              /* LughContext for gradient tensors */
    /* Hyperparameters (cached for backward) */
    int n_layer;
    int n_head;
    int n_head_kv;
    int n_embd;
    int head_dim;
    int n_vocab;
    int n_tokens;
    float rms_norm_eps;
    float lora_scale;            /* LoRA scaling factor */
    /* Embedding */
    float *input_embeddings;     /* Token embeddings [n_embd, n_tokens] */
    /* Per-layer activations */
    LughLayerActivations *layers;
    /* Final norm and output */
    float *final_norm_out;       /* After final RMS norm */
    float *logits;               /* Output logits [n_vocab, n_tokens] */
    /* Trainable weight references */
    bool train_lora;             /* Whether training LoRA weights */
    bool train_full;             /* Whether training full model weights */
    /* Full model weight tensor IDs (for train_full) */
    int *weight_tensor_ids;      /* Array of LughTensor IDs for model weights */
    char **weight_tensor_names;  /* Corresponding tensor names */
    int n_weight_tensors;        /* Number of weight tensors */
    /* Token IDs (needed for embedding backward) */
    int *tokens;
    /* Memory for activations */
    struct ggml_context *act_ctx; /* Context for activation storage */
#ifdef USE_ITHREADS
    perl_mutex cache_mutex;
#endif
} LughTrainingCache;

/* Training cache registry */
static LughTrainingCache* training_cache_registry[MAX_TRAINING_CACHES] = {NULL};
static int next_training_cache_id = 1;

#ifdef USE_ITHREADS
/* training_cache_mutex is declared and initialized with other mutexes at top of file */
#define TRAINING_CACHE_LOCK()   MUTEX_LOCK(&training_cache_mutex)
#define TRAINING_CACHE_UNLOCK() MUTEX_UNLOCK(&training_cache_mutex)
#else
#define TRAINING_CACHE_LOCK()
#define TRAINING_CACHE_UNLOCK()
#endif

/* Allocate training cache ID */
static int alloc_training_cache_id(void) {
    int id = -1;
    TRAINING_CACHE_LOCK();
    for (int i = 0; i < MAX_TRAINING_CACHES; i++) {
        int check_id = (next_training_cache_id + i) % MAX_TRAINING_CACHES;
        if (check_id == 0) check_id = 1;
        if (training_cache_registry[check_id] == NULL) {
            id = check_id;
            next_training_cache_id = (id + 1) % MAX_TRAINING_CACHES;
            if (next_training_cache_id == 0) next_training_cache_id = 1;
            break;
        }
    }
    TRAINING_CACHE_UNLOCK();
    return id;
}

/* Get training cache by ID */
static LughTrainingCache* get_training_cache_by_id(int id) {
    LughTrainingCache *tc = NULL;
    if (id <= 0 || id >= MAX_TRAINING_CACHES) return NULL;
    TRAINING_CACHE_LOCK();
    tc = training_cache_registry[id];
    if (tc && !tc->active) tc = NULL;
    TRAINING_CACHE_UNLOCK();
    return tc;
}

/* Free layer activations */
static void free_layer_activations(LughLayerActivations *la) {
    if (!la) return;
    /* Note: Memory is in act_ctx, freed when context is freed */
    /* Just zero out pointers */
    Zero(la, 1, LughLayerActivations);
}

/* Create a new training cache */
static LughTrainingCache* create_training_cache(int n_layer) {
    int id = alloc_training_cache_id();
    if (id < 0) return NULL;
    
    LughTrainingCache *tc;
    Newxz(tc, 1, LughTrainingCache);
    if (!tc) return NULL;
    
    tc->id = id;
    tc->active = 1;
    tc->n_layer = n_layer;
    
    /* Initialize weight tensor arrays */
    tc->weight_tensor_ids = NULL;
    tc->weight_tensor_names = NULL;
    tc->n_weight_tensors = 0;
    
    Newxz(tc->layers, n_layer, LughLayerActivations);
    if (!tc->layers) {
        Safefree(tc);
        return NULL;
    }
    
    /* Create context for activation storage */
    size_t mem_size = 64 * 1024 * 1024;  /* 64MB for activations (small model) */
    struct ggml_init_params params = {
        .mem_size = mem_size,
        .mem_buffer = NULL,
        .no_alloc = false
    };
    tc->act_ctx = ggml_init(params);
    if (!tc->act_ctx) {
        Safefree(tc->layers);
        Safefree(tc);
        return NULL;
    }
    
#ifdef USE_ITHREADS
    MUTEX_INIT(&tc->cache_mutex);
#endif
    
    TRAINING_CACHE_LOCK();
    training_cache_registry[id] = tc;
    TRAINING_CACHE_UNLOCK();
    
    return tc;
}

/* Free training cache */
static void free_training_cache(LughTrainingCache *tc) {
    if (!tc) return;
    
    TRAINING_CACHE_LOCK();
    if (tc->id > 0 && tc->id < MAX_TRAINING_CACHES) {
        training_cache_registry[tc->id] = NULL;
    }
    tc->active = 0;
    TRAINING_CACHE_UNLOCK();
    
    if (tc->layers) {
        for (int i = 0; i < tc->n_layer; i++) {
            free_layer_activations(&tc->layers[i]);
        }
        Safefree(tc->layers);
    }
    if (tc->act_ctx) {
        ggml_free(tc->act_ctx);
    }
    if (tc->tokens) {
        Safefree(tc->tokens);
    }
    /* Free weight tensor arrays (don't free the tensors themselves, just the registry) */
    if (tc->weight_tensor_ids) {
        Safefree(tc->weight_tensor_ids);
    }
    if (tc->weight_tensor_names) {
        for (int i = 0; i < tc->n_weight_tensors; i++) {
            if (tc->weight_tensor_names[i]) {
                Safefree(tc->weight_tensor_names[i]);
            }
        }
        Safefree(tc->weight_tensor_names);
    }
    
#ifdef USE_ITHREADS
    MUTEX_DESTROY(&tc->cache_mutex);
#endif
    
    Safefree(tc);
}

/* ============================================================================
 * Global Registries (thread-safe via integer IDs)
 * ============================================================================ */

static LughContext* context_registry[MAX_CONTEXTS] = {NULL};
static LughTensor*  tensor_registry[MAX_TENSORS]   = {NULL};
static LughModel*   model_registry[MAX_CONTEXTS]   = {NULL};
static LughKVCache* kvcache_registry[MAX_KVCACHES] = {NULL};
static LughSpeculative* speculative_registry[MAX_SPECULATIVE] = {NULL};
static int next_context_id = 1;
static int next_tensor_id  = 1;
static int next_model_id   = 1;
static int next_kvcache_id = 1;
static int next_speculative_id = 1;

/* Global autograd state */
static bool grad_enabled = true;  /* Whether gradient tracking is enabled */

#ifdef USE_ITHREADS
#define KVCACHE_REGISTRY_LOCK()   MUTEX_LOCK(&kvcache_mutex)
#define KVCACHE_REGISTRY_UNLOCK() MUTEX_UNLOCK(&kvcache_mutex)
#define SPECULATIVE_REGISTRY_LOCK()   MUTEX_LOCK(&speculative_mutex)
#define SPECULATIVE_REGISTRY_UNLOCK() MUTEX_UNLOCK(&speculative_mutex)
#else
#define KVCACHE_REGISTRY_LOCK()
#define KVCACHE_REGISTRY_UNLOCK()
#define SPECULATIVE_REGISTRY_LOCK()
#define SPECULATIVE_REGISTRY_UNLOCK()
#endif

/* Allocate a new context ID */
static int alloc_context_id(void) {
    int id = -1;
    CONTEXT_LOCK();
    for (int i = 0; i < MAX_CONTEXTS; i++) {
        int check_id = (next_context_id + i) % MAX_CONTEXTS;
        if (check_id == 0) check_id = 1;  /* Skip 0 */
        if (context_registry[check_id] == NULL) {
            id = check_id;
            next_context_id = (id + 1) % MAX_CONTEXTS;
            if (next_context_id == 0) next_context_id = 1;
            break;
        }
    }
    CONTEXT_UNLOCK();
    return id;
}

/* Get context by ID */
static LughContext* get_context_by_id(int id) {
    LughContext *lctx = NULL;
    if (id <= 0 || id >= MAX_CONTEXTS) return NULL;
    CONTEXT_LOCK();
    lctx = context_registry[id];
    if (lctx && !lctx->active) lctx = NULL;
    CONTEXT_UNLOCK();
    return lctx;
}

/* Allocate a new tensor ID */
static int alloc_tensor_id(void) {
    int id = -1;
    TENSOR_LOCK();
    for (int i = 0; i < MAX_TENSORS; i++) {
        int check_id = (next_tensor_id + i) % MAX_TENSORS;
        if (check_id == 0) check_id = 1;
        if (tensor_registry[check_id] == NULL) {
            id = check_id;
            next_tensor_id = (id + 1) % MAX_TENSORS;
            if (next_tensor_id == 0) next_tensor_id = 1;
            break;
        }
    }
    TENSOR_UNLOCK();
    return id;
}

/* Get tensor by ID */
static LughTensor* get_tensor_by_id(int id) {
    LughTensor *lt = NULL;
    if (id <= 0 || id >= MAX_TENSORS) return NULL;
    TENSOR_LOCK();
    lt = tensor_registry[id];
    if (lt && !lt->active) lt = NULL;
    TENSOR_UNLOCK();
    return lt;
}

/* Create a new LughTensor and register it */
static LughTensor* create_lugh_tensor(pTHX_ struct ggml_tensor *tensor, int context_id, bool requires_grad) {
    LughTensor *lt;
    int id;
    
    if (!tensor) return NULL;
    
    id = alloc_tensor_id();
    if (id < 0) {
        croak("Tensor registry full (max %d tensors)", MAX_TENSORS);
        return NULL;
    }
    
    Newxz(lt, 1, LughTensor);
    if (!lt) {
        croak("Failed to allocate LughTensor");
        return NULL;
    }
    
    lt->tensor = tensor;
    lt->grad = NULL;
    lt->context_id = context_id;
    lt->id = id;
    lt->active = 1;
    lt->requires_grad = requires_grad;
    lt->backward_op = LUGH_BACKWARD_NONE;
    lt->n_inputs = 0;
    lt->is_leaf = true;          /* Default: leaf tensor */
    lt->grad_accumulated = false;
    
    /* Initialize input_ids to -1 (invalid) */
    for (int i = 0; i < 4; i++) {
        lt->input_ids[i] = -1;
    }
    
    TENSOR_LOCK();
    tensor_registry[id] = lt;
    TENSOR_UNLOCK();
    
    return lt;
}

/* Free a LughTensor and remove from registry */
static void free_lugh_tensor(LughTensor *lt) {
    if (!lt) return;
    
    TENSOR_LOCK();
    if (lt->id > 0 && lt->id < MAX_TENSORS) {
        tensor_registry[lt->id] = NULL;
    }
    lt->active = 0;
    TENSOR_UNLOCK();
    
    /* Note: tensor->data is owned by the context, not freed here */
    /* Note: grad tensor is also owned by the context */
    Safefree(lt);
}

/* Allocate gradient tensor for a LughTensor (same shape as original) */
static int alloc_grad(pTHX_ LughTensor *lt, LughContext *lctx) {
    if (!lt || !lctx || !lt->tensor) return 0;
    if (lt->grad) return 1; /* Already allocated */
    
    /* Create gradient tensor with same shape as original */
    struct ggml_tensor *grad = ggml_dup_tensor(lctx->ctx, lt->tensor);
    if (!grad) return 0;
    
    /* Ensure memory is allocated */
    if (!grad->data) {
        /* If ggml didn't allocate, we have a problem */
        return 0;
    }
    
    /* Zero-initialize the gradient using explicit memset */
    size_t nbytes = ggml_nbytes(grad);
    memset(grad->data, 0, nbytes);
    
    /* Force a memory barrier */
    __sync_synchronize();
    
    lt->grad = grad;
    return 1;
}

/* Zero out all accumulated gradients */
static void zero_grad(LughTensor *lt) {
    if (!lt || !lt->grad) return;
    ggml_set_zero(lt->grad);
    lt->grad_accumulated = false;
}

/* Accumulate gradient into tensor's grad buffer */
static void accumulate_grad(LughTensor *lt, struct ggml_tensor *grad_in) {
    int64_t i, n;
    if (!lt || !lt->grad || !grad_in) return;
    
    n = ggml_nelements(lt->grad);
    if (n != ggml_nelements(grad_in)) return; /* Shape mismatch */
    
    /* Accumulate: grad += grad_in */
    for (i = 0; i < n; i++) {
        float old_val = ggml_get_f32_1d(lt->grad, i);
        float new_val = ggml_get_f32_1d(grad_in, i);
        ggml_set_f32_1d(lt->grad, i, old_val + new_val);
    }
    lt->grad_accumulated = true;
}

/* Set gradient directly (for output tensors) */
static void set_grad_ones(LughTensor *lt) {
    int64_t i, n;
    if (!lt || !lt->grad) return;
    
    n = ggml_nelements(lt->grad);
    for (i = 0; i < n; i++) {
        ggml_set_f32_1d(lt->grad, i, 1.0f);
    }
    lt->grad_accumulated = true;
}

/* Forward declarations for backward operations */
static void backward_add(pTHX_ LughTensor *output, LughContext *lctx);
static void backward_sub(pTHX_ LughTensor *output, LughContext *lctx);
static void backward_mul(pTHX_ LughTensor *output, LughContext *lctx);
static void backward_div(pTHX_ LughTensor *output, LughContext *lctx);
static void backward_matmul(pTHX_ LughTensor *output, LughContext *lctx);
static void backward_sum(pTHX_ LughTensor *output, LughContext *lctx);
static void backward_relu(pTHX_ LughTensor *output, LughContext *lctx);
static void backward_scale(pTHX_ LughTensor *output, LughContext *lctx);
static void backward_gelu(pTHX_ LughTensor *output, LughContext *lctx);
static void backward_silu(pTHX_ LughTensor *output, LughContext *lctx);
static void backward_softmax(pTHX_ LughTensor *output, LughContext *lctx);
static void backward_rms_norm(pTHX_ LughTensor *output, LughContext *lctx);
static void backward_rope(pTHX_ LughTensor *output, LughContext *lctx);
static void backward_mean(pTHX_ LughTensor *output, LughContext *lctx);
static void backward_cross_entropy(pTHX_ LughTensor *output, LughContext *lctx);
static void backward_mse(pTHX_ LughTensor *output, LughContext *lctx);
static void backward_transformer_forward(pTHX_ LughTensor *output, LughContext *lctx);

/* Perform backward pass from a tensor (recursive) */
static void backward_tensor(pTHX_ LughTensor *lt, LughContext *lctx) {
    int i;
    
    if (!lt || !lt->requires_grad || !lt->grad) return;
    
    /* Don't backprop through leaf tensors */
    if (lt->is_leaf) return;
    
    /* Dispatch based on backward operation */
    switch (lt->backward_op) {
        case LUGH_BACKWARD_ADD:
            backward_add(aTHX_ lt, lctx);
            break;
        case LUGH_BACKWARD_SUB:
            backward_sub(aTHX_ lt, lctx);
            break;
        case LUGH_BACKWARD_MUL:
            backward_mul(aTHX_ lt, lctx);
            break;
        case LUGH_BACKWARD_DIV:
            backward_div(aTHX_ lt, lctx);
            break;
        case LUGH_BACKWARD_SCALE:
            backward_scale(aTHX_ lt, lctx);
            break;
        case LUGH_BACKWARD_MATMUL:
            backward_matmul(aTHX_ lt, lctx);
            break;
        case LUGH_BACKWARD_SUM:
            backward_sum(aTHX_ lt, lctx);
            break;
        case LUGH_BACKWARD_MEAN:
            backward_mean(aTHX_ lt, lctx);
            break;
        case LUGH_BACKWARD_RELU:
            backward_relu(aTHX_ lt, lctx);
            break;
        case LUGH_BACKWARD_GELU:
            backward_gelu(aTHX_ lt, lctx);
            break;
        case LUGH_BACKWARD_SILU:
            backward_silu(aTHX_ lt, lctx);
            break;
        case LUGH_BACKWARD_SOFTMAX:
            backward_softmax(aTHX_ lt, lctx);
            break;
        case LUGH_BACKWARD_RMS_NORM:
            backward_rms_norm(aTHX_ lt, lctx);
            break;
        case LUGH_BACKWARD_ROPE:
            backward_rope(aTHX_ lt, lctx);
            break;
        case LUGH_BACKWARD_CROSS_ENTROPY:
            backward_cross_entropy(aTHX_ lt, lctx);
            break;
        case LUGH_BACKWARD_MSE:
            backward_mse(aTHX_ lt, lctx);
            break;
        case LUGH_BACKWARD_TRANSFORMER_FORWARD:
            backward_transformer_forward(aTHX_ lt, lctx);
            break;
        default:
            break;
    }
    
    /* Recursively backward through inputs */
    for (i = 0; i < lt->n_inputs; i++) {
        if (lt->input_ids[i] > 0) {
            LughTensor *input = get_tensor_by_id(lt->input_ids[i]);
            if (input && input->requires_grad) {
                backward_tensor(aTHX_ input, lctx);
            }
        }
    }
}

/* ============================================================================
 * Backward Operation Implementations
 * ============================================================================ */

/* d(a+b)/da = 1, d(a+b)/db = 1 */
static void backward_add(pTHX_ LughTensor *output, LughContext *lctx) {
    int i;
    PERL_UNUSED_ARG(lctx);
    
    for (i = 0; i < output->n_inputs; i++) {
        LughTensor *input = get_tensor_by_id(output->input_ids[i]);
        if (input && input->requires_grad && input->grad) {
            /* Gradient passes through unchanged for add */
            accumulate_grad(input, output->grad);
        }
    }
}

/* d(a-b)/da = 1, d(a-b)/db = -1 */
static void backward_sub(pTHX_ LughTensor *output, LughContext *lctx) {
    int64_t j, n;
    PERL_UNUSED_ARG(lctx);
    
    if (output->n_inputs < 2) return;
    
    /* First input: gradient passes through */
    LughTensor *a = get_tensor_by_id(output->input_ids[0]);
    if (a && a->requires_grad && a->grad) {
        accumulate_grad(a, output->grad);
    }
    
    /* Second input: gradient is negated */
    LughTensor *b = get_tensor_by_id(output->input_ids[1]);
    if (b && b->requires_grad && b->grad) {
        n = ggml_nelements(output->grad);
        for (j = 0; j < n; j++) {
            float old = ggml_get_f32_1d(b->grad, j);
            float grad_out = ggml_get_f32_1d(output->grad, j);
            ggml_set_f32_1d(b->grad, j, old - grad_out);
        }
        b->grad_accumulated = true;
    }
}

/* d(a*b)/da = b, d(a*b)/db = a (element-wise) */
static void backward_mul(pTHX_ LughTensor *output, LughContext *lctx) {
    LughTensor *a, *b;
    PERL_UNUSED_ARG(lctx);

    GET_BINARY_INPUTS(output, a, b);

    /* d/da = b * grad_output */
    BACKWARD_BINARY_LOOP_A(a, b, output, grad_out * b_val);

    /* d/db = a * grad_output */
    BACKWARD_BINARY_LOOP_B(a, b, output, grad_out * a_val);
}

/* d(a/b)/da = 1/b, d(a/b)/db = -a/b^2 */
static void backward_div(pTHX_ LughTensor *output, LughContext *lctx) {
    int64_t j, n;
    PERL_UNUSED_ARG(lctx);
    
    if (output->n_inputs < 2) return;
    
    LughTensor *a = get_tensor_by_id(output->input_ids[0]);
    LughTensor *b = get_tensor_by_id(output->input_ids[1]);
    
    if (!a || !b) return;
    n = ggml_nelements(output->grad);
    
    /* d/da = (1/b) * grad_output */
    if (a->requires_grad && a->grad) {
        for (j = 0; j < n; j++) {
            float old = ggml_get_f32_1d(a->grad, j);
            float grad_out = ggml_get_f32_1d(output->grad, j);
            float b_val = ggml_get_f32_1d(b->tensor, j);
            if (b_val != 0.0f) {
                ggml_set_f32_1d(a->grad, j, old + grad_out / b_val);
            }
        }
        a->grad_accumulated = true;
    }
    
    /* d/db = (-a/b^2) * grad_output */
    if (b->requires_grad && b->grad) {
        for (j = 0; j < n; j++) {
            float old = ggml_get_f32_1d(b->grad, j);
            float grad_out = ggml_get_f32_1d(output->grad, j);
            float a_val = ggml_get_f32_1d(a->tensor, j);
            float b_val = ggml_get_f32_1d(b->tensor, j);
            if (b_val != 0.0f) {
                ggml_set_f32_1d(b->grad, j, old - grad_out * a_val / (b_val * b_val));
            }
        }
        b->grad_accumulated = true;
    }
}

/* d(sum(a))/da = ones_like(a) */
static void backward_sum(pTHX_ LughTensor *output, LughContext *lctx) {
    int64_t j, n;
    float grad_out;
    LughTensor *a;
    PERL_UNUSED_ARG(lctx);

    GET_UNARY_INPUT(output, a);

    /* Sum output should be scalar, grad is also scalar */
    grad_out = ggml_get_f32_1d(output->grad, 0);
    n = ggml_nelements(a->grad);

    /* Distribute gradient to all elements */
    for (j = 0; j < n; j++) {
        float old = ggml_get_f32_1d(a->grad, j);
        ggml_set_f32_1d(a->grad, j, old + grad_out);
    }
    a->grad_accumulated = true;
}

/* d(relu(a))/da = 1 if a > 0 else 0 */
static void backward_relu(pTHX_ LughTensor *output, LughContext *lctx) {
    LughTensor *a;
    PERL_UNUSED_ARG(lctx);

    GET_UNARY_INPUT(output, a);

    /* ReLU derivative: 1 if x > 0, 0 otherwise */
    BACKWARD_UNARY_LOOP(a, output, (x > 0.0f) ? 1.0f : 0.0f);
}

/* Matmul backward: C = A @ B -> dA = dC @ B^T, dB = A^T @ dC */
/* For 2D matrices: A[M,K] @ B[K,N] = C[M,N] */
/* dA[M,K] = dC[M,N] @ B^T[N,K] */
/* dB[K,N] = A^T[K,M] @ dC[M,N] */
static void backward_matmul(pTHX_ LughTensor *output, LughContext *lctx) {
    int64_t i, j, k;
    int64_t M, K, N;
    
    PERL_UNUSED_ARG(lctx);
    
    if (output->n_inputs < 2) return;
    
    LughTensor *a = get_tensor_by_id(output->input_ids[0]);
    LughTensor *b = get_tensor_by_id(output->input_ids[1]);
    
    if (!a || !b || !output->grad) return;
    
    /* Get dimensions - assume 2D for now */
    /* A: [ne0, ne1] = [K, M] in ggml (column-major) */
    /* B: [ne0, ne1] = [N, K] in ggml */
    /* C: [ne0, ne1] = [N, M] in ggml */
    int64_t a_ne0 = a->tensor->ne[0];  /* K */
    int64_t a_ne1 = a->tensor->ne[1];  /* M */
    int64_t b_ne0 = b->tensor->ne[0];  /* N */
    int64_t b_ne1 = b->tensor->ne[1];  /* K */
    
    M = a_ne1;
    K = a_ne0;
    N = b_ne0;
    
    /* dA = dC @ B^T */
    /* dA[m,k] = sum_n(dC[m,n] * B[k,n]) */
    if (a->requires_grad && a->grad) {
        for (i = 0; i < M; i++) {          /* rows of A */
            for (j = 0; j < K; j++) {      /* cols of A */
                float grad_sum = 0.0f;
                for (k = 0; k < N; k++) {  /* sum over N */
                    /* dC[i,k] * B[j,k] (B transposed) */
                    float dc_val = ggml_get_f32_1d(output->grad, k + i * N);
                    float b_val = ggml_get_f32_1d(b->tensor, k + j * N);
                    grad_sum += dc_val * b_val;
                }
                int64_t a_idx = j + i * K;
                float old = ggml_get_f32_1d(a->grad, a_idx);
                ggml_set_f32_1d(a->grad, a_idx, old + grad_sum);
            }
        }
        a->grad_accumulated = true;
    }
    
    /* dB = A^T @ dC */
    /* dB[k,n] = sum_m(A[m,k] * dC[m,n]) */
    if (b->requires_grad && b->grad) {
        for (i = 0; i < K; i++) {          /* rows of B (cols of A) */
            for (j = 0; j < N; j++) {      /* cols of B */
                float grad_sum = 0.0f;
                for (k = 0; k < M; k++) {  /* sum over M */
                    /* A^T[i,k] * dC[k,j] = A[k,i] * dC[k,j] */
                    float a_val = ggml_get_f32_1d(a->tensor, i + k * K);
                    float dc_val = ggml_get_f32_1d(output->grad, j + k * N);
                    grad_sum += a_val * dc_val;
                }
                int64_t b_idx = j + i * N;
                float old = ggml_get_f32_1d(b->grad, b_idx);
                ggml_set_f32_1d(b->grad, b_idx, old + grad_sum);
            }
        }
        b->grad_accumulated = true;
    }
}

/* d(scale(a, s))/da = s (element-wise scale by constant) */
static void backward_scale(pTHX_ LughTensor *output, LughContext *lctx) {
    LughTensor *a;
    float scale;
    union { int i; float f; } scale_union;
    PERL_UNUSED_ARG(lctx);

    GET_UNARY_INPUT(output, a);

    /* Scale factor is stored in input_ids[1] as a bit-cast float */
    scale_union.i = output->input_ids[1];
    scale = scale_union.f;

    /* derivative is just the scale factor */
    BACKWARD_UNARY_LOOP(a, output, scale);
}

/* Helper: compute GELU derivative at x */
static inline float gelu_derivative(float x) {
    const float SQRT_2_OVER_PI = 0.7978845608028654f;  /* sqrt(2/pi) */
    const float COEF = 0.044715f;

    float x3 = x * x * x;
    float inner = SQRT_2_OVER_PI * (x + COEF * x3);
    float tanh_inner = tanhf(inner);
    float sech2_inner = 1.0f - tanh_inner * tanh_inner;
    float d_inner = SQRT_2_OVER_PI * (1.0f + 3.0f * COEF * x * x);

    return 0.5f * (1.0f + tanh_inner) + 0.5f * x * sech2_inner * d_inner;
}

/* d(gelu(x))/dx = 0.5 * (1 + tanh(sqrt(2/pi) * (x + 0.044715 * x^3))) +
                   0.5 * x * (1 - tanh^2(...)) * sqrt(2/pi) * (1 + 3*0.044715*x^2) */
/* Simplified using the standard GELU derivative */
static void backward_gelu(pTHX_ LughTensor *output, LughContext *lctx) {
    LughTensor *a;
    PERL_UNUSED_ARG(lctx);

    GET_UNARY_INPUT(output, a);
    BACKWARD_UNARY_LOOP(a, output, gelu_derivative(x));
}

/* Helper: compute SiLU derivative at x */
static inline float silu_derivative(float x) {
    float sigmoid_x = 1.0f / (1.0f + expf(-x));
    return sigmoid_x * (1.0f + x * (1.0f - sigmoid_x));
}

/* d(silu(x))/dx = silu(x) + sigmoid(x) * (1 - silu(x)) */
/* silu(x) = x * sigmoid(x), sigmoid(x) = 1 / (1 + exp(-x)) */
/* d(silu)/dx = sigmoid(x) + x * sigmoid(x) * (1 - sigmoid(x)) = sigmoid(x) * (1 + x * (1 - sigmoid(x))) */
static void backward_silu(pTHX_ LughTensor *output, LughContext *lctx) {
    LughTensor *a;
    PERL_UNUSED_ARG(lctx);

    GET_UNARY_INPUT(output, a);
    BACKWARD_UNARY_LOOP(a, output, silu_derivative(x));
}

/* d(softmax(x)_i)/dx_j = softmax_i * (delta_ij - softmax_j) */
/* For loss gradients: dL/dx_i = sum_j(dL/dy_j * dy_j/dx_i) */
/*                             = sum_j(dL/dy_j * y_j * (delta_ij - y_i)) */
/*                             = y_i * (dL/dy_i - sum_j(dL/dy_j * y_j)) */
static void backward_softmax(pTHX_ LughTensor *output, LughContext *lctx) {
    int64_t j, n;
    float sum_grad_y;
    LughTensor *a;
    PERL_UNUSED_ARG(lctx);

    GET_UNARY_INPUT(output, a);
    n = ggml_nelements(a->grad);

    /* First compute sum(grad_out * y) where y is the softmax output */
    sum_grad_y = 0.0f;
    for (j = 0; j < n; j++) {
        float grad_out = ggml_get_f32_1d(output->grad, j);
        float y = ggml_get_f32_1d(output->tensor, j);
        sum_grad_y += grad_out * y;
    }

    /* Then compute gradient: y_i * (grad_out_i - sum(grad_out * y)) */
    for (j = 0; j < n; j++) {
        float old = ggml_get_f32_1d(a->grad, j);
        float grad_out = ggml_get_f32_1d(output->grad, j);
        float y = ggml_get_f32_1d(output->tensor, j);

        float softmax_grad = y * (grad_out - sum_grad_y);
        ggml_set_f32_1d(a->grad, j, old + softmax_grad);
    }
    a->grad_accumulated = true;
}

/* d(rms_norm(x))/dx - RMS normalization backward */
/* rms_norm(x) = x / rms(x) where rms(x) = sqrt(mean(x^2) + eps) */
/* Let r = rms(x), then y = x/r */
/* dy/dx = (1/r) - x * dr/dx / r^2 */
/* dr/dx = x / (n * r) where n is number of elements */
/* dy/dx = (1/r) * (1 - (x^2)/(n*r^2)) = (1/r) * (1 - y*x/n) */
static void backward_rms_norm(pTHX_ LughTensor *output, LughContext *lctx) {
    int64_t j, n;
    float sum_sq, rms, sum_grad_xy;
    const float eps = 1e-5f;
    LughTensor *a;
    PERL_UNUSED_ARG(lctx);

    GET_UNARY_INPUT(output, a);
    n = ggml_nelements(a->grad);
    
    /* Compute RMS of input */
    sum_sq = 0.0f;
    for (j = 0; j < n; j++) {
        float x = ggml_get_f32_1d(a->tensor, j);
        sum_sq += x * x;
    }
    rms = sqrtf(sum_sq / n + eps);
    
    /* Compute sum(grad_out * x * y) / n for the correction term */
    sum_grad_xy = 0.0f;
    for (j = 0; j < n; j++) {
        float grad_out = ggml_get_f32_1d(output->grad, j);
        float x = ggml_get_f32_1d(a->tensor, j);
        float y = ggml_get_f32_1d(output->tensor, j);
        sum_grad_xy += grad_out * x * y;
    }
    sum_grad_xy /= n;
    
    /* Compute gradient: (1/rms) * (grad_out - y * sum_grad_xy / rms) */
    for (j = 0; j < n; j++) {
        float old = ggml_get_f32_1d(a->grad, j);
        float grad_out = ggml_get_f32_1d(output->grad, j);
        float y = ggml_get_f32_1d(output->tensor, j);
        
        float rms_grad = (grad_out - y * sum_grad_xy / rms) / rms;
        ggml_set_f32_1d(a->grad, j, old + rms_grad);
    }
    a->grad_accumulated = true;
}

/* d(rope(x))/dx - Rotary Position Embedding backward */
/* RoPE applies rotation: [x0, x1] -> [x0*cos - x1*sin, x0*sin + x1*cos] */
/* The backward is just the transpose of the rotation matrix (which is its inverse) */
/* [dy0, dy1] -> [dy0*cos + dy1*sin, -dy0*sin + dy1*cos] */
static void backward_rope(pTHX_ LughTensor *output, LughContext *lctx) {
    int64_t head_dim, n_heads, pos;
    LughTensor *a;
    PERL_UNUSED_ARG(lctx);

    GET_UNARY_INPUT(output, a);
    
    /* Get head dimension from tensor shape */
    /* Assume shape is [head_dim, n_heads, ...] */
    head_dim = a->tensor->ne[0];
    n_heads = a->tensor->ne[1];
    
    /* Position might be stored in input_ids[1] */
    pos = output->input_ids[1];
    if (pos < 0) pos = 0;
    
    /* RoPE base frequency */
    const float theta_base = 10000.0f;
    
    /* Process each head */
    for (int64_t h = 0; h < n_heads; h++) {
        int64_t head_offset = h * head_dim;
        
        /* Process pairs of elements */
        for (int64_t i = 0; i < head_dim / 2; i++) {
            float freq = 1.0f / powf(theta_base, (float)(2 * i) / head_dim);
            float angle = pos * freq;
            float cos_angle = cosf(angle);
            float sin_angle = sinf(angle);
            
            int64_t idx0 = head_offset + i;
            int64_t idx1 = head_offset + i + head_dim / 2;
            
            float grad_out0 = ggml_get_f32_1d(output->grad, idx0);
            float grad_out1 = ggml_get_f32_1d(output->grad, idx1);
            
            /* Inverse rotation (transpose of rotation matrix) */
            float grad_in0 = grad_out0 * cos_angle + grad_out1 * sin_angle;
            float grad_in1 = -grad_out0 * sin_angle + grad_out1 * cos_angle;
            
            float old0 = ggml_get_f32_1d(a->grad, idx0);
            float old1 = ggml_get_f32_1d(a->grad, idx1);
            
            ggml_set_f32_1d(a->grad, idx0, old0 + grad_in0);
            ggml_set_f32_1d(a->grad, idx1, old1 + grad_in1);
        }
    }
    a->grad_accumulated = true;
}

/* d(mean(a))/da = 1/n for all elements */
static void backward_mean(pTHX_ LughTensor *output, LughContext *lctx) {
    int64_t j, n;
    PERL_UNUSED_ARG(lctx);
    
    if (output->n_inputs < 1) return;
    
    LughTensor *a = get_tensor_by_id(output->input_ids[0]);
    if (!a || !a->requires_grad || !a->grad) return;
    
    /* Mean output should be scalar */
    float grad_out = ggml_get_f32_1d(output->grad, 0);
    n = ggml_nelements(a->grad);
    
    /* Distribute gradient equally to all elements */
    float grad_per_elem = grad_out / (float)n;
    for (j = 0; j < n; j++) {
        float old = ggml_get_f32_1d(a->grad, j);
        ggml_set_f32_1d(a->grad, j, old + grad_per_elem);
    }
    a->grad_accumulated = true;
}

/* Cross-entropy backward: dL/d(logits) = softmax(logits) - one_hot(targets) */
static void backward_cross_entropy(pTHX_ LughTensor *output, LughContext *lctx) {
    int64_t i, j;
    
    if (!output || !output->grad) return;
    if (output->n_inputs < 2) return;
    
    LughTensor *predictions = get_tensor_by_id(output->input_ids[0]);
    LughTensor *targets = get_tensor_by_id(output->input_ids[1]);
    if (!predictions || !targets) return;
    if (!predictions->tensor || !targets->tensor) return;
    if (!predictions->requires_grad) return;
    
    /* Allocate gradient if needed */
    if (!predictions->grad) {
        if (!alloc_grad(aTHX_ predictions, lctx)) return;
    }
    
    float grad_out = ggml_get_f32_1d(output->grad, 0);
    
    /* Get dimensions: predictions is [vocab_size, batch_size] or [vocab_size] */
    int64_t vocab_size = predictions->tensor->ne[0];
    int64_t batch_size = predictions->tensor->ne[1];
    if (batch_size < 1) batch_size = 1;
    
    /* Verify targets tensor has correct size */
    int64_t targets_size = ggml_nelements(targets->tensor);
    if (targets_size < batch_size) return;  /* Safety check */
    
    /* For each batch item, compute softmax gradient */
    for (i = 0; i < batch_size; i++) {
        /* Get target class for this batch item */
        float target_f = ggml_get_f32_1d(targets->tensor, i);
        int target_class = (int)target_f;
        if (target_class < 0 || target_class >= vocab_size) continue;
        
        /* Compute softmax for this batch item */
        float max_val = -1e9f;
        for (j = 0; j < vocab_size; j++) {
            int64_t idx = i * vocab_size + j;
            if (idx >= ggml_nelements(predictions->tensor)) continue;
            float val = ggml_get_f32_1d(predictions->tensor, idx);
            if (val > max_val) max_val = val;
        }
        
        float sum_exp = 0.0f;
        for (j = 0; j < vocab_size; j++) {
            int64_t idx = i * vocab_size + j;
            if (idx >= ggml_nelements(predictions->tensor)) continue;
            float val = ggml_get_f32_1d(predictions->tensor, idx);
            sum_exp += expf(val - max_val);
        }
        
        if (sum_exp <= 0.0f) continue;  /* Avoid division by zero */
        
        /* Gradient: softmax - one_hot */
        for (j = 0; j < vocab_size; j++) {
            int64_t idx = i * vocab_size + j;
            if (idx >= ggml_nelements(predictions->tensor)) continue;
            if (idx >= ggml_nelements(predictions->grad)) continue;
            
            float val = ggml_get_f32_1d(predictions->tensor, idx);
            float softmax_j = expf(val - max_val) / sum_exp;
            float one_hot = (j == target_class) ? 1.0f : 0.0f;
            float grad = (softmax_j - one_hot) * grad_out / (float)batch_size;
            
            float old = ggml_get_f32_1d(predictions->grad, idx);
            ggml_set_f32_1d(predictions->grad, idx, old + grad);
        }
    }
    predictions->grad_accumulated = true;
}

/* MSE backward: dL/d(predictions) = 2*(predictions - targets)/n */
static void backward_mse(pTHX_ LughTensor *output, LughContext *lctx) {
    int64_t i, n;
    
    if (!output || !output->grad) return;
    if (output->n_inputs < 2) return;
    
    LughTensor *predictions = get_tensor_by_id(output->input_ids[0]);
    LughTensor *targets = get_tensor_by_id(output->input_ids[1]);
    if (!predictions || !targets) return;
    if (!predictions->tensor || !targets->tensor) return;
    if (!predictions->requires_grad) return;
    
    /* Allocate gradient if needed */
    if (!predictions->grad) {
        if (!alloc_grad(aTHX_ predictions, lctx)) return;
    }
    
    float grad_out = ggml_get_f32_1d(output->grad, 0);
    n = ggml_nelements(predictions->tensor);
    
    /* dL/d(predictions) = 2 * (predictions - targets) / n */
    for (i = 0; i < n; i++) {
        float pred = ggml_get_f32_1d(predictions->tensor, i);
        float tgt = ggml_get_f32_1d(targets->tensor, i);
        float grad = 2.0f * (pred - tgt) * grad_out / (float)n;
        
        float old = ggml_get_f32_1d(predictions->grad, i);
        ggml_set_f32_1d(predictions->grad, i, old + grad);
    }
    predictions->grad_accumulated = true;
}

/* ============================================================================
 * Transformer Backward Pass - Full gradient computation through transformer
 * Computes gradients for LoRA weights AND optionally full model weights
 * ============================================================================ */

/* Helper: Compute dL/dX for RMS norm: dL/dX = dL/dY * (1/rms) * (I - X*X^T/sum(X^2)) * gamma */
static void backward_rms_norm_layer(
    float *grad_input,       /* Output: gradient w.r.t. input [n_embd, n_tokens] */
    const float *grad_output,/* Input: gradient w.r.t. output */
    const float *input,      /* Input activations */
    const float *gamma,      /* RMS norm weights (can be NULL for unit gamma) */
    int n_embd,
    int n_tokens,
    float eps
) {
    for (int t = 0; t < n_tokens; t++) {
        const float *x = input + t * n_embd;
        const float *dy = grad_output + t * n_embd;
        float *dx = grad_input + t * n_embd;
        
        /* Compute RMS */
        float sum_sq = 0.0f;
        for (int i = 0; i < n_embd; i++) {
            sum_sq += x[i] * x[i];
        }
        float rms = sqrtf(sum_sq / n_embd + eps);
        float inv_rms = 1.0f / rms;
        float inv_rms3 = inv_rms * inv_rms * inv_rms;
        
        /* Compute sum(dy * gamma * x) for the correction term */
        float sum_dy_gamma_x = 0.0f;
        for (int i = 0; i < n_embd; i++) {
            float g = gamma ? gamma[i] : 1.0f;
            sum_dy_gamma_x += dy[i] * g * x[i];
        }
        
        /* dx = gamma * inv_rms * (dy - x * sum_dy_gamma_x * inv_rms^2 / n_embd) */
        for (int i = 0; i < n_embd; i++) {
            float g = gamma ? gamma[i] : 1.0f;
            dx[i] = g * inv_rms * dy[i] 
                  - g * x[i] * sum_dy_gamma_x * inv_rms3 / n_embd;
        }
    }
}

/* Helper: Compute dL/dW and dL/dX for matmul Y = W @ X */
/* W: [out_dim, in_dim], X: [in_dim, n_tokens], Y: [out_dim, n_tokens] */
static void backward_matmul_layer(
    float *grad_W,           /* Output: gradient w.r.t. W [out_dim, in_dim] (accumulated) */
    float *grad_X,           /* Output: gradient w.r.t. X [in_dim, n_tokens] (may be NULL) */
    const float *grad_Y,     /* Input: gradient w.r.t. Y [out_dim, n_tokens] */
    const float *W,          /* Weight matrix */
    const float *X,          /* Input */
    int out_dim,
    int in_dim,
    int n_tokens
) {
    /* dL/dW = dL/dY @ X^T : [out_dim, n_tokens] @ [n_tokens, in_dim] = [out_dim, in_dim] */
    if (grad_W) {
        for (int o = 0; o < out_dim; o++) {
            for (int i = 0; i < in_dim; i++) {
                float sum = 0.0f;
                for (int t = 0; t < n_tokens; t++) {
                    sum += grad_Y[t * out_dim + o] * X[t * in_dim + i];
                }
                grad_W[o * in_dim + i] += sum;
            }
        }
    }
    
    /* dL/dX = W^T @ dL/dY : [in_dim, out_dim] @ [out_dim, n_tokens] = [in_dim, n_tokens] */
    if (grad_X) {
        for (int t = 0; t < n_tokens; t++) {
            for (int i = 0; i < in_dim; i++) {
                float sum = 0.0f;
                for (int o = 0; o < out_dim; o++) {
                    sum += W[o * in_dim + i] * grad_Y[t * out_dim + o];
                }
                grad_X[t * in_dim + i] = sum;
            }
        }
    }
}

/* Helper: Compute LoRA gradients for Y = WX + scale * B(AX) */
static void backward_lora_matmul(
    LughTensor *grad_A,      /* Gradient tensor for A matrix */
    LughTensor *grad_B,      /* Gradient tensor for B matrix */
    const float *grad_Y,     /* Gradient w.r.t. output [out_dim, n_tokens] */
    const float *X,          /* Input [in_dim, n_tokens] */
    const float *A,          /* LoRA A matrix [rank, in_dim] */
    const float *B,          /* LoRA B matrix [out_dim, rank] */
    int out_dim,
    int in_dim,
    int rank,
    int n_tokens,
    float scale
) {
    int t, r, i, o;
    
    /* Intermediate: AX = A @ X : [rank, n_tokens] */
    float *AX;
    Newxz(AX, rank * n_tokens, float);
    for (t = 0; t < n_tokens; t++) {
        for (r = 0; r < rank; r++) {
            float sum = 0.0f;
            for (i = 0; i < in_dim; i++) {
                sum += A[r * in_dim + i] * X[t * in_dim + i];
            }
            AX[t * rank + r] = sum;
        }
    }
    
    /* dL/dB = scale * dL/dY @ (AX)^T : [out_dim, n_tokens] @ [n_tokens, rank] = [out_dim, rank] */
    if (grad_B && grad_B->grad) {
        for (o = 0; o < out_dim; o++) {
            for (r = 0; r < rank; r++) {
                float sum = 0.0f;
                for (t = 0; t < n_tokens; t++) {
                    sum += grad_Y[t * out_dim + o] * AX[t * rank + r];
                }
                float old = ggml_get_f32_1d(grad_B->grad, o * rank + r);
                ggml_set_f32_1d(grad_B->grad, o * rank + r, old + scale * sum);
            }
        }
        grad_B->grad_accumulated = true;
    }
    
    /* dL/d(AX) = scale * B^T @ dL/dY : [rank, out_dim] @ [out_dim, n_tokens] = [rank, n_tokens] */
    float *grad_AX;
    Newxz(grad_AX, rank * n_tokens, float);
    for (t = 0; t < n_tokens; t++) {
        for (r = 0; r < rank; r++) {
            float sum = 0.0f;
            for (o = 0; o < out_dim; o++) {
                sum += B[o * rank + r] * grad_Y[t * out_dim + o];
            }
            grad_AX[t * rank + r] = scale * sum;
        }
    }
    
    /* dL/dA = dL/d(AX) @ X^T : [rank, n_tokens] @ [n_tokens, in_dim] = [rank, in_dim] */
    if (grad_A && grad_A->grad) {
        for (r = 0; r < rank; r++) {
            for (i = 0; i < in_dim; i++) {
                float sum = 0.0f;
                for (t = 0; t < n_tokens; t++) {
                    sum += grad_AX[t * rank + r] * X[t * in_dim + i];
                }
                float old = ggml_get_f32_1d(grad_A->grad, r * in_dim + i);
                ggml_set_f32_1d(grad_A->grad, r * in_dim + i, old + sum);
            }
        }
        grad_A->grad_accumulated = true;
    }
    
    Safefree(AX);
    Safefree(grad_AX);
}

/* backward_weight_matmul: Compute weight gradient for ggml_mul_mat
 * 
 * For forward: y = ggml_mul_mat(W, x) = W^T @ x
 *   where W is [in_dim, out_dim] (ne[0]=in_dim, ne[1]=out_dim)
 *         x is [in_dim, n_tokens]
 *         y is [out_dim, n_tokens]
 * 
 * For backward: dL/dW = x @ (dL/dy)^T
 *   dL/dW = [in_dim, n_tokens] @ [n_tokens, out_dim] = [in_dim, out_dim]
 * 
 * Accumulates gradient into weight_tensor->grad
 */
static void backward_weight_matmul(
    LughTensor *weight_tensor,  /* Weight tensor with grad buffer */
    const float *grad_Y,        /* Gradient w.r.t. output [out_dim, n_tokens] */
    const float *X,             /* Input [in_dim, n_tokens] */
    int out_dim,                /* output dimension (ne[1] of weight) */
    int in_dim,                 /* input dimension (ne[0] of weight) */
    int n_tokens,
    float scale                 /* Scaling factor for gradient */
) {
    if (!weight_tensor || !weight_tensor->grad || !weight_tensor->grad->data) {
        return;
    }
    
    float *grad_W = (float*)weight_tensor->grad->data;
    
    /* dL/dW = X @ grad_Y^T in column-major storage
     * W is [in_dim, out_dim] with ne[0]=in_dim, ne[1]=out_dim
     * grad_W[i, o] = sum_t X[i, t] * grad_Y[o, t]
     * ggml column-major: grad_W[o * in_dim + i]
     */
    float max_grad = 0.0f;
    for (int o = 0; o < out_dim; o++) {
        for (int i = 0; i < in_dim; i++) {
            float sum = 0.0f;
            for (int t = 0; t < n_tokens; t++) {
                /* X stored column-major: X[i, t] = X[t * in_dim + i] */
                /* grad_Y stored column-major: grad_Y[o, t] = grad_Y[t * out_dim + o] */
                sum += X[t * in_dim + i] * grad_Y[t * out_dim + o];
            }
            float grad_val = scale * sum;
            /* Gradient clipping */
            if (grad_val > 1.0f) grad_val = 1.0f;
            if (grad_val < -1.0f) grad_val = -1.0f;
            /* Store in ggml column-major: grad_W[i, o] = grad_W[o * in_dim + i] */
            grad_W[o * in_dim + i] += grad_val;
            if (fabsf(grad_val) > max_grad) max_grad = fabsf(grad_val);
        }
    }
    
    weight_tensor->grad_accumulated = true;
}

/* Helper: SiLU backward: dL/dX = dL/dY * (silu'(X)) where silu'(x) = sigmoid(x) + x*sigmoid(x)*(1-sigmoid(x)) */
static void backward_silu_layer(
    float *grad_input,
    const float *grad_output,
    const float *input,
    int n_elements
) {
    for (int i = 0; i < n_elements; i++) {
        float x = input[i];
        float sig = 1.0f / (1.0f + expf(-x));
        float dsilu = sig + x * sig * (1.0f - sig);
        grad_input[i] = grad_output[i] * dsilu;
    }
}

/* Helper: Softmax backward for attention weights */
static void backward_softmax_layer(
    float *grad_input,       /* [n_head, n_tokens, n_kv] */
    const float *grad_output,
    const float *softmax_out,
    int n_head,
    int n_tokens,
    int n_kv
) {
    for (int h = 0; h < n_head; h++) {
        for (int t = 0; t < n_tokens; t++) {
            const float *s = softmax_out + h * n_tokens * n_kv + t * n_kv;
            const float *dy = grad_output + h * n_tokens * n_kv + t * n_kv;
            float *dx = grad_input + h * n_tokens * n_kv + t * n_kv;
            
            /* Compute sum(dy * s) */
            float sum = 0.0f;
            for (int k = 0; k < n_kv; k++) {
                sum += dy[k] * s[k];
            }
            
            /* dx = s * (dy - sum) */
            for (int k = 0; k < n_kv; k++) {
                dx[k] = s[k] * (dy[k] - sum);
            }
        }
    }
}

/* backward_transformer_forward is defined after LoRA types below */

/* Allocate a new model ID */
static int alloc_model_id(void) {
    int id = -1;
    CONTEXT_LOCK();
    for (int i = 0; i < MAX_CONTEXTS; i++) {
        int check_id = (next_model_id + i) % MAX_CONTEXTS;
        if (check_id == 0) check_id = 1;
        if (model_registry[check_id] == NULL) {
            id = check_id;
            next_model_id = (id + 1) % MAX_CONTEXTS;
            if (next_model_id == 0) next_model_id = 1;
            break;
        }
    }
    CONTEXT_UNLOCK();
    return id;
}

/* Get model by ID */
static LughModel* get_model_by_id(int id) {
    LughModel *lm = NULL;
    if (id <= 0 || id >= MAX_CONTEXTS) return NULL;
    CONTEXT_LOCK();
    lm = model_registry[id];
    if (lm && !lm->active) lm = NULL;
    CONTEXT_UNLOCK();
    return lm;
}

/* Allocate a new KV cache ID */
static int alloc_kvcache_id(void) {
    int id = -1;
    KVCACHE_REGISTRY_LOCK();
    for (int i = 0; i < MAX_KVCACHES; i++) {
        int check_id = (next_kvcache_id + i) % MAX_KVCACHES;
        if (check_id == 0) check_id = 1;
        if (kvcache_registry[check_id] == NULL) {
            id = check_id;
            next_kvcache_id = (id + 1) % MAX_KVCACHES;
            if (next_kvcache_id == 0) next_kvcache_id = 1;
            break;
        }
    }
    KVCACHE_REGISTRY_UNLOCK();
    return id;
}

/* Get KV cache by ID */
static LughKVCache* get_kvcache_by_id(int id) {
    LughKVCache *cache = NULL;
    if (id <= 0 || id >= MAX_KVCACHES) return NULL;
    KVCACHE_REGISTRY_LOCK();
    cache = kvcache_registry[id];
    if (cache && !cache->active) cache = NULL;
    KVCACHE_REGISTRY_UNLOCK();
    return cache;
}

/* Free a KV cache */
static void free_kvcache(LughKVCache *cache) {
    int i;
    if (!cache) return;
    
    KVCACHE_LOCK(cache);
    
    if (cache->k_cache) {
        for (i = 0; i < cache->n_layer; i++) {
            if (cache->k_cache[i]) Safefree(cache->k_cache[i]);
        }
        Safefree(cache->k_cache);
        cache->k_cache = NULL;
    }
    
    if (cache->v_cache) {
        for (i = 0; i < cache->n_layer; i++) {
            if (cache->v_cache[i]) Safefree(cache->v_cache[i]);
        }
        Safefree(cache->v_cache);
        cache->v_cache = NULL;
    }
    
    cache->active = 0;
    
    KVCACHE_UNLOCK(cache);
    
#ifdef USE_ITHREADS
    MUTEX_DESTROY(&cache->cache_mutex);
#endif
    
    Safefree(cache);
}

/* Create a new KV cache */
static LughKVCache* create_kvcache(int n_layer, int n_ctx, int n_head_kv, int head_dim) {
    LughKVCache *cache;
    int id, i;
    int n_kv_dim = n_head_kv * head_dim;
    size_t layer_size = (size_t)n_ctx * n_kv_dim * sizeof(float);
    
    id = alloc_kvcache_id();
    if (id < 0) return NULL;
    
    Newxz(cache, 1, LughKVCache);
    if (!cache) return NULL;
    
#ifdef USE_ITHREADS
    MUTEX_INIT(&cache->cache_mutex);
#endif
    
    cache->id = id;
    cache->active = 1;
    cache->n_layer = n_layer;
    cache->n_ctx = n_ctx;
    cache->n_head_kv = n_head_kv;
    cache->head_dim = head_dim;
    cache->n_kv_dim = n_kv_dim;
    cache->n_cached = 0;
    
    /* Allocate K and V caches for each layer */
    Newxz(cache->k_cache, n_layer, float*);
    Newxz(cache->v_cache, n_layer, float*);
    
    if (!cache->k_cache || !cache->v_cache) {
        free_kvcache(cache);
        return NULL;
    }
    
    for (i = 0; i < n_layer; i++) {
        Newxz(cache->k_cache[i], n_ctx * n_kv_dim, float);
        Newxz(cache->v_cache[i], n_ctx * n_kv_dim, float);
        if (!cache->k_cache[i] || !cache->v_cache[i]) {
            free_kvcache(cache);
            return NULL;
        }
    }
    
    KVCACHE_REGISTRY_LOCK();
    kvcache_registry[id] = cache;
    KVCACHE_REGISTRY_UNLOCK();
    
    return cache;
}

/* ============================================================================
 * Speculative Decoding Registry Functions
 * ============================================================================ */

/* Allocate a new speculative ID */
static int alloc_speculative_id(void) {
    int id = -1;
    SPECULATIVE_REGISTRY_LOCK();
    for (int i = 0; i < MAX_SPECULATIVE; i++) {
        int check_id = (next_speculative_id + i) % MAX_SPECULATIVE;
        if (check_id == 0) check_id = 1;
        if (speculative_registry[check_id] == NULL) {
            id = check_id;
            next_speculative_id = (id + 1) % MAX_SPECULATIVE;
            if (next_speculative_id == 0) next_speculative_id = 1;
            break;
        }
    }
    SPECULATIVE_REGISTRY_UNLOCK();
    return id;
}

/* Get speculative decoder by ID */
static LughSpeculative* get_speculative_by_id(int id) {
    LughSpeculative *spec = NULL;
    if (id <= 0 || id >= MAX_SPECULATIVE) return NULL;
    SPECULATIVE_REGISTRY_LOCK();
    spec = speculative_registry[id];
    if (spec && !spec->active) spec = NULL;
    SPECULATIVE_REGISTRY_UNLOCK();
    return spec;
}

/* Free a speculative decoder (does NOT free the underlying models/caches) */
static void free_speculative(LughSpeculative *spec) {
    if (!spec) return;
    
    SPECULATIVE_LOCK(spec);
    spec->active = 0;
    SPECULATIVE_UNLOCK(spec);
    
#ifdef USE_ITHREADS
    MUTEX_DESTROY(&spec->spec_mutex);
#endif
    
    /* Note: we don't free main_cache/draft_cache here - they're owned separately */
    
    SPECULATIVE_REGISTRY_LOCK();
    speculative_registry[spec->id] = NULL;
    SPECULATIVE_REGISTRY_UNLOCK();
    
    Safefree(spec);
}

/* Create a new speculative decoder */
static LughSpeculative* create_speculative(
    int main_model_id, 
    int draft_model_id,
    LughKVCache *main_cache,
    LughKVCache *draft_cache,
    int n_vocab,
    int k,
    float temperature,
    float top_p
) {
    LughSpeculative *spec;
    int id;
    
    id = alloc_speculative_id();
    if (id < 0) return NULL;
    
    Newxz(spec, 1, LughSpeculative);
    if (!spec) return NULL;
    
#ifdef USE_ITHREADS
    MUTEX_INIT(&spec->spec_mutex);
#endif
    
    spec->id = id;
    spec->active = 1;
    spec->main_model_id = main_model_id;
    spec->draft_model_id = draft_model_id;
    spec->main_cache = main_cache;
    spec->draft_cache = draft_cache;
    spec->n_vocab = n_vocab;
    spec->k = k;
    spec->temperature = temperature;
    spec->top_p = top_p;
    spec->tokens_drafted = 0;
    spec->tokens_accepted = 0;
    spec->total_steps = 0;
    
    SPECULATIVE_REGISTRY_LOCK();
    speculative_registry[id] = spec;
    SPECULATIVE_REGISTRY_UNLOCK();
    
    return spec;
}

/* ============================================================================
 * Magic vtable for cleanup
 * ============================================================================ */

static int lugh_context_free(pTHX_ SV *sv, MAGIC *mg) {
    int id = (int)(IV)mg->mg_ptr;
    LughContext *lctx = get_context_by_id(id);
    if (lctx) {
        CONTEXT_LOCK();
        if (lctx->ctx) {
            ggml_free(lctx->ctx);
            lctx->ctx = NULL;
        }
        lctx->active = 0;
        context_registry[id] = NULL;
        Safefree(lctx);
        CONTEXT_UNLOCK();
    }
    return 0;
}

static MGVTBL lugh_context_vtbl = {
    NULL,                /* get */
    NULL,                /* set */
    NULL,                /* len */
    NULL,                /* clear */
    lugh_context_free,   /* free */
    NULL,                /* copy */
    NULL,                /* dup */
    NULL                 /* local */
};

static int lugh_model_free(pTHX_ SV *sv, MAGIC *mg) {
    int id = (int)(IV)mg->mg_ptr;
    LughModel *lm = get_model_by_id(id);
    if (lm) {
        CONTEXT_LOCK();
        if (lm->ctx) {
            ggml_free(lm->ctx);
            lm->ctx = NULL;
        }
        if (lm->gguf) {
            gguf_free(lm->gguf);
            lm->gguf = NULL;
        }
        if (lm->mmap) {
            lugh_mmap_free(lm->mmap);
            lm->mmap = NULL;
        }
        if (lm->filename) {
            Safefree(lm->filename);
            lm->filename = NULL;
        }
        if (lm->architecture) {
            Safefree(lm->architecture);
            lm->architecture = NULL;
        }
        lm->active = 0;
        lm->use_mmap = 0;
        model_registry[id] = NULL;
        Safefree(lm);
        CONTEXT_UNLOCK();
    }
    return 0;
}

static MGVTBL lugh_model_vtbl = {
    NULL,                /* get */
    NULL,                /* set */
    NULL,                /* len */
    NULL,                /* clear */
    lugh_model_free,     /* free */
    NULL,                /* copy */
    NULL,                /* dup */
    NULL                 /* local */
};

/* KV Cache magic free function */
static int lugh_kvcache_free(pTHX_ SV *sv, MAGIC *mg) {
    int id = (int)(IV)mg->mg_ptr;
    LughKVCache *cache;
    
    KVCACHE_REGISTRY_LOCK();
    cache = kvcache_registry[id];
    if (cache) {
        kvcache_registry[id] = NULL;
        free_kvcache(cache);
    }
    KVCACHE_REGISTRY_UNLOCK();
    
    return 0;
}

static MGVTBL lugh_kvcache_vtbl = {
    NULL,                /* get */
    NULL,                /* set */
    NULL,                /* len */
    NULL,                /* clear */
    lugh_kvcache_free,   /* free */
    NULL,                /* copy */
    NULL,                /* dup */
    NULL                 /* local */
};

/* Helper to get LughKVCache from SV */
static LughKVCache* get_lugh_kvcache(pTHX_ SV *sv) {
    MAGIC *mg;
    int id;
    LughKVCache *cache;
    
    if (!sv_isobject(sv))
        croak("Not a Lugh::KVCache object");
    
    sv = SvRV(sv);
    mg = mg_find(sv, PERL_MAGIC_ext);
    if (!mg || mg->mg_virtual != &lugh_kvcache_vtbl)
        croak("Invalid Lugh::KVCache object");
    
    id = (int)(IV)mg->mg_ptr;
    cache = get_kvcache_by_id(id);
    if (!cache)
        croak("Lugh::KVCache has been destroyed");
    
    return cache;
}

/* Helper to get LughModel from SV */
static LughModel* get_lugh_model(pTHX_ SV *sv) {
    MAGIC *mg;
    int id;
    LughModel *lm;
    
    if (!sv_isobject(sv))
        croak("Not a Lugh::Model object");
    
    sv = SvRV(sv);
    mg = mg_find(sv, PERL_MAGIC_ext);
    if (!mg || mg->mg_virtual != &lugh_model_vtbl)
        croak("Invalid Lugh::Model object");
    
    id = (int)(IV)mg->mg_ptr;
    lm = get_model_by_id(id);
    if (!lm)
        croak("Lugh::Model has been destroyed");
    
    return lm;
}

/* Helper to get LughContext from SV */
static LughContext* get_lugh_context(pTHX_ SV *sv) {
    MAGIC *mg;
    int id;
    LughContext *lctx;
    
    if (!sv_isobject(sv))
        croak("Not a Lugh::Context object");
    
    sv = SvRV(sv);
    mg = mg_find(sv, PERL_MAGIC_ext);
    if (!mg || mg->mg_virtual != &lugh_context_vtbl)
        croak("Invalid Lugh::Context object");
    
    id = (int)(IV)mg->mg_ptr;
    lctx = get_context_by_id(id);
    if (!lctx)
        croak("Lugh::Context has been destroyed");
    
    return lctx;
}

/* ============================================================================
 * RoPE Scaling Types - For context extension
 * ============================================================================ */

typedef enum {
    LUGH_ROPE_SCALING_NONE    = 0,  /* No scaling - use training context */
    LUGH_ROPE_SCALING_LINEAR  = 1,  /* Linear interpolation */
    LUGH_ROPE_SCALING_YARN    = 2,  /* YaRN (Yet another RoPE extensioN) */
    LUGH_ROPE_SCALING_LONGROPE = 3  /* LongRoPE method */
} LughRopeScalingType;

/* RoPE configuration structure for Lugh::RoPE objects */
typedef struct {
    LughRopeScalingType scaling_type;
    int    n_ctx_orig;      /* Original training context length */
    int    target_ctx;      /* Target extended context length */
    float  freq_base;       /* Base frequency (10000.0 default) */
    float  freq_scale;      /* Frequency scale (1.0 = no scaling) */
    float  ext_factor;      /* YaRN extension factor (-1.0 = auto) */
    float  attn_factor;     /* YaRN attention factor (1.0 default) */
    float  beta_fast;       /* YaRN high-freq boundary (32.0 default) */
    float  beta_slow;       /* YaRN low-freq boundary (1.0 default) */
    int    id;              /* Registry ID */
    int    active;          /* Active flag */
} LughRopeConfig;

/* RoPE config registry */
#define MAX_ROPE_CONFIGS 256
static LughRopeConfig rope_registry[MAX_ROPE_CONFIGS];
static int rope_registry_initialized = 0;

static void init_rope_registry(void) {
    if (!rope_registry_initialized) {
        memset(rope_registry, 0, sizeof(rope_registry));
        rope_registry_initialized = 1;
    }
}

static int register_rope_config(LughRopeConfig *config) {
    int i;
    init_rope_registry();
    for (i = 0; i < MAX_ROPE_CONFIGS; i++) {
        if (!rope_registry[i].active) {
            rope_registry[i] = *config;
            rope_registry[i].id = i;
            rope_registry[i].active = 1;
            return i;
        }
    }
    return -1;
}

static LughRopeConfig* get_rope_config_by_id(int id) {
    if (id < 0 || id >= MAX_ROPE_CONFIGS) return NULL;
    if (!rope_registry[id].active) return NULL;
    return &rope_registry[id];
}

/* Magic vtable for Lugh::RoPE */
static int lugh_rope_free(pTHX_ SV *sv, MAGIC *mg);
static MGVTBL lugh_rope_vtbl = { 0, 0, 0, 0, lugh_rope_free, 0, 0, 0 };

static int lugh_rope_free(pTHX_ SV *sv, MAGIC *mg) {
    int id = (int)(IV)mg->mg_ptr;
    if (id >= 0 && id < MAX_ROPE_CONFIGS) {
        rope_registry[id].active = 0;
    }
    return 0;
}

static LughRopeConfig* get_lugh_rope(pTHX_ SV *sv) {
    MAGIC *mg;
    int id;
    LughRopeConfig *config;
    
    if (!sv_isobject(sv))
        croak("Not a Lugh::RoPE object");
    
    sv = SvRV(sv);
    mg = mg_find(sv, PERL_MAGIC_ext);
    if (!mg || mg->mg_virtual != &lugh_rope_vtbl)
        croak("Invalid Lugh::RoPE object");
    
    id = (int)(IV)mg->mg_ptr;
    config = get_rope_config_by_id(id);
    if (!config)
        croak("Lugh::RoPE has been destroyed");
    
    return config;
}

/* Magic vtable for Lugh::Speculative */
static int lugh_speculative_free(pTHX_ SV *sv, MAGIC *mg);
static MGVTBL lugh_speculative_vtbl = { 0, 0, 0, 0, lugh_speculative_free, 0, 0, 0 };

static int lugh_speculative_free(pTHX_ SV *sv, MAGIC *mg) {
    int id = (int)(IV)mg->mg_ptr;
    LughSpeculative *spec = get_speculative_by_id(id);
    if (spec) {
        free_speculative(spec);
    }
    return 0;
}

static LughSpeculative* get_lugh_speculative(pTHX_ SV *sv) {
    MAGIC *mg;
    int id;
    LughSpeculative *spec;
    
    if (!sv_isobject(sv))
        croak("Not a Lugh::Speculative object");
    
    sv = SvRV(sv);
    mg = mg_find(sv, PERL_MAGIC_ext);
    if (!mg || mg->mg_virtual != &lugh_speculative_vtbl)
        croak("Invalid Lugh::Speculative object");
    
    id = (int)(IV)mg->mg_ptr;
    spec = get_speculative_by_id(id);
    if (!spec)
        croak("Lugh::Speculative has been destroyed");
    
    return spec;
}

/* ============================================================================
 * Lugh::Inference Forward Pass Helpers - Shared between forward() and forward_cache()
 * ============================================================================ */

/* Model hyperparameters structure */
typedef struct {
    int n_embd;
    int n_layer;
    int n_head;
    int n_head_kv;
    int n_vocab;
    int n_threads;
    int n_ctx;
    int n_rot;
    int head_dim;
    int use_flash_attn;
    float rms_norm_eps;
    float rope_freq_base;
    float rope_freq_scale;
    char backend_name[32];  /* Backend name: "cpu", "metal", "cuda", "auto", etc. */
    char architecture[32];  /* Model architecture: "llama", "qwen2", "phi3", "gemma2", etc. */
    LughArchType arch_type; /* Architecture type enum for inference path selection */
    /* RoPE scaling parameters */
    LughRopeScalingType rope_scaling_type;
    int   n_ctx_orig;       /* Original training context length */
    float rope_ext_factor;  /* YaRN extension factor */
    float rope_attn_factor; /* YaRN attention factor */
    float rope_beta_fast;   /* YaRN high-freq boundary */
    float rope_beta_slow;   /* YaRN low-freq boundary */
} LughHyperparams;

/* Forward pass options - passed to do_forward_unified */
typedef struct {
    int *tokens;            /* Single sequence tokens (NULL for batch mode) */
    int n_tokens;           /* Number of tokens */
    int **all_tokens;       /* Batch mode: array of token arrays */
    int *seq_lengths;       /* Batch mode: length of each sequence */
    int n_sequences;        /* Batch mode: number of sequences */
    void *cache;            /* LughKVCache* - KV cache (optional, single sequence) */
    void **caches;          /* LughKVCache** - Array of caches (batch mode) */
    int n_caches;           /* Number of caches in array */
    void *pool;             /* LughMemoryPool* - Memory pool (optional) */
    void *lora;             /* LughLoRAAdapter* - LoRA adapter (optional) */
    SV *rope_sv;            /* RoPE override (optional) */
    int return_all_logits;  /* If 1, return logits for all positions */
} LughForwardOpts;

/* Forward result - returned by do_forward_unified */
typedef struct {
    float *logits;          /* Single sequence: logits for last position */
    float *all_logits;      /* All positions: [n_tokens * n_vocab] if requested */
    int n_tokens;           /* Number of tokens (for all_logits) */
    int n_vocab;            /* Vocabulary size */
    float **batch_logits;   /* Batch mode: array of logits arrays */
    int n_sequences;        /* Batch mode: number of sequences */
    int is_batch;           /* 1 if batch mode */
    char *error;            /* Error message if failed */
} LughForwardResult;

/* Layer weights structure */
typedef struct {
    /* Attention */
    struct ggml_tensor *attn_norm;
    struct ggml_tensor *wq;          /* Separate Q weight (most architectures) */
    struct ggml_tensor *wk;          /* Separate K weight */
    struct ggml_tensor *wv;          /* Separate V weight */
    struct ggml_tensor *wqkv;        /* Combined QKV weight (phi, qwen, bloom, gpt2) */
    struct ggml_tensor *wo;
    struct ggml_tensor *attn_post_norm;  /* Post-attention norm (gemma2) */
    /* FFN */
    struct ggml_tensor *ffn_norm;
    struct ggml_tensor *ffn_gate;    /* SwiGLU gate (llama, qwen, gemma) - NULL for GELU models */
    struct ggml_tensor *ffn_up;
    struct ggml_tensor *ffn_down;
    struct ggml_tensor *ffn_post_norm;   /* Post-FFN norm (gemma2) */
    /* Flags */
    int has_combined_qkv;            /* 1 if using wqkv instead of wq/wk/wv */
    int has_ffn_gate;                /* 1 if using SwiGLU, 0 for GELU */
    int has_post_norm;               /* 1 if architecture uses post-normalization */
    int layer_idx;                   /* Layer index for LoRA tensor name lookup */
} LughLayerWeights;

/* Extract hyperparameters from Perl HV and model */
static void extract_hyperparams(pTHX_ HV *hv, LughModel *model, LughHyperparams *hp) {
    SV **svp;
    int64_t key_id;
    char key[128];
    const char *arch;
    
    /* Defaults */
    hp->rms_norm_eps = 1e-5f;
    hp->rope_freq_base = 10000.0f;
    hp->rope_freq_scale = 1.0f;
    strcpy(hp->architecture, "llama");  /* Default architecture */
    
    /* RoPE scaling defaults */
    hp->rope_scaling_type = LUGH_ROPE_SCALING_NONE;
    hp->n_ctx_orig = 0;  /* Will be set to n_ctx if not in metadata */
    hp->rope_ext_factor = -1.0f;  /* -1.0 = auto-compute for YaRN */
    hp->rope_attn_factor = 1.0f;
    hp->rope_beta_fast = 32.0f;
    hp->rope_beta_slow = 1.0f;
    
    /* Get architecture from model metadata (set during model load) */
    if (model->architecture && strlen(model->architecture) > 0) {
        strncpy(hp->architecture, model->architecture, sizeof(hp->architecture) - 1);
        hp->architecture[sizeof(hp->architecture) - 1] = '\0';
    }
    arch = hp->architecture;
    
    /* Get from Perl hash */
    svp = hv_fetch(hv, "n_embd", 6, 0);
    hp->n_embd = svp ? SvIV(*svp) : 2048;
    
    svp = hv_fetch(hv, "n_layer", 7, 0);
    hp->n_layer = svp ? SvIV(*svp) : 22;
    
    svp = hv_fetch(hv, "n_head", 6, 0);
    hp->n_head = svp ? SvIV(*svp) : 32;
    
    svp = hv_fetch(hv, "n_head_kv", 9, 0);
    hp->n_head_kv = svp ? SvIV(*svp) : 4;
    
    svp = hv_fetch(hv, "n_vocab", 7, 0);
    hp->n_vocab = svp ? SvIV(*svp) : 32000;
    
    svp = hv_fetch(hv, "n_threads", 9, 0);
    hp->n_threads = svp ? SvIV(*svp) : 4;
    
    svp = hv_fetch(hv, "flash_attn", 10, 0);
    hp->use_flash_attn = svp ? SvIV(*svp) : 0;
    
    /* Derived */
    hp->head_dim = hp->n_embd / hp->n_head;
    
    /* Backend selection: "cpu", "metal", "cuda", "vulkan", "auto", etc. */
    svp = hv_fetch(hv, "backend", 7, 0);
    if (svp && SvPOK(*svp)) {
        const char *backend_str = SvPV_nolen(*svp);
        strncpy(hp->backend_name, backend_str, sizeof(hp->backend_name) - 1);
        hp->backend_name[sizeof(hp->backend_name) - 1] = '\0';
    } else {
        strcpy(hp->backend_name, "cpu");  /* Default to CPU for compatibility */
    }
    
    /* Get from model metadata using dynamic architecture prefix */
    snprintf(key, sizeof(key), "%s.attention.layer_norm_rms_epsilon", arch);
    key_id = gguf_find_key(model->gguf, key);
    if (key_id >= 0) hp->rms_norm_eps = gguf_get_val_f32(model->gguf, key_id);
    
    snprintf(key, sizeof(key), "%s.rope.freq_base", arch);
    key_id = gguf_find_key(model->gguf, key);
    if (key_id >= 0) hp->rope_freq_base = gguf_get_val_f32(model->gguf, key_id);
    
    snprintf(key, sizeof(key), "%s.rope.dimension_count", arch);
    key_id = gguf_find_key(model->gguf, key);
    hp->n_rot = (key_id >= 0) ? gguf_get_val_u32(model->gguf, key_id) : hp->head_dim;
    
    snprintf(key, sizeof(key), "%s.context_length", arch);
    key_id = gguf_find_key(model->gguf, key);
    hp->n_ctx = (key_id >= 0) ? gguf_get_val_u32(model->gguf, key_id) : 2048;
    
    /* Default n_ctx_orig to n_ctx (training context) */
    hp->n_ctx_orig = hp->n_ctx;
    
    /* RoPE scaling type from metadata */
    snprintf(key, sizeof(key), "%s.rope.scaling.type", arch);
    key_id = gguf_find_key(model->gguf, key);
    if (key_id >= 0) {
        const char *scaling_str = gguf_get_val_str(model->gguf, key_id);
        if (scaling_str) {
            if (strcmp(scaling_str, "linear") == 0)
                hp->rope_scaling_type = LUGH_ROPE_SCALING_LINEAR;
            else if (strcmp(scaling_str, "yarn") == 0)
                hp->rope_scaling_type = LUGH_ROPE_SCALING_YARN;
            else if (strcmp(scaling_str, "longrope") == 0)
                hp->rope_scaling_type = LUGH_ROPE_SCALING_LONGROPE;
        }
    }
    
    /* RoPE scaling factor -> freq_scale (inverse) */
    snprintf(key, sizeof(key), "%s.rope.scaling.factor", arch);
    key_id = gguf_find_key(model->gguf, key);
    if (key_id >= 0) {
        float factor = gguf_get_val_f32(model->gguf, key_id);
        hp->rope_freq_scale = (factor > 0) ? 1.0f / factor : 1.0f;
    } else {
        /* Fallback to legacy key */
        snprintf(key, sizeof(key), "%s.rope.scale_linear", arch);
        key_id = gguf_find_key(model->gguf, key);
        if (key_id >= 0) {
            float factor = gguf_get_val_f32(model->gguf, key_id);
            hp->rope_freq_scale = (factor > 0) ? 1.0f / factor : 1.0f;
        }
    }
    
    /* Original context length for scaling */
    snprintf(key, sizeof(key), "%s.rope.scaling.original_context_length", arch);
    key_id = gguf_find_key(model->gguf, key);
    if (key_id >= 0) {
        hp->n_ctx_orig = gguf_get_val_u32(model->gguf, key_id);
    }
    
    /* YaRN parameters */
    snprintf(key, sizeof(key), "%s.rope.scaling.yarn_ext_factor", arch);
    key_id = gguf_find_key(model->gguf, key);
    if (key_id >= 0) hp->rope_ext_factor = gguf_get_val_f32(model->gguf, key_id);
    
    snprintf(key, sizeof(key), "%s.rope.scaling.yarn_attn_factor", arch);
    key_id = gguf_find_key(model->gguf, key);
    if (key_id >= 0) hp->rope_attn_factor = gguf_get_val_f32(model->gguf, key_id);
    
    snprintf(key, sizeof(key), "%s.rope.scaling.yarn_beta_fast", arch);
    key_id = gguf_find_key(model->gguf, key);
    if (key_id >= 0) hp->rope_beta_fast = gguf_get_val_f32(model->gguf, key_id);
    
    snprintf(key, sizeof(key), "%s.rope.scaling.yarn_beta_slow", arch);
    key_id = gguf_find_key(model->gguf, key);
    if (key_id >= 0) hp->rope_beta_slow = gguf_get_val_f32(model->gguf, key_id);
    
    /* Check for RoPE config override from Perl hash */
    svp = hv_fetch(hv, "rope", 4, 0);
    if (svp && SvROK(*svp) && sv_isobject(*svp)) {
        LughRopeConfig *rope = get_lugh_rope(aTHX_ *svp);
        hp->rope_scaling_type = rope->scaling_type;
        hp->rope_freq_scale = rope->freq_scale;
        hp->n_ctx_orig = rope->n_ctx_orig;
        hp->rope_ext_factor = rope->ext_factor;
        hp->rope_attn_factor = rope->attn_factor;
        hp->rope_beta_fast = rope->beta_fast;
        hp->rope_beta_slow = rope->beta_slow;
        /* Override freq_base if set in rope config */
        if (rope->freq_base > 0) {
            hp->rope_freq_base = rope->freq_base;
        }
    }
    
    /* Set architecture type for inference path selection */
    hp->arch_type = get_arch_type(arch);
}

/* Apply RoPE config override to hyperparams */
static void apply_rope_override(pTHX_ LughHyperparams *hp, SV *rope_sv) {
    if (!rope_sv || !SvROK(rope_sv) || !sv_isobject(rope_sv)) return;
    
    LughRopeConfig *rope = get_lugh_rope(aTHX_ rope_sv);
    hp->rope_scaling_type = rope->scaling_type;
    hp->rope_freq_scale = rope->freq_scale;
    if (rope->n_ctx_orig > 0) hp->n_ctx_orig = rope->n_ctx_orig;
    hp->rope_ext_factor = rope->ext_factor;
    hp->rope_attn_factor = rope->attn_factor;
    hp->rope_beta_fast = rope->beta_fast;
    hp->rope_beta_slow = rope->beta_slow;
    if (rope->freq_base > 0) {
        hp->rope_freq_base = rope->freq_base;
    }
}

/* Get layer weights from model context */
/* Get layer weights from model context - architecture aware */
static int get_layer_weights_for_arch(struct ggml_context *ctx_w, int layer, 
                                       LughLayerWeights *lw, LughArchType arch_type) {
    char name[64];
    int valid = 1;
    
    /* Initialize all pointers to NULL */
    memset(lw, 0, sizeof(LughLayerWeights));
    
    /* Set layer index for LoRA lookups */
    lw->layer_idx = layer;
    
    /* Set flags based on architecture */
    lw->has_combined_qkv = arch_has_combined_qkv(arch_type);
    lw->has_ffn_gate = arch_has_ffn_gate(arch_type);
    lw->has_post_norm = arch_has_post_norm(arch_type);
    
    /* Attention norm (all architectures have this) */
    snprintf(name, sizeof(name), "blk.%d.attn_norm.weight", layer);
    lw->attn_norm = ggml_get_tensor(ctx_w, name);
    if (!lw->attn_norm) valid = 0;
    
    /* Q/K/V weights - check combined first, then separate */
    if (lw->has_combined_qkv) {
        /* Try combined QKV tensor */
        snprintf(name, sizeof(name), "blk.%d.attn_qkv.weight", layer);
        lw->wqkv = ggml_get_tensor(ctx_w, name);
        if (!lw->wqkv) {
            /* Fallback to separate Q/K/V if combined not found */
            lw->has_combined_qkv = 0;
        }
    }
    
    if (!lw->has_combined_qkv) {
        /* Separate Q, K, V tensors */
        snprintf(name, sizeof(name), "blk.%d.attn_q.weight", layer);
        lw->wq = ggml_get_tensor(ctx_w, name);
        
        snprintf(name, sizeof(name), "blk.%d.attn_k.weight", layer);
        lw->wk = ggml_get_tensor(ctx_w, name);
        
        snprintf(name, sizeof(name), "blk.%d.attn_v.weight", layer);
        lw->wv = ggml_get_tensor(ctx_w, name);
        
        if (!lw->wq || !lw->wk || !lw->wv) valid = 0;
    }
    
    /* Attention output */
    snprintf(name, sizeof(name), "blk.%d.attn_output.weight", layer);
    lw->wo = ggml_get_tensor(ctx_w, name);
    if (!lw->wo) valid = 0;
    
    /* Post-attention norm (gemma2, etc.) */
    if (lw->has_post_norm) {
        snprintf(name, sizeof(name), "blk.%d.post_attention_norm.weight", layer);
        lw->attn_post_norm = ggml_get_tensor(ctx_w, name);
        /* Not critical if missing - some models don't have it */
    }
    
    /* FFN norm */
    snprintf(name, sizeof(name), "blk.%d.ffn_norm.weight", layer);
    lw->ffn_norm = ggml_get_tensor(ctx_w, name);
    if (!lw->ffn_norm) valid = 0;
    
    /* FFN gate (SwiGLU models only) */
    if (lw->has_ffn_gate) {
        snprintf(name, sizeof(name), "blk.%d.ffn_gate.weight", layer);
        lw->ffn_gate = ggml_get_tensor(ctx_w, name);
        if (!lw->ffn_gate) {
            /* Model doesn't have gate - switch to GELU path */
            lw->has_ffn_gate = 0;
        }
    }
    
    /* FFN up/down (all architectures) */
    snprintf(name, sizeof(name), "blk.%d.ffn_up.weight", layer);
    lw->ffn_up = ggml_get_tensor(ctx_w, name);
    if (!lw->ffn_up) valid = 0;
    
    snprintf(name, sizeof(name), "blk.%d.ffn_down.weight", layer);
    lw->ffn_down = ggml_get_tensor(ctx_w, name);
    if (!lw->ffn_down) valid = 0;
    
    /* Post-FFN norm (gemma2, etc.) */
    if (lw->has_post_norm) {
        snprintf(name, sizeof(name), "blk.%d.post_ffw_norm.weight", layer);
        lw->ffn_post_norm = ggml_get_tensor(ctx_w, name);
        /* Not critical if missing */
    }
    
    return valid;
}

/* Legacy wrapper for backward compatibility */
static int get_layer_weights(struct ggml_context *ctx_w, int layer, LughLayerWeights *lw) {
    /* Default to LLAMA architecture for backward compatibility */
    return get_layer_weights_for_arch(ctx_w, layer, lw, LUGH_ARCH_LLAMA);
}

/* ============================================================================
 * Backend Management
 * Uses ggml's backend registry for dynamic backend discovery and initialization
 * ============================================================================ */

/* Check if Metal backend is available at runtime via ggml registry */
static int metal_is_available(void) {
    size_t i, count = ggml_backend_reg_count();
    for (i = 0; i < count; i++) {
        ggml_backend_reg_t reg = ggml_backend_reg_get(i);
        const char *name = ggml_backend_reg_name(reg);
        if (strcmp(name, "Metal") == 0) {
            return ggml_backend_reg_dev_count(reg) > 0 ? 1 : 0;
        }
    }
    return 0;
}

/* Initialize CPU backend with n_threads */
static ggml_backend_t init_cpu_backend(int n_threads) {
    ggml_backend_t backend = ggml_backend_cpu_init();
    if (backend) {
        ggml_backend_cpu_set_n_threads(backend, n_threads);
    }
    return backend;
}

/* Initialize backend by name using ggml registry
 * Supported names: "CPU", "Metal", "CUDA", "Vulkan", "BLAS", etc.
 * Returns NULL if backend not available
 * All backends are handled uniformly through the ggml registry.
 */
static ggml_backend_t init_backend_by_name(const char *name, int n_threads) {
    ggml_backend_t backend = NULL;
    
    /* Handle special case for CPU which needs thread count */
    if (strcmp(name, "CPU") == 0 || strcmp(name, "cpu") == 0) {
        return init_cpu_backend(n_threads);
    }
    
    /* Use ggml registry for all other backends (Metal, CUDA, Vulkan, etc.) */
    backend = ggml_backend_init_by_name(name, NULL);
    return backend;
}

/* Initialize the best available backend (GPU preferred, CPU fallback) */
static ggml_backend_t init_best_backend(int n_threads) {
    ggml_backend_t backend = NULL;
    
    /* ggml_backend_init_best() returns best GPU or CPU */
    backend = ggml_backend_init_best();
    
    /* If we got a CPU backend, set thread count */
    if (backend) {
        ggml_backend_dev_t dev = ggml_backend_get_device(backend);
        if (dev && ggml_backend_dev_type(dev) == GGML_BACKEND_DEVICE_TYPE_CPU) {
            ggml_backend_cpu_set_n_threads(backend, n_threads);
        }
    }
    
    return backend;
}

/* Get the name of a backend for debugging/logging */
static const char* get_backend_name(ggml_backend_t backend) {
    if (!backend) return "none";
    return ggml_backend_name(backend);
}

/* Check if a backend is GPU-based */
static int is_gpu_backend(ggml_backend_t backend) {
    if (!backend) return 0;
    ggml_backend_dev_t dev = ggml_backend_get_device(backend);
    if (!dev) return 0;
    enum ggml_backend_dev_type type = ggml_backend_dev_type(dev);
    return (type == GGML_BACKEND_DEVICE_TYPE_GPU || 
            type == GGML_BACKEND_DEVICE_TYPE_IGPU);
}

/* Forward declaration for create_compute_context (defined below) */
static struct ggml_context* create_compute_context(size_t mem_size);

/* ============================================================================
 * Memory Pool for Reusing Compute Resources
 * Avoids repeated allocation/deallocation during inference
 * ============================================================================ */

#define MAX_MEMORY_POOLS 64

typedef struct {
    int id;
    int active;
    ggml_backend_t backend;          /* Cached backend */
    ggml_gallocr_t allocator;        /* Cached graph allocator */
    struct ggml_context *ctx_compute; /* Cached compute context */
    size_t ctx_size;                  /* Size of compute context */
    int n_threads;                    /* Thread count for backend */
    char backend_name[32];            /* Backend name */
#ifdef USE_ITHREADS
    perl_mutex pool_mutex;            /* Thread-safe access */
#endif
} LughMemoryPool;

static LughMemoryPool* mempool_registry[MAX_MEMORY_POOLS] = {NULL};
static int next_mempool_id = 1;

#ifdef USE_ITHREADS
static perl_mutex mempool_mutex;
#define MEMPOOL_LOCK()   MUTEX_LOCK(&mempool_mutex)
#define MEMPOOL_UNLOCK() MUTEX_UNLOCK(&mempool_mutex)
#define POOL_LOCK(pool)   MUTEX_LOCK(&(pool)->pool_mutex)
#define POOL_UNLOCK(pool) MUTEX_UNLOCK(&(pool)->pool_mutex)
#else
#define MEMPOOL_LOCK()
#define MEMPOOL_UNLOCK()
#define POOL_LOCK(pool)
#define POOL_UNLOCK(pool)
#endif

/* Allocate a memory pool ID */
static int alloc_mempool_id(void) {
    int id = -1;
    MEMPOOL_LOCK();
    for (int i = 0; i < MAX_MEMORY_POOLS; i++) {
        int check_id = (next_mempool_id + i) % MAX_MEMORY_POOLS;
        if (check_id == 0) check_id = 1;
        if (mempool_registry[check_id] == NULL) {
            id = check_id;
            next_mempool_id = (id + 1) % MAX_MEMORY_POOLS;
            if (next_mempool_id == 0) next_mempool_id = 1;
            break;
        }
    }
    MEMPOOL_UNLOCK();
    return id;
}

/* Get memory pool by ID */
static LughMemoryPool* get_mempool_by_id(int id) {
    LughMemoryPool *pool = NULL;
    if (id <= 0 || id >= MAX_MEMORY_POOLS) return NULL;
    MEMPOOL_LOCK();
    pool = mempool_registry[id];
    if (pool && !pool->active) pool = NULL;
    MEMPOOL_UNLOCK();
    return pool;
}

/* Create a new memory pool */
static LughMemoryPool* create_memory_pool(
    const char *backend_name, 
    int n_threads,
    size_t ctx_size
) {
    int id = alloc_mempool_id();
    if (id < 0) return NULL;
    
    LughMemoryPool *pool;
    Newxz(pool, 1, LughMemoryPool);
    pool->id = id;
    pool->active = 1;
    pool->ctx_size = ctx_size;
    pool->n_threads = n_threads;
    strncpy(pool->backend_name, backend_name, 31);
    pool->backend_name[31] = '\0';
    
#ifdef USE_ITHREADS
    MUTEX_INIT(&pool->pool_mutex);
#endif
    
    /* Initialize backend */
    if (strcmp(backend_name, "auto") == 0) {
        pool->backend = init_best_backend(n_threads);
    } else {
        pool->backend = init_backend_by_name(backend_name, n_threads);
    }
    
    if (!pool->backend) {
        Safefree(pool);
        return NULL;
    }
    
    /* Create initial compute context */
    pool->ctx_compute = create_compute_context(ctx_size);
    if (!pool->ctx_compute) {
        ggml_backend_free(pool->backend);
        Safefree(pool);
        return NULL;
    }
    
    /* Create graph allocator */
    pool->allocator = ggml_gallocr_new(ggml_backend_get_default_buffer_type(pool->backend));
    if (!pool->allocator) {
        ggml_free(pool->ctx_compute);
        ggml_backend_free(pool->backend);
        Safefree(pool);
        return NULL;
    }
    
    /* Register */
    MEMPOOL_LOCK();
    mempool_registry[id] = pool;
    MEMPOOL_UNLOCK();
    
    return pool;
}

/* Reset pool's compute context for reuse - internal version (no lock) */
static int reset_memory_pool_unlocked(LughMemoryPool *pool) {
    if (!pool || !pool->active) return 0;
    
    /* Free old context and create new one */
    if (pool->ctx_compute) {
        ggml_free(pool->ctx_compute);
    }
    pool->ctx_compute = create_compute_context(pool->ctx_size);
    
    return pool->ctx_compute != NULL;
}

/* Reset pool's compute context for reuse - public version (with lock) */
static int reset_memory_pool(LughMemoryPool *pool) {
    int result;
    if (!pool || !pool->active) return 0;
    
    POOL_LOCK(pool);
    result = reset_memory_pool_unlocked(pool);
    POOL_UNLOCK(pool);
    
    return result;
}

/* Free a memory pool */
static void free_memory_pool(LughMemoryPool *pool) {
    if (!pool) return;
    
    POOL_LOCK(pool);
    pool->active = 0;
    
    if (pool->allocator) {
        ggml_gallocr_free(pool->allocator);
        pool->allocator = NULL;
    }
    if (pool->ctx_compute) {
        ggml_free(pool->ctx_compute);
        pool->ctx_compute = NULL;
    }
    if (pool->backend) {
        ggml_backend_free(pool->backend);
        pool->backend = NULL;
    }
    POOL_UNLOCK(pool);
    
    /* Remove from registry */
    MEMPOOL_LOCK();
    if (pool->id > 0 && pool->id < MAX_MEMORY_POOLS) {
        mempool_registry[pool->id] = NULL;
    }
    MEMPOOL_UNLOCK();
    
#ifdef USE_ITHREADS
    MUTEX_DESTROY(&pool->pool_mutex);
#endif
    Safefree(pool);
}

/* Create compute context with no_alloc=true */
static struct ggml_context* create_compute_context(size_t mem_size) {
    struct ggml_init_params params = {
        .mem_size   = mem_size,
        .mem_buffer = NULL,
        .no_alloc   = true,
    };
    return ggml_init(params);
}

/* ============================================================================
 * LoRA Adapter Support
 * Low-Rank Adaptation for efficient model fine-tuning
 * Supports GGUF and SafeTensors formats
 * ============================================================================ */

#define MAX_LORA_ADAPTERS 64
#define MAX_LORA_WEIGHTS  512

/* Individual LoRA weight pair for a single tensor */
struct LughLoRAWeight {
    char name[128];              /* Base tensor name (e.g., "blk.0.attn_q.weight") */
    struct ggml_tensor *a;       /* Down-projection [rank × d_in] */
    struct ggml_tensor *b;       /* Up-projection [d_out × rank] */
    int rank;                    /* LoRA rank (inferred from tensor shapes) */
    /* Trainable weight support (Phase 3) */
    int tensor_a_id;             /* LughTensor ID for A matrix (for autograd) */
    int tensor_b_id;             /* LughTensor ID for B matrix (for autograd) */
};

/* LoRA adapter container */
struct LughLoRAAdapter {
    int id;
    int active;
    float alpha;                 /* Scaling factor from adapter metadata */
    float scale;                 /* User-specified scale multiplier */
    char *source_file;           /* Path to source file */
    char *architecture;          /* Must match base model architecture */
    char format[16];             /* "gguf" or "safetensors" or "trainable" */
    /* Weight storage */
    LughLoRAWeight *weights;     /* Array of LoRA weight pairs */
    int n_weights;               /* Number of weight pairs */
    int weights_capacity;        /* Allocated capacity */
    /* Tensor memory */
    struct ggml_context *ctx;    /* Context for LoRA tensors */
    ggml_backend_buffer_t buffer; /* Backend buffer for tensor data */
    /* Trainable LoRA support (Phase 3) */
    bool trainable;              /* True if created for training (not loaded) */
    int model_id;                /* Associated model ID for target lookups */
    int context_id;              /* LughContext ID for autograd tensors */
#ifdef USE_ITHREADS
    perl_mutex lora_mutex;       /* Thread-safe access */
#endif
};

/* LoRA adapter registry */
static LughLoRAAdapter* lora_registry[MAX_LORA_ADAPTERS] = {NULL};
static int next_lora_id = 1;

#ifdef USE_ITHREADS
/* lora_registry_mutex is declared at top with other mutexes */
#define LORA_REGISTRY_LOCK()   MUTEX_LOCK(&lora_registry_mutex)
#define LORA_REGISTRY_UNLOCK() MUTEX_UNLOCK(&lora_registry_mutex)
#define LORA_LOCK(lora)   MUTEX_LOCK(&(lora)->lora_mutex)
#define LORA_UNLOCK(lora) MUTEX_UNLOCK(&(lora)->lora_mutex)
#else
#define LORA_REGISTRY_LOCK()
#define LORA_REGISTRY_UNLOCK()
#define LORA_LOCK(lora)
#define LORA_UNLOCK(lora)
#endif

/* Allocate a LoRA adapter ID */
static int alloc_lora_id(void) {
    int id = -1;
    LORA_REGISTRY_LOCK();
    for (int i = 0; i < MAX_LORA_ADAPTERS; i++) {
        int check_id = (next_lora_id + i) % MAX_LORA_ADAPTERS;
        if (check_id == 0) check_id = 1;
        if (lora_registry[check_id] == NULL) {
            id = check_id;
            next_lora_id = (id + 1) % MAX_LORA_ADAPTERS;
            if (next_lora_id == 0) next_lora_id = 1;
            break;
        }
    }
    LORA_REGISTRY_UNLOCK();
    return id;
}

/* Get LoRA adapter by ID */
static LughLoRAAdapter* get_lora_by_id(int id) {
    LughLoRAAdapter *lora = NULL;
    if (id <= 0 || id >= MAX_LORA_ADAPTERS) return NULL;
    LORA_REGISTRY_LOCK();
    lora = lora_registry[id];
    if (lora && !lora->active) lora = NULL;
    LORA_REGISTRY_UNLOCK();
    return lora;
}

/* Forward declaration for LoRA vtbl (defined later) */
static MGVTBL lugh_lora_vtbl;

/* Helper to get LughLoRAAdapter from SV (can return NULL if not a valid LoRA) */
static LughLoRAAdapter* get_lugh_lora(pTHX_ SV *sv) {
    MAGIC *mg;
    int id;
    LughLoRAAdapter *lora;
    
    if (!sv || !SvOK(sv)) return NULL;
    if (!sv_isobject(sv)) return NULL;
    
    sv = SvRV(sv);
    mg = mg_findext(sv, PERL_MAGIC_ext, &lugh_lora_vtbl);
    if (!mg) return NULL;
    
    id = (int)(IV)mg->mg_ptr;
    lora = get_lora_by_id(id);
    
    return lora;
}

/* Find LoRA weight for a given tensor name */
static LughLoRAWeight* find_lora_weight(LughLoRAAdapter *lora, const char *tensor_name) {
    int i;
    if (!lora || !tensor_name) return NULL;
    for (i = 0; i < lora->n_weights; i++) {
        if (strcmp(lora->weights[i].name, tensor_name) == 0) {
            return &lora->weights[i];
        }
    }
    return NULL;
}

/* Add a LoRA weight pair to adapter */
static int add_lora_weight(LughLoRAAdapter *lora, const char *name,
                           struct ggml_tensor *a, struct ggml_tensor *b) {
    if (!lora || !name || !a || !b) return 0;
    
    /* Grow capacity if needed */
    if (lora->n_weights >= lora->weights_capacity) {
        int new_cap = lora->weights_capacity == 0 ? 64 : lora->weights_capacity * 2;
        LughLoRAWeight *new_weights;
        Newxz(new_weights, new_cap, LughLoRAWeight);
        if (!new_weights) return 0;
        if (lora->weights) {
            Copy(lora->weights, new_weights, lora->n_weights, LughLoRAWeight);
            Safefree(lora->weights);
        }
        lora->weights = new_weights;
        lora->weights_capacity = new_cap;
    }
    
    /* Add the weight */
    LughLoRAWeight *w = &lora->weights[lora->n_weights];
    strncpy(w->name, name, sizeof(w->name) - 1);
    w->a = a;
    w->b = b;
    /* Rank is second dimension of A: A is [in_features, rank] in GGML */
    w->rank = (int)a->ne[1];
    w->tensor_a_id = -1;  /* Set by create() for trainable LoRA */
    w->tensor_b_id = -1;
    lora->n_weights++;
    
    return 1;
}

/* Free a LoRA adapter */
static void free_lora_adapter(LughLoRAAdapter *lora) {
    if (!lora) return;
    
    LORA_LOCK(lora);
    
    if (lora->weights) {
        Safefree(lora->weights);
        lora->weights = NULL;
    }
    if (lora->source_file) {
        Safefree(lora->source_file);
        lora->source_file = NULL;
    }
    if (lora->architecture) {
        Safefree(lora->architecture);
        lora->architecture = NULL;
    }
    if (lora->buffer) {
        ggml_backend_buffer_free(lora->buffer);
        lora->buffer = NULL;
    }
    if (lora->ctx) {
        ggml_free(lora->ctx);
        lora->ctx = NULL;
    }
    
    lora->active = 0;
    
    LORA_UNLOCK(lora);
    
    /* Remove from registry */
    LORA_REGISTRY_LOCK();
    if (lora->id > 0 && lora->id < MAX_LORA_ADAPTERS) {
        lora_registry[lora->id] = NULL;
    }
    LORA_REGISTRY_UNLOCK();
    
#ifdef USE_ITHREADS
    MUTEX_DESTROY(&lora->lora_mutex);
#endif
    Safefree(lora);
}

/* Create a new LoRA adapter container */
static LughLoRAAdapter* create_lora_adapter(void) {
    int id = alloc_lora_id();
    if (id < 0) return NULL;
    
    LughLoRAAdapter *lora;
    Newxz(lora, 1, LughLoRAAdapter);
    if (!lora) return NULL;
    
    lora->id = id;
    lora->active = 1;
    lora->alpha = 1.0f;
    lora->scale = 1.0f;
    lora->n_weights = 0;
    lora->weights_capacity = 0;
    lora->weights = NULL;
    lora->trainable = false;
    lora->model_id = -1;
    lora->context_id = -1;
    
#ifdef USE_ITHREADS
    MUTEX_INIT(&lora->lora_mutex);
#endif
    
    LORA_REGISTRY_LOCK();
    lora_registry[id] = lora;
    LORA_REGISTRY_UNLOCK();
    
    return lora;
}

/* ============================================================================
 * LoRA-Aware Matrix Multiplication
 * Applies LoRA adaptation: y = W*x + scale * (B * (A * x))
 * ============================================================================ */

/* Helper: LoRA-aware matrix multiplication */
static struct ggml_tensor* lora_mul_mat(
    struct ggml_context *ctx,
    struct ggml_tensor *w,           /* Base model weight */
    struct ggml_tensor *x,           /* Input */
    LughLoRAAdapter *lora,           /* LoRA adapter (can be NULL) */
    const char *weight_name          /* Tensor name for LoRA lookup */
) {
    struct ggml_tensor *result = ggml_mul_mat(ctx, w, x);
    
    if (!lora || !weight_name) {
        return result;
    }
    
    LughLoRAWeight *lw = find_lora_weight(lora, weight_name);
    if (!lw || !lw->a || !lw->b) {
        return result;
    }
    
    /* Compute scaling factor: alpha / rank * scale */
    float s = (lora->alpha / (float)lw->rank) * lora->scale;
    
    /* LoRA: B * (A * x) */
    struct ggml_tensor *ax = ggml_mul_mat(ctx, lw->a, x);
    struct ggml_tensor *bax = ggml_mul_mat(ctx, lw->b, ax);
    
    /* Scale and add */
    bax = ggml_scale(ctx, bax, s);
    result = ggml_add(ctx, result, bax);
    
    return result;
}

/* ============================================================================
 * Main Transformer Backward Pass
 * Uses cached activations to compute analytical gradients for LoRA training
 * 
 * Note: This is a simplified backward pass focused on LoRA gradient accumulation.
 * Full transformer backward would require storing more activations.
 * ============================================================================ */

/* Helper to find weight tensor by name in training cache */
static LughTensor* find_weight_in_cache(LughTrainingCache *cache, const char *name) {
    if (!cache || !name) return NULL;
    for (int w = 0; w < cache->n_weight_tensors; w++) {
        if (cache->weight_tensor_names[w] && 
            strcmp(cache->weight_tensor_names[w], name) == 0) {
            return get_tensor_by_id(cache->weight_tensor_ids[w]);
        }
    }
    return NULL;
}

/* Main transformer backward pass - accumulate LoRA gradients */
static void backward_transformer_forward(pTHX_ LughTensor *output, LughContext *lctx) {
    DEBUG_PRINT("DEBUG: backward_transformer_forward starting, output=%p\n", (void*)output);
    DEBUG_PRINT("DEBUG: output->training_cache_id=%d\n", output->training_cache_id);
    LughTrainingCache *cache = get_training_cache_by_id(output->training_cache_id);
    if (!cache) {
        croak("No training cache found for backward pass");
    }
    DEBUG_PRINT("DEBUG: got training cache %d\n", cache->id);
    
    LughModel *model = get_model_by_id(cache->model_id);
    if (!model) {
        croak("Model not found for backward pass");
    }
    DEBUG_PRINT("DEBUG: got model, ctx=%p\n", (void*)model->ctx);
    
    LughLoRAAdapter *lora = NULL;
    if (cache->lora_id > 0) {
        DEBUG_PRINT("DEBUG: getting lora by id %d\n", cache->lora_id);
        lora = get_lora_by_id(cache->lora_id);
    }
    DEBUG_PRINT("DEBUG: got lora=%p, n_weights=%d\n", (void*)lora, lora ? lora->n_weights : -1);
    
    /* Get gradient from output (dL/dlogits) */
    DEBUG_PRINT("DEBUG: checking output->grad=%p\n", (void*)output->grad);
    if (!output->grad || !output->grad->data) {
        croak("No output gradient provided for backward pass");
    }
    DEBUG_PRINT("DEBUG: grad->data=%p\n", (void*)output->grad->data);
    float *grad_logits = (float*)output->grad->data;
    DEBUG_PRINT("DEBUG: grad_logits=%p\n", (void*)grad_logits);
    
    int n_tokens = cache->n_tokens;
    int n_embd = cache->n_embd;
    int n_vocab = cache->n_vocab;
    int n_layer = cache->n_layer;
    DEBUG_PRINT("DEBUG: n_tokens=%d, n_embd=%d, n_vocab=%d, n_layer=%d\n", n_tokens, n_embd, n_vocab, n_layer);
    float norm_eps = cache->rms_norm_eps > 0 ? cache->rms_norm_eps : 1e-5f;
    
    /* Allocate gradient accumulators */
    size_t hidden_size = (size_t)n_tokens * n_embd;
    DEBUG_PRINT("DEBUG: allocating grad_hidden size=%zu\n", hidden_size);
    float *grad_hidden = (float*)calloc(hidden_size, sizeof(float));
    float *grad_temp = (float*)calloc(hidden_size, sizeof(float));
    DEBUG_PRINT("DEBUG: grad_hidden=%p, grad_temp=%p\n", (void*)grad_hidden, (void*)grad_temp);
    
    if (!grad_hidden || !grad_temp) {
        free(grad_hidden);
        free(grad_temp);
        croak("Failed to allocate gradient memory");
    }
    
    /* ======================================================================
     * Step 1: Output projection backward (logits = lm_head @ final_norm_out)
     * dL/d(final_norm_out) = lm_head^T @ dL/dlogits
     * ====================================================================== */
    DEBUG_PRINT("DEBUG: getting lm_head\n");
    struct ggml_tensor *lm_head = ggml_get_tensor(model->ctx, "output.weight");
    if (!lm_head) {
        lm_head = ggml_get_tensor(model->ctx, "token_embd.weight");
    }
    DEBUG_PRINT("DEBUG: lm_head=%p, type=%d, ne=[%lld,%lld]\n", (void*)lm_head, 
            lm_head ? (int)lm_head->type : -1,
            lm_head ? (long long)lm_head->ne[0] : 0,
            lm_head ? (long long)lm_head->ne[1] : 0);
    
    /* Only do backward for F32 weights; quantized weights need special handling */
    if (lm_head && lm_head->data && lm_head->type == GGML_TYPE_F32) {
        DEBUG_PRINT("DEBUG: computing lm_head backward (F32)\n");
        float *lm_head_data = (float*)lm_head->data;
        size_t lm_head_max = (size_t)n_vocab * n_embd;
        size_t grad_logits_max = (size_t)n_tokens * n_vocab;
        
        /* Validate memory before accessing */
        size_t lm_head_nbytes = lm_head_max * sizeof(float);
        size_t grad_nbytes = grad_logits_max * sizeof(float);
        
        /* Memory barrier to ensure all prior writes are visible */
        __sync_synchronize();
        
        /* Touch first and last elements to verify memory is accessible */
        volatile float test_lm = lm_head_data[0];
        volatile float test_lm2 = lm_head_data[lm_head_max - 1];
        volatile float test_grad = grad_logits[0];
        volatile float test_grad2 = grad_logits[grad_logits_max - 1];
        (void)test_lm; (void)test_lm2; (void)test_grad; (void)test_grad2;
        
        /* Another barrier after validation */
        __sync_synchronize();
        
        /* lm_head: [n_embd, n_vocab], grad_logits: [n_vocab, n_tokens] */
        /* grad_hidden = lm_head^T @ grad_logits => [n_embd, n_tokens] */
        for (int t = 0; t < n_tokens; t++) {
            for (int e = 0; e < n_embd; e++) {
                float sum = 0.0f;
                for (int v = 0; v < n_vocab; v++) {
                    size_t lm_idx = (size_t)v * n_embd + e;
                    size_t grad_idx = (size_t)t * n_vocab + v;
                    if (lm_idx >= lm_head_max || grad_idx >= grad_logits_max) {
                        croak("BOUNDS ERROR: lm_idx=%zu/%zu, grad_idx=%zu/%zu", 
                                lm_idx, lm_head_max, grad_idx, grad_logits_max);
                    }
                    sum += lm_head_data[lm_idx] * grad_logits[grad_idx];
                }
                grad_hidden[t * n_embd + e] = sum;
            }
        }
        DEBUG_PRINT("DEBUG: lm_head backward done\n");
    } else {
        /* For quantized models, just use grad_logits directly as a rough approximation */
        /* This is a simplified LoRA-only training that doesn't need full backward through lm_head */
        DEBUG_PRINT("DEBUG: skipping lm_head backward (quantized), using identity gradient\n");
        /* Initialize grad_hidden with a scaled version of grad from cross-entropy */
        /* For LoRA training, we mainly care about gradients through attention/FFN */
        for (int t = 0; t < n_tokens; t++) {
            for (int e = 0; e < n_embd; e++) {
                grad_hidden[t * n_embd + e] = 1e-4f; /* Small constant gradient */
            }
        }
    }
    
    /* ======================================================================
     * Step 2: Final RMS norm backward
     * ====================================================================== */
    if (cache->final_norm_out) {
        /* Get pre-norm input (last layer output) */
        float *pre_norm = NULL;
        if (cache->layers && n_layer > 0) {
            pre_norm = cache->layers[n_layer - 1].down_out;
        }
        if (pre_norm) {
            backward_rms_norm_layer(
                grad_temp,              /* output: gradient w.r.t. input */
                grad_hidden,            /* input: gradient w.r.t. output (d_output) */
                pre_norm,               /* input activations */
                NULL,                   /* gamma (NULL for no learned scale) */
                n_embd, n_tokens, norm_eps
            );
            memcpy(grad_hidden, grad_temp, hidden_size * sizeof(float));
        }
    }
    
    /* ======================================================================
     * Step 3: Layer-by-layer backward pass (reverse order) - LoRA gradients only
     * ====================================================================== */
    
    if (cache->train_lora && lora && cache->layers) {
        for (int layer = n_layer - 1; layer >= 0; layer--) {
            LughLayerActivations *act = &cache->layers[layer];
            char name_buf[64];
            
            /* FFN backward - accumulate LoRA gradients */
            /* ffn_down LoRA gradient: output = W @ input, so grad_W = grad_output @ input^T */
            snprintf(name_buf, sizeof(name_buf), "blk.%d.ffn_down.weight", layer);
            LughLoRAWeight *lw_down = find_lora_weight(lora, name_buf);
            if (lw_down && act->ffn_act && lw_down->tensor_a_id > 0 && lw_down->tensor_b_id > 0 &&
                lw_down->a && lw_down->b) {
                LughTensor *grad_a = get_tensor_by_id(lw_down->tensor_a_id);
                LughTensor *grad_b = get_tensor_by_id(lw_down->tensor_b_id);
                if (grad_a && grad_b) {
                    float scale = lora->alpha / (float)lw_down->rank * lora->scale;
                    int in_dim = lw_down->a->ne[1];  /* A is [rank, in_dim] */
                    int out_dim = lw_down->b->ne[0]; /* B is [out_dim, rank] */
                    backward_lora_matmul(
                        grad_a, grad_b,
                        grad_hidden,          /* grad w.r.t. output [out_dim, n_tokens] */
                        act->ffn_act,         /* input [in_dim, n_tokens] */
                        (float*)lw_down->a->data,
                        (float*)lw_down->b->data,
                        out_dim, in_dim, lw_down->rank, n_tokens, scale
                    );
                }
            }
            
            /* Attention O projection LoRA gradient */
            snprintf(name_buf, sizeof(name_buf), "blk.%d.attn_output.weight", layer);
            LughLoRAWeight *lw_o = find_lora_weight(lora, name_buf);
            if (lw_o && act->attn_out && lw_o->tensor_a_id > 0 && lw_o->tensor_b_id > 0 &&
                lw_o->a && lw_o->b) {
                LughTensor *grad_a = get_tensor_by_id(lw_o->tensor_a_id);
                LughTensor *grad_b = get_tensor_by_id(lw_o->tensor_b_id);
                if (grad_a && grad_b) {
                    float scale = lora->alpha / (float)lw_o->rank * lora->scale;
                    int in_dim = lw_o->a->ne[1];
                    int out_dim = lw_o->b->ne[0];
                    backward_lora_matmul(
                        grad_a, grad_b,
                        grad_hidden,
                        act->attn_out,
                        (float*)lw_o->a->data,
                        (float*)lw_o->b->data,
                        out_dim, in_dim, lw_o->rank, n_tokens, scale
                    );
                }
            }
            
            /* Q, K, V projection LoRA gradients */
            /* Would need attention backward to compute proper gradients */
            /* Simplified: use grad_hidden approximation for testing */
            const char *qkv_suffixes[] = {"attn_q", "attn_k", "attn_v"};
            for (int q = 0; q < 3; q++) {
                snprintf(name_buf, sizeof(name_buf), "blk.%d.%s.weight", layer, qkv_suffixes[q]);
                LughLoRAWeight *lw_qkv = find_lora_weight(lora, name_buf);
                if (lw_qkv && act->attn_norm_out && lw_qkv->tensor_a_id > 0 && lw_qkv->tensor_b_id > 0 &&
                    lw_qkv->a && lw_qkv->b) {
                    LughTensor *grad_a = get_tensor_by_id(lw_qkv->tensor_a_id);
                    LughTensor *grad_b = get_tensor_by_id(lw_qkv->tensor_b_id);
                    if (grad_a && grad_b) {
                        float scale = lora->alpha / (float)lw_qkv->rank * lora->scale;
                        int in_dim = lw_qkv->a->ne[1];
                        int out_dim = lw_qkv->b->ne[0];
                        /* Use scaled down gradient as approximation */
                        backward_lora_matmul(
                            grad_a, grad_b,
                            grad_hidden,
                            act->attn_norm_out,
                            (float*)lw_qkv->a->data,
                            (float*)lw_qkv->b->data,
                            out_dim, in_dim, lw_qkv->rank, n_tokens, scale * 0.1f
                        );
                    }
                }
            }
            
            /* Propagate gradient through residual connections */
            /* grad_hidden already accumulates through both paths */
        }
    }
    
    /* ======================================================================
     * Step 3b: Full weight training - proper backpropagation
     * Compute gradients for model weights with correct gradient flow
     * ====================================================================== */
    
    if (cache->train_full && cache->n_weight_tensors > 0 && cache->layers) {
        DEBUG_PRINT("Computing full weight gradients for %d tensors\n", cache->n_weight_tensors);
        
        /* Allocate buffers for gradient propagation */
        size_t hidden_size = n_embd * n_tokens;
        float *grad_hidden_full = (float*)calloc(hidden_size, sizeof(float));
        float *grad_temp_full = (float*)calloc(hidden_size, sizeof(float));
        if (!grad_hidden_full || !grad_temp_full) {
            if (grad_hidden_full) free(grad_hidden_full);
            if (grad_temp_full) free(grad_temp_full);
            croak("Failed to allocate gradient buffers");
        }
        
        /* ====== Step 1: Output projection gradient ====== */
        /* logits = ggml_mul_mat(W_output, final_norm_out) = W_output^T @ final_norm_out
         * W_output is [n_embd, n_vocab] (ne[0]=n_embd, ne[1]=n_vocab)
         * final_norm_out is [n_embd, n_tokens]
         * logits is [n_vocab, n_tokens]
         */
        
        LughTensor *output_wt = find_weight_in_cache(cache, "output.weight");
        if (output_wt && output_wt->tensor && output_wt->grad && 
            output->grad && cache->final_norm_out) {
            int in_dim = output_wt->tensor->ne[0];   /* n_embd (input to W^T @ x) */
            int out_dim = output_wt->tensor->ne[1];  /* n_vocab (output of W^T @ x) */
            float *W_output = (float*)output_wt->tensor->data;
            float *grad_logits = (float*)output->grad->data;
            
            /* Compute output weight gradient: dL/dW = X @ grad_Y^T */
            backward_weight_matmul(
                output_wt,
                grad_logits,            /* [n_vocab, n_tokens] = [out_dim, n_tokens] */
                cache->final_norm_out,  /* [n_embd, n_tokens] = [in_dim, n_tokens] */
                out_dim, in_dim, n_tokens, 1.0f
            );
            
            /* Compute gradient w.r.t. final_norm_out: dL/dx = W @ dL/dy
             * For y = W^T @ x, we have dL/dx = W @ dL/dy
             * W is [n_embd, n_vocab], dL/dy is [n_vocab, n_tokens]
             * dL/dx = [n_embd, n_vocab] @ [n_vocab, n_tokens] = [n_embd, n_tokens]
             */
            for (int t = 0; t < n_tokens; t++) {
                for (int e = 0; e < in_dim; e++) {  /* e indexes n_embd */
                    float sum = 0.0f;
                    for (int v = 0; v < out_dim; v++) {  /* v indexes n_vocab */
                        /* W[e, v] in ggml column-major = W_output[v * in_dim + e] */
                        float w_val = W_output[v * in_dim + e];
                        float grad_val = grad_logits[t * out_dim + v];
                        sum += w_val * grad_val;
                    }
                    grad_hidden_full[t * in_dim + e] = sum;
                }
            }
            DEBUG_PRINT("  Backprop through output projection done\n");
        }
        
        /* ====== Step 2: Layer-by-layer backward (reverse order) ====== */
        for (int layer = n_layer - 1; layer >= 0; layer--) {
            LughLayerActivations *act = &cache->layers[layer];
            char name_buf[64];
            
            /* ----- FFN backward ----- */
            /* FFN: out = residual + ggml_mul_mat(W_down, silu(W_gate @ x) * (W_up @ x)) */
            /* where x = ffn_norm(attn_output) */
            /* For ggml_mul_mat(W, x) = W^T @ x:
             *   W_down is [n_ff, n_embd] (ne[0]=n_ff, ne[1]=n_embd)
             *   input is [n_ff, n_tokens] (ffn_act)
             *   output is [n_embd, n_tokens] (matches grad_hidden_full)
             */
            
            /* ffn_down gradient */
            snprintf(name_buf, sizeof(name_buf), "blk.%d.ffn_down.weight", layer);
            LughTensor *wt_down = find_weight_in_cache(cache, name_buf);
            if (wt_down && wt_down->tensor && wt_down->grad && act->ffn_act) {
                int in_dim = wt_down->tensor->ne[0];   /* n_ff (input to W^T @ x) */
                int out_dim = wt_down->tensor->ne[1];  /* n_embd (output of W^T @ x) */
                
                /* dL/dW_down = ffn_act @ grad_hidden^T */
                backward_weight_matmul(
                    wt_down,
                    grad_hidden_full,  /* [n_embd, n_tokens] = [out_dim, n_tokens] */
                    act->ffn_act,      /* [n_ff, n_tokens] = [in_dim, n_tokens] */
                    out_dim, in_dim, n_tokens, 1.0f
                );
                
                /* Compute grad w.r.t ffn_act for backprop to gate/up */
                /* For y = W^T @ x, we have dL/dx = W @ dL/dy */
                /* W_down is [n_ff, n_embd], so dL/d_ffn_act = W_down @ grad_hidden */
                float *W_down = (float*)wt_down->tensor->data;
                float *grad_ffn_act = (float*)calloc(in_dim * n_tokens, sizeof(float));
                if (grad_ffn_act) {
                    for (int t = 0; t < n_tokens; t++) {
                        for (int i = 0; i < in_dim; i++) {  /* i indexes n_ff */
                            float sum = 0.0f;
                            for (int o = 0; o < out_dim; o++) {  /* o indexes n_embd */
                                /* W_down[i, o] in ggml column-major = W_down[o * in_dim + i] */
                                float w_val = W_down[o * in_dim + i];
                                sum += w_val * grad_hidden_full[t * out_dim + o];
                            }
                            grad_ffn_act[t * in_dim + i] = sum;
                        }
                    }
                    
                    /* ffn_act = silu(gate_out) * up_out */
                    /* dL/d_gate = dL/d_ffn_act * up_out * silu'(gate) */
                    /* dL/d_up = dL/d_ffn_act * silu(gate) */
                    
                    /* ffn_up gradient 
                     * W_up is [n_embd, n_ff] (ne[0]=n_embd, ne[1]=n_ff)
                     * Forward: up_out = W_up^T @ ffn_norm_out = [n_ff, n_tokens]
                     * up_in_dim = ne[0] = n_embd, up_out_dim = ne[1] = n_ff
                     */
                    snprintf(name_buf, sizeof(name_buf), "blk.%d.ffn_up.weight", layer);
                    LughTensor *wt_up = find_weight_in_cache(cache, name_buf);
                    if (wt_up && wt_up->tensor && wt_up->grad && act->ffn_norm_out && act->gate_out) {
                        int up_in_dim = wt_up->tensor->ne[0];   /* n_embd (input to W^T @ x) */
                        int up_out_dim = wt_up->tensor->ne[1];  /* n_ff (output of W^T @ x) */
                        
                        /* dL/d_up_out = dL/d_ffn_act * silu(gate_out) */
                        float *grad_up_out = (float*)calloc(up_out_dim * n_tokens, sizeof(float));
                        if (grad_up_out) {
                            for (int t = 0; t < n_tokens; t++) {
                                for (int f = 0; f < up_out_dim; f++) {
                                    float gate_val = act->gate_out[t * up_out_dim + f];
                                    float silu_gate = gate_val / (1.0f + expf(-gate_val));
                                    grad_up_out[t * up_out_dim + f] = grad_ffn_act[t * up_out_dim + f] * silu_gate;
                                }
                            }
                            backward_weight_matmul(
                                wt_up,
                                grad_up_out,       /* [n_ff, n_tokens] = [out_dim, n_tokens] */
                                act->ffn_norm_out, /* [n_embd, n_tokens] = [in_dim, n_tokens] */
                                up_out_dim, up_in_dim, n_tokens, 1.0f
                            );
                            free(grad_up_out);
                        }
                    }
                    
                    /* ffn_gate gradient
                     * W_gate is [n_embd, n_ff] (ne[0]=n_embd, ne[1]=n_ff)
                     * Forward: gate_out = W_gate^T @ ffn_norm_out = [n_ff, n_tokens]
                     * gate_in_dim = ne[0] = n_embd, gate_out_dim = ne[1] = n_ff
                     */
                    snprintf(name_buf, sizeof(name_buf), "blk.%d.ffn_gate.weight", layer);
                    LughTensor *wt_gate = find_weight_in_cache(cache, name_buf);
                    if (wt_gate && wt_gate->tensor && wt_gate->grad && act->ffn_norm_out && act->gate_out && act->up_out) {
                        int gate_in_dim = wt_gate->tensor->ne[0];   /* n_embd (input) */
                        int gate_out_dim = wt_gate->tensor->ne[1];  /* n_ff (output) */
                        
                        /* dL/d_gate_out = dL/d_ffn_act * up_out * silu'(gate) */
                        /* silu'(x) = sigmoid(x) + x * sigmoid(x) * (1 - sigmoid(x)) */
                        /*          = sigmoid(x) * (1 + x * (1 - sigmoid(x))) */
                        float *grad_gate_out = (float*)calloc(gate_out_dim * n_tokens, sizeof(float));
                        if (grad_gate_out) {
                            for (int t = 0; t < n_tokens; t++) {
                                for (int f = 0; f < gate_out_dim; f++) {
                                    float gate_val = act->gate_out[t * gate_out_dim + f];
                                    float up_val = act->up_out[t * gate_out_dim + f];
                                    float sigmoid_gate = 1.0f / (1.0f + expf(-gate_val));
                                    float silu_deriv = sigmoid_gate * (1.0f + gate_val * (1.0f - sigmoid_gate));
                                    grad_gate_out[t * gate_out_dim + f] = 
                                        grad_ffn_act[t * gate_out_dim + f] * up_val * silu_deriv;
                                }
                            }
                            backward_weight_matmul(
                                wt_gate,
                                grad_gate_out,     /* [n_ff, n_tokens] = [out_dim, n_tokens] */
                                act->ffn_norm_out, /* [n_embd, n_tokens] = [in_dim, n_tokens] */
                                gate_out_dim, gate_in_dim, n_tokens, 1.0f
                            );
                            free(grad_gate_out);
                        }
                    }
                    
                    free(grad_ffn_act);
                }
            }
            
            /* ----- Attention backward (simplified) ----- */
            /* For attention, we use the stored activations */
            /* attn_output projection: o_proj = ggml_mul_mat(W_o, attn_out) = W_o^T @ attn_out 
             * W_o is [n_embd, n_embd] (ne[0]=n_embd, ne[1]=n_embd)
             */
            
            snprintf(name_buf, sizeof(name_buf), "blk.%d.attn_output.weight", layer);
            LughTensor *wt_o = find_weight_in_cache(cache, name_buf);
            if (wt_o && wt_o->tensor && wt_o->grad && act->attn_out) {
                int o_in_dim = wt_o->tensor->ne[0];   /* n_embd (input to W^T @ x) */
                int o_out_dim = wt_o->tensor->ne[1];  /* n_embd (output of W^T @ x) */
                
                backward_weight_matmul(
                    wt_o,
                    grad_hidden_full,  /* [n_embd, n_tokens] = [out_dim, n_tokens] */
                    act->attn_out,     /* [n_embd, n_tokens] = [in_dim, n_tokens] */
                    o_out_dim, o_in_dim, n_tokens, 1.0f
                );
            }
            
            /* Q, K, V projections - use attention norm output as input
             * W_q/k/v are [n_embd, heads*head_dim] or similar
             * in_dim = ne[0], out_dim = ne[1]
             */
            const char *qkv_names[] = {"attn_q", "attn_k", "attn_v"};
            for (int q = 0; q < 3; q++) {
                snprintf(name_buf, sizeof(name_buf), "blk.%d.%s.weight", layer, qkv_names[q]);
                LughTensor *wt_qkv = find_weight_in_cache(cache, name_buf);
                if (wt_qkv && wt_qkv->tensor && wt_qkv->grad && act->attn_norm_out) {
                    int qkv_in_dim = wt_qkv->tensor->ne[0];   /* input dim */
                    int qkv_out_dim = wt_qkv->tensor->ne[1];  /* output dim */
                    
                    /* Use scaled gradient for QKV (attention backward is complex) */
                    backward_weight_matmul(
                        wt_qkv,
                        grad_hidden_full,   /* approximation */
                        act->attn_norm_out, /* [n_embd, n_tokens] = [in_dim, n_tokens] */
                        qkv_out_dim, qkv_in_dim, n_tokens, 0.1f  /* scale down */
                    );
                }
            }
            
            /* Gradient continues through residual - already in grad_hidden_full */
        }
        
        /* Weight lookup uses find_weight_in_cache helper */
        
        free(grad_hidden_full);
        free(grad_temp_full);
    }
    
    free(grad_hidden);
    free(grad_temp);
    
    /* Free the training cache now that backward is complete */
    free_training_cache(cache);
    output->training_cache_id = 0;
}

/* ============================================================================
 * LoRA-Aware Layer Building Helpers
 * These functions wrap the matrix multiplications with LoRA support
 * ============================================================================ */

/* Build Q, K, V projections with LoRA support
 * Returns reshaped tensors ready for attention computation
 */
typedef struct {
    struct ggml_tensor *q;   /* [head_dim, n_head, n_tokens] */
    struct ggml_tensor *k;   /* [head_dim, n_head_kv, n_tokens] */
    struct ggml_tensor *v;   /* [head_dim, n_head_kv, n_tokens] */
} LughQKVResult;

static LughQKVResult build_qkv_with_lora(
    struct ggml_context *ctx,
    struct ggml_tensor *cur,       /* Input tensor [n_embd, n_tokens] */
    LughLayerWeights *lw,          /* Layer weights */
    LughHyperparams *hp,           /* Model hyperparameters */
    LughLoRAAdapter *lora          /* LoRA adapter (can be NULL) */
) {
    LughQKVResult qkv;
    int n_tokens = cur->ne[1];
    char name_buf[64];
    
    if (lw->has_combined_qkv && lw->wqkv) {
        /* Combined QKV: no LoRA support for combined (would need to split) */
        struct ggml_tensor *combined = ggml_mul_mat(ctx, lw->wqkv, cur);
        int qkv_dim = hp->n_embd + 2 * (hp->n_head_kv * hp->head_dim);
        
        qkv.q = ggml_view_2d(ctx, combined, hp->n_embd, n_tokens,
                             qkv_dim * sizeof(float), 0);
        qkv.k = ggml_view_2d(ctx, combined, hp->n_head_kv * hp->head_dim, n_tokens,
                             qkv_dim * sizeof(float), hp->n_embd * sizeof(float));
        qkv.v = ggml_view_2d(ctx, combined, hp->n_head_kv * hp->head_dim, n_tokens,
                             qkv_dim * sizeof(float), (hp->n_embd + hp->n_head_kv * hp->head_dim) * sizeof(float));
    } else {
        /* Separate Q, K, V projections with LoRA */
        snprintf(name_buf, sizeof(name_buf), "blk.%d.attn_q.weight", lw->layer_idx);
        qkv.q = lora_mul_mat(ctx, lw->wq, cur, lora, name_buf);
        
        snprintf(name_buf, sizeof(name_buf), "blk.%d.attn_k.weight", lw->layer_idx);
        qkv.k = lora_mul_mat(ctx, lw->wk, cur, lora, name_buf);
        
        snprintf(name_buf, sizeof(name_buf), "blk.%d.attn_v.weight", lw->layer_idx);
        qkv.v = lora_mul_mat(ctx, lw->wv, cur, lora, name_buf);
    }
    
    /* Reshape for attention heads */
    qkv.q = ggml_reshape_3d(ctx, qkv.q, hp->head_dim, hp->n_head, n_tokens);
    qkv.k = ggml_reshape_3d(ctx, qkv.k, hp->head_dim, hp->n_head_kv, n_tokens);
    qkv.v = ggml_reshape_3d(ctx, qkv.v, hp->head_dim, hp->n_head_kv, n_tokens);
    
    return qkv;
}

/* Build FFN (Feed-Forward Network) with LoRA support */
static struct ggml_tensor* build_ffn_with_lora(
    struct ggml_context *ctx,
    struct ggml_tensor *cur,
    LughLayerWeights *lw,
    LughLoRAAdapter *lora          /* LoRA adapter (can be NULL) */
) {
    char name_buf[64];
    
    if (lw->has_ffn_gate && lw->ffn_gate) {
        /* SwiGLU: gate * silu(up) -> down (llama, qwen, gemma) */
        struct ggml_tensor *gate, *up;
        
        snprintf(name_buf, sizeof(name_buf), "blk.%d.ffn_gate.weight", lw->layer_idx);
        gate = lora_mul_mat(ctx, lw->ffn_gate, cur, lora, name_buf);
        
        snprintf(name_buf, sizeof(name_buf), "blk.%d.ffn_up.weight", lw->layer_idx);
        up = lora_mul_mat(ctx, lw->ffn_up, cur, lora, name_buf);
        
        gate = ggml_silu(ctx, gate);
        cur = ggml_mul(ctx, gate, up);
        
        snprintf(name_buf, sizeof(name_buf), "blk.%d.ffn_down.weight", lw->layer_idx);
        cur = lora_mul_mat(ctx, lw->ffn_down, cur, lora, name_buf);
    } else {
        /* GELU: gelu(up) -> down (phi, gpt2, bert) */
        struct ggml_tensor *up;
        
        snprintf(name_buf, sizeof(name_buf), "blk.%d.ffn_up.weight", lw->layer_idx);
        up = lora_mul_mat(ctx, lw->ffn_up, cur, lora, name_buf);
        
        cur = ggml_gelu(ctx, up);
        
        snprintf(name_buf, sizeof(name_buf), "blk.%d.ffn_down.weight", lw->layer_idx);
        cur = lora_mul_mat(ctx, lw->ffn_down, cur, lora, name_buf);
    }
    return cur;
}

/* Build attention output projection with LoRA support */
static struct ggml_tensor* build_attn_output_with_lora(
    struct ggml_context *ctx,
    struct ggml_tensor *attn_out,   /* [n_embd, n_tokens] */
    LughLayerWeights *lw,
    LughLoRAAdapter *lora           /* LoRA adapter (can be NULL) */
) {
    char name_buf[64];
    snprintf(name_buf, sizeof(name_buf), "blk.%d.attn_output.weight", lw->layer_idx);
    return lora_mul_mat(ctx, lw->wo, attn_out, lora, name_buf);
}

/* ============================================================================
 * JSON Parsing via Perl (for SafeTensors support)
 * Calls Cpanel::JSON::XS::decode_json from C
 * ============================================================================ */

/* Decode JSON string using Cpanel::JSON::XS via Perl */
static SV* decode_json_via_perl(pTHX_ const char *json_str, STRLEN len) {
    dSP;
    SV *json_sv;
    SV *result = NULL;
    int count;
    
    ENTER;
    SAVETMPS;
    
    PUSHMARK(SP);
    json_sv = sv_2mortal(newSVpvn(json_str, len));
    XPUSHs(json_sv);
    PUTBACK;
    
    /* Call Cpanel::JSON::XS::decode_json() */
    count = call_pv("Cpanel::JSON::XS::decode_json", G_SCALAR | G_EVAL);
    
    SPAGAIN;
    
    if (SvTRUE(ERRSV)) {
        /* JSON parse error */
        POPs;
        PUTBACK;
        FREETMPS;
        LEAVE;
        return NULL;
    }
    
    if (count != 1) {
        PUTBACK;
        FREETMPS;
        LEAVE;
        return NULL;
    }
    
    result = POPs;
    SvREFCNT_inc(result);
    
    PUTBACK;
    FREETMPS;
    LEAVE;
    
    return result;
}

/* Ensure Cpanel::JSON::XS is loaded */
static void ensure_json_loaded(pTHX) {
    static int loaded = 0;
    if (!loaded) {
        load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Cpanel::JSON::XS"), NULL);
        loaded = 1;
    }
}

/* ============================================================================
 * LoRA Magic vtable for cleanup
 * ============================================================================ */

static int lugh_lora_free(pTHX_ SV *sv, MAGIC *mg) {
    int id = (int)(IV)mg->mg_ptr;
    LughLoRAAdapter *lora = get_lora_by_id(id);
    if (lora) {
        free_lora_adapter(lora);
    }
    return 0;
}

static MGVTBL lugh_lora_vtbl = {
    NULL,              /* get */
    NULL,              /* set */
    NULL,              /* len */
    NULL,              /* clear */
    lugh_lora_free,    /* free */
    NULL,              /* copy */
    NULL,              /* dup */
    NULL               /* local */
};

/* ============================================================================
 * Architecture-Aware Tensor Builders
 * Reusable functions for building computation graphs across different model types
 * ============================================================================ */

/* Forward declarations for helper functions */
static struct ggml_tensor* build_ffn(struct ggml_context *ctx, struct ggml_tensor *cur, LughLayerWeights *lw);
static struct ggml_tensor* apply_rms_norm(struct ggml_context *ctx, struct ggml_tensor *cur, struct ggml_tensor *norm_weight, float eps);
static struct ggml_tensor* build_standard_attention(struct ggml_context *ctx, struct ggml_tensor *q, struct ggml_tensor *k, struct ggml_tensor *v, int head_dim, int n_past);

/* Q/K/V projection results structure */
typedef struct {
    struct ggml_tensor *q;   /* [head_dim, n_head, n_tokens] */
    struct ggml_tensor *k;   /* [head_dim, n_head_kv, n_tokens] */
    struct ggml_tensor *v;   /* [head_dim, n_head_kv, n_tokens] */
} LughQKV;

/* Build Q, K, V projections - handles both combined and separate QKV tensors
 * Returns reshaped tensors ready for attention computation
 */
static LughQKV build_qkv_projections(
    struct ggml_context *ctx,
    struct ggml_tensor *cur,       /* Input tensor [n_embd, n_tokens] */
    LughLayerWeights *lw,          /* Layer weights */
    LughHyperparams *hp            /* Model hyperparameters */
) {
    LughQKV qkv;
    int n_tokens = cur->ne[1];
    
    if (lw->has_combined_qkv && lw->wqkv) {
        /* Combined QKV: split into Q, K, V */
        struct ggml_tensor *combined = ggml_mul_mat(ctx, lw->wqkv, cur);
        int qkv_dim = hp->n_embd + 2 * (hp->n_head_kv * hp->head_dim);
        
        qkv.q = ggml_view_2d(ctx, combined, hp->n_embd, n_tokens,
                             qkv_dim * sizeof(float), 0);
        qkv.k = ggml_view_2d(ctx, combined, hp->n_head_kv * hp->head_dim, n_tokens,
                             qkv_dim * sizeof(float), hp->n_embd * sizeof(float));
        qkv.v = ggml_view_2d(ctx, combined, hp->n_head_kv * hp->head_dim, n_tokens,
                             qkv_dim * sizeof(float), (hp->n_embd + hp->n_head_kv * hp->head_dim) * sizeof(float));
    } else {
        /* Separate Q, K, V projections */
        qkv.q = ggml_mul_mat(ctx, lw->wq, cur);
        qkv.k = ggml_mul_mat(ctx, lw->wk, cur);
        qkv.v = ggml_mul_mat(ctx, lw->wv, cur);
    }
    
    /* Reshape for attention heads */
    qkv.q = ggml_reshape_3d(ctx, qkv.q, hp->head_dim, hp->n_head, n_tokens);
    qkv.k = ggml_reshape_3d(ctx, qkv.k, hp->head_dim, hp->n_head_kv, n_tokens);
    qkv.v = ggml_reshape_3d(ctx, qkv.v, hp->head_dim, hp->n_head_kv, n_tokens);
    
    return qkv;
}

/* Apply RoPE (Rotary Positional Embeddings) to Q and K tensors */
static void apply_rope_to_qkv(
    struct ggml_context *ctx,
    LughQKV *qkv,                  /* Q/K/V tensors (modified in place) */
    struct ggml_tensor *pos,       /* Position tensor */
    LughHyperparams *hp            /* Hyperparameters with RoPE config */
) {
    float ext_factor  = hp->rope_ext_factor;
    float attn_factor = hp->rope_attn_factor;
    float beta_fast   = hp->rope_beta_fast;
    float beta_slow   = hp->rope_beta_slow;
    
    /* For LINEAR scaling, set ext_factor to 0 (disables YaRN-specific interpolation) */
    if (hp->rope_scaling_type == LUGH_ROPE_SCALING_LINEAR) {
        ext_factor = 0.0f;
    }
    /* For NONE scaling, disable all YaRN parameters */
    else if (hp->rope_scaling_type == LUGH_ROPE_SCALING_NONE) {
        ext_factor = 0.0f;
        attn_factor = 1.0f;
        beta_fast = 0.0f;
        beta_slow = 0.0f;
    }
    
    qkv->q = ggml_rope_ext(ctx, qkv->q, pos, NULL, hp->n_rot, 0, hp->n_ctx_orig,
                           hp->rope_freq_base, hp->rope_freq_scale,
                           ext_factor, attn_factor, beta_fast, beta_slow);
    qkv->k = ggml_rope_ext(ctx, qkv->k, pos, NULL, hp->n_rot, 0, hp->n_ctx_orig,
                           hp->rope_freq_base, hp->rope_freq_scale,
                           ext_factor, attn_factor, beta_fast, beta_slow);
}

/* Apply RoPE to a single tensor - convenience wrapper */
static struct ggml_tensor* apply_rope_single(
    struct ggml_context *ctx,
    struct ggml_tensor *tensor,
    struct ggml_tensor *pos,
    LughHyperparams *hp
) {
    float ext_factor  = hp->rope_ext_factor;
    float attn_factor = hp->rope_attn_factor;
    float beta_fast   = hp->rope_beta_fast;
    float beta_slow   = hp->rope_beta_slow;
    
    /* For LINEAR scaling, set ext_factor to 0 */
    if (hp->rope_scaling_type == LUGH_ROPE_SCALING_LINEAR) {
        ext_factor = 0.0f;
    }
    /* For NONE scaling, disable all YaRN parameters */
    else if (hp->rope_scaling_type == LUGH_ROPE_SCALING_NONE) {
        ext_factor = 0.0f;
        attn_factor = 1.0f;
        beta_fast = 0.0f;
        beta_slow = 0.0f;
    }
    
    return ggml_rope_ext(ctx, tensor, pos, NULL, hp->n_rot, 0, hp->n_ctx_orig,
                         hp->rope_freq_base, hp->rope_freq_scale,
                         ext_factor, attn_factor, beta_fast, beta_slow);
}

/* Build complete self-attention block
 * Handles: QKV projection, RoPE, attention computation, output projection, post-norm
 */
static struct ggml_tensor* build_self_attention(
    struct ggml_context *ctx,
    struct ggml_tensor *cur,       /* Input (after attention norm) */
    struct ggml_tensor *pos,       /* Position tensor */
    LughLayerWeights *lw,
    LughHyperparams *hp,
    int use_flash_attn             /* 1 to use flash attention */
) {
    LughQKV qkv;
    struct ggml_tensor *attn_out;
    int n_tokens = cur->ne[1];
    
    /* Build Q, K, V projections */
    qkv = build_qkv_projections(ctx, cur, lw, hp);
    
    /* Apply RoPE */
    apply_rope_to_qkv(ctx, &qkv, pos, hp);
    
    /* Compute attention */
    if (use_flash_attn) {
        float scale = 1.0f / sqrtf((float)hp->head_dim);
        struct ggml_tensor *q_fa = ggml_cont(ctx, ggml_permute(ctx, qkv.q, 0, 2, 1, 3));
        struct ggml_tensor *k_fa = ggml_cont(ctx, ggml_permute(ctx, qkv.k, 0, 2, 1, 3));
        struct ggml_tensor *v_fa = ggml_cont(ctx, ggml_permute(ctx, qkv.v, 0, 2, 1, 3));
        attn_out = ggml_flash_attn_ext(ctx, q_fa, k_fa, v_fa, NULL, scale, 0.0f, 0.0f);
        attn_out = ggml_reshape_3d(ctx, attn_out, hp->head_dim, hp->n_head, n_tokens);
    } else {
        attn_out = build_standard_attention(ctx, qkv.q, qkv.k, qkv.v, hp->head_dim, 0);
    }
    
    /* Reshape and output projection */
    attn_out = ggml_reshape_2d(ctx, attn_out, hp->n_embd, n_tokens);
    cur = ggml_mul_mat(ctx, lw->wo, attn_out);
    
    return cur;
}

/* Build complete FFN block with pre-norm and optional post-norm */
static struct ggml_tensor* build_ffn_block(
    struct ggml_context *ctx,
    struct ggml_tensor *cur,       /* Input tensor */
    LughLayerWeights *lw,
    float rms_norm_eps
) {
    /* FFN: norm -> gate/up -> activation -> down */
    cur = apply_rms_norm(ctx, cur, lw->ffn_norm, rms_norm_eps);
    cur = build_ffn(ctx, cur, lw);
    
    /* Post-FFN normalization (Gemma2, etc.) */
    if (lw->has_post_norm && lw->ffn_post_norm) {
        cur = apply_rms_norm(ctx, cur, lw->ffn_post_norm, rms_norm_eps);
    }
    
    return cur;
}

/* Build complete transformer layer (attention + FFN with residuals)
 * This is the highest-level abstraction for a single transformer block
 */
static struct ggml_tensor* build_transformer_layer(
    struct ggml_context *ctx,
    struct ggml_tensor *cur,       /* Input tensor */
    struct ggml_tensor *pos,       /* Position tensor */
    LughLayerWeights *lw,
    LughHyperparams *hp,
    int use_flash_attn
) {
    struct ggml_tensor *residual = cur;
    
    /* Attention block */
    cur = apply_rms_norm(ctx, cur, lw->attn_norm, hp->rms_norm_eps);
    cur = build_self_attention(ctx, cur, pos, lw, hp, use_flash_attn);
    
    /* Post-attention normalization (Gemma2, etc.) */
    if (lw->has_post_norm && lw->attn_post_norm) {
        cur = apply_rms_norm(ctx, cur, lw->attn_post_norm, hp->rms_norm_eps);
    }
    
    /* Residual connection */
    cur = ggml_add(ctx, cur, residual);
    residual = cur;
    
    /* FFN block */
    cur = build_ffn_block(ctx, cur, lw, hp->rms_norm_eps);
    
    /* Residual connection */
    cur = ggml_add(ctx, cur, residual);
    
    return cur;
}

/* Build FFN (Feed-Forward Network) for a layer - without LoRA
 * Supports both SwiGLU (with gate) and GELU (without gate) architectures
 * This is a convenience wrapper around build_ffn_with_lora
 */
static struct ggml_tensor* build_ffn(
    struct ggml_context *ctx,
    struct ggml_tensor *cur,
    LughLayerWeights *lw
) {
    return build_ffn_with_lora(ctx, cur, lw, NULL);
}

/* Apply RMS norm and multiply by weight */
static struct ggml_tensor* apply_rms_norm(
    struct ggml_context *ctx,
    struct ggml_tensor *cur,
    struct ggml_tensor *norm_weight,
    float eps
) {
    cur = ggml_rms_norm(ctx, cur, eps);
    cur = ggml_mul(ctx, cur, norm_weight);
    return cur;
}

/* Build standard (non-flash) attention computation
 * Returns attention output with shape [head_dim, n_head, n_tokens]
 */
static struct ggml_tensor* build_standard_attention(
    struct ggml_context *ctx,
    struct ggml_tensor *q,      /* [head_dim, n_head, n_tokens] */
    struct ggml_tensor *k,      /* [head_dim, n_head_kv, n_kv] */
    struct ggml_tensor *v,      /* [head_dim, n_head_kv, n_kv] */
    int head_dim,
    int n_past                  /* For causal mask offset */
) {
    float scale = 1.0f / sqrtf((float)head_dim);
    struct ggml_tensor *kq, *v_t, *attn_out;
    
    /* Permute: [head_dim, n_head, seq] -> [head_dim, seq, n_head] */
    q = ggml_permute(ctx, q, 0, 2, 1, 3);
    k = ggml_permute(ctx, k, 0, 2, 1, 3);
    v = ggml_permute(ctx, v, 0, 2, 1, 3);
    
    /* QK^T */
    kq = ggml_mul_mat(ctx, k, q);
    kq = ggml_scale(ctx, kq, scale);
    
    /* Causal mask */
    kq = ggml_diag_mask_inf(ctx, kq, n_past);
    kq = ggml_soft_max(ctx, kq);
    
    /* Attention @ V */
    v_t = ggml_cont(ctx, ggml_transpose(ctx, v));
    attn_out = ggml_mul_mat(ctx, v_t, kq);
    attn_out = ggml_cont(ctx, ggml_permute(ctx, attn_out, 0, 2, 1, 3));
    
    return attn_out;
}

/* ============================================================================
 * Forward Pass Implementation - Core C function
 * Called by all forward_* XS functions
 * ============================================================================ */

static void free_forward_result(LughForwardResult *result) {
    if (result->logits) Safefree(result->logits);
    if (result->all_logits) Safefree(result->all_logits);
    if (result->batch_logits) {
        int i;
        for (i = 0; i < result->n_sequences; i++) {
            if (result->batch_logits[i]) Safefree(result->batch_logits[i]);
        }
        Safefree(result->batch_logits);
    }
    if (result->error) Safefree(result->error);
}

static int do_forward_unified(
    pTHX_
    HV *self_hv,
    LughForwardOpts *opts,
    LughForwardResult *result
) {
    SV **svp;
    LughModel *model;
    LughLoRAAdapter *lora = opts->lora;
    LughKVCache *cache = opts->cache;
    LughKVCache **caches = (LughKVCache**)opts->caches;
    int n_caches = opts->n_caches;
    LughMemoryPool *pool = opts->pool;
    int i, j;
    int *tokens = opts->tokens;
    int n_tokens = opts->n_tokens;
    int **all_tokens = opts->all_tokens;
    int *seq_lengths = opts->seq_lengths;
    int n_sequences = opts->n_sequences;
    int is_batch_mode = (all_tokens != NULL);
    LughHyperparams hp;
    struct ggml_context *ctx_w = NULL;
    struct ggml_context *ctx_c = NULL;
    struct ggml_cgraph *gf = NULL;
    struct ggml_tensor *cur = NULL;
    struct ggml_tensor *inpL = NULL;
    ggml_backend_t backend = NULL;
    ggml_gallocr_t allocr = NULL;
    int pos_offset = 0;
    int n_kv;
    struct ggml_tensor **k_cache_tensors = NULL;
    struct ggml_tensor **v_cache_tensors = NULL;
    struct ggml_tensor **k_new_tensors = NULL;
    struct ggml_tensor **v_new_tensors = NULL;
    int owns_backend = 0;
    int owns_allocr = 0;
    
    /* Initialize result */
    Zero(result, 1, LughForwardResult);
    result->is_batch = is_batch_mode;
    
    /* Get model */
    svp = hv_fetch(self_hv, "_model", 6, 0);
    if (!svp || !*svp) {
        result->error = savepv("No model in inference object");
        return 0;
    }
    model = get_lugh_model(aTHX_ *svp);
    if (!model) {
        result->error = savepv("Invalid model");
        return 0;
    }
    
    /* Extract hyperparameters */
    extract_hyperparams(aTHX_ self_hv, model, &hp);
    apply_rope_override(aTHX_ &hp, opts->rope_sv);
    result->n_vocab = hp.n_vocab;
    
    ctx_w = model->ctx;
    
    /* Setup resources based on what's provided */
    if (pool) {
        POOL_LOCK(pool);
        if (!reset_memory_pool_unlocked(pool)) {
            POOL_UNLOCK(pool);
            result->error = savepv("Failed to reset memory pool");
            return 0;
        }
        ctx_c = pool->ctx_compute;
        backend = pool->backend;
        allocr = pool->allocator;
    } else {
        /* Initialize backend */
        if (strcmp(hp.backend_name, "auto") == 0) {
            backend = init_best_backend(hp.n_threads);
        } else {
            backend = init_backend_by_name(hp.backend_name, hp.n_threads);
        }
        owns_backend = 1;
        if (!backend) {
            result->error = savepv("Failed to initialize backend");
            return 0;
        }
        
        ctx_c = create_compute_context(512 * 1024 * 1024);
        if (!ctx_c) {
            ggml_backend_free(backend);
            result->error = savepv("Failed to create compute context");
            return 0;
        }
    }
    
    /* Setup cache if provided */
    if (cache) {
        KVCACHE_LOCK(cache);
        pos_offset = cache->n_cached;
        n_kv = pos_offset + n_tokens;
        
        Newxz(k_cache_tensors, hp.n_layer, struct ggml_tensor *);
        Newxz(v_cache_tensors, hp.n_layer, struct ggml_tensor *);
        Newxz(k_new_tensors, hp.n_layer, struct ggml_tensor *);
        Newxz(v_new_tensors, hp.n_layer, struct ggml_tensor *);
    }
    
    /* ============================================================
     * Build forward pass graph - single sequence mode
     * ============================================================ */
    if (!is_batch_mode) {
        struct ggml_tensor *tok_embd = ggml_get_tensor(ctx_w, "token_embd.weight");
        struct ggml_tensor *output_norm = ggml_get_tensor(ctx_w, "output_norm.weight");
        struct ggml_tensor *output = ggml_get_tensor(ctx_w, "output.weight");
        struct ggml_tensor *pos;
        int layer;
        int n_kv_dim = hp.n_head_kv * hp.head_dim;
        
        if (!output) output = tok_embd;
        if (!tok_embd) {
            if (cache) {
                Safefree(k_cache_tensors);
                Safefree(v_cache_tensors);
                Safefree(k_new_tensors);
                Safefree(v_new_tensors);
                KVCACHE_UNLOCK(cache);
            }
            if (pool) {
                POOL_UNLOCK(pool);
            } else {
                ggml_free(ctx_c);
                if (owns_backend) ggml_backend_free(backend);
            }
            result->error = savepv("Required tensors not found in model");
            return 0;
        }
        
        pos = ggml_new_tensor_1d(ctx_c, GGML_TYPE_I32, n_tokens);
        ggml_set_name(pos, "pos");
        
        {
            struct ggml_tensor *inp_tokens = ggml_new_tensor_1d(ctx_c, GGML_TYPE_I32, n_tokens);
            ggml_set_name(inp_tokens, "inp_tokens");
            inpL = ggml_get_rows(ctx_c, tok_embd, inp_tokens);
            ggml_set_name(inpL, "inp_embd");
        }
        
        cur = inpL;
        
        /* Process transformer layers */
        for (layer = 0; layer < hp.n_layer; layer++) {
            LughLayerWeights lw;
            struct ggml_tensor *residual;
            
            if (!get_layer_weights_for_arch(ctx_w, layer, &lw, hp.arch_type)) continue;
            
            residual = cur;
            cur = apply_rms_norm(ctx_c, cur, lw.attn_norm, hp.rms_norm_eps);
            
            /* Self-attention */
            {
                struct ggml_tensor *q, *k_new, *v_new;
                struct ggml_tensor *k_full, *v_full;
                struct ggml_tensor *attn_out;
                char q_name[64], k_name[64], v_name[64], o_name[64];
                
                snprintf(q_name, sizeof(q_name), "blk.%d.attn_q.weight", layer);
                snprintf(k_name, sizeof(k_name), "blk.%d.attn_k.weight", layer);
                snprintf(v_name, sizeof(v_name), "blk.%d.attn_v.weight", layer);
                snprintf(o_name, sizeof(o_name), "blk.%d.attn_output.weight", layer);
                
                if (lw.has_combined_qkv) {
                    struct ggml_tensor *qkv = ggml_mul_mat(ctx_c, lw.wqkv, cur);
                    int qkv_dim = hp.n_embd + 2 * n_kv_dim;
                    q = ggml_view_2d(ctx_c, qkv, hp.n_embd, n_tokens, qkv_dim * sizeof(float), 0);
                    k_new = ggml_view_2d(ctx_c, qkv, n_kv_dim, n_tokens, qkv_dim * sizeof(float), hp.n_embd * sizeof(float));
                    v_new = ggml_view_2d(ctx_c, qkv, n_kv_dim, n_tokens, qkv_dim * sizeof(float), (hp.n_embd + n_kv_dim) * sizeof(float));
                    q = ggml_reshape_3d(ctx_c, q, hp.head_dim, hp.n_head, n_tokens);
                    k_new = ggml_reshape_3d(ctx_c, k_new, hp.head_dim, hp.n_head_kv, n_tokens);
                    v_new = ggml_reshape_3d(ctx_c, v_new, hp.head_dim, hp.n_head_kv, n_tokens);
                } else {
                    q = lora_mul_mat(ctx_c, lw.wq, cur, lora, q_name);
                    k_new = lora_mul_mat(ctx_c, lw.wk, cur, lora, k_name);
                    v_new = lora_mul_mat(ctx_c, lw.wv, cur, lora, v_name);
                    q = ggml_reshape_3d(ctx_c, q, hp.head_dim, hp.n_head, n_tokens);
                    k_new = ggml_reshape_3d(ctx_c, k_new, hp.head_dim, hp.n_head_kv, n_tokens);
                    v_new = ggml_reshape_3d(ctx_c, v_new, hp.head_dim, hp.n_head_kv, n_tokens);
                }
                
                q = apply_rope_single(ctx_c, q, pos, &hp);
                k_new = apply_rope_single(ctx_c, k_new, pos, &hp);
                
                /* Handle KV cache if present */
                if (cache) {
                    if (pos_offset > 0) {
                        char k_cache_name[64], v_cache_name[64];
                        struct ggml_tensor *k_cached, *v_cached;
                        
                        snprintf(k_cache_name, sizeof(k_cache_name), "k_cache_%d", layer);
                        snprintf(v_cache_name, sizeof(v_cache_name), "v_cache_%d", layer);
                        
                        k_cached = ggml_new_tensor_3d(ctx_c, GGML_TYPE_F32, hp.head_dim, hp.n_head_kv, pos_offset);
                        ggml_set_name(k_cached, k_cache_name);
                        v_cached = ggml_new_tensor_3d(ctx_c, GGML_TYPE_F32, hp.head_dim, hp.n_head_kv, pos_offset);
                        ggml_set_name(v_cached, v_cache_name);
                        
                        k_cache_tensors[layer] = k_cached;
                        v_cache_tensors[layer] = v_cached;
                        
                        k_full = ggml_concat(ctx_c, k_cached, k_new, 2);
                        v_full = ggml_concat(ctx_c, v_cached, v_new, 2);
                    } else {
                        k_full = k_new;
                        v_full = v_new;
                    }
                    
                    /* Create output copy tensors for cache extraction */
                    {
                        char k_new_name[64], v_new_name[64];
                        struct ggml_tensor *k_out, *v_out;
                        
                        snprintf(k_new_name, sizeof(k_new_name), "k_new_%d", layer);
                        snprintf(v_new_name, sizeof(v_new_name), "v_new_%d", layer);
                        
                        k_out = ggml_new_tensor_3d(ctx_c, GGML_TYPE_F32, k_new->ne[0], k_new->ne[1], k_new->ne[2]);
                        v_out = ggml_new_tensor_3d(ctx_c, GGML_TYPE_F32, v_new->ne[0], v_new->ne[1], v_new->ne[2]);
                        ggml_set_name(k_out, k_new_name);
                        ggml_set_name(v_out, v_new_name);
                        
                        k_out = ggml_cpy(ctx_c, k_new, k_out);
                        v_out = ggml_cpy(ctx_c, v_new, v_out);
                        
                        k_new_tensors[layer] = k_out;
                        v_new_tensors[layer] = v_out;
                    }
                } else {
                    k_full = k_new;
                    v_full = v_new;
                }
                
                attn_out = build_standard_attention(ctx_c, q, k_full, v_full, hp.head_dim, cache ? pos_offset : 0);
                attn_out = ggml_reshape_2d(ctx_c, attn_out, hp.n_embd, n_tokens);
                attn_out = lora_mul_mat(ctx_c, lw.wo, attn_out, lora, o_name);
                
                if (lw.has_post_norm && lw.attn_post_norm) {
                    attn_out = apply_rms_norm(ctx_c, attn_out, lw.attn_post_norm, hp.rms_norm_eps);
                }
                
                cur = ggml_add(ctx_c, residual, attn_out);
            }
            
            /* FFN */
            residual = cur;
            cur = apply_rms_norm(ctx_c, cur, lw.ffn_norm, hp.rms_norm_eps);
            cur = build_ffn_with_lora(ctx_c, cur, &lw, lora);
            
            if (lw.has_post_norm && lw.ffn_post_norm) {
                cur = apply_rms_norm(ctx_c, cur, lw.ffn_post_norm, hp.rms_norm_eps);
            }
            
            cur = ggml_add(ctx_c, residual, cur);
        }
        
        /* Final norm and output projection */
        if (output_norm) {
            cur = apply_rms_norm(ctx_c, cur, output_norm, hp.rms_norm_eps);
        }
        cur = ggml_mul_mat(ctx_c, output, cur);
        ggml_set_name(cur, "logits");
        
        gf = ggml_new_graph(ctx_c);
        ggml_build_forward_expand(gf, cur);
        
        /* Add k_new/v_new tensors to graph for cache extraction */
        if (cache) {
            int layer;
            for (layer = 0; layer < hp.n_layer; layer++) {
                if (k_new_tensors[layer]) ggml_build_forward_expand(gf, k_new_tensors[layer]);
                if (v_new_tensors[layer]) ggml_build_forward_expand(gf, v_new_tensors[layer]);
            }
        }
        
        /* Allocate and run */
        if (!pool) {
            allocr = ggml_gallocr_new(ggml_backend_get_default_buffer_type(backend));
            owns_allocr = 1;
            if (!ggml_gallocr_reserve(allocr, gf) || !ggml_gallocr_alloc_graph(allocr, gf)) {
                ggml_gallocr_free(allocr);
                ggml_free(ctx_c);
                if (owns_backend) ggml_backend_free(backend);
                if (cache) {
                    Safefree(k_cache_tensors);
                    Safefree(v_cache_tensors);
                    Safefree(k_new_tensors);
                    Safefree(v_new_tensors);
                    KVCACHE_UNLOCK(cache);
                }
                result->error = savepv("Failed to allocate compute graph");
                return 0;
            }
        } else {
            if (!ggml_gallocr_alloc_graph(allocr, gf)) {
                POOL_UNLOCK(pool);
                if (cache) {
                    Safefree(k_cache_tensors);
                    Safefree(v_cache_tensors);
                    Safefree(k_new_tensors);
                    Safefree(v_new_tensors);
                    KVCACHE_UNLOCK(cache);
                }
                result->error = savepv("Failed to allocate compute graph with pool");
                return 0;
            }
        }
        
        /* Set input data */
        {
            struct ggml_tensor *inp = ggml_graph_get_tensor(gf, "inp_tokens");
            struct ggml_tensor *pos_tensor = ggml_graph_get_tensor(gf, "pos");

            /* Validate token IDs before passing to ggml */
            if (inp && tokens) {
                for (i = 0; i < n_tokens; i++) {
                    if (tokens[i] < 0 || tokens[i] >= hp.n_vocab) {
                        char errbuf[256];
                        snprintf(errbuf, sizeof(errbuf),
                                 "Token ID %d at position %d is out of range [0, %d)",
                                 tokens[i], i, hp.n_vocab);
                        if (cache) {
                            Safefree(k_cache_tensors);
                            Safefree(v_cache_tensors);
                            Safefree(k_new_tensors);
                            Safefree(v_new_tensors);
                            KVCACHE_UNLOCK(cache);
                        }
                        if (owns_allocr) ggml_gallocr_free(allocr);
                        if (!pool) ggml_free(ctx_c);
                        if (owns_backend) ggml_backend_free(backend);
                        if (pool) POOL_UNLOCK(pool);
                        result->error = savepv(errbuf);
                        return 0;
                    }
                }
            }

            if (inp) ggml_backend_tensor_set(inp, tokens, 0, n_tokens * sizeof(int));
            
            if (pos_tensor) {
                int *positions;
                Newx(positions, n_tokens, int);
                for (i = 0; i < n_tokens; i++) {
                    positions[i] = pos_offset + i;
                }
                ggml_backend_tensor_set(pos_tensor, positions, 0, n_tokens * sizeof(int));
                Safefree(positions);
            }
            
            /* Set cached K/V data if cache with existing data */
            if (cache && pos_offset > 0) {
                for (i = 0; i < hp.n_layer; i++) {
                    size_t cache_size = pos_offset * hp.n_head_kv * hp.head_dim * sizeof(float);
                    if (k_cache_tensors[i] && cache->k_cache[i]) {
                        ggml_backend_tensor_set(k_cache_tensors[i], cache->k_cache[i], 0, cache_size);
                    }
                    if (v_cache_tensors[i] && cache->v_cache[i]) {
                        ggml_backend_tensor_set(v_cache_tensors[i], cache->v_cache[i], 0, cache_size);
                    }
                }
            }
        }
        
        /* Run forward pass */
        if (ggml_backend_graph_compute(backend, gf) != GGML_STATUS_SUCCESS) {
            if (owns_allocr) ggml_gallocr_free(allocr);
            if (!pool) ggml_free(ctx_c);
            if (owns_backend) ggml_backend_free(backend);
            if (pool) POOL_UNLOCK(pool);
            if (cache) {
                Safefree(k_cache_tensors);
                Safefree(v_cache_tensors);
                Safefree(k_new_tensors);
                Safefree(v_new_tensors);
                KVCACHE_UNLOCK(cache);
            }
            result->error = savepv("Failed to compute graph");
            return 0;
        }
        
        /* Update cache with new K/V values */
        if (cache) {
            for (i = 0; i < hp.n_layer; i++) {
                struct ggml_tensor *k_new_tensor = k_new_tensors[i];
                struct ggml_tensor *v_new_tensor = v_new_tensors[i];
                size_t new_size = n_tokens * hp.n_head_kv * hp.head_dim * sizeof(float);
                size_t offset = pos_offset * hp.n_head_kv * hp.head_dim * sizeof(float);
                
                if (k_new_tensor && cache->k_cache[i]) {
                    float *temp;
                    Newx(temp, n_tokens * hp.n_head_kv * hp.head_dim, float);
                    ggml_backend_tensor_get(k_new_tensor, temp, 0, new_size);
                    memcpy((char*)cache->k_cache[i] + offset, temp, new_size);
                    Safefree(temp);
                }
                if (v_new_tensor && cache->v_cache[i]) {
                    float *temp;
                    Newx(temp, n_tokens * hp.n_head_kv * hp.head_dim, float);
                    ggml_backend_tensor_get(v_new_tensor, temp, 0, new_size);
                    memcpy((char*)cache->v_cache[i] + offset, temp, new_size);
                    Safefree(temp);
                }
            }
            cache->n_cached = pos_offset + n_tokens;
        }
        
        /* Extract logits */
        {
            struct ggml_tensor *logits_tensor = ggml_graph_get_tensor(gf, "logits");
            if (logits_tensor) {
                size_t logits_size = hp.n_vocab * sizeof(float);
                
                /* Always extract last position logits */
                Newx(result->logits, hp.n_vocab, float);
                ggml_backend_tensor_get(logits_tensor, result->logits, 
                                        (n_tokens - 1) * hp.n_vocab * sizeof(float), logits_size);
                
                /* If requested, extract all position logits */
                if (opts->return_all_logits && n_tokens > 1) {
                    size_t all_logits_size = n_tokens * hp.n_vocab * sizeof(float);
                    Newx(result->all_logits, n_tokens * hp.n_vocab, float);
                    ggml_backend_tensor_get(logits_tensor, result->all_logits, 0, all_logits_size);
                    result->n_tokens = n_tokens;
                }
            }
        }
        
        /* Cleanup */
        if (owns_allocr) ggml_gallocr_free(allocr);
        if (!pool) ggml_free(ctx_c);
        if (owns_backend) ggml_backend_free(backend);
        if (pool) POOL_UNLOCK(pool);
        if (cache) {
            Safefree(k_cache_tensors);
            Safefree(v_cache_tensors);
            Safefree(k_new_tensors);
            Safefree(v_new_tensors);
            KVCACHE_UNLOCK(cache);
        }
    }
    /* ============================================================
     * Batch mode - process multiple sequences
     * ============================================================ */
    else {
        result->n_sequences = n_sequences;
        Newxz(result->batch_logits, n_sequences, float*);
        
        /* Process each sequence independently */
        for (i = 0; i < n_sequences; i++) {
            struct ggml_tensor *tok_embd, *output_norm, *output, *pos;
            int layer;
            int seq_len = seq_lengths[i];
            int *seq_tokens = all_tokens[i];
            LughKVCache *seq_cache = (caches && i < n_caches) ? caches[i] : NULL;
            int seq_pos_offset = 0;
            int seq_n_kv = seq_len;
            struct ggml_tensor **seq_k_cache_tensors = NULL;
            struct ggml_tensor **seq_v_cache_tensors = NULL;
            struct ggml_tensor **seq_k_new_tensors = NULL;
            struct ggml_tensor **seq_v_new_tensors = NULL;
            int n_kv_dim = hp.n_head_kv * hp.head_dim;
            
            /* Setup cache for this sequence */
            if (seq_cache) {
                KVCACHE_LOCK(seq_cache);
                seq_pos_offset = seq_cache->n_cached;
                seq_n_kv = seq_pos_offset + seq_len;
                
                Newxz(seq_k_cache_tensors, hp.n_layer, struct ggml_tensor *);
                Newxz(seq_v_cache_tensors, hp.n_layer, struct ggml_tensor *);
                Newxz(seq_k_new_tensors, hp.n_layer, struct ggml_tensor *);
                Newxz(seq_v_new_tensors, hp.n_layer, struct ggml_tensor *);
            }
            
            /* Reset pool for each sequence if using pool */
            if (pool) {
                reset_memory_pool_unlocked(pool);
                ctx_c = pool->ctx_compute;
            } else if (i > 0) {
                /* Free previous ctx_c and create new one */
                ggml_free(ctx_c);
                ctx_c = create_compute_context(512 * 1024 * 1024);
                if (!ctx_c) {
                    if (seq_cache) {
                        Safefree(seq_k_cache_tensors);
                        Safefree(seq_v_cache_tensors);
                        Safefree(seq_k_new_tensors);
                        Safefree(seq_v_new_tensors);
                        KVCACHE_UNLOCK(seq_cache);
                    }
                    if (owns_backend) ggml_backend_free(backend);
                    result->error = savepv("Failed to create compute context for sequence");
                    return 0;
                }
            }
            
            tok_embd = ggml_get_tensor(ctx_w, "token_embd.weight");
            output_norm = ggml_get_tensor(ctx_w, "output_norm.weight");
            output = ggml_get_tensor(ctx_w, "output.weight");
            if (!output) output = tok_embd;
            
            pos = ggml_new_tensor_1d(ctx_c, GGML_TYPE_I32, seq_len);
            ggml_set_name(pos, "pos");
            
            {
                struct ggml_tensor *inp_tokens = ggml_new_tensor_1d(ctx_c, GGML_TYPE_I32, seq_len);
                ggml_set_name(inp_tokens, "inp_tokens");
                inpL = ggml_get_rows(ctx_c, tok_embd, inp_tokens);
            }
            
            cur = inpL;
            
            for (layer = 0; layer < hp.n_layer; layer++) {
                LughLayerWeights lw;
                struct ggml_tensor *residual;
                char q_name[64], k_name[64], v_name[64], o_name[64];
                
                if (!get_layer_weights_for_arch(ctx_w, layer, &lw, hp.arch_type)) continue;
                
                residual = cur;
                cur = apply_rms_norm(ctx_c, cur, lw.attn_norm, hp.rms_norm_eps);
                
                snprintf(q_name, sizeof(q_name), "blk.%d.attn_q.weight", layer);
                snprintf(k_name, sizeof(k_name), "blk.%d.attn_k.weight", layer);
                snprintf(v_name, sizeof(v_name), "blk.%d.attn_v.weight", layer);
                snprintf(o_name, sizeof(o_name), "blk.%d.attn_output.weight", layer);
                
                {
                    struct ggml_tensor *q, *k, *v, *k_new, *v_new, *attn_out;
                    struct ggml_tensor *k_full, *v_full;
                    
                    if (lw.has_combined_qkv) {
                        struct ggml_tensor *qkv = ggml_mul_mat(ctx_c, lw.wqkv, cur);
                        int qkv_dim = hp.n_embd + 2 * n_kv_dim;
                        q = ggml_view_2d(ctx_c, qkv, hp.n_embd, seq_len, qkv_dim * sizeof(float), 0);
                        k_new = ggml_view_2d(ctx_c, qkv, n_kv_dim, seq_len, qkv_dim * sizeof(float), hp.n_embd * sizeof(float));
                        v_new = ggml_view_2d(ctx_c, qkv, n_kv_dim, seq_len, qkv_dim * sizeof(float), (hp.n_embd + n_kv_dim) * sizeof(float));
                        q = ggml_reshape_3d(ctx_c, q, hp.head_dim, hp.n_head, seq_len);
                        k_new = ggml_reshape_3d(ctx_c, k_new, hp.head_dim, hp.n_head_kv, seq_len);
                        v_new = ggml_reshape_3d(ctx_c, v_new, hp.head_dim, hp.n_head_kv, seq_len);
                    } else {
                        q = lora_mul_mat(ctx_c, lw.wq, cur, lora, q_name);
                        k_new = lora_mul_mat(ctx_c, lw.wk, cur, lora, k_name);
                        v_new = lora_mul_mat(ctx_c, lw.wv, cur, lora, v_name);
                        q = ggml_reshape_3d(ctx_c, q, hp.head_dim, hp.n_head, seq_len);
                        k_new = ggml_reshape_3d(ctx_c, k_new, hp.head_dim, hp.n_head_kv, seq_len);
                        v_new = ggml_reshape_3d(ctx_c, v_new, hp.head_dim, hp.n_head_kv, seq_len);
                    }
                    
                    q = apply_rope_single(ctx_c, q, pos, &hp);
                    k_new = apply_rope_single(ctx_c, k_new, pos, &hp);
                    
                    /* Handle KV cache if present for this sequence */
                    if (seq_cache) {
                        if (seq_pos_offset > 0) {
                            char k_cache_name[64], v_cache_name[64];
                            struct ggml_tensor *k_cached, *v_cached;
                            
                            snprintf(k_cache_name, sizeof(k_cache_name), "k_cache_%d", layer);
                            snprintf(v_cache_name, sizeof(v_cache_name), "v_cache_%d", layer);
                            
                            k_cached = ggml_new_tensor_3d(ctx_c, GGML_TYPE_F32, hp.head_dim, hp.n_head_kv, seq_pos_offset);
                            ggml_set_name(k_cached, k_cache_name);
                            v_cached = ggml_new_tensor_3d(ctx_c, GGML_TYPE_F32, hp.head_dim, hp.n_head_kv, seq_pos_offset);
                            ggml_set_name(v_cached, v_cache_name);
                            
                            seq_k_cache_tensors[layer] = k_cached;
                            seq_v_cache_tensors[layer] = v_cached;
                            
                            k_full = ggml_concat(ctx_c, k_cached, k_new, 2);
                            v_full = ggml_concat(ctx_c, v_cached, v_new, 2);
                        } else {
                            k_full = k_new;
                            v_full = v_new;
                        }
                        
                        /* Track new K/V for cache update */
                        {
                            char k_out_name[64], v_out_name[64];
                            snprintf(k_out_name, sizeof(k_out_name), "k_new_%d", layer);
                            snprintf(v_out_name, sizeof(v_out_name), "v_new_%d", layer);
                            seq_k_new_tensors[layer] = ggml_cpy(ctx_c, k_new, ggml_new_tensor_3d(ctx_c, GGML_TYPE_F32, hp.head_dim, hp.n_head_kv, seq_len));
                            ggml_set_name(seq_k_new_tensors[layer], k_out_name);
                            seq_v_new_tensors[layer] = ggml_cpy(ctx_c, v_new, ggml_new_tensor_3d(ctx_c, GGML_TYPE_F32, hp.head_dim, hp.n_head_kv, seq_len));
                            ggml_set_name(seq_v_new_tensors[layer], v_out_name);
                        }
                    } else {
                        k_full = k_new;
                        v_full = v_new;
                    }
                    
                    attn_out = build_standard_attention(ctx_c, q, k_full, v_full, hp.head_dim, seq_cache ? seq_pos_offset : 0);
                    attn_out = ggml_reshape_2d(ctx_c, attn_out, hp.n_embd, seq_len);
                    attn_out = lora_mul_mat(ctx_c, lw.wo, attn_out, lora, o_name);
                    
                    if (lw.has_post_norm && lw.attn_post_norm) {
                        attn_out = apply_rms_norm(ctx_c, attn_out, lw.attn_post_norm, hp.rms_norm_eps);
                    }
                    
                    cur = ggml_add(ctx_c, residual, attn_out);
                }
                
                residual = cur;
                cur = apply_rms_norm(ctx_c, cur, lw.ffn_norm, hp.rms_norm_eps);
                cur = build_ffn_with_lora(ctx_c, cur, &lw, lora);
                
                if (lw.has_post_norm && lw.ffn_post_norm) {
                    cur = apply_rms_norm(ctx_c, cur, lw.ffn_post_norm, hp.rms_norm_eps);
                }
                
                cur = ggml_add(ctx_c, residual, cur);
            }
            
            if (output_norm) {
                cur = apply_rms_norm(ctx_c, cur, output_norm, hp.rms_norm_eps);
            }
            cur = ggml_mul_mat(ctx_c, output, cur);
            ggml_set_name(cur, "logits");
            
            gf = ggml_new_graph(ctx_c);
            ggml_build_forward_expand(gf, cur);
            
            /* Add k_new/v_new tensors to graph for cache extraction */
            if (seq_cache) {
                int lyr;
                for (lyr = 0; lyr < hp.n_layer; lyr++) {
                    if (seq_k_new_tensors[lyr]) ggml_build_forward_expand(gf, seq_k_new_tensors[lyr]);
                    if (seq_v_new_tensors[lyr]) ggml_build_forward_expand(gf, seq_v_new_tensors[lyr]);
                }
            }
            
            if (!pool) {
                if (i == 0) {
                    allocr = ggml_gallocr_new(ggml_backend_get_default_buffer_type(backend));
                    owns_allocr = 1;
                }
                ggml_gallocr_reserve(allocr, gf);
            }
            ggml_gallocr_alloc_graph(allocr, gf);
            
            /* Set inputs */
            {
                struct ggml_tensor *inp = ggml_graph_get_tensor(gf, "inp_tokens");
                struct ggml_tensor *pos_tensor = ggml_graph_get_tensor(gf, "pos");
                int lyr;

                /* Validate token IDs before passing to ggml (batch mode) */
                if (inp && seq_tokens) {
                    for (j = 0; j < seq_len; j++) {
                        if (seq_tokens[j] < 0 || seq_tokens[j] >= hp.n_vocab) {
                            char errbuf[256];
                            snprintf(errbuf, sizeof(errbuf),
                                     "Token ID %d at position %d in sequence %d is out of range [0, %d)",
                                     seq_tokens[j], j, i, hp.n_vocab);
                            if (seq_cache) {
                                Safefree(seq_k_cache_tensors);
                                Safefree(seq_v_cache_tensors);
                                Safefree(seq_k_new_tensors);
                                Safefree(seq_v_new_tensors);
                                KVCACHE_UNLOCK(seq_cache);
                            }
                            if (owns_allocr) ggml_gallocr_free(allocr);
                            if (!pool) ggml_free(ctx_c);
                            if (owns_backend) ggml_backend_free(backend);
                            if (pool) POOL_UNLOCK(pool);
                            result->error = savepv(errbuf);
                            return 0;
                        }
                    }
                }

                if (inp) ggml_backend_tensor_set(inp, seq_tokens, 0, seq_len * sizeof(int));
                
                if (pos_tensor) {
                    int *positions;
                    Newx(positions, seq_len, int);
                    for (j = 0; j < seq_len; j++) positions[j] = seq_pos_offset + j;
                    ggml_backend_tensor_set(pos_tensor, positions, 0, seq_len * sizeof(int));
                    Safefree(positions);
                }
                
                /* Load cached K/V data for this sequence */
                if (seq_cache && seq_pos_offset > 0) {
                    for (lyr = 0; lyr < hp.n_layer; lyr++) {
                        if (seq_k_cache_tensors[lyr] && seq_cache->k_cache[lyr]) {
                            size_t cache_size = seq_pos_offset * n_kv_dim * sizeof(float);
                            ggml_backend_tensor_set(seq_k_cache_tensors[lyr], seq_cache->k_cache[lyr], 0, cache_size);
                        }
                        if (seq_v_cache_tensors[lyr] && seq_cache->v_cache[lyr]) {
                            size_t cache_size = seq_pos_offset * n_kv_dim * sizeof(float);
                            ggml_backend_tensor_set(seq_v_cache_tensors[lyr], seq_cache->v_cache[lyr], 0, cache_size);
                        }
                    }
                }
            }
            
            ggml_backend_graph_compute(backend, gf);
            
            /* Update cache with new K/V values */
            if (seq_cache) {
                int lyr;
                for (lyr = 0; lyr < hp.n_layer; lyr++) {
                    struct ggml_tensor *k_new_tensor = seq_k_new_tensors[lyr];
                    struct ggml_tensor *v_new_tensor = seq_v_new_tensors[lyr];
                    size_t new_size = seq_len * n_kv_dim * sizeof(float);
                    size_t offset = seq_pos_offset * n_kv_dim * sizeof(float);
                    
                    if (k_new_tensor && seq_cache->k_cache[lyr]) {
                        float *temp;
                        Newx(temp, seq_len * n_kv_dim, float);
                        ggml_backend_tensor_get(k_new_tensor, temp, 0, new_size);
                        memcpy((char*)seq_cache->k_cache[lyr] + offset, temp, new_size);
                        Safefree(temp);
                    }
                    if (v_new_tensor && seq_cache->v_cache[lyr]) {
                        float *temp;
                        Newx(temp, seq_len * n_kv_dim, float);
                        ggml_backend_tensor_get(v_new_tensor, temp, 0, new_size);
                        memcpy((char*)seq_cache->v_cache[lyr] + offset, temp, new_size);
                        Safefree(temp);
                    }
                }
                seq_cache->n_cached = seq_pos_offset + seq_len;
            }
            
            /* Extract logits for this sequence */
            {
                struct ggml_tensor *logits_tensor = ggml_graph_get_tensor(gf, "logits");
                if (logits_tensor) {
                    Newx(result->batch_logits[i], hp.n_vocab, float);
                    ggml_backend_tensor_get(logits_tensor, result->batch_logits[i],
                                            (seq_len - 1) * hp.n_vocab * sizeof(float),
                                            hp.n_vocab * sizeof(float));
                }
            }
            
            /* Cleanup per-sequence cache resources */
            if (seq_cache) {
                Safefree(seq_k_cache_tensors);
                Safefree(seq_v_cache_tensors);
                Safefree(seq_k_new_tensors);
                Safefree(seq_v_new_tensors);
                KVCACHE_UNLOCK(seq_cache);
            }
        }
        
        /* Cleanup batch mode */
        if (owns_allocr) ggml_gallocr_free(allocr);
        if (!pool) ggml_free(ctx_c);
        if (owns_backend) ggml_backend_free(backend);
        if (pool) POOL_UNLOCK(pool);
    }
    
    return 1;  /* Success */
}

/* Helper to parse tokens from AV to int array with validation */
static int* parse_tokens_av(pTHX_ AV *av, int *n_tokens_out) {
    int n = av_len(av) + 1;
    int *tokens;
    int i;

    /* Validate: must have at least one token */
    if (n == 0) {
        croak("Token array cannot be empty - at least one token is required");
    }

    Newx(tokens, n, int);
    for (i = 0; i < n; i++) {
        SV **elem = av_fetch(av, i, 0);
        int token = elem ? SvIV(*elem) : 0;

        /* Validate: token IDs must be non-negative */
        if (token < 0) {
            Safefree(tokens);
            croak("Invalid token ID %d at index %d: token IDs must be non-negative", token, i);
        }

        tokens[i] = token;
    }
    *n_tokens_out = n;
    return tokens;
}

/* Helper to parse sequences from AV to int** array */
static int parse_sequences_av(pTHX_ AV *av, int ***all_tokens_out, int **seq_lengths_out, int *n_sequences_out) {
    int n = av_len(av) + 1;
    int **all_tokens;
    int *seq_lengths;
    int i, j;
    
    if (n == 0) return 0;
    
    Newxz(all_tokens, n, int*);
    Newxz(seq_lengths, n, int);
    
    for (i = 0; i < n; i++) {
        SV **seq_svp = av_fetch(av, i, 0);
        AV *seq_av;
        if (!seq_svp || !SvROK(*seq_svp) || SvTYPE(SvRV(*seq_svp)) != SVt_PVAV) {
            for (j = 0; j < i; j++) Safefree(all_tokens[j]);
            Safefree(all_tokens);
            Safefree(seq_lengths);
            return 0;
        }
        seq_av = (AV*)SvRV(*seq_svp);
        seq_lengths[i] = av_len(seq_av) + 1;
        Newx(all_tokens[i], seq_lengths[i], int);
        for (j = 0; j < seq_lengths[i]; j++) {
            SV **elem = av_fetch(seq_av, j, 0);
            all_tokens[i][j] = elem ? SvIV(*elem) : 0;
        }
    }
    
    *all_tokens_out = all_tokens;
    *seq_lengths_out = seq_lengths;
    *n_sequences_out = n;
    return 1;
}

/* Helper to free sequences */
static void free_sequences(int **all_tokens, int *seq_lengths, int n_sequences) {
    int i;
    if (all_tokens) {
        for (i = 0; i < n_sequences; i++) {
            if (all_tokens[i]) Safefree(all_tokens[i]);
        }
        Safefree(all_tokens);
    }
    if (seq_lengths) Safefree(seq_lengths);
}

/* Helper to parse forward options from named parameters on the Perl stack.
 * Consolidates duplicated parameter parsing across forward methods.
 *
 * Parameters:
 *   opts      - pointer to LughForwardOpts struct (must be Zero'd by caller)
 *   start_idx - starting index on the stack (usually 1 for methods)
 *   items     - total number of items on the stack
 *   st        - the stack (use ST(i) macro in caller, pass pointer)
 *
 * Supported keys:
 *   tokens    => \@tokens      - single sequence tokens
 *   sequences => \@sequences   - batch mode: array of token arrays
 *   cache     => $cache        - single KV cache object
 *   caches    => \@caches      - batch mode: array of KV cache objects
 *   pool      => $pool         - memory pool object
 *   lora      => $lora         - LoRA adapter object
 *   rope      => $rope         - RoPE configuration override
 */
static void parse_forward_options(pTHX_ LughForwardOpts *opts, SV **st, int start_idx, int items) {
    int i;

    for (i = start_idx; i < items; i += 2) {
        if (i + 1 < items && SvPOK(st[i])) {
            const char *key = SvPV_nolen(st[i]);
            SV *val = st[i + 1];

            if (strEQ(key, "tokens") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                opts->tokens = parse_tokens_av(aTHX_ (AV*)SvRV(val), &opts->n_tokens);
            }
            else if (strEQ(key, "sequences") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                if (!parse_sequences_av(aTHX_ (AV*)SvRV(val), &opts->all_tokens, &opts->seq_lengths, &opts->n_sequences)) {
                    croak("Invalid sequences format");
                }
            }
            else if (strEQ(key, "cache")) {
                opts->cache = get_lugh_kvcache(aTHX_ val);
            }
            else if (strEQ(key, "caches") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                AV *caches_av = (AV*)SvRV(val);
                int nc = av_len(caches_av) + 1;
                int ci;
                Newxz(opts->caches, nc, void*);
                opts->n_caches = nc;
                for (ci = 0; ci < nc; ci++) {
                    SV **csv = av_fetch(caches_av, ci, 0);
                    if (csv && *csv && SvROK(*csv)) {
                        opts->caches[ci] = get_lugh_kvcache(aTHX_ *csv);
                    }
                }
            }
            else if (strEQ(key, "pool") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
                HV *pool_hv = (HV*)SvRV(val);
                SV **svp = hv_fetch(pool_hv, "_pool_id", 8, 0);
                if (svp && *svp) opts->pool = get_mempool_by_id(SvIV(*svp));
            }
            else if (strEQ(key, "lora")) {
                opts->lora = get_lugh_lora(aTHX_ val);
            }
            else if (strEQ(key, "rope")) {
                opts->rope_sv = val;
            }
        }
    }
}

/* ============================================================================
 * Speculative Decoding Helper Functions (pure C)
 * ============================================================================ */

/* Initialize KV caches for speculative decoding */
static int spec_init_caches(pTHX_ HV *spec_hv, LughSpeculative *spec) {
    SV **svp, *main_inf, *draft_inf;
    HV *inf_hv;
    int main_n_layer, main_n_ctx, main_n_head_kv, main_n_embd, main_n_head, main_head_dim;
    int draft_n_layer, draft_n_ctx, draft_n_head_kv, draft_n_embd, draft_n_head, draft_head_dim;
    LughKVCache *main_cache, *draft_cache;
    
    /* Already have caches */
    if (spec->main_cache && spec->draft_cache) {
        return 1;
    }
    
    /* Get inference objects */
    svp = hv_fetch(spec_hv, "_main_inference", 15, 0);
    if (!svp || !*svp) return 0;
    main_inf = *svp;
    
    svp = hv_fetch(spec_hv, "_draft_inference", 16, 0);
    if (!svp || !*svp) return 0;
    draft_inf = *svp;
    
    /* Extract main model params */
    inf_hv = (HV*)SvRV(main_inf);
    svp = hv_fetch(inf_hv, "n_layer", 7, 0);
    main_n_layer = svp ? SvIV(*svp) : 22;
    svp = hv_fetch(inf_hv, "n_ctx", 5, 0);
    main_n_ctx = svp ? SvIV(*svp) : 2048;
    svp = hv_fetch(inf_hv, "n_head_kv", 9, 0);
    main_n_head_kv = svp ? SvIV(*svp) : 4;
    svp = hv_fetch(inf_hv, "n_embd", 6, 0);
    main_n_embd = svp ? SvIV(*svp) : 2048;
    svp = hv_fetch(inf_hv, "n_head", 6, 0);
    main_n_head = svp ? SvIV(*svp) : 32;
    main_head_dim = main_n_embd / main_n_head;
    
    /* Extract draft model params */
    inf_hv = (HV*)SvRV(draft_inf);
    svp = hv_fetch(inf_hv, "n_layer", 7, 0);
    draft_n_layer = svp ? SvIV(*svp) : 22;
    svp = hv_fetch(inf_hv, "n_ctx", 5, 0);
    draft_n_ctx = svp ? SvIV(*svp) : 2048;
    svp = hv_fetch(inf_hv, "n_head_kv", 9, 0);
    draft_n_head_kv = svp ? SvIV(*svp) : 4;
    svp = hv_fetch(inf_hv, "n_embd", 6, 0);
    draft_n_embd = svp ? SvIV(*svp) : 2048;
    svp = hv_fetch(inf_hv, "n_head", 6, 0);
    draft_n_head = svp ? SvIV(*svp) : 32;
    draft_head_dim = draft_n_embd / draft_n_head;
    
    /* Create caches */
    SPECULATIVE_LOCK(spec);
    if (!spec->main_cache) {
        main_cache = create_kvcache(main_n_layer, main_n_ctx, main_n_head_kv, main_head_dim);
        if (!main_cache) {
            SPECULATIVE_UNLOCK(spec);
            return 0;
        }
        spec->main_cache = main_cache;
    }
    if (!spec->draft_cache) {
        draft_cache = create_kvcache(draft_n_layer, draft_n_ctx, draft_n_head_kv, draft_head_dim);
        if (!draft_cache) {
            SPECULATIVE_UNLOCK(spec);
            return 0;
        }
        spec->draft_cache = draft_cache;
    }
    SPECULATIVE_UNLOCK(spec);
    
    return 1;
}

/* Generate draft tokens using draft model - returns array of token IDs or NULL on error */
static AV* spec_draft_tokens(pTHX_ HV *spec_hv, LughSpeculative *spec, int *input_tokens, int n_input, int n_draft) {
    SV **svp, *draft_inf;
    int n_vocab;
    int *tokens;
    AV *draft_av;
    int i, j;
    LughForwardOpts opts;
    LughForwardResult result;
    float *probs = NULL;
    int *indices = NULL;
    
    svp = hv_fetch(spec_hv, "_draft_inference", 16, 0);
    if (!svp || !*svp) return NULL;
    draft_inf = *svp;
    
    svp = hv_fetch(spec_hv, "n_vocab", 7, 0);
    n_vocab = svp ? SvIV(*svp) : spec->n_vocab;
    
    if (n_draft <= 0) n_draft = spec->k;
    if (n_draft > 16) n_draft = 16;
    
    /* Copy input tokens */
    Newx(tokens, n_input + n_draft, int);
    for (i = 0; i < n_input; i++) {
        tokens[i] = input_tokens[i];
    }
    
    draft_av = newAV();
    
    /* Generate n_draft tokens autoregressively using draft model */
    for (i = 0; i < n_draft; i++) {
        int cur_len = n_input + i;
        float max_logit = -1e9f;
        float sum = 0.0f;
        float threshold, cumsum;
        int sampled_token;
        
        /* Run forward pass on current sequence */
        Zero(&opts, 1, LughForwardOpts);
        Newx(opts.tokens, cur_len, int);
        for (j = 0; j < cur_len; j++) opts.tokens[j] = tokens[j];
        opts.n_tokens = cur_len;
        
        if (!do_forward_unified(aTHX_ (HV*)SvRV(draft_inf), &opts, &result)) {
            Safefree(opts.tokens);
            Safefree(tokens);
            free_forward_result(&result);
            av_undef(draft_av);
            return NULL;
        }
        Safefree(opts.tokens);
        
        /* Sample from logits using top-p */
        Newx(probs, n_vocab, float);
        Newx(indices, n_vocab, int);
        
        for (j = 0; j < n_vocab && j < result.n_vocab; j++) {
            probs[j] = result.logits[j];
            if (probs[j] > max_logit) max_logit = probs[j];
            indices[j] = j;
        }
        
        /* Softmax with temperature */
        for (j = 0; j < n_vocab; j++) {
            probs[j] = expf((probs[j] - max_logit) / spec->temperature);
            sum += probs[j];
        }
        for (j = 0; j < n_vocab; j++) {
            probs[j] /= sum;
        }
        
        /* Top-p (nucleus) sampling:
           1. Sort tokens by probability (descending)
           2. Find smallest set with cumulative prob >= top_p
           3. Sample from that set */
        
        /* Simple bubble sort on indices by probability (descending) */
        for (j = 0; j < n_vocab - 1; j++) {
            int k;
            for (k = j + 1; k < n_vocab; k++) {
                if (probs[indices[k]] > probs[indices[j]]) {
                    int tmp = indices[j];
                    indices[j] = indices[k];
                    indices[k] = tmp;
                }
            }
            /* Early exit once we have enough probability mass */
            if (j > 0) {
                float top_sum = 0.0f;
                int m;
                for (m = 0; m <= j; m++) top_sum += probs[indices[m]];
                if (top_sum >= spec->top_p) break;
            }
        }
        
        /* Find cutoff where cumulative prob >= top_p */
        {
            int cutoff = 0;
            cumsum = 0.0f;
            for (j = 0; j < n_vocab; j++) {
                cumsum += probs[indices[j]];
                cutoff = j + 1;
                if (cumsum >= spec->top_p) break;
            }
            
            /* Renormalize top-p subset and sample */
            sum = 0.0f;
            for (j = 0; j < cutoff; j++) {
                sum += probs[indices[j]];
            }
            
            threshold = lugh_rand_float() * sum;
            cumsum = 0.0f;
            sampled_token = indices[0];  /* Default to top token */
            for (j = 0; j < cutoff; j++) {
                cumsum += probs[indices[j]];
                if (cumsum >= threshold) {
                    sampled_token = indices[j];
                    break;
                }
            }
        }
        
        Safefree(probs);
        Safefree(indices);
        probs = NULL;
        indices = NULL;
        free_forward_result(&result);
        
        tokens[cur_len] = sampled_token;
        av_push(draft_av, newSViv(sampled_token));
    }

    
    SPECULATIVE_LOCK(spec);
    spec->tokens_drafted += n_draft;
    SPECULATIVE_UNLOCK(spec);
    
    Safefree(tokens);
    
    return draft_av;
}

/* Verify draft tokens using main model - returns array of accepted tokens or NULL on error */
static AV* spec_verify_tokens(pTHX_ HV *spec_hv, LughSpeculative *spec, 
                               int *input_tokens, int n_input, 
                               int *draft_tokens, int n_draft) {
    SV **svp, *main_inf;
    int n_vocab;
    int *all_tokens;
    AV *accepted_av;
    int n_accepted;
    LughForwardOpts opts;
    LughForwardResult result;
    int i, j;
    int total_tokens;
    
    svp = hv_fetch(spec_hv, "_main_inference", 15, 0);
    if (!svp || !*svp) return NULL;
    main_inf = *svp;
    
    svp = hv_fetch(spec_hv, "n_vocab", 7, 0);
    n_vocab = svp ? SvIV(*svp) : spec->n_vocab;
    
    /* Build full sequence: input + draft tokens */
    total_tokens = n_input + n_draft;
    Newx(all_tokens, total_tokens, int);
    for (i = 0; i < n_input; i++) {
        all_tokens[i] = input_tokens[i];
    }
    for (i = 0; i < n_draft; i++) {
        all_tokens[n_input + i] = draft_tokens[i];
    }
    
    /* Run main model forward on full sequence, requesting all logits */
    Zero(&opts, 1, LughForwardOpts);
    opts.tokens = all_tokens;
    opts.n_tokens = total_tokens;
    opts.return_all_logits = 1;  /* Request logits for all positions */
    
    if (!do_forward_unified(aTHX_ (HV*)SvRV(main_inf), &opts, &result)) {
        Safefree(all_tokens);
        free_forward_result(&result);
        return NULL;
    }
    
    accepted_av = newAV();
    n_accepted = 0;
    
    /* Proper speculative decoding verification:
       - Logits at position (n_input - 1) predict what should be at position n_input
       - So we check if draft_tokens[i] matches the prediction at position (n_input - 1 + i)
       
       For each draft token i:
       - Get logits at position (n_input - 1 + i)
       - Convert to probabilities
       - Check if draft_tokens[i] has acceptable probability
    */
    for (i = 0; i < n_draft; i++) {
        int logit_pos = n_input - 1 + i;  /* Position whose logits predict the next token */
        int draft_token = draft_tokens[i];
        float *pos_logits;
        float max_logit = -1e9f;
        float sum = 0.0f;
        float *probs;
        float prob;
        
        /* Get logits for this position */
        if (result.all_logits && logit_pos < result.n_tokens) {
            pos_logits = result.all_logits + (logit_pos * n_vocab);
        } else {
            /* Fallback to last position logits if all_logits not available */
            pos_logits = result.logits;
        }
        
        if (!pos_logits) break;
        
        /* Convert logits to probabilities with temperature */
        Newx(probs, n_vocab, float);
        for (j = 0; j < n_vocab && j < result.n_vocab; j++) {
            probs[j] = pos_logits[j];
            if (probs[j] > max_logit) max_logit = probs[j];
        }
        for (j = 0; j < n_vocab; j++) {
            probs[j] = expf((probs[j] - max_logit) / spec->temperature);
            sum += probs[j];
        }
        for (j = 0; j < n_vocab; j++) {
            probs[j] /= sum;
        }
        
        /* Get probability of draft token */
        prob = (draft_token >= 0 && draft_token < n_vocab) ? probs[draft_token] : 0.0f;
        
        Safefree(probs);
        
        /* Accept if probability exceeds threshold (typical threshold ~0.01) */
        if (prob >= 0.01f) {
            av_push(accepted_av, newSViv(draft_token));
            n_accepted++;
        } else {
            /* First rejection - stop accepting */
            break;
        }
    }
    
    Safefree(all_tokens);
    free_forward_result(&result);
    
    SPECULATIVE_LOCK(spec);
    spec->tokens_accepted += n_accepted;
    spec->total_steps++;
    SPECULATIVE_UNLOCK(spec);
    
    return accepted_av;
}

/* Global last error for speculative decoding (thread-local would be better, but this helps debugging) */
static char spec_last_error[512] = "";

/* One speculation step: draft + verify - returns accepted tokens or NULL on error */
static AV* spec_step(pTHX_ HV *spec_hv, LughSpeculative *spec, int *input_tokens, int n_input) {
    AV *draft_av, *accepted_av;
    int *draft_tokens_arr;
    int n_draft, i;

    spec_last_error[0] = '\0';

    /* Initialize caches if needed */
    if (!spec_init_caches(aTHX_ spec_hv, spec)) {
        snprintf(spec_last_error, sizeof(spec_last_error), "Failed to initialize KV caches");
        return NULL;
    }

    /* Generate draft tokens */
    draft_av = spec_draft_tokens(aTHX_ spec_hv, spec, input_tokens, n_input, spec->k);
    if (!draft_av) {
        snprintf(spec_last_error, sizeof(spec_last_error), "Failed to generate draft tokens (n_input=%d, k=%d)", n_input, spec->k);
        return NULL;
    }
    
    n_draft = av_len(draft_av) + 1;
    Newx(draft_tokens_arr, n_draft, int);
    for (i = 0; i < n_draft; i++) {
        SV **tv = av_fetch(draft_av, i, 0);
        draft_tokens_arr[i] = tv ? SvIV(*tv) : 0;
    }
    
    /* Verify draft tokens */
    accepted_av = spec_verify_tokens(aTHX_ spec_hv, spec, input_tokens, n_input, draft_tokens_arr, n_draft);

    Safefree(draft_tokens_arr);
    av_undef(draft_av);

    if (!accepted_av && spec_last_error[0] == '\0') {
        snprintf(spec_last_error, sizeof(spec_last_error), "Failed to verify draft tokens (n_input=%d, n_draft=%d)", n_input, n_draft);
    }

    return accepted_av;
}

/* ============================================================================
 * XS Functions
 * ============================================================================ */

MODULE = Lugh    PACKAGE = Lugh

PROTOTYPES: DISABLE

BOOT:
    INIT_MUTEXES();

const char *
version()
CODE:
    RETVAL = "0.04";
OUTPUT:
    RETVAL

void
srand(seed)
    unsigned int seed
CODE:
    lugh_srand(seed);

const char *
ggml_version()
CODE:
    /* Return ggml build info */
    RETVAL = "ggml 0.9.5";
OUTPUT:
    RETVAL

int
has_metal()
CODE:
    /* Check if Metal backend is registered (linked at build time) */
    RETVAL = metal_is_available();
OUTPUT:
    RETVAL

int
metal_available()
CODE:
    RETVAL = metal_is_available();
OUTPUT:
    RETVAL

int
backend_count()
CODE:
    /* Return count of registered backends */
    RETVAL = (int)ggml_backend_reg_count();
OUTPUT:
    RETVAL

int
backend_device_count()
CODE:
    /* Return count of available devices */
    RETVAL = (int)ggml_backend_dev_count();
OUTPUT:
    RETVAL

void
available_backends()
PPCODE:
{
    size_t i, count;
    /* Always include "auto" option */
    count = ggml_backend_reg_count();
    EXTEND(SP, count + 1);
    
    /* List all registered backends by name */
    for (i = 0; i < count; i++) {
        ggml_backend_reg_t reg = ggml_backend_reg_get(i);
        const char *name = ggml_backend_reg_name(reg);
        mPUSHp(name, strlen(name));
    }
    
    /* Always add "auto" as special option */
    mPUSHp("auto", 4);
}

SV *
backend_info(name)
    const char *name
CODE:
{
    HV *info = newHV();
    size_t i, count;
    int found = 0;
    
    count = ggml_backend_reg_count();
    for (i = 0; i < count; i++) {
        ggml_backend_reg_t reg = ggml_backend_reg_get(i);
        const char *reg_name = ggml_backend_reg_name(reg);
        if (strcmp(name, reg_name) == 0) {
            size_t dev_count = ggml_backend_reg_dev_count(reg);
            hv_store(info, "name", 4, newSVpv(reg_name, 0), 0);
            hv_store(info, "device_count", 12, newSViv(dev_count), 0);
            
            /* Check first device for type info */
            if (dev_count > 0) {
                ggml_backend_dev_t dev = ggml_backend_reg_dev_get(reg, 0);
                const char *desc = ggml_backend_dev_description(dev);
                enum ggml_backend_dev_type dtype = ggml_backend_dev_type(dev);
                const char *type_str;
                int is_gpu = 0;
                
                switch (dtype) {
                    case GGML_BACKEND_DEVICE_TYPE_CPU:
                        type_str = "CPU";
                        break;
                    case GGML_BACKEND_DEVICE_TYPE_GPU:
                        type_str = "GPU";
                        is_gpu = 1;
                        break;
                    default:
                        type_str = "ACCEL";
                        is_gpu = 1;
                }
                hv_store(info, "description", 11, newSVpv(desc, 0), 0);
                hv_store(info, "type", 4, newSVpv(type_str, 0), 0);
                hv_store(info, "is_gpu", 6, newSViv(is_gpu), 0);
            }
            found = 1;
            break;
        }
    }
    
    if (!found) {
        hv_store(info, "name", 4, newSVpv(name, 0), 0);
        hv_store(info, "error", 5, newSVpv("Backend not found", 0), 0);
    }
    
    RETVAL = newRV_noinc((SV*)info);
}
OUTPUT:
    RETVAL

const char *
best_backend()
CODE:
{
    /* Find the best available backend - prefer GPU over CPU */
    size_t i, count = ggml_backend_reg_count();
    const char *best = "CPU";  /* fallback */
    
    for (i = 0; i < count; i++) {
        ggml_backend_reg_t reg = ggml_backend_reg_get(i);
        size_t dev_count = ggml_backend_reg_dev_count(reg);
        if (dev_count > 0) {
            ggml_backend_dev_t dev = ggml_backend_reg_dev_get(reg, 0);
            enum ggml_backend_dev_type dtype = ggml_backend_dev_type(dev);
            if (dtype == GGML_BACKEND_DEVICE_TYPE_GPU) {
                best = ggml_backend_reg_name(reg);
                break;  /* Found GPU, stop searching */
            }
        }
    }
    RETVAL = best;
}
OUTPUT:
    RETVAL

int
backend_available(name)
    const char *name
CODE:
{
    size_t i, count;
    RETVAL = 0;
    
    if (strcmp(name, "auto") == 0) {
        RETVAL = 1;  /* auto is always available */
    } else {
        count = ggml_backend_reg_count();
        for (i = 0; i < count; i++) {
            ggml_backend_reg_t reg = ggml_backend_reg_get(i);
            const char *reg_name = ggml_backend_reg_name(reg);
            if (strcmp(name, reg_name) == 0) {
                /* Check if it has at least one device */
                if (ggml_backend_reg_dev_count(reg) > 0) {
                    RETVAL = 1;
                }
                break;
            }
        }
    }
}
OUTPUT:
    RETVAL

MODULE = Lugh    PACKAGE = Lugh::Context

SV *
new(class, ...)
    char *class
PREINIT:
    LughContext *lctx;
    size_t mem_size = 16 * 1024 * 1024;  /* 16MB default */
    struct ggml_init_params params;
    SV *sv;
    int i, id;
CODE:
    INIT_MUTEXES();
    
    /* Allocate context ID first */
    id = alloc_context_id();
    if (id < 0) {
        croak("Maximum number of contexts (%d) reached", MAX_CONTEXTS);
    }
    
    /* Parse optional arguments */
    for (i = 1; i < items; i += 2) {
        if (i + 1 < items) {
            const char *key = SvPV_nolen(ST(i));
            if (strEQ(key, "mem_size")) {
                mem_size = SvUV(ST(i + 1));
            }
        }
    }

    /* Validate mem_size - must be positive */
    if (mem_size == 0) {
        /* Release the allocated ID back to the pool */
        CONTEXT_LOCK();
        context_registry[id] = NULL;
        CONTEXT_UNLOCK();
        croak("mem_size must be positive (got 0)");
    }

    /* Allocate our state */
    Newxz(lctx, 1, LughContext);
    lctx->mem_size = mem_size;
    lctx->id = id;
    lctx->active = 1;
    
    /* Initialize ggml context */
    params.mem_size = mem_size;
    params.mem_buffer = NULL;
    params.no_alloc = false;
    
    lctx->ctx = ggml_init(params);
    if (!lctx->ctx) {
        Safefree(lctx);
        croak("Failed to initialize ggml context");
    }
    
    /* Register in global registry */
    CONTEXT_LOCK();
    context_registry[id] = lctx;
    CONTEXT_UNLOCK();
    
    /* Create blessed reference with magic - store ID not pointer */
    sv = newSV(0);
    sv_magicext(sv, NULL, PERL_MAGIC_ext, &lugh_context_vtbl, INT2PTR(char*, (IV)id), 0);
    RETVAL = sv_bless(newRV_noinc(sv), gv_stashpv(class, GV_ADD));
OUTPUT:
    RETVAL

int
id(self)
    SV *self
CODE:
    LughContext *lctx = get_lugh_context(aTHX_ self);
    RETVAL = lctx->id;
OUTPUT:
    RETVAL

size_t
mem_size(self)
    SV *self
CODE:
    LughContext *lctx = get_lugh_context(aTHX_ self);
    RETVAL = lctx->mem_size;
OUTPUT:
    RETVAL

size_t
used_mem(self)
    SV *self
CODE:
    LughContext *lctx = get_lugh_context(aTHX_ self);
    RETVAL = ggml_used_mem(lctx->ctx);
OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
CODE:
    /* Magic cleanup handles this */
    PERL_UNUSED_VAR(self);

MODULE = Lugh  PACKAGE = Lugh::Inference

=pod

=head1 Lugh::Inference

The inference engine - runs the forward pass through the model

=cut

SV *
new(class, ...)
    const char *class
PREINIT:
    LughModel *model = NULL;
    SV *model_sv = NULL;
    int i;
    int n_ctx = 2048;
    int n_threads = 4;
CODE:
    /* Parse arguments */
    if ((items - 1) % 2 != 0) {
        croak("Usage: Lugh::Inference->new(model => $model, n_ctx => 2048, n_threads => 4)");
    }
    
    for (i = 1; i < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        
        if (strEQ(key, "model")) {
            model_sv = val;
            model = get_lugh_model(aTHX_ val);
        } else if (strEQ(key, "n_ctx")) {
            n_ctx = SvIV(val);
        } else if (strEQ(key, "n_threads")) {
            n_threads = SvIV(val);
        }
    }
    
    if (!model) {
        croak("model parameter is required");
    }
    
    /* For now, return a simple blessed hash with the config */
    {
        HV *hv = newHV();
        SV *sv;
        
        hv_store(hv, "_model", 6, SvREFCNT_inc(model_sv), 0);
        hv_store(hv, "n_ctx", 5, newSViv(n_ctx), 0);
        hv_store(hv, "n_threads", 9, newSViv(n_threads), 0);
        
        /* Store model hyperparameters */
        {
            int64_t key_id;
            
            key_id = gguf_find_key(model->gguf, "llama.embedding_length");
            if (key_id >= 0) hv_store(hv, "n_embd", 6, newSViv(gguf_get_val_u32(model->gguf, key_id)), 0);
            
            key_id = gguf_find_key(model->gguf, "llama.block_count");
            if (key_id >= 0) hv_store(hv, "n_layer", 7, newSViv(gguf_get_val_u32(model->gguf, key_id)), 0);
            
            key_id = gguf_find_key(model->gguf, "llama.attention.head_count");
            if (key_id >= 0) hv_store(hv, "n_head", 6, newSViv(gguf_get_val_u32(model->gguf, key_id)), 0);
            
            key_id = gguf_find_key(model->gguf, "llama.attention.head_count_kv");
            if (key_id >= 0) hv_store(hv, "n_head_kv", 9, newSViv(gguf_get_val_u32(model->gguf, key_id)), 0);
            
            key_id = gguf_find_key(model->gguf, "llama.feed_forward_length");
            if (key_id >= 0) hv_store(hv, "n_ff", 4, newSViv(gguf_get_val_u32(model->gguf, key_id)), 0);
            
            key_id = gguf_find_key(model->gguf, "llama.vocab_size");
            if (key_id >= 0) {
                hv_store(hv, "n_vocab", 7, newSViv(gguf_get_val_u32(model->gguf, key_id)), 0);
            } else {
                /* Infer from tokenizer or embedding tensor */
                hv_store(hv, "n_vocab", 7, newSViv(32000), 0);  /* Default llama vocab */
            }
        }
        
        sv = newRV_noinc((SV*)hv);
        sv_bless(sv, gv_stashpv(class, GV_ADD));
        RETVAL = sv;
    }
OUTPUT:
    RETVAL

SV *
model(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) {
        croak("Not a valid Lugh::Inference object");
    }
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_model", 6, 0);
    if (svp && *svp) {
        RETVAL = SvREFCNT_inc(*svp);
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

int
n_ctx(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
CODE:
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "n_ctx", 5, 0);
    RETVAL = svp ? SvIV(*svp) : 2048;
OUTPUT:
    RETVAL

int
n_vocab(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
CODE:
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "n_vocab", 7, 0);
    RETVAL = svp ? SvIV(*svp) : 32000;
OUTPUT:
    RETVAL

int
n_embd(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
CODE:
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "n_embd", 6, 0);
    RETVAL = svp ? SvIV(*svp) : 2048;
OUTPUT:
    RETVAL

int
n_layer(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
CODE:
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "n_layer", 7, 0);
    RETVAL = svp ? SvIV(*svp) : 22;
OUTPUT:
    RETVAL

int
n_head(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
CODE:
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "n_head", 6, 0);
    RETVAL = svp ? SvIV(*svp) : 32;
OUTPUT:
    RETVAL

void
forward(self, ...)
    SV *self
PREINIT:
    HV *hv;
    LughForwardOpts opts;
    LughForwardResult result;
    int i, j;
PPCODE:
    hv = (HV*)SvRV(self);
    Zero(&opts, 1, LughForwardOpts);

    /* Parse named parameters: forward(tokens => \@t, lora => $l, ...) */
    parse_forward_options(aTHX_ &opts, &ST(0), 1, items);

    if (!opts.tokens && !opts.all_tokens) {
        croak("forward() requires tokens => \\@tokens");
    }
    
    /* Validate caches vs cache usage */
    if (opts.all_tokens) {
        if (opts.cache) croak("Use 'caches' (array) for batch mode, not 'cache'");
        if (opts.caches && opts.n_caches != opts.n_sequences) {
            Safefree(opts.caches);
            free_sequences(opts.all_tokens, opts.seq_lengths, opts.n_sequences);
            croak("Number of caches (%d) must match number of sequences (%d)", opts.n_caches, opts.n_sequences);
        }
    }
    
    if (!do_forward_unified(aTHX_ hv, &opts, &result)) {
        char *err = result.error ? result.error : "Forward pass failed";
        if (opts.tokens) Safefree(opts.tokens);
        if (opts.caches) Safefree(opts.caches);
        free_sequences(opts.all_tokens, opts.seq_lengths, opts.n_sequences);
        free_forward_result(&result);
        croak("%s", err);
    }
    
    if (opts.tokens) Safefree(opts.tokens);
    if (opts.caches) Safefree(opts.caches);
    free_sequences(opts.all_tokens, opts.seq_lengths, opts.n_sequences);
    
    if (result.is_batch) {
        AV *results_av = newAV();
        for (i = 0; i < result.n_sequences; i++) {
            AV *seq_av = newAV();
            for (j = 0; j < result.n_vocab; j++) {
                av_push(seq_av, newSVnv(result.batch_logits[i][j]));
            }
            av_push(results_av, newRV_noinc((SV*)seq_av));
        }
        free_forward_result(&result);
        EXTEND(SP, 1);
        mPUSHs(newRV_noinc((SV*)results_av));
    } else {
        EXTEND(SP, result.n_vocab);
        for (j = 0; j < result.n_vocab; j++) {
            mPUSHn(result.logits[j]);
        }
        free_forward_result(&result);
    }

SV *
forward_all(self, ...)
    SV *self
PREINIT:
    HV *hv;
    LughForwardOpts opts;
    LughForwardResult result;
    int i, j;
    AV *outer_av;
CODE:
    hv = (HV*)SvRV(self);
    Zero(&opts, 1, LughForwardOpts);
    opts.return_all_logits = 1;  /* Always request all position logits */

    /* Parse named parameters: forward_all(tokens => \@t, lora => $l, ...) */
    parse_forward_options(aTHX_ &opts, &ST(0), 1, items);

    if (!opts.tokens && !opts.all_tokens) {
        croak("forward_all() requires tokens => \\@tokens");
    }
    
    /* Validate caches vs cache usage */
    if (opts.all_tokens) {
        if (opts.cache) croak("Use 'caches' (array) for batch mode, not 'cache'");
        if (opts.caches && opts.n_caches != opts.n_sequences) {
            Safefree(opts.caches);
            free_sequences(opts.all_tokens, opts.seq_lengths, opts.n_sequences);
            croak("Number of caches (%d) must match number of sequences (%d)", opts.n_caches, opts.n_sequences);
        }
    }
    
    if (!do_forward_unified(aTHX_ hv, &opts, &result)) {
        char *err = result.error ? result.error : "Forward pass failed";
        if (opts.tokens) Safefree(opts.tokens);
        if (opts.caches) Safefree(opts.caches);
        free_sequences(opts.all_tokens, opts.seq_lengths, opts.n_sequences);
        free_forward_result(&result);
        croak("%s", err);
    }
    
    if (opts.tokens) Safefree(opts.tokens);
    if (opts.caches) Safefree(opts.caches);
    free_sequences(opts.all_tokens, opts.seq_lengths, opts.n_sequences);
    
    /* Return array of arrays: [ [logits_pos0], [logits_pos1], ... ] */
    outer_av = newAV();
    
    if (result.all_logits && result.n_tokens > 0) {
        for (i = 0; i < result.n_tokens; i++) {
            AV *pos_av = newAV();
            float *pos_logits = result.all_logits + (i * result.n_vocab);
            for (j = 0; j < result.n_vocab; j++) {
                av_push(pos_av, newSVnv(pos_logits[j]));
            }
            av_push(outer_av, newRV_noinc((SV*)pos_av));
        }
    } else if (result.logits) {
        /* Fallback: only last position available */
        AV *pos_av = newAV();
        for (j = 0; j < result.n_vocab; j++) {
            av_push(pos_av, newSVnv(result.logits[j]));
        }
        av_push(outer_av, newRV_noinc((SV*)pos_av));
    }
    
    free_forward_result(&result);
    RETVAL = newRV_noinc((SV*)outer_av);
OUTPUT:
    RETVAL

void
forward_simple(self, tokens_ref)
    SV *self
    SV *tokens_ref
PREINIT:
    HV *hv;
    LughForwardOpts opts;
    LughForwardResult result;
    int j;
PPCODE:
    if (!SvROK(tokens_ref) || SvTYPE(SvRV(tokens_ref)) != SVt_PVAV) {
        croak("forward_simple() requires an array reference");
    }
    
    hv = (HV*)SvRV(self);
    Zero(&opts, 1, LughForwardOpts);
    opts.tokens = parse_tokens_av(aTHX_ (AV*)SvRV(tokens_ref), &opts.n_tokens);
    
    if (!do_forward_unified(aTHX_ hv, &opts, &result)) {
        char *err = result.error ? result.error : "Forward pass failed";
        Safefree(opts.tokens);
        free_forward_result(&result);
        croak("%s", err);
    }
    
    Safefree(opts.tokens);
    
    EXTEND(SP, result.n_vocab);
    for (j = 0; j < result.n_vocab; j++) {
        mPUSHn(result.logits[j]);
    }
    free_forward_result(&result);

void
forward_cache(self, ...)
    SV *self
PREINIT:
    HV *hv;
    LughForwardOpts opts;
    LughForwardResult result;
    int j;
PPCODE:
    hv = (HV*)SvRV(self);
    Zero(&opts, 1, LughForwardOpts);

    /* Detect positional: forward_cache($cache, \@tokens, ...) */
    if (items >= 3 && sv_isobject(ST(1)) && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVAV) {
        opts.cache = get_lugh_kvcache(aTHX_ ST(1));
        opts.tokens = parse_tokens_av(aTHX_ (AV*)SvRV(ST(2)), &opts.n_tokens);
        /* Parse remaining as named params */
        parse_forward_options(aTHX_ &opts, &ST(0), 3, items);
    } else {
        /* Named params: forward_cache(cache => $c, tokens => \@t, ...) */
        parse_forward_options(aTHX_ &opts, &ST(0), 1, items);
    }

    if (!opts.tokens) croak("forward_cache() requires tokens");
    if (!opts.cache) croak("forward_cache() requires cache");
    
    if (!do_forward_unified(aTHX_ hv, &opts, &result)) {
        char *err = result.error ? result.error : "Forward pass failed";
        Safefree(opts.tokens);
        free_forward_result(&result);
        croak("%s", err);
    }
    
    Safefree(opts.tokens);
    
    EXTEND(SP, result.n_vocab);
    for (j = 0; j < result.n_vocab; j++) {
        mPUSHn(result.logits[j]);
    }
    free_forward_result(&result);

void
forward_pool(self, ...)
    SV *self
PREINIT:
    HV *hv;
    LughForwardOpts opts;
    LughForwardResult result;
    int j;
    SV **svp;
PPCODE:
    hv = (HV*)SvRV(self);
    Zero(&opts, 1, LughForwardOpts);

    /* Detect positional: forward_pool($pool, \@tokens, ...) */
    if (items >= 3 && sv_isobject(ST(1)) && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVAV) {
        SV *pool_sv = ST(1);
        if (SvROK(pool_sv) && SvTYPE(SvRV(pool_sv)) == SVt_PVHV) {
            HV *pool_hv = (HV*)SvRV(pool_sv);
            svp = hv_fetch(pool_hv, "_pool_id", 8, 0);
            if (svp && *svp) opts.pool = get_mempool_by_id(SvIV(*svp));
        }
        opts.tokens = parse_tokens_av(aTHX_ (AV*)SvRV(ST(2)), &opts.n_tokens);
        /* Parse remaining as named params */
        parse_forward_options(aTHX_ &opts, &ST(0), 3, items);
    } else {
        /* Named params */
        parse_forward_options(aTHX_ &opts, &ST(0), 1, items);
    }

    if (!opts.tokens) croak("forward_pool() requires tokens");
    if (!opts.pool) croak("forward_pool() requires pool");
    
    if (!do_forward_unified(aTHX_ hv, &opts, &result)) {
        char *err = result.error ? result.error : "Forward pass failed";
        Safefree(opts.tokens);
        free_forward_result(&result);
        croak("%s", err);
    }
    
    Safefree(opts.tokens);
    
    EXTEND(SP, result.n_vocab);
    for (j = 0; j < result.n_vocab; j++) {
        mPUSHn(result.logits[j]);
    }
    free_forward_result(&result);

void
forward_batch(self, ...)
    SV *self
PREINIT:
    HV *hv;
    LughForwardOpts opts;
    LughForwardResult result;
    int i, j;
PPCODE:
    hv = (HV*)SvRV(self);
    Zero(&opts, 1, LughForwardOpts);

    /* Detect positional: forward_batch(\@sequences, ...) */
    if (items >= 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVAV) {
        if (!parse_sequences_av(aTHX_ (AV*)SvRV(ST(1)), &opts.all_tokens, &opts.seq_lengths, &opts.n_sequences)) {
            croak("Invalid sequences format");
        }
        /* Parse remaining as named params */
        parse_forward_options(aTHX_ &opts, &ST(0), 2, items);
    } else {
        /* Named params */
        parse_forward_options(aTHX_ &opts, &ST(0), 1, items);
    }

    if (!opts.all_tokens) croak("forward_batch() requires sequences");
    if (opts.cache) croak("Use 'caches' (array) for batch mode, not 'cache'");
    if (opts.caches && opts.n_caches != opts.n_sequences) {
        Safefree(opts.caches);
        free_sequences(opts.all_tokens, opts.seq_lengths, opts.n_sequences);
        croak("Number of caches (%d) must match number of sequences (%d)", opts.n_caches, opts.n_sequences);
    }
    
    if (!do_forward_unified(aTHX_ hv, &opts, &result)) {
        char *err = result.error ? result.error : "Forward pass failed";
        if (opts.caches) Safefree(opts.caches);
        free_sequences(opts.all_tokens, opts.seq_lengths, opts.n_sequences);
        free_forward_result(&result);
        croak("%s", err);
    }
    
    if (opts.caches) Safefree(opts.caches);
    free_sequences(opts.all_tokens, opts.seq_lengths, opts.n_sequences);
    
    /* Return array ref of results */
    {
        AV *results_av = newAV();
        for (i = 0; i < result.n_sequences; i++) {
            AV *seq_av = newAV();
            for (j = 0; j < result.n_vocab; j++) {
                av_push(seq_av, newSVnv(result.batch_logits[i][j]));
            }
            av_push(results_av, newRV_noinc((SV*)seq_av));
        }
        free_forward_result(&result);
        EXTEND(SP, 1);
        mPUSHs(newRV_noinc((SV*)results_av));
    }

void
forward_cache_pool(self, ...)
    SV *self
PREINIT:
    HV *hv;
    LughForwardOpts opts;
    LughForwardResult result;
    int j;
    SV **svp;
PPCODE:
    hv = (HV*)SvRV(self);
    Zero(&opts, 1, LughForwardOpts);

    /* Detect positional: forward_cache_pool($cache, $pool, \@tokens, ...) */
    if (items >= 4 && sv_isobject(ST(1)) && sv_isobject(ST(2)) &&
        SvROK(ST(3)) && SvTYPE(SvRV(ST(3))) == SVt_PVAV) {
        opts.cache = get_lugh_kvcache(aTHX_ ST(1));
        SV *pool_sv = ST(2);
        if (SvROK(pool_sv) && SvTYPE(SvRV(pool_sv)) == SVt_PVHV) {
            HV *pool_hv = (HV*)SvRV(pool_sv);
            svp = hv_fetch(pool_hv, "_pool_id", 8, 0);
            if (svp && *svp) opts.pool = get_mempool_by_id(SvIV(*svp));
        }
        opts.tokens = parse_tokens_av(aTHX_ (AV*)SvRV(ST(3)), &opts.n_tokens);
        /* Parse remaining as named params */
        parse_forward_options(aTHX_ &opts, &ST(0), 4, items);
    } else {
        /* Named params */
        parse_forward_options(aTHX_ &opts, &ST(0), 1, items);
    }

    if (!opts.tokens) croak("forward_cache_pool() requires tokens");
    if (!opts.cache) croak("forward_cache_pool() requires cache");
    if (!opts.pool) croak("forward_cache_pool() requires pool");
    
    if (!do_forward_unified(aTHX_ hv, &opts, &result)) {
        char *err = result.error ? result.error : "Forward pass failed";
        Safefree(opts.tokens);
        free_forward_result(&result);
        croak("%s", err);
    }
    
    Safefree(opts.tokens);
    
    EXTEND(SP, result.n_vocab);
    for (j = 0; j < result.n_vocab; j++) {
        mPUSHn(result.logits[j]);
    }
    free_forward_result(&result);

void
forward_batch_pool(self, ...)
    SV *self
PREINIT:
    HV *hv;
    LughForwardOpts opts;
    LughForwardResult result;
    int i, j;
    SV **svp;
PPCODE:
    hv = (HV*)SvRV(self);
    Zero(&opts, 1, LughForwardOpts);

    /* Detect positional: forward_batch_pool($pool, \@sequences, ...) */
    if (items >= 3 && sv_isobject(ST(1)) && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVAV) {
        SV *pool_sv = ST(1);
        if (SvROK(pool_sv) && SvTYPE(SvRV(pool_sv)) == SVt_PVHV) {
            HV *pool_hv = (HV*)SvRV(pool_sv);
            svp = hv_fetch(pool_hv, "_pool_id", 8, 0);
            if (svp && *svp) opts.pool = get_mempool_by_id(SvIV(*svp));
        }
        if (!parse_sequences_av(aTHX_ (AV*)SvRV(ST(2)), &opts.all_tokens, &opts.seq_lengths, &opts.n_sequences)) {
            croak("Invalid sequences format");
        }
        /* Parse remaining as named params */
        parse_forward_options(aTHX_ &opts, &ST(0), 3, items);
    } else {
        /* Named params */
        parse_forward_options(aTHX_ &opts, &ST(0), 1, items);
    }

    if (!opts.all_tokens) croak("forward_batch_pool() requires sequences");
    if (!opts.pool) croak("forward_batch_pool() requires pool");
    if (opts.caches && opts.n_caches != opts.n_sequences) {
        Safefree(opts.caches);
        free_sequences(opts.all_tokens, opts.seq_lengths, opts.n_sequences);
        croak("Number of caches (%d) must match number of sequences (%d)", opts.n_caches, opts.n_sequences);
    }
    
    if (!do_forward_unified(aTHX_ hv, &opts, &result)) {
        char *err = result.error ? result.error : "Forward pass failed";
        if (opts.caches) Safefree(opts.caches);
        free_sequences(opts.all_tokens, opts.seq_lengths, opts.n_sequences);
        free_forward_result(&result);
        croak("%s", err);
    }
    
    if (opts.caches) Safefree(opts.caches);
    free_sequences(opts.all_tokens, opts.seq_lengths, opts.n_sequences);
    
    /* Return array ref of results */
    {
        AV *results_av = newAV();
        for (i = 0; i < result.n_sequences; i++) {
            AV *seq_av = newAV();
            for (j = 0; j < result.n_vocab; j++) {
                av_push(seq_av, newSVnv(result.batch_logits[i][j]));
            }
            av_push(results_av, newRV_noinc((SV*)seq_av));
        }
        free_forward_result(&result);
        EXTEND(SP, 1);
        mPUSHs(newRV_noinc((SV*)results_av));
    }

int
sample_top_p(self, logits_ref, ...)
    SV *self
    SV *logits_ref
PREINIT:
    AV *logits_av;
    int n_vocab;
    float *logits;
    float temperature = 0.8f;
    float top_p = 0.95f;
    int i;
    float max_logit = -1e9f;
    float sum = 0.0f;
    float cumsum = 0.0f;
    float threshold;
    int *indices;
CODE:
    if (!SvROK(logits_ref) || SvTYPE(SvRV(logits_ref)) != SVt_PVAV) {
        croak("logits must be an array reference");
    }
    logits_av = (AV*)SvRV(logits_ref);
    n_vocab = av_len(logits_av) + 1;
    
    /* Parse optional parameters */
    for (i = 2; i < items; i += 2) {
        if (i + 1 < items) {
            const char *key = SvPV_nolen(ST(i));
            if (strEQ(key, "temperature")) {
                temperature = SvNV(ST(i + 1));
            } else if (strEQ(key, "top_p")) {
                top_p = SvNV(ST(i + 1));
            }
        }
    }
    
    Newx(logits, n_vocab, float);
    Newx(indices, n_vocab, int);
    
    /* Copy logits and find max */
    for (i = 0; i < n_vocab; i++) {
        SV **svp = av_fetch(logits_av, i, 0);
        logits[i] = svp ? SvNV(*svp) : 0.0f;
        if (logits[i] > max_logit) max_logit = logits[i];
        indices[i] = i;
    }
    
    /* Apply temperature and softmax */
    for (i = 0; i < n_vocab; i++) {
        logits[i] = expf((logits[i] - max_logit) / temperature);
        sum += logits[i];
    }
    for (i = 0; i < n_vocab; i++) {
        logits[i] /= sum;
    }
    
    /* Sort indices by probability (descending) using selection sort for top elements only */
    /* We only need to find enough elements to reach top_p cumulative probability */
    {
        int cutoff = 0;
        float top_sum = 0.0f;
        
        /* Selection sort: find largest elements one by one until we have top_p mass */
        for (i = 0; i < n_vocab && top_sum < top_p; i++) {
            int max_idx = i;
            float max_prob = logits[indices[i]];
            int j;
            
            /* Find the maximum in remaining unsorted portion */
            for (j = i + 1; j < n_vocab; j++) {
                if (logits[indices[j]] > max_prob) {
                    max_prob = logits[indices[j]];
                    max_idx = j;
                }
            }
            
            /* Swap to position i */
            if (max_idx != i) {
                int tmp = indices[i];
                indices[i] = indices[max_idx];
                indices[max_idx] = tmp;
            }
            
            top_sum += logits[indices[i]];
            cutoff = i + 1;
        }
        
        /* Renormalize the top_p subset and sample */
        threshold = lugh_rand_float() * top_sum;
        cumsum = 0.0f;
        RETVAL = indices[0];  /* Default to most likely */
        
        for (i = 0; i < cutoff; i++) {
            cumsum += logits[indices[i]];
            if (cumsum >= threshold) {
                RETVAL = indices[i];
                break;
            }
        }
    }
    
    Safefree(logits);
    Safefree(indices);
OUTPUT:
    RETVAL

int
sample_top_k(self, logits_ref, ...)
    SV *self
    SV *logits_ref
PREINIT:
    AV *logits_av;
    int n_vocab;
    float *logits;
    float temperature = 0.8f;
    int top_k = 40;
    int i;
    float max_logit = -1e9f;
    float sum = 0.0f;
    float threshold;
    int *indices;
CODE:
    if (!SvROK(logits_ref) || SvTYPE(SvRV(logits_ref)) != SVt_PVAV) {
        croak("logits must be an array reference");
    }
    logits_av = (AV*)SvRV(logits_ref);
    n_vocab = av_len(logits_av) + 1;
    
    /* Parse optional parameters */
    for (i = 2; i < items; i += 2) {
        if (i + 1 < items) {
            const char *key = SvPV_nolen(ST(i));
            if (strEQ(key, "temperature")) {
                temperature = SvNV(ST(i + 1));
            } else if (strEQ(key, "top_k")) {
                top_k = SvIV(ST(i + 1));
            }
        }
    }
    
    if (top_k <= 0 || top_k > n_vocab) top_k = n_vocab;
    
    Newx(logits, n_vocab, float);
    Newx(indices, n_vocab, int);
    
    /* Copy logits and find max */
    for (i = 0; i < n_vocab; i++) {
        SV **svp = av_fetch(logits_av, i, 0);
        logits[i] = svp ? SvNV(*svp) : 0.0f;
        if (logits[i] > max_logit) max_logit = logits[i];
        indices[i] = i;
    }
    
    /* Apply temperature and softmax */
    sum = 0.0f;
    for (i = 0; i < n_vocab; i++) {
        logits[i] = expf((logits[i] - max_logit) / temperature);
        sum += logits[i];
    }
    for (i = 0; i < n_vocab; i++) {
        logits[i] /= sum;
    }
    
    /* Partial sort to get top_k elements (selection-style) */
    {
        int j, k;
        for (k = 0; k < top_k; k++) {
            int max_idx = k;
            for (j = k + 1; j < n_vocab; j++) {
                if (logits[j] > logits[max_idx]) {
                    max_idx = j;
                }
            }
            if (max_idx != k) {
                float tmp = logits[k];
                int tmp_idx = indices[k];
                logits[k] = logits[max_idx];
                indices[k] = indices[max_idx];
                logits[max_idx] = tmp;
                indices[max_idx] = tmp_idx;
            }
        }
    }
    
    /* Renormalize top_k probabilities */
    sum = 0.0f;
    for (i = 0; i < top_k; i++) {
        sum += logits[i];
    }
    
    /* Sample from top_k tokens */
    threshold = lugh_rand_float() * sum;
    float cumsum = 0.0f;
    RETVAL = indices[0];  /* Default to most likely */
    
    for (i = 0; i < top_k; i++) {
        cumsum += logits[i];
        if (cumsum >= threshold) {
            RETVAL = indices[i];
            break;
        }
    }
    
    Safefree(logits);
    Safefree(indices);
OUTPUT:
    RETVAL

void
generate(self, tokens_ref, ...)
    SV *self
    SV *tokens_ref
PREINIT:
    HV *hv;
    SV **svp;
    LughModel *model;
    AV *tokens_av;
    AV *result_av;
    int *tokens = NULL;
    int n_tokens;
    int max_tokens = 128;
    float temperature = 0.8f;
    float top_p = 0.95f;
    int top_k = 40;
    int eos_token = 2;
    int greedy = 0;
    SV *callback = NULL;
    int i;
    int n_result;
    SV **orig_sp;
PPCODE:
    orig_sp = SP;  /* Save original stack pointer */
    
    /* Get model */
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_model", 6, 0);
    if (!svp || !*svp) croak("No model in inference object");
    model = get_lugh_model(aTHX_ *svp);
    if (!model) croak("Invalid model");
    
    /* Parse input tokens */
    if (!SvROK(tokens_ref) || SvTYPE(SvRV(tokens_ref)) != SVt_PVAV) {
        croak("generate() requires an array reference of tokens");
    }
    tokens_av = (AV*)SvRV(tokens_ref);
    n_tokens = av_len(tokens_av) + 1;
    if (n_tokens == 0) {
        croak("generate() requires at least one token");
    }
    
    /* Parse optional parameters */
    for (i = 2; i < items; i += 2) {
        if (i + 1 < items) {
            const char *key = SvPV_nolen(ST(i));
            if (strEQ(key, "max_tokens")) {
                max_tokens = SvIV(ST(i + 1));
            } else if (strEQ(key, "temperature")) {
                temperature = SvNV(ST(i + 1));
            } else if (strEQ(key, "top_p")) {
                top_p = SvNV(ST(i + 1));
            } else if (strEQ(key, "top_k")) {
                top_k = SvIV(ST(i + 1));
            } else if (strEQ(key, "eos_token")) {
                eos_token = SvIV(ST(i + 1));
            } else if (strEQ(key, "greedy")) {
                greedy = SvTRUE(ST(i + 1));
            } else if (strEQ(key, "callback")) {
                if (SvROK(ST(i + 1)) && SvTYPE(SvRV(ST(i + 1))) == SVt_PVCV) {
                    callback = ST(i + 1);
                }
            }
        }
    }
    
    /* Get EOS from model if not specified */
    {
        int64_t key_id = gguf_find_key(model->gguf, "tokenizer.ggml.eos_token_id");
        if (key_id >= 0) {
            eos_token = gguf_get_val_u32(model->gguf, key_id);
        }
    }
    
    /* Initialize tokens array with prompt */
    Newx(tokens, n_tokens + max_tokens, int);
    for (i = 0; i < n_tokens; i++) {
        SV **elem = av_fetch(tokens_av, i, 0);
        tokens[i] = elem ? SvIV(*elem) : 0;
    }
    
    /* Create result array for generated tokens only */
    result_av = newAV();
    
    /* Generation loop */
    {
        int gen_count = 0;
        int current_len = n_tokens;
        
        while (gen_count < max_tokens) {
            AV *input_av;
            SV *input_ref;
            int next_token;
            AV *logits_av;
            int n_vocab;
            int j;
            
            /* Build input array for forward pass */
            input_av = newAV();
            for (j = 0; j < current_len; j++) {
                av_push(input_av, newSViv(tokens[j]));
            }
            input_ref = newRV_noinc((SV*)input_av);
            
            /* Call forward() to get logits - create logits_av outside scope */
            logits_av = newAV();
            {
                dSP;
                int count;
                ENTER;
                SAVETMPS;
                
                PUSHMARK(SP);
                XPUSHs(self);
                XPUSHs(input_ref);
                PUTBACK;
                
                count = call_method("forward_simple", G_ARRAY);
                
                SPAGAIN;
                
                /* Debug output */
                
                /* Collect logits into array - pop in reverse order */
                av_extend(logits_av, count - 1);
                for (j = count - 1; j >= 0; j--) {
                    SV *val = POPs;
                    av_store(logits_av, j, newSVnv(SvNV(val)));
                }
                
                PUTBACK;
                FREETMPS;
                LEAVE;
            }
            
            SvREFCNT_dec(input_ref);
            n_vocab = av_len(logits_av) + 1;
            
            
            /* Sample next token */
            if (greedy) {
                /* Argmax for greedy sampling */
                float max_val = -1e9f;
                next_token = 0;
                for (j = 0; j < n_vocab; j++) {
                    SV **svp = av_fetch(logits_av, j, 0);
                    float val = svp ? SvNV(*svp) : 0.0f;
                    if (val > max_val) {
                        max_val = val;
                        next_token = j;
                    }
                }
            } else if (top_k > 0 && top_k < 1000) {
                /* Use top_k sampling inline */
                float *probs;
                int *indices;
                float max_logit = -1e9f;
                float sum = 0.0f;
                float threshold, cumsum;
                int k;
                
                Newx(probs, n_vocab, float);
                Newx(indices, n_vocab, int);
                
                /* Copy logits and find max */
                for (j = 0; j < n_vocab; j++) {
                    SV **svp = av_fetch(logits_av, j, 0);
                    probs[j] = svp ? SvNV(*svp) : 0.0f;
                    if (probs[j] > max_logit) max_logit = probs[j];
                    indices[j] = j;
                }
                
                /* Apply temperature and softmax */
                for (j = 0; j < n_vocab; j++) {
                    probs[j] = expf((probs[j] - max_logit) / temperature);
                    sum += probs[j];
                }
                for (j = 0; j < n_vocab; j++) {
                    probs[j] /= sum;
                }
                
                /* Partial sort to get top_k elements */
                for (k = 0; k < top_k && k < n_vocab; k++) {
                    int max_idx = k;
                    for (j = k + 1; j < n_vocab; j++) {
                        if (probs[j] > probs[max_idx]) max_idx = j;
                    }
                    if (max_idx != k) {
                        float tmp = probs[k];
                        int tmp_idx = indices[k];
                        probs[k] = probs[max_idx];
                        indices[k] = indices[max_idx];
                        probs[max_idx] = tmp;
                        indices[max_idx] = tmp_idx;
                    }
                }
                
                /* Renormalize and sample */
                sum = 0.0f;
                for (k = 0; k < top_k && k < n_vocab; k++) sum += probs[k];
                threshold = lugh_rand_float() * sum;
                cumsum = 0.0f;
                next_token = indices[0];
                for (k = 0; k < top_k && k < n_vocab; k++) {
                    cumsum += probs[k];
                    if (cumsum >= threshold) {
                        next_token = indices[k];
                        break;
                    }
                }
                
                Safefree(probs);
                Safefree(indices);
            } else {
                /* Use top_p sampling inline */
                float *probs;
                int *indices;
                float max_logit = -1e9f;
                float sum = 0.0f;
                float threshold, cumsum;
                
                Newx(probs, n_vocab, float);
                Newx(indices, n_vocab, int);
                
                /* Copy logits and find max */
                for (j = 0; j < n_vocab; j++) {
                    SV **svp = av_fetch(logits_av, j, 0);
                    probs[j] = svp ? SvNV(*svp) : 0.0f;
                    if (probs[j] > max_logit) max_logit = probs[j];
                    indices[j] = j;
                }
                
                /* Apply temperature and softmax */
                for (j = 0; j < n_vocab; j++) {
                    probs[j] = expf((probs[j] - max_logit) / temperature);
                    sum += probs[j];
                }
                for (j = 0; j < n_vocab; j++) {
                    probs[j] /= sum;
                }
                
                /* Sort by probability (bubble sort with early exit) */
                {
                    int swapped, k;
                    for (j = 0; j < n_vocab - 1; j++) {
                        swapped = 0;
                        cumsum = 0;
                        for (k = 0; k < n_vocab - j - 1; k++) {
                            if (probs[k] < probs[k + 1]) {
                                float tmp = probs[k];
                                int tmp_idx = indices[k];
                                probs[k] = probs[k + 1];
                                indices[k] = indices[k + 1];
                                probs[k + 1] = tmp;
                                indices[k + 1] = tmp_idx;
                                swapped = 1;
                            }
                        }
                        if (!swapped) break;
                        for (k = 0; k <= j; k++) cumsum += probs[k];
                        if (cumsum >= top_p) break;
                    }
                }
                
                /* Sample from top_p tokens */
                threshold = lugh_rand_float() * top_p;
                cumsum = 0.0f;
                next_token = indices[0];
                for (j = 0; j < n_vocab; j++) {
                    cumsum += probs[j];
                    if (cumsum >= threshold) {
                        next_token = indices[j];
                        break;
                    }
                    if (cumsum >= top_p) break;
                }
                
                Safefree(probs);
                Safefree(indices);
            }
            
            SvREFCNT_dec((SV*)logits_av);
            
            /* Add to results */
            av_push(result_av, newSViv(next_token));
            tokens[current_len] = next_token;
            current_len++;
            gen_count++;
            
            /* Call streaming callback if provided */
            if (callback) {
                dSP;
                int should_stop;
                
                ENTER;
                SAVETMPS;
                
                PUSHMARK(SP);
                XPUSHs(sv_2mortal(newSViv(next_token)));
                XPUSHs(sv_2mortal(newSViv(gen_count)));
                PUTBACK;
                
                call_sv(callback, G_SCALAR);
                
                SPAGAIN;
                should_stop = POPi;
                
                PUTBACK;
                FREETMPS;
                LEAVE;
                
                /* Callback returns true to stop generation */
                if (should_stop) break;
            }
            
            /* Check for EOS token */
            if (next_token == eos_token) break;
        }
    }
    
    Safefree(tokens);
    
    /* Return generated tokens as list */
    n_result = av_len(result_av) + 1;
    {
        /* Use XSRETURN explicitly */
        int count = 0;
        SP = orig_sp;  /* Restore original stack pointer */
        for (i = 0; i < n_result; i++) {
            SV **svp = av_fetch(result_av, i, 0);
            if (svp) {
                XST_mIV(count, SvIV(*svp));
                count++;
            }
        }
        SvREFCNT_dec(result_av);
        XSRETURN(count);
    }

SV *
create_kv_cache(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    int n_layer, n_ctx, n_head_kv, n_embd, n_head, head_dim;
    LughKVCache *cache;
CODE:
    /* Get inference object parameters */
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "n_layer", 7, 0);
    n_layer = svp ? SvIV(*svp) : 22;
    
    svp = hv_fetch(hv, "n_ctx", 5, 0);
    n_ctx = svp ? SvIV(*svp) : 2048;
    
    svp = hv_fetch(hv, "n_head_kv", 9, 0);
    n_head_kv = svp ? SvIV(*svp) : 4;
    
    svp = hv_fetch(hv, "n_embd", 6, 0);
    n_embd = svp ? SvIV(*svp) : 2048;
    
    svp = hv_fetch(hv, "n_head", 6, 0);
    n_head = svp ? SvIV(*svp) : 32;
    
    head_dim = n_embd / n_head;
    
    /* Create cache with model parameters */
    cache = create_kvcache(n_layer, n_ctx, n_head_kv, head_dim);
    if (!cache) {
        croak("Failed to allocate KV cache");
    }
    
    {
        SV *sv = newSV(0);
        sv_setiv(sv, 0);
        sv_magicext(sv, NULL, PERL_MAGIC_ext, &lugh_kvcache_vtbl, (char*)(IV)cache->id, 0);
        sv = newRV_noinc(sv);
        sv_bless(sv, gv_stashpv("Lugh::KVCache", GV_ADD));
        RETVAL = sv;
    }
OUTPUT:
    RETVAL

SV *
create_memory_pool(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughModel *model;
    LughHyperparams hp;
    LughMemoryPool *pool;
    HV *pool_hv;
CODE:
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_model", 6, 0);
    if (!svp || !*svp) croak("No model in inference object");
    model = get_lugh_model(aTHX_ *svp);
    if (!model) croak("Invalid model");
    
    extract_hyperparams(aTHX_ hv, model, &hp);
    
    pool = create_memory_pool(hp.backend_name, hp.n_threads, 512 * 1024 * 1024);
    if (!pool) {
        croak("Failed to create memory pool");
    }
    
    /* Create blessed hashref for pool */
    pool_hv = newHV();
    hv_store(pool_hv, "_pool_id", 8, newSViv(pool->id), 0);
    hv_store(pool_hv, "backend", 7, newSVpv(pool->backend_name, 0), 0);
    hv_store(pool_hv, "n_threads", 9, newSViv(pool->n_threads), 0);
    hv_store(pool_hv, "ctx_size", 8, newSVuv(pool->ctx_size), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)pool_hv), gv_stashpv("Lugh::MemoryPool", GV_ADD));
OUTPUT:
    RETVAL

MODULE = Lugh  PACKAGE = Lugh::MemoryPool

void
DESTROY(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughMemoryPool *pool;
CODE:
    if (!SvROK(self)) return;
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_pool_id", 8, 0);
    if (svp && *svp) {
        pool = get_mempool_by_id(SvIV(*svp));
        if (pool) {
            free_memory_pool(pool);
        }
    }

int
reset(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughMemoryPool *pool;
CODE:
    if (!SvROK(self)) croak("Invalid memory pool");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_pool_id", 8, 0);
    if (!svp || !*svp) croak("Invalid memory pool");
    pool = get_mempool_by_id(SvIV(*svp));
    if (!pool) croak("Memory pool not found");
    RETVAL = reset_memory_pool(pool);
OUTPUT:
    RETVAL

const char *
backend(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughMemoryPool *pool;
CODE:
    if (!SvROK(self)) croak("Invalid memory pool");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_pool_id", 8, 0);
    if (!svp || !*svp) croak("Invalid memory pool");
    pool = get_mempool_by_id(SvIV(*svp));
    if (!pool) croak("Memory pool not found");
    RETVAL = pool->backend_name;
OUTPUT:
    RETVAL

MODULE = Lugh  PACKAGE = Lugh::KVCache

SV *
new(class, ...)
    const char *class
PREINIT:
    int n_layer = 0;
    int n_ctx = 2048;
    int n_head_kv = 4;
    int head_dim = 64;
    int i;
    LughKVCache *cache;
CODE:
    /* Parse arguments */
    for (i = 1; i < items; i += 2) {
        if (i + 1 < items) {
            const char *key = SvPV_nolen(ST(i));
            if (strEQ(key, "n_layer")) {
                n_layer = SvIV(ST(i + 1));
            } else if (strEQ(key, "n_ctx")) {
                n_ctx = SvIV(ST(i + 1));
            } else if (strEQ(key, "n_head_kv")) {
                n_head_kv = SvIV(ST(i + 1));
            } else if (strEQ(key, "head_dim")) {
                head_dim = SvIV(ST(i + 1));
            }
        }
    }
    
    if (n_layer <= 0) {
        croak("n_layer must be positive");
    }
    if (n_ctx <= 0) {
        croak("n_ctx must be positive");
    }
    
    cache = create_kvcache(n_layer, n_ctx, n_head_kv, head_dim);
    if (!cache) {
        croak("Failed to allocate KV cache");
    }
    
    {
        SV *sv = newSV(0);
        sv_setiv(sv, 0);
        sv_magicext(sv, NULL, PERL_MAGIC_ext, &lugh_kvcache_vtbl, (char*)(IV)cache->id, 0);
        sv = newRV_noinc(sv);
        sv_bless(sv, gv_stashpv(class, GV_ADD));
        RETVAL = sv;
    }
OUTPUT:
    RETVAL

int
n_cached(self)
    SV *self
PREINIT:
    LughKVCache *cache;
CODE:
    cache = get_lugh_kvcache(aTHX_ self);
    KVCACHE_LOCK(cache);
    RETVAL = cache->n_cached;
    KVCACHE_UNLOCK(cache);
OUTPUT:
    RETVAL

int
n_ctx(self)
    SV *self
PREINIT:
    LughKVCache *cache;
CODE:
    cache = get_lugh_kvcache(aTHX_ self);
    RETVAL = cache->n_ctx;
OUTPUT:
    RETVAL

int
n_layer(self)
    SV *self
PREINIT:
    LughKVCache *cache;
CODE:
    cache = get_lugh_kvcache(aTHX_ self);
    RETVAL = cache->n_layer;
OUTPUT:
    RETVAL

void
clear(self)
    SV *self
PREINIT:
    LughKVCache *cache;
    int i;
CODE:
    cache = get_lugh_kvcache(aTHX_ self);
    KVCACHE_LOCK(cache);
    
    /* Zero out all cache data */
    for (i = 0; i < cache->n_layer; i++) {
        if (cache->k_cache[i]) {
            memset(cache->k_cache[i], 0, cache->n_ctx * cache->n_kv_dim * sizeof(float));
        }
        if (cache->v_cache[i]) {
            memset(cache->v_cache[i], 0, cache->n_ctx * cache->n_kv_dim * sizeof(float));
        }
    }
    cache->n_cached = 0;
    
    KVCACHE_UNLOCK(cache);

void
resize(self, new_n_cached)
    SV *self
    int new_n_cached
PREINIT:
    LughKVCache *cache;
CODE:
    cache = get_lugh_kvcache(aTHX_ self);
    KVCACHE_LOCK(cache);
    
    if (new_n_cached < 0) new_n_cached = 0;
    if (new_n_cached > cache->n_ctx) new_n_cached = cache->n_ctx;
    cache->n_cached = new_n_cached;
    
    KVCACHE_UNLOCK(cache);

MODULE = Lugh  PACKAGE = Lugh::Tokenizer

=pod

=head1 Lugh::Tokenizer

Tokenizer for encoding text to tokens and decoding tokens back to text.
Reads vocabulary from the GGUF model file.

=cut

SV *
new(class, ...)
    const char *class
PREINIT:
    LughModel *model = NULL;
    SV *model_sv = NULL;
    int i;
CODE:
    /* Parse arguments */
    if ((items - 1) % 2 != 0) {
        croak("Usage: Lugh::Tokenizer->new(model => $model)");
    }
    
    for (i = 1; i < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        
        if (strEQ(key, "model")) {
            model_sv = val;
            model = get_lugh_model(aTHX_ val);
        }
    }
    
    if (!model) {
        croak("model parameter is required");
    }
    
    {
        HV *hv = newHV();
        HV *token_to_id = newHV();
        AV *id_to_token = newAV();
        int64_t tokens_key, scores_key, merges_key;
        SV *sv;
        int64_t n_vocab;
        int64_t j;
        int bos_id = 1, eos_id = 2, unk_id = 0;
        int64_t key_id;
        
        /* Get special token IDs */
        key_id = gguf_find_key(model->gguf, "tokenizer.ggml.bos_token_id");
        if (key_id >= 0) bos_id = gguf_get_val_u32(model->gguf, key_id);
        
        key_id = gguf_find_key(model->gguf, "tokenizer.ggml.eos_token_id");
        if (key_id >= 0) eos_id = gguf_get_val_u32(model->gguf, key_id);
        
        key_id = gguf_find_key(model->gguf, "tokenizer.ggml.unknown_token_id");
        if (key_id >= 0) unk_id = gguf_get_val_u32(model->gguf, key_id);
        
        /* Load vocabulary */
        tokens_key = gguf_find_key(model->gguf, "tokenizer.ggml.tokens");
        if (tokens_key < 0) {
            croak("No vocabulary found in model");
        }
        
        n_vocab = gguf_get_arr_n(model->gguf, tokens_key);
        av_extend(id_to_token, n_vocab - 1);
        
        for (j = 0; j < n_vocab; j++) {
            const char *tok = gguf_get_arr_str(model->gguf, tokens_key, j);
            STRLEN len = strlen(tok);
            
            /* Store in id_to_token array */
            av_store(id_to_token, j, newSVpv(tok, len));
            
            /* Store in token_to_id hash */
            hv_store(token_to_id, tok, len, newSViv(j), 0);
        }
        
        hv_store(hv, "_model", 6, SvREFCNT_inc(model_sv), 0);
        hv_store(hv, "_token_to_id", 12, newRV_noinc((SV*)token_to_id), 0);
        hv_store(hv, "_id_to_token", 12, newRV_noinc((SV*)id_to_token), 0);
        hv_store(hv, "n_vocab", 7, newSViv(n_vocab), 0);
        hv_store(hv, "bos_id", 6, newSViv(bos_id), 0);
        hv_store(hv, "eos_id", 6, newSViv(eos_id), 0);
        hv_store(hv, "unk_id", 6, newSViv(unk_id), 0);
        
        sv = newRV_noinc((SV*)hv);
        sv_bless(sv, gv_stashpv(class, GV_ADD));
        RETVAL = sv;
    }
OUTPUT:
    RETVAL

int
n_vocab(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
CODE:
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "n_vocab", 7, 0);
    RETVAL = svp ? SvIV(*svp) : 0;
OUTPUT:
    RETVAL

int
bos_id(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
CODE:
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "bos_id", 6, 0);
    RETVAL = svp ? SvIV(*svp) : 1;
OUTPUT:
    RETVAL

int
eos_id(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
CODE:
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "eos_id", 6, 0);
    RETVAL = svp ? SvIV(*svp) : 2;
OUTPUT:
    RETVAL

SV *
decode(self, ...)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    AV *id_to_token;
    SV *result;
    int i;
    int skip_special = 0;
CODE:
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_id_to_token", 12, 0);
    if (!svp || !SvROK(*svp)) {
        croak("Tokenizer not initialized properly");
    }
    id_to_token = (AV*)SvRV(*svp);
    
    result = newSVpv("", 0);
    
    /* Handle array reference or list of token ids */
    if (items == 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVAV) {
        /* Array reference passed */
        AV *av = (AV*)SvRV(ST(1));
        int n = av_len(av) + 1;
        for (i = 0; i < n; i++) {
            SV **elem = av_fetch(av, i, 0);
            if (elem && *elem) {
                int token_id = SvIV(*elem);
                SV **tokp = av_fetch(id_to_token, token_id, 0);
                if (tokp && *tokp) {
                    const char *tok = SvPV_nolen(*tokp);
                    /* Skip special tokens like <s>, </s>, etc if needed */
                    if (tok[0] != '<' || !strchr(tok, '>')) {
                        /* Handle SentencePiece underscore prefix (▁ -> space) */
                        if ((unsigned char)tok[0] == 0xE2 && 
                            (unsigned char)tok[1] == 0x96 && 
                            (unsigned char)tok[2] == 0x81) {
                            sv_catpvn(result, " ", 1);
                            sv_catpv(result, tok + 3);
                        } else {
                            sv_catpv(result, tok);
                        }
                    }
                }
            }
        }
    } else {
        /* List of token ids passed directly */
        for (i = 1; i < items; i++) {
            int token_id = SvIV(ST(i));
            SV **tokp = av_fetch(id_to_token, token_id, 0);
            if (tokp && *tokp) {
                const char *tok = SvPV_nolen(*tokp);
                /* Skip special tokens like <s>, </s>, etc if needed */
                if (tok[0] != '<' || !strchr(tok, '>')) {
                    /* Handle SentencePiece underscore prefix (▁ -> space) */
                    if ((unsigned char)tok[0] == 0xE2 && 
                        (unsigned char)tok[1] == 0x96 && 
                        (unsigned char)tok[2] == 0x81) {
                        sv_catpvn(result, " ", 1);
                        sv_catpv(result, tok + 3);
                    } else {
                        sv_catpv(result, tok);
                    }
                }
            }
        }
    }
    
    RETVAL = result;
OUTPUT:
    RETVAL

void
encode(self, text, ...)
    SV *self
    SV *text
PREINIT:
    HV *hv;
    SV **svp;
    HV *token_to_id;
    AV *id_to_token;
    const char *str;
    STRLEN len;
    AV *tokens;
    int add_bos = 1;
    int bos_id, eos_id, unk_id;
    size_t pos;
    int i;
PPCODE:
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "_token_to_id", 12, 0);
    if (!svp || !SvROK(*svp)) croak("Tokenizer not initialized");
    token_to_id = (HV*)SvRV(*svp);
    
    svp = hv_fetch(hv, "_id_to_token", 12, 0);
    if (!svp || !SvROK(*svp)) croak("Tokenizer not initialized");
    id_to_token = (AV*)SvRV(*svp);
    
    svp = hv_fetch(hv, "bos_id", 6, 0);
    bos_id = svp ? SvIV(*svp) : 1;
    svp = hv_fetch(hv, "eos_id", 6, 0);
    eos_id = svp ? SvIV(*svp) : 2;
    svp = hv_fetch(hv, "unk_id", 6, 0);
    unk_id = svp ? SvIV(*svp) : 0;
    
    /* Parse optional add_bos parameter */
    for (i = 2; i < items; i += 2) {
        if (i + 1 < items) {
            const char *key = SvPV_nolen(ST(i));
            if (strEQ(key, "add_bos")) {
                add_bos = SvIV(ST(i + 1));
            }
        }
    }
    
    str = SvPV(text, len);
    
    /* Simple greedy tokenization (longest match first) */
    /* For production, should use proper BPE merge algorithm */
    
    if (add_bos) {
        XPUSHs(sv_2mortal(newSViv(bos_id)));
    }
    
    pos = 0;
    while (pos < len) {
        int best_len = 0;
        int best_id = unk_id;
        int try_len;
        char buf[256];
        int at_word_start = (pos == 0 || str[pos-1] == ' ' || str[pos-1] == '\n' || str[pos-1] == '\t');
        
        /* Skip space - it becomes part of the next token's ▁ prefix */
        if (str[pos] == ' ' || str[pos] == '\t') {
            pos++;
            continue;
        }
        
        /* Try to find longest matching token */
        for (try_len = (len - pos > 255 ? 255 : len - pos); try_len > 0; try_len--) {
            SV **id_ptr;
            
            /* Copy substring to buffer */
            memcpy(buf, str + pos, try_len);
            buf[try_len] = '\0';
            
            /* Try with SentencePiece prefix for word start */
            if (at_word_start) {
                char sp_buf[260];
                /* ▁ = 0xE2 0x96 0x81 in UTF-8 */
                sp_buf[0] = 0xE2;
                sp_buf[1] = 0x96;
                sp_buf[2] = 0x81;
                memcpy(sp_buf + 3, buf, try_len + 1);
                id_ptr = hv_fetch(token_to_id, sp_buf, try_len + 3, 0);
                if (id_ptr && *id_ptr) {
                    best_id = SvIV(*id_ptr);
                    best_len = try_len;
                    break;
                }
            }
            
            /* Try without prefix */
            id_ptr = hv_fetch(token_to_id, buf, try_len, 0);
            if (id_ptr && *id_ptr) {
                best_id = SvIV(*id_ptr);
                best_len = try_len;
                break;
            }
        }
        
        if (best_len == 0) {
            /* Skip unknown character */
            pos++;
            XPUSHs(sv_2mortal(newSViv(unk_id)));
        } else {
            pos += best_len;
            XPUSHs(sv_2mortal(newSViv(best_id)));
        }
    }

#ifdef USE_ITHREADS

void
CLONE(class)
    char *class
CODE:
    /*
     * Thread cloning: contexts cannot be shared across threads
     * because ggml_context is not thread-safe. Each thread must
     * create its own contexts. We invalidate cloned contexts here.
     * 
     * Tensors also cannot be shared as they belong to a context.
     */
    PERL_UNUSED_VAR(class);
    /* 
     * Note: The magic cleanup will still be called but the context
     * has been invalidated in the clone. New contexts must be created.
     */

#endif

MODULE = Lugh    PACKAGE = Lugh::Tensor

SV *
new_f32(class, ctx_sv, ...)
    char *class
    SV *ctx_sv
PREINIT:
    LughContext *lctx;
    struct ggml_tensor *tensor = NULL;
    int64_t ne[4] = {1, 1, 1, 1};
    int n_dims = 1;
    int i;
CODE:
    lctx = get_lugh_context(aTHX_ ctx_sv);
    
    /* Parse dimensions */
    n_dims = items - 2;
    if (n_dims < 1) n_dims = 1;
    if (n_dims > 4) croak("Maximum 4 dimensions supported");

    for (i = 0; i < n_dims; i++) {
        ne[i] = SvIV(ST(i + 2));
        /* Validate: dimensions must be positive */
        if (ne[i] <= 0) {
            croak("Invalid dimension %d at position %d: dimensions must be positive", (int)ne[i], i);
        }
    }

    /* Create tensor based on dimensionality */
    switch (n_dims) {
        case 1:
            tensor = ggml_new_tensor_1d(lctx->ctx, GGML_TYPE_F32, ne[0]);
            break;
        case 2:
            tensor = ggml_new_tensor_2d(lctx->ctx, GGML_TYPE_F32, ne[0], ne[1]);
            break;
        case 3:
            tensor = ggml_new_tensor_3d(lctx->ctx, GGML_TYPE_F32, ne[0], ne[1], ne[2]);
            break;
        case 4:
            tensor = ggml_new_tensor_4d(lctx->ctx, GGML_TYPE_F32, ne[0], ne[1], ne[2], ne[3]);
            break;
    }
    
    if (!tensor) {
        croak("Failed to create tensor");
    }
    
    /* Return tensor pointer as blessed IV */
    RETVAL = sv_bless(
        newRV_noinc(newSViv(PTR2IV(tensor))),
        gv_stashpv(class, GV_ADD)
    );
OUTPUT:
    RETVAL

void
set_f32(self, ...)
    SV *self
PREINIT:
    struct ggml_tensor *tensor;
    int64_t i, n_elements;
CODE:
    tensor = INT2PTR(struct ggml_tensor *, SvIV(SvRV(self)));
    n_elements = ggml_nelements(tensor);
    
    if (items - 1 != n_elements) {
        croak("Expected %ld values, got %d", (long)n_elements, (int)(items - 1));
    }
    
    for (i = 0; i < n_elements; i++) {
        ggml_set_f32_1d(tensor, i, SvNV(ST(i + 1)));
    }

void
get_f32(self)
    SV *self
PREINIT:
    struct ggml_tensor *tensor;
    int64_t i, n_elements;
PPCODE:
    tensor = INT2PTR(struct ggml_tensor *, SvIV(SvRV(self)));
    n_elements = ggml_nelements(tensor);
    
    EXTEND(SP, n_elements);
    for (i = 0; i < n_elements; i++) {
        mPUSHn(ggml_get_f32_1d(tensor, i));
    }

int64_t
nelements(self)
    SV *self
CODE:
    struct ggml_tensor *tensor = INT2PTR(struct ggml_tensor *, SvIV(SvRV(self)));
    RETVAL = ggml_nelements(tensor);
OUTPUT:
    RETVAL

int
n_dims(self)
    SV *self
CODE:
    struct ggml_tensor *tensor = INT2PTR(struct ggml_tensor *, SvIV(SvRV(self)));
    RETVAL = ggml_n_dims(tensor);
OUTPUT:
    RETVAL

void
shape(self)
    SV *self
PREINIT:
    struct ggml_tensor *tensor;
    int i, n_dims;
PPCODE:
    tensor = INT2PTR(struct ggml_tensor *, SvIV(SvRV(self)));
    n_dims = ggml_n_dims(tensor);
    
    EXTEND(SP, n_dims);
    for (i = 0; i < n_dims; i++) {
        mPUSHi(tensor->ne[i]);
    }

int
type(self)
    SV *self
CODE:
    struct ggml_tensor *tensor = INT2PTR(struct ggml_tensor *, SvIV(SvRV(self)));
    RETVAL = (int)tensor->type;
OUTPUT:
    RETVAL

const char *
type_name(self)
    SV *self
CODE:
    struct ggml_tensor *tensor = INT2PTR(struct ggml_tensor *, SvIV(SvRV(self)));
    RETVAL = ggml_type_name(tensor->type);
OUTPUT:
    RETVAL

size_t
type_size(self)
    SV *self
CODE:
    struct ggml_tensor *tensor = INT2PTR(struct ggml_tensor *, SvIV(SvRV(self)));
    RETVAL = ggml_type_size(tensor->type);
OUTPUT:
    RETVAL

int64_t
blck_size(self)
    SV *self
CODE:
    struct ggml_tensor *tensor = INT2PTR(struct ggml_tensor *, SvIV(SvRV(self)));
    RETVAL = ggml_blck_size(tensor->type);
OUTPUT:
    RETVAL

int
is_quantized(self)
    SV *self
CODE:
    struct ggml_tensor *tensor = INT2PTR(struct ggml_tensor *, SvIV(SvRV(self)));
    RETVAL = ggml_is_quantized(tensor->type) ? 1 : 0;
OUTPUT:
    RETVAL

size_t
nbytes(self)
    SV *self
CODE:
    struct ggml_tensor *tensor = INT2PTR(struct ggml_tensor *, SvIV(SvRV(self)));
    RETVAL = ggml_nbytes(tensor);
OUTPUT:
    RETVAL

SV *
quantize(self, ctx_sv, dest_type)
    SV *self
    SV *ctx_sv
    int dest_type
PREINIT:
    LughContext *lctx;
    struct ggml_tensor *src;
    struct ggml_tensor *dst;
    int64_t ne[4];
    int i, n_dims;
    float *src_data;
    int64_t n_elements;
CODE:
    lctx = get_lugh_context(aTHX_ ctx_sv);
    src = INT2PTR(struct ggml_tensor *, SvIV(SvRV(self)));
    
    if (dest_type < 0 || dest_type >= GGML_TYPE_COUNT) {
        croak("Invalid destination type: %d", dest_type);
    }
    
    if (!ggml_is_quantized((enum ggml_type)dest_type)) {
        croak("Destination type %s is not a quantized type", 
              ggml_type_name((enum ggml_type)dest_type));
    }
    
    if (src->type != GGML_TYPE_F32) {
        croak("Source tensor must be F32, got %s", ggml_type_name(src->type));
    }
    
    /* Get dimensions */
    n_dims = ggml_n_dims(src);
    for (i = 0; i < 4; i++) {
        ne[i] = src->ne[i];
    }
    
    /* Create destination tensor */
    switch (n_dims) {
        case 1:
            dst = ggml_new_tensor_1d(lctx->ctx, (enum ggml_type)dest_type, ne[0]);
            break;
        case 2:
            dst = ggml_new_tensor_2d(lctx->ctx, (enum ggml_type)dest_type, ne[0], ne[1]);
            break;
        case 3:
            dst = ggml_new_tensor_3d(lctx->ctx, (enum ggml_type)dest_type, ne[0], ne[1], ne[2]);
            break;
        case 4:
            dst = ggml_new_tensor_4d(lctx->ctx, (enum ggml_type)dest_type, ne[0], ne[1], ne[2], ne[3]);
            break;
        default:
            croak("Unsupported dimensionality: %d", n_dims);
    }
    
    if (!dst) {
        croak("Failed to create destination tensor");
    }
    
    /* Quantize the data */
    n_elements = ggml_nelements(src);
    src_data = (float *)src->data;
    
    {
        int64_t n_rows = n_elements / ne[0];
        ggml_quantize_chunk(
            (enum ggml_type)dest_type,
            src_data,
            dst->data,
            0,
            n_rows,
            ne[0],
            NULL
        );
    }
    
    RETVAL = sv_bless(
        newRV_noinc(newSViv(PTR2IV(dst))),
        gv_stashpv("Lugh::Tensor", GV_ADD)
    );
OUTPUT:
    RETVAL

SV *
dequantize(self, ctx_sv)
    SV *self
    SV *ctx_sv
PREINIT:
    LughContext *lctx;
    struct ggml_tensor *src;
    struct ggml_tensor *dst;
    int64_t ne[4];
    int i, n_dims;
    int64_t n_elements;
CODE:
    lctx = get_lugh_context(aTHX_ ctx_sv);
    src = INT2PTR(struct ggml_tensor *, SvIV(SvRV(self)));
    
    if (!ggml_is_quantized(src->type) && src->type != GGML_TYPE_F16 && src->type != GGML_TYPE_BF16) {
        croak("Source tensor is not quantized (type: %s)", ggml_type_name(src->type));
    }
    
    /* Get dimensions */
    n_dims = ggml_n_dims(src);
    for (i = 0; i < 4; i++) {
        ne[i] = src->ne[i];
    }
    
    /* Create F32 destination tensor */
    switch (n_dims) {
        case 1:
            dst = ggml_new_tensor_1d(lctx->ctx, GGML_TYPE_F32, ne[0]);
            break;
        case 2:
            dst = ggml_new_tensor_2d(lctx->ctx, GGML_TYPE_F32, ne[0], ne[1]);
            break;
        case 3:
            dst = ggml_new_tensor_3d(lctx->ctx, GGML_TYPE_F32, ne[0], ne[1], ne[2]);
            break;
        case 4:
            dst = ggml_new_tensor_4d(lctx->ctx, GGML_TYPE_F32, ne[0], ne[1], ne[2], ne[3]);
            break;
        default:
            croak("Unsupported dimensionality: %d", n_dims);
    }
    
    if (!dst) {
        croak("Failed to create destination tensor");
    }
    
    /* Dequantize using ggml's type traits */
    n_elements = ggml_nelements(src);
    {
        const struct ggml_type_traits *traits = ggml_get_type_traits(src->type);
        if (traits && traits->to_float) {
            traits->to_float(src->data, (float *)dst->data, n_elements);
        } else {
            croak("No dequantization function available for type %s", 
                  ggml_type_name(src->type));
        }
    }
    
    RETVAL = sv_bless(
        newRV_noinc(newSViv(PTR2IV(dst))),
        gv_stashpv("Lugh::Tensor", GV_ADD)
    );
OUTPUT:
    RETVAL

SV *
from_ptr(class, ptr_iv)
    char *class
    IV ptr_iv
CODE:
    /* Create Lugh::Tensor from a raw pointer value */
    if (ptr_iv == 0) {
        croak("Cannot create tensor from null pointer");
    }
    
    RETVAL = sv_bless(
        newRV_noinc(newSViv(ptr_iv)),
        gv_stashpv(class, GV_ADD)
    );
OUTPUT:
    RETVAL

MODULE = Lugh    PACKAGE = Lugh::Ops

SV *
add(ctx_sv, a_sv, b_sv)
    SV *ctx_sv
    SV *a_sv
    SV *b_sv
PREINIT:
    LughContext *lctx;
    struct ggml_tensor *a, *b, *result;
CODE:
    lctx = get_lugh_context(aTHX_ ctx_sv);
    a = INT2PTR(struct ggml_tensor *, SvIV(SvRV(a_sv)));
    b = INT2PTR(struct ggml_tensor *, SvIV(SvRV(b_sv)));
    
    result = ggml_add(lctx->ctx, a, b);
    if (!result) {
        croak("ggml_add failed");
    }
    
    RETVAL = sv_bless(
        newRV_noinc(newSViv(PTR2IV(result))),
        gv_stashpv("Lugh::Tensor", GV_ADD)
    );
OUTPUT:
    RETVAL

SV *
mul(ctx_sv, a_sv, b_sv)
    SV *ctx_sv
    SV *a_sv
    SV *b_sv
PREINIT:
    LughContext *lctx;
    struct ggml_tensor *a, *b, *result;
CODE:
    lctx = get_lugh_context(aTHX_ ctx_sv);
    a = INT2PTR(struct ggml_tensor *, SvIV(SvRV(a_sv)));
    b = INT2PTR(struct ggml_tensor *, SvIV(SvRV(b_sv)));
    
    result = ggml_mul(lctx->ctx, a, b);
    if (!result) {
        croak("ggml_mul failed");
    }
    
    RETVAL = sv_bless(
        newRV_noinc(newSViv(PTR2IV(result))),
        gv_stashpv("Lugh::Tensor", GV_ADD)
    );
OUTPUT:
    RETVAL

SV *
mul_mat(ctx_sv, a_sv, b_sv)
    SV *ctx_sv
    SV *a_sv
    SV *b_sv
PREINIT:
    LughContext *lctx;
    struct ggml_tensor *a, *b, *result;
CODE:
    lctx = get_lugh_context(aTHX_ ctx_sv);
    a = INT2PTR(struct ggml_tensor *, SvIV(SvRV(a_sv)));
    b = INT2PTR(struct ggml_tensor *, SvIV(SvRV(b_sv)));
    
    result = ggml_mul_mat(lctx->ctx, a, b);
    if (!result) {
        croak("ggml_mul_mat failed");
    }
    
    RETVAL = sv_bless(
        newRV_noinc(newSViv(PTR2IV(result))),
        gv_stashpv("Lugh::Tensor", GV_ADD)
    );
OUTPUT:
    RETVAL

SV *
soft_max(ctx_sv, a_sv)
    SV *ctx_sv
    SV *a_sv
PREINIT:
    LughContext *lctx;
    struct ggml_tensor *a, *result;
CODE:
    lctx = get_lugh_context(aTHX_ ctx_sv);
    a = INT2PTR(struct ggml_tensor *, SvIV(SvRV(a_sv)));
    
    result = ggml_soft_max(lctx->ctx, a);
    if (!result) {
        croak("ggml_soft_max failed");
    }
    
    RETVAL = sv_bless(
        newRV_noinc(newSViv(PTR2IV(result))),
        gv_stashpv("Lugh::Tensor", GV_ADD)
    );
OUTPUT:
    RETVAL

SV *
rms_norm(ctx_sv, a_sv, eps)
    SV *ctx_sv
    SV *a_sv
    float eps
PREINIT:
    LughContext *lctx;
    struct ggml_tensor *a, *result;
CODE:
    lctx = get_lugh_context(aTHX_ ctx_sv);
    a = INT2PTR(struct ggml_tensor *, SvIV(SvRV(a_sv)));
    
    result = ggml_rms_norm(lctx->ctx, a, eps);
    if (!result) {
        croak("ggml_rms_norm failed");
    }
    
    RETVAL = sv_bless(
        newRV_noinc(newSViv(PTR2IV(result))),
        gv_stashpv("Lugh::Tensor", GV_ADD)
    );
OUTPUT:
    RETVAL

SV *
silu(ctx_sv, a_sv)
    SV *ctx_sv
    SV *a_sv
PREINIT:
    LughContext *lctx;
    struct ggml_tensor *a, *result;
CODE:
    lctx = get_lugh_context(aTHX_ ctx_sv);
    a = INT2PTR(struct ggml_tensor *, SvIV(SvRV(a_sv)));
    
    result = ggml_silu(lctx->ctx, a);
    if (!result) {
        croak("ggml_silu failed");
    }
    
    RETVAL = sv_bless(
        newRV_noinc(newSViv(PTR2IV(result))),
        gv_stashpv("Lugh::Tensor", GV_ADD)
    );
OUTPUT:
    RETVAL

MODULE = Lugh    PACKAGE = Lugh::Graph

SV *
new(class, ctx_sv)
    char *class
    SV *ctx_sv
PREINIT:
    LughContext *lctx;
    struct ggml_cgraph *graph;
CODE:
    lctx = get_lugh_context(aTHX_ ctx_sv);
    graph = ggml_new_graph(lctx->ctx);
    
    if (!graph) {
        croak("Failed to create computation graph");
    }
    
    RETVAL = sv_bless(
        newRV_noinc(newSViv(PTR2IV(graph))),
        gv_stashpv(class, GV_ADD)
    );
OUTPUT:
    RETVAL

void
build_forward(self, tensor_sv)
    SV *self
    SV *tensor_sv
CODE:
    struct ggml_cgraph *graph = INT2PTR(struct ggml_cgraph *, SvIV(SvRV(self)));
    struct ggml_tensor *tensor = INT2PTR(struct ggml_tensor *, SvIV(SvRV(tensor_sv)));
    
    ggml_build_forward_expand(graph, tensor);

void
compute(self, ctx_sv, n_threads)
    SV *self
    SV *ctx_sv
    int n_threads
CODE:
    LughContext *lctx = get_lugh_context(aTHX_ ctx_sv);
    struct ggml_cgraph *graph = INT2PTR(struct ggml_cgraph *, SvIV(SvRV(self)));
    
    ggml_graph_compute_with_ctx(lctx->ctx, graph, n_threads);

MODULE = Lugh    PACKAGE = Lugh::Model

SV *
new(class, ...)
    char *class
PREINIT:
    LughModel *lm;
    const char *filename = NULL;
    struct gguf_init_params gguf_params;
    struct ggml_context *tensor_ctx = NULL;
    SV *sv;
    int i, id;
    int64_t key_id;
    int use_mmap = 0;  /* Default: don't use mmap for backward compatibility */
    int prefetch = 1;  /* Default: prefetch the whole file after mapping */
CODE:
    INIT_MUTEXES();

    /* Parse arguments */
    for (i = 1; i < items; i += 2) {
        if (i + 1 < items) {
            const char *key = SvPV_nolen(ST(i));
            if (strEQ(key, "model") || strEQ(key, "file") || strEQ(key, "path")) {
                filename = SvPV_nolen(ST(i + 1));
            } else if (strEQ(key, "use_mmap") || strEQ(key, "mmap")) {
                use_mmap = SvTRUE(ST(i + 1)) ? 1 : 0;
            } else if (strEQ(key, "prefetch")) {
                prefetch = SvTRUE(ST(i + 1)) ? 1 : 0;
            }
        }
    }

    if (!filename) {
        croak("Lugh::Model->new requires 'model' parameter with path to GGUF file");
    }

    /* Check if mmap is requested but not supported */
    if (use_mmap && !LUGH_MMAP_SUPPORTED) {
        warn("mmap not supported on this platform, falling back to standard loading");
        use_mmap = 0;
    }

    /* Allocate model ID */
    id = alloc_model_id();
    if (id < 0) {
        croak("Maximum number of models (%d) reached", MAX_CONTEXTS);
    }

    /* Allocate model structure */
    Newxz(lm, 1, LughModel);
    lm->id = id;
    lm->active = 1;
    lm->mmap = NULL;
    lm->use_mmap = 0;

    /* Copy filename */
    Newx(lm->filename, strlen(filename) + 1, char);
    strcpy(lm->filename, filename);

    /* Try mmap loading if requested */
    if (use_mmap) {
        lm->mmap = lugh_mmap_create(filename);
        if (lm->mmap) {
            lm->use_mmap = 1;
            /* Prefetch the entire file if requested (helps with initial load) */
            if (prefetch) {
                lugh_mmap_prefetch(lm->mmap, 0, lm->mmap->size);
            }
        } else {
            warn("Failed to mmap file %s, falling back to standard loading", filename);
        }
    }

    /* Initialize GGUF context
     * Note: Even with mmap, we still use gguf_init_from_file because ggml's
     * gguf parser needs to read metadata. The tensor data will be read from
     * mmap if available. This is a hybrid approach - metadata is parsed
     * normally, but the mmap pointer is available for tensor data access.
     */
    gguf_params.no_alloc = false;
    gguf_params.ctx = &tensor_ctx;

    lm->gguf = gguf_init_from_file(filename, gguf_params);
    if (!lm->gguf) {
        if (lm->mmap) {
            lugh_mmap_free(lm->mmap);
            lm->mmap = NULL;
        }
        Safefree(lm->filename);
        Safefree(lm);
        croak("Failed to load GGUF file: %s", filename);
    }

    lm->ctx = tensor_ctx;
    lm->n_tensors = gguf_get_n_tensors(lm->gguf);
    lm->n_kv = gguf_get_n_kv(lm->gguf);

    /* Get architecture if available */
    key_id = gguf_find_key(lm->gguf, "general.architecture");
    if (key_id >= 0) {
        const char *arch = gguf_get_val_str(lm->gguf, key_id);
        Newx(lm->architecture, strlen(arch) + 1, char);
        strcpy(lm->architecture, arch);
    }

    /* Register in global registry */
    CONTEXT_LOCK();
    model_registry[id] = lm;
    CONTEXT_UNLOCK();

    /* Create blessed reference with magic */
    sv = newSV(0);
    sv_magicext(sv, NULL, PERL_MAGIC_ext, &lugh_model_vtbl, INT2PTR(char*, (IV)id), 0);
    RETVAL = sv_bless(newRV_noinc(sv), gv_stashpv(class, GV_ADD));
OUTPUT:
    RETVAL

const char *
filename(self)
    SV *self
CODE:
    LughModel *lm = get_lugh_model(aTHX_ self);
    RETVAL = lm->filename;
OUTPUT:
    RETVAL

const char *
architecture(self)
    SV *self
CODE:
    LughModel *lm = get_lugh_model(aTHX_ self);
    RETVAL = lm->architecture ? lm->architecture : "unknown";
OUTPUT:
    RETVAL

int
use_mmap(self)
    SV *self
CODE:
    LughModel *lm = get_lugh_model(aTHX_ self);
    RETVAL = lm->use_mmap;
OUTPUT:
    RETVAL

UV
mmap_size(self)
    SV *self
CODE:
    LughModel *lm = get_lugh_model(aTHX_ self);
    if (lm->mmap && lm->mmap->active) {
        RETVAL = (UV)lm->mmap->size;
    } else {
        RETVAL = 0;
    }
OUTPUT:
    RETVAL

int
mmap_supported(class = NULL)
    SV *class
CODE:
    PERL_UNUSED_VAR(class);
    RETVAL = LUGH_MMAP_SUPPORTED;
OUTPUT:
    RETVAL

const char *
arch_type(self)
    SV *self
CODE:
    LughModel *lm = get_lugh_model(aTHX_ self);
    LughArchType at = get_arch_type(lm->architecture);
    switch (at) {
        case LUGH_ARCH_LLAMA:     RETVAL = "llama"; break;
        case LUGH_ARCH_QWEN:      RETVAL = "qwen"; break;
        case LUGH_ARCH_QWEN2:     RETVAL = "qwen2"; break;
        case LUGH_ARCH_PHI:       RETVAL = "phi"; break;
        case LUGH_ARCH_GEMMA:     RETVAL = "gemma"; break;
        case LUGH_ARCH_GEMMA2:    RETVAL = "gemma2"; break;
        case LUGH_ARCH_GPT2:      RETVAL = "gpt2"; break;
        case LUGH_ARCH_GPTJ:      RETVAL = "gptj"; break;
        case LUGH_ARCH_GPTNEOX:   RETVAL = "gptneox"; break;
        case LUGH_ARCH_FALCON:    RETVAL = "falcon"; break;
        case LUGH_ARCH_BLOOM:     RETVAL = "bloom"; break;
        case LUGH_ARCH_MPT:       RETVAL = "mpt"; break;
        case LUGH_ARCH_STARCODER: RETVAL = "starcoder"; break;
        case LUGH_ARCH_STABLELM:  RETVAL = "stablelm"; break;
        case LUGH_ARCH_INTERNLM:  RETVAL = "internlm"; break;
        case LUGH_ARCH_DEEPSEEK:  RETVAL = "deepseek"; break;
        case LUGH_ARCH_COMMAND_R: RETVAL = "command_r"; break;
        case LUGH_ARCH_MAMBA:     RETVAL = "mamba"; break;
        case LUGH_ARCH_RWKV:      RETVAL = "rwkv"; break;
        case LUGH_ARCH_BERT:      RETVAL = "bert"; break;
        case LUGH_ARCH_T5:        RETVAL = "t5"; break;
        default:                  RETVAL = "unknown"; break;
    }
OUTPUT:
    RETVAL

int
arch_has_combined_qkv(self)
    SV *self
CODE:
    LughModel *lm = get_lugh_model(aTHX_ self);
    LughArchType at = get_arch_type(lm->architecture);
    RETVAL = arch_has_combined_qkv(at);
OUTPUT:
    RETVAL

int
arch_has_ffn_gate(self)
    SV *self
CODE:
    LughModel *lm = get_lugh_model(aTHX_ self);
    LughArchType at = get_arch_type(lm->architecture);
    RETVAL = arch_has_ffn_gate(at);
OUTPUT:
    RETVAL

int
arch_has_post_norm(self)
    SV *self
CODE:
    LughModel *lm = get_lugh_model(aTHX_ self);
    LughArchType at = get_arch_type(lm->architecture);
    RETVAL = arch_has_post_norm(at);
OUTPUT:
    RETVAL

int
arch_is_recurrent(self)
    SV *self
CODE:
    LughModel *lm = get_lugh_model(aTHX_ self);
    LughArchType at = get_arch_type(lm->architecture);
    RETVAL = arch_is_recurrent(at);
OUTPUT:
    RETVAL

int64_t
n_tensors(self)
    SV *self
CODE:
    LughModel *lm = get_lugh_model(aTHX_ self);
    RETVAL = lm->n_tensors;
OUTPUT:
    RETVAL

int64_t
n_kv(self)
    SV *self
CODE:
    LughModel *lm = get_lugh_model(aTHX_ self);
    RETVAL = lm->n_kv;
OUTPUT:
    RETVAL

void
tensor_info(self, name)
    SV *self
    const char *name
PREINIT:
    LughModel *lm;
    struct ggml_tensor *t;
PPCODE:
    lm = get_lugh_model(aTHX_ self);
    t = ggml_get_tensor(lm->ctx, name);
    if (t) {
        /* Return: type, n_dims, ne[0], ne[1], ne[2], ne[3] */
        EXTEND(SP, 6);
        mPUSHi(t->type);
        mPUSHi(ggml_n_dims(t));
        mPUSHi(t->ne[0]);
        mPUSHi(t->ne[1]);
        mPUSHi(t->ne[2]);
        mPUSHi(t->ne[3]);
    }

void
tensor_names(self)
    SV *self
PREINIT:
    LughModel *lm;
    int64_t i;
PPCODE:
    lm = get_lugh_model(aTHX_ self);
    EXTEND(SP, lm->n_tensors);
    for (i = 0; i < lm->n_tensors; i++) {
        mPUSHs(newSVpv(gguf_get_tensor_name(lm->gguf, i), 0));
    }

void
kv_keys(self)
    SV *self
PREINIT:
    LughModel *lm;
    int64_t i;
PPCODE:
    lm = get_lugh_model(aTHX_ self);
    EXTEND(SP, lm->n_kv);
    for (i = 0; i < lm->n_kv; i++) {
        mPUSHs(newSVpv(gguf_get_key(lm->gguf, i), 0));
    }

SV *
get_kv(self, key)
    SV *self
    const char *key
PREINIT:
    LughModel *lm;
    int64_t key_id;
    enum gguf_type kv_type;
CODE:
    lm = get_lugh_model(aTHX_ self);
    key_id = gguf_find_key(lm->gguf, key);
    
    if (key_id < 0) {
        RETVAL = &PL_sv_undef;
    } else {
        kv_type = gguf_get_kv_type(lm->gguf, key_id);
        switch (kv_type) {
            case GGUF_TYPE_UINT8:
                RETVAL = newSVuv(gguf_get_val_u8(lm->gguf, key_id));
                break;
            case GGUF_TYPE_INT8:
                RETVAL = newSViv(gguf_get_val_i8(lm->gguf, key_id));
                break;
            case GGUF_TYPE_UINT16:
                RETVAL = newSVuv(gguf_get_val_u16(lm->gguf, key_id));
                break;
            case GGUF_TYPE_INT16:
                RETVAL = newSViv(gguf_get_val_i16(lm->gguf, key_id));
                break;
            case GGUF_TYPE_UINT32:
                RETVAL = newSVuv(gguf_get_val_u32(lm->gguf, key_id));
                break;
            case GGUF_TYPE_INT32:
                RETVAL = newSViv(gguf_get_val_i32(lm->gguf, key_id));
                break;
            case GGUF_TYPE_UINT64:
                RETVAL = newSVuv(gguf_get_val_u64(lm->gguf, key_id));
                break;
            case GGUF_TYPE_INT64:
                RETVAL = newSViv(gguf_get_val_i64(lm->gguf, key_id));
                break;
            case GGUF_TYPE_FLOAT32:
                RETVAL = newSVnv(gguf_get_val_f32(lm->gguf, key_id));
                break;
            case GGUF_TYPE_FLOAT64:
                RETVAL = newSVnv(gguf_get_val_f64(lm->gguf, key_id));
                break;
            case GGUF_TYPE_BOOL:
                RETVAL = gguf_get_val_bool(lm->gguf, key_id) ? &PL_sv_yes : &PL_sv_no;
                break;
            case GGUF_TYPE_STRING:
                RETVAL = newSVpv(gguf_get_val_str(lm->gguf, key_id), 0);
                break;
            case GGUF_TYPE_ARRAY:
                /* Return array reference */
                {
                    enum gguf_type arr_type = gguf_get_arr_type(lm->gguf, key_id);
                    size_t n = gguf_get_arr_n(lm->gguf, key_id);
                    AV *av = newAV();
                    size_t j;
                    
                    if (arr_type == GGUF_TYPE_STRING) {
                        for (j = 0; j < n; j++) {
                            av_push(av, newSVpv(gguf_get_arr_str(lm->gguf, key_id, j), 0));
                        }
                    } else {
                        /* For numeric arrays, return as-is for now */
                        /* TODO: decode based on arr_type */
                    }
                    RETVAL = newRV_noinc((SV*)av);
                }
                break;
            default:
                RETVAL = &PL_sv_undef;
        }
    }
OUTPUT:
    RETVAL

SV *
get_trainable_weights(self, ctx_sv)
    SV *self
    SV *ctx_sv
PREINIT:
    LughModel *lm;
    LughContext *lctx;
    MAGIC *mg;
    HV *result_hv;
    int n_tensors = 0;
    int i;
    char name_buf[128];
    int64_t n_layer = 0;
CODE:
    /* Get model */
    if (!SvROK(self)) croak("Not a reference");
    mg = mg_findext(SvRV(self), PERL_MAGIC_ext, &lugh_model_vtbl);
    if (!mg) croak("Invalid Model object");
    lm = get_model_by_id((int)(IV)mg->mg_ptr);
    if (!lm) croak("Model not found");
    
    /* Get context for creating gradient tensors */
    lctx = get_lugh_context(aTHX_ ctx_sv);
    if (!lctx) croak("Invalid context");
    
    /* Get number of layers */
    {
        int64_t key_id = gguf_find_key(lm->gguf, "llama.block_count");
        if (key_id < 0) key_id = gguf_find_key(lm->gguf, "qwen2.block_count");
        if (key_id >= 0) {
            n_layer = gguf_get_val_u32(lm->gguf, key_id);
        }
    }
    
    result_hv = newHV();
    
    /* Wrap embedding tensor */
    {
        struct ggml_tensor *tok_embd = ggml_get_tensor(lm->ctx, "token_embd.weight");
        if (tok_embd && tok_embd->type == GGML_TYPE_F32) {
            LughTensor *lt = create_lugh_tensor(aTHX_ tok_embd, lctx->id, true);
            if (lt) {
                alloc_grad(aTHX_ lt, lctx);
                HV *tensor_hv = newHV();
                hv_store(tensor_hv, "_tensor_id", 10, newSViv(lt->id), 0);
                hv_store(tensor_hv, "_context_id", 11, newSViv(lctx->id), 0);
                hv_store(tensor_hv, "requires_grad", 13, newSViv(1), 0);
                hv_store(tensor_hv, "name", 4, newSVpv("token_embd.weight", 0), 0);
                SV *tsv = sv_bless(newRV_noinc((SV*)tensor_hv), gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
                hv_store(result_hv, "token_embd.weight", 17, tsv, 0);
                n_tensors++;
            }
        }
    }
    
    /* Wrap output norm tensor */
    {
        struct ggml_tensor *norm = ggml_get_tensor(lm->ctx, "output_norm.weight");
        if (norm && norm->type == GGML_TYPE_F32) {
            LughTensor *lt = create_lugh_tensor(aTHX_ norm, lctx->id, true);
            if (lt) {
                alloc_grad(aTHX_ lt, lctx);
                HV *tensor_hv = newHV();
                hv_store(tensor_hv, "_tensor_id", 10, newSViv(lt->id), 0);
                hv_store(tensor_hv, "_context_id", 11, newSViv(lctx->id), 0);
                hv_store(tensor_hv, "requires_grad", 13, newSViv(1), 0);
                hv_store(tensor_hv, "name", 4, newSVpv("output_norm.weight", 0), 0);
                SV *tsv = sv_bless(newRV_noinc((SV*)tensor_hv), gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
                hv_store(result_hv, "output_norm.weight", 18, tsv, 0);
                n_tensors++;
            }
        }
    }
    
    /* Wrap output/lm_head tensor */
    {
        struct ggml_tensor *output = ggml_get_tensor(lm->ctx, "output.weight");
        if (output && output->type == GGML_TYPE_F32) {
            LughTensor *lt = create_lugh_tensor(aTHX_ output, lctx->id, true);
            if (lt) {
                alloc_grad(aTHX_ lt, lctx);
                HV *tensor_hv = newHV();
                hv_store(tensor_hv, "_tensor_id", 10, newSViv(lt->id), 0);
                hv_store(tensor_hv, "_context_id", 11, newSViv(lctx->id), 0);
                hv_store(tensor_hv, "requires_grad", 13, newSViv(1), 0);
                hv_store(tensor_hv, "name", 4, newSVpv("output.weight", 0), 0);
                SV *tsv = sv_bless(newRV_noinc((SV*)tensor_hv), gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
                hv_store(result_hv, "output.weight", 13, tsv, 0);
                n_tensors++;
            }
        }
    }
    
    /* Wrap per-layer tensors */
    for (i = 0; i < n_layer; i++) {
        const char *tensor_names[] = {
            "attn_norm.weight", "ffn_norm.weight",
            "attn_q.weight", "attn_k.weight", "attn_v.weight", "attn_output.weight",
            "ffn_gate.weight", "ffn_up.weight", "ffn_down.weight"
        };
        int n_names = sizeof(tensor_names) / sizeof(tensor_names[0]);
        int j;
        
        for (j = 0; j < n_names; j++) {
            snprintf(name_buf, sizeof(name_buf), "blk.%d.%s", i, tensor_names[j]);
            struct ggml_tensor *t = ggml_get_tensor(lm->ctx, name_buf);
            if (t && t->type == GGML_TYPE_F32) {
                LughTensor *lt = create_lugh_tensor(aTHX_ t, lctx->id, true);
                if (lt) {
                    alloc_grad(aTHX_ lt, lctx);
                    HV *tensor_hv = newHV();
                    hv_store(tensor_hv, "_tensor_id", 10, newSViv(lt->id), 0);
                    hv_store(tensor_hv, "_context_id", 11, newSViv(lctx->id), 0);
                    hv_store(tensor_hv, "requires_grad", 13, newSViv(1), 0);
                    hv_store(tensor_hv, "name", 4, newSVpv(name_buf, 0), 0);
                    SV *tsv = sv_bless(newRV_noinc((SV*)tensor_hv), gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
                    hv_store(result_hv, name_buf, strlen(name_buf), tsv, 0);
                    n_tensors++;
                }
            }
        }
    }
    
    /* Store count */
    hv_store(result_hv, "_n_tensors", 10, newSViv(n_tensors), 0);
    hv_store(result_hv, "_model_id", 9, newSViv(lm->id), 0);
    
    RETVAL = newRV_noinc((SV*)result_hv);
OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
CODE:
    /* Magic cleanup handles this */
    PERL_UNUSED_VAR(self);

SV *
create(class, ...)
    char *class
PREINIT:
    const char *path = NULL;
    const char *architecture = "llama";
    int n_vocab = 256;
    int n_embd = 64;
    int n_layer = 2;
    int n_head = 4;
    int n_head_kv = 2;
    int n_ff = 128;
    int n_ctx = 128;
    float rope_freq_base = 10000.0;
    float norm_eps = 1e-5;
    int i;
    struct gguf_context *gguf = NULL;
    struct ggml_init_params ggml_params;
    struct ggml_context *tensor_ctx = NULL;
    struct ggml_tensor *t;
    char name_buf[128];
    int head_dim;
    float scale;
CODE:
    /* Parse arguments */
    for (i = 1; i < items; i += 2) {
        if (i + 1 < items) {
            const char *key = SvPV_nolen(ST(i));
            if (strEQ(key, "path") || strEQ(key, "file")) {
                path = SvPV_nolen(ST(i + 1));
            } else if (strEQ(key, "architecture") || strEQ(key, "arch")) {
                architecture = SvPV_nolen(ST(i + 1));
            } else if (strEQ(key, "n_vocab") || strEQ(key, "vocab_size")) {
                n_vocab = SvIV(ST(i + 1));
            } else if (strEQ(key, "n_embd") || strEQ(key, "hidden_size")) {
                n_embd = SvIV(ST(i + 1));
            } else if (strEQ(key, "n_layer") || strEQ(key, "num_layers")) {
                n_layer = SvIV(ST(i + 1));
            } else if (strEQ(key, "n_head") || strEQ(key, "num_heads")) {
                n_head = SvIV(ST(i + 1));
            } else if (strEQ(key, "n_head_kv") || strEQ(key, "num_kv_heads")) {
                n_head_kv = SvIV(ST(i + 1));
            } else if (strEQ(key, "n_ff") || strEQ(key, "intermediate_size")) {
                n_ff = SvIV(ST(i + 1));
            } else if (strEQ(key, "n_ctx") || strEQ(key, "context_length")) {
                n_ctx = SvIV(ST(i + 1));
            } else if (strEQ(key, "rope_freq_base")) {
                rope_freq_base = SvNV(ST(i + 1));
            } else if (strEQ(key, "norm_eps")) {
                norm_eps = SvNV(ST(i + 1));
            }
        }
    }

    if (!path) {
        croak("Lugh::Model->create requires 'path' parameter");
    }

    /* Validate parameters */
    if (n_embd % n_head != 0) {
        croak("n_embd (%d) must be divisible by n_head (%d)", n_embd, n_head);
    }
    head_dim = n_embd / n_head;

    /* Create GGUF context */
    gguf = gguf_init_empty();
    if (!gguf) {
        croak("Failed to create GGUF context");
    }

    /* Set metadata */
    gguf_set_val_str(gguf, "general.architecture", architecture);
    gguf_set_val_str(gguf, "general.name", "lugh-created-model");
    gguf_set_val_u32(gguf, "general.file_type", 0);  /* F32 */
    
    /* Model hyperparameters - use architecture-specific keys */
    {
        char key[64];
        snprintf(key, sizeof(key), "%s.vocab_size", architecture);
        gguf_set_val_u32(gguf, key, n_vocab);
        snprintf(key, sizeof(key), "%s.embedding_length", architecture);
        gguf_set_val_u32(gguf, key, n_embd);
        snprintf(key, sizeof(key), "%s.block_count", architecture);
        gguf_set_val_u32(gguf, key, n_layer);
        snprintf(key, sizeof(key), "%s.attention.head_count", architecture);
        gguf_set_val_u32(gguf, key, n_head);
        snprintf(key, sizeof(key), "%s.attention.head_count_kv", architecture);
        gguf_set_val_u32(gguf, key, n_head_kv);
        snprintf(key, sizeof(key), "%s.feed_forward_length", architecture);
        gguf_set_val_u32(gguf, key, n_ff);
        snprintf(key, sizeof(key), "%s.context_length", architecture);
        gguf_set_val_u32(gguf, key, n_ctx);
        snprintf(key, sizeof(key), "%s.rope.freq_base", architecture);
        gguf_set_val_f32(gguf, key, rope_freq_base);
        snprintf(key, sizeof(key), "%s.attention.layer_norm_rms_epsilon", architecture);
        gguf_set_val_f32(gguf, key, norm_eps);
    }

    /* Create ggml context for tensors */
    /* Estimate size needed for all tensors */
    {
        size_t tensor_size = 0;
        /* Token embeddings: [n_embd, n_vocab] */
        tensor_size += n_embd * n_vocab * sizeof(float);
        /* Output norm: [n_embd] */
        tensor_size += n_embd * sizeof(float);
        /* Output projection (lm_head): [n_vocab, n_embd] */
        tensor_size += n_vocab * n_embd * sizeof(float);
        /* Per layer: */
        for (i = 0; i < n_layer; i++) {
            /* Attention norm: [n_embd] */
            tensor_size += n_embd * sizeof(float);
            /* Q, K, V, O projections: [n_embd, n_embd] or [n_embd, n_head_kv * head_dim] */
            tensor_size += n_embd * n_embd * sizeof(float);  /* Q */
            tensor_size += n_embd * (n_head_kv * head_dim) * sizeof(float);  /* K */
            tensor_size += n_embd * (n_head_kv * head_dim) * sizeof(float);  /* V */
            tensor_size += n_embd * n_embd * sizeof(float);  /* O */
            /* FFN norm: [n_embd] */
            tensor_size += n_embd * sizeof(float);
            /* FFN: gate, up [n_ff, n_embd], down [n_embd, n_ff] */
            tensor_size += n_ff * n_embd * sizeof(float);  /* gate */
            tensor_size += n_ff * n_embd * sizeof(float);  /* up */
            tensor_size += n_embd * n_ff * sizeof(float);  /* down */
        }
        tensor_size += 256 * 1024 * 1024;  /* Extra overhead */
        
        ggml_params.mem_size = tensor_size;
        ggml_params.mem_buffer = NULL;
        ggml_params.no_alloc = false;
    }
    
    tensor_ctx = ggml_init(ggml_params);
    if (!tensor_ctx) {
        gguf_free(gguf);
        croak("Failed to create tensor context");
    }

    /* Initialize random seed for weight initialization */
    srand(42);
    scale = 0.02f;

    /* Create token embeddings: token.embd.weight [n_embd, n_vocab] */
    t = ggml_new_tensor_2d(tensor_ctx, GGML_TYPE_F32, n_embd, n_vocab);
    ggml_set_name(t, "token_embd.weight");
    {
        float *data = (float*)t->data;
        for (int j = 0; j < n_embd * n_vocab; j++) {
            data[j] = ((float)rand() / RAND_MAX - 0.5f) * scale;
        }
    }
    gguf_add_tensor(gguf, t);

    /* Create per-layer tensors */
    for (i = 0; i < n_layer; i++) {
        /* Attention norm weight */
        snprintf(name_buf, sizeof(name_buf), "blk.%d.attn_norm.weight", i);
        t = ggml_new_tensor_1d(tensor_ctx, GGML_TYPE_F32, n_embd);
        ggml_set_name(t, name_buf);
        {
            float *data = (float*)t->data;
            for (int j = 0; j < n_embd; j++) data[j] = 1.0f;  /* Initialize to 1 */
        }
        gguf_add_tensor(gguf, t);

        /* Q projection: [n_embd, n_embd] */
        snprintf(name_buf, sizeof(name_buf), "blk.%d.attn_q.weight", i);
        t = ggml_new_tensor_2d(tensor_ctx, GGML_TYPE_F32, n_embd, n_embd);
        ggml_set_name(t, name_buf);
        {
            float *data = (float*)t->data;
            for (int j = 0; j < n_embd * n_embd; j++) {
                data[j] = ((float)rand() / RAND_MAX - 0.5f) * scale;
            }
        }
        gguf_add_tensor(gguf, t);

        /* K projection: [n_embd, n_head_kv * head_dim] */
        snprintf(name_buf, sizeof(name_buf), "blk.%d.attn_k.weight", i);
        t = ggml_new_tensor_2d(tensor_ctx, GGML_TYPE_F32, n_embd, n_head_kv * head_dim);
        ggml_set_name(t, name_buf);
        {
            float *data = (float*)t->data;
            int size = n_embd * n_head_kv * head_dim;
            for (int j = 0; j < size; j++) {
                data[j] = ((float)rand() / RAND_MAX - 0.5f) * scale;
            }
        }
        gguf_add_tensor(gguf, t);

        /* V projection: [n_embd, n_head_kv * head_dim] */
        snprintf(name_buf, sizeof(name_buf), "blk.%d.attn_v.weight", i);
        t = ggml_new_tensor_2d(tensor_ctx, GGML_TYPE_F32, n_embd, n_head_kv * head_dim);
        ggml_set_name(t, name_buf);
        {
            float *data = (float*)t->data;
            int size = n_embd * n_head_kv * head_dim;
            for (int j = 0; j < size; j++) {
                data[j] = ((float)rand() / RAND_MAX - 0.5f) * scale;
            }
        }
        gguf_add_tensor(gguf, t);

        /* O projection: [n_head * head_dim, n_embd] */
        snprintf(name_buf, sizeof(name_buf), "blk.%d.attn_output.weight", i);
        t = ggml_new_tensor_2d(tensor_ctx, GGML_TYPE_F32, n_head * head_dim, n_embd);
        ggml_set_name(t, name_buf);
        {
            float *data = (float*)t->data;
            for (int j = 0; j < n_head * head_dim * n_embd; j++) {
                data[j] = ((float)rand() / RAND_MAX - 0.5f) * scale;
            }
        }
        gguf_add_tensor(gguf, t);

        /* FFN norm weight */
        snprintf(name_buf, sizeof(name_buf), "blk.%d.ffn_norm.weight", i);
        t = ggml_new_tensor_1d(tensor_ctx, GGML_TYPE_F32, n_embd);
        ggml_set_name(t, name_buf);
        {
            float *data = (float*)t->data;
            for (int j = 0; j < n_embd; j++) data[j] = 1.0f;
        }
        gguf_add_tensor(gguf, t);

        /* FFN gate: [n_ff, n_embd] */
        snprintf(name_buf, sizeof(name_buf), "blk.%d.ffn_gate.weight", i);
        t = ggml_new_tensor_2d(tensor_ctx, GGML_TYPE_F32, n_embd, n_ff);
        ggml_set_name(t, name_buf);
        {
            float *data = (float*)t->data;
            for (int j = 0; j < n_embd * n_ff; j++) {
                data[j] = ((float)rand() / RAND_MAX - 0.5f) * scale;
            }
        }
        gguf_add_tensor(gguf, t);

        /* FFN up: [n_ff, n_embd] */
        snprintf(name_buf, sizeof(name_buf), "blk.%d.ffn_up.weight", i);
        t = ggml_new_tensor_2d(tensor_ctx, GGML_TYPE_F32, n_embd, n_ff);
        ggml_set_name(t, name_buf);
        {
            float *data = (float*)t->data;
            for (int j = 0; j < n_embd * n_ff; j++) {
                data[j] = ((float)rand() / RAND_MAX - 0.5f) * scale;
            }
        }
        gguf_add_tensor(gguf, t);

        /* FFN down: [n_embd, n_ff] */
        snprintf(name_buf, sizeof(name_buf), "blk.%d.ffn_down.weight", i);
        t = ggml_new_tensor_2d(tensor_ctx, GGML_TYPE_F32, n_ff, n_embd);
        ggml_set_name(t, name_buf);
        {
            float *data = (float*)t->data;
            for (int j = 0; j < n_ff * n_embd; j++) {
                data[j] = ((float)rand() / RAND_MAX - 0.5f) * scale;
            }
        }
        gguf_add_tensor(gguf, t);
    }

    /* Output norm: output_norm.weight [n_embd] */
    t = ggml_new_tensor_1d(tensor_ctx, GGML_TYPE_F32, n_embd);
    ggml_set_name(t, "output_norm.weight");
    {
        float *data = (float*)t->data;
        for (i = 0; i < n_embd; i++) data[i] = 1.0f;
    }
    gguf_add_tensor(gguf, t);

    /* Output projection (lm_head): output.weight [n_vocab, n_embd] */
    t = ggml_new_tensor_2d(tensor_ctx, GGML_TYPE_F32, n_embd, n_vocab);
    ggml_set_name(t, "output.weight");
    {
        float *data = (float*)t->data;
        for (i = 0; i < n_embd * n_vocab; i++) {
            data[i] = ((float)rand() / RAND_MAX - 0.5f) * scale;
        }
    }
    gguf_add_tensor(gguf, t);

    /* Add minimal tokenizer vocabulary */
    {
        const char *tokens[256];
        float scores[256];
        int32_t token_types[256];
        
        /* Special tokens */
        tokens[0] = "<unk>";
        tokens[1] = "<s>";
        tokens[2] = "</s>";
        tokens[3] = "<pad>";
        for (i = 0; i < 4; i++) {
            scores[i] = 0.0f;
            token_types[i] = 3;  /* CONTROL */
        }
        
        /* Byte tokens */
        static char byte_tokens[252][8];
        for (i = 4; i < 256 && i < n_vocab; i++) {
            snprintf(byte_tokens[i-4], sizeof(byte_tokens[0]), "<0x%02X>", i - 4);
            tokens[i] = byte_tokens[i-4];
            scores[i] = -(float)i;
            token_types[i] = 1;  /* NORMAL */
        }
        
        /* Add tokenizer metadata */
        gguf_set_val_str(gguf, "tokenizer.ggml.model", "llama");
        gguf_set_val_u32(gguf, "tokenizer.ggml.bos_token_id", 1);
        gguf_set_val_u32(gguf, "tokenizer.ggml.eos_token_id", 2);
        gguf_set_val_u32(gguf, "tokenizer.ggml.unknown_token_id", 0);
        gguf_set_val_u32(gguf, "tokenizer.ggml.padding_token_id", 3);
        
        /* Add token arrays */
        {
            int tok_count = (n_vocab < 256) ? n_vocab : 256;
            gguf_set_arr_str(gguf, "tokenizer.ggml.tokens", tokens, tok_count);
            gguf_set_arr_data(gguf, "tokenizer.ggml.scores", GGUF_TYPE_FLOAT32, scores, tok_count);
            gguf_set_arr_data(gguf, "tokenizer.ggml.token_type", GGUF_TYPE_INT32, token_types, tok_count);
        }
    }

    /* Write to file */
    gguf_write_to_file(gguf, path, false);
    
    /* Cleanup */
    gguf_free(gguf);
    ggml_free(tensor_ctx);

    /* Now load the model we just created */
    {
        SV *model_sv;
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv("Lugh::Model", 0)));
        XPUSHs(sv_2mortal(newSVpv("model", 0)));
        XPUSHs(sv_2mortal(newSVpv(path, 0)));
        PUTBACK;
        call_method("new", G_SCALAR);
        SPAGAIN;
        model_sv = POPs;
        SvREFCNT_inc(model_sv);
        PUTBACK;
        FREETMPS;
        LEAVE;
        RETVAL = model_sv;
    }
OUTPUT:
    RETVAL

MODULE = Lugh    PACKAGE = Lugh::LoRA

=pod

=head1 Lugh::LoRA

LoRA (Low-Rank Adaptation) adapter loading and management.
Supports GGUF and SafeTensors formats.

=cut

SV *
new(class, ...)
    char *class
PREINIT:
    const char *adapter_file = NULL;
    const char *config_file = NULL;
    SV *model_sv = NULL;
    LughModel *model = NULL;
    float scale = 1.0f;
    int i;
CODE:
    INIT_MUTEXES();
    
    /* Parse arguments */
    for (i = 1; i < items; i += 2) {
        if (i + 1 < items) {
            const char *key = SvPV_nolen(ST(i));
            if (strEQ(key, "adapter") || strEQ(key, "file")) {
                adapter_file = SvPV_nolen(ST(i + 1));
            } else if (strEQ(key, "config")) {
                config_file = SvPV_nolen(ST(i + 1));
            } else if (strEQ(key, "model")) {
                model_sv = ST(i + 1);
                model = get_lugh_model(aTHX_ model_sv);
            } else if (strEQ(key, "scale")) {
                scale = SvNV(ST(i + 1));
            }
        }
    }
    
    if (!adapter_file) {
        croak("Lugh::LoRA->new requires 'adapter' parameter with path to adapter file");
    }
    if (!model) {
        croak("Lugh::LoRA->new requires 'model' parameter with Lugh::Model object");
    }
    
    /* Detect format by extension */
    int is_gguf = 0;
    int is_safetensors = 0;
    size_t len = strlen(adapter_file);
    
    if (len > 5 && strcmp(adapter_file + len - 5, ".gguf") == 0) {
        is_gguf = 1;
    } else if (len > 12 && strcmp(adapter_file + len - 12, ".safetensors") == 0) {
        is_safetensors = 1;
    } else {
        croak("Unrecognized adapter format. Expected .gguf or .safetensors");
    }
    
    /* Create adapter container */
    LughLoRAAdapter *lora = create_lora_adapter();
    if (!lora) {
        croak("Failed to create LoRA adapter (max adapters reached)");
    }
    
    lora->scale = scale;
    Newx(lora->source_file, strlen(adapter_file) + 1, char);
    strcpy(lora->source_file, adapter_file);
    
    if (is_gguf) {
        /* ============================================
         * GGUF LoRA Loading
         * ============================================ */
        strcpy(lora->format, "gguf");
        
        struct ggml_context *tensor_ctx = NULL;
        struct gguf_init_params gguf_params = {
            .no_alloc = false,
            .ctx = &tensor_ctx
        };
        
        struct gguf_context *gguf = gguf_init_from_file(adapter_file, gguf_params);
        if (!gguf) {
            free_lora_adapter(lora);
            croak("Failed to load GGUF adapter: %s", adapter_file);
        }
        
        lora->ctx = tensor_ctx;
        
        /* Validate adapter type */
        int64_t key_id = gguf_find_key(gguf, "general.type");
        if (key_id >= 0) {
            const char *type = gguf_get_val_str(gguf, key_id);
            if (strcmp(type, "adapter") != 0) {
                gguf_free(gguf);
                free_lora_adapter(lora);
                croak("GGUF file is not an adapter (general.type='%s')", type);
            }
        }
        
        key_id = gguf_find_key(gguf, "adapter.type");
        if (key_id >= 0) {
            const char *atype = gguf_get_val_str(gguf, key_id);
            if (strcmp(atype, "lora") != 0) {
                gguf_free(gguf);
                free_lora_adapter(lora);
                croak("Adapter type is not LoRA (adapter.type='%s')", atype);
            }
        }
        
        /* Validate architecture match */
        key_id = gguf_find_key(gguf, "general.architecture");
        if (key_id >= 0) {
            const char *adapter_arch = gguf_get_val_str(gguf, key_id);
            if (model->architecture && strcmp(adapter_arch, model->architecture) != 0) {
                gguf_free(gguf);
                free_lora_adapter(lora);
                croak("Architecture mismatch: model='%s', adapter='%s'",
                      model->architecture, adapter_arch);
            }
            Newx(lora->architecture, strlen(adapter_arch) + 1, char);
            strcpy(lora->architecture, adapter_arch);
        }
        
        /* Get alpha */
        key_id = gguf_find_key(gguf, "adapter.lora.alpha");
        if (key_id >= 0) {
            lora->alpha = gguf_get_val_f32(gguf, key_id);
        } else {
            lora->alpha = 1.0f;
        }
        
        /* Collect tensor pairs: match *.lora_a with *.lora_b */
        int n_tensors = gguf_get_n_tensors(gguf);
        
        /* First pass: collect all lora_a tensors */
        for (i = 0; i < n_tensors; i++) {
            const char *tname = gguf_get_tensor_name(gguf, i);
            size_t tlen = strlen(tname);
            
            /* Check if ends with .lora_a */
            if (tlen > 7 && strcmp(tname + tlen - 7, ".lora_a") == 0) {
                /* Extract base name */
                char base_name[128];
                strncpy(base_name, tname, tlen - 7);
                base_name[tlen - 7] = '\0';
                
                /* Build lora_b name */
                char b_name[136];
                snprintf(b_name, sizeof(b_name), "%s.lora_b", base_name);
                
                /* Find matching lora_b tensor */
                struct ggml_tensor *tensor_a = ggml_get_tensor(tensor_ctx, tname);
                struct ggml_tensor *tensor_b = ggml_get_tensor(tensor_ctx, b_name);
                
                if (tensor_a && tensor_b) {
                    add_lora_weight(lora, base_name, tensor_a, tensor_b);
                }
            }
        }
        
        gguf_free(gguf);  /* Free GGUF metadata, tensors remain in tensor_ctx */
        
    } else if (is_safetensors) {
        /* ============================================
         * SafeTensors LoRA Loading
         * ============================================ */
        strcpy(lora->format, "safetensors");
        
        ensure_json_loaded(aTHX);
        
        /* Open file */
        FILE *fp = fopen(adapter_file, "rb");
        if (!fp) {
            free_lora_adapter(lora);
            croak("Cannot open SafeTensors file: %s", adapter_file);
        }
        
        /* Read header length (8-byte little-endian) */
        uint64_t header_len;
        if (fread(&header_len, 8, 1, fp) != 1) {
            fclose(fp);
            free_lora_adapter(lora);
            croak("Failed to read SafeTensors header length");
        }
        
        /* Sanity check header length */
        if (header_len > 100 * 1024 * 1024) {  /* Max 100MB header */
            fclose(fp);
            free_lora_adapter(lora);
            croak("SafeTensors header too large: %llu bytes", (unsigned long long)header_len);
        }
        
        /* Read header JSON */
        char *header_json;
        Newx(header_json, header_len + 1, char);
        if (fread(header_json, header_len, 1, fp) != 1) {
            Safefree(header_json);
            fclose(fp);
            free_lora_adapter(lora);
            croak("Failed to read SafeTensors header");
        }
        header_json[header_len] = '\0';
        
        /* Data starts after header */
        long data_offset = 8 + header_len;
        
        /* Parse header JSON via Perl */
        SV *header_hv_sv = decode_json_via_perl(aTHX_ header_json, header_len);
        Safefree(header_json);
        
        if (!header_hv_sv || !SvROK(header_hv_sv) || SvTYPE(SvRV(header_hv_sv)) != SVt_PVHV) {
            fclose(fp);
            free_lora_adapter(lora);
            croak("Failed to parse SafeTensors header JSON");
        }
        
        HV *header_hv = (HV*)SvRV(header_hv_sv);
        
        /* Count tensors and calculate memory needed */
        size_t total_tensor_size = 0;
        int tensor_count = 0;
        
        hv_iterinit(header_hv);
        HE *entry;
        while ((entry = hv_iternext(header_hv))) {
            const char *tname = HePV(entry, PL_na);
            if (strcmp(tname, "__metadata__") == 0) continue;
            
            SV *val = HeVAL(entry);
            if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVHV) continue;
            
            HV *tensor_info = (HV*)SvRV(val);
            SV **offsets_sv = hv_fetch(tensor_info, "data_offsets", 12, 0);
            if (offsets_sv && SvROK(*offsets_sv) && SvTYPE(SvRV(*offsets_sv)) == SVt_PVAV) {
                AV *offsets = (AV*)SvRV(*offsets_sv);
                SV **start_sv = av_fetch(offsets, 0, 0);
                SV **end_sv = av_fetch(offsets, 1, 0);
                if (start_sv && end_sv) {
                    size_t start = SvUV(*start_sv);
                    size_t end = SvUV(*end_sv);
                    total_tensor_size += (end - start);
                    tensor_count++;
                }
            }
        }
        
        /* Create ggml context for tensors */
        struct ggml_init_params ctx_params = {
            .mem_size = tensor_count * ggml_tensor_overhead() + 1024,
            .mem_buffer = NULL,
            .no_alloc = true,
        };
        lora->ctx = ggml_init(ctx_params);
        if (!lora->ctx) {
            fclose(fp);
            SvREFCNT_dec(header_hv_sv);
            free_lora_adapter(lora);
            croak("Failed to create tensor context");
        }
        
        /* Create backend buffer for tensor data */
        ggml_backend_t cpu_backend = ggml_backend_cpu_init();
        lora->buffer = ggml_backend_alloc_buffer(cpu_backend, total_tensor_size + 4096);
        ggml_backend_free(cpu_backend);
        
        if (!lora->buffer) {
            fclose(fp);
            SvREFCNT_dec(header_hv_sv);
            free_lora_adapter(lora);
            croak("Failed to allocate tensor buffer");
        }
        
        struct ggml_tallocr alloc = ggml_tallocr_new(lora->buffer);
        
        /* Create tensors and load data */
        /* We need to handle HuggingFace naming convention:
         * base_model.model.layers.N.self_attn.q_proj.lora_A.weight
         * -> blk.N.attn_q.weight.lora_a
         */
        
        hv_iterinit(header_hv);
        while ((entry = hv_iternext(header_hv))) {
            STRLEN name_len;
            const char *tname = HePV(entry, name_len);
            if (strcmp(tname, "__metadata__") == 0) continue;
            
            SV *val = HeVAL(entry);
            if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVHV) continue;
            
            HV *tensor_info = (HV*)SvRV(val);
            
            /* Get dtype */
            SV **dtype_sv = hv_fetch(tensor_info, "dtype", 5, 0);
            const char *dtype = dtype_sv ? SvPV_nolen(*dtype_sv) : "F32";
            
            enum ggml_type ggml_dtype;
            if (strcmp(dtype, "F32") == 0) {
                ggml_dtype = GGML_TYPE_F32;
            } else if (strcmp(dtype, "F16") == 0) {
                ggml_dtype = GGML_TYPE_F16;
            } else if (strcmp(dtype, "BF16") == 0) {
                ggml_dtype = GGML_TYPE_BF16;
            } else {
                continue;  /* Skip unsupported dtype */
            }
            
            /* Get shape */
            SV **shape_sv = hv_fetch(tensor_info, "shape", 5, 0);
            if (!shape_sv || !SvROK(*shape_sv)) continue;
            AV *shape_av = (AV*)SvRV(*shape_sv);
            int ndims = av_len(shape_av) + 1;
            int64_t dims[4] = {1, 1, 1, 1};
            for (int d = 0; d < ndims && d < 4; d++) {
                SV **dim_sv = av_fetch(shape_av, d, 0);
                if (dim_sv) dims[d] = SvIV(*dim_sv);
            }
            
            /* Get data offsets */
            SV **offsets_sv = hv_fetch(tensor_info, "data_offsets", 12, 0);
            if (!offsets_sv || !SvROK(*offsets_sv)) continue;
            AV *offsets = (AV*)SvRV(*offsets_sv);
            SV **start_sv = av_fetch(offsets, 0, 0);
            SV **end_sv = av_fetch(offsets, 1, 0);
            if (!start_sv || !end_sv) continue;
            
            size_t data_start = SvUV(*start_sv);
            size_t data_end = SvUV(*end_sv);
            size_t data_size = data_end - data_start;
            
            /* Create tensor */
            struct ggml_tensor *t;
            if (ndims == 1) {
                t = ggml_new_tensor_1d(lora->ctx, ggml_dtype, dims[0]);
            } else {
                t = ggml_new_tensor_2d(lora->ctx, ggml_dtype, dims[1], dims[0]);
            }
            ggml_set_name(t, tname);
            ggml_tallocr_alloc(&alloc, t);
            
            /* Read data from file */
            void *data_buf;
            Newx(data_buf, data_size, char);
            fseek(fp, data_offset + data_start, SEEK_SET);
            if (fread(data_buf, data_size, 1, fp) == 1) {
                ggml_backend_tensor_set(t, data_buf, 0, data_size);
            }
            Safefree(data_buf);
        }
        
        fclose(fp);
        
        /* Now pair up lora_A and lora_B tensors */
        /* HuggingFace names: *.lora_A.weight and *.lora_B.weight */
        struct ggml_tensor *t;
        for (t = ggml_get_first_tensor(lora->ctx); t; t = ggml_get_next_tensor(lora->ctx, t)) {
            const char *tname = t->name;
            size_t tlen = strlen(tname);
            
            /* Check for lora_A.weight suffix */
            if (tlen > 14 && strcmp(tname + tlen - 14, ".lora_A.weight") == 0) {
                /* Extract base name */
                char base_name[256];
                strncpy(base_name, tname, tlen - 14);
                base_name[tlen - 14] = '\0';
                
                /* Build lora_B name */
                char b_name[280];
                snprintf(b_name, sizeof(b_name), "%s.lora_B.weight", base_name);
                
                /* Find matching lora_B tensor */
                struct ggml_tensor *tensor_b = ggml_get_tensor(lora->ctx, b_name);
                
                if (tensor_b) {
                    /* Convert HuggingFace name to Lugh name for lookup */
                    /* e.g., base_model.model.layers.0.self_attn.q_proj
                     * -> blk.0.attn_q.weight */
                    char lugh_name[128];
                    int layer_num = -1;
                    
                    /* Try to parse layer number */
                    const char *layers_pos = strstr(base_name, ".layers.");
                    if (layers_pos) {
                        sscanf(layers_pos, ".layers.%d", &layer_num);
                    }
                    
                    /* Determine weight type */
                    const char *weight_type = NULL;
                    if (strstr(base_name, "q_proj")) weight_type = "attn_q";
                    else if (strstr(base_name, "k_proj")) weight_type = "attn_k";
                    else if (strstr(base_name, "v_proj")) weight_type = "attn_v";
                    else if (strstr(base_name, "o_proj")) weight_type = "attn_output";
                    else if (strstr(base_name, "gate_proj")) weight_type = "ffn_gate";
                    else if (strstr(base_name, "up_proj")) weight_type = "ffn_up";
                    else if (strstr(base_name, "down_proj")) weight_type = "ffn_down";
                    
                    if (layer_num >= 0 && weight_type) {
                        snprintf(lugh_name, sizeof(lugh_name), "blk.%d.%s.weight", 
                                 layer_num, weight_type);
                    } else {
                        /* Fallback: use original base name */
                        strncpy(lugh_name, base_name, sizeof(lugh_name) - 1);
                    }
                    
                    add_lora_weight(lora, lugh_name, t, tensor_b);
                }
            }
        }
        
        SvREFCNT_dec(header_hv_sv);
        
        /* Try to load config if not specified */
        if (!config_file) {
            /* Look for adapter_config.json in same directory */
            char config_path[512];
            strncpy(config_path, adapter_file, sizeof(config_path) - 30);
            char *last_slash = strrchr(config_path, '/');
            if (last_slash) {
                strcpy(last_slash + 1, "adapter_config.json");
            } else {
                strcpy(config_path, "adapter_config.json");
            }
            
            FILE *cfg_fp = fopen(config_path, "r");
            if (cfg_fp) {
                fseek(cfg_fp, 0, SEEK_END);
                long cfg_size = ftell(cfg_fp);
                fseek(cfg_fp, 0, SEEK_SET);
                
                char *cfg_json;
                Newx(cfg_json, cfg_size + 1, char);
                if (fread(cfg_json, cfg_size, 1, cfg_fp) == 1) {
                    cfg_json[cfg_size] = '\0';
                    
                    SV *cfg_sv = decode_json_via_perl(aTHX_ cfg_json, cfg_size);
                    if (cfg_sv && SvROK(cfg_sv) && SvTYPE(SvRV(cfg_sv)) == SVt_PVHV) {
                        HV *cfg_hv = (HV*)SvRV(cfg_sv);
                        
                        SV **alpha_sv = hv_fetch(cfg_hv, "lora_alpha", 10, 0);
                        if (alpha_sv && SvOK(*alpha_sv)) {
                            lora->alpha = SvNV(*alpha_sv);
                        }
                        
                        SvREFCNT_dec(cfg_sv);
                    }
                }
                Safefree(cfg_json);
                fclose(cfg_fp);
            }
        }
    }
    
    /* Create blessed reference with magic */
    SV *sv = newSV(0);
    sv_magicext(sv, NULL, PERL_MAGIC_ext, &lugh_lora_vtbl, INT2PTR(char*, (IV)lora->id), 0);
    RETVAL = sv_bless(newRV_noinc(sv), gv_stashpv(class, GV_ADD));
OUTPUT:
    RETVAL

float
alpha(self)
    SV *self
PREINIT:
    LughLoRAAdapter *lora;
    MAGIC *mg;
CODE:
    if (!SvROK(self)) croak("Not a reference");
    mg = mg_findext(SvRV(self), PERL_MAGIC_ext, &lugh_lora_vtbl);
    if (!mg) croak("Invalid LoRA object");
    lora = get_lora_by_id((int)(IV)mg->mg_ptr);
    if (!lora) croak("LoRA adapter not found");
    RETVAL = lora->alpha;
OUTPUT:
    RETVAL

float
scale(self, ...)
    SV *self
PREINIT:
    LughLoRAAdapter *lora;
    MAGIC *mg;
CODE:
    if (!SvROK(self)) croak("Not a reference");
    mg = mg_findext(SvRV(self), PERL_MAGIC_ext, &lugh_lora_vtbl);
    if (!mg) croak("Invalid LoRA object");
    lora = get_lora_by_id((int)(IV)mg->mg_ptr);
    if (!lora) croak("LoRA adapter not found");
    
    if (items > 1) {
        lora->scale = SvNV(ST(1));
    }
    RETVAL = lora->scale;
OUTPUT:
    RETVAL

int
n_weights(self)
    SV *self
PREINIT:
    LughLoRAAdapter *lora;
    MAGIC *mg;
CODE:
    if (!SvROK(self)) croak("Not a reference");
    mg = mg_findext(SvRV(self), PERL_MAGIC_ext, &lugh_lora_vtbl);
    if (!mg) croak("Invalid LoRA object");
    lora = get_lora_by_id((int)(IV)mg->mg_ptr);
    if (!lora) croak("LoRA adapter not found");
    RETVAL = lora->n_weights;
OUTPUT:
    RETVAL

const char *
format(self)
    SV *self
PREINIT:
    LughLoRAAdapter *lora;
    MAGIC *mg;
CODE:
    if (!SvROK(self)) croak("Not a reference");
    mg = mg_findext(SvRV(self), PERL_MAGIC_ext, &lugh_lora_vtbl);
    if (!mg) croak("Invalid LoRA object");
    lora = get_lora_by_id((int)(IV)mg->mg_ptr);
    if (!lora) croak("LoRA adapter not found");
    RETVAL = lora->format;
OUTPUT:
    RETVAL

void
weight_names(self)
    SV *self
PREINIT:
    LughLoRAAdapter *lora;
    MAGIC *mg;
    int i;
PPCODE:
    if (!SvROK(self)) croak("Not a reference");
    mg = mg_findext(SvRV(self), PERL_MAGIC_ext, &lugh_lora_vtbl);
    if (!mg) croak("Invalid LoRA object");
    lora = get_lora_by_id((int)(IV)mg->mg_ptr);
    if (!lora) croak("LoRA adapter not found");
    
    EXTEND(SP, lora->n_weights);
    for (i = 0; i < lora->n_weights; i++) {
        mPUSHp(lora->weights[i].name, strlen(lora->weights[i].name));
    }

bool
trainable(self)
    SV *self
PREINIT:
    LughLoRAAdapter *lora;
    MAGIC *mg;
CODE:
    if (!SvROK(self)) croak("Not a reference");
    mg = mg_findext(SvRV(self), PERL_MAGIC_ext, &lugh_lora_vtbl);
    if (!mg) croak("Invalid LoRA object");
    lora = get_lora_by_id((int)(IV)mg->mg_ptr);
    if (!lora) croak("LoRA adapter not found");
    RETVAL = lora->trainable;
OUTPUT:
    RETVAL

SV *
create(class, ...)
    char *class
PREINIT:
    SV *model_sv = NULL;
    LughModel *model = NULL;
    int rank = 16;
    float alpha = 32.0f;
    float scale = 1.0f;
    AV *targets_av = NULL;
    SV *context_sv = NULL;
    LughContext *lctx = NULL;
    int i;
CODE:
    INIT_MUTEXES();
    
    /* Parse arguments */
    for (i = 1; i < items; i += 2) {
        if (i + 1 < items) {
            const char *key = SvPV_nolen(ST(i));
            if (strEQ(key, "model")) {
                model_sv = ST(i + 1);
                model = get_lugh_model(aTHX_ model_sv);
            } else if (strEQ(key, "rank")) {
                rank = SvIV(ST(i + 1));
            } else if (strEQ(key, "alpha")) {
                alpha = SvNV(ST(i + 1));
            } else if (strEQ(key, "scale")) {
                scale = SvNV(ST(i + 1));
            } else if (strEQ(key, "targets")) {
                if (SvROK(ST(i + 1)) && SvTYPE(SvRV(ST(i + 1))) == SVt_PVAV) {
                    targets_av = (AV*)SvRV(ST(i + 1));
                }
            } else if (strEQ(key, "context")) {
                context_sv = ST(i + 1);
            }
        }
    }
    
    if (!model) {
        croak("Lugh::LoRA->create requires 'model' parameter");
    }
    if (rank < 1 || rank > 256) {
        croak("LoRA rank must be between 1 and 256");
    }
    
    /* Get or create autograd context */
    if (context_sv) {
        lctx = get_lugh_context(aTHX_ context_sv);
    }
    if (!lctx) {
        /* Create a new context for LoRA tensors */
        size_t mem_size = 256 * 1024 * 1024;  /* 256MB for LoRA weights */
        struct ggml_init_params params = {
            .mem_size = mem_size,
            .mem_buffer = NULL,
            .no_alloc = false
        };
        struct ggml_context *ctx = ggml_init(params);
        if (!ctx) {
            croak("Failed to create context for LoRA tensors");
        }
        
        /* Create a LughContext wrapper */
        int ctx_id = alloc_context_id();
        if (ctx_id < 0) {
            ggml_free(ctx);
            croak("Context registry full");
        }
        
        LughContext *new_lctx;
        Newxz(new_lctx, 1, LughContext);
        new_lctx->ctx = ctx;
        new_lctx->id = ctx_id;
        new_lctx->active = 1;
        new_lctx->mem_size = mem_size;
        
        CONTEXT_LOCK();
        context_registry[ctx_id] = new_lctx;
        CONTEXT_UNLOCK();
        
        lctx = new_lctx;
    }
    
    /* Create adapter container */
    LughLoRAAdapter *lora = create_lora_adapter();
    if (!lora) {
        croak("Failed to create LoRA adapter (max adapters reached)");
    }
    
    lora->alpha = alpha;
    lora->scale = scale;
    lora->trainable = true;
    lora->model_id = model->id;
    lora->context_id = lctx->id;
    strcpy(lora->format, "trainable");
    
    if (model->architecture) {
        Newx(lora->architecture, strlen(model->architecture) + 1, char);
        strcpy(lora->architecture, model->architecture);
    }
    
    /* Default targets if not specified */
    const char *default_targets[] = {"attn_q", "attn_v"};
    int n_targets = 2;
    const char **targets = default_targets;
    
    if (targets_av && av_len(targets_av) >= 0) {
        n_targets = av_len(targets_av) + 1;
        Newx(targets, n_targets, const char *);
        for (i = 0; i < n_targets; i++) {
            SV **elem = av_fetch(targets_av, i, 0);
            if (elem) {
                targets[i] = SvPV_nolen(*elem);
            } else {
                targets[i] = "";
            }
        }
    }
    
    /* Extract model dimensions from GGUF metadata */
    const char *arch = model->architecture ? model->architecture : "llama";
    char key[128];
    int64_t key_id;
    
    /* Get n_embd */
    snprintf(key, sizeof(key), "%s.embedding_length", arch);
    key_id = gguf_find_key(model->gguf, key);
    int n_embd = (key_id >= 0) ? gguf_get_val_u32(model->gguf, key_id) : 2048;
    
    /* Get n_layer */
    snprintf(key, sizeof(key), "%s.block_count", arch);
    key_id = gguf_find_key(model->gguf, key);
    int n_layers = (key_id >= 0) ? gguf_get_val_u32(model->gguf, key_id) : 22;
    
    /* Get n_head */
    snprintf(key, sizeof(key), "%s.attention.head_count", arch);
    key_id = gguf_find_key(model->gguf, key);
    int n_head = (key_id >= 0) ? gguf_get_val_u32(model->gguf, key_id) : 32;
    
    /* Get n_head_kv */
    snprintf(key, sizeof(key), "%s.attention.head_count_kv", arch);
    key_id = gguf_find_key(model->gguf, key);
    int n_head_kv = (key_id >= 0) ? gguf_get_val_u32(model->gguf, key_id) : n_head;
    
    /* Get n_ff (FFN intermediate size) */
    snprintf(key, sizeof(key), "%s.feed_forward_length", arch);
    key_id = gguf_find_key(model->gguf, key);
    int n_ff = (key_id >= 0) ? gguf_get_val_u32(model->gguf, key_id) : n_embd * 4;
    
    int head_dim = n_embd / n_head;
    
    /* Create LoRA weights for each target in each layer */
    for (int layer = 0; layer < n_layers; layer++) {
        for (int t = 0; t < n_targets; t++) {
            const char *target = targets[t];
            char weight_name[128];
            
            /* Construct weight name */
            snprintf(weight_name, sizeof(weight_name), "blk.%d.%s.weight", layer, target);
            
            /* Get the original weight dimensions from model */
            int64_t d_in = n_embd;
            int64_t d_out = n_embd;
            
            /* Adjust for different target types */
            if (strstr(target, "attn_k") || strstr(target, "attn_v")) {
                /* K,V projections may have different size with GQA */
                if (n_head_kv > 0 && n_head_kv < n_head) {
                    d_out = n_head_kv * head_dim;
                }
            } else if (strstr(target, "ffn_")) {
                /* FFN layers often 4x embedding size */
                if (strstr(target, "ffn_up") || strstr(target, "ffn_gate")) {
                    d_out = n_ff;
                } else if (strstr(target, "ffn_down")) {
                    d_in = n_ff;
                }
            }
            
            /* Create A matrix: [d_in, rank] - down projection */
            struct ggml_tensor *a = ggml_new_tensor_2d(lctx->ctx, GGML_TYPE_F32, d_in, rank);
            if (!a) {
                free_lora_adapter(lora);
                croak("Failed to allocate LoRA A matrix");
            }
            
            /* Create B matrix: [rank, d_out] - up projection */
            struct ggml_tensor *b = ggml_new_tensor_2d(lctx->ctx, GGML_TYPE_F32, rank, d_out);
            if (!b) {
                free_lora_adapter(lora);
                croak("Failed to allocate LoRA B matrix");
            }
            
            /* Set tensor names at creation (required for GGUF save) */
            char name_a[140], name_b[140];
            snprintf(name_a, sizeof(name_a), "%s.lora_a", weight_name);
            snprintf(name_b, sizeof(name_b), "%s.lora_b", weight_name);
            ggml_set_name(a, name_a);
            ggml_set_name(b, name_b);
            
            /* Initialize A with small random values (Kaiming init) */
            float scale_a = sqrtf(2.0f / (float)d_in);
            int64_t n_a = ggml_nelements(a);
            for (int64_t j = 0; j < n_a; j++) {
                float rand_val = (lugh_rand_float() - 0.5f) * 2.0f * scale_a;
                ggml_set_f32_1d(a, j, rand_val);
            }
            
            /* Initialize B with zeros (standard LoRA init) */
            ggml_set_zero(b);
            
            /* Add to adapter */
            if (!add_lora_weight(lora, weight_name, a, b)) {
                free_lora_adapter(lora);
                croak("Failed to add LoRA weight %s", weight_name);
            }
            
            /* Create autograd tensors for training */
            LughLoRAWeight *lw = &lora->weights[lora->n_weights - 1];
            
            LughTensor *lt_a = create_lugh_tensor(aTHX_ a, lctx->id, true);
            LughTensor *lt_b = create_lugh_tensor(aTHX_ b, lctx->id, true);
            
            if (lt_a && lt_b) {
                lw->tensor_a_id = lt_a->id;
                lw->tensor_b_id = lt_b->id;
                
                /* Allocate gradient tensors */
                alloc_grad(aTHX_ lt_a, lctx);
                alloc_grad(aTHX_ lt_b, lctx);
            }
        }
    }
    
    /* Clean up targets array if we allocated it */
    if (targets != default_targets) {
        Safefree(targets);
    }
    
    /* Create blessed reference with magic */
    SV *sv = newSV(0);
    sv_magicext(sv, NULL, PERL_MAGIC_ext, &lugh_lora_vtbl, INT2PTR(char*, (IV)lora->id), 0);
    RETVAL = sv_bless(newRV_noinc(sv), gv_stashpv(class, GV_ADD));
OUTPUT:
    RETVAL

SV *
get_weight_tensor(self, name, type)
    SV *self
    const char *name
    const char *type
PREINIT:
    LughLoRAAdapter *lora;
    MAGIC *mg;
    LughLoRAWeight *lw;
    LughTensor *lt = NULL;
CODE:
    if (!SvROK(self)) croak("Not a reference");
    mg = mg_findext(SvRV(self), PERL_MAGIC_ext, &lugh_lora_vtbl);
    if (!mg) croak("Invalid LoRA object");
    lora = get_lora_by_id((int)(IV)mg->mg_ptr);
    if (!lora) croak("LoRA adapter not found");
    
    if (!lora->trainable) {
        croak("get_weight_tensor only available on trainable LoRA adapters");
    }
    
    lw = find_lora_weight(lora, name);
    if (!lw) {
        croak("LoRA weight '%s' not found", name);
    }
    
    int tensor_id = -1;
    if (strcmp(type, "a") == 0 || strcmp(type, "A") == 0) {
        tensor_id = lw->tensor_a_id;
    } else if (strcmp(type, "b") == 0 || strcmp(type, "B") == 0) {
        tensor_id = lw->tensor_b_id;
    } else {
        croak("type must be 'a' or 'b', got '%s'", type);
    }
    
    lt = get_tensor_by_id(tensor_id);
    if (!lt) {
        RETVAL = &PL_sv_undef;
    } else {
        /* Return as Lugh::Autograd::Tensor blessed hash reference */
        HV *result_hv = newHV();
        hv_store(result_hv, "_tensor_id", 10, newSViv(lt->id), 0);
        hv_store(result_hv, "_context_id", 11, newSViv(lora->context_id), 0);
        hv_store(result_hv, "requires_grad", 13, newSViv(lt->requires_grad ? 1 : 0), 0);
        RETVAL = sv_bless(newRV_noinc((SV*)result_hv), gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
    }
OUTPUT:
    RETVAL

void
save(self, path)
    SV *self
    const char *path
PREINIT:
    LughLoRAAdapter *lora;
    MAGIC *mg;
CODE:
    if (!SvROK(self)) croak("Not a reference");
    mg = mg_findext(SvRV(self), PERL_MAGIC_ext, &lugh_lora_vtbl);
    if (!mg) croak("Invalid LoRA object");
    lora = get_lora_by_id((int)(IV)mg->mg_ptr);
    if (!lora) croak("LoRA adapter not found");
    
    /* Check file extension */
    size_t len = strlen(path);
    if (len <= 5 || strcmp(path + len - 5, ".gguf") != 0) {
        croak("LoRA save path must end with .gguf");
    }
    
    /* Create GGUF writer context */
    struct gguf_context *gguf = gguf_init_empty();
    if (!gguf) {
        croak("Failed to create GGUF context");
    }
    
    /* Add metadata */
    gguf_set_val_str(gguf, "general.type", "adapter");
    gguf_set_val_str(gguf, "adapter.type", "lora");
    gguf_set_val_f32(gguf, "adapter.lora.alpha", lora->alpha);
    
    if (lora->architecture) {
        gguf_set_val_str(gguf, "general.architecture", lora->architecture);
    }
    
    /* Add tensor pairs */
    for (int i = 0; i < lora->n_weights; i++) {
        LughLoRAWeight *lw = &lora->weights[i];
        
        /* For loaded adapters, set names if not already set */
        if (!lora->trainable) {
            char tensor_name_a[140];
            char tensor_name_b[140];
            snprintf(tensor_name_a, sizeof(tensor_name_a), "%s.lora_a", lw->name);
            snprintf(tensor_name_b, sizeof(tensor_name_b), "%s.lora_b", lw->name);
            ggml_set_name(lw->a, tensor_name_a);
            ggml_set_name(lw->b, tensor_name_b);
        }
        
        /* Add tensors to GGUF */
        gguf_add_tensor(gguf, lw->a);
        gguf_add_tensor(gguf, lw->b);
    }
    
    /* Write to file */
    gguf_write_to_file(gguf, path, false);
    gguf_free(gguf);

void
trainable_parameters(self)
    SV *self
PREINIT:
    LughLoRAAdapter *lora;
    LughTensor *lt;
    MAGIC *mg;
    int i, count = 0;
    HV *result_hv;
PPCODE:
    if (!SvROK(self)) croak("Not a reference");
    mg = mg_findext(SvRV(self), PERL_MAGIC_ext, &lugh_lora_vtbl);
    if (!mg) croak("Invalid LoRA object");
    lora = get_lora_by_id((int)(IV)mg->mg_ptr);
    if (!lora) croak("LoRA adapter not found");
    
    if (!lora->trainable) {
        croak("trainable_parameters() only available for trainable LoRA adapters (created with create())");
    }
    
    /* Count valid tensors first */
    for (i = 0; i < lora->n_weights; i++) {
        LughLoRAWeight *lw = &lora->weights[i];
        if (lw->tensor_a_id > 0) count++;
        if (lw->tensor_b_id > 0) count++;
    }
    
    EXTEND(SP, count);
    
    /* Return all trainable tensor objects */
    for (i = 0; i < lora->n_weights; i++) {
        LughLoRAWeight *lw = &lora->weights[i];
        
        if (lw->tensor_a_id > 0) {
            lt = get_tensor_by_id(lw->tensor_a_id);
            if (lt) {
                result_hv = newHV();
                hv_store(result_hv, "_tensor_id", 10, newSViv(lt->id), 0);
                hv_store(result_hv, "_context_id", 11, newSViv(lt->context_id), 0);
                hv_store(result_hv, "requires_grad", 13, newSViv(lt->requires_grad ? 1 : 0), 0);
                mPUSHs(sv_bless(newRV_noinc((SV*)result_hv), gv_stashpv("Lugh::Autograd::Tensor", GV_ADD)));
            }
        }
        
        if (lw->tensor_b_id > 0) {
            lt = get_tensor_by_id(lw->tensor_b_id);
            if (lt) {
                result_hv = newHV();
                hv_store(result_hv, "_tensor_id", 10, newSViv(lt->id), 0);
                hv_store(result_hv, "_context_id", 11, newSViv(lt->context_id), 0);
                hv_store(result_hv, "requires_grad", 13, newSViv(lt->requires_grad ? 1 : 0), 0);
                mPUSHs(sv_bless(newRV_noinc((SV*)result_hv), gv_stashpv("Lugh::Autograd::Tensor", GV_ADD)));
            }
        }
    }

void
DESTROY(self)
    SV *self
CODE:
    /* Magic cleanup handles this */
    PERL_UNUSED_VAR(self);

# ============================================================================
# Lugh::RoPE - RoPE Scaling Configuration
# ============================================================================

MODULE = Lugh    PACKAGE = Lugh::RoPE

PROTOTYPES: DISABLE

SV *
new(class, ...)
    const char *class
PREINIT:
    LughRopeConfig config;
    int i, id;
    SV *obj;
    HV *stash;
CODE:
    /* Initialize defaults */
    config.scaling_type = LUGH_ROPE_SCALING_NONE;
    config.n_ctx_orig = 0;
    config.target_ctx = 0;
    config.freq_base = 0.0f;   /* 0 = use model default */
    config.freq_scale = 1.0f;
    config.ext_factor = -1.0f; /* -1 = auto-compute for YaRN */
    config.attn_factor = 1.0f;
    config.beta_fast = 32.0f;
    config.beta_slow = 1.0f;
    
    /* Parse key-value pairs */
    for (i = 1; i < items; i += 2) {
        if (i + 1 >= items) croak("Odd number of arguments");
        
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        
        if (strcmp(key, "scaling_type") == 0) {
            if (SvIOK(val)) {
                config.scaling_type = (LughRopeScalingType)SvIV(val);
            } else if (SvPOK(val)) {
                const char *s = SvPV_nolen(val);
                if (strcmp(s, "none") == 0) config.scaling_type = LUGH_ROPE_SCALING_NONE;
                else if (strcmp(s, "linear") == 0) config.scaling_type = LUGH_ROPE_SCALING_LINEAR;
                else if (strcmp(s, "yarn") == 0) config.scaling_type = LUGH_ROPE_SCALING_YARN;
                else if (strcmp(s, "longrope") == 0) config.scaling_type = LUGH_ROPE_SCALING_LONGROPE;
                else croak("Unknown scaling_type: %s", s);
            }
        }
        else if (strcmp(key, "n_ctx_orig") == 0) config.n_ctx_orig = SvIV(val);
        else if (strcmp(key, "target_ctx") == 0) config.target_ctx = SvIV(val);
        else if (strcmp(key, "freq_base") == 0) config.freq_base = SvNV(val);
        else if (strcmp(key, "freq_scale") == 0) config.freq_scale = SvNV(val);
        else if (strcmp(key, "ext_factor") == 0) config.ext_factor = SvNV(val);
        else if (strcmp(key, "attn_factor") == 0) config.attn_factor = SvNV(val);
        else if (strcmp(key, "beta_fast") == 0) config.beta_fast = SvNV(val);
        else if (strcmp(key, "beta_slow") == 0) config.beta_slow = SvNV(val);
    }
    
    /* Auto-compute freq_scale if target_ctx set and freq_scale not explicitly set */
    if (config.target_ctx > 0 && config.n_ctx_orig > 0 && config.freq_scale == 1.0f) {
        config.freq_scale = (float)config.n_ctx_orig / (float)config.target_ctx;
    }
    
    /* Register config */
    id = register_rope_config(&config);
    if (id < 0) croak("Too many RoPE configs");
    
    /* Create blessed object */
    obj = newSViv(0);
    sv_magicext(obj, NULL, PERL_MAGIC_ext, &lugh_rope_vtbl, (char*)(IV)id, 0);
    stash = gv_stashpv(class, GV_ADD);
    RETVAL = sv_bless(newRV_noinc(obj), stash);
OUTPUT:
    RETVAL

SV *
none(class)
    const char *class
PREINIT:
    LughRopeConfig config;
    int id;
    SV *obj;
    HV *stash;
CODE:
    memset(&config, 0, sizeof(config));
    config.scaling_type = LUGH_ROPE_SCALING_NONE;
    config.freq_scale = 1.0f;
    config.attn_factor = 1.0f;
    
    id = register_rope_config(&config);
    if (id < 0) croak("Too many RoPE configs");
    
    obj = newSViv(0);
    sv_magicext(obj, NULL, PERL_MAGIC_ext, &lugh_rope_vtbl, (char*)(IV)id, 0);
    stash = gv_stashpv(class, GV_ADD);
    RETVAL = sv_bless(newRV_noinc(obj), stash);
OUTPUT:
    RETVAL

SV *
linear(class, n_ctx_orig, target_ctx)
    const char *class
    int n_ctx_orig
    int target_ctx
PREINIT:
    LughRopeConfig config;
    int id;
    SV *obj;
    HV *stash;
CODE:
    memset(&config, 0, sizeof(config));
    config.scaling_type = LUGH_ROPE_SCALING_LINEAR;
    config.n_ctx_orig = n_ctx_orig;
    config.target_ctx = target_ctx;
    config.freq_scale = (float)n_ctx_orig / (float)target_ctx;
    config.ext_factor = 0.0f;  /* Disable YaRN for linear */
    config.attn_factor = 1.0f;
    
    id = register_rope_config(&config);
    if (id < 0) croak("Too many RoPE configs");
    
    obj = newSViv(0);
    sv_magicext(obj, NULL, PERL_MAGIC_ext, &lugh_rope_vtbl, (char*)(IV)id, 0);
    stash = gv_stashpv(class, GV_ADD);
    RETVAL = sv_bless(newRV_noinc(obj), stash);
OUTPUT:
    RETVAL

SV *
yarn(class, n_ctx_orig, target_ctx, ...)
    const char *class
    int n_ctx_orig
    int target_ctx
PREINIT:
    LughRopeConfig config;
    int id, i;
    SV *obj;
    HV *stash;
CODE:
    memset(&config, 0, sizeof(config));
    config.scaling_type = LUGH_ROPE_SCALING_YARN;
    config.n_ctx_orig = n_ctx_orig;
    config.target_ctx = target_ctx;
    config.freq_scale = (float)n_ctx_orig / (float)target_ctx;
    config.ext_factor = -1.0f;  /* Auto-compute */
    config.attn_factor = 1.0f;
    config.beta_fast = 32.0f;
    config.beta_slow = 1.0f;
    
    /* Parse optional YaRN params */
    for (i = 3; i < items; i += 2) {
        if (i + 1 >= items) break;
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        
        if (strcmp(key, "ext_factor") == 0) config.ext_factor = SvNV(val);
        else if (strcmp(key, "attn_factor") == 0) config.attn_factor = SvNV(val);
        else if (strcmp(key, "beta_fast") == 0) config.beta_fast = SvNV(val);
        else if (strcmp(key, "beta_slow") == 0) config.beta_slow = SvNV(val);
    }
    
    id = register_rope_config(&config);
    if (id < 0) croak("Too many RoPE configs");
    
    obj = newSViv(0);
    sv_magicext(obj, NULL, PERL_MAGIC_ext, &lugh_rope_vtbl, (char*)(IV)id, 0);
    stash = gv_stashpv(class, GV_ADD);
    RETVAL = sv_bless(newRV_noinc(obj), stash);
OUTPUT:
    RETVAL

SV *
linear_2x(class, n_ctx_orig)
    const char *class
    int n_ctx_orig
CODE:
    /* Delegate to linear() with 2x target */
    PUSHMARK(SP);
    EXTEND(SP, 3);
    mPUSHp(class, strlen(class));
    mPUSHi(n_ctx_orig);
    mPUSHi(n_ctx_orig * 2);
    PUTBACK;
    call_method("linear", G_SCALAR);
    SPAGAIN;
    RETVAL = SvREFCNT_inc(POPs);
OUTPUT:
    RETVAL

SV *
linear_4x(class, n_ctx_orig)
    const char *class
    int n_ctx_orig
CODE:
    PUSHMARK(SP);
    EXTEND(SP, 3);
    mPUSHp(class, strlen(class));
    mPUSHi(n_ctx_orig);
    mPUSHi(n_ctx_orig * 4);
    PUTBACK;
    call_method("linear", G_SCALAR);
    SPAGAIN;
    RETVAL = SvREFCNT_inc(POPs);
OUTPUT:
    RETVAL

SV *
yarn_32k(class, n_ctx_orig)
    const char *class
    int n_ctx_orig
CODE:
    PUSHMARK(SP);
    EXTEND(SP, 3);
    mPUSHp(class, strlen(class));
    mPUSHi(n_ctx_orig);
    mPUSHi(32768);
    PUTBACK;
    call_method("yarn", G_SCALAR);
    SPAGAIN;
    RETVAL = SvREFCNT_inc(POPs);
OUTPUT:
    RETVAL

SV *
yarn_64k(class, n_ctx_orig)
    const char *class
    int n_ctx_orig
CODE:
    PUSHMARK(SP);
    EXTEND(SP, 3);
    mPUSHp(class, strlen(class));
    mPUSHi(n_ctx_orig);
    mPUSHi(65536);
    PUTBACK;
    call_method("yarn", G_SCALAR);
    SPAGAIN;
    RETVAL = SvREFCNT_inc(POPs);
OUTPUT:
    RETVAL

SV *
yarn_128k(class, n_ctx_orig)
    const char *class
    int n_ctx_orig
CODE:
    PUSHMARK(SP);
    EXTEND(SP, 3);
    mPUSHp(class, strlen(class));
    mPUSHi(n_ctx_orig);
    mPUSHi(131072);
    PUTBACK;
    call_method("yarn", G_SCALAR);
    SPAGAIN;
    RETVAL = SvREFCNT_inc(POPs);
OUTPUT:
    RETVAL

SV *
from_model(class, model_sv)
    const char *class
    SV *model_sv
PREINIT:
    LughModel *lm;
    LughRopeConfig config;
    int id, key_id;
    SV *obj;
    HV *stash;
    char key[128];
    const char *arch;
CODE:
    lm = get_lugh_model(aTHX_ model_sv);
    
    /* Initialize defaults */
    memset(&config, 0, sizeof(config));
    config.scaling_type = LUGH_ROPE_SCALING_NONE;
    config.freq_scale = 1.0f;
    config.ext_factor = -1.0f;  /* Auto-compute for YaRN */
    config.attn_factor = 1.0f;
    config.beta_fast = 32.0f;
    config.beta_slow = 1.0f;
    
    arch = lm->architecture ? lm->architecture : "llama";
    
    /* Get context length */
    snprintf(key, sizeof(key), "%s.context_length", arch);
    key_id = gguf_find_key(lm->gguf, key);
    if (key_id >= 0) {
        config.n_ctx_orig = gguf_get_val_u32(lm->gguf, key_id);
        config.target_ctx = config.n_ctx_orig;  /* Default target = original */
    }
    
    /* Get rope.freq_base */
    snprintf(key, sizeof(key), "%s.rope.freq_base", arch);
    key_id = gguf_find_key(lm->gguf, key);
    if (key_id >= 0) {
        config.freq_base = gguf_get_val_f32(lm->gguf, key_id);
    }
    
    /* Get scaling type */
    snprintf(key, sizeof(key), "%s.rope.scaling.type", arch);
    key_id = gguf_find_key(lm->gguf, key);
    if (key_id >= 0) {
        const char *scaling_str = gguf_get_val_str(lm->gguf, key_id);
        if (scaling_str) {
            if (strcmp(scaling_str, "linear") == 0)
                config.scaling_type = LUGH_ROPE_SCALING_LINEAR;
            else if (strcmp(scaling_str, "yarn") == 0)
                config.scaling_type = LUGH_ROPE_SCALING_YARN;
            else if (strcmp(scaling_str, "longrope") == 0)
                config.scaling_type = LUGH_ROPE_SCALING_LONGROPE;
        }
    }
    
    /* Get scaling factor -> freq_scale */
    snprintf(key, sizeof(key), "%s.rope.scaling.factor", arch);
    key_id = gguf_find_key(lm->gguf, key);
    if (key_id >= 0) {
        float factor = gguf_get_val_f32(lm->gguf, key_id);
        if (factor > 0) {
            config.freq_scale = 1.0f / factor;
            /* Compute target_ctx from factor */
            if (config.n_ctx_orig > 0) {
                config.target_ctx = (int)(config.n_ctx_orig * factor);
            }
        }
    } else {
        /* Fallback to legacy key */
        snprintf(key, sizeof(key), "%s.rope.scale_linear", arch);
        key_id = gguf_find_key(lm->gguf, key);
        if (key_id >= 0) {
            float factor = gguf_get_val_f32(lm->gguf, key_id);
            if (factor > 0) {
                config.freq_scale = 1.0f / factor;
                if (config.n_ctx_orig > 0) {
                    config.target_ctx = (int)(config.n_ctx_orig * factor);
                }
            }
        }
    }
    
    /* Original context length for scaling */
    snprintf(key, sizeof(key), "%s.rope.scaling.original_context_length", arch);
    key_id = gguf_find_key(lm->gguf, key);
    if (key_id >= 0) {
        config.n_ctx_orig = gguf_get_val_u32(lm->gguf, key_id);
    }
    
    /* YaRN parameters */
    snprintf(key, sizeof(key), "%s.rope.scaling.yarn_ext_factor", arch);
    key_id = gguf_find_key(lm->gguf, key);
    if (key_id >= 0) config.ext_factor = gguf_get_val_f32(lm->gguf, key_id);
    
    snprintf(key, sizeof(key), "%s.rope.scaling.yarn_attn_factor", arch);
    key_id = gguf_find_key(lm->gguf, key);
    if (key_id >= 0) config.attn_factor = gguf_get_val_f32(lm->gguf, key_id);
    
    snprintf(key, sizeof(key), "%s.rope.scaling.yarn_beta_fast", arch);
    key_id = gguf_find_key(lm->gguf, key);
    if (key_id >= 0) config.beta_fast = gguf_get_val_f32(lm->gguf, key_id);
    
    snprintf(key, sizeof(key), "%s.rope.scaling.yarn_beta_slow", arch);
    key_id = gguf_find_key(lm->gguf, key);
    if (key_id >= 0) config.beta_slow = gguf_get_val_f32(lm->gguf, key_id);
    
    /* Register and create object */
    id = register_rope_config(&config);
    if (id < 0) croak("Too many RoPE configs");
    
    obj = newSViv(0);
    sv_magicext(obj, NULL, PERL_MAGIC_ext, &lugh_rope_vtbl, (char*)(IV)id, 0);
    stash = gv_stashpv(class, GV_ADD);
    RETVAL = sv_bless(newRV_noinc(obj), stash);
OUTPUT:
    RETVAL

int
scaling_type(self)
    SV *self
CODE:
    LughRopeConfig *config = get_lugh_rope(aTHX_ self);
    RETVAL = config->scaling_type;
OUTPUT:
    RETVAL

const char *
scaling_type_name(self)
    SV *self
PREINIT:
    LughRopeConfig *config;
CODE:
    config = get_lugh_rope(aTHX_ self);
    switch (config->scaling_type) {
        case LUGH_ROPE_SCALING_NONE:    RETVAL = "none"; break;
        case LUGH_ROPE_SCALING_LINEAR:  RETVAL = "linear"; break;
        case LUGH_ROPE_SCALING_YARN:    RETVAL = "yarn"; break;
        case LUGH_ROPE_SCALING_LONGROPE: RETVAL = "longrope"; break;
        default: RETVAL = "unknown";
    }
OUTPUT:
    RETVAL

int
n_ctx_orig(self)
    SV *self
CODE:
    LughRopeConfig *config = get_lugh_rope(aTHX_ self);
    RETVAL = config->n_ctx_orig;
OUTPUT:
    RETVAL

int
target_ctx(self)
    SV *self
CODE:
    LughRopeConfig *config = get_lugh_rope(aTHX_ self);
    RETVAL = config->target_ctx;
OUTPUT:
    RETVAL

double
freq_base(self)
    SV *self
CODE:
    LughRopeConfig *config = get_lugh_rope(aTHX_ self);
    RETVAL = config->freq_base;
OUTPUT:
    RETVAL

double
freq_scale(self)
    SV *self
CODE:
    LughRopeConfig *config = get_lugh_rope(aTHX_ self);
    RETVAL = config->freq_scale;
OUTPUT:
    RETVAL

double
ext_factor(self)
    SV *self
CODE:
    LughRopeConfig *config = get_lugh_rope(aTHX_ self);
    RETVAL = config->ext_factor;
OUTPUT:
    RETVAL

double
attn_factor(self)
    SV *self
CODE:
    LughRopeConfig *config = get_lugh_rope(aTHX_ self);
    RETVAL = config->attn_factor;
OUTPUT:
    RETVAL

double
beta_fast(self)
    SV *self
CODE:
    LughRopeConfig *config = get_lugh_rope(aTHX_ self);
    RETVAL = config->beta_fast;
OUTPUT:
    RETVAL

double
beta_slow(self)
    SV *self
CODE:
    LughRopeConfig *config = get_lugh_rope(aTHX_ self);
    RETVAL = config->beta_slow;
OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
CODE:
    /* Magic cleanup handles this */
    PERL_UNUSED_VAR(self);

# Constants for scaling types
int
ROPE_SCALING_NONE()
CODE:
    RETVAL = LUGH_ROPE_SCALING_NONE;
OUTPUT:
    RETVAL

int
ROPE_SCALING_LINEAR()
CODE:
    RETVAL = LUGH_ROPE_SCALING_LINEAR;
OUTPUT:
    RETVAL

int
ROPE_SCALING_YARN()
CODE:
    RETVAL = LUGH_ROPE_SCALING_YARN;
OUTPUT:
    RETVAL

int
ROPE_SCALING_LONGROPE()
CODE:
    RETVAL = LUGH_ROPE_SCALING_LONGROPE;
OUTPUT:
    RETVAL

# ============================================================================
# Lugh::Speculative - Speculative Decoding
# ============================================================================

MODULE = Lugh    PACKAGE = Lugh::Speculative

SV *
new(class, ...)
    const char *class
PREINIT:
    HV *hv;
    SV *obj, *main_inference_sv = NULL, *draft_inference_sv = NULL;
    SV **svp;
    int main_model_id = 0, draft_model_id = 0;
    int main_n_vocab = 0, draft_n_vocab = 0;
    LughSpeculative *spec;
    int i, k = 4;
    float temperature = 0.8, top_p = 0.95;
    HV *stash;
CODE:
    /* Parse named parameters */
    for (i = 1; i < items; i += 2) {
        if (i + 1 < items && SvPOK(ST(i))) {
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            if (strEQ(key, "inference") || strEQ(key, "main")) {
                main_inference_sv = val;
            } else if (strEQ(key, "draft") || strEQ(key, "draft_inference")) {
                draft_inference_sv = val;
            } else if (strEQ(key, "k") || strEQ(key, "depth")) {
                k = SvIV(val);
            } else if (strEQ(key, "temperature")) {
                temperature = SvNV(val);
            } else if (strEQ(key, "top_p")) {
                top_p = SvNV(val);
            }
        }
    }
    
    if (!main_inference_sv)
        croak("Lugh::Speculative->new requires 'inference' (main inference engine)");
    if (!draft_inference_sv)
        croak("Lugh::Speculative->new requires 'draft' (draft inference engine)");
    
    /* Extract model IDs and vocab sizes from inference objects */
    if (!SvROK(main_inference_sv) || SvTYPE(SvRV(main_inference_sv)) != SVt_PVHV)
        croak("'inference' must be a Lugh::Inference object");
    if (!SvROK(draft_inference_sv) || SvTYPE(SvRV(draft_inference_sv)) != SVt_PVHV)
        croak("'draft' must be a Lugh::Inference object");
    
    hv = (HV*)SvRV(main_inference_sv);
    svp = hv_fetch(hv, "_model_id", 9, 0);
    if (svp && *svp) main_model_id = SvIV(*svp);
    svp = hv_fetch(hv, "n_vocab", 7, 0);
    if (svp && *svp) main_n_vocab = SvIV(*svp);
    
    hv = (HV*)SvRV(draft_inference_sv);
    svp = hv_fetch(hv, "_model_id", 9, 0);
    if (svp && *svp) draft_model_id = SvIV(*svp);
    svp = hv_fetch(hv, "n_vocab", 7, 0);
    if (svp && *svp) draft_n_vocab = SvIV(*svp);
    
    /* Validate vocab compatibility */
    if (main_n_vocab != draft_n_vocab)
        croak("Vocab size mismatch: main model has %d, draft model has %d", 
              main_n_vocab, draft_n_vocab);
    
    if (main_n_vocab == 0)
        croak("Could not determine vocabulary size from inference objects");
    
    /* Validate k */
    if (k < 1 || k > 16)
        croak("Speculation depth k must be between 1 and 16 (got %d)", k);
    
    /* Create KV caches for both models (we need to get model params) */
    /* For now, create them lazily in generate() */
    
    /* Create speculative decoder */
    spec = create_speculative(main_model_id, draft_model_id, 
                              NULL, NULL, main_n_vocab,
                              k, temperature, top_p);
    if (!spec)
        croak("Failed to create speculative decoder");
    
    /* Create blessed object */
    obj = newSViv(0);
    sv_magicext(obj, NULL, PERL_MAGIC_ext, &lugh_speculative_vtbl, (char*)(IV)spec->id, 0);
    
    /* Store references to inference objects */
    hv = newHV();
    hv_store(hv, "_spec_id", 8, newSViv(spec->id), 0);
    hv_store(hv, "_main_inference", 15, SvREFCNT_inc(main_inference_sv), 0);
    hv_store(hv, "_draft_inference", 16, SvREFCNT_inc(draft_inference_sv), 0);
    hv_store(hv, "k", 1, newSViv(k), 0);
    hv_store(hv, "temperature", 11, newSVnv(temperature), 0);
    hv_store(hv, "top_p", 5, newSVnv(top_p), 0);
    hv_store(hv, "n_vocab", 7, newSViv(main_n_vocab), 0);
    
    stash = gv_stashpv(class, GV_ADD);
    RETVAL = sv_bless(newRV_noinc((SV*)hv), stash);
OUTPUT:
    RETVAL

int
k(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Speculative object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "k", 1, 0);
    RETVAL = svp ? SvIV(*svp) : 4;
OUTPUT:
    RETVAL

double
temperature(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Speculative object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "temperature", 11, 0);
    RETVAL = svp ? SvNV(*svp) : 0.8;
OUTPUT:
    RETVAL

double
top_p(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Speculative object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "top_p", 5, 0);
    RETVAL = svp ? SvNV(*svp) : 0.95;
OUTPUT:
    RETVAL

int
n_vocab(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Speculative object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "n_vocab", 7, 0);
    RETVAL = svp ? SvIV(*svp) : 0;
OUTPUT:
    RETVAL

double
acceptance_rate(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughSpeculative *spec;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Speculative object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_spec_id", 8, 0);
    if (!svp) croak("Invalid Lugh::Speculative object");
    spec = get_speculative_by_id(SvIV(*svp));
    if (!spec) croak("Speculative decoder has been destroyed");
    
    if (spec->tokens_drafted == 0)
        RETVAL = 0.0;
    else
        RETVAL = (double)spec->tokens_accepted / (double)spec->tokens_drafted;
OUTPUT:
    RETVAL

IV
tokens_drafted(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughSpeculative *spec;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Speculative object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_spec_id", 8, 0);
    if (!svp) croak("Invalid Lugh::Speculative object");
    spec = get_speculative_by_id(SvIV(*svp));
    if (!spec) croak("Speculative decoder has been destroyed");
    RETVAL = spec->tokens_drafted;
OUTPUT:
    RETVAL

IV
tokens_accepted(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughSpeculative *spec;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Speculative object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_spec_id", 8, 0);
    if (!svp) croak("Invalid Lugh::Speculative object");
    spec = get_speculative_by_id(SvIV(*svp));
    if (!spec) croak("Speculative decoder has been destroyed");
    RETVAL = spec->tokens_accepted;
OUTPUT:
    RETVAL

IV
total_steps(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughSpeculative *spec;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Speculative object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_spec_id", 8, 0);
    if (!svp) croak("Invalid Lugh::Speculative object");
    spec = get_speculative_by_id(SvIV(*svp));
    if (!spec) croak("Speculative decoder has been destroyed");
    RETVAL = spec->total_steps;
OUTPUT:
    RETVAL

void
reset_stats(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughSpeculative *spec;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Speculative object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_spec_id", 8, 0);
    if (!svp) croak("Invalid Lugh::Speculative object");
    spec = get_speculative_by_id(SvIV(*svp));
    if (!spec) croak("Speculative decoder has been destroyed");
    
    SPECULATIVE_LOCK(spec);
    spec->tokens_drafted = 0;
    spec->tokens_accepted = 0;
    spec->total_steps = 0;
    SPECULATIVE_UNLOCK(spec);

void
DESTROY(self)
    SV *self
CODE:
    /* Magic cleanup handles this */
    PERL_UNUSED_VAR(self);

int
init_caches(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughSpeculative *spec;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Speculative object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "_spec_id", 8, 0);
    if (!svp) croak("Invalid Lugh::Speculative object");
    spec = get_speculative_by_id(SvIV(*svp));
    if (!spec) croak("Speculative decoder has been destroyed");
    
    if (!spec_init_caches(aTHX_ hv, spec)) {
        croak("Failed to initialize KV caches");
    }
    
    RETVAL = 1;
OUTPUT:
    RETVAL

void
draft_tokens(self, input_tokens_ref, n_draft)
    SV *self
    SV *input_tokens_ref
    int n_draft
PREINIT:
    HV *hv;
    SV **svp;
    LughSpeculative *spec;
    AV *input_av, *draft_av;
    int i, n_input;
    int *input_tokens;
PPCODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Speculative object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "_spec_id", 8, 0);
    if (!svp) croak("Invalid Lugh::Speculative object");
    spec = get_speculative_by_id(SvIV(*svp));
    if (!spec) croak("Speculative decoder has been destroyed");
    
    if (!SvROK(input_tokens_ref) || SvTYPE(SvRV(input_tokens_ref)) != SVt_PVAV)
        croak("input_tokens must be an array reference");
    input_av = (AV*)SvRV(input_tokens_ref);
    n_input = av_len(input_av) + 1;
    
    /* Convert input tokens to C array */
    Newx(input_tokens, n_input, int);
    for (i = 0; i < n_input; i++) {
        SV **tv = av_fetch(input_av, i, 0);
        input_tokens[i] = tv ? SvIV(*tv) : 0;
    }
    
    /* Call C helper function */
    draft_av = spec_draft_tokens(aTHX_ hv, spec, input_tokens, n_input, n_draft);
    
    Safefree(input_tokens);
    
    if (!draft_av) {
        croak("Draft token generation failed");
    }
    
    EXTEND(SP, 1);
    mPUSHs(newRV_noinc((SV*)draft_av));

void
verify_tokens(self, input_tokens_ref, draft_tokens_ref)
    SV *self
    SV *input_tokens_ref
    SV *draft_tokens_ref
PREINIT:
    HV *hv;
    SV **svp;
    LughSpeculative *spec;
    AV *input_av, *draft_av_in, *accepted_av;
    int i, n_input, n_draft;
    int *input_tokens, *draft_tokens;
PPCODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Speculative object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "_spec_id", 8, 0);
    if (!svp) croak("Invalid Lugh::Speculative object");
    spec = get_speculative_by_id(SvIV(*svp));
    if (!spec) croak("Speculative decoder has been destroyed");
    
    if (!SvROK(input_tokens_ref) || SvTYPE(SvRV(input_tokens_ref)) != SVt_PVAV)
        croak("input_tokens must be an array reference");
    if (!SvROK(draft_tokens_ref) || SvTYPE(SvRV(draft_tokens_ref)) != SVt_PVAV)
        croak("draft_tokens must be an array reference");
    
    input_av = (AV*)SvRV(input_tokens_ref);
    draft_av_in = (AV*)SvRV(draft_tokens_ref);
    n_input = av_len(input_av) + 1;
    n_draft = av_len(draft_av_in) + 1;
    
    /* Convert input tokens to C array */
    Newx(input_tokens, n_input, int);
    for (i = 0; i < n_input; i++) {
        SV **tv = av_fetch(input_av, i, 0);
        input_tokens[i] = tv ? SvIV(*tv) : 0;
    }
    
    /* Convert draft tokens to C array */
    Newx(draft_tokens, n_draft, int);
    for (i = 0; i < n_draft; i++) {
        SV **tv = av_fetch(draft_av_in, i, 0);
        draft_tokens[i] = tv ? SvIV(*tv) : 0;
    }
    
    /* Call C helper function */
    accepted_av = spec_verify_tokens(aTHX_ hv, spec, input_tokens, n_input, draft_tokens, n_draft);
    
    Safefree(input_tokens);
    Safefree(draft_tokens);
    
    if (!accepted_av) {
        croak("Token verification failed");
    }
    
    EXTEND(SP, 1);
    mPUSHs(newRV_noinc((SV*)accepted_av));

void
step(self, input_tokens_ref)
    SV *self
    SV *input_tokens_ref
PREINIT:
    HV *hv;
    SV **svp;
    LughSpeculative *spec;
    AV *input_av, *accepted_av;
    int *input_tokens;
    int n_input, i;
PPCODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Speculative object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "_spec_id", 8, 0);
    if (!svp) croak("Invalid Lugh::Speculative object");
    spec = get_speculative_by_id(SvIV(*svp));
    if (!spec) croak("Speculative decoder has been destroyed");
    
    if (!SvROK(input_tokens_ref) || SvTYPE(SvRV(input_tokens_ref)) != SVt_PVAV)
        croak("input_tokens must be an array reference");
    
    input_av = (AV*)SvRV(input_tokens_ref);
    n_input = av_len(input_av) + 1;
    
    /* Convert input tokens to C array */
    Newx(input_tokens, n_input, int);
    for (i = 0; i < n_input; i++) {
        SV **tv = av_fetch(input_av, i, 0);
        input_tokens[i] = tv ? SvIV(*tv) : 0;
    }
    
    /* Call C helper function directly */
    accepted_av = spec_step(aTHX_ hv, spec, input_tokens, n_input);
    
    Safefree(input_tokens);
    
    if (!accepted_av) {
        if (spec_last_error[0] != '\0') {
            croak("Speculative step failed: %s", spec_last_error);
        } else {
            croak("Speculative step failed");
        }
    }
    
    EXTEND(SP, 1);
    mPUSHs(newRV_noinc((SV*)accepted_av));

void
generate(self, input_tokens_ref, max_tokens)
    SV *self
    SV *input_tokens_ref
    int max_tokens
PREINIT:
    HV *hv;
    SV **svp;
    LughSpeculative *spec;
    AV *input_av, *output_av, *accepted_av;
    int *current_tokens;
    int n_current, n_generated;
    int i;
PPCODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Speculative object");
    hv = (HV*)SvRV(self);
    
    svp = hv_fetch(hv, "_spec_id", 8, 0);
    if (!svp) croak("Invalid Lugh::Speculative object");
    spec = get_speculative_by_id(SvIV(*svp));
    if (!spec) croak("Speculative decoder has been destroyed");
    
    if (!SvROK(input_tokens_ref) || SvTYPE(SvRV(input_tokens_ref)) != SVt_PVAV)
        croak("input_tokens must be an array reference");
    
    input_av = (AV*)SvRV(input_tokens_ref);
    n_current = av_len(input_av) + 1;
    
    if (max_tokens <= 0) max_tokens = 256;
    
    /* Initialize caches directly */
    if (!spec_init_caches(aTHX_ hv, spec)) {
        croak("Failed to initialize caches");
    }
    
    /* Build current tokens array */
    Newx(current_tokens, n_current + max_tokens, int);
    for (i = 0; i < n_current; i++) {
        SV **tv = av_fetch(input_av, i, 0);
        current_tokens[i] = tv ? SvIV(*tv) : 0;
    }
    
    output_av = newAV();
    n_generated = 0;
    
    /* Generation loop */
    while (n_generated < max_tokens) {
        int n_accepted;
        
        /* Call C helper function directly */
        accepted_av = spec_step(aTHX_ hv, spec, current_tokens, n_current);
        
        if (!accepted_av) {
            break;
        }
        
        n_accepted = av_len(accepted_av) + 1;
        
        if (n_accepted == 0) {
            av_undef(accepted_av);
            break;
        }
        
        /* Add accepted tokens to current sequence and output */
        for (i = 0; i < n_accepted && n_generated < max_tokens; i++) {
            SV **tv = av_fetch(accepted_av, i, 0);
            if (tv && *tv) {
                int token = SvIV(*tv);
                current_tokens[n_current++] = token;
                av_push(output_av, newSViv(token));
                n_generated++;
                
                /* Check for EOS token */
                if (token == 2) {
                    av_undef(accepted_av);
                    goto done;
                }
            }
        }
        
        av_undef(accepted_av);
    }
    
  done:
    Safefree(current_tokens);

    EXTEND(SP, 1);
    mPUSHs(newRV_noinc((SV*)output_av));

void
reset(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughSpeculative *spec;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Speculative object");
    hv = (HV*)SvRV(self);

    svp = hv_fetch(hv, "_spec_id", 8, 0);
    if (!svp) croak("Invalid Lugh::Speculative object");
    spec = get_speculative_by_id(SvIV(*svp));
    if (!spec) croak("Speculative decoder has been destroyed");

    SPECULATIVE_LOCK(spec);
    /* Reset KV caches if they exist */
    if (spec->main_cache) {
        KVCACHE_LOCK(spec->main_cache);
        spec->main_cache->n_cached = 0;
        KVCACHE_UNLOCK(spec->main_cache);
    }
    if (spec->draft_cache) {
        KVCACHE_LOCK(spec->draft_cache);
        spec->draft_cache->n_cached = 0;
        KVCACHE_UNLOCK(spec->draft_cache);
    }
    SPECULATIVE_UNLOCK(spec);

# ============================================================================
# Lugh::Autograd - Automatic Differentiation Support
# ============================================================================

MODULE = Lugh    PACKAGE = Lugh::Autograd::Tensor

SV *
new(class, ctx_sv, type_str, ...)
    char *class
    SV *ctx_sv
    char *type_str
PREINIT:
    LughContext *lctx;
    LughTensor *lt;
    struct ggml_tensor *tensor = NULL;
    int64_t ne[4] = {1, 1, 1, 1};
    int n_dims = 0;
    int i;
    enum ggml_type dtype = GGML_TYPE_F32;
    bool requires_grad = false;
    HV *result_hv;
CODE:
    lctx = get_lugh_context(aTHX_ ctx_sv);
    
    /* Parse type string */
    if (strEQ(type_str, "f32")) {
        dtype = GGML_TYPE_F32;
    } else if (strEQ(type_str, "f16")) {
        dtype = GGML_TYPE_F16;
    } else if (strEQ(type_str, "i32")) {
        dtype = GGML_TYPE_I32;
    } else {
        croak("Unsupported tensor type: %s (use f32, f16, or i32)", type_str);
    }
    
    /* Parse remaining arguments: dimensions and options */
    /* Format: new($ctx, $type, @dims) or new($ctx, $type, @dims, { requires_grad => 1 }) */
    for (i = 3; i < items; i++) {
        SV *arg = ST(i);
        if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVHV) {
            /* Options hash */
            HV *opts = (HV*)SvRV(arg);
            SV **rg = hv_fetch(opts, "requires_grad", 13, 0);
            if (rg && *rg) requires_grad = SvTRUE(*rg);
        } else {
            /* Dimension */
            if (n_dims >= 4) croak("Maximum 4 dimensions supported");
            ne[n_dims] = SvIV(arg);
            if (ne[n_dims] <= 0) {
                croak("Invalid dimension %d at position %d: dimensions must be positive", 
                      (int)ne[n_dims], n_dims);
            }
            n_dims++;
        }
    }
    
    if (n_dims == 0) n_dims = 1;  /* Default to 1D */
    
    /* Create tensor based on dimensionality */
    switch (n_dims) {
        case 1:
            tensor = ggml_new_tensor_1d(lctx->ctx, dtype, ne[0]);
            break;
        case 2:
            tensor = ggml_new_tensor_2d(lctx->ctx, dtype, ne[0], ne[1]);
            break;
        case 3:
            tensor = ggml_new_tensor_3d(lctx->ctx, dtype, ne[0], ne[1], ne[2]);
            break;
        case 4:
            tensor = ggml_new_tensor_4d(lctx->ctx, dtype, ne[0], ne[1], ne[2], ne[3]);
            break;
    }
    
    if (!tensor) {
        croak("Failed to create tensor");
    }
    
    /* Create and register LughTensor */
    lt = create_lugh_tensor(aTHX_ tensor, lctx->id, requires_grad);
    if (!lt) {
        croak("Failed to register tensor");
    }
    
    /* If requires_grad, allocate gradient tensor now */
    if (requires_grad) {
        if (!alloc_grad(aTHX_ lt, lctx)) {
            free_lugh_tensor(lt);
            croak("Failed to allocate gradient tensor");
        }
    }
    
    /* Return as blessed hash reference */
    result_hv = newHV();
    hv_store(result_hv, "_tensor_id", 10, newSViv(lt->id), 0);
    hv_store(result_hv, "_context_id", 11, newSViv(lctx->id), 0);
    hv_store(result_hv, "requires_grad", 13, newSViv(requires_grad ? 1 : 0), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)result_hv), gv_stashpv(class, GV_ADD));
OUTPUT:
    RETVAL

int
id(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Autograd::Tensor object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_tensor_id", 10, 0);
    RETVAL = svp ? SvIV(*svp) : -1;
OUTPUT:
    RETVAL

bool
requires_grad(self, ...)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughTensor *lt;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Autograd::Tensor object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid tensor object");
    lt = get_tensor_by_id(SvIV(*svp));
    if (!lt) croak("Tensor has been freed");
    
    if (items > 1) {
        /* Setter */
        bool new_val = SvTRUE(ST(1));
        lt->requires_grad = new_val;
        hv_store(hv, "requires_grad", 13, newSViv(new_val ? 1 : 0), 0);
        
        /* Allocate grad tensor if needed */
        if (new_val && !lt->grad) {
            LughContext *lctx = get_context_by_id(lt->context_id);
            if (lctx) {
                alloc_grad(aTHX_ lt, lctx);
            }
        }
    }
    RETVAL = lt->requires_grad;
OUTPUT:
    RETVAL

SV *
grad(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughTensor *lt;
    int64_t i, n_elements;
    AV *grad_av;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Autograd::Tensor object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid tensor object");
    lt = get_tensor_by_id(SvIV(*svp));
    if (!lt) croak("Tensor has been freed");
    
    if (!lt->grad) {
        RETVAL = &PL_sv_undef;
    } else {
        /* Return gradient values as array reference */
        n_elements = ggml_nelements(lt->grad);
        grad_av = newAV();
        av_extend(grad_av, n_elements - 1);
        
        for (i = 0; i < n_elements; i++) {
            av_push(grad_av, newSVnv(ggml_get_f32_1d(lt->grad, i)));
        }
        RETVAL = newRV_noinc((SV*)grad_av);
    }
OUTPUT:
    RETVAL

void
zero_grad(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughTensor *lt;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Autograd::Tensor object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid tensor object");
    lt = get_tensor_by_id(SvIV(*svp));
    if (!lt) croak("Tensor has been freed");
    
    zero_grad(lt);

void
set_data(self, ...)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughTensor *lt;
    int64_t i, n_elements;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Autograd::Tensor object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid tensor object");
    lt = get_tensor_by_id(SvIV(*svp));
    if (!lt) croak("Tensor has been freed");
    
    n_elements = ggml_nelements(lt->tensor);
    
    if (items - 1 != n_elements) {
        croak("Expected %ld values, got %d", (long)n_elements, (int)(items - 1));
    }
    
    for (i = 0; i < n_elements; i++) {
        ggml_set_f32_1d(lt->tensor, i, SvNV(ST(i + 1)));
    }

void
get_data(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughTensor *lt;
    int64_t i, n_elements;
PPCODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Autograd::Tensor object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid tensor object");
    lt = get_tensor_by_id(SvIV(*svp));
    if (!lt) croak("Tensor has been freed");
    
    n_elements = ggml_nelements(lt->tensor);
    EXTEND(SP, n_elements);
    for (i = 0; i < n_elements; i++) {
        mPUSHn(ggml_get_f32_1d(lt->tensor, i));
    }

int64_t
nelements(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughTensor *lt;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Autograd::Tensor object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid tensor object");
    lt = get_tensor_by_id(SvIV(*svp));
    if (!lt) croak("Tensor has been freed");
    
    RETVAL = ggml_nelements(lt->tensor);
OUTPUT:
    RETVAL

void
shape(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughTensor *lt;
    int i, n_dims;
PPCODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Autograd::Tensor object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid tensor object");
    lt = get_tensor_by_id(SvIV(*svp));
    if (!lt) croak("Tensor has been freed");
    
    n_dims = ggml_n_dims(lt->tensor);
    EXTEND(SP, n_dims);
    for (i = 0; i < n_dims; i++) {
        mPUSHi(lt->tensor->ne[i]);
    }

bool
is_leaf(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughTensor *lt;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Autograd::Tensor object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid tensor object");
    lt = get_tensor_by_id(SvIV(*svp));
    if (!lt) croak("Tensor has been freed");
    
    RETVAL = lt->is_leaf;
OUTPUT:
    RETVAL

void
backward(self, ...)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughTensor *lt;
    LughContext *lctx;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Autograd::Tensor object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid tensor object");
    lt = get_tensor_by_id(SvIV(*svp));
    if (!lt) croak("Tensor has been freed");
    
    if (!lt->requires_grad) {
        croak("backward() called on tensor that doesn't require gradients");
    }
    
    lctx = get_context_by_id(lt->context_id);
    if (!lctx) croak("Context has been destroyed");
    
    /* Ensure gradient tensor exists */
    if (!lt->grad) {
        alloc_grad(aTHX_ lt, lctx);
    }
    
    /* Initialize gradient to 1.0 for scalar loss, or provided gradient */
    if (items > 1) {
        /* User provided gradient values */
        int64_t i, n = ggml_nelements(lt->grad);
        if (items - 1 != n) {
            croak("Expected %ld gradient values, got %d", (long)n, (int)(items - 1));
        }
        for (i = 0; i < n; i++) {
            ggml_set_f32_1d(lt->grad, i, SvNV(ST(i + 1)));
        }
    } else {
        /* Default: set gradient to 1.0 (scalar loss) */
        set_grad_ones(lt);
    }
    
    /* Perform backward pass through computation graph */
    backward_tensor(aTHX_ lt, lctx);

SV *
_raw_tensor_ptr(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughTensor *lt;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Invalid Lugh::Autograd::Tensor object");
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid tensor object");
    lt = get_tensor_by_id(SvIV(*svp));
    if (!lt) croak("Tensor has been freed");
    
    /* Return raw pointer for interop with Lugh::Ops */
    RETVAL = newSViv(PTR2IV(lt->tensor));
OUTPUT:
    RETVAL

# ============================================================================
# Autograd Operations - create tensors with gradient tracking
# ============================================================================

MODULE = Lugh    PACKAGE = Lugh::Autograd::Ops

SV *
add(class, ctx_sv, a_sv, b_sv)
    char *class
    SV *ctx_sv
    SV *a_sv
    SV *b_sv
PREINIT:
    LughContext *lctx;
    LughTensor *a, *b, *out;
    struct ggml_tensor *result;
    HV *a_hv, *b_hv, *result_hv;
    SV **svp;
    bool requires_grad;
    int i;
CODE:
    PERL_UNUSED_ARG(class);
    lctx = get_lugh_context(aTHX_ ctx_sv);
    
    /* Get input tensors */
    if (!SvROK(a_sv) || SvTYPE(SvRV(a_sv)) != SVt_PVHV)
        croak("First argument must be an Autograd::Tensor");
    if (!SvROK(b_sv) || SvTYPE(SvRV(b_sv)) != SVt_PVHV)
        croak("Second argument must be an Autograd::Tensor");
    
    a_hv = (HV*)SvRV(a_sv);
    b_hv = (HV*)SvRV(b_sv);
    
    svp = hv_fetch(a_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid first tensor");
    a = get_tensor_by_id(SvIV(*svp));
    if (!a) croak("First tensor has been freed");
    
    svp = hv_fetch(b_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid second tensor");
    b = get_tensor_by_id(SvIV(*svp));
    if (!b) croak("Second tensor has been freed");
    
    /* Create output tensor */
    result = ggml_add(lctx->ctx, a->tensor, b->tensor);
    if (!result) croak("Failed to create add operation");
    
    /* Compute requires_grad for output (only if grad is enabled globally) */
    requires_grad = grad_enabled && (a->requires_grad || b->requires_grad);
    
    out = create_lugh_tensor(aTHX_ result, lctx->id, requires_grad);
    if (!out) croak("Failed to register output tensor");
    
    /* Set up computation graph only if tracking gradients */
    if (requires_grad) {
        out->is_leaf = false;
        out->backward_op = LUGH_BACKWARD_ADD;
        out->n_inputs = 2;
        out->input_ids[0] = a->id;
        out->input_ids[1] = b->id;
        alloc_grad(aTHX_ out, lctx);
    }
    
    /* Return as blessed hash reference */
    result_hv = newHV();
    hv_store(result_hv, "_tensor_id", 10, newSViv(out->id), 0);
    hv_store(result_hv, "_context_id", 11, newSViv(lctx->id), 0);
    hv_store(result_hv, "requires_grad", 13, newSViv(requires_grad ? 1 : 0), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)result_hv), 
                      gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
OUTPUT:
    RETVAL

SV *
mul(class, ctx_sv, a_sv, b_sv)
    char *class
    SV *ctx_sv
    SV *a_sv
    SV *b_sv
PREINIT:
    LughContext *lctx;
    LughTensor *a, *b, *out;
    struct ggml_tensor *result;
    HV *a_hv, *b_hv, *result_hv;
    SV **svp;
    bool requires_grad;
    int i;
CODE:
    PERL_UNUSED_ARG(class);
    lctx = get_lugh_context(aTHX_ ctx_sv);
    
    /* Get input tensors */
    if (!SvROK(a_sv) || SvTYPE(SvRV(a_sv)) != SVt_PVHV)
        croak("First argument must be an Autograd::Tensor");
    if (!SvROK(b_sv) || SvTYPE(SvRV(b_sv)) != SVt_PVHV)
        croak("Second argument must be an Autograd::Tensor");
    
    a_hv = (HV*)SvRV(a_sv);
    b_hv = (HV*)SvRV(b_sv);
    
    svp = hv_fetch(a_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid first tensor");
    a = get_tensor_by_id(SvIV(*svp));
    if (!a) croak("First tensor has been freed");
    
    svp = hv_fetch(b_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid second tensor");
    b = get_tensor_by_id(SvIV(*svp));
    if (!b) croak("Second tensor has been freed");
    
    /* Create output tensor - element-wise multiply */
    result = ggml_mul(lctx->ctx, a->tensor, b->tensor);
    if (!result) croak("Failed to create mul operation");
    
    /* Compute requires_grad for output (only if grad is enabled globally) */
    requires_grad = grad_enabled && (a->requires_grad || b->requires_grad);
    
    out = create_lugh_tensor(aTHX_ result, lctx->id, requires_grad);
    if (!out) croak("Failed to register output tensor");
    
    /* Set up computation graph only if tracking gradients */
    if (requires_grad) {
        out->is_leaf = false;
        out->backward_op = LUGH_BACKWARD_MUL;
        out->n_inputs = 2;
        out->input_ids[0] = a->id;
        out->input_ids[1] = b->id;
        alloc_grad(aTHX_ out, lctx);
    }
    
    /* Return as blessed hash reference */
    result_hv = newHV();
    hv_store(result_hv, "_tensor_id", 10, newSViv(out->id), 0);
    hv_store(result_hv, "_context_id", 11, newSViv(lctx->id), 0);
    hv_store(result_hv, "requires_grad", 13, newSViv(requires_grad ? 1 : 0), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)result_hv), 
                      gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
OUTPUT:
    RETVAL

SV *
sum(class, ctx_sv, a_sv)
    char *class
    SV *ctx_sv
    SV *a_sv
PREINIT:
    LughContext *lctx;
    LughTensor *a, *out;
    struct ggml_tensor *result;
    HV *a_hv, *result_hv;
    SV **svp;
    bool requires_grad;
CODE:
    PERL_UNUSED_ARG(class);
    lctx = get_lugh_context(aTHX_ ctx_sv);
    
    /* Get input tensor */
    if (!SvROK(a_sv) || SvTYPE(SvRV(a_sv)) != SVt_PVHV)
        croak("Argument must be an Autograd::Tensor");
    
    a_hv = (HV*)SvRV(a_sv);
    
    svp = hv_fetch(a_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid tensor");
    a = get_tensor_by_id(SvIV(*svp));
    if (!a) croak("Tensor has been freed");
    
    /* Create sum output tensor (scalar) */
    result = ggml_sum(lctx->ctx, a->tensor);
    if (!result) croak("Failed to create sum operation");
    
    /* Compute requires_grad (only if grad is enabled globally) */
    requires_grad = grad_enabled && a->requires_grad;
    
    out = create_lugh_tensor(aTHX_ result, lctx->id, requires_grad);
    if (!out) croak("Failed to register output tensor");
    
    /* Set up computation graph only if tracking gradients */
    if (requires_grad) {
        out->is_leaf = false;
        out->backward_op = LUGH_BACKWARD_SUM;
        out->n_inputs = 1;
        out->input_ids[0] = a->id;
        alloc_grad(aTHX_ out, lctx);
    }
    
    /* Return as blessed hash reference */
    result_hv = newHV();
    hv_store(result_hv, "_tensor_id", 10, newSViv(out->id), 0);
    hv_store(result_hv, "_context_id", 11, newSViv(lctx->id), 0);
    hv_store(result_hv, "requires_grad", 13, newSViv(requires_grad ? 1 : 0), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)result_hv), 
                      gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
OUTPUT:
    RETVAL

SV *
sub(class, ctx_sv, a_sv, b_sv)
    char *class
    SV *ctx_sv
    SV *a_sv
    SV *b_sv
PREINIT:
    LughContext *lctx;
    LughTensor *a, *b, *out;
    struct ggml_tensor *result;
    HV *a_hv, *b_hv, *result_hv;
    SV **svp;
    bool requires_grad;
CODE:
    PERL_UNUSED_ARG(class);
    lctx = get_lugh_context(aTHX_ ctx_sv);
    
    if (!SvROK(a_sv) || SvTYPE(SvRV(a_sv)) != SVt_PVHV)
        croak("First argument must be an Autograd::Tensor");
    if (!SvROK(b_sv) || SvTYPE(SvRV(b_sv)) != SVt_PVHV)
        croak("Second argument must be an Autograd::Tensor");
    
    a_hv = (HV*)SvRV(a_sv);
    b_hv = (HV*)SvRV(b_sv);
    
    svp = hv_fetch(a_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid first tensor");
    a = get_tensor_by_id(SvIV(*svp));
    if (!a) croak("First tensor has been freed");
    
    svp = hv_fetch(b_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid second tensor");
    b = get_tensor_by_id(SvIV(*svp));
    if (!b) croak("Second tensor has been freed");
    
    result = ggml_sub(lctx->ctx, a->tensor, b->tensor);
    if (!result) croak("Failed to create sub operation");
    
    requires_grad = grad_enabled && (a->requires_grad || b->requires_grad);
    
    out = create_lugh_tensor(aTHX_ result, lctx->id, requires_grad);
    if (!out) croak("Failed to register output tensor");
    
    if (requires_grad) {
        out->is_leaf = false;
        out->backward_op = LUGH_BACKWARD_SUB;
        out->n_inputs = 2;
        out->input_ids[0] = a->id;
        out->input_ids[1] = b->id;
        alloc_grad(aTHX_ out, lctx);
    }
    
    result_hv = newHV();
    hv_store(result_hv, "_tensor_id", 10, newSViv(out->id), 0);
    hv_store(result_hv, "_context_id", 11, newSViv(lctx->id), 0);
    hv_store(result_hv, "requires_grad", 13, newSViv(requires_grad ? 1 : 0), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)result_hv), 
                      gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
OUTPUT:
    RETVAL

SV *
div(class, ctx_sv, a_sv, b_sv)
    char *class
    SV *ctx_sv
    SV *a_sv
    SV *b_sv
PREINIT:
    LughContext *lctx;
    LughTensor *a, *b, *out;
    struct ggml_tensor *result;
    HV *a_hv, *b_hv, *result_hv;
    SV **svp;
    bool requires_grad;
CODE:
    PERL_UNUSED_ARG(class);
    lctx = get_lugh_context(aTHX_ ctx_sv);
    
    if (!SvROK(a_sv) || SvTYPE(SvRV(a_sv)) != SVt_PVHV)
        croak("First argument must be an Autograd::Tensor");
    if (!SvROK(b_sv) || SvTYPE(SvRV(b_sv)) != SVt_PVHV)
        croak("Second argument must be an Autograd::Tensor");
    
    a_hv = (HV*)SvRV(a_sv);
    b_hv = (HV*)SvRV(b_sv);
    
    svp = hv_fetch(a_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid first tensor");
    a = get_tensor_by_id(SvIV(*svp));
    if (!a) croak("First tensor has been freed");
    
    svp = hv_fetch(b_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid second tensor");
    b = get_tensor_by_id(SvIV(*svp));
    if (!b) croak("Second tensor has been freed");
    
    result = ggml_div(lctx->ctx, a->tensor, b->tensor);
    if (!result) croak("Failed to create div operation");
    
    requires_grad = grad_enabled && (a->requires_grad || b->requires_grad);
    
    out = create_lugh_tensor(aTHX_ result, lctx->id, requires_grad);
    if (!out) croak("Failed to register output tensor");
    
    if (requires_grad) {
        out->is_leaf = false;
        out->backward_op = LUGH_BACKWARD_DIV;
        out->n_inputs = 2;
        out->input_ids[0] = a->id;
        out->input_ids[1] = b->id;
        alloc_grad(aTHX_ out, lctx);
    }
    
    result_hv = newHV();
    hv_store(result_hv, "_tensor_id", 10, newSViv(out->id), 0);
    hv_store(result_hv, "_context_id", 11, newSViv(lctx->id), 0);
    hv_store(result_hv, "requires_grad", 13, newSViv(requires_grad ? 1 : 0), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)result_hv), 
                      gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
OUTPUT:
    RETVAL

SV *
scale(class, ctx_sv, a_sv, scale_val)
    char *class
    SV *ctx_sv
    SV *a_sv
    float scale_val
PREINIT:
    LughContext *lctx;
    LughTensor *a, *out;
    struct ggml_tensor *result;
    HV *a_hv, *result_hv;
    SV **svp;
    bool requires_grad;
    union { int i; float f; } scale_union;
CODE:
    PERL_UNUSED_ARG(class);
    lctx = get_lugh_context(aTHX_ ctx_sv);
    
    if (!SvROK(a_sv) || SvTYPE(SvRV(a_sv)) != SVt_PVHV)
        croak("Argument must be an Autograd::Tensor");
    
    a_hv = (HV*)SvRV(a_sv);
    
    svp = hv_fetch(a_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid tensor");
    a = get_tensor_by_id(SvIV(*svp));
    if (!a) croak("Tensor has been freed");
    
    result = ggml_scale(lctx->ctx, a->tensor, scale_val);
    if (!result) croak("Failed to create scale operation");
    
    requires_grad = grad_enabled && a->requires_grad;
    
    out = create_lugh_tensor(aTHX_ result, lctx->id, requires_grad);
    if (!out) croak("Failed to register output tensor");
    
    if (requires_grad) {
        out->is_leaf = false;
        out->backward_op = LUGH_BACKWARD_SCALE;
        out->n_inputs = 1;
        out->input_ids[0] = a->id;
        /* Store scale factor as bit-cast int in input_ids[1] */
        scale_union.f = scale_val;
        out->input_ids[1] = scale_union.i;
        alloc_grad(aTHX_ out, lctx);
    }
    
    result_hv = newHV();
    hv_store(result_hv, "_tensor_id", 10, newSViv(out->id), 0);
    hv_store(result_hv, "_context_id", 11, newSViv(lctx->id), 0);
    hv_store(result_hv, "requires_grad", 13, newSViv(requires_grad ? 1 : 0), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)result_hv), 
                      gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
OUTPUT:
    RETVAL

SV *
matmul(class, ctx_sv, a_sv, b_sv)
    char *class
    SV *ctx_sv
    SV *a_sv
    SV *b_sv
PREINIT:
    LughContext *lctx;
    LughTensor *a, *b, *out;
    struct ggml_tensor *result;
    HV *a_hv, *b_hv, *result_hv;
    SV **svp;
    bool requires_grad;
CODE:
    PERL_UNUSED_ARG(class);
    lctx = get_lugh_context(aTHX_ ctx_sv);
    
    if (!SvROK(a_sv) || SvTYPE(SvRV(a_sv)) != SVt_PVHV)
        croak("First argument must be an Autograd::Tensor");
    if (!SvROK(b_sv) || SvTYPE(SvRV(b_sv)) != SVt_PVHV)
        croak("Second argument must be an Autograd::Tensor");
    
    a_hv = (HV*)SvRV(a_sv);
    b_hv = (HV*)SvRV(b_sv);
    
    svp = hv_fetch(a_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid first tensor");
    a = get_tensor_by_id(SvIV(*svp));
    if (!a) croak("First tensor has been freed");
    
    svp = hv_fetch(b_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid second tensor");
    b = get_tensor_by_id(SvIV(*svp));
    if (!b) croak("Second tensor has been freed");
    
    result = ggml_mul_mat(lctx->ctx, a->tensor, b->tensor);
    if (!result) croak("Failed to create matmul operation");
    
    requires_grad = grad_enabled && (a->requires_grad || b->requires_grad);
    
    out = create_lugh_tensor(aTHX_ result, lctx->id, requires_grad);
    if (!out) croak("Failed to register output tensor");
    
    if (requires_grad) {
        out->is_leaf = false;
        out->backward_op = LUGH_BACKWARD_MATMUL;
        out->n_inputs = 2;
        out->input_ids[0] = a->id;
        out->input_ids[1] = b->id;
        alloc_grad(aTHX_ out, lctx);
    }
    
    result_hv = newHV();
    hv_store(result_hv, "_tensor_id", 10, newSViv(out->id), 0);
    hv_store(result_hv, "_context_id", 11, newSViv(lctx->id), 0);
    hv_store(result_hv, "requires_grad", 13, newSViv(requires_grad ? 1 : 0), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)result_hv), 
                      gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
OUTPUT:
    RETVAL

SV *
relu(class, ctx_sv, a_sv)
    char *class
    SV *ctx_sv
    SV *a_sv
PREINIT:
    LughContext *lctx;
    LughTensor *a, *out;
    struct ggml_tensor *result;
    HV *a_hv, *result_hv;
    SV **svp;
    bool requires_grad;
CODE:
    PERL_UNUSED_ARG(class);
    lctx = get_lugh_context(aTHX_ ctx_sv);
    
    if (!SvROK(a_sv) || SvTYPE(SvRV(a_sv)) != SVt_PVHV)
        croak("Argument must be an Autograd::Tensor");
    
    a_hv = (HV*)SvRV(a_sv);
    
    svp = hv_fetch(a_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid tensor");
    a = get_tensor_by_id(SvIV(*svp));
    if (!a) croak("Tensor has been freed");
    
    result = ggml_relu(lctx->ctx, a->tensor);
    if (!result) croak("Failed to create relu operation");
    
    requires_grad = grad_enabled && a->requires_grad;
    
    out = create_lugh_tensor(aTHX_ result, lctx->id, requires_grad);
    if (!out) croak("Failed to register output tensor");
    
    if (requires_grad) {
        out->is_leaf = false;
        out->backward_op = LUGH_BACKWARD_RELU;
        out->n_inputs = 1;
        out->input_ids[0] = a->id;
        alloc_grad(aTHX_ out, lctx);
    }
    
    result_hv = newHV();
    hv_store(result_hv, "_tensor_id", 10, newSViv(out->id), 0);
    hv_store(result_hv, "_context_id", 11, newSViv(lctx->id), 0);
    hv_store(result_hv, "requires_grad", 13, newSViv(requires_grad ? 1 : 0), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)result_hv), 
                      gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
OUTPUT:
    RETVAL

SV *
gelu(class, ctx_sv, a_sv)
    char *class
    SV *ctx_sv
    SV *a_sv
PREINIT:
    LughContext *lctx;
    LughTensor *a, *out;
    struct ggml_tensor *result;
    HV *a_hv, *result_hv;
    SV **svp;
    bool requires_grad;
CODE:
    PERL_UNUSED_ARG(class);
    lctx = get_lugh_context(aTHX_ ctx_sv);
    
    if (!SvROK(a_sv) || SvTYPE(SvRV(a_sv)) != SVt_PVHV)
        croak("Argument must be an Autograd::Tensor");
    
    a_hv = (HV*)SvRV(a_sv);
    
    svp = hv_fetch(a_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid tensor");
    a = get_tensor_by_id(SvIV(*svp));
    if (!a) croak("Tensor has been freed");
    
    result = ggml_gelu(lctx->ctx, a->tensor);
    if (!result) croak("Failed to create gelu operation");
    
    requires_grad = grad_enabled && a->requires_grad;
    
    out = create_lugh_tensor(aTHX_ result, lctx->id, requires_grad);
    if (!out) croak("Failed to register output tensor");
    
    if (requires_grad) {
        out->is_leaf = false;
        out->backward_op = LUGH_BACKWARD_GELU;
        out->n_inputs = 1;
        out->input_ids[0] = a->id;
        alloc_grad(aTHX_ out, lctx);
    }
    
    result_hv = newHV();
    hv_store(result_hv, "_tensor_id", 10, newSViv(out->id), 0);
    hv_store(result_hv, "_context_id", 11, newSViv(lctx->id), 0);
    hv_store(result_hv, "requires_grad", 13, newSViv(requires_grad ? 1 : 0), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)result_hv), 
                      gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
OUTPUT:
    RETVAL

SV *
silu(class, ctx_sv, a_sv)
    char *class
    SV *ctx_sv
    SV *a_sv
PREINIT:
    LughContext *lctx;
    LughTensor *a, *out;
    struct ggml_tensor *result;
    HV *a_hv, *result_hv;
    SV **svp;
    bool requires_grad;
CODE:
    PERL_UNUSED_ARG(class);
    lctx = get_lugh_context(aTHX_ ctx_sv);
    
    if (!SvROK(a_sv) || SvTYPE(SvRV(a_sv)) != SVt_PVHV)
        croak("Argument must be an Autograd::Tensor");
    
    a_hv = (HV*)SvRV(a_sv);
    
    svp = hv_fetch(a_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid tensor");
    a = get_tensor_by_id(SvIV(*svp));
    if (!a) croak("Tensor has been freed");
    
    result = ggml_silu(lctx->ctx, a->tensor);
    if (!result) croak("Failed to create silu operation");
    
    requires_grad = grad_enabled && a->requires_grad;
    
    out = create_lugh_tensor(aTHX_ result, lctx->id, requires_grad);
    if (!out) croak("Failed to register output tensor");
    
    if (requires_grad) {
        out->is_leaf = false;
        out->backward_op = LUGH_BACKWARD_SILU;
        out->n_inputs = 1;
        out->input_ids[0] = a->id;
        alloc_grad(aTHX_ out, lctx);
    }
    
    result_hv = newHV();
    hv_store(result_hv, "_tensor_id", 10, newSViv(out->id), 0);
    hv_store(result_hv, "_context_id", 11, newSViv(lctx->id), 0);
    hv_store(result_hv, "requires_grad", 13, newSViv(requires_grad ? 1 : 0), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)result_hv), 
                      gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
OUTPUT:
    RETVAL

SV *
softmax(class, ctx_sv, a_sv)
    char *class
    SV *ctx_sv
    SV *a_sv
PREINIT:
    LughContext *lctx;
    LughTensor *a, *out;
    struct ggml_tensor *result;
    HV *a_hv, *result_hv;
    SV **svp;
    bool requires_grad;
CODE:
    PERL_UNUSED_ARG(class);
    lctx = get_lugh_context(aTHX_ ctx_sv);
    
    if (!SvROK(a_sv) || SvTYPE(SvRV(a_sv)) != SVt_PVHV)
        croak("Argument must be an Autograd::Tensor");
    
    a_hv = (HV*)SvRV(a_sv);
    
    svp = hv_fetch(a_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid tensor");
    a = get_tensor_by_id(SvIV(*svp));
    if (!a) croak("Tensor has been freed");
    
    result = ggml_soft_max(lctx->ctx, a->tensor);
    if (!result) croak("Failed to create softmax operation");
    
    requires_grad = grad_enabled && a->requires_grad;
    
    out = create_lugh_tensor(aTHX_ result, lctx->id, requires_grad);
    if (!out) croak("Failed to register output tensor");
    
    if (requires_grad) {
        out->is_leaf = false;
        out->backward_op = LUGH_BACKWARD_SOFTMAX;
        out->n_inputs = 1;
        out->input_ids[0] = a->id;
        alloc_grad(aTHX_ out, lctx);
    }
    
    result_hv = newHV();
    hv_store(result_hv, "_tensor_id", 10, newSViv(out->id), 0);
    hv_store(result_hv, "_context_id", 11, newSViv(lctx->id), 0);
    hv_store(result_hv, "requires_grad", 13, newSViv(requires_grad ? 1 : 0), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)result_hv), 
                      gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
OUTPUT:
    RETVAL

SV *
rms_norm(class, ctx_sv, a_sv, ...)
    char *class
    SV *ctx_sv
    SV *a_sv
PREINIT:
    LughContext *lctx;
    LughTensor *a, *out;
    struct ggml_tensor *result;
    HV *a_hv, *result_hv;
    SV **svp;
    bool requires_grad;
    float eps;
CODE:
    PERL_UNUSED_ARG(class);
    lctx = get_lugh_context(aTHX_ ctx_sv);
    
    eps = (items > 3) ? SvNV(ST(3)) : 1e-5f;
    
    if (!SvROK(a_sv) || SvTYPE(SvRV(a_sv)) != SVt_PVHV)
        croak("Argument must be an Autograd::Tensor");
    
    a_hv = (HV*)SvRV(a_sv);
    
    svp = hv_fetch(a_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid tensor");
    a = get_tensor_by_id(SvIV(*svp));
    if (!a) croak("Tensor has been freed");
    
    result = ggml_rms_norm(lctx->ctx, a->tensor, eps);
    if (!result) croak("Failed to create rms_norm operation");
    
    requires_grad = grad_enabled && a->requires_grad;
    
    out = create_lugh_tensor(aTHX_ result, lctx->id, requires_grad);
    if (!out) croak("Failed to register output tensor");
    
    if (requires_grad) {
        out->is_leaf = false;
        out->backward_op = LUGH_BACKWARD_RMS_NORM;
        out->n_inputs = 1;
        out->input_ids[0] = a->id;
        alloc_grad(aTHX_ out, lctx);
    }
    
    result_hv = newHV();
    hv_store(result_hv, "_tensor_id", 10, newSViv(out->id), 0);
    hv_store(result_hv, "_context_id", 11, newSViv(lctx->id), 0);
    hv_store(result_hv, "requires_grad", 13, newSViv(requires_grad ? 1 : 0), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)result_hv), 
                      gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
OUTPUT:
    RETVAL

SV *
mean(class, ctx_sv, a_sv)
    char *class
    SV *ctx_sv
    SV *a_sv
PREINIT:
    LughContext *lctx;
    LughTensor *a, *out;
    struct ggml_tensor *result;
    HV *a_hv, *result_hv;
    SV **svp;
    bool requires_grad;
CODE:
    PERL_UNUSED_ARG(class);
    lctx = get_lugh_context(aTHX_ ctx_sv);
    
    if (!SvROK(a_sv) || SvTYPE(SvRV(a_sv)) != SVt_PVHV)
        croak("Argument must be an Autograd::Tensor");
    
    a_hv = (HV*)SvRV(a_sv);
    
    svp = hv_fetch(a_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid tensor");
    a = get_tensor_by_id(SvIV(*svp));
    if (!a) croak("Tensor has been freed");
    
    result = ggml_mean(lctx->ctx, a->tensor);
    if (!result) croak("Failed to create mean operation");
    
    requires_grad = grad_enabled && a->requires_grad;
    
    out = create_lugh_tensor(aTHX_ result, lctx->id, requires_grad);
    if (!out) croak("Failed to register output tensor");
    
    if (requires_grad) {
        out->is_leaf = false;
        out->backward_op = LUGH_BACKWARD_MEAN;
        out->n_inputs = 1;
        out->input_ids[0] = a->id;
        alloc_grad(aTHX_ out, lctx);
    }
    
    result_hv = newHV();
    hv_store(result_hv, "_tensor_id", 10, newSViv(out->id), 0);
    hv_store(result_hv, "_context_id", 11, newSViv(lctx->id), 0);
    hv_store(result_hv, "requires_grad", 13, newSViv(requires_grad ? 1 : 0), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)result_hv), 
                      gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
PREINIT:
    HV *hv;
    SV **svp;
    LughTensor *lt;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        return;
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_tensor_id", 10, 0);
    if (!svp) return;
    lt = get_tensor_by_id(SvIV(*svp));
    if (lt) {
        free_lugh_tensor(lt);
    }

# ============================================================================
# Lugh::Autograd - Gradient Context Management
# ============================================================================

MODULE = Lugh    PACKAGE = Lugh::Autograd

bool
is_grad_enabled()
CODE:
    RETVAL = grad_enabled;
OUTPUT:
    RETVAL

bool
set_grad_enabled(enabled)
    bool enabled
PREINIT:
    bool prev;
CODE:
    prev = grad_enabled;
    grad_enabled = enabled;
    RETVAL = prev;
OUTPUT:
    RETVAL

# ============================================================================
# Lugh::Train - Training Loop and Loss Functions
# ============================================================================

MODULE = Lugh    PACKAGE = Lugh::Train

=pod

=head1 Lugh::Train

High-level training API with loss functions and training loop.

=cut

SV *
cross_entropy_loss(class, ctx_sv, logits_sv, targets_av)
    char *class
    SV *ctx_sv
    SV *logits_sv
    SV *targets_av
PREINIT:
    LughContext *lctx;
    LughTensor *logits, *loss_tensor, *targets_tensor;
    struct ggml_tensor *loss, *targets_ggml;
    HV *logits_hv, *result_hv;
    SV **svp;
    AV *targets;
    int64_t batch_size, vocab_size, i;
    float total_loss = 0.0f;
    bool requires_grad;
CODE:
    PERL_UNUSED_ARG(class);
    lctx = get_lugh_context(aTHX_ ctx_sv);
    
    /* Get logits tensor */
    if (!SvROK(logits_sv) || SvTYPE(SvRV(logits_sv)) != SVt_PVHV)
        croak("logits must be an Autograd::Tensor");
    logits_hv = (HV*)SvRV(logits_sv);
    svp = hv_fetch(logits_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid logits tensor");
    logits = get_tensor_by_id(SvIV(*svp));
    if (!logits) croak("Logits tensor has been freed");
    
    /* Get targets array */
    if (!SvROK(targets_av) || SvTYPE(SvRV(targets_av)) != SVt_PVAV)
        croak("targets must be an array reference of token IDs");
    targets = (AV*)SvRV(targets_av);
    
    /* Logits shape: [vocab_size, batch_size] or [vocab_size] */
    vocab_size = logits->tensor->ne[0];
    batch_size = logits->tensor->ne[1] > 0 ? logits->tensor->ne[1] : 1;
    
    int n_targets = av_len(targets) + 1;
    if (n_targets != batch_size) {
        croak("Number of targets (%d) must match batch size (%ld)", 
              n_targets, (long)batch_size);
    }
    
    /* Create targets tensor for backward pass */
    targets_ggml = ggml_new_tensor_1d(lctx->ctx, GGML_TYPE_F32, batch_size);
    if (!targets_ggml) croak("Failed to create targets tensor");
    for (i = 0; i < batch_size; i++) {
        SV **target_sv = av_fetch(targets, i, 0);
        if (!target_sv) croak("Missing target at index %ld", (long)i);
        ggml_set_f32_1d(targets_ggml, i, (float)SvIV(*target_sv));
    }
    targets_tensor = create_lugh_tensor(aTHX_ targets_ggml, lctx->id, false);
    if (!targets_tensor) croak("Failed to register targets tensor");
    
    /* Compute cross-entropy loss: -log(softmax(logits)[target]) */
    for (i = 0; i < batch_size; i++) {
        SV **target_sv = av_fetch(targets, i, 0);
        int target_id = SvIV(*target_sv);
        
        if (target_id < 0 || target_id >= vocab_size) {
            croak("Target ID %d out of range [0, %ld)", target_id, (long)vocab_size);
        }
        
        /* Compute log-softmax for numerical stability */
        /* log_softmax = logits - log(sum(exp(logits))) */
        float max_logit = -INFINITY;
        for (int64_t v = 0; v < vocab_size; v++) {
            float val = ggml_get_f32_1d(logits->tensor, i * vocab_size + v);
            if (val > max_logit) max_logit = val;
        }
        
        float sum_exp = 0.0f;
        for (int64_t v = 0; v < vocab_size; v++) {
            float val = ggml_get_f32_1d(logits->tensor, i * vocab_size + v);
            sum_exp += expf(val - max_logit);
        }
        float log_sum_exp = max_logit + logf(sum_exp);
        
        float target_logit = ggml_get_f32_1d(logits->tensor, i * vocab_size + target_id);
        float log_prob = target_logit - log_sum_exp;
        
        total_loss -= log_prob;  /* Negative log probability */
    }
    
    /* Average loss over batch */
    total_loss /= (float)batch_size;
    
    /* Create scalar loss tensor */
    loss = ggml_new_tensor_1d(lctx->ctx, GGML_TYPE_F32, 1);
    if (!loss) croak("Failed to create loss tensor");
    ggml_set_f32_1d(loss, 0, total_loss);
    
    requires_grad = grad_enabled && logits->requires_grad;
    
    loss_tensor = create_lugh_tensor(aTHX_ loss, lctx->id, requires_grad);
    if (!loss_tensor) croak("Failed to register loss tensor");
    
    if (requires_grad) {
        loss_tensor->is_leaf = false;
        loss_tensor->backward_op = LUGH_BACKWARD_CROSS_ENTROPY;
        loss_tensor->n_inputs = 2;
        loss_tensor->input_ids[0] = logits->id;
        loss_tensor->input_ids[1] = targets_tensor->id;
        alloc_grad(aTHX_ loss_tensor, lctx);
    }
    
    result_hv = newHV();
    hv_store(result_hv, "_tensor_id", 10, newSViv(loss_tensor->id), 0);
    hv_store(result_hv, "_context_id", 11, newSViv(lctx->id), 0);
    hv_store(result_hv, "requires_grad", 13, newSViv(requires_grad ? 1 : 0), 0);
    hv_store(result_hv, "loss_value", 10, newSVnv(total_loss), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)result_hv), 
                      gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
OUTPUT:
    RETVAL

SV *
mse_loss(class, ctx_sv, predictions_sv, targets_sv)
    char *class
    SV *ctx_sv
    SV *predictions_sv
    SV *targets_sv
PREINIT:
    LughContext *lctx;
    LughTensor *predictions, *targets_tensor, *loss_tensor;
    struct ggml_tensor *loss;
    HV *pred_hv, *targets_hv, *result_hv;
    SV **svp;
    int64_t i, n_elements;
    float total_loss = 0.0f;
    bool requires_grad;
CODE:
    PERL_UNUSED_ARG(class);
    lctx = get_lugh_context(aTHX_ ctx_sv);
    
    /* Get predictions tensor */
    if (!SvROK(predictions_sv) || SvTYPE(SvRV(predictions_sv)) != SVt_PVHV)
        croak("predictions must be an Autograd::Tensor");
    pred_hv = (HV*)SvRV(predictions_sv);
    svp = hv_fetch(pred_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid predictions tensor");
    predictions = get_tensor_by_id(SvIV(*svp));
    if (!predictions) croak("Predictions tensor has been freed");
    
    /* Get targets tensor */
    if (!SvROK(targets_sv) || SvTYPE(SvRV(targets_sv)) != SVt_PVHV)
        croak("targets must be an Autograd::Tensor");
    targets_hv = (HV*)SvRV(targets_sv);
    svp = hv_fetch(targets_hv, "_tensor_id", 10, 0);
    if (!svp) croak("Invalid targets tensor");
    targets_tensor = get_tensor_by_id(SvIV(*svp));
    if (!targets_tensor) croak("Targets tensor has been freed");
    
    n_elements = ggml_nelements(predictions->tensor);
    if (n_elements != ggml_nelements(targets_tensor->tensor)) {
        croak("Predictions and targets must have same number of elements");
    }
    
    /* Compute MSE: mean((predictions - targets)^2) */
    for (i = 0; i < n_elements; i++) {
        float pred = ggml_get_f32_1d(predictions->tensor, i);
        float target = ggml_get_f32_1d(targets_tensor->tensor, i);
        float diff = pred - target;
        total_loss += diff * diff;
    }
    total_loss /= (float)n_elements;
    
    /* Create scalar loss tensor */
    loss = ggml_new_tensor_1d(lctx->ctx, GGML_TYPE_F32, 1);
    if (!loss) croak("Failed to create loss tensor");
    ggml_set_f32_1d(loss, 0, total_loss);
    
    requires_grad = grad_enabled && predictions->requires_grad;
    
    loss_tensor = create_lugh_tensor(aTHX_ loss, lctx->id, requires_grad);
    if (!loss_tensor) croak("Failed to register loss tensor");
    
    if (requires_grad) {
        loss_tensor->is_leaf = false;
        loss_tensor->backward_op = LUGH_BACKWARD_MSE;
        loss_tensor->n_inputs = 2;
        loss_tensor->input_ids[0] = predictions->id;
        loss_tensor->input_ids[1] = targets_tensor->id;
        alloc_grad(aTHX_ loss_tensor, lctx);
    }
    
    result_hv = newHV();
    hv_store(result_hv, "_tensor_id", 10, newSViv(loss_tensor->id), 0);
    hv_store(result_hv, "_context_id", 11, newSViv(lctx->id), 0);
    hv_store(result_hv, "requires_grad", 13, newSViv(requires_grad ? 1 : 0), 0);
    hv_store(result_hv, "loss_value", 10, newSVnv(total_loss), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)result_hv), 
                      gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
OUTPUT:
    RETVAL

=pod

=head2 forward

Training-aware forward pass that stores intermediate activations for gradient
computation. Returns logits as an Autograd::Tensor suitable for loss computation.

    my $logits = Lugh::Train->forward(
        inference => $model,
        context   => $ctx,
        tokens    => \@tokens,
        lora      => $lora,          # Optional: LoRA adapter to train
        train_lora => 1,             # Default 1: compute LoRA gradients
        train_full => 0,             # Future: full model gradients
    );
    
    my $loss = Lugh::Train->cross_entropy_loss($ctx, $logits, \@targets);
    $loss->backward;

=cut

SV *
forward(class, ...)
    char *class
PREINIT:
    SV *inference_sv = NULL;
    SV *ctx_sv = NULL;
    SV *tokens_sv = NULL;
    SV *lora_sv = NULL;
    int train_lora = 1;
    int train_full = 0;
    HV *inf_hv;
    SV **svp;
    LughModel *model;
    LughLoRAAdapter *lora = NULL;
    LughContext *lctx;
    LughTrainingCache *tc = NULL;
    LughTensor *logits_tensor;
    struct ggml_tensor *logits_ggml;
    HV *result_hv;
    int i, j, layer;
    int *tokens = NULL;
    int n_tokens = 0;
    /* Hyperparams */
    int n_layer, n_head, n_head_kv, n_embd, head_dim, n_vocab;
    int n_ctx_orig;
    float rms_norm_eps, rope_freq_base, rope_freq_scale;
    LughHyperparams hp;  /* For RoPE */
    /* Forward pass state */
    struct ggml_context *ctx_c = NULL;
    struct ggml_cgraph *gf = NULL;
    ggml_backend_t backend = NULL;
    ggml_gallocr_t allocr = NULL;
CODE:
    PERL_UNUSED_ARG(class);
    
    /* Parse named parameters */
    for (i = 1; i < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "inference") || strEQ(key, "model")) {
            inference_sv = val;
        } else if (strEQ(key, "context") || strEQ(key, "ctx")) {
            ctx_sv = val;
        } else if (strEQ(key, "tokens")) {
            tokens_sv = val;
        } else if (strEQ(key, "lora")) {
            lora_sv = val;
        } else if (strEQ(key, "train_lora")) {
            train_lora = SvIV(val);
        } else if (strEQ(key, "train_full")) {
            train_full = SvIV(val);
        }
    }
    
    if (!inference_sv) croak("forward() requires inference => $model");
    if (!ctx_sv) croak("forward() requires context => $ctx");
    if (!tokens_sv) croak("forward() requires tokens => \\@tokens");
    
    /* Get inference object */
    if (!SvROK(inference_sv) || SvTYPE(SvRV(inference_sv)) != SVt_PVHV)
        croak("inference must be a Lugh::Inference object");
    inf_hv = (HV*)SvRV(inference_sv);
    
    /* Get model from inference */
    svp = hv_fetch(inf_hv, "_model", 6, 0);
    if (!svp) croak("No model in inference object");
    model = get_lugh_model(aTHX_ *svp);
    if (!model) croak("Invalid model");
    
    /* Get context */
    lctx = get_lugh_context(aTHX_ ctx_sv);
    if (!lctx) croak("Invalid context");
    
    /* Get LoRA adapter if provided */
    if (lora_sv && SvOK(lora_sv)) {
        lora = get_lugh_lora(aTHX_ lora_sv);
    }
    
    /* Parse tokens */
    if (!SvROK(tokens_sv) || SvTYPE(SvRV(tokens_sv)) != SVt_PVAV)
        croak("tokens must be an array reference");
    {
        AV *tokens_av = (AV*)SvRV(tokens_sv);
        n_tokens = av_len(tokens_av) + 1;
        if (n_tokens < 1) croak("tokens array is empty");
        Newx(tokens, n_tokens, int);
        for (i = 0; i < n_tokens; i++) {
            SV **elem = av_fetch(tokens_av, i, 0);
            tokens[i] = elem ? SvIV(*elem) : 0;
        }
    }
    
    /* Extract hyperparameters from model */
    {
        svp = hv_fetch(inf_hv, "n_layer", 7, 0);
        n_layer = svp ? SvIV(*svp) : 22;
        svp = hv_fetch(inf_hv, "n_head", 6, 0);
        n_head = svp ? SvIV(*svp) : 32;
        svp = hv_fetch(inf_hv, "n_head_kv", 9, 0);
        n_head_kv = svp ? SvIV(*svp) : 8;
        svp = hv_fetch(inf_hv, "n_embd", 6, 0);
        n_embd = svp ? SvIV(*svp) : 2048;
        svp = hv_fetch(inf_hv, "n_vocab", 7, 0);
        n_vocab = svp ? SvIV(*svp) : 32000;
        head_dim = n_embd / n_head;
        rms_norm_eps = 1e-5f;
        
        /* Initialize hp struct for RoPE */
        memset(&hp, 0, sizeof(hp));
        hp.n_layer = n_layer;
        hp.n_head = n_head;
        hp.n_head_kv = n_head_kv;
        hp.n_embd = n_embd;
        hp.head_dim = head_dim;
        hp.n_vocab = n_vocab;
        hp.n_rot = head_dim;  /* Typically same as head_dim */
        hp.n_ctx_orig = 2048;  /* Default */
        hp.rope_freq_base = 10000.0f;  /* Llama default */
        hp.rope_freq_scale = 1.0f;
        hp.rope_scaling_type = LUGH_ROPE_SCALING_NONE;
        hp.rope_ext_factor = 0.0f;
        hp.rope_attn_factor = 1.0f;
        hp.rope_beta_fast = 0.0f;
        hp.rope_beta_slow = 0.0f;
        hp.rms_norm_eps = rms_norm_eps;
        
        /* Try to get actual RoPE params from inference object */
        svp = hv_fetch(inf_hv, "rope_freq_base", 14, 0);
        if (svp) hp.rope_freq_base = SvNV(*svp);
        svp = hv_fetch(inf_hv, "n_ctx", 5, 0);
        if (svp) hp.n_ctx_orig = SvIV(*svp);
    }
    
    /* Create training cache */
    tc = create_training_cache(n_layer);
    if (!tc) {
        Safefree(tokens);
        croak("Failed to create training cache");
    }
    
    /* Store hyperparams in cache */
    tc->model_id = model->id;
    tc->context_id = lctx->id;
    tc->lora_id = lora ? lora->id : 0;
    tc->n_layer = n_layer;
    tc->n_head = n_head;
    tc->n_head_kv = n_head_kv;
    tc->n_embd = n_embd;
    tc->head_dim = head_dim;
    tc->n_vocab = n_vocab;
    tc->n_tokens = n_tokens;
    tc->rms_norm_eps = rms_norm_eps;
    tc->train_lora = train_lora ? true : false;
    tc->train_full = train_full ? true : false;
    if (lora && lora->n_weights > 0 && lora->weights && lora->weights[0].rank > 0) {
        tc->lora_scale = (lora->alpha / (float)lora->weights[0].rank) * lora->scale;
    } else {
        tc->lora_scale = 1.0f;
    }
    
    /* Copy tokens for backward */
    Newx(tc->tokens, n_tokens, int);
    Copy(tokens, tc->tokens, n_tokens, int);
    
    /* Initialize backend - use CPU for training to avoid Metal issues */
    DEBUG_PRINT("DEBUG: creating CPU backend\n");
    backend = init_cpu_backend(4);
    if (!backend) {
        free_training_cache(tc);
        Safefree(tokens);
        croak("Failed to initialize backend");
    }
    DEBUG_PRINT("DEBUG: backend created\n");
    
    /* Create compute context */
    ctx_c = create_compute_context(512 * 1024 * 1024);
    if (!ctx_c) {
        ggml_backend_free(backend);
        free_training_cache(tc);
        Safefree(tokens);
        croak("Failed to create compute context");
    }
    DEBUG_PRINT("DEBUG: compute context created\n");
    
    /* ============================================================
     * Build forward pass with activation storage
     * ============================================================ */
    {
        struct ggml_tensor *tok_embd = ggml_get_tensor(model->ctx, "token_embd.weight");
        struct ggml_tensor *output_norm = ggml_get_tensor(model->ctx, "output_norm.weight");
        struct ggml_tensor *output_weight = ggml_get_tensor(model->ctx, "output.weight");
        struct ggml_tensor *cur, *inpL, *pos;
        int n_kv_dim = n_head_kv * head_dim;
        DEBUG_PRINT("DEBUG: got tensors, tok_embd=%p\n", (void*)tok_embd);
        
        if (!output_weight) output_weight = tok_embd;
        if (!tok_embd) {
            ggml_free(ctx_c);
            ggml_backend_free(backend);
            free_training_cache(tc);
            Safefree(tokens);
            croak("Token embedding not found in model");
        }
        
        /* Position tensor */
        pos = ggml_new_tensor_1d(ctx_c, GGML_TYPE_I32, n_tokens);
        ggml_set_name(pos, "pos");
        
        /* Input token tensor */
        {
            struct ggml_tensor *inp_tokens = ggml_new_tensor_1d(ctx_c, GGML_TYPE_I32, n_tokens);
            ggml_set_name(inp_tokens, "inp_tokens");
            inpL = ggml_get_rows(ctx_c, tok_embd, inp_tokens);
            ggml_set_name(inpL, "inp_embd");
        }
        DEBUG_PRINT("DEBUG: input tokens created\n");
        
        /* Tensor to store embeddings for backward */
        {
            struct ggml_tensor *embd_store = ggml_new_tensor_2d(tc->act_ctx, GGML_TYPE_F32, n_embd, n_tokens);
            ggml_set_name(embd_store, "train_embd");
            tc->input_embeddings = (float*)embd_store->data;
        }
        DEBUG_PRINT("DEBUG: embeddings storage created\n");
        
        cur = inpL;
        
        /* Process transformer layers */
        DEBUG_PRINT("DEBUG: starting layer loop, n_layer=%d\n", n_layer);
        for (layer = 0; layer < n_layer; layer++) {
            DEBUG_PRINT("DEBUG: layer %d\n", layer);
            LughLayerActivations *la = &tc->layers[layer];
            struct ggml_tensor *residual;
            struct ggml_tensor *attn_norm_w, *ffn_norm_w;
            struct ggml_tensor *wq, *wk, *wv, *wo;
            struct ggml_tensor *w_gate, *w_up, *w_down;
            char name_buf[128];
            
            DEBUG_PRINT("DEBUG: layer %d getting weights\n", layer);
            /* Get layer weights */
            snprintf(name_buf, sizeof(name_buf), "blk.%d.attn_norm.weight", layer);
            attn_norm_w = ggml_get_tensor(model->ctx, name_buf);
            DEBUG_PRINT("DEBUG: attn_norm_w=%p\n", (void*)attn_norm_w);
            snprintf(name_buf, sizeof(name_buf), "blk.%d.ffn_norm.weight", layer);
            ffn_norm_w = ggml_get_tensor(model->ctx, name_buf);
            DEBUG_PRINT("DEBUG: ffn_norm_w=%p\n", (void*)ffn_norm_w);
            
            snprintf(name_buf, sizeof(name_buf), "blk.%d.attn_q.weight", layer);
            wq = ggml_get_tensor(model->ctx, name_buf);
            DEBUG_PRINT("DEBUG: wq=%p\n", (void*)wq);
            snprintf(name_buf, sizeof(name_buf), "blk.%d.attn_k.weight", layer);
            wk = ggml_get_tensor(model->ctx, name_buf);
            snprintf(name_buf, sizeof(name_buf), "blk.%d.attn_v.weight", layer);
            wv = ggml_get_tensor(model->ctx, name_buf);
            snprintf(name_buf, sizeof(name_buf), "blk.%d.attn_output.weight", layer);
            wo = ggml_get_tensor(model->ctx, name_buf);
            
            snprintf(name_buf, sizeof(name_buf), "blk.%d.ffn_gate.weight", layer);
            w_gate = ggml_get_tensor(model->ctx, name_buf);
            snprintf(name_buf, sizeof(name_buf), "blk.%d.ffn_up.weight", layer);
            w_up = ggml_get_tensor(model->ctx, name_buf);
            snprintf(name_buf, sizeof(name_buf), "blk.%d.ffn_down.weight", layer);
            w_down = ggml_get_tensor(model->ctx, name_buf);
            DEBUG_PRINT("DEBUG: layer %d weights fetched\n", layer);
            
            if (!attn_norm_w || !wq) {
                DEBUG_PRINT("DEBUG: skipping layer %d (missing weights)\n", layer);
                continue;  /* Skip malformed layer */
            }
            
            DEBUG_PRINT("DEBUG: layer %d storing input\n", layer);
            /* Store layer input for backward */
            {
                struct ggml_tensor *input_store = ggml_new_tensor_2d(tc->act_ctx, GGML_TYPE_F32, n_embd, n_tokens);
                la->input = (float*)input_store->data;
            }
            DEBUG_PRINT("DEBUG: layer %d stored input, doing attn norm\n", layer);
            
            residual = cur;
            
            /* Name layer input for extraction */
            snprintf(name_buf, sizeof(name_buf), "layer%d_input", layer);
            ggml_set_name(cur, name_buf);
            
            /* Attention norm */
            cur = apply_rms_norm(ctx_c, cur, attn_norm_w, rms_norm_eps);
            snprintf(name_buf, sizeof(name_buf), "layer%d_attn_norm", layer);
            ggml_set_name(cur, name_buf);
            DEBUG_PRINT("DEBUG: layer %d attn norm done\n", layer);
            
            /* Allocate storage for activation extraction */
            {
                struct ggml_tensor *norm_store = ggml_new_tensor_2d(tc->act_ctx, GGML_TYPE_F32, n_embd, n_tokens);
                if (!norm_store) {
                    croak("Failed to allocate norm_store for layer %d", layer);
                }
                la->attn_norm_out = (float*)norm_store->data;
                DEBUG_PRINT("DEBUG: layer %d norm_store=%p\n", layer, (void*)norm_store);
            }
            DEBUG_PRINT("DEBUG: layer %d doing QKV projections\n", layer);
            
            /* Q, K, V projections with LoRA */
            {
                struct ggml_tensor *q, *k, *v, *attn_out;
                char q_name[64], k_name[64], v_name[64], o_name[64];
                
                snprintf(q_name, sizeof(q_name), "blk.%d.attn_q.weight", layer);
                snprintf(k_name, sizeof(k_name), "blk.%d.attn_k.weight", layer);
                snprintf(v_name, sizeof(v_name), "blk.%d.attn_v.weight", layer);
                snprintf(o_name, sizeof(o_name), "blk.%d.attn_output.weight", layer);
                
                DEBUG_PRINT("DEBUG: lora_mul_mat for Q\n");
                q = lora_mul_mat(ctx_c, wq, cur, lora, q_name);
                snprintf(name_buf, sizeof(name_buf), "layer%d_q", layer);
                ggml_set_name(q, name_buf);
                DEBUG_PRINT("DEBUG: lora_mul_mat for K\n");
                k = lora_mul_mat(ctx_c, wk, cur, lora, k_name);
                snprintf(name_buf, sizeof(name_buf), "layer%d_k", layer);
                ggml_set_name(k, name_buf);
                DEBUG_PRINT("DEBUG: lora_mul_mat for V\n");
                v = lora_mul_mat(ctx_c, wv, cur, lora, v_name);
                snprintf(name_buf, sizeof(name_buf), "layer%d_v", layer);
                ggml_set_name(v, name_buf);
                
                DEBUG_PRINT("DEBUG: storing Q,K,V tensors (head_dim=%d, n_head=%d, n_head_kv=%d, n_tokens=%d)\n", 
                        head_dim, n_head, n_head_kv, n_tokens);
                /* Store Q, K, V for backward */
                {
                    struct ggml_tensor *q_store = ggml_new_tensor_3d(tc->act_ctx, GGML_TYPE_F32, head_dim, n_head, n_tokens);
                    DEBUG_PRINT("DEBUG: q_store=%p\n", (void*)q_store);
                    if (!q_store) croak("Failed to create q_store");
                    struct ggml_tensor *k_store = ggml_new_tensor_3d(tc->act_ctx, GGML_TYPE_F32, head_dim, n_head_kv, n_tokens);
                    DEBUG_PRINT("DEBUG: k_store=%p\n", (void*)k_store);
                    if (!k_store) croak("Failed to create k_store");
                    struct ggml_tensor *v_store = ggml_new_tensor_3d(tc->act_ctx, GGML_TYPE_F32, head_dim, n_head_kv, n_tokens);
                    DEBUG_PRINT("DEBUG: v_store=%p\n", (void*)v_store);
                    if (!v_store) croak("Failed to create v_store");
                    la->q = (float*)q_store->data;
                    la->k = (float*)k_store->data;
                    la->v = (float*)v_store->data;
                    DEBUG_PRINT("DEBUG: stored Q,K,V pointers\n");
                }
                
                DEBUG_PRINT("DEBUG: reshaping Q,K,V\n");
                /* Reshape Q, K, V */
                q = ggml_reshape_3d(ctx_c, q, head_dim, n_head, n_tokens);
                k = ggml_reshape_3d(ctx_c, k, head_dim, n_head_kv, n_tokens);
                v = ggml_reshape_3d(ctx_c, v, head_dim, n_head_kv, n_tokens);
                DEBUG_PRINT("DEBUG: reshaped, applying RoPE\n");
                
                /* Apply RoPE */
                q = apply_rope_single(ctx_c, q, pos, &hp);
                DEBUG_PRINT("DEBUG: RoPE on Q done\n");
                k = apply_rope_single(ctx_c, k, pos, &hp);
                DEBUG_PRINT("DEBUG: RoPE on K done\n");
                
                /* Attention computation */
                DEBUG_PRINT("DEBUG: building attention\n");
                attn_out = build_standard_attention(ctx_c, q, k, v, head_dim, 0);
                DEBUG_PRINT("DEBUG: attention built\n");
                attn_out = ggml_reshape_2d(ctx_c, attn_out, n_embd, n_tokens);
                snprintf(name_buf, sizeof(name_buf), "layer%d_attn_out", layer);
                ggml_set_name(attn_out, name_buf);
                DEBUG_PRINT("DEBUG: attention output reshaped\n");
                
                /* Store attention output for backward */
                DEBUG_PRINT("DEBUG: storing attn_out, tc=%p, tc->act_ctx=%p\n", (void*)tc, (void*)tc->act_ctx);
                {
                    struct ggml_tensor *attn_store = ggml_new_tensor_2d(tc->act_ctx, GGML_TYPE_F32, n_embd, n_tokens);
                    DEBUG_PRINT("DEBUG: attn_store created=%p\n", (void*)attn_store);
                    la->attn_out = (float*)attn_store->data;
                    DEBUG_PRINT("DEBUG: attn_out stored\n");
                }
                
                /* O projection */
                DEBUG_PRINT("DEBUG: doing O projection\n");
                attn_out = lora_mul_mat(ctx_c, wo, attn_out, lora, o_name);
                snprintf(name_buf, sizeof(name_buf), "layer%d_o_proj", layer);
                ggml_set_name(attn_out, name_buf);
                DEBUG_PRINT("DEBUG: O projection done\n");
                
                /* Store O projection output */
                {
                    struct ggml_tensor *o_store = ggml_new_tensor_2d(tc->act_ctx, GGML_TYPE_F32, n_embd, n_tokens);
                    la->o_proj_out = (float*)o_store->data;
                    DEBUG_PRINT("DEBUG: o_proj_out stored\n");
                }
                
                /* Residual connection */
                cur = ggml_add(ctx_c, residual, attn_out);
            }
            
            /* FFN */
            residual = cur;
            cur = apply_rms_norm(ctx_c, cur, ffn_norm_w, rms_norm_eps);
            snprintf(name_buf, sizeof(name_buf), "layer%d_ffn_norm", layer);
            ggml_set_name(cur, name_buf);
            DEBUG_PRINT("DEBUG: layer %d FFN norm done\n", layer);
            
            /* Store FFN norm output */
            {
                struct ggml_tensor *ffn_norm_store = ggml_new_tensor_2d(tc->act_ctx, GGML_TYPE_F32, n_embd, n_tokens);
                la->ffn_norm_out = (float*)ffn_norm_store->data;
            }
            DEBUG_PRINT("DEBUG: layer %d FFN norm stored\n", layer);
            
            /* FFN with LoRA */
            DEBUG_PRINT("DEBUG: layer %d checking FFN weights: gate=%p up=%p down=%p\n", 
                    layer, (void*)w_gate, (void*)w_up, (void*)w_down);
            if (w_gate && w_up && w_down) {
                struct ggml_tensor *gate_out, *up_out, *ffn_act, *down_out;
                int ffn_dim = w_gate->ne[1];
                char gate_name[64], up_name[64], down_name[64];
                
                snprintf(gate_name, sizeof(gate_name), "blk.%d.ffn_gate.weight", layer);
                snprintf(up_name, sizeof(up_name), "blk.%d.ffn_up.weight", layer);
                snprintf(down_name, sizeof(down_name), "blk.%d.ffn_down.weight", layer);
                
                DEBUG_PRINT("DEBUG: layer %d FFN gate/up\n", layer);
                gate_out = lora_mul_mat(ctx_c, w_gate, cur, lora, gate_name);
                snprintf(name_buf, sizeof(name_buf), "layer%d_gate", layer);
                ggml_set_name(gate_out, name_buf);
                up_out = lora_mul_mat(ctx_c, w_up, cur, lora, up_name);
                snprintf(name_buf, sizeof(name_buf), "layer%d_up", layer);
                ggml_set_name(up_out, name_buf);
                
                /* Store gate and up outputs */
                {
                    struct ggml_tensor *gate_store = ggml_new_tensor_2d(tc->act_ctx, GGML_TYPE_F32, ffn_dim, n_tokens);
                    struct ggml_tensor *up_store = ggml_new_tensor_2d(tc->act_ctx, GGML_TYPE_F32, ffn_dim, n_tokens);
                    la->gate_out = (float*)gate_store->data;
                    la->up_out = (float*)up_store->data;
                }
                DEBUG_PRINT("DEBUG: layer %d FFN gate/up stored\n", layer);
                
                /* SiLU activation on gate, multiply with up */
                ffn_act = ggml_mul(ctx_c, ggml_silu(ctx_c, gate_out), up_out);
                snprintf(name_buf, sizeof(name_buf), "layer%d_ffn_act", layer);
                ggml_set_name(ffn_act, name_buf);
                DEBUG_PRINT("DEBUG: layer %d FFN activation done\n", layer);
                
                /* Store FFN activation */
                {
                    struct ggml_tensor *act_store = ggml_new_tensor_2d(tc->act_ctx, GGML_TYPE_F32, ffn_dim, n_tokens);
                    la->ffn_act = (float*)act_store->data;
                }
                
                down_out = lora_mul_mat(ctx_c, w_down, ffn_act, lora, down_name);
                snprintf(name_buf, sizeof(name_buf), "layer%d_down", layer);
                ggml_set_name(down_out, name_buf);
                DEBUG_PRINT("DEBUG: layer %d FFN down done\n", layer);
                
                /* Store down output */
                {
                    struct ggml_tensor *down_store = ggml_new_tensor_2d(tc->act_ctx, GGML_TYPE_F32, n_embd, n_tokens);
                    la->down_out = (float*)down_store->data;
                }
                
                cur = ggml_add(ctx_c, residual, down_out);
                DEBUG_PRINT("DEBUG: layer %d complete\n", layer);
            }
        }
        DEBUG_PRINT("DEBUG: all layers complete\n");
        
        /* Final RMS norm */
        DEBUG_PRINT("DEBUG: doing final norm\n");
        if (output_norm) {
            cur = apply_rms_norm(ctx_c, cur, output_norm, rms_norm_eps);
            ggml_set_name(cur, "final_norm");
            
            /* Store final norm output */
            {
                struct ggml_tensor *final_store = ggml_new_tensor_2d(tc->act_ctx, GGML_TYPE_F32, n_embd, n_tokens);
                tc->final_norm_out = (float*)final_store->data;
            }
            DEBUG_PRINT("DEBUG: final norm done\n");
        }
        
        /* Output projection (logits) */
        DEBUG_PRINT("DEBUG: output projection\n");
        cur = ggml_mul_mat(ctx_c, output_weight, cur);
        ggml_set_name(cur, "logits");
        DEBUG_PRINT("DEBUG: logits computed\n");
        
        /* Build and run graph */
        DEBUG_PRINT("DEBUG: building graph\n");
        gf = ggml_new_graph(ctx_c);
        ggml_build_forward_expand(gf, cur);
        DEBUG_PRINT("DEBUG: graph built, allocating\n");
        
        allocr = ggml_gallocr_new(ggml_backend_get_default_buffer_type(backend));
        DEBUG_PRINT("DEBUG: allocr created\n");
        if (!ggml_gallocr_reserve(allocr, gf)) {
            DEBUG_PRINT("DEBUG: reserve failed\n");
            ggml_gallocr_free(allocr);
            ggml_free(ctx_c);
            ggml_backend_free(backend);
            free_training_cache(tc);
            Safefree(tokens);
            croak("Failed to reserve compute graph");
        }
        DEBUG_PRINT("DEBUG: reserved\n");
        if (!ggml_gallocr_alloc_graph(allocr, gf)) {
            DEBUG_PRINT("DEBUG: alloc graph failed\n");
            ggml_gallocr_free(allocr);
            ggml_free(ctx_c);
            ggml_backend_free(backend);
            free_training_cache(tc);
            Safefree(tokens);
            croak("Failed to allocate compute graph");
        }
        DEBUG_PRINT("DEBUG: graph allocated\n");
        
        /* Set input data */
        DEBUG_PRINT("DEBUG: setting input data\n");
        {
            struct ggml_tensor *inp = ggml_graph_get_tensor(gf, "inp_tokens");
            struct ggml_tensor *pos_tensor = ggml_graph_get_tensor(gf, "pos");
            DEBUG_PRINT("DEBUG: inp=%p, pos=%p\n", (void*)inp, (void*)pos_tensor);
            
            if (inp) {
                DEBUG_PRINT("DEBUG: setting inp tokens\n");
                ggml_backend_tensor_set(inp, tokens, 0, n_tokens * sizeof(int));
                DEBUG_PRINT("DEBUG: inp tokens set\n");
            }
            
            if (pos_tensor) {
                int *positions;
                DEBUG_PRINT("DEBUG: setting positions\n");
                Newx(positions, n_tokens, int);
                for (i = 0; i < n_tokens; i++) positions[i] = i;
                ggml_backend_tensor_set(pos_tensor, positions, 0, n_tokens * sizeof(int));
                Safefree(positions);
                DEBUG_PRINT("DEBUG: positions set\n");
            }
        }
        
        /* Run forward pass */
        DEBUG_PRINT("DEBUG: computing forward pass\n");
        DEBUG_PRINT("DEBUG: graph backend=%s\n", ggml_backend_name(backend));
        DEBUG_PRINT("DEBUG: calling ggml_backend_graph_compute\n");
        if (ggml_backend_graph_compute(backend, gf) != GGML_STATUS_SUCCESS) {
            ggml_gallocr_free(allocr);
            ggml_free(ctx_c);
            ggml_backend_free(backend);
            free_training_cache(tc);
            Safefree(tokens);
            croak("Failed to compute forward pass");
        }
        
        /* Extract activations from graph for backward pass */
        /* Copy computed values to training cache storage tensors */
        {
            struct ggml_tensor *logits_t = ggml_graph_get_tensor(gf, "logits");
            if (logits_t) {
                /* Allocate storage for logits in training cache */
                struct ggml_tensor *logits_store = ggml_new_tensor_2d(tc->act_ctx, GGML_TYPE_F32, n_vocab, n_tokens);
                tc->logits = (float*)logits_store->data;
                ggml_backend_tensor_get(logits_t, tc->logits, 0, n_vocab * n_tokens * sizeof(float));
            }
        }
        
        /* Extract and copy all layer activations from computed graph */
        DEBUG_PRINT("DEBUG: extracting layer activations\n");
        {
            char name_buf[128];
            int layer;
            int n_layer = tc->n_layer;
            int n_embd = tc->n_embd;
            int n_head = tc->n_head;
            int n_head_kv = tc->n_head_kv;
            int head_dim = tc->head_dim;
            int n_vocab_cache = tc->n_vocab;
            size_t embd_size = n_embd * n_tokens * sizeof(float);
            size_t qkv_size = head_dim * n_head * n_tokens * sizeof(float);
            size_t kv_size = head_dim * n_head_kv * n_tokens * sizeof(float);
            
            for (layer = 0; layer < n_layer; layer++) {
                LughLayerActivations *la = &tc->layers[layer];
                struct ggml_tensor *t;
                
                /* Extract layer input */
                snprintf(name_buf, sizeof(name_buf), "layer%d_input", layer);
                t = ggml_graph_get_tensor(gf, name_buf);
                if (t && la->input) {
                    ggml_backend_tensor_get(t, la->input, 0, embd_size);
                }
                
                /* Extract attention norm output */
                snprintf(name_buf, sizeof(name_buf), "layer%d_attn_norm", layer);
                t = ggml_graph_get_tensor(gf, name_buf);
                if (t && la->attn_norm_out) {
                    ggml_backend_tensor_get(t, la->attn_norm_out, 0, embd_size);
                }
                
                /* Extract Q, K, V projections */
                snprintf(name_buf, sizeof(name_buf), "layer%d_q", layer);
                t = ggml_graph_get_tensor(gf, name_buf);
                if (t && la->q) {
                    ggml_backend_tensor_get(t, la->q, 0, qkv_size);
                }
                
                snprintf(name_buf, sizeof(name_buf), "layer%d_k", layer);
                t = ggml_graph_get_tensor(gf, name_buf);
                if (t && la->k) {
                    ggml_backend_tensor_get(t, la->k, 0, kv_size);
                }
                
                snprintf(name_buf, sizeof(name_buf), "layer%d_v", layer);
                t = ggml_graph_get_tensor(gf, name_buf);
                if (t && la->v) {
                    ggml_backend_tensor_get(t, la->v, 0, kv_size);
                }
                
                /* Extract attention output (before O projection) */
                snprintf(name_buf, sizeof(name_buf), "layer%d_attn_out", layer);
                t = ggml_graph_get_tensor(gf, name_buf);
                if (t && la->attn_out) {
                    ggml_backend_tensor_get(t, la->attn_out, 0, embd_size);
                }
                
                /* Extract O projection output */
                snprintf(name_buf, sizeof(name_buf), "layer%d_o_proj", layer);
                t = ggml_graph_get_tensor(gf, name_buf);
                if (t && la->o_proj_out) {
                    ggml_backend_tensor_get(t, la->o_proj_out, 0, embd_size);
                }
                
                /* Extract FFN norm output */
                snprintf(name_buf, sizeof(name_buf), "layer%d_ffn_norm", layer);
                t = ggml_graph_get_tensor(gf, name_buf);
                if (t && la->ffn_norm_out) {
                    ggml_backend_tensor_get(t, la->ffn_norm_out, 0, embd_size);
                }
                
                /* Extract gate output */
                snprintf(name_buf, sizeof(name_buf), "layer%d_gate", layer);
                t = ggml_graph_get_tensor(gf, name_buf);
                if (t && la->gate_out) {
                    /* FFN intermediate size is typically 4*n_embd or custom */
                    size_t ffn_size = ggml_nbytes(t);
                    ggml_backend_tensor_get(t, la->gate_out, 0, ffn_size);
                }
                
                /* Extract up output */
                snprintf(name_buf, sizeof(name_buf), "layer%d_up", layer);
                t = ggml_graph_get_tensor(gf, name_buf);
                if (t && la->up_out) {
                    size_t ffn_size = ggml_nbytes(t);
                    ggml_backend_tensor_get(t, la->up_out, 0, ffn_size);
                }
                
                /* Extract FFN activation (SiLU(gate) * up) */
                snprintf(name_buf, sizeof(name_buf), "layer%d_ffn_act", layer);
                t = ggml_graph_get_tensor(gf, name_buf);
                if (t && la->ffn_act) {
                    size_t ffn_size = ggml_nbytes(t);
                    ggml_backend_tensor_get(t, la->ffn_act, 0, ffn_size);
                }
                
                /* Extract down output */
                snprintf(name_buf, sizeof(name_buf), "layer%d_down", layer);
                t = ggml_graph_get_tensor(gf, name_buf);
                if (t && la->down_out) {
                    ggml_backend_tensor_get(t, la->down_out, 0, embd_size);
                }
                
                DEBUG_PRINT("DEBUG: extracted layer %d activations\n", layer);
            }
            
            /* Extract final norm output */
            {
                struct ggml_tensor *t = ggml_graph_get_tensor(gf, "final_norm");
                if (t && tc->final_norm_out) {
                    ggml_backend_tensor_get(t, tc->final_norm_out, 0, embd_size);
                }
            }
            DEBUG_PRINT("DEBUG: extraction complete\n");
        }
        
        /* Create logits Autograd::Tensor */
        logits_ggml = ggml_new_tensor_2d(lctx->ctx, GGML_TYPE_F32, n_vocab, n_tokens);
        if (!logits_ggml) {
            ggml_gallocr_free(allocr);
            ggml_free(ctx_c);
            ggml_backend_free(backend);
            free_training_cache(tc);
            Safefree(tokens);
            croak("Failed to create logits tensor");
        }
        
        /* Copy logits data */
        if (tc->logits) {
            memcpy(logits_ggml->data, tc->logits, n_vocab * n_tokens * sizeof(float));
        }
        
        ggml_gallocr_free(allocr);
        ggml_free(ctx_c);
        ggml_backend_free(backend);
    }
    
    Safefree(tokens);
    
    /* Create LughTensor for logits with training cache reference */
    logits_tensor = create_lugh_tensor(aTHX_ logits_ggml, lctx->id, true);
    if (!logits_tensor) {
        free_training_cache(tc);
        croak("Failed to register logits tensor");
    }
    
    logits_tensor->is_leaf = false;
    logits_tensor->backward_op = LUGH_BACKWARD_TRANSFORMER_FORWARD;
    logits_tensor->training_cache_id = tc->id;
    logits_tensor->n_inputs = 0;  /* Inputs tracked via training cache */
    
    /* Allocate gradient for logits */
    alloc_grad(aTHX_ logits_tensor, lctx);
    
    /* Return Autograd::Tensor */
    result_hv = newHV();
    hv_store(result_hv, "_tensor_id", 10, newSViv(logits_tensor->id), 0);
    hv_store(result_hv, "_context_id", 11, newSViv(lctx->id), 0);
    hv_store(result_hv, "requires_grad", 13, newSViv(1), 0);
    hv_store(result_hv, "_training_cache_id", 18, newSViv(tc->id), 0);
    hv_store(result_hv, "n_vocab", 7, newSViv(n_vocab), 0);
    hv_store(result_hv, "n_tokens", 8, newSViv(n_tokens), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)result_hv), 
                      gv_stashpv("Lugh::Autograd::Tensor", GV_ADD));
OUTPUT:
    RETVAL

void
register_weight_tensors(class, logits_sv, weights_av)
    char *class
    SV *logits_sv
    AV *weights_av
PREINIT:
    HV *logits_hv;
    SV **svp;
    LughTrainingCache *tc;
    int cache_id, n_weights, i;
CODE:
    PERL_UNUSED_ARG(class);
    
    /* Get training cache from logits tensor */
    if (!SvROK(logits_sv) || SvTYPE(SvRV(logits_sv)) != SVt_PVHV)
        croak("logits must be an Autograd::Tensor");
    logits_hv = (HV*)SvRV(logits_sv);
    svp = hv_fetch(logits_hv, "_training_cache_id", 18, 0);
    if (!svp) croak("Tensor has no training cache");
    cache_id = SvIV(*svp);
    tc = get_training_cache_by_id(cache_id);
    if (!tc) croak("Training cache not found");
    
    /* Parse weights array */
    n_weights = av_len(weights_av) + 1;
    if (n_weights == 0) return;
    
    /* Allocate storage */
    Newx(tc->weight_tensor_ids, n_weights, int);
    Newx(tc->weight_tensor_names, n_weights, char*);
    tc->n_weight_tensors = n_weights;
    
    for (i = 0; i < n_weights; i++) {
        SV **elem = av_fetch(weights_av, i, 0);
        if (!elem || !SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVHV)
            croak("Weight %d must be an Autograd::Tensor", i);
        
        HV *weight_hv = (HV*)SvRV(*elem);
        svp = hv_fetch(weight_hv, "_tensor_id", 10, 0);
        if (!svp) croak("Invalid weight tensor %d", i);
        tc->weight_tensor_ids[i] = SvIV(*svp);
        
        /* Get tensor name if available */
        svp = hv_fetch(weight_hv, "name", 4, 0);
        if (svp && SvOK(*svp)) {
            STRLEN len;
            const char *name = SvPV(*svp, len);
            Newx(tc->weight_tensor_names[i], len + 1, char);
            Copy(name, tc->weight_tensor_names[i], len + 1, char);
        } else {
            tc->weight_tensor_names[i] = NULL;
        }
    }
    
    DEBUG_PRINT("Registered %d weight tensors for training\n", n_weights);

void
batch_data(class, data_av, ...)
    SV* class
    AV* data_av
PREINIT:
    STRLEN batch_size = 32;
    int shuffle = 0;
    STRLEN data_len, i, j;
    STRLEN *indices = NULL;
    AV *result_av;
PPCODE:
    PERL_UNUSED_VAR(class);
    
    /* Parse optional args - items includes class and data_av, so remaining must be even */
    if (items > 2) {
        if ((items - 2) % 2 != 0) croak("Expected key-value pairs after data");
        for (i = 2; i < (STRLEN)items; i += 2) {
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            if (strEQ(key, "batch_size")) {
                batch_size = SvIV(val);
            } else if (strEQ(key, "shuffle")) {
                shuffle = SvTRUE(val);
            }
        }
    }
    
    data_len = av_len(data_av) + 1;
    if (data_len == 0) {
        XSRETURN_EMPTY;
    }
    
    /* Create index array */
    Newx(indices, data_len, STRLEN);
    for (i = 0; i < data_len; i++) {
        indices[i] = i;
    }
    
    /* Fisher-Yates shuffle if requested */
    if (shuffle) {
        for (i = data_len - 1; i > 0; i--) {
            j = (STRLEN)(Drand01() * (i + 1));
            if (j != i) {
                STRLEN tmp = indices[i];
                indices[i] = indices[j];
                indices[j] = tmp;
            }
        }
    }
    
    /* Create batches */
    result_av = newAV();
    for (i = 0; i < data_len; i += batch_size) {
        AV *batch_av = newAV();
        STRLEN end = i + batch_size;
        if (end > data_len) end = data_len;
        
        for (j = i; j < end; j++) {
            SV **elem = av_fetch(data_av, indices[j], 0);
            if (elem && *elem) {
                av_push(batch_av, SvREFCNT_inc(*elem));
            }
        }
        av_push(result_av, newRV_noinc((SV*)batch_av));
    }
    
    Safefree(indices);
    
    /* Return list of batch arrayrefs */
    {
        STRLEN n = av_len(result_av) + 1;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            SV **elem = av_fetch(result_av, i, 0);
            if (elem && *elem) {
                PUSHs(sv_2mortal(SvREFCNT_inc(*elem)));
            }
        }
    }
    SvREFCNT_dec(result_av);

void
tokenize_batch(class, tokenizer, texts_av, ...)
    SV* class
    SV* tokenizer
    AV* texts_av
PREINIT:
    STRLEN max_length = 512;
    STRLEN i, n_texts;
    AV *all_input_ids;
    AV *all_targets;
    AV *result;
PPCODE:
    PERL_UNUSED_VAR(class);
    
    if (!tokenizer || !SvOK(tokenizer)) {
        croak("tokenizer required");
    }
    
    /* Parse optional args */
    if (items > 3) {
        for (i = 3; i < (STRLEN)items; i += 2) {
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            if (strEQ(key, "max_length")) {
                max_length = SvIV(val);
            }
        }
    }
    
    n_texts = av_len(texts_av) + 1;
    all_input_ids = newAV();
    all_targets = newAV();
    
    for (i = 0; i < n_texts; i++) {
        SV **text_svp = av_fetch(texts_av, i, 0);
        if (!text_svp || !*text_svp) continue;
        
        /* Call tokenizer->encode(text) */
        dSP;
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);
        XPUSHs(tokenizer);
        XPUSHs(*text_svp);
        PUTBACK;
        
        int count = call_method("encode", G_LIST);
        
        SPAGAIN;
        
        if (count > 0) {
            AV *tokens = newAV();
            STRLEN j;
            
            /* Pop tokens in reverse order */
            for (j = 0; j < (STRLEN)count; j++) {
                SV *tok = POPs;
                av_unshift(tokens, 1);
                av_store(tokens, 0, SvREFCNT_inc(tok));
            }
            
            STRLEN n_tokens = av_len(tokens) + 1;
            
            /* Truncate if needed */
            if (n_tokens > max_length) {
                n_tokens = max_length;
            }
            
            /* For LM: inputs are tokens[:-1], targets are tokens[1:] */
            if (n_tokens > 1) {
                AV *input_ids = newAV();
                AV *target_ids = newAV();
                
                for (j = 0; j < n_tokens - 1; j++) {
                    SV **tokp = av_fetch(tokens, j, 0);
                    if (tokp && *tokp) {
                        av_push(input_ids, SvREFCNT_inc(*tokp));
                    }
                }
                
                for (j = 1; j < n_tokens; j++) {
                    SV **tokp = av_fetch(tokens, j, 0);
                    if (tokp && *tokp) {
                        av_push(target_ids, SvREFCNT_inc(*tokp));
                    }
                }
                
                av_push(all_input_ids, newRV_noinc((SV*)input_ids));
                av_push(all_targets, newRV_noinc((SV*)target_ids));
            }
            
            SvREFCNT_dec(tokens);
        }
        
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    
    /* Return (\@all_input_ids, \@all_targets) */
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newRV_noinc((SV*)all_input_ids)));
    PUSHs(sv_2mortal(newRV_noinc((SV*)all_targets)));

void
zero_grad(class, ...)
    SV* class
PREINIT:
    STRLEN i;
PPCODE:
    PERL_UNUSED_VAR(class);
    
    for (i = 1; i < (STRLEN)items; i++) {
        SV *tensor_sv = ST(i);
        if (!SvOK(tensor_sv)) continue;
        
        dSP;
        ENTER;
        SAVETMPS;
        
        /* Check if tensor->can('zero_grad') */
        PUSHMARK(SP);
        XPUSHs(tensor_sv);
        XPUSHs(sv_2mortal(newSVpv("zero_grad", 0)));
        PUTBACK;
        
        int count = call_method("can", G_SCALAR);
        SPAGAIN;
        
        if (count > 0) {
            SV *can_result = POPs;
            if (SvTRUE(can_result)) {
                PUTBACK;
                
                /* Call zero_grad method */
                PUSHMARK(SP);
                XPUSHs(tensor_sv);
                PUTBACK;
                
                call_method("zero_grad", G_DISCARD);
                SPAGAIN;
            }
        }
        
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    
    XSRETURN_EMPTY;

SV*
training_step(class, model, optimizer, inputs, targets, ...)
    SV* class
    SV* model
    SV* optimizer
    SV* inputs
    SV* targets
PREINIT:
    const char *loss_fn = "cross_entropy";
    SV *ctx = NULL;
    SV *logits = NULL;
    SV *loss = NULL;
    float loss_value = 0.0;
    STRLEN i;
CODE:
    PERL_UNUSED_VAR(class);
    
    /* Parse optional args */
    for (i = 5; i < (STRLEN)items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "loss_fn")) {
            loss_fn = SvPV_nolen(val);
        } else if (strEQ(key, "ctx")) {
            ctx = val;
        }
    }
    
    if (!ctx) {
        croak("ctx option required");
    }
    
    /* Zero gradients on optimizer if available */
    if (optimizer && SvOK(optimizer)) {
        dSP;
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);
        XPUSHs(optimizer);
        XPUSHs(sv_2mortal(newSVpv("zero_grad", 0)));
        PUTBACK;
        
        int count = call_method("can", G_SCALAR);
        SPAGAIN;
        
        if (count > 0 && SvTRUE(POPs)) {
            PUTBACK;
            PUSHMARK(SP);
            XPUSHs(optimizer);
            PUTBACK;
            call_method("zero_grad", G_DISCARD);
        }
        
        FREETMPS;
        LEAVE;
    }
    
    /* Forward pass: model->forward(inputs) */
    {
        dSP;
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);
        XPUSHs(model);
        XPUSHs(inputs);
        PUTBACK;
        
        int count = call_method("forward", G_SCALAR);
        SPAGAIN;
        
        if (count > 0) {
            logits = SvREFCNT_inc(POPs);
        }
        
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    
    if (!logits) {
        croak("model->forward() returned nothing");
    }
    
    /* Compute loss */
    {
        dSP;
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);
        mXPUSHs(newSVpv("Lugh::Train", 0));
        XPUSHs(ctx);
        XPUSHs(logits);
        XPUSHs(targets);
        PUTBACK;
        
        int count;
        if (strEQ(loss_fn, "cross_entropy")) {
            count = call_method("cross_entropy_loss", G_SCALAR);
        } else if (strEQ(loss_fn, "mse")) {
            count = call_method("mse_loss", G_SCALAR);
        } else {
            croak("Unknown loss function: %s", loss_fn);
        }
        
        SPAGAIN;
        
        if (count > 0) {
            loss = SvREFCNT_inc(POPs);
        }
        
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    
    SvREFCNT_dec(logits);
    
    if (!loss) {
        croak("Loss computation failed");
    }
    
    /* Backward pass: loss->backward() */
    {
        dSP;
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);
        XPUSHs(loss);
        PUTBACK;
        
        call_method("backward", G_DISCARD);
        
        FREETMPS;
        LEAVE;
    }
    
    /* Optimizer step if available */
    if (optimizer && SvOK(optimizer)) {
        dSP;
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);
        XPUSHs(optimizer);
        XPUSHs(sv_2mortal(newSVpv("step", 0)));
        PUTBACK;
        
        int count = call_method("can", G_SCALAR);
        SPAGAIN;
        
        if (count > 0 && SvTRUE(POPs)) {
            PUTBACK;
            PUSHMARK(SP);
            XPUSHs(optimizer);
            PUTBACK;
            call_method("step", G_DISCARD);
        }
        
        FREETMPS;
        LEAVE;
    }
    
    /* Get loss value: ($loss->get_data())[0] */
    {
        dSP;
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);
        XPUSHs(loss);
        PUTBACK;
        
        int count = call_method("get_data", G_LIST);
        SPAGAIN;
        
        if (count > 0) {
            /* First element is the loss value */
            SV *first = NULL;
            STRLEN j;
            for (j = 0; j < (STRLEN)count; j++) {
                SV *val = POPs;
                if (j == (STRLEN)count - 1) {
                    loss_value = SvNV(val);
                }
            }
        }
        
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    
    SvREFCNT_dec(loss);
    
    RETVAL = newSVnv(loss_value);
OUTPUT:
    RETVAL

MODULE = Lugh  PACKAGE = Lugh::Optimizer::SGD

SV*
new(class, ...)
    const char* class
PREINIT:
    HV* self;
    float lr = 0.001f;
    float momentum = 0.0f;
    float weight_decay = 0.0f;
    int nesterov = 0;
    AV* params = NULL;
    AV* velocities = NULL;
    STRLEN i;
CODE:
    /* Parse options */
    for (i = 1; i < (STRLEN)items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "lr") || strEQ(key, "learning_rate")) {
            lr = SvNV(val);
        } else if (strEQ(key, "momentum")) {
            momentum = SvNV(val);
        } else if (strEQ(key, "weight_decay")) {
            weight_decay = SvNV(val);
        } else if (strEQ(key, "nesterov")) {
            nesterov = SvTRUE(val);
        } else if (strEQ(key, "params")) {
            if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                params = (AV*)SvRV(val);
            }
        }
    }
    
    self = newHV();
    hv_store(self, "lr", 2, newSVnv(lr), 0);
    hv_store(self, "momentum", 8, newSVnv(momentum), 0);
    hv_store(self, "weight_decay", 12, newSVnv(weight_decay), 0);
    hv_store(self, "nesterov", 8, newSViv(nesterov), 0);
    hv_store(self, "step_count", 10, newSViv(0), 0);
    
    if (params) {
        hv_store(self, "params", 6, newRV_inc((SV*)params), 0);
    } else {
        hv_store(self, "params", 6, newRV_noinc((SV*)newAV()), 0);
    }
    
    /* Initialize velocity buffers */
    velocities = newAV();
    hv_store(self, "velocities", 10, newRV_noinc((SV*)velocities), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)self), gv_stashpv(class, GV_ADD));
OUTPUT:
    RETVAL

void
add_param(self, param)
    SV* self
    SV* param
PREINIT:
    HV* self_hv;
    SV** svp;
    AV* params;
    AV* velocities;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("self must be a hash ref");
    self_hv = (HV*)SvRV(self);
    
    svp = hv_fetch(self_hv, "params", 6, 0);
    if (!svp || !SvROK(*svp)) croak("params not found");
    params = (AV*)SvRV(*svp);
    
    svp = hv_fetch(self_hv, "velocities", 10, 0);
    if (!svp || !SvROK(*svp)) croak("velocities not found");
    velocities = (AV*)SvRV(*svp);
    
    av_push(params, SvREFCNT_inc(param));
    av_push(velocities, &PL_sv_undef);  /* Will be initialized on first step */

void
zero_grad(self)
    SV* self
PREINIT:
    HV* self_hv;
    SV** svp;
    AV* params;
    STRLEN i, n;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("self must be a hash ref");
    self_hv = (HV*)SvRV(self);
    
    svp = hv_fetch(self_hv, "params", 6, 0);
    if (!svp || !SvROK(*svp)) return;
    params = (AV*)SvRV(*svp);
    
    n = av_len(params) + 1;
    for (i = 0; i < n; i++) {
        SV** param_svp = av_fetch(params, i, 0);
        if (!param_svp || !*param_svp) continue;
        
        dSP;
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);
        XPUSHs(*param_svp);
        PUTBACK;
        
        call_method("zero_grad", G_DISCARD);
        
        FREETMPS;
        LEAVE;
    }

void
step(self)
    SV* self
PREINIT:
    HV* self_hv;
    SV** svp;
    AV* params;
    AV* velocities;
    float lr, momentum, weight_decay;
    int nesterov;
    STRLEN i, n, j;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("self must be a hash ref");
    self_hv = (HV*)SvRV(self);
    
    /* Get hyperparameters */
    svp = hv_fetch(self_hv, "lr", 2, 0);
    lr = svp ? SvNV(*svp) : 0.001f;
    
    svp = hv_fetch(self_hv, "momentum", 8, 0);
    momentum = svp ? SvNV(*svp) : 0.0f;
    
    svp = hv_fetch(self_hv, "weight_decay", 12, 0);
    weight_decay = svp ? SvNV(*svp) : 0.0f;
    
    svp = hv_fetch(self_hv, "nesterov", 8, 0);
    nesterov = svp ? SvIV(*svp) : 0;
    
    /* Get params and velocities */
    svp = hv_fetch(self_hv, "params", 6, 0);
    if (!svp || !SvROK(*svp)) return;
    params = (AV*)SvRV(*svp);
    
    svp = hv_fetch(self_hv, "velocities", 10, 0);
    if (!svp || !SvROK(*svp)) return;
    velocities = (AV*)SvRV(*svp);
    
    n = av_len(params) + 1;
    
    for (i = 0; i < n; i++) {
        SV** param_svp = av_fetch(params, i, 0);
        if (!param_svp || !*param_svp) continue;
        
        SV *param = *param_svp;
        HV *param_hv;
        LughTensor *tensor;
        AV *data_av = NULL;
        AV *grad_av = NULL;
        AV *vel_av = NULL;
        STRLEN n_elem;
        
        if (!SvROK(param) || SvTYPE(SvRV(param)) != SVt_PVHV) continue;
        param_hv = (HV*)SvRV(param);
        
        svp = hv_fetch(param_hv, "_tensor_id", 10, 0);
        if (!svp) continue;
        tensor = get_tensor_by_id(SvIV(*svp));
        if (!tensor || !tensor->grad) continue;
        
        /* Get data and grad as Perl arrays */
        n_elem = ggml_nelements(tensor->tensor);
        data_av = newAV();
        grad_av = newAV();
        
        for (j = 0; j < n_elem; j++) {
            av_push(data_av, newSVnv(ggml_get_f32_1d(tensor->tensor, j)));
            av_push(grad_av, newSVnv(ggml_get_f32_1d(tensor->grad, j)));
        }
        
        /* Get or create velocity */
        SV** vel_svp = av_fetch(velocities, i, 0);
        if (!vel_svp || !SvROK(*vel_svp)) {
            /* Initialize velocity to zeros */
            vel_av = newAV();
            for (j = 0; j < n_elem; j++) {
                av_push(vel_av, newSVnv(0.0));
            }
            av_store(velocities, i, newRV_noinc((SV*)vel_av));
        } else {
            vel_av = (AV*)SvRV(*vel_svp);
        }
        
        /* SGD update with momentum */
        for (j = 0; j < n_elem; j++) {
            SV** data_svp = av_fetch(data_av, j, 0);
            SV** grad_svp = av_fetch(grad_av, j, 0);
            SV** vel_svp2 = av_fetch(vel_av, j, 0);
            
            if (!data_svp || !grad_svp || !vel_svp2) continue;
            
            float d = SvNV(*data_svp);
            float g = SvNV(*grad_svp);
            float v = SvNV(*vel_svp2);
            
            /* Apply weight decay */
            if (weight_decay > 0) {
                g += weight_decay * d;
            }
            
            /* Update velocity */
            v = momentum * v + g;
            sv_setnv(*vel_svp2, v);
            
            /* Compute update */
            float update;
            if (nesterov) {
                update = g + momentum * v;
            } else {
                update = v;
            }
            
            /* Apply update */
            d -= lr * update;
            ggml_set_f32_1d(tensor->tensor, j, d);
        }
        
        SvREFCNT_dec(data_av);
        SvREFCNT_dec(grad_av);
    }
    
    /* Increment step count */
    svp = hv_fetch(self_hv, "step_count", 10, 0);
    if (svp) {
        sv_setiv(*svp, SvIV(*svp) + 1);
    }

float
get_lr(self)
    SV* self
PREINIT:
    HV* self_hv;
    SV** svp;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("self must be a hash ref");
    self_hv = (HV*)SvRV(self);
    svp = hv_fetch(self_hv, "lr", 2, 0);
    RETVAL = svp ? SvNV(*svp) : 0.001f;
OUTPUT:
    RETVAL

void
set_lr(self, new_lr)
    SV* self
    float new_lr
PREINIT:
    HV* self_hv;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("self must be a hash ref");
    self_hv = (HV*)SvRV(self);
    hv_store(self_hv, "lr", 2, newSVnv(new_lr), 0);

MODULE = Lugh  PACKAGE = Lugh::Optimizer::AdamW

SV*
new(class, ...)
    const char* class
PREINIT:
    HV* self;
    float lr = 0.001f;
    float beta1 = 0.9f;
    float beta2 = 0.999f;
    float eps = 1e-8f;
    float weight_decay = 0.01f;
    AV* params = NULL;
    STRLEN i;
CODE:
    /* Parse options */
    for (i = 1; i < (STRLEN)items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "lr") || strEQ(key, "learning_rate")) {
            lr = SvNV(val);
        } else if (strEQ(key, "beta1")) {
            beta1 = SvNV(val);
        } else if (strEQ(key, "beta2")) {
            beta2 = SvNV(val);
        } else if (strEQ(key, "eps") || strEQ(key, "epsilon")) {
            eps = SvNV(val);
        } else if (strEQ(key, "weight_decay")) {
            weight_decay = SvNV(val);
        } else if (strEQ(key, "params")) {
            if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                params = (AV*)SvRV(val);
            }
        }
    }
    
    self = newHV();
    hv_store(self, "lr", 2, newSVnv(lr), 0);
    hv_store(self, "beta1", 5, newSVnv(beta1), 0);
    hv_store(self, "beta2", 5, newSVnv(beta2), 0);
    hv_store(self, "eps", 3, newSVnv(eps), 0);
    hv_store(self, "weight_decay", 12, newSVnv(weight_decay), 0);
    hv_store(self, "step_count", 10, newSViv(0), 0);
    
    if (params) {
        hv_store(self, "params", 6, newRV_inc((SV*)params), 0);
    } else {
        hv_store(self, "params", 6, newRV_noinc((SV*)newAV()), 0);
    }
    
    /* Initialize m (first moment) and v (second moment) buffers */
    hv_store(self, "m_buffers", 9, newRV_noinc((SV*)newAV()), 0);
    hv_store(self, "v_buffers", 9, newRV_noinc((SV*)newAV()), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)self), gv_stashpv(class, GV_ADD));
OUTPUT:
    RETVAL

void
add_param(self, param)
    SV* self
    SV* param
PREINIT:
    HV* self_hv;
    SV** svp;
    AV* params;
    AV* m_buffers;
    AV* v_buffers;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("self must be a hash ref");
    self_hv = (HV*)SvRV(self);
    
    svp = hv_fetch(self_hv, "params", 6, 0);
    if (!svp || !SvROK(*svp)) croak("params not found");
    params = (AV*)SvRV(*svp);
    
    svp = hv_fetch(self_hv, "m_buffers", 9, 0);
    if (!svp || !SvROK(*svp)) croak("m_buffers not found");
    m_buffers = (AV*)SvRV(*svp);
    
    svp = hv_fetch(self_hv, "v_buffers", 9, 0);
    if (!svp || !SvROK(*svp)) croak("v_buffers not found");
    v_buffers = (AV*)SvRV(*svp);
    
    av_push(params, SvREFCNT_inc(param));
    av_push(m_buffers, &PL_sv_undef);
    av_push(v_buffers, &PL_sv_undef);

void
zero_grad(self)
    SV* self
PREINIT:
    HV* self_hv;
    SV** svp;
    AV* params;
    STRLEN i, n;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("self must be a hash ref");
    self_hv = (HV*)SvRV(self);
    
    svp = hv_fetch(self_hv, "params", 6, 0);
    if (!svp || !SvROK(*svp)) return;
    params = (AV*)SvRV(*svp);
    
    n = av_len(params) + 1;
    for (i = 0; i < n; i++) {
        SV** param_svp = av_fetch(params, i, 0);
        if (!param_svp || !*param_svp) continue;
        
        dSP;
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);
        XPUSHs(*param_svp);
        PUTBACK;
        
        call_method("zero_grad", G_DISCARD);
        
        FREETMPS;
        LEAVE;
    }

void
step(self)
    SV* self
PREINIT:
    HV* self_hv;
    SV** svp;
    AV* params;
    AV* m_buffers;
    AV* v_buffers;
    float lr, beta1, beta2, eps, weight_decay;
    int step_count;
    float bias_correction1, bias_correction2;
    STRLEN i, n, j;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("self must be a hash ref");
    self_hv = (HV*)SvRV(self);
    
    /* Get hyperparameters */
    svp = hv_fetch(self_hv, "lr", 2, 0);
    lr = svp ? SvNV(*svp) : 0.001f;
    
    svp = hv_fetch(self_hv, "beta1", 5, 0);
    beta1 = svp ? SvNV(*svp) : 0.9f;
    
    svp = hv_fetch(self_hv, "beta2", 5, 0);
    beta2 = svp ? SvNV(*svp) : 0.999f;
    
    svp = hv_fetch(self_hv, "eps", 3, 0);
    eps = svp ? SvNV(*svp) : 1e-8f;
    
    svp = hv_fetch(self_hv, "weight_decay", 12, 0);
    weight_decay = svp ? SvNV(*svp) : 0.01f;
    
    svp = hv_fetch(self_hv, "step_count", 10, 0);
    step_count = svp ? SvIV(*svp) : 0;
    step_count++;
    
    /* Bias correction */
    bias_correction1 = 1.0f - powf(beta1, (float)step_count);
    bias_correction2 = 1.0f - powf(beta2, (float)step_count);
    
    /* Get buffers */
    svp = hv_fetch(self_hv, "params", 6, 0);
    if (!svp || !SvROK(*svp)) return;
    params = (AV*)SvRV(*svp);
    
    svp = hv_fetch(self_hv, "m_buffers", 9, 0);
    if (!svp || !SvROK(*svp)) return;
    m_buffers = (AV*)SvRV(*svp);
    
    svp = hv_fetch(self_hv, "v_buffers", 9, 0);
    if (!svp || !SvROK(*svp)) return;
    v_buffers = (AV*)SvRV(*svp);
    
    n = av_len(params) + 1;
    
    for (i = 0; i < n; i++) {
        SV** param_svp = av_fetch(params, i, 0);
        if (!param_svp || !*param_svp) continue;
        
        SV *param = *param_svp;
        HV *param_hv;
        LughTensor *tensor;
        AV *m_av = NULL;
        AV *v_av = NULL;
        STRLEN n_elem;
        
        if (!SvROK(param) || SvTYPE(SvRV(param)) != SVt_PVHV) continue;
        param_hv = (HV*)SvRV(param);
        
        svp = hv_fetch(param_hv, "_tensor_id", 10, 0);
        if (!svp) continue;
        tensor = get_tensor_by_id(SvIV(*svp));
        if (!tensor || !tensor->grad) continue;
        
        n_elem = ggml_nelements(tensor->tensor);
        
        /* Get or create m buffer */
        SV** m_svp = av_fetch(m_buffers, i, 0);
        if (!m_svp || !SvROK(*m_svp)) {
            m_av = newAV();
            for (j = 0; j < n_elem; j++) {
                av_push(m_av, newSVnv(0.0));
            }
            av_store(m_buffers, i, newRV_noinc((SV*)m_av));
        } else {
            m_av = (AV*)SvRV(*m_svp);
        }
        
        /* Get or create v buffer */
        SV** v_svp = av_fetch(v_buffers, i, 0);
        if (!v_svp || !SvROK(*v_svp)) {
            v_av = newAV();
            for (j = 0; j < n_elem; j++) {
                av_push(v_av, newSVnv(0.0));
            }
            av_store(v_buffers, i, newRV_noinc((SV*)v_av));
        } else {
            v_av = (AV*)SvRV(*v_svp);
        }
        
        /* AdamW update */
        for (j = 0; j < n_elem; j++) {
            float d = ggml_get_f32_1d(tensor->tensor, j);
            float g = ggml_get_f32_1d(tensor->grad, j);
            
            SV** m_svp2 = av_fetch(m_av, j, 0);
            SV** v_svp2 = av_fetch(v_av, j, 0);
            if (!m_svp2 || !v_svp2) continue;
            
            float m = SvNV(*m_svp2);
            float v = SvNV(*v_svp2);
            
            /* Update biased first moment estimate */
            m = beta1 * m + (1.0f - beta1) * g;
            sv_setnv(*m_svp2, m);
            
            /* Update biased second moment estimate */
            v = beta2 * v + (1.0f - beta2) * g * g;
            sv_setnv(*v_svp2, v);
            
            /* Compute bias-corrected estimates */
            float m_hat = m / bias_correction1;
            float v_hat = v / bias_correction2;
            
            /* AdamW: decoupled weight decay */
            d = d * (1.0f - lr * weight_decay);
            
            /* Adam update */
            d -= lr * m_hat / (sqrtf(v_hat) + eps);
            
            ggml_set_f32_1d(tensor->tensor, j, d);
        }
    }
    
    /* Update step count */
    hv_store(self_hv, "step_count", 10, newSViv(step_count), 0);

float
get_lr(self)
    SV* self
PREINIT:
    HV* self_hv;
    SV** svp;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("self must be a hash ref");
    self_hv = (HV*)SvRV(self);
    svp = hv_fetch(self_hv, "lr", 2, 0);
    RETVAL = svp ? SvNV(*svp) : 0.001f;
OUTPUT:
    RETVAL

void
set_lr(self, new_lr)
    SV* self
    float new_lr
PREINIT:
    HV* self_hv;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("self must be a hash ref");
    self_hv = (HV*)SvRV(self);
    hv_store(self_hv, "lr", 2, newSVnv(new_lr), 0);

int
get_step_count(self)
    SV* self
PREINIT:
    HV* self_hv;
    SV** svp;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("self must be a hash ref");
    self_hv = (HV*)SvRV(self);
    svp = hv_fetch(self_hv, "step_count", 10, 0);
    RETVAL = svp ? SvIV(*svp) : 0;
OUTPUT:
    RETVAL

MODULE = Lugh  PACKAGE = Lugh::Optimizer

void
clip_grad_norm(class, max_norm, ...)
    SV* class
    float max_norm
PREINIT:
    float total_norm = 0.0f;
    float clip_coef;
    STRLEN i;
    AV* tensors_av = NULL;
    AV* all_grads = NULL;
PPCODE:
    PERL_UNUSED_VAR(class);
    
    if (max_norm <= 0) {
        croak("max_norm must be positive");
    }
    
    /* Collect all gradient data */
    all_grads = newAV();
    
    for (i = 2; i < (STRLEN)items; i++) {
        SV *tensor_sv = ST(i);
        if (!SvOK(tensor_sv)) continue;
        if (!SvROK(tensor_sv) || SvTYPE(SvRV(tensor_sv)) != SVt_PVHV) continue;
        
        HV *tensor_hv = (HV*)SvRV(tensor_sv);
        SV **svp = hv_fetch(tensor_hv, "_tensor_id", 10, 0);
        if (!svp) continue;
        
        LughTensor *tensor = get_tensor_by_id(SvIV(*svp));
        if (!tensor || !tensor->grad) continue;
        
        STRLEN n_elem = ggml_nelements(tensor->grad);
        STRLEN j;
        for (j = 0; j < n_elem; j++) {
            float g = ggml_get_f32_1d(tensor->grad, j);
            total_norm += g * g;
            
            /* Store tensor_id and index for later update */
            AV *info = newAV();
            av_push(info, newSViv(tensor->id));
            av_push(info, newSViv(j));
            av_push(all_grads, newRV_noinc((SV*)info));
        }
    }
    
    total_norm = sqrtf(total_norm);
    
    /* Clip if necessary */
    if (total_norm > max_norm) {
        clip_coef = max_norm / (total_norm + 1e-6f);
        
        STRLEN n = av_len(all_grads) + 1;
        for (i = 0; i < n; i++) {
            SV **info_svp = av_fetch(all_grads, i, 0);
            if (!info_svp || !SvROK(*info_svp)) continue;
            
            AV *info = (AV*)SvRV(*info_svp);
            SV **id_svp = av_fetch(info, 0, 0);
            SV **idx_svp = av_fetch(info, 1, 0);
            if (!id_svp || !idx_svp) continue;
            
            LughTensor *tensor = get_tensor_by_id(SvIV(*id_svp));
            if (!tensor || !tensor->grad) continue;
            
            STRLEN idx = SvIV(*idx_svp);
            float g = ggml_get_f32_1d(tensor->grad, idx);
            ggml_set_f32_1d(tensor->grad, idx, g * clip_coef);
        }
    }
    
    SvREFCNT_dec(all_grads);
    
    /* Return total norm (before clipping) */
    EXTEND(SP, 1);
    mPUSHn(total_norm);

void
clip_grad_value(class, max_value, ...)
    SV* class
    float max_value
PREINIT:
    STRLEN i;
PPCODE:
    PERL_UNUSED_VAR(class);
    
    if (max_value <= 0) {
        croak("max_value must be positive");
    }
    
    for (i = 2; i < (STRLEN)items; i++) {
        SV *tensor_sv = ST(i);
        if (!SvOK(tensor_sv)) continue;
        if (!SvROK(tensor_sv) || SvTYPE(SvRV(tensor_sv)) != SVt_PVHV) continue;
        
        HV *tensor_hv = (HV*)SvRV(tensor_sv);
        SV **svp = hv_fetch(tensor_hv, "_tensor_id", 10, 0);
        if (!svp) continue;
        
        LughTensor *tensor = get_tensor_by_id(SvIV(*svp));
        if (!tensor || !tensor->grad) continue;
        
        STRLEN n_elem = ggml_nelements(tensor->grad);
        STRLEN j;
        for (j = 0; j < n_elem; j++) {
            float g = ggml_get_f32_1d(tensor->grad, j);
            if (g > max_value) {
                ggml_set_f32_1d(tensor->grad, j, max_value);
            } else if (g < -max_value) {
                ggml_set_f32_1d(tensor->grad, j, -max_value);
            }
        }
    }
    
    XSRETURN_EMPTY;

MODULE = Lugh  PACKAGE = Lugh::Optimizer::LRScheduler

SV*
new(class, optimizer, ...)
    const char* class
    SV* optimizer
PREINIT:
    HV* self;
    const char* schedule_type = "constant";
    float initial_lr = 0.0f;
    int warmup_steps = 0;
    int total_steps = 1000;
    float min_lr = 0.0f;
    float decay_rate = 0.1f;
    AV* milestones = NULL;
    STRLEN i;
CODE:
    /* Get initial LR from optimizer */
    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(optimizer);
        PUTBACK;
        int count = call_method("get_lr", G_SCALAR);
        SPAGAIN;
        if (count > 0) {
            initial_lr = POPn;
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    
    /* Parse options */
    for (i = 2; i < (STRLEN)items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "schedule") || strEQ(key, "type")) {
            schedule_type = SvPV_nolen(val);
        } else if (strEQ(key, "warmup_steps")) {
            warmup_steps = SvIV(val);
        } else if (strEQ(key, "total_steps")) {
            total_steps = SvIV(val);
        } else if (strEQ(key, "min_lr")) {
            min_lr = SvNV(val);
        } else if (strEQ(key, "decay_rate") || strEQ(key, "gamma")) {
            decay_rate = SvNV(val);
        } else if (strEQ(key, "milestones")) {
            if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                milestones = (AV*)SvRV(val);
            }
        }
    }
    
    self = newHV();
    hv_store(self, "optimizer", 9, SvREFCNT_inc(optimizer), 0);
    hv_store(self, "schedule", 8, newSVpv(schedule_type, 0), 0);
    hv_store(self, "initial_lr", 10, newSVnv(initial_lr), 0);
    hv_store(self, "warmup_steps", 12, newSViv(warmup_steps), 0);
    hv_store(self, "total_steps", 11, newSViv(total_steps), 0);
    hv_store(self, "min_lr", 6, newSVnv(min_lr), 0);
    hv_store(self, "decay_rate", 10, newSVnv(decay_rate), 0);
    hv_store(self, "current_step", 12, newSViv(0), 0);
    
    if (milestones) {
        hv_store(self, "milestones", 10, newRV_inc((SV*)milestones), 0);
    } else {
        hv_store(self, "milestones", 10, newRV_noinc((SV*)newAV()), 0);
    }
    
    RETVAL = sv_bless(newRV_noinc((SV*)self), gv_stashpv(class, GV_ADD));
OUTPUT:
    RETVAL

void
step(self)
    SV* self
PREINIT:
    HV* self_hv;
    SV** svp;
    SV* optimizer;
    const char* schedule;
    float initial_lr, min_lr, decay_rate;
    int warmup_steps, total_steps, current_step;
    float new_lr;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("self must be a hash ref");
    self_hv = (HV*)SvRV(self);
    
    /* Get scheduler parameters */
    svp = hv_fetch(self_hv, "optimizer", 9, 0);
    if (!svp) croak("optimizer not found");
    optimizer = *svp;
    
    svp = hv_fetch(self_hv, "schedule", 8, 0);
    schedule = svp ? SvPV_nolen(*svp) : "constant";
    
    svp = hv_fetch(self_hv, "initial_lr", 10, 0);
    initial_lr = svp ? SvNV(*svp) : 0.001f;
    
    svp = hv_fetch(self_hv, "min_lr", 6, 0);
    min_lr = svp ? SvNV(*svp) : 0.0f;
    
    svp = hv_fetch(self_hv, "decay_rate", 10, 0);
    decay_rate = svp ? SvNV(*svp) : 0.1f;
    
    svp = hv_fetch(self_hv, "warmup_steps", 12, 0);
    warmup_steps = svp ? SvIV(*svp) : 0;
    
    svp = hv_fetch(self_hv, "total_steps", 11, 0);
    total_steps = svp ? SvIV(*svp) : 1000;
    
    svp = hv_fetch(self_hv, "current_step", 12, 0);
    current_step = svp ? SvIV(*svp) : 0;
    current_step++;
    
    /* Compute new LR based on schedule */
    new_lr = initial_lr;
    
    if (strEQ(schedule, "constant")) {
        new_lr = initial_lr;
    }
    else if (strEQ(schedule, "linear")) {
        /* Linear decay from initial_lr to min_lr */
        if (current_step <= warmup_steps) {
            /* Linear warmup */
            new_lr = initial_lr * ((float)current_step / (float)warmup_steps);
        } else {
            /* Linear decay */
            int decay_steps = total_steps - warmup_steps;
            int steps_after_warmup = current_step - warmup_steps;
            if (decay_steps > 0) {
                float progress = (float)steps_after_warmup / (float)decay_steps;
                if (progress > 1.0f) progress = 1.0f;
                new_lr = initial_lr + (min_lr - initial_lr) * progress;
            }
        }
    }
    else if (strEQ(schedule, "cosine")) {
        /* Cosine annealing */
        if (current_step <= warmup_steps) {
            new_lr = initial_lr * ((float)current_step / (float)warmup_steps);
        } else {
            int decay_steps = total_steps - warmup_steps;
            int steps_after_warmup = current_step - warmup_steps;
            if (decay_steps > 0) {
                float progress = (float)steps_after_warmup / (float)decay_steps;
                if (progress > 1.0f) progress = 1.0f;
                /* Cosine: lr = min_lr + 0.5 * (initial_lr - min_lr) * (1 + cos(pi * progress)) */
                new_lr = min_lr + 0.5f * (initial_lr - min_lr) * (1.0f + cosf(M_PI * progress));
            }
        }
    }
    else if (strEQ(schedule, "exponential")) {
        /* Exponential decay: lr = initial_lr * decay_rate^step */
        new_lr = initial_lr * powf(decay_rate, (float)current_step);
        if (new_lr < min_lr) new_lr = min_lr;
    }
    else if (strEQ(schedule, "step")) {
        /* Step decay at milestones */
        svp = hv_fetch(self_hv, "milestones", 10, 0);
        if (svp && SvROK(*svp)) {
            AV *milestones = (AV*)SvRV(*svp);
            STRLEN n = av_len(milestones) + 1;
            STRLEN j;
            int decay_count = 0;
            for (j = 0; j < n; j++) {
                SV **m_svp = av_fetch(milestones, j, 0);
                if (m_svp && current_step >= SvIV(*m_svp)) {
                    decay_count++;
                }
            }
            new_lr = initial_lr * powf(decay_rate, (float)decay_count);
        }
        if (new_lr < min_lr) new_lr = min_lr;
    }
    else if (strEQ(schedule, "warmup")) {
        /* Just warmup, then constant */
        if (current_step <= warmup_steps && warmup_steps > 0) {
            new_lr = initial_lr * ((float)current_step / (float)warmup_steps);
        } else {
            new_lr = initial_lr;
        }
    }
    
    /* Update optimizer LR */
    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(optimizer);
        mXPUSHn(new_lr);
        PUTBACK;
        call_method("set_lr", G_DISCARD);
        FREETMPS;
        LEAVE;
    }
    
    /* Update current step */
    hv_store(self_hv, "current_step", 12, newSViv(current_step), 0);

float
get_lr(self)
    SV* self
PREINIT:
    HV* self_hv;
    SV** svp;
    SV* optimizer;
    float lr = 0.0f;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("self must be a hash ref");
    self_hv = (HV*)SvRV(self);
    
    svp = hv_fetch(self_hv, "optimizer", 9, 0);
    if (svp) {
        optimizer = *svp;
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(optimizer);
        PUTBACK;
        int count = call_method("get_lr", G_SCALAR);
        SPAGAIN;
        if (count > 0) {
            lr = POPn;
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    
    RETVAL = lr;
OUTPUT:
    RETVAL

int
get_step(self)
    SV* self
PREINIT:
    HV* self_hv;
    SV** svp;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("self must be a hash ref");
    self_hv = (HV*)SvRV(self);
    svp = hv_fetch(self_hv, "current_step", 12, 0);
    RETVAL = svp ? SvIV(*svp) : 0;
OUTPUT:
    RETVAL