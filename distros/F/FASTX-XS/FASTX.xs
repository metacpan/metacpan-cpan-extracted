/* FASTA/FASTQ parser using kseq.h */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <zlib.h>
#include "kseq.h"

// Initialize kseq
KSEQ_INIT(gzFile, gzread)

// Helper function to convert a kseq_t record to a Perl hash reference
static SV* kseq_to_hash(pTHX_ kseq_t *seq) {
    HV* hash = newHV();
    
    // Add name, always present
    hv_store(hash, "name", 4, newSVpvn(seq->name.s, seq->name.l), 0);
    
    // Add sequence, always present
    hv_store(hash, "seq", 3, newSVpvn(seq->seq.s, seq->seq.l), 0);
    
    // Add comment if present
    if (seq->comment.l)
        hv_store(hash, "comment", 7, newSVpvn(seq->comment.s, seq->comment.l), 0);
    
    // Add quality if present
    if (seq->qual.l)
        hv_store(hash, "qual", 4, newSVpvn(seq->qual.s, seq->qual.l), 0);
    
    return newRV_noinc((SV*)hash);
}

MODULE = FASTX::XS   PACKAGE = FASTX::XS
PROTOTYPES: DISABLE

SV*
_xs_new(class, filename)
    char* class
    char* filename
    CODE:
        gzFile fp;
        kseq_t *seq;
        
        // Open the file
        fp = gzopen(filename, "r");
        if (fp == NULL)
            croak("Failed to open file: %s", filename);
        
        // Initialize kseq
        seq = kseq_init(fp);
        if (seq == NULL) {
            gzclose(fp);
            croak("Failed to initialize sequence parser");
        }
        
        // Create a hash to store our object data
        HV* self = newHV();
        
        // Store the file pointer and seq object as an IV
        hv_store(self, "_fp", 3, newSViv(PTR2IV(fp)), 0);
        hv_store(self, "_seq", 4, newSViv(PTR2IV(seq)), 0);
        
        // Bless and return
        RETVAL = sv_bless(newRV_noinc((SV*)self), gv_stashpv(class, 0));
    OUTPUT:
        RETVAL

SV*
next_seq(self)
    SV* self
    CODE:
        HV* hash;
        SV** fp_sv;
        SV** seq_sv;
        gzFile fp;
        kseq_t *seq;
        int ret;
        
        // Get the hash
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Not a blessed hash reference");
        hash = (HV*)SvRV(self);
        
        // Get the file pointer and seq object
        fp_sv = hv_fetch(hash, "_fp", 3, 0);
        seq_sv = hv_fetch(hash, "_seq", 4, 0);
        
        if (!fp_sv || !seq_sv)
            croak("Invalid object");
        
        // Check if pointers are valid (not already freed)
        if (!SvOK(*fp_sv) || SvIV(*fp_sv) == 0)
            croak("File pointer has been freed");
        if (!SvOK(*seq_sv) || SvIV(*seq_sv) == 0)
            croak("Sequence parser has been freed");
        
        fp = INT2PTR(gzFile, SvIV(*fp_sv));
        seq = INT2PTR(kseq_t*, SvIV(*seq_sv));
        
        // Read next sequence
        ret = kseq_read(seq);
        
        if (ret < 0) {
            // EOF or error
            RETVAL = &PL_sv_undef;
        } else {
            // Convert to hash and return
            RETVAL = kseq_to_hash(aTHX_ seq);
        }
    OUTPUT:
        RETVAL

void
DESTROY(self)
    SV* self
    CODE:
        HV* hash;
        SV** fp_sv;
        SV** seq_sv;
        gzFile fp;
        kseq_t *seq;
        
        // Get the hash
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            return;
        hash = (HV*)SvRV(self);
        
        // Get the file pointer and seq object
        fp_sv = hv_fetch(hash, "_fp", 3, 0);
        seq_sv = hv_fetch(hash, "_seq", 4, 0);
        
        if (!fp_sv || !seq_sv)
            return;
        
        // Check if pointers are valid before cleanup
        if (SvOK(*fp_sv) && SvIV(*fp_sv) != 0) {
            fp = INT2PTR(gzFile, SvIV(*fp_sv));
            gzclose(fp);
            // Mark as cleaned up
            sv_setiv(*fp_sv, 0);
        }
        
        if (SvOK(*seq_sv) && SvIV(*seq_sv) != 0) {
            seq = INT2PTR(kseq_t*, SvIV(*seq_sv));
            kseq_destroy(seq);
            // Mark as cleaned up
            sv_setiv(*seq_sv, 0);
        }