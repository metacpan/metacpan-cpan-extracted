package Dyn 0.03 {
    use strict;
    use warnings;
    no warnings 'redefine';
    use 5.030;
    use XSLoader;
    XSLoader::load( __PACKAGE__, our $VERSION );
    #
    use Dyn::Call qw[:all];
    use Dyn::Callback qw[:all];
    use Dyn::Load qw[:all];
    use experimental 'signatures';
    #
    use parent 'Exporter';
    our %EXPORT_TAGS = (
        dc    => [@Dyn::Call::EXPORT_OK],
        dcb   => [@Dyn::Callback::EXPORT_OK],
        dl    => [@Dyn::Load::EXPORT_OK],
        sugar => [qw[call load MODIFY_SCALAR_ATTRIBUTES MODIFY_CODE_ATTRIBUTES AUTOLOAD]]
    );
    @{ $EXPORT_TAGS{all} } = our @EXPORT_OK = map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;
};
1;
__END__

=encoding utf-8

=head1 NAME

Dyn - dyncall Backed FFI

=head1 SYNOPSIS

    use Dyn qw[:sugar];	# Exports nothing by default
    sub pow : Dyn( '/usr/lib/libm-2.33.so', '(dd)d');
    print pow( 2, 10 );	# 1024

=head1 DESCRIPTION

Dyn is a wrapper around L<dyncall|https://dyncall.org/>.

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

Honestly, you should be using one of the above packages rather than this one as
they provide clean wrappers of dyncall's C functions. This package contains the
sugary API.

=head1 Functions

While most of the upstream API is covered in the L<Dyn::Call>,
L<Dyn::Callback>, and L<Dyn::Load> packages, all the sugar is right here in
C<Dyn>. The most simple use of C<Dyn> would look something like this:

	use Dyn ':sugar';
	sub some_argless_function() : Dyn('somelib.so', '()v');
	some_argless_function();

Be aware that this will look a lot more like L<NativeCall from
Raku|https://docs.raku.org/language/nativecall> before v1.0!

The second line above looks like a normal Perl sub declaration but includes the
C<:Dyn> attribute to specify that the sub is actually defined in a native
library.

To avoid banging your head on a built-in function, you may name your sub
anything else and let Dyn know what symbol to attach:

	sub my_abs : Dyn('my_lib.dll', '(d)d', 'abs');
	CORE::say my_abs( -75 ); # Should print 75 if your abs is something that makes sense

This is by far the fastest way to work with this distribution but it's not by
any means the only way.

All of the following methods may be imported by name or with the C<:sugar> tag.

Note that everything here is subject to change before v1.0.

=head2 C<load( ... )>

Creates a wrapper around a given symbol in a given library.

	my $pow = Dyn::load( 'C:\Windows\System32\user32.dll', 'pow', 'dd)d' );

Expected parameters include:

=over

=item C<lib> - pointer returned by L<< C<dlLoadLibrary( ... )>|Dyn::Load/C<dlLoadLibrary( ... )> >> or the path of the library as a string

=item C<name> - the name of the symbol to call

=item C<signature> - signature defining argument types, return type, and optionally the calling convention used

=back

=head2 C<call( ... )>

Invokes the function according to the provided L<signature|/Signatures>.

	my $value = $pow->call( 2.0, 10 ); # Same as Dyn::call( $pow, 2.0, 10 )

Expected parameters include:

=over

=item C<bind> - C<Dyn> object bound with C<load( ... )>

=item C<...> - any arguments to bind to the call

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
    e                     vararg function
    .                     vararg function's variadic/ellipsis part (...), to be speciﬁed before ﬁrst vararg
    c                     only on x86: cdecl
    s                     only on x86: stdcall
    F                     only on x86: fastcall (MS)
    f                     only on x86: fastcall (GNU)
    +                     only on x86: thiscall (MS)
    #                     only on x86: thiscall (GNU)
    A                     only on ARM: ARM mode
    a                     only on ARM: THUMB mode
    $                     syscall

=head1 Platform Support

The dyncall library runs on many different platforms and operating systems
(including Windows, Linux, OpenBSD, FreeBSD, macOS, DragonFlyBSD, NetBSD,
Plan9, iOS, Haiku, Nintendo DS, Playstation Portable, Solaris, Minix, Raspberry
Pi, ReactOS, etc.) and processors (x86, x64, arm (arm & thumb mode), arm64,
mips, mips64, ppc32, ppc64, sparc, sparc64, etc.).

=head1 See Also

Check out L<FFI::Platypus> for a more robust and mature FFI.

Examples found in C<eg/>.

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
