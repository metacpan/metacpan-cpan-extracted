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
static int mutex_initialized = 0;

#define CONTEXT_LOCK()   MUTEX_LOCK(&context_mutex)
#define CONTEXT_UNLOCK() MUTEX_UNLOCK(&context_mutex)
#define TENSOR_LOCK()    MUTEX_LOCK(&tensor_mutex)
#define TENSOR_UNLOCK()  MUTEX_UNLOCK(&tensor_mutex)

#define INIT_MUTEXES() do { \
    if (!mutex_initialized) { \
        MUTEX_INIT(&context_mutex); \
        MUTEX_INIT(&tensor_mutex); \
        MUTEX_INIT(&kvcache_mutex); \
        MUTEX_INIT(&mempool_mutex); \
        MUTEX_INIT(&lora_registry_mutex); \
        MUTEX_INIT(&speculative_mutex); \
        mutex_initialized = 1; \
    } \
} while(0)

#else
#define CONTEXT_LOCK()
#define CONTEXT_UNLOCK()
#define TENSOR_LOCK()
#define TENSOR_UNLOCK()
#define INIT_MUTEXES()
#endif

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

typedef struct {
    struct ggml_tensor *tensor;
    int context_id;  /* ID of owning context */
    int id;
    int active;
} LughTensor;

typedef struct {
    struct gguf_context *gguf;
    struct ggml_context *ctx;     /* Context for tensor data */
    char *filename;
    int id;
    int active;
    /* Model metadata */
    int64_t n_tensors;
    int64_t n_kv;
    char *architecture;
} LughModel;

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
        if (lm->filename) {
            Safefree(lm->filename);
            lm->filename = NULL;
        }
        if (lm->architecture) {
            Safefree(lm->architecture);
            lm->architecture = NULL;
        }
        lm->active = 0;
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
typedef struct {
    char name[128];              /* Base tensor name (e.g., "blk.0.attn_q.weight") */
    struct ggml_tensor *a;       /* Down-projection [rank × d_in] */
    struct ggml_tensor *b;       /* Up-projection [d_out × rank] */
    int rank;                    /* LoRA rank (inferred from tensor shapes) */
} LughLoRAWeight;

/* LoRA adapter container */
typedef struct {
    int id;
    int active;
    float alpha;                 /* Scaling factor from adapter metadata */
    float scale;                 /* User-specified scale multiplier */
    char *source_file;           /* Path to source file */
    char *architecture;          /* Must match base model architecture */
    char format[16];             /* "gguf" or "safetensors" */
    /* Weight storage */
    LughLoRAWeight *weights;     /* Array of LoRA weight pairs */
    int n_weights;               /* Number of weight pairs */
    int weights_capacity;        /* Allocated capacity */
    /* Tensor memory */
    struct ggml_context *ctx;    /* Context for LoRA tensors */
    ggml_backend_buffer_t buffer; /* Backend buffer for tensor data */
#ifdef USE_ITHREADS
    perl_mutex lora_mutex;       /* Thread-safe access */
#endif
} LughLoRAAdapter;

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
            
            threshold = (float)rand() / (float)RAND_MAX * sum;
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

/* One speculation step: draft + verify - returns accepted tokens or NULL on error */
static AV* spec_step(pTHX_ HV *spec_hv, LughSpeculative *spec, int *input_tokens, int n_input) {
    AV *draft_av, *accepted_av;
    int *draft_tokens_arr;
    int n_draft, i;
    
    /* Initialize caches if needed */
    if (!spec_init_caches(aTHX_ spec_hv, spec)) {
        return NULL;
    }
    
    /* Generate draft tokens */
    draft_av = spec_draft_tokens(aTHX_ spec_hv, spec, input_tokens, n_input, spec->k);
    if (!draft_av) {
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
    srand(seed);

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
    for (i = 1; i < items; i += 2) {
        if (i + 1 < items && SvPOK(ST(i))) {
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            if (strEQ(key, "tokens") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                opts.tokens = parse_tokens_av(aTHX_ (AV*)SvRV(val), &opts.n_tokens);
            } else if (strEQ(key, "lora")) {
                opts.lora = get_lugh_lora(aTHX_ val);
            } else if (strEQ(key, "cache")) {
                opts.cache = get_lugh_kvcache(aTHX_ val);
            } else if (strEQ(key, "caches") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                AV *caches_av = (AV*)SvRV(val);
                int nc = av_len(caches_av) + 1;
                int ci;
                Newxz(opts.caches, nc, void*);
                opts.n_caches = nc;
                for (ci = 0; ci < nc; ci++) {
                    SV **csv = av_fetch(caches_av, ci, 0);
                    if (csv && *csv && SvROK(*csv)) {
                        opts.caches[ci] = get_lugh_kvcache(aTHX_ *csv);
                    }
                }
            } else if (strEQ(key, "pool") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
                HV *pool_hv = (HV*)SvRV(val);
                SV **svp = hv_fetch(pool_hv, "_pool_id", 8, 0);
                if (svp && *svp) opts.pool = get_mempool_by_id(SvIV(*svp));
            } else if (strEQ(key, "rope")) {
                opts.rope_sv = val;
            } else if (strEQ(key, "sequences") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                if (!parse_sequences_av(aTHX_ (AV*)SvRV(val), &opts.all_tokens, &opts.seq_lengths, &opts.n_sequences)) {
                    croak("Invalid sequences format");
                }
            }
        }
    }
    
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
    for (i = 1; i < items; i += 2) {
        if (i + 1 < items && SvPOK(ST(i))) {
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            if (strEQ(key, "tokens") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                opts.tokens = parse_tokens_av(aTHX_ (AV*)SvRV(val), &opts.n_tokens);
            } else if (strEQ(key, "lora")) {
                opts.lora = get_lugh_lora(aTHX_ val);
            } else if (strEQ(key, "cache")) {
                opts.cache = get_lugh_kvcache(aTHX_ val);
            } else if (strEQ(key, "caches") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                AV *caches_av = (AV*)SvRV(val);
                int nc = av_len(caches_av) + 1;
                int ci;
                Newxz(opts.caches, nc, void*);
                opts.n_caches = nc;
                for (ci = 0; ci < nc; ci++) {
                    SV **csv = av_fetch(caches_av, ci, 0);
                    if (csv && *csv && SvROK(*csv)) {
                        opts.caches[ci] = get_lugh_kvcache(aTHX_ *csv);
                    }
                }
            } else if (strEQ(key, "pool") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
                HV *pool_hv = (HV*)SvRV(val);
                SV **svp = hv_fetch(pool_hv, "_pool_id", 8, 0);
                if (svp && *svp) opts.pool = get_mempool_by_id(SvIV(*svp));
            } else if (strEQ(key, "rope")) {
                opts.rope_sv = val;
            } else if (strEQ(key, "sequences") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                if (!parse_sequences_av(aTHX_ (AV*)SvRV(val), &opts.all_tokens, &opts.seq_lengths, &opts.n_sequences)) {
                    croak("Invalid sequences format");
                }
            }
        }
    }
    
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
    int j, i;
PPCODE:
    hv = (HV*)SvRV(self);
    Zero(&opts, 1, LughForwardOpts);
    
    /* Detect positional: forward_cache($cache, \@tokens, ...) */
    if (items >= 3 && sv_isobject(ST(1)) && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVAV) {
        opts.cache = get_lugh_kvcache(aTHX_ ST(1));
        opts.tokens = parse_tokens_av(aTHX_ (AV*)SvRV(ST(2)), &opts.n_tokens);
        /* Parse remaining as named params */
        for (i = 3; i < items; i += 2) {
            if (i + 1 < items && SvPOK(ST(i))) {
                const char *key = SvPV_nolen(ST(i));
                SV *val = ST(i + 1);
                if (strEQ(key, "lora")) opts.lora = get_lugh_lora(aTHX_ val);
                else if (strEQ(key, "rope")) opts.rope_sv = val;
            }
        }
    } else {
        /* Named params: forward_cache(cache => $c, tokens => \@t, ...) */
        for (i = 1; i < items; i += 2) {
            if (i + 1 < items && SvPOK(ST(i))) {
                const char *key = SvPV_nolen(ST(i));
                SV *val = ST(i + 1);
                if (strEQ(key, "tokens") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                    opts.tokens = parse_tokens_av(aTHX_ (AV*)SvRV(val), &opts.n_tokens);
                } else if (strEQ(key, "cache")) {
                    opts.cache = get_lugh_kvcache(aTHX_ val);
                } else if (strEQ(key, "lora")) {
                    opts.lora = get_lugh_lora(aTHX_ val);
                } else if (strEQ(key, "rope")) {
                    opts.rope_sv = val;
                }
            }
        }
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
    int j, i;
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
        for (i = 3; i < items; i += 2) {
            if (i + 1 < items && SvPOK(ST(i))) {
                const char *key = SvPV_nolen(ST(i));
                SV *val = ST(i + 1);
                if (strEQ(key, "lora")) opts.lora = get_lugh_lora(aTHX_ val);
                else if (strEQ(key, "rope")) opts.rope_sv = val;
            }
        }
    } else {
        /* Named params */
        for (i = 1; i < items; i += 2) {
            if (i + 1 < items && SvPOK(ST(i))) {
                const char *key = SvPV_nolen(ST(i));
                SV *val = ST(i + 1);
                if (strEQ(key, "tokens") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                    opts.tokens = parse_tokens_av(aTHX_ (AV*)SvRV(val), &opts.n_tokens);
                } else if (strEQ(key, "pool") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
                    HV *pool_hv = (HV*)SvRV(val);
                    svp = hv_fetch(pool_hv, "_pool_id", 8, 0);
                    if (svp && *svp) opts.pool = get_mempool_by_id(SvIV(*svp));
                } else if (strEQ(key, "lora")) {
                    opts.lora = get_lugh_lora(aTHX_ val);
                } else if (strEQ(key, "rope")) {
                    opts.rope_sv = val;
                }
            }
        }
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
        for (i = 2; i < items; i += 2) {
            if (i + 1 < items && SvPOK(ST(i))) {
                const char *key = SvPV_nolen(ST(i));
                SV *val = ST(i + 1);
                if (strEQ(key, "lora")) opts.lora = get_lugh_lora(aTHX_ val);
                else if (strEQ(key, "rope")) opts.rope_sv = val;
                else if (strEQ(key, "caches") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                    AV *caches_av = (AV*)SvRV(val);
                    int nc = av_len(caches_av) + 1;
                    int ci;
                    Newxz(opts.caches, nc, void*);
                    opts.n_caches = nc;
                    for (ci = 0; ci < nc; ci++) {
                        SV **csv = av_fetch(caches_av, ci, 0);
                        if (csv && *csv && SvROK(*csv)) {
                            opts.caches[ci] = get_lugh_kvcache(aTHX_ *csv);
                        }
                    }
                }
            }
        }
    } else {
        /* Named params */
        for (i = 1; i < items; i += 2) {
            if (i + 1 < items && SvPOK(ST(i))) {
                const char *key = SvPV_nolen(ST(i));
                SV *val = ST(i + 1);
                if (strEQ(key, "sequences") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                    if (!parse_sequences_av(aTHX_ (AV*)SvRV(val), &opts.all_tokens, &opts.seq_lengths, &opts.n_sequences)) {
                        croak("Invalid sequences format");
                    }
                } else if (strEQ(key, "caches") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                    AV *caches_av = (AV*)SvRV(val);
                    int nc = av_len(caches_av) + 1;
                    int ci;
                    Newxz(opts.caches, nc, void*);
                    opts.n_caches = nc;
                    for (ci = 0; ci < nc; ci++) {
                        SV **csv = av_fetch(caches_av, ci, 0);
                        if (csv && *csv && SvROK(*csv)) {
                            opts.caches[ci] = get_lugh_kvcache(aTHX_ *csv);
                        }
                    }
                } else if (strEQ(key, "cache")) {
                    /* Single cache - error for batch mode */
                    opts.cache = get_lugh_kvcache(aTHX_ val);
                } else if (strEQ(key, "lora")) {
                    opts.lora = get_lugh_lora(aTHX_ val);
                } else if (strEQ(key, "rope")) {
                    opts.rope_sv = val;
                }
            }
        }
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
    int j, i;
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
        for (i = 4; i < items; i += 2) {
            if (i + 1 < items && SvPOK(ST(i))) {
                const char *key = SvPV_nolen(ST(i));
                SV *val = ST(i + 1);
                if (strEQ(key, "lora")) opts.lora = get_lugh_lora(aTHX_ val);
                else if (strEQ(key, "rope")) opts.rope_sv = val;
            }
        }
    } else {
        /* Named params */
        for (i = 1; i < items; i += 2) {
            if (i + 1 < items && SvPOK(ST(i))) {
                const char *key = SvPV_nolen(ST(i));
                SV *val = ST(i + 1);
                if (strEQ(key, "tokens") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                    opts.tokens = parse_tokens_av(aTHX_ (AV*)SvRV(val), &opts.n_tokens);
                } else if (strEQ(key, "cache")) {
                    opts.cache = get_lugh_kvcache(aTHX_ val);
                } else if (strEQ(key, "pool") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
                    HV *pool_hv = (HV*)SvRV(val);
                    svp = hv_fetch(pool_hv, "_pool_id", 8, 0);
                    if (svp && *svp) opts.pool = get_mempool_by_id(SvIV(*svp));
                } else if (strEQ(key, "lora")) {
                    opts.lora = get_lugh_lora(aTHX_ val);
                } else if (strEQ(key, "rope")) {
                    opts.rope_sv = val;
                }
            }
        }
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
        for (i = 3; i < items; i += 2) {
            if (i + 1 < items && SvPOK(ST(i))) {
                const char *key = SvPV_nolen(ST(i));
                SV *val = ST(i + 1);
                if (strEQ(key, "lora")) opts.lora = get_lugh_lora(aTHX_ val);
                else if (strEQ(key, "rope")) opts.rope_sv = val;
                else if (strEQ(key, "caches") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                    AV *caches_av = (AV*)SvRV(val);
                    int nc = av_len(caches_av) + 1;
                    int ci;
                    Newxz(opts.caches, nc, void*);
                    opts.n_caches = nc;
                    for (ci = 0; ci < nc; ci++) {
                        SV **csv = av_fetch(caches_av, ci, 0);
                        if (csv && *csv && SvROK(*csv)) {
                            opts.caches[ci] = get_lugh_kvcache(aTHX_ *csv);
                        }
                    }
                }
            }
        }
    } else {
        /* Named params */
        for (i = 1; i < items; i += 2) {
            if (i + 1 < items && SvPOK(ST(i))) {
                const char *key = SvPV_nolen(ST(i));
                SV *val = ST(i + 1);
                if (strEQ(key, "sequences") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                    if (!parse_sequences_av(aTHX_ (AV*)SvRV(val), &opts.all_tokens, &opts.seq_lengths, &opts.n_sequences)) {
                        croak("Invalid sequences format");
                    }
                } else if (strEQ(key, "pool") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
                    HV *pool_hv = (HV*)SvRV(val);
                    svp = hv_fetch(pool_hv, "_pool_id", 8, 0);
                    if (svp && *svp) opts.pool = get_mempool_by_id(SvIV(*svp));
                } else if (strEQ(key, "caches") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                    AV *caches_av = (AV*)SvRV(val);
                    int nc = av_len(caches_av) + 1;
                    int ci;
                    Newxz(opts.caches, nc, void*);
                    opts.n_caches = nc;
                    for (ci = 0; ci < nc; ci++) {
                        SV **csv = av_fetch(caches_av, ci, 0);
                        if (csv && *csv && SvROK(*csv)) {
                            opts.caches[ci] = get_lugh_kvcache(aTHX_ *csv);
                        }
                    }
                } else if (strEQ(key, "lora")) {
                    opts.lora = get_lugh_lora(aTHX_ val);
                } else if (strEQ(key, "rope")) {
                    opts.rope_sv = val;
                }
            }
        }
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
        threshold = (float)rand() / (float)RAND_MAX * top_sum;
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
    threshold = (float)rand() / (float)RAND_MAX * sum;
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
                threshold = (float)rand() / (float)RAND_MAX * sum;
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
                threshold = (float)rand() / (float)RAND_MAX * top_p;
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
CODE:
    INIT_MUTEXES();
    
    /* Parse arguments */
    for (i = 1; i < items; i += 2) {
        if (i + 1 < items) {
            const char *key = SvPV_nolen(ST(i));
            if (strEQ(key, "model") || strEQ(key, "file") || strEQ(key, "path")) {
                filename = SvPV_nolen(ST(i + 1));
            }
        }
    }
    
    if (!filename) {
        croak("Lugh::Model->new requires 'model' parameter with path to GGUF file");
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
    
    /* Copy filename */
    Newx(lm->filename, strlen(filename) + 1, char);
    strcpy(lm->filename, filename);
    
    /* Initialize GGUF context */
    gguf_params.no_alloc = false;
    gguf_params.ctx = &tensor_ctx;
    
    lm->gguf = gguf_init_from_file(filename, gguf_params);
    if (!lm->gguf) {
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

void
DESTROY(self)
    SV *self
CODE:
    /* Magic cleanup handles this */
    PERL_UNUSED_VAR(self);

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
        croak("Speculative step failed");
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

