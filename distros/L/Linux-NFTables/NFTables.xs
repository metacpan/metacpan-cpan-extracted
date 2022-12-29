#include "easyxs/easyxs.h"
#include <nftables/libnftables.h>

#define PERL_NS "Linux::NFTables"

typedef struct {
    struct nft_ctx* nft;
    pid_t pid;
} perl_nft_s;

#define _MAKE_PRIVATE_CONST(name) \
    newCONSTSUB(gv_stashpv(PERL_NS, 0), "_" #name, newSVuv(name));

// ----------------------------------------------------------------------

MODULE = Linux::NFTables        PACKAGE = Linux::NFTables

PROTOTYPES: DISABLE

BOOT:
    _MAKE_PRIVATE_CONST(NFT_CTX_OUTPUT_REVERSEDNS);
    _MAKE_PRIVATE_CONST(NFT_CTX_OUTPUT_SERVICE);
    _MAKE_PRIVATE_CONST(NFT_CTX_OUTPUT_STATELESS);
    _MAKE_PRIVATE_CONST(NFT_CTX_OUTPUT_HANDLE);
    _MAKE_PRIVATE_CONST(NFT_CTX_OUTPUT_JSON);
    _MAKE_PRIVATE_CONST(NFT_CTX_OUTPUT_ECHO);
    _MAKE_PRIVATE_CONST(NFT_CTX_OUTPUT_GUID);
    _MAKE_PRIVATE_CONST(NFT_CTX_OUTPUT_NUMERIC_PROTO);
    _MAKE_PRIVATE_CONST(NFT_CTX_OUTPUT_NUMERIC_PRIO);
    _MAKE_PRIVATE_CONST(NFT_CTX_OUTPUT_NUMERIC_SYMBOL);
    _MAKE_PRIVATE_CONST(NFT_CTX_OUTPUT_NUMERIC_TIME);
    _MAKE_PRIVATE_CONST(NFT_CTX_OUTPUT_NUMERIC_ALL);
    _MAKE_PRIVATE_CONST(NFT_CTX_OUTPUT_TERSE);

    _MAKE_PRIVATE_CONST(NFT_DEBUG_SCANNER);
    _MAKE_PRIVATE_CONST(NFT_DEBUG_PARSER);
    _MAKE_PRIVATE_CONST(NFT_DEBUG_EVALUATION);
    _MAKE_PRIVATE_CONST(NFT_DEBUG_NETLINK);
    _MAKE_PRIVATE_CONST(NFT_DEBUG_MNL);
    _MAKE_PRIVATE_CONST(NFT_DEBUG_PROTO_CTX);
    _MAKE_PRIVATE_CONST(NFT_DEBUG_SEGTREE);

SV*
new (const char* classname)
    CODE:
        struct nft_ctx* nft = nft_ctx_new(NFT_CTX_DEFAULT);

        int err = nft_ctx_buffer_output(nft);
        if (err) {
            nft_ctx_free(nft);
            croak("Failed to set buffered output!");
        }

        err = nft_ctx_buffer_error(nft);
        if (err) {
            nft_ctx_free(nft);
            croak("Failed to set buffered error output!");
        }

        RETVAL = exs_new_structref( perl_nft_s, classname );

        perl_nft_s* perl_nft = exs_structref_ptr(RETVAL);
        *perl_nft = (perl_nft_s) {
            .nft = nft,
            .pid = getpid(),
        };

    OUTPUT:
        RETVAL

void
DESTROY (SV* self_sv)
    CODE:
        perl_nft_s* perl_nft = exs_structref_ptr(self_sv);

        if (PL_dirty && perl_nft->pid == getpid()) {
            warn("DESTROYing %" SVf " at global destruction; memory leak likely!", self_sv);
        }

        nft_ctx_free(perl_nft->nft);

bool
get_dry_run (SV* self_sv)
    CODE:
        perl_nft_s* perl_nft = exs_structref_ptr(self_sv);
        RETVAL = nft_ctx_get_dry_run(perl_nft->nft);
    OUTPUT:
        RETVAL

SV*
set_dry_run (SV* self_sv, bool dry_yn=true)
    CODE:
        perl_nft_s* perl_nft = exs_structref_ptr(self_sv);
        nft_ctx_set_dry_run(perl_nft->nft, dry_yn);
        RETVAL = SvREFCNT_inc(self_sv);
    OUTPUT:
        RETVAL

unsigned
_output_get_flags (SV* self_sv)
    ALIAS:
        _output_get_debug = 1
    CODE:
        perl_nft_s* perl_nft = exs_structref_ptr(self_sv);
        RETVAL = ix ? nft_ctx_output_get_debug(perl_nft->nft) : nft_ctx_output_get_flags(perl_nft->nft);
    OUTPUT:
        RETVAL

SV*
_output_set_flags (SV* self_sv, SV* flags_sv)
    ALIAS:
        _output_set_debug = 1
    CODE:
        perl_nft_s* perl_nft = exs_structref_ptr(self_sv);
        UV flags = exs_SvUV(flags_sv);

        if (ix) {
            nft_ctx_output_set_debug(perl_nft->nft, flags);
        }
        else {
            nft_ctx_output_set_flags(perl_nft->nft, flags);
        }

        RETVAL = SvREFCNT_inc(self_sv);
    OUTPUT:
        RETVAL

const char*
run_cmd (SV* self_sv, SV* buf_sv)
    CODE:
        perl_nft_s* perl_nft = exs_structref_ptr(self_sv);
        const char* buf = exs_SvPVbyte_nolen(buf_sv);

        int err = nft_run_cmd_from_buffer(perl_nft->nft, buf);
        if (err) {
            croak_sv( newSVpv( nft_ctx_get_error_buffer(perl_nft->nft), 0 ) );
        }

        RETVAL = nft_ctx_get_output_buffer(perl_nft->nft);

    OUTPUT:
        RETVAL
