/*
 * Lugh::Prompt - Chat Template Formatting for LLM Conversations (XS)
 * 
 * This module provides C-based chat template formatting for various
 * LLM chat formats: ChatML, Llama2, Llama3, Mistral, Gemma, etc.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <stdlib.h>

/* Format definition structure */
typedef struct {
    const char* name;
    const char* bos_token;
    const char* eos_token;
    const char* system_prefix;
    const char* system_suffix;
    const char* user_prefix;
    const char* user_suffix;
    const char* assistant_prefix;
    const char* assistant_suffix;
    const char* generation_prompt;
    const char* first_user_prefix;  /* NULL if same as user_prefix */
    int system_to_user;             /* 1 if system should be prepended to first user */
} PromptFormat;

/* Built-in format definitions */
static const PromptFormat FORMATS[] = {
    /* ChatML - Qwen, Phi, Yi */
    {
        "chatml",
        "",                              /* bos_token */
        "",                              /* eos_token */
        "<|im_start|>system\n",          /* system_prefix */
        "<|im_end|>\n",                  /* system_suffix */
        "<|im_start|>user\n",            /* user_prefix */
        "<|im_end|>\n",                  /* user_suffix */
        "<|im_start|>assistant\n",       /* assistant_prefix */
        "<|im_end|>\n",                  /* assistant_suffix */
        "<|im_start|>assistant\n",       /* generation_prompt */
        NULL,                            /* first_user_prefix */
        0                                /* system_to_user */
    },
    /* Llama 2 */
    {
        "llama2",
        "<s>",                           /* bos_token */
        "</s>",                          /* eos_token */
        "[INST] <<SYS>>\n",              /* system_prefix */
        "\n<</SYS>>\n\n",                /* system_suffix */
        "",                              /* user_prefix */
        " [/INST] ",                     /* user_suffix */
        "",                              /* assistant_prefix */
        " </s><s>[INST] ",               /* assistant_suffix */
        "",                              /* generation_prompt */
        "[INST] ",                       /* first_user_prefix */
        0                                /* system_to_user */
    },
    /* Llama 3 */
    {
        "llama3",
        "<|begin_of_text|>",             /* bos_token */
        "",                              /* eos_token */
        "<|start_header_id|>system<|end_header_id|>\n\n",  /* system_prefix */
        "<|eot_id|>",                    /* system_suffix */
        "<|start_header_id|>user<|end_header_id|>\n\n",    /* user_prefix */
        "<|eot_id|>",                    /* user_suffix */
        "<|start_header_id|>assistant<|end_header_id|>\n\n", /* assistant_prefix */
        "<|eot_id|>",                    /* assistant_suffix */
        "<|start_header_id|>assistant<|end_header_id|>\n\n", /* generation_prompt */
        NULL,                            /* first_user_prefix */
        0                                /* system_to_user */
    },
    /* Mistral */
    {
        "mistral",
        "<s>",                           /* bos_token */
        "</s>",                          /* eos_token */
        "",                              /* system_prefix */
        "",                              /* system_suffix */
        "[INST] ",                       /* user_prefix */
        " [/INST]",                      /* user_suffix */
        "",                              /* assistant_prefix */
        "</s> ",                         /* assistant_suffix */
        "",                              /* generation_prompt */
        NULL,                            /* first_user_prefix */
        1                                /* system_to_user - prepend to first user */
    },
    /* Gemma */
    {
        "gemma",
        "<bos>",                         /* bos_token */
        "",                              /* eos_token */
        "",                              /* system_prefix */
        "",                              /* system_suffix */
        "<start_of_turn>user\n",         /* user_prefix */
        "<end_of_turn>\n",               /* user_suffix */
        "<start_of_turn>model\n",        /* assistant_prefix */
        "<end_of_turn>\n",               /* assistant_suffix */
        "<start_of_turn>model\n",        /* generation_prompt */
        NULL,                            /* first_user_prefix */
        1                                /* system_to_user */
    },
    /* Zephyr */
    {
        "zephyr",
        "",                              /* bos_token */
        "</s>",                          /* eos_token */
        "<|system|>\n",                  /* system_prefix */
        "</s>\n",                        /* system_suffix */
        "<|user|>\n",                    /* user_prefix */
        "</s>\n",                        /* user_suffix */
        "<|assistant|>\n",               /* assistant_prefix */
        "</s>\n",                        /* assistant_suffix */
        "<|assistant|>\n",               /* generation_prompt */
        NULL,                            /* first_user_prefix */
        0                                /* system_to_user */
    },
    /* Alpaca */
    {
        "alpaca",
        "",                              /* bos_token */
        "",                              /* eos_token */
        "",                              /* system_prefix */
        "\n\n",                          /* system_suffix */
        "### Instruction:\n",            /* user_prefix */
        "\n\n",                          /* user_suffix */
        "### Response:\n",               /* assistant_prefix */
        "\n\n",                          /* assistant_suffix */
        "### Response:\n",               /* generation_prompt */
        NULL,                            /* first_user_prefix */
        0                                /* system_to_user */
    },
    /* Vicuna */
    {
        "vicuna",
        "",                              /* bos_token */
        "</s>",                          /* eos_token */
        "",                              /* system_prefix */
        "\n\n",                          /* system_suffix */
        "USER: ",                        /* user_prefix */
        "\n",                            /* user_suffix */
        "ASSISTANT: ",                   /* assistant_prefix */
        "</s>\n",                        /* assistant_suffix */
        "ASSISTANT: ",                   /* generation_prompt */
        NULL,                            /* first_user_prefix */
        0                                /* system_to_user */
    },
    /* Raw - no formatting */
    {
        "raw",
        "",                              /* bos_token */
        "",                              /* eos_token */
        "",                              /* system_prefix */
        "\n",                            /* system_suffix */
        "",                              /* user_prefix */
        "\n",                            /* user_suffix */
        "",                              /* assistant_prefix */
        "\n",                            /* assistant_suffix */
        "",                              /* generation_prompt */
        NULL,                            /* first_user_prefix */
        0                                /* system_to_user */
    },
    { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0 }
};

/* Architecture to format mapping */
typedef struct {
    const char* arch;
    const char* format;
} ArchFormatMap;

static const ArchFormatMap ARCH_FORMATS[] = {
    { "llama",    "llama2" },
    { "llama2",   "llama2" },
    { "llama3",   "llama3" },
    { "mistral",  "mistral" },
    { "qwen",     "chatml" },
    { "qwen2",    "chatml" },
    { "phi",      "chatml" },
    { "phi2",     "chatml" },
    { "phi3",     "chatml" },
    { "gemma",    "gemma" },
    { "gemma2",   "gemma" },
    { "yi",       "chatml" },
    { "internlm", "chatml" },
    { "falcon",   "raw" },
    { "gpt2",     "raw" },
    { "bloom",    "raw" },
    { "starcoder", "raw" },
    { NULL, NULL }
};

/* Find format by name (case-insensitive) */
static const PromptFormat* find_format(const char* name) {
    if (!name) return &FORMATS[0];  /* default to chatml */
    
    for (int i = 0; FORMATS[i].name != NULL; i++) {
        if (strcasecmp(FORMATS[i].name, name) == 0) {
            return &FORMATS[i];
        }
    }
    return NULL;
}

/* Find format for architecture */
static const char* format_for_arch(const char* arch) {
    if (!arch) return "chatml";
    
    for (int i = 0; ARCH_FORMATS[i].arch != NULL; i++) {
        if (strcasecmp(ARCH_FORMATS[i].arch, arch) == 0) {
            return ARCH_FORMATS[i].format;
        }
    }
    return "chatml";  /* default */
}

/* String buffer for building prompts */
typedef struct {
    char* data;
    size_t len;
    size_t cap;
} StrBuf;

static void strbuf_init(StrBuf* buf) {
    buf->cap = 1024;
    buf->data = (char*)malloc(buf->cap);
    buf->data[0] = '\0';
    buf->len = 0;
}

static void strbuf_free(StrBuf* buf) {
    if (buf->data) free(buf->data);
    buf->data = NULL;
    buf->len = 0;
    buf->cap = 0;
}

static void strbuf_append(StrBuf* buf, const char* str) {
    if (!str) return;
    size_t slen = strlen(str);
    if (buf->len + slen + 1 > buf->cap) {
        buf->cap = (buf->len + slen + 1) * 2;
        buf->data = (char*)realloc(buf->data, buf->cap);
    }
    memcpy(buf->data + buf->len, str, slen + 1);
    buf->len += slen;
}

/* Core apply function - used by both OO and functional interfaces */
static SV* do_apply_format(const char* fmt_name, AV* messages_av, int add_generation_prompt, int add_bos) {
    const PromptFormat* fmt = find_format(fmt_name);
    
    if (!fmt) {
        croak("Unknown prompt format: %s", fmt_name);
    }
    
    SSize_t n_msgs = av_len(messages_av) + 1;
    if (n_msgs == 0) {
        return newSVpv("", 0);
    }
    
    StrBuf buf;
    strbuf_init(&buf);
    
    /* Add BOS token */
    if (add_bos && fmt->bos_token[0]) {
        strbuf_append(&buf, fmt->bos_token);
    }
    
    /* Extract system content if system_to_user is set */
    const char* system_content = NULL;
    int start_idx = 0;
    
    if (fmt->system_to_user && n_msgs > 0) {
        SV** msg_sv = av_fetch(messages_av, 0, 0);
        if (msg_sv && SvROK(*msg_sv) && SvTYPE(SvRV(*msg_sv)) == SVt_PVHV) {
            HV* msg = (HV*)SvRV(*msg_sv);
            SV** role_sv = hv_fetch(msg, "role", 4, 0);
            if (role_sv && SvOK(*role_sv)) {
                const char* role = SvPV_nolen(*role_sv);
                if (strcmp(role, "system") == 0) {
                    SV** content_sv = hv_fetch(msg, "content", 7, 0);
                    if (content_sv && SvOK(*content_sv)) {
                        system_content = SvPV_nolen(*content_sv);
                    }
                    start_idx = 1;
                }
            }
        }
    }
    
    /* Process each message */
    int first_user = 1;
    const char* last_role = NULL;
    
    for (SSize_t i = start_idx; i < n_msgs; i++) {
        SV** msg_sv = av_fetch(messages_av, i, 0);
        if (!msg_sv || !SvROK(*msg_sv) || SvTYPE(SvRV(*msg_sv)) != SVt_PVHV) {
            continue;
        }
        
        HV* msg = (HV*)SvRV(*msg_sv);
        SV** role_sv = hv_fetch(msg, "role", 4, 0);
        SV** content_sv = hv_fetch(msg, "content", 7, 0);
        
        const char* role = (role_sv && SvOK(*role_sv)) ? SvPV_nolen(*role_sv) : "user";
        const char* content = (content_sv && SvOK(*content_sv)) ? SvPV_nolen(*content_sv) : "";
        
        last_role = role;
        
        if (strcmp(role, "system") == 0) {
            strbuf_append(&buf, fmt->system_prefix);
            strbuf_append(&buf, content);
            strbuf_append(&buf, fmt->system_suffix);
        }
        else if (strcmp(role, "user") == 0) {
            /* Use first_user_prefix if available and this is first user */
            const char* prefix = (first_user && fmt->first_user_prefix) 
                               ? fmt->first_user_prefix 
                               : fmt->user_prefix;
            
            strbuf_append(&buf, prefix);
            
            /* Prepend system content if needed */
            if (first_user && system_content) {
                strbuf_append(&buf, system_content);
                strbuf_append(&buf, "\n\n");
            }
            
            strbuf_append(&buf, content);
            strbuf_append(&buf, fmt->user_suffix);
            first_user = 0;
        }
        else if (strcmp(role, "assistant") == 0) {
            strbuf_append(&buf, fmt->assistant_prefix);
            strbuf_append(&buf, content);
            strbuf_append(&buf, fmt->assistant_suffix);
        }
    }
    
    /* Add generation prompt if requested and last wasn't assistant */
    if (add_generation_prompt) {
        if (!last_role || strcmp(last_role, "assistant") != 0) {
            strbuf_append(&buf, fmt->generation_prompt);
        }
    }
    
    SV* result = newSVpv(buf.data, buf.len);
    strbuf_free(&buf);
    return result;
}

/* Parse messages and options from argument list */
static void parse_apply_args(I32 ax, I32 items, int start, AV** messages_out, int* add_gen_out, int* add_bos_out) {
    AV* messages = newAV();
    int add_generation_prompt = 1;
    int add_bos = 1;
    
    int i = start;
    while (i < items) {
        SV* arg = ST(i);
        
        if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVHV) {
            /* It's a hashref - check if it's a message or options */
            HV* hv = (HV*)SvRV(arg);
            if (hv_exists(hv, "role", 4)) {
                /* It's a message */
                av_push(messages, SvREFCNT_inc(arg));
            }
            i++;
        }
        else if (!SvROK(arg) && SvPOK(arg)) {
            /* It's a string key - treat as key => value pair */
            const char* key = SvPV_nolen(arg);
            i++;
            if (i < items) {
                SV* val = ST(i);
                if (strcmp(key, "add_generation_prompt") == 0) {
                    add_generation_prompt = SvTRUE(val) ? 1 : 0;
                }
                else if (strcmp(key, "add_bos") == 0) {
                    add_bos = SvTRUE(val) ? 1 : 0;
                }
                i++;
            }
        }
        else {
            i++;
        }
    }
    
    *messages_out = messages;
    *add_gen_out = add_generation_prompt;
    *add_bos_out = add_bos;
}

MODULE = Lugh::Prompt    PACKAGE = Lugh::Prompt

PROTOTYPES: DISABLE

# Constructor - returns blessed hashref with format name
SV*
new(class, ...)
    SV* class
    CODE:
        const char* format_name = "chatml";
        
        /* Parse options */
        int i = 1;
        while (i < items) {
            SV* key = ST(i);
            if (!SvPOK(key)) { i++; continue; }
            const char* k = SvPV_nolen(key);
            i++;
            if (i >= items) break;
            SV* val = ST(i);
            i++;
            
            if (strcmp(k, "format") == 0 && SvPOK(val)) {
                format_name = SvPV_nolen(val);
            }
            else if (strcmp(k, "model") == 0 && SvROK(val)) {
                /* Get architecture from model object */
                dSP;
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(val);
                PUTBACK;
                int count = call_method("architecture", G_SCALAR);
                SPAGAIN;
                if (count == 1) {
                    SV* arch_sv = POPs;
                    if (SvOK(arch_sv)) {
                        const char* arch = SvPV_nolen(arch_sv);
                        format_name = format_for_arch(arch);
                    }
                }
                PUTBACK;
                FREETMPS;
                LEAVE;
            }
        }
        
        /* Validate format */
        if (!find_format(format_name)) {
            croak("Unknown prompt format: %s", format_name);
        }
        
        /* Create blessed hashref */
        HV* self = newHV();
        hv_store(self, "format", 6, newSVpv(format_name, 0), 0);
        
        SV* self_ref = newRV_noinc((SV*)self);
        const char* classname = SvPOK(class) ? SvPV_nolen(class) : "Lugh::Prompt";
        sv_bless(self_ref, gv_stashpv(classname, GV_ADD));
        
        RETVAL = self_ref;
    OUTPUT:
        RETVAL

# Get format name
SV*
format_name(self)
    SV* self
    CODE:
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) {
            croak("format_name called on invalid object");
        }
        HV* hv = (HV*)SvRV(self);
        SV** fmt_sv = hv_fetch(hv, "format", 6, 0);
        if (fmt_sv && SvOK(*fmt_sv)) {
            RETVAL = newSVsv(*fmt_sv);
        } else {
            RETVAL = newSVpv("chatml", 0);
        }
    OUTPUT:
        RETVAL

# Apply format to messages (OO interface)
SV*
apply(self, ...)
    SV* self
    CODE:
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) {
            croak("apply called on invalid object");
        }
        HV* hv = (HV*)SvRV(self);
        SV** fmt_sv = hv_fetch(hv, "format", 6, 0);
        const char* fmt_name = (fmt_sv && SvOK(*fmt_sv)) ? SvPV_nolen(*fmt_sv) : "chatml";
        
        AV* messages;
        int add_gen, add_bos;
        parse_apply_args(ax, items, 1, &messages, &add_gen, &add_bos);
        
        RETVAL = do_apply_format(fmt_name, messages, add_gen, add_bos);
        SvREFCNT_dec((SV*)messages);
    OUTPUT:
        RETVAL

# Format a single message
SV*
format_message(self, role, content)
    SV* self
    SV* role
    SV* content
    CODE:
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV) {
            croak("format_message called on invalid object");
        }
        HV* hv = (HV*)SvRV(self);
        SV** fmt_sv = hv_fetch(hv, "format", 6, 0);
        const char* fmt_name = (fmt_sv && SvOK(*fmt_sv)) ? SvPV_nolen(*fmt_sv) : "chatml";
        
        const PromptFormat* fmt = find_format(fmt_name);
        if (!fmt) {
            croak("Unknown prompt format: %s", fmt_name);
        }
        
        const char* role_str = SvPOK(role) ? SvPV_nolen(role) : "user";
        const char* content_str = SvPOK(content) ? SvPV_nolen(content) : "";
        
        StrBuf buf;
        strbuf_init(&buf);
        
        if (strcmp(role_str, "system") == 0) {
            strbuf_append(&buf, fmt->system_prefix);
            strbuf_append(&buf, content_str);
            strbuf_append(&buf, fmt->system_suffix);
        }
        else if (strcmp(role_str, "user") == 0) {
            strbuf_append(&buf, fmt->user_prefix);
            strbuf_append(&buf, content_str);
            strbuf_append(&buf, fmt->user_suffix);
        }
        else if (strcmp(role_str, "assistant") == 0) {
            strbuf_append(&buf, fmt->assistant_prefix);
            strbuf_append(&buf, content_str);
            strbuf_append(&buf, fmt->assistant_suffix);
        }
        else {
            strbuf_append(&buf, content_str);
        }
        
        RETVAL = newSVpv(buf.data, buf.len);
        strbuf_free(&buf);
    OUTPUT:
        RETVAL

# Return list of available format names
void
available_formats(...)
    PPCODE:
        int i;
        for (i = 0; FORMATS[i].name != NULL; i++) {
            mXPUSHs(newSVpv(FORMATS[i].name, 0));
        }

# Get format name for architecture
SV*
format_for_architecture(...)
    CODE:
        const char* arch_str = NULL;
        /* Handle both class method and function call */
        if (items >= 2) {
            arch_str = SvPOK(ST(1)) ? SvPV_nolen(ST(1)) : NULL;
        } else if (items == 1) {
            arch_str = SvPOK(ST(0)) ? SvPV_nolen(ST(0)) : NULL;
        }
        const char* fmt = format_for_arch(arch_str);
        RETVAL = newSVpv(fmt, 0);
    OUTPUT:
        RETVAL

# Check if format exists
int
has_format(...)
    CODE:
        const char* name_str = NULL;
        if (items >= 2) {
            name_str = SvPOK(ST(1)) ? SvPV_nolen(ST(1)) : NULL;
        } else if (items == 1) {
            name_str = SvPOK(ST(0)) ? SvPV_nolen(ST(0)) : NULL;
        }
        RETVAL = find_format(name_str) != NULL;
    OUTPUT:
        RETVAL

# Get format info as hash
SV*
get_format(...)
    CODE:
        const char* name_str = NULL;
        if (items >= 2) {
            name_str = SvPOK(ST(1)) ? SvPV_nolen(ST(1)) : NULL;
        } else if (items == 1) {
            name_str = SvPOK(ST(0)) ? SvPV_nolen(ST(0)) : NULL;
        }
        const PromptFormat* fmt = find_format(name_str);
        if (!fmt) {
            RETVAL = &PL_sv_undef;
        } else {
            HV* hv = newHV();
            hv_store(hv, "name", 4, newSVpv(fmt->name, 0), 0);
            hv_store(hv, "bos_token", 9, newSVpv(fmt->bos_token, 0), 0);
            hv_store(hv, "eos_token", 9, newSVpv(fmt->eos_token, 0), 0);
            hv_store(hv, "system_prefix", 13, newSVpv(fmt->system_prefix, 0), 0);
            hv_store(hv, "system_suffix", 13, newSVpv(fmt->system_suffix, 0), 0);
            hv_store(hv, "user_prefix", 11, newSVpv(fmt->user_prefix, 0), 0);
            hv_store(hv, "user_suffix", 11, newSVpv(fmt->user_suffix, 0), 0);
            hv_store(hv, "assistant_prefix", 16, newSVpv(fmt->assistant_prefix, 0), 0);
            hv_store(hv, "assistant_suffix", 16, newSVpv(fmt->assistant_suffix, 0), 0);
            hv_store(hv, "generation_prompt", 17, newSVpv(fmt->generation_prompt, 0), 0);
            RETVAL = newRV_noinc((SV*)hv);
        }
    OUTPUT:
        RETVAL

# Shortcut functions - chatml
SV*
chatml(...)
    CODE:
        AV* messages;
        int add_gen, add_bos;
        parse_apply_args(ax, items, 0, &messages, &add_gen, &add_bos);
        RETVAL = do_apply_format("chatml", messages, add_gen, add_bos);
        SvREFCNT_dec((SV*)messages);
    OUTPUT:
        RETVAL

# Shortcut functions - llama2
SV*
llama2(...)
    CODE:
        AV* messages;
        int add_gen, add_bos;
        parse_apply_args(ax, items, 0, &messages, &add_gen, &add_bos);
        RETVAL = do_apply_format("llama2", messages, add_gen, add_bos);
        SvREFCNT_dec((SV*)messages);
    OUTPUT:
        RETVAL

# Shortcut functions - llama3
SV*
llama3(...)
    CODE:
        AV* messages;
        int add_gen, add_bos;
        parse_apply_args(ax, items, 0, &messages, &add_gen, &add_bos);
        RETVAL = do_apply_format("llama3", messages, add_gen, add_bos);
        SvREFCNT_dec((SV*)messages);
    OUTPUT:
        RETVAL

# Shortcut functions - mistral
SV*
mistral(...)
    CODE:
        AV* messages;
        int add_gen, add_bos;
        parse_apply_args(ax, items, 0, &messages, &add_gen, &add_bos);
        RETVAL = do_apply_format("mistral", messages, add_gen, add_bos);
        SvREFCNT_dec((SV*)messages);
    OUTPUT:
        RETVAL

# Shortcut functions - gemma
SV*
gemma(...)
    CODE:
        AV* messages;
        int add_gen, add_bos;
        parse_apply_args(ax, items, 0, &messages, &add_gen, &add_bos);
        RETVAL = do_apply_format("gemma", messages, add_gen, add_bos);
        SvREFCNT_dec((SV*)messages);
    OUTPUT:
        RETVAL

# Shortcut functions - zephyr
SV*
zephyr(...)
    CODE:
        AV* messages;
        int add_gen, add_bos;
        parse_apply_args(ax, items, 0, &messages, &add_gen, &add_bos);
        RETVAL = do_apply_format("zephyr", messages, add_gen, add_bos);
        SvREFCNT_dec((SV*)messages);
    OUTPUT:
        RETVAL

# Shortcut functions - alpaca
SV*
alpaca(...)
    CODE:
        AV* messages;
        int add_gen, add_bos;
        parse_apply_args(ax, items, 0, &messages, &add_gen, &add_bos);
        RETVAL = do_apply_format("alpaca", messages, add_gen, add_bos);
        SvREFCNT_dec((SV*)messages);
    OUTPUT:
        RETVAL

# Shortcut functions - vicuna
SV*
vicuna(...)
    CODE:
        AV* messages;
        int add_gen, add_bos;
        parse_apply_args(ax, items, 0, &messages, &add_gen, &add_bos);
        RETVAL = do_apply_format("vicuna", messages, add_gen, add_bos);
        SvREFCNT_dec((SV*)messages);
    OUTPUT:
        RETVAL

# Shortcut functions - raw
SV*
raw(...)
    CODE:
        AV* messages;
        int add_gen, add_bos;
        parse_apply_args(ax, items, 0, &messages, &add_gen, &add_bos);
        RETVAL = do_apply_format("raw", messages, add_gen, add_bos);
        SvREFCNT_dec((SV*)messages);
    OUTPUT:
        RETVAL
