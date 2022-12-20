package Dyn 0.05 {
    use strict;
    use warnings;
    use 5.030;
    #
    use Dyn::Call     qw[:all];
    use Dyn::Callback qw[:all];
    use Dyn::Load     qw[:all];
    #
    use parent 'Exporter';
    our %EXPORT_TAGS = (
        dc  => [@Dyn::Call::EXPORT_OK],
        dcb => [@Dyn::Callback::EXPORT_OK],
        dl  => [@Dyn::Load::EXPORT_OK],
    );
    @{ $EXPORT_TAGS{all} } = our @EXPORT_OK = map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;
};
1;
__END__

=encoding utf-8

=head1 NAME

Dyn - dyncall-Backed FFI Building Blocks

=head1 SYNOPSIS

    use Dyn qw[:dc :dl]; # Imports all functions from Dyn::Call and Dyn::Load

=head1 DESCRIPTION

Dyn is a wrapper around L<dyncall|https://dyncall.org/>. It's here for the sake
of convenience.

This distribution includes...

=over

=item L<Dyn::Call>

An encapsulation of architecture-, OS- and compiler-specific function call
semantics.

Functions can be imported with the C<:dc> tag.

=item L<Dyn::Callback>

Callback interface of C<dyncall> located in C<dyncallback>.

Functions can be imported with the C<:dcb> tag.

=item L<Dyn::Load>

Facilitates portable library symbol loading and access to functions in foreign
dynamic libraries and code modules.

Functions can be imported with the C<:dl> tag.

=back

=head1 Signatures

C<dyncall> uses an almost C<pack>-like syntax to define signatures. A signature
is a character string that represents a function's arguments and return value
types. This is an essential part of mapping the more flexible and often
abstract data types provided in scripting languages to the strict machine-level
data types used by C-libraries.

=for future The high-level C interface functions L<<
C<dcCallF( ... )>|Dyn::Call/C<dcCallF( ... )> >>, L<< C<dcVCallF( ...
)>|Dyn::Call/C<dcVCallF( ... )> >>, L<< C<dcArgF( ... )>|Dyn::Call/C<dcArgF(
... )> >> and L<< C<dcVArgF( ... )>|Dyn::Call/C<dcVArgF( ... )> >> of the
dyncall library also make use of this signature string format.

Here are some signature examples along with their equivalent C function
prototypes:

    dyncall signature    C function prototype
    --------------------------------------------
    )v                   void      f1 ( )
    ii)i                 int       f2 ( int, int )
    p)L                  long long f3 ( void * )
    p)v                  void      f4 ( int ** )
    iBcdZ)d              double    f5 ( int, bool, char, double, const char * )
    _esl_.di)v           void      f6 ( short a, long long b, ... ) (for (promoted) varargs: double, int)
    (Zi)i                int       f7 ( const char *, int )
    (iiid)v              void      f8 ( int, int, int, double )

The following types are supported:

    Signature character     C/C++ data type
    ----------------------------------------------------
    v                       void
    B                       _Bool, bool
    c                       char
    C                       unsigned char
    s                       short
    S                       unsigned short
    i                       int
    I                       unsigned int
    j                       long
    J                       unsigned long
    l                       long long, int64_t
    L                       unsigned long long, uint64_t
    f                       float
    d                       double
    p                       void *
    Z                       const char * (pointer to a C string)
    A                       aggregate (struct/union described out-of-band via DCaggr)

See L<Dyn::Call|Dyn::Call/Signature> for importable values.

Please note that using a C<(> at the beginning of a signature string is
possible, although not required. The character doesn't have any meaning and
will simply be ignored. However, using it prevents annoying syntax highlighting
problems with some code editors.

Calling convention modes can be switched using the signature string, as well.
An C<_> in the signature string is followed by a character specifying what
calling convention to use, as this effects how arguments are passed. This makes
only sense if there are multiple co-existing calling conventions on a single
platform. Usually, this is done at the beginning of the string, except in
special cases, like specifying where the varargs part of a variadic function
begins. The following signature characters exist:

    Signature character   Calling Convention
    ------------------------------------------------------
    :                     platform's default calling convention
    *                     C++ this calls (platform native)
    e                     vararg function
    .                     vararg function's variadic/ellipsis part (...), to be specified before first vararg
    c                     only on x86: cdecl
    s                     only on x86: stdcall
    F                     only on x86: fastcall (MS)
    f                     only on x86: fastcall (GNU)
    +                     only on x86: thiscall (MS)
    #                     only on x86: thiscall (GNU)
    A                     only on ARM: ARM mode
    a                     only on ARM: THUMB mode
    $                     syscall

See L<Dyn::Call|Dyn::Call/Modes> for importable values.

=head1 Platform Support

The dyncall library runs on many different platforms and operating systems
(including Windows, Linux, OpenBSD, FreeBSD, macOS, DragonFlyBSD, NetBSD,
Plan9, iOS, Haiku, Nintendo DS, Playstation Portable, Solaris, Minix, Raspberry
Pi, ReactOS, etc.) and processors (x86, x64, arm (arm & thumb mode), arm64,
mips, mips64, ppc32, ppc64, sparc, sparc64, etc.).

=head1 See Also

L<https://dyncall.org>

L<Affix> for a dyncall wrapper with some of the rough edges sanded down.

L<FFI::Platypus> for a mature, well-tested FFI.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

dyncall OpenBSD FreeBSD macOS DragonFlyBSD NetBSD iOS ReactOS mips mips64 ppc32
ppc64 sparc sparc64 co-existing varargs variadic

=end stopwords

=cut
