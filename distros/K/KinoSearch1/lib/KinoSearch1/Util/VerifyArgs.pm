package KinoSearch1::Util::VerifyArgs;
use strict;
use warnings;

use Scalar::Util qw( blessed );
use Carp;

use base qw( Exporter );

our @EXPORT_OK = qw( verify_args kerror a_isa_b );

my $kerror;

sub kerror {$kerror}

# Verify that named parameters exist in a defaults hash.
sub verify_args {
    my $defaults = shift;    # leave the rest of @_ intact

    # verify that args came in pairs
    if ( @_ % 2 ) {
        my ( $package, $filename, $line ) = caller(1);
        $kerror
            = "Parameter error: odd number of args at $filename line $line\n";
        return 0;
    }

    # verify keys, ignore values
    while (@_) {
        my ( $var, undef ) = ( shift, shift );
        next if exists $defaults->{$var};
        my ( $package, $filename, $line ) = caller(1);
        $kerror = "Invalid parameter: '$var' at $filename line $line\n";
        return 0;
    }

    return 1;
}

=begin comment

a_isa_b serves the same purpose as the isa method from UNIVERSAL, only it is
called as a function rather than a method.

    # safer than $foo->isa($class), which crashes if $foo isn't blessed
    my $confirm = a_isa_b( $foo, $class );

=end comment
=cut

sub a_isa_b {
    my ( $item, $class_name ) = @_;
    return 0 unless blessed($item);
    return $item->isa($class_name);
}

1;

__END__


__H__

#ifndef H_KINO_VERIFY_ARGS
#define H_KINO_VERIFY_ARGS 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1UtilCarp.h"

/* Return a mortalized hash, built using a defaults hash and @_.
 */
#define Kino1_Verify_build_args_hash(args_hash, defaults_hash_name, stack_st)\
    /* dXSARGS in the next function pops a stack marker, so we push one */  \
    PUSHMARK(SP);                                                           \
    args_hash = Kino1_Verify_do_build_args_hash(defaults_hash_name, stack_st);

HV* Kino1_Verify_do_build_args_hash(char*, I32);
SV* Kino1_Verify_extract_arg(HV*, char*, I32);

#endif /* include guard */

__C__

#include "KinoSearch1UtilVerifyArgs.h"

HV*
Kino1_Verify_do_build_args_hash(char* defaults_hash_name, I32 stack_st) {
    HV     *defaults_hash, *args_hash;
    char   *key;
    I32     key_len;
    STRLEN  len;
    SV     *key_sv, *val_sv, *val_copy_sv;
    I32     stack_pos;

    dXSARGS;

    /* create the args hash and mortalize it */
    args_hash = newHV();
    args_hash = (HV*)sv_2mortal( (SV*)args_hash );

    /* NOTE: the defaults hash must be declared using "our" */
    defaults_hash = get_hv(defaults_hash_name, 0);
    if (defaults_hash == NULL)
        Kino1_confess("Can't find hash named %s", defaults_hash_name);

    /* make the args hash a copy of the defaults hash */
    (void)hv_iterinit(defaults_hash);
    while ((val_sv = hv_iternextsv(defaults_hash, &key, &key_len))) {
        val_copy_sv = newSVsv(val_sv);
        hv_store(args_hash, key, key_len, val_copy_sv, 0);
    }

    /* verify and copy hash-style params into args hash from stack */
    if ((items - stack_st) % 2 != 0)
        Kino1_confess("Expecting hash-style params, "
            "got odd number of args");
    stack_pos = stack_st;
    while (stack_pos < items) {
        key_sv = ST(stack_pos++);
        key = SvPV(key_sv, len);
        key_len = len;
        if (!hv_exists(args_hash, key, key_len)) {
            Kino1_confess("Invalid parameter: '%s'", key);
        }
        val_sv = ST(stack_pos++);
        val_copy_sv = newSVsv(val_sv);
        hv_store(args_hash, key, key_len, val_copy_sv, 0);
    }
    
    return args_hash;
}


SV* 
Kino1_Verify_extract_arg(HV* hash, char* key, I32 key_len) {
    SV** sv_ptr;

    sv_ptr = hv_fetch(hash, key, key_len, 0);
    if (sv_ptr == NULL)
        Kino1_confess("Failed to retrieve hash entry '%s'", key);
    return *sv_ptr;
}


__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Util::VerifyArgs - some validation functions

==head1 DESCRIPTION

Provide some utility functions under the general heading of "verification".

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut
