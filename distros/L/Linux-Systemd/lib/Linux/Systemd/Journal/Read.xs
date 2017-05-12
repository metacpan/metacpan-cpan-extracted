#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <systemd/sd-journal.h>

sd_journal *j;

void split_data_to_svs(const char *msg, SV **k_sv, SV **v_sv) {
    char *data_copy = strdup(msg);
    char *k = strtok(data_copy, "=");
    char *v = strtok(NULL, "=");

    (*k_sv) = newSVpv(k, strlen(k));
    (*v_sv) = newSVpv(v, strlen(v));
}

MODULE = Linux::Systemd::Journal::Read PACKAGE = Linux::Systemd::Journal::Read

PROTOTYPES: ENABLE

NO_OUTPUT void
__open()
    CODE:
        int r = sd_journal_open(&j, SD_JOURNAL_LOCAL_ONLY);
        if (r < 0)
            croak("Failed to open journal: %s\n", strerror(r));
//
// NO_OUTPUT void
// __open_files(path)
//     CODE:
//         int r = sd_journal_open_files(&j, path, SD_JOURNAL_LOCAL_ONLY);
//         if (r < 0)
//             croak("Failed to open journal: %s\n", strerror(r));

uint64_t
get_usage(self)
    CODE:
        int r = sd_journal_get_usage(j, &RETVAL);
        if (r < 0)
            croak("Failed to open journal: %s\n", strerror(-r));
    OUTPUT: RETVAL

int
next(self, uint64_t skip=0)
    CODE:
        if (skip > 0)
            RETVAL = sd_journal_next_skip(j, skip);
        else
            RETVAL = sd_journal_next(j);
    POSTCALL:
        if (RETVAL < 0)
            croak("Failed to move to next record: %s\n", strerror(-RETVAL));
    OUTPUT: RETVAL

int
previous(self, uint64_t skip=0)
    CODE:
        if (skip > 0)
            RETVAL = sd_journal_previous_skip(j, skip);
        else
            RETVAL = sd_journal_previous(j);
    POSTCALL:
        if (RETVAL < 0)
            croak("Failed to move to previous record: %s\n", strerror(-RETVAL));
    OUTPUT: RETVAL

NO_OUTPUT void
seek_head(self)
    CODE:
        int r = sd_journal_seek_head(j);
        if (r < 0)
            croak("Failed to seek to journal head: %s\n", strerror(-r));

NO_OUTPUT void
seek_tail(self)
    CODE:
        int r = sd_journal_seek_tail(j);
        if (r < 0)
            croak("Failed to seek to journal tail: %s\n", strerror(-r));

NO_OUTPUT void
wait(self)
    CODE:
        int r = sd_journal_wait(j, (uint64_t) -1);
        if (r < 0)
            croak("Failed to wait for changes: %s\n", strerror(-r));


SV *
get_data(self, const char *field)
    CODE:
        SV     *key_sv;
        char   *data;
        size_t l;
        int r = sd_journal_get_data(j, field, (const void**) &data, &l);
        if (r < 0)
            croak("Failed to read message field '%s': %s\n", field, strerror(-r));

        split_data_to_svs(data, &key_sv, &RETVAL);
    OUTPUT: RETVAL

HV *
get_entry(self)
    PREINIT:
        const void *data;
        size_t l;
        SV   *key_sv, *val_sv;
        int r;
    CODE:
        RETVAL = newHV();
        sd_journal_restart_data(j);
        while ((r = sd_journal_enumerate_data(j, &data, &l)) > 0) {
            split_data_to_svs(data, &key_sv, &val_sv);
            hv_store_ent(RETVAL, key_sv, val_sv, 0);
        }

        if (r < 0)
            croak("Failed to get entry data: %s\n", strerror(-r));

    OUTPUT: RETVAL

# TODO should take binary data as well
NO_OUTPUT void
__add_match(const char *data)
    CODE:
        int r = sd_journal_add_match(j, data, 0);
        if (r < 0)
            croak("Failed to add a match: %s\n", strerror(-r));

NO_OUTPUT void
__match_and()
    CODE:
        int r = sd_journal_add_conjunction(j);
        if (r < 0)
            croak("Failed to set conjunction: %s\n", strerror(-r));

NO_OUTPUT void
__match_or()
    CODE:
        int r = sd_journal_add_disjunction(j);
        if (r < 0)
            croak("Failed to set disjunction: %s\n", strerror(-r));

NO_OUTPUT void
flush_matches(self)
    CODE:
        sd_journal_flush_matches(j);


NO_OUTPUT void
DESTROY(self)
    CODE:
        sd_journal_close(j);
