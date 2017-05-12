#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "git2.h"
#include <xs_helpers.h>
#include <xs_object_magic.h>

typedef struct {
    git_repository *repo;
} git_t;

MODULE = Git::XS PACKAGE = Git::XS
PROTOTYPES: DISABLE
VERSIONCHECK: DISABLE

void _build(self)
    SV *self
    PREINIT:
        git_t *git;
    CODE:
        Newx(git, 1, git_t);
        xs_object_magic_attach_struct(aTHX_ SvRV(self), git);
        SV *repo = call_getter(self, "repo");
        if (call_test(self, "_repo_exists", repo))
            git_repository_open(&(git->repo), SvPV_nolen(repo));
        SvREFCNT_dec(repo);

SV * _init(self, bare_flag)
    SV *self
    SV *bare_flag
    PREINIT:
        int rc;
    INIT:
        RETVAL = SvREFCNT_inc(self);
        git_t *git = xs_object_magic_get_struct_rv(aTHX_ self);
        int bare = SvIV(bare_flag);
    CODE:
        SV *repo = call_getter(self, "repo");
        char *path = SvPV_nolen(repo);
        git_repository **git_p = &(git->repo);
        rc = git_repository_init(git_p, path, bare);
        if (rc != GIT_SUCCESS)
            croak("git init failed with code: %d", rc);
    OUTPUT:
        RETVAL

void DESTROY(self)
    SV *self
    INIT:
        git_t *git = xs_object_magic_get_struct_rv(aTHX_ self);
    CODE:
        Safefree(git);
