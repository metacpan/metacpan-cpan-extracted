package KinoSearch1::Util::ToolSet;
use strict;
use warnings;
use bytes;
no bytes;

use base qw( Exporter );

use Carp qw( carp croak cluck confess );
# everything except readonly and set_prototype
use Scalar::Util qw(
    refaddr
    blessed
    dualvar
    isweak
    refaddr
    reftype
    tainted
    weaken
    isvstring
    looks_like_number
);
use KinoSearch1 qw( K_DEBUG kdump );
use KinoSearch1::Util::VerifyArgs qw( verify_args kerror a_isa_b );
use KinoSearch1::Util::MathUtils qw( ceil );

our @EXPORT = qw(
    carp
    croak
    cluck
    confess

    refaddr
    blessed
    dualvar
    isweak
    refaddr
    reftype
    tainted
    weaken
    isvstring
    looks_like_number

    K_DEBUG
    kdump
    kerror

    verify_args
    a_isa_b

    ceil
);

1;

__END__

__COPYRIGHT__

Copyright 2005-2010 Marvin Humphrey

This program is free software; you can redistribute it and/or modify
under the same terms as Perl itself.

