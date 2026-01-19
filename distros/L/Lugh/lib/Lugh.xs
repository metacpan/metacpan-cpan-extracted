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
 * Based on llama.cpp architecture support - used for inference path selection
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
/* Based on llama.cpp's LLM_TENSOR_ATTN_QKV usage */
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
 * Global Registries (thread-safe via integer IDs)
 * ============================================================================ */

static LughContext* context_registry[MAX_CONTEXTS] = {NULL};
static LughTensor*  tensor_registry[MAX_TENSORS]   = {NULL};
static LughModel*   model_registry[MAX_CONTEXTS]   = {NULL};
static LughKVCache* kvcache_registry[MAX_KVCACHES] = {NULL};
static int next_context_id = 1;
static int next_tensor_id  = 1;
static int next_model_id   = 1;
static int next_kvcache_id = 1;

#ifdef USE_ITHREADS
#define KVCACHE_REGISTRY_LOCK()   MUTEX_LOCK(&kvcache_mutex)
#define KVCACHE_REGISTRY_UNLOCK() MUTEX_UNLOCK(&kvcache_mutex)
#else
#define KVCACHE_REGISTRY_LOCK()
#define KVCACHE_REGISTRY_UNLOCK()
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
 * Lugh::Inference Forward Pass Helpers - Shared between forward() and forward_with_cache()
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
} LughHyperparams;

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
    
    /* Set architecture type for inference path selection */
    hp->arch_type = get_arch_type(arch);
}

/* Get layer weights from model context */
/* Get layer weights from model context - architecture aware */
static int get_layer_weights_for_arch(struct ggml_context *ctx_w, int layer, 
                                       LughLayerWeights *lw, LughArchType arch_type) {
    char name[64];
    int valid = 1;
    
    /* Initialize all pointers to NULL */
    memset(lw, 0, sizeof(LughLayerWeights));
    
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
    qkv->q = ggml_rope_ext(ctx, qkv->q, pos, NULL, hp->n_rot, 0, hp->n_ctx,
                           hp->rope_freq_base, hp->rope_freq_scale, 0.0f, 1.0f, 0.0f, 0.0f);
    qkv->k = ggml_rope_ext(ctx, qkv->k, pos, NULL, hp->n_rot, 0, hp->n_ctx,
                           hp->rope_freq_base, hp->rope_freq_scale, 0.0f, 1.0f, 0.0f, 0.0f);
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

/* Build FFN (Feed-Forward Network) for a layer
 * Supports both SwiGLU (with gate) and GELU (without gate) architectures
 */
static struct ggml_tensor* build_ffn(
    struct ggml_context *ctx,
    struct ggml_tensor *cur,
    LughLayerWeights *lw
) {
    if (lw->has_ffn_gate && lw->ffn_gate) {
        /* SwiGLU: gate * silu(up) -> down (llama, qwen, gemma) */
        struct ggml_tensor *gate = ggml_mul_mat(ctx, lw->ffn_gate, cur);
        struct ggml_tensor *up = ggml_mul_mat(ctx, lw->ffn_up, cur);
        gate = ggml_silu(ctx, gate);
        cur = ggml_mul(ctx, gate, up);
        cur = ggml_mul_mat(ctx, lw->ffn_down, cur);
    } else {
        /* GELU: gelu(up) -> down (phi, gpt2, bert) */
        struct ggml_tensor *up = ggml_mul_mat(ctx, lw->ffn_up, cur);
        cur = ggml_gelu(ctx, up);
        cur = ggml_mul_mat(ctx, lw->ffn_down, cur);
    }
    return cur;
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
    SV **svp;
    LughModel *model;
    int i, n_tokens = 0;
    int *tokens = NULL;
    LughHyperparams hp;
    struct ggml_context *ctx_w = NULL;  /* weights context (model->ctx) */
    struct ggml_context *ctx_c = NULL;  /* compute context */
    struct ggml_cgraph *gf = NULL;
    struct ggml_tensor *cur = NULL;
    struct ggml_tensor *inpL = NULL;
    ggml_backend_t backend = NULL;
    ggml_gallocr_t allocr = NULL;
PPCODE:
    /* Get model */
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_model", 6, 0);
    if (!svp || !*svp) croak("No model in inference object");
    model = get_lugh_model(aTHX_ *svp);
    if (!model) croak("Invalid model");
    
    /* Parse tokens from args */
    /* Expect either an array ref or a list of tokens */
    if (items == 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVAV) {
        /* Array reference passed */
        AV *av = (AV*)SvRV(ST(1));
        n_tokens = av_len(av) + 1;
        if (n_tokens == 0) {
            croak("forward() requires at least one token");
        }
        Newx(tokens, n_tokens, int);
        for (i = 0; i < n_tokens; i++) {
            SV **elem = av_fetch(av, i, 0);
            tokens[i] = elem ? SvIV(*elem) : 0;
        }
    } else {
        /* List of tokens passed directly */
        for (i = 1; i < items; i++) {
            n_tokens++;
        }
        if (n_tokens == 0) {
            croak("forward() requires at least one token");
        }
        Newx(tokens, n_tokens, int);
        for (i = 0; i < n_tokens; i++) {
            tokens[i] = SvIV(ST(i + 1));
        }
    }
    
    /* Extract hyperparameters */
    extract_hyperparams(aTHX_ hv, model, &hp);
    
    /* Use model's context directly for weights */
    ctx_w = model->ctx;
    
    /* Initialize backend based on backend_name */
    if (strcmp(hp.backend_name, "auto") == 0) {
        backend = init_best_backend(hp.n_threads);
    } else {
        backend = init_backend_by_name(hp.backend_name, hp.n_threads);
    }
    if (!backend) {
        Safefree(tokens);
        croak("Failed to initialize backend '%s'", hp.backend_name);
    }
    
    /* Create compute context for intermediate tensors */
    ctx_c = create_compute_context(512 * 1024 * 1024);
    if (!ctx_c) {
        ggml_backend_free(backend);
        Safefree(tokens);
        croak("Failed to create compute context");
    }
    
    /* Build the forward pass graph */
    {
        struct ggml_tensor *tok_embd = ggml_get_tensor(ctx_w, "token_embd.weight");
        struct ggml_tensor *output_norm = ggml_get_tensor(ctx_w, "output_norm.weight");
        struct ggml_tensor *output = ggml_get_tensor(ctx_w, "output.weight");
        struct ggml_tensor *pos;
        int layer;
        
        /* Support tied embeddings: if output.weight is missing, use token_embd.weight */
        if (!output) {
            output = tok_embd;
        }
        
        if (!tok_embd) {
            ggml_free(ctx_c);
            ggml_backend_free(backend);
            Safefree(tokens);
            croak("Required tensors not found in model");
        }
        
        /* Create position tensor for RoPE */
        pos = ggml_new_tensor_1d(ctx_c, GGML_TYPE_I32, n_tokens);
        ggml_set_name(pos, "pos");
        
        /* Create input embedding: lookup tokens in embedding table */
        {
            struct ggml_tensor *inp_tokens = ggml_new_tensor_1d(ctx_c, GGML_TYPE_I32, n_tokens);
            ggml_set_name(inp_tokens, "inp_tokens");
            inpL = ggml_get_rows(ctx_c, tok_embd, inp_tokens);
            ggml_set_name(inpL, "inp_embd");
        }
        
        cur = inpL;
        
        /* Process each transformer layer */
        for (layer = 0; layer < hp.n_layer; layer++) {
            LughLayerWeights lw;
            struct ggml_tensor *residual;
            
            /* Get layer weights using architecture-aware helper */
            if (!get_layer_weights_for_arch(ctx_w, layer, &lw, hp.arch_type)) {
                continue;  /* Skip layers with missing weights */
            }
            
            residual = cur;
            
            /* RMS Norm before attention */
            cur = apply_rms_norm(ctx_c, cur, lw.attn_norm, hp.rms_norm_eps);
            
            /* Self-attention: Q, K, V projections */
            {
                struct ggml_tensor *q, *k, *v;
                struct ggml_tensor *attn_out;
                
                /* Q, K, V projections - handle combined or separate */
                if (lw.has_combined_qkv) {
                    /* Split combined QKV tensor */
                    struct ggml_tensor *qkv = ggml_mul_mat(ctx_c, lw.wqkv, cur);
                    int qkv_dim = hp.n_embd + 2 * (hp.n_head_kv * hp.head_dim);
                    q = ggml_view_2d(ctx_c, qkv, hp.n_embd, n_tokens, 
                                     qkv_dim * sizeof(float), 0);
                    k = ggml_view_2d(ctx_c, qkv, hp.n_head_kv * hp.head_dim, n_tokens,
                                     qkv_dim * sizeof(float), hp.n_embd * sizeof(float));
                    v = ggml_view_2d(ctx_c, qkv, hp.n_head_kv * hp.head_dim, n_tokens,
                                     qkv_dim * sizeof(float), (hp.n_embd + hp.n_head_kv * hp.head_dim) * sizeof(float));
                } else {
                    q = ggml_mul_mat(ctx_c, lw.wq, cur);
                    k = ggml_mul_mat(ctx_c, lw.wk, cur);
                    v = ggml_mul_mat(ctx_c, lw.wv, cur);
                }
                
                /* Reshape for attention heads */
                q = ggml_reshape_3d(ctx_c, q, hp.head_dim, hp.n_head, n_tokens);
                k = ggml_reshape_3d(ctx_c, k, hp.head_dim, hp.n_head_kv, n_tokens);
                v = ggml_reshape_3d(ctx_c, v, hp.head_dim, hp.n_head_kv, n_tokens);
                
                /* Apply RoPE (rotary positional embeddings) */
                q = ggml_rope_ext(ctx_c, q, pos, NULL, hp.n_rot, 0, hp.n_ctx,
                                  hp.rope_freq_base, hp.rope_freq_scale, 0.0f, 1.0f, 0.0f, 0.0f);
                k = ggml_rope_ext(ctx_c, k, pos, NULL, hp.n_rot, 0, hp.n_ctx,
                                  hp.rope_freq_base, hp.rope_freq_scale, 0.0f, 1.0f, 0.0f, 0.0f);
                
                /* For GQA: handled by ggml broadcasting */
                
                if (hp.use_flash_attn) {
                    /* Flash Attention path */
                    float scale = 1.0f / sqrtf((float)hp.head_dim);
                    
                    /* Reshape for flash attention: add batch dimension */
                    struct ggml_tensor *q_fa = ggml_cont(ctx_c, ggml_permute(ctx_c, q, 0, 2, 1, 3));
                    struct ggml_tensor *k_fa = ggml_cont(ctx_c, ggml_permute(ctx_c, k, 0, 2, 1, 3));
                    struct ggml_tensor *v_fa = ggml_cont(ctx_c, ggml_permute(ctx_c, v, 0, 2, 1, 3));
                    
                    /* Flash attention - NULL mask means causal masking */
                    attn_out = ggml_flash_attn_ext(ctx_c, q_fa, k_fa, v_fa, NULL, scale, 0.0f, 0.0f);
                    attn_out = ggml_reshape_3d(ctx_c, attn_out, hp.head_dim, hp.n_head, n_tokens);
                } else {
                    /* Standard scaled dot-product attention */
                    attn_out = build_standard_attention(ctx_c, q, k, v, hp.head_dim, 0);
                }
                
                /* Attention output: reshape to 2D and project */
                attn_out = ggml_reshape_2d(ctx_c, attn_out, hp.n_embd, n_tokens);
                cur = ggml_mul_mat(ctx_c, lw.wo, attn_out);
            }
            
            /* Post-attention normalization (gemma2, etc.) */
            if (lw.has_post_norm && lw.attn_post_norm) {
                cur = apply_rms_norm(ctx_c, cur, lw.attn_post_norm, hp.rms_norm_eps);
            }
            
            /* Residual connection after attention */
            cur = ggml_add(ctx_c, cur, residual);
            residual = cur;
            
            /* FFN: RMS norm -> SwiGLU/GELU -> down projection */
            cur = apply_rms_norm(ctx_c, cur, lw.ffn_norm, hp.rms_norm_eps);
            cur = build_ffn(ctx_c, cur, &lw);
            
            /* Post-FFN normalization (gemma2, etc.) */
            if (lw.has_post_norm && lw.ffn_post_norm) {
                cur = apply_rms_norm(ctx_c, cur, lw.ffn_post_norm, hp.rms_norm_eps);
            }
            
            /* Residual connection after FFN */
            cur = ggml_add(ctx_c, cur, residual);
        }
        
        /* Final norm and output projection */
        if (output_norm) {
            cur = apply_rms_norm(ctx_c, cur, output_norm, hp.rms_norm_eps);
        }
        
        /* Project to vocabulary (logits) */
        cur = ggml_mul_mat(ctx_c, output, cur);
        ggml_set_name(cur, "logits");
        
        /* Build graph */
        gf = ggml_new_graph(ctx_c);
        ggml_build_forward_expand(gf, cur);
    }
    
    /* Allocate compute buffer */
    allocr = ggml_gallocr_new(ggml_backend_get_default_buffer_type(backend));
    if (!ggml_gallocr_reserve(allocr, gf)) {
        ggml_gallocr_free(allocr);
        ggml_free(ctx_c);
        ggml_backend_free(backend);
        Safefree(tokens);
        croak("Failed to reserve compute allocator");
    }
    
    if (!ggml_gallocr_alloc_graph(allocr, gf)) {
        ggml_gallocr_free(allocr);
        ggml_free(ctx_c);
        ggml_backend_free(backend);
        Safefree(tokens);
        croak("Failed to allocate compute graph");
    }
    
    /* Set input token data */
    {
        struct ggml_tensor *inp = ggml_graph_get_tensor(gf, "inp_tokens");
        struct ggml_tensor *pos_tensor = ggml_graph_get_tensor(gf, "pos");
        struct ggml_tensor *mask_tensor = ggml_graph_get_tensor(gf, "kq_mask");
        
        if (inp) {
            ggml_backend_tensor_set(inp, tokens, 0, n_tokens * sizeof(int));
        }
        
        /* Set position indices (0, 1, 2, ..., n_tokens-1) */
        if (pos_tensor) {
            int *positions;
            int p;
            Newx(positions, n_tokens, int);
            for (p = 0; p < n_tokens; p++) {
                positions[p] = p;
            }
            ggml_backend_tensor_set(pos_tensor, positions, 0, n_tokens * sizeof(int));
            Safefree(positions);
        }
        
        /* Set causal attention mask: 0 for allowed, -inf for masked */
        if (mask_tensor) {
            float *mask_data;
            int row, col;
            Newx(mask_data, n_tokens * n_tokens, float);
            for (row = 0; row < n_tokens; row++) {
                for (col = 0; col < n_tokens; col++) {
                    /* Causal mask: can only attend to current and previous positions */
                    if (col <= row) {
                        mask_data[row * n_tokens + col] = 0.0f;
                    } else {
                        mask_data[row * n_tokens + col] = -INFINITY;
                    }
                }
            }
            ggml_backend_tensor_set(mask_tensor, mask_data, 0, n_tokens * n_tokens * sizeof(float));
            Safefree(mask_data);
        }
    }
    
    /* Run the forward pass */
    if (ggml_backend_graph_compute(backend, gf) != GGML_STATUS_SUCCESS) {
        ggml_gallocr_free(allocr);
        ggml_free(ctx_c);
        ggml_backend_free(backend);
        Safefree(tokens);
        croak("Failed to compute graph");
    }
    
    /* Extract logits from the last token */
    {
        struct ggml_tensor *logits_tensor = ggml_graph_get_tensor(gf, "logits");
        if (logits_tensor) {
            float *logits_data;
            int j;
            size_t logits_size = hp.n_vocab * sizeof(float);
            
            Newx(logits_data, hp.n_vocab, float);
            
            /* Get logits for last token */
            ggml_backend_tensor_get(logits_tensor, logits_data, 
                                    (n_tokens - 1) * hp.n_vocab * sizeof(float), logits_size);
            
            /* Return logits as array */
            EXTEND(SP, hp.n_vocab);
            for (j = 0; j < hp.n_vocab; j++) {
                mPUSHn(logits_data[j]);
            }
            
            Safefree(logits_data);
        }
    }
    
    /* Cleanup - note: ctx_w is model->ctx, don't free it */
    ggml_gallocr_free(allocr);
    ggml_free(ctx_c);
    ggml_backend_free(backend);
    Safefree(tokens);

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
    
    /* Sort by probability (simple bubble sort for now - ok for top_p sampling) */
    {
        int j, swapped;
        for (i = 0; i < n_vocab - 1; i++) {
            swapped = 0;
            for (j = 0; j < n_vocab - i - 1; j++) {
                if (logits[j] < logits[j + 1]) {
                    float tmp = logits[j];
                    int tmp_idx = indices[j];
                    logits[j] = logits[j + 1];
                    indices[j] = indices[j + 1];
                    logits[j + 1] = tmp;
                    indices[j + 1] = tmp_idx;
                    swapped = 1;
                }
            }
            if (!swapped) break;
            /* Early exit when we have enough probability mass */
            cumsum = 0;
            for (j = 0; j <= i; j++) cumsum += logits[j];
            if (cumsum >= top_p) break;
        }
    }
    
    /* Sample from top_p tokens */
    threshold = (float)rand() / (float)RAND_MAX * top_p;
    cumsum = 0.0f;
    RETVAL = indices[0];  /* Default to most likely */
    
    for (i = 0; i < n_vocab; i++) {
        cumsum += logits[i];
        if (cumsum >= threshold) {
            RETVAL = indices[i];
            break;
        }
        if (cumsum >= top_p) break;
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
                
                count = call_method("forward", G_ARRAY);
                
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

void
forward_with_cache(self, cache_sv, tokens_ref)
    SV *self
    SV *cache_sv
    SV *tokens_ref
PREINIT:
    HV *hv;
    SV **svp;
    LughModel *model;
    LughKVCache *cache;
    LughHyperparams hp;
    int i, n_tokens = 0;
    int *tokens = NULL;
    int pos_offset;  /* Starting position for new tokens */
    struct ggml_context *ctx_w = NULL;
    struct ggml_context *ctx_c = NULL;
    struct ggml_cgraph *gf = NULL;
    struct ggml_tensor *cur = NULL;
    struct ggml_tensor *inpL = NULL;
    ggml_backend_t backend = NULL;
    ggml_gallocr_t allocr = NULL;
    int n_kv;  /* Total KV length = n_cached + n_tokens */
    /* Arrays to track tensors for cache operations */
    struct ggml_tensor **k_cache_tensors = NULL;
    struct ggml_tensor **v_cache_tensors = NULL;
    struct ggml_tensor **k_new_tensors = NULL;
    struct ggml_tensor **v_new_tensors = NULL;
PPCODE:
    /* Get model */
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_model", 6, 0);
    if (!svp || !*svp) croak("No model in inference object");
    model = get_lugh_model(aTHX_ *svp);
    if (!model) croak("Invalid model");
    
    /* Get cache */
    cache = get_lugh_kvcache(aTHX_ cache_sv);
    if (!cache) croak("Invalid KV cache");
    
    /* Parse tokens from array ref */
    if (!SvROK(tokens_ref) || SvTYPE(SvRV(tokens_ref)) != SVt_PVAV) {
        croak("tokens must be an array reference");
    }
    {
        AV *av = (AV*)SvRV(tokens_ref);
        n_tokens = av_len(av) + 1;
        if (n_tokens == 0) {
            croak("forward_with_cache() requires at least one token");
        }
        Newx(tokens, n_tokens, int);
        for (i = 0; i < n_tokens; i++) {
            SV **elem = av_fetch(av, i, 0);
            tokens[i] = elem ? SvIV(*elem) : 0;
        }
    }
    
    /* Lock cache and get position offset */
    KVCACHE_LOCK(cache);
    pos_offset = cache->n_cached;
    n_kv = pos_offset + n_tokens;  /* Total sequence length */
    
    /* Check context overflow */
    if (n_kv > cache->n_ctx) {
        KVCACHE_UNLOCK(cache);
        Safefree(tokens);
        croak("KV cache overflow: %d tokens exceed context size %d", n_kv, cache->n_ctx);
    }
    
    /* Get hyperparameters using helper */
    extract_hyperparams(aTHX_ hv, model, &hp);
    
    ctx_w = model->ctx;
    
    /* Initialize backend based on backend_name */
    if (strcmp(hp.backend_name, "auto") == 0) {
        backend = init_best_backend(hp.n_threads);
    } else {
        backend = init_backend_by_name(hp.backend_name, hp.n_threads);
    }
    if (!backend) {
        KVCACHE_UNLOCK(cache);
        Safefree(tokens);
        croak("Failed to initialize backend '%s'", hp.backend_name);
    }
    
    /* Create compute context using helper */
    ctx_c = create_compute_context(512 * 1024 * 1024);
    if (!ctx_c) {
        ggml_backend_free(backend);
        KVCACHE_UNLOCK(cache);
        Safefree(tokens);
        croak("Failed to create compute context");
    }
    
    /* Allocate arrays to track cache tensors */
    Newxz(k_cache_tensors, hp.n_layer, struct ggml_tensor *);
    Newxz(v_cache_tensors, hp.n_layer, struct ggml_tensor *);
    Newxz(k_new_tensors, hp.n_layer, struct ggml_tensor *);
    Newxz(v_new_tensors, hp.n_layer, struct ggml_tensor *);
    
    /* Build forward pass graph with KV cache */
    {
        struct ggml_tensor *tok_embd = ggml_get_tensor(ctx_w, "token_embd.weight");
        struct ggml_tensor *output_norm = ggml_get_tensor(ctx_w, "output_norm.weight");
        struct ggml_tensor *output = ggml_get_tensor(ctx_w, "output.weight");
        struct ggml_tensor *pos;
        int layer;
        int n_kv_dim = hp.n_head_kv * hp.head_dim;
        
        if (!output) output = tok_embd;
        
        if (!tok_embd) {
            ggml_free(ctx_c);
            ggml_backend_free(backend);
            KVCACHE_UNLOCK(cache);
            Safefree(tokens);
            croak("Required tensors not found in model");
        }
        
        /* Position tensor - positions start at pos_offset */
        pos = ggml_new_tensor_1d(ctx_c, GGML_TYPE_I32, n_tokens);
        ggml_set_name(pos, "pos");
        
        /* Create input embedding */
        {
            struct ggml_tensor *inp_tokens = ggml_new_tensor_1d(ctx_c, GGML_TYPE_I32, n_tokens);
            ggml_set_name(inp_tokens, "inp_tokens");
            inpL = ggml_get_rows(ctx_c, tok_embd, inp_tokens);
            ggml_set_name(inpL, "inp_embd");
        }
        
        cur = inpL;
        
        /* Process each transformer layer with KV cache */
        for (layer = 0; layer < hp.n_layer; layer++) {
            LughLayerWeights lw;
            struct ggml_tensor *residual;
            
            /* Get layer weights using architecture-aware helper */
            if (!get_layer_weights_for_arch(ctx_w, layer, &lw, hp.arch_type)) {
                continue;
            }
            
            residual = cur;
            
            /* RMS Norm before attention using helper */
            cur = apply_rms_norm(ctx_c, cur, lw.attn_norm, hp.rms_norm_eps);
            
            /* Self-attention with KV cache */
            {
                struct ggml_tensor *q, *k_new, *v_new;
                struct ggml_tensor *k_full, *v_full;
                struct ggml_tensor *attn_out;
                
                /* Compute Q, K, V for new tokens - handle combined or separate */
                if (lw.has_combined_qkv) {
                    /* Split combined QKV tensor */
                    struct ggml_tensor *qkv = ggml_mul_mat(ctx_c, lw.wqkv, cur);
                    int qkv_dim = hp.n_embd + 2 * (hp.n_head_kv * hp.head_dim);
                    q = ggml_view_2d(ctx_c, qkv, hp.n_embd, n_tokens, 
                                     qkv_dim * sizeof(float), 0);
                    k_new = ggml_view_2d(ctx_c, qkv, hp.n_head_kv * hp.head_dim, n_tokens,
                                     qkv_dim * sizeof(float), hp.n_embd * sizeof(float));
                    v_new = ggml_view_2d(ctx_c, qkv, hp.n_head_kv * hp.head_dim, n_tokens,
                                     qkv_dim * sizeof(float), (hp.n_embd + hp.n_head_kv * hp.head_dim) * sizeof(float));
                    /* Need to reshape for attention */
                    q = ggml_reshape_3d(ctx_c, q, hp.head_dim, hp.n_head, n_tokens);
                    k_new = ggml_reshape_3d(ctx_c, k_new, hp.head_dim, hp.n_head_kv, n_tokens);
                    v_new = ggml_reshape_3d(ctx_c, v_new, hp.head_dim, hp.n_head_kv, n_tokens);
                } else {
                    q = ggml_mul_mat(ctx_c, lw.wq, cur);
                    k_new = ggml_mul_mat(ctx_c, lw.wk, cur);
                    v_new = ggml_mul_mat(ctx_c, lw.wv, cur);
                    
                    /* Reshape for attention */
                    q = ggml_reshape_3d(ctx_c, q, hp.head_dim, hp.n_head, n_tokens);
                    k_new = ggml_reshape_3d(ctx_c, k_new, hp.head_dim, hp.n_head_kv, n_tokens);
                    v_new = ggml_reshape_3d(ctx_c, v_new, hp.head_dim, hp.n_head_kv, n_tokens);
                }
                
                /* Apply RoPE with position offset */
                q = ggml_rope_ext(ctx_c, q, pos, NULL, hp.n_rot, 0, hp.n_ctx,
                                  hp.rope_freq_base, hp.rope_freq_scale, 0.0f, 1.0f, 0.0f, 0.0f);
                k_new = ggml_rope_ext(ctx_c, k_new, pos, NULL, hp.n_rot, 0, hp.n_ctx,
                                      hp.rope_freq_base, hp.rope_freq_scale, 0.0f, 1.0f, 0.0f, 0.0f);
                
                /* Create tensors for cached K/V */
                if (pos_offset > 0) {
                    /* We have cached K/V - need to concatenate */
                    char k_cache_name[64], v_cache_name[64];
                    struct ggml_tensor *k_cached, *v_cached;
                    
                    snprintf(k_cache_name, sizeof(k_cache_name), "k_cache_%d", layer);
                    snprintf(v_cache_name, sizeof(v_cache_name), "v_cache_%d", layer);
                    
                    /* Create tensors for cached data */
                    k_cached = ggml_new_tensor_3d(ctx_c, GGML_TYPE_F32, hp.head_dim, hp.n_head_kv, pos_offset);
                    ggml_set_name(k_cached, k_cache_name);
                    v_cached = ggml_new_tensor_3d(ctx_c, GGML_TYPE_F32, hp.head_dim, hp.n_head_kv, pos_offset);
                    ggml_set_name(v_cached, v_cache_name);
                    
                    /* Store tensor pointers for later data setting */
                    k_cache_tensors[layer] = k_cached;
                    v_cache_tensors[layer] = v_cached;
                    
                    /* Concatenate cached + new along sequence dimension (dim 2) */
                    k_full = ggml_concat(ctx_c, k_cached, k_new, 2);
                    v_full = ggml_concat(ctx_c, v_cached, v_new, 2);
                } else {
                    /* No cache - just use new K/V */
                    k_full = k_new;
                    v_full = v_new;
                }
                
                /* Store new K/V tensor pointers for later extraction */
                /* Use ggml_cpy to create output tensors that won't be aliased */
                {
                    char k_new_name[64], v_new_name[64];
                    struct ggml_tensor *k_out, *v_out;
                    
                    snprintf(k_new_name, sizeof(k_new_name), "k_new_%d", layer);
                    snprintf(v_new_name, sizeof(v_new_name), "v_new_%d", layer);
                    
                    /* Create destination tensors for output */
                    k_out = ggml_new_tensor_3d(ctx_c, GGML_TYPE_F32, k_new->ne[0], k_new->ne[1], k_new->ne[2]);
                    v_out = ggml_new_tensor_3d(ctx_c, GGML_TYPE_F32, v_new->ne[0], v_new->ne[1], v_new->ne[2]);
                    
                    ggml_set_name(k_out, k_new_name);
                    ggml_set_name(v_out, v_new_name);
                    
                    /* Copy k_new/v_new to output tensors */
                    k_out = ggml_cpy(ctx_c, k_new, k_out);
                    v_out = ggml_cpy(ctx_c, v_new, v_out);
                    
                    k_new_tensors[layer] = k_out;
                    v_new_tensors[layer] = v_out;
                }
                
                /* Standard attention (no flash attention for simplicity) */
                {
                    float scale = 1.0f / sqrtf((float)hp.head_dim);
                    struct ggml_tensor *kq;
                    struct ggml_tensor *v_t;
                    
                    /* Permute: [head_dim, n_head, seq] -> [head_dim, seq, n_head] */
                    q = ggml_permute(ctx_c, q, 0, 2, 1, 3);
                    k_full = ggml_permute(ctx_c, k_full, 0, 2, 1, 3);
                    v_full = ggml_permute(ctx_c, v_full, 0, 2, 1, 3);
                    
                    /* QK^T: [n_kv, n_tokens, n_head] */
                    kq = ggml_mul_mat(ctx_c, k_full, q);
                    kq = ggml_scale(ctx_c, kq, scale);
                    
                    /* Causal mask: for each query position, can attend to all positions <= query_pos + pos_offset */
                    /* Using diag_mask_inf with offset to handle cached positions */
                    kq = ggml_diag_mask_inf(ctx_c, kq, pos_offset);
                    kq = ggml_soft_max(ctx_c, kq);
                    
                    /* Attention @ V */
                    v_t = ggml_cont(ctx_c, ggml_transpose(ctx_c, v_full));
                    attn_out = ggml_mul_mat(ctx_c, v_t, kq);
                    attn_out = ggml_cont(ctx_c, ggml_permute(ctx_c, attn_out, 0, 2, 1, 3));
                }
                
                /* Reshape and project */
                attn_out = ggml_reshape_2d(ctx_c, attn_out, hp.n_embd, n_tokens);
                cur = ggml_mul_mat(ctx_c, lw.wo, attn_out);
            }
            
            /* Post-attention normalization (gemma2, etc.) */
            if (lw.has_post_norm && lw.attn_post_norm) {
                cur = apply_rms_norm(ctx_c, cur, lw.attn_post_norm, hp.rms_norm_eps);
            }
            
            /* Residual + FFN using helpers */
            cur = ggml_add(ctx_c, cur, residual);
            residual = cur;
            
            cur = apply_rms_norm(ctx_c, cur, lw.ffn_norm, hp.rms_norm_eps);
            cur = build_ffn(ctx_c, cur, &lw);
            
            /* Post-FFN normalization (gemma2, etc.) */
            if (lw.has_post_norm && lw.ffn_post_norm) {
                cur = apply_rms_norm(ctx_c, cur, lw.ffn_post_norm, hp.rms_norm_eps);
            }
            
            cur = ggml_add(ctx_c, cur, residual);
        }
        
        /* Final norm and output projection */
        if (output_norm) {
            cur = apply_rms_norm(ctx_c, cur, output_norm, hp.rms_norm_eps);
        }
        
        cur = ggml_mul_mat(ctx_c, output, cur);
        ggml_set_name(cur, "logits");
        
        /* Build graph */
        gf = ggml_new_graph(ctx_c);
        ggml_build_forward_expand(gf, cur);
        
        /* Also need to include k_new/v_new tensors in graph for extraction */
        for (layer = 0; layer < hp.n_layer; layer++) {
            /* Use stored tensor pointers instead of looking up by name */
            if (k_new_tensors[layer]) ggml_build_forward_expand(gf, k_new_tensors[layer]);
            if (v_new_tensors[layer]) ggml_build_forward_expand(gf, v_new_tensors[layer]);
        }
    }
    
    /* Allocate compute buffer */
    allocr = ggml_gallocr_new(ggml_backend_get_default_buffer_type(backend));
    if (!ggml_gallocr_reserve(allocr, gf)) {
        ggml_gallocr_free(allocr);
        ggml_free(ctx_c);
        ggml_backend_free(backend);
        KVCACHE_UNLOCK(cache);
        Safefree(tokens);
        croak("Failed to reserve compute allocator");
    }
    
    if (!ggml_gallocr_alloc_graph(allocr, gf)) {
        ggml_gallocr_free(allocr);
        ggml_free(ctx_c);
        ggml_backend_free(backend);
        KVCACHE_UNLOCK(cache);
        Safefree(tokens);
        croak("Failed to allocate compute graph");
    }
    
    /* Set input data */
    {
        struct ggml_tensor *inp = ggml_graph_get_tensor(gf, "inp_tokens");
        struct ggml_tensor *pos_tensor = ggml_graph_get_tensor(gf, "pos");
        
        if (inp) {
            ggml_backend_tensor_set(inp, tokens, 0, n_tokens * sizeof(int));
        }
        
        /* Set positions starting from pos_offset */
        if (pos_tensor) {
            int *positions;
            int p;
            Newx(positions, n_tokens, int);
            for (p = 0; p < n_tokens; p++) {
                positions[p] = pos_offset + p;
            }
            ggml_backend_tensor_set(pos_tensor, positions, 0, n_tokens * sizeof(int));
            Safefree(positions);
        }
        
        /* Set cached K/V data using stored tensor pointers */
        if (pos_offset > 0) {
            int layer;
            for (layer = 0; layer < hp.n_layer; layer++) {
                size_t cache_size = pos_offset * cache->n_head_kv * cache->head_dim * sizeof(float);
                
                if (k_cache_tensors[layer] && cache->k_cache[layer]) {
                    ggml_backend_tensor_set(k_cache_tensors[layer], cache->k_cache[layer], 0, cache_size);
                }
                if (v_cache_tensors[layer] && cache->v_cache[layer]) {
                    ggml_backend_tensor_set(v_cache_tensors[layer], cache->v_cache[layer], 0, cache_size);
                }
            }
        }
    }
    
    /* Run the forward pass */
    if (ggml_backend_graph_compute(backend, gf) != GGML_STATUS_SUCCESS) {
        ggml_gallocr_free(allocr);
        ggml_free(ctx_c);
        ggml_backend_free(backend);
        KVCACHE_UNLOCK(cache);
        Safefree(tokens);
        croak("Failed to compute graph");
    }
    
    /* Update cache with new K/V values */
    {
        int layer;
        int n_kv_dim = cache->n_head_kv * cache->head_dim;
        
        for (layer = 0; layer < hp.n_layer; layer++) {
            struct ggml_tensor *k_new_tensor, *v_new_tensor;
            size_t new_size = n_tokens * n_kv_dim * sizeof(float);
            size_t offset = pos_offset * n_kv_dim * sizeof(float);
            
            /* Use stored tensor pointers */
            k_new_tensor = k_new_tensors[layer];
            v_new_tensor = v_new_tensors[layer];
            
            if (k_new_tensor && cache->k_cache[layer]) {
                /* Copy new K values to cache at the correct position */
                float *temp;
                Newx(temp, n_tokens * n_kv_dim, float);
                ggml_backend_tensor_get(k_new_tensor, temp, 0, new_size);
                memcpy((char*)cache->k_cache[layer] + offset, temp, new_size);
                Safefree(temp);
            }
            if (v_new_tensor && cache->v_cache[layer]) {
                float *temp;
                Newx(temp, n_tokens * n_kv_dim, float);
                ggml_backend_tensor_get(v_new_tensor, temp, 0, new_size);
                memcpy((char*)cache->v_cache[layer] + offset, temp, new_size);
                Safefree(temp);
            }
        }
        
        /* Update cached count */
        cache->n_cached = n_kv;
    }
    
    /* Extract logits */
    {
        struct ggml_tensor *logits_tensor = ggml_graph_get_tensor(gf, "logits");
        if (logits_tensor) {
            float *logits_data;
            int j;
            size_t logits_size = hp.n_vocab * sizeof(float);
            
            Newx(logits_data, hp.n_vocab, float);
            
            /* Get logits for last token */
            ggml_backend_tensor_get(logits_tensor, logits_data,
                                    (n_tokens - 1) * hp.n_vocab * sizeof(float), logits_size);
            
            EXTEND(SP, hp.n_vocab);
            for (j = 0; j < hp.n_vocab; j++) {
                mPUSHn(logits_data[j]);
            }
            
            Safefree(logits_data);
        }
    }
    
    /* Cleanup */
    Safefree(k_cache_tensors);
    Safefree(v_cache_tensors);
    Safefree(k_new_tensors);
    Safefree(v_new_tensors);
    ggml_gallocr_free(allocr);
    ggml_free(ctx_c);
    ggml_backend_free(backend);
    KVCACHE_UNLOCK(cache);
    Safefree(tokens);

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

void
forward_with_pool(self, pool_sv, tokens_ref)
    SV *self
    SV *pool_sv
    SV *tokens_ref
PREINIT:
    HV *hv, *pool_hv;
    SV **svp;
    LughModel *model;
    LughMemoryPool *pool;
    int *tokens = NULL;
    int n_tokens = 0;
    int i;
    LughHyperparams hp;
    struct ggml_context *ctx_w = NULL;
    struct ggml_cgraph *gf = NULL;
    struct ggml_tensor *cur = NULL;
    struct ggml_tensor *inpL = NULL;
PPCODE:
    /* Get model */
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_model", 6, 0);
    if (!svp || !*svp) croak("No model in inference object");
    model = get_lugh_model(aTHX_ *svp);
    if (!model) croak("Invalid model");
    
    /* Get memory pool */
    if (!SvROK(pool_sv) || SvTYPE(SvRV(pool_sv)) != SVt_PVHV) {
        croak("pool must be a Lugh::MemoryPool object");
    }
    pool_hv = (HV*)SvRV(pool_sv);
    svp = hv_fetch(pool_hv, "_pool_id", 8, 0);
    if (!svp || !*svp) croak("Invalid memory pool");
    pool = get_mempool_by_id(SvIV(*svp));
    if (!pool) croak("Memory pool not found or inactive");
    
    /* Parse tokens */
    if (!SvROK(tokens_ref) || SvTYPE(SvRV(tokens_ref)) != SVt_PVAV) {
        croak("tokens must be an array reference");
    }
    {
        AV *av = (AV*)SvRV(tokens_ref);
        n_tokens = av_len(av) + 1;
        if (n_tokens == 0) croak("forward_with_pool requires at least one token");
        Newx(tokens, n_tokens, int);
        for (i = 0; i < n_tokens; i++) {
            SV **elem = av_fetch(av, i, 0);
            tokens[i] = elem ? SvIV(*elem) : 0;
        }
    }
    
    extract_hyperparams(aTHX_ hv, model, &hp);
    ctx_w = model->ctx;
    
    POOL_LOCK(pool);
    
    /* Reset the pool's compute context for this run (use unlocked version since we hold lock) */
    if (!reset_memory_pool_unlocked(pool)) {
        POOL_UNLOCK(pool);
        Safefree(tokens);
        croak("Failed to reset memory pool");
    }
    
    /* Build forward pass using pool's resources */
    {
        struct ggml_tensor *tok_embd = ggml_get_tensor(ctx_w, "token_embd.weight");
        struct ggml_tensor *output_norm = ggml_get_tensor(ctx_w, "output_norm.weight");
        struct ggml_tensor *output = ggml_get_tensor(ctx_w, "output.weight");
        struct ggml_tensor *pos;
        int layer;
        
        if (!output) output = tok_embd;
        if (!tok_embd) {
            POOL_UNLOCK(pool);
            Safefree(tokens);
            croak("Required tensors not found");
        }
        
        pos = ggml_new_tensor_1d(pool->ctx_compute, GGML_TYPE_I32, n_tokens);
        ggml_set_name(pos, "pos");
        
        {
            struct ggml_tensor *inp_tokens = ggml_new_tensor_1d(pool->ctx_compute, GGML_TYPE_I32, n_tokens);
            ggml_set_name(inp_tokens, "inp_tokens");
            inpL = ggml_get_rows(pool->ctx_compute, tok_embd, inp_tokens);
            ggml_set_name(inpL, "inp_embd");
        }
        
        cur = inpL;
        
        /* Process transformer layers */
        for (layer = 0; layer < hp.n_layer; layer++) {
            LughLayerWeights lw;
            struct ggml_tensor *residual;
            
            if (!get_layer_weights_for_arch(ctx_w, layer, &lw, hp.arch_type)) continue;
            
            residual = cur;
            cur = apply_rms_norm(pool->ctx_compute, cur, lw.attn_norm, hp.rms_norm_eps);
            
            /* Self-attention */
            {
                struct ggml_tensor *q, *k, *v;
                struct ggml_tensor *attn_out;
                
                if (lw.has_combined_qkv) {
                    /* Split combined QKV tensor */
                    struct ggml_tensor *qkv = ggml_mul_mat(pool->ctx_compute, lw.wqkv, cur);
                    int qkv_dim = hp.n_embd + 2 * (hp.n_head_kv * hp.head_dim);
                    q = ggml_view_2d(pool->ctx_compute, qkv, hp.n_embd, n_tokens, 
                                     qkv_dim * sizeof(float), 0);
                    k = ggml_view_2d(pool->ctx_compute, qkv, hp.n_head_kv * hp.head_dim, n_tokens,
                                     qkv_dim * sizeof(float), hp.n_embd * sizeof(float));
                    v = ggml_view_2d(pool->ctx_compute, qkv, hp.n_head_kv * hp.head_dim, n_tokens,
                                     qkv_dim * sizeof(float), (hp.n_embd + hp.n_head_kv * hp.head_dim) * sizeof(float));
                } else {
                    q = ggml_mul_mat(pool->ctx_compute, lw.wq, cur);
                    k = ggml_mul_mat(pool->ctx_compute, lw.wk, cur);
                    v = ggml_mul_mat(pool->ctx_compute, lw.wv, cur);
                }
                
                q = ggml_reshape_3d(pool->ctx_compute, q, hp.head_dim, hp.n_head, n_tokens);
                k = ggml_reshape_3d(pool->ctx_compute, k, hp.head_dim, hp.n_head_kv, n_tokens);
                v = ggml_reshape_3d(pool->ctx_compute, v, hp.head_dim, hp.n_head_kv, n_tokens);
                
                q = ggml_rope_ext(pool->ctx_compute, q, pos, NULL, hp.n_rot, 0, hp.n_ctx,
                                  hp.rope_freq_base, hp.rope_freq_scale, 0.0f, 1.0f, 0.0f, 0.0f);
                k = ggml_rope_ext(pool->ctx_compute, k, pos, NULL, hp.n_rot, 0, hp.n_ctx,
                                  hp.rope_freq_base, hp.rope_freq_scale, 0.0f, 1.0f, 0.0f, 0.0f);
                
                attn_out = build_standard_attention(pool->ctx_compute, q, k, v, hp.head_dim, 0);
                attn_out = ggml_reshape_2d(pool->ctx_compute, attn_out, hp.n_embd, n_tokens);
                attn_out = ggml_mul_mat(pool->ctx_compute, lw.wo, attn_out);
                
                /* Post-attention norm (Gemma2, etc.) */
                if (lw.has_post_norm && lw.attn_post_norm) {
                    attn_out = apply_rms_norm(pool->ctx_compute, attn_out, lw.attn_post_norm, hp.rms_norm_eps);
                }
                
                cur = ggml_add(pool->ctx_compute, residual, attn_out);
            }
            
            /* FFN */
            residual = cur;
            cur = apply_rms_norm(pool->ctx_compute, cur, lw.ffn_norm, hp.rms_norm_eps);
            cur = build_ffn(pool->ctx_compute, cur, &lw);
            
            /* Post-FFN norm (Gemma2, etc.) */
            if (lw.has_post_norm && lw.ffn_post_norm) {
                cur = apply_rms_norm(pool->ctx_compute, cur, lw.ffn_post_norm, hp.rms_norm_eps);
            }
            
            cur = ggml_add(pool->ctx_compute, residual, cur);
        }
        
        /* Final norm and output projection */
        cur = apply_rms_norm(pool->ctx_compute, cur, output_norm, hp.rms_norm_eps);
        cur = ggml_mul_mat(pool->ctx_compute, output, cur);
        ggml_set_name(cur, "logits");
        
        /* Build and allocate graph */
        gf = ggml_new_graph(pool->ctx_compute);
        ggml_build_forward_expand(gf, cur);
        
        if (!ggml_gallocr_alloc_graph(pool->allocator, gf)) {
            POOL_UNLOCK(pool);
            Safefree(tokens);
            croak("Failed to allocate graph with pool");
        }
        
        /* Set input data */
        {
            struct ggml_tensor *inp_tokens_tensor = ggml_graph_get_tensor(gf, "inp_tokens");
            struct ggml_tensor *pos_tensor = ggml_graph_get_tensor(gf, "pos");
            int *pos_data;
            
            if (inp_tokens_tensor) {
                ggml_backend_tensor_set(inp_tokens_tensor, tokens, 0, n_tokens * sizeof(int));
            }
            if (pos_tensor) {
                Newx(pos_data, n_tokens, int);
                for (i = 0; i < n_tokens; i++) pos_data[i] = i;
                ggml_backend_tensor_set(pos_tensor, pos_data, 0, n_tokens * sizeof(int));
                Safefree(pos_data);
            }
        }
    }
    
    /* Compute */
    if (ggml_backend_graph_compute(pool->backend, gf) != GGML_STATUS_SUCCESS) {
        POOL_UNLOCK(pool);
        Safefree(tokens);
        croak("Failed to compute graph with pool");
    }
    
    /* Extract logits */
    {
        struct ggml_tensor *logits_tensor = ggml_graph_get_tensor(gf, "logits");
        if (logits_tensor) {
            float *logits_data;
            int j;
            size_t logits_size = hp.n_vocab * sizeof(float);
            
            Newx(logits_data, hp.n_vocab, float);
            ggml_backend_tensor_get(logits_tensor, logits_data,
                                    (n_tokens - 1) * hp.n_vocab * sizeof(float), logits_size);
            
            EXTEND(SP, hp.n_vocab);
            for (j = 0; j < hp.n_vocab; j++) {
                mPUSHn(logits_data[j]);
            }
            Safefree(logits_data);
        }
    }
    
    POOL_UNLOCK(pool);
    Safefree(tokens);

void
forward_batch(self, sequences_ref)
    SV *self
    SV *sequences_ref
PREINIT:
    HV *hv;
    SV **svp;
    LughModel *model;
    AV *sequences_av;
    int n_sequences = 0;
    int **all_tokens = NULL;
    int *seq_lengths = NULL;
    int max_len = 0;
    int total_tokens = 0;
    int i, j;
    LughHyperparams hp;
    struct ggml_context *ctx_w = NULL;
    struct ggml_context *ctx_c = NULL;
    ggml_backend_t backend = NULL;
    ggml_gallocr_t allocr = NULL;
    AV *results_av;
PPCODE:
    /* Get model */
    hv = (HV*)SvRV(self);
    svp = hv_fetch(hv, "_model", 6, 0);
    if (!svp || !*svp) croak("No model in inference object");
    model = get_lugh_model(aTHX_ *svp);
    if (!model) croak("Invalid model");
    
    /* Parse sequences - array of array refs */
    if (!SvROK(sequences_ref) || SvTYPE(SvRV(sequences_ref)) != SVt_PVAV) {
        croak("sequences must be an array of array references");
    }
    sequences_av = (AV*)SvRV(sequences_ref);
    n_sequences = av_len(sequences_av) + 1;
    if (n_sequences == 0) croak("forward_batch requires at least one sequence");
    
    /* Parse each sequence */
    Newxz(all_tokens, n_sequences, int*);
    Newxz(seq_lengths, n_sequences, int);
    
    for (i = 0; i < n_sequences; i++) {
        SV **seq_svp = av_fetch(sequences_av, i, 0);
        if (!seq_svp || !SvROK(*seq_svp) || SvTYPE(SvRV(*seq_svp)) != SVt_PVAV) {
            for (j = 0; j < i; j++) Safefree(all_tokens[j]);
            Safefree(all_tokens);
            Safefree(seq_lengths);
            croak("Each sequence must be an array reference");
        }
        AV *seq_av = (AV*)SvRV(*seq_svp);
        seq_lengths[i] = av_len(seq_av) + 1;
        total_tokens += seq_lengths[i];
        if (seq_lengths[i] > max_len) max_len = seq_lengths[i];
        
        Newx(all_tokens[i], seq_lengths[i], int);
        for (j = 0; j < seq_lengths[i]; j++) {
            SV **elem = av_fetch(seq_av, j, 0);
            all_tokens[i][j] = elem ? SvIV(*elem) : 0;
        }
    }
    
    extract_hyperparams(aTHX_ hv, model, &hp);
    ctx_w = model->ctx;
    
    /* Initialize backend */
    if (strcmp(hp.backend_name, "auto") == 0) {
        backend = init_best_backend(hp.n_threads);
    } else {
        backend = init_backend_by_name(hp.backend_name, hp.n_threads);
    }
    if (!backend) {
        for (i = 0; i < n_sequences; i++) Safefree(all_tokens[i]);
        Safefree(all_tokens);
        Safefree(seq_lengths);
        croak("Failed to initialize backend");
    }
    
    /* Create compute context */
    ctx_c = create_compute_context(512 * 1024 * 1024);
    if (!ctx_c) {
        ggml_backend_free(backend);
        for (i = 0; i < n_sequences; i++) Safefree(all_tokens[i]);
        Safefree(all_tokens);
        Safefree(seq_lengths);
        croak("Failed to create compute context");
    }
    
    /* Create result array */
    results_av = newAV();
    
    /* Process each sequence (sequential batch - each gets its own forward pass) */
    for (i = 0; i < n_sequences; i++) {
        struct ggml_context *seq_ctx = create_compute_context(512 * 1024 * 1024);
        struct ggml_cgraph *gf = NULL;
        struct ggml_tensor *cur = NULL, *inpL = NULL;
        AV *logits_av = newAV();
        
        if (!seq_ctx) {
            av_push(results_av, newRV_noinc((SV*)newAV()));  /* empty result */
            continue;
        }
        
        /* Build forward pass for this sequence */
        {
            struct ggml_tensor *tok_embd = ggml_get_tensor(ctx_w, "token_embd.weight");
            struct ggml_tensor *output_norm = ggml_get_tensor(ctx_w, "output_norm.weight");
            struct ggml_tensor *output = ggml_get_tensor(ctx_w, "output.weight");
            struct ggml_tensor *pos;
            int layer;
            int n_tokens = seq_lengths[i];
            
            if (!output) output = tok_embd;
            
            pos = ggml_new_tensor_1d(seq_ctx, GGML_TYPE_I32, n_tokens);
            ggml_set_name(pos, "pos");
            
            {
                struct ggml_tensor *inp_tokens = ggml_new_tensor_1d(seq_ctx, GGML_TYPE_I32, n_tokens);
                ggml_set_name(inp_tokens, "inp_tokens");
                inpL = ggml_get_rows(seq_ctx, tok_embd, inp_tokens);
            }
            
            cur = inpL;
            
            for (layer = 0; layer < hp.n_layer; layer++) {
                LughLayerWeights lw;
                struct ggml_tensor *residual;
                
                if (!get_layer_weights_for_arch(ctx_w, layer, &lw, hp.arch_type)) continue;
                
                residual = cur;
                cur = apply_rms_norm(seq_ctx, cur, lw.attn_norm, hp.rms_norm_eps);
                
                {
                    struct ggml_tensor *q, *k, *v;
                    struct ggml_tensor *attn_out;
                    
                    if (lw.has_combined_qkv) {
                        /* Split combined QKV tensor */
                        struct ggml_tensor *qkv = ggml_mul_mat(seq_ctx, lw.wqkv, cur);
                        int qkv_dim = hp.n_embd + 2 * (hp.n_head_kv * hp.head_dim);
                        q = ggml_view_2d(seq_ctx, qkv, hp.n_embd, n_tokens, 
                                         qkv_dim * sizeof(float), 0);
                        k = ggml_view_2d(seq_ctx, qkv, hp.n_head_kv * hp.head_dim, n_tokens,
                                         qkv_dim * sizeof(float), hp.n_embd * sizeof(float));
                        v = ggml_view_2d(seq_ctx, qkv, hp.n_head_kv * hp.head_dim, n_tokens,
                                         qkv_dim * sizeof(float), (hp.n_embd + hp.n_head_kv * hp.head_dim) * sizeof(float));
                    } else {
                        q = ggml_mul_mat(seq_ctx, lw.wq, cur);
                        k = ggml_mul_mat(seq_ctx, lw.wk, cur);
                        v = ggml_mul_mat(seq_ctx, lw.wv, cur);
                    }
                    
                    q = ggml_reshape_3d(seq_ctx, q, hp.head_dim, hp.n_head, n_tokens);
                    k = ggml_reshape_3d(seq_ctx, k, hp.head_dim, hp.n_head_kv, n_tokens);
                    v = ggml_reshape_3d(seq_ctx, v, hp.head_dim, hp.n_head_kv, n_tokens);
                    
                    q = ggml_rope_ext(seq_ctx, q, pos, NULL, hp.n_rot, 0, hp.n_ctx,
                                      hp.rope_freq_base, hp.rope_freq_scale, 0.0f, 1.0f, 0.0f, 0.0f);
                    k = ggml_rope_ext(seq_ctx, k, pos, NULL, hp.n_rot, 0, hp.n_ctx,
                                      hp.rope_freq_base, hp.rope_freq_scale, 0.0f, 1.0f, 0.0f, 0.0f);
                    
                    attn_out = build_standard_attention(seq_ctx, q, k, v, hp.head_dim, 0);
                    attn_out = ggml_reshape_2d(seq_ctx, attn_out, hp.n_embd, n_tokens);
                    attn_out = ggml_mul_mat(seq_ctx, lw.wo, attn_out);
                    
                    /* Post-attention norm (Gemma2, etc.) */
                    if (lw.has_post_norm && lw.attn_post_norm) {
                        attn_out = apply_rms_norm(seq_ctx, attn_out, lw.attn_post_norm, hp.rms_norm_eps);
                    }
                    
                    cur = ggml_add(seq_ctx, residual, attn_out);
                }
                
                residual = cur;
                cur = apply_rms_norm(seq_ctx, cur, lw.ffn_norm, hp.rms_norm_eps);
                cur = build_ffn(seq_ctx, cur, &lw);
                
                /* Post-FFN norm (Gemma2, etc.) */
                if (lw.has_post_norm && lw.ffn_post_norm) {
                    cur = apply_rms_norm(seq_ctx, cur, lw.ffn_post_norm, hp.rms_norm_eps);
                }
                
                cur = ggml_add(seq_ctx, residual, cur);
            }
            
            cur = apply_rms_norm(seq_ctx, cur, output_norm, hp.rms_norm_eps);
            cur = ggml_mul_mat(seq_ctx, output, cur);
            ggml_set_name(cur, "logits");
            
            gf = ggml_new_graph(seq_ctx);
            ggml_build_forward_expand(gf, cur);
            
            /* Allocate and set inputs */
            allocr = ggml_gallocr_new(ggml_backend_get_default_buffer_type(backend));
            if (ggml_gallocr_alloc_graph(allocr, gf)) {
                struct ggml_tensor *inp_tokens_tensor = ggml_graph_get_tensor(gf, "inp_tokens");
                struct ggml_tensor *pos_tensor = ggml_graph_get_tensor(gf, "pos");
                
                if (inp_tokens_tensor) {
                    ggml_backend_tensor_set(inp_tokens_tensor, all_tokens[i], 0, n_tokens * sizeof(int));
                }
                if (pos_tensor) {
                    int *pos_data;
                    Newx(pos_data, n_tokens, int);
                    for (j = 0; j < n_tokens; j++) pos_data[j] = j;
                    ggml_backend_tensor_set(pos_tensor, pos_data, 0, n_tokens * sizeof(int));
                    Safefree(pos_data);
                }
                
                /* Compute */
                if (ggml_backend_graph_compute(backend, gf) == GGML_STATUS_SUCCESS) {
                    struct ggml_tensor *logits_tensor = ggml_graph_get_tensor(gf, "logits");
                    if (logits_tensor) {
                        float *logits_data;
                        size_t logits_size = hp.n_vocab * sizeof(float);
                        
                        Newx(logits_data, hp.n_vocab, float);
                        ggml_backend_tensor_get(logits_tensor, logits_data,
                                                (n_tokens - 1) * hp.n_vocab * sizeof(float), logits_size);
                        
                        for (j = 0; j < hp.n_vocab; j++) {
                            av_push(logits_av, newSVnv(logits_data[j]));
                        }
                        Safefree(logits_data);
                    }
                }
            }
            ggml_gallocr_free(allocr);
        }
        
        ggml_free(seq_ctx);
        av_push(results_av, newRV_noinc((SV*)logits_av));
    }
    
    /* Cleanup */
    ggml_free(ctx_c);
    ggml_backend_free(backend);
    for (i = 0; i < n_sequences; i++) Safefree(all_tokens[i]);
    Safefree(all_tokens);
    Safefree(seq_lengths);
    
    /* Return array of logits arrays */
    EXTEND(SP, 1);
    mPUSHs(newRV_noinc((SV*)results_av));

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
