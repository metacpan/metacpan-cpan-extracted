package FFI::Platypus::DL;

use strict;
use warnings;
use 5.008004;
use Exporter qw( import );

require FFI::Platypus;
our @EXPORT = qw( dlopen dlerror dlsym dlclose );
push @EXPORT, grep /RTLD_/, keys %FFI::Platypus::DL::;

# ABSTRACT: Slightly non-portable interface to libdl
our $VERSION = '2.10'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Platypus::DL - Slightly non-portable interface to libdl

=head1 VERSION

version 2.10

=head1 SYNOPSIS

 use FFI::Platypus 2.00;
 use FFI::Platypus::DL;
 
 my $handle = dlopen("./libfoo.so", RTLD_PLATYPUS_DEFAULT);
 my $address = dlsym($handle, "my_function_named_foo");
 my $ffi = FFI::Platypus->new( api => 2 );
 $ffi->function($address => [] => 'void')->call;
 dlclose($handle);

=head1 DESCRIPTION

This module provides an interface to libdl, the dynamic loader on UNIX.  The underlying interface
has always been used by L<FFI::Platypus>, but it wasn't a public interface until version 0.52.  The
name was changed with that version when it became a public interface, so be sure to specify that
version if you are going to use it.

It is somewhat non-portable for these reasons:

=over 4

=item GNU extensions

It provides some GNU extensions to platforms such as Linux that support them.

=item Windows

It provides an emulation layer on Windows.  The emulation layer only supports C<RTLD_PLATYPUS_DEFAULT>
as a flag.  The emulation layer emulates the convention described below of passing C<undef> as
the dynamic library name to mean, use the currently running executable.  I've used it without
any problems for years, but Windows is not my main development platform.

=back

=head1 FUNCTIONS

=head2 dlopen

 my $handle = dlopen($filename, $flags);

This opens a dynamic library in the context of the dynamic loader.  C<$filename> is the full or
relative path to a dynamic library (usually a C<.so> on Linux and some other UNIXen, a C<.dll> on
Windows and a C<.dylib> on OS X).  C<$flags> are flags that can be used to alter the behavior
of the library and the symbols it contains.  The return value is an opaque pointer or C<$handle>
which can be used to look up symbols with C<dlsym>.  The handle should be closed with C<dlclose>
when you are done with it.

By convention if you pass in C<undef> for the filename, the currently loaded executable will be
used instead of a separate dynamic library.  This is the easiest and most portable way to find
the address of symbols in the standard C library.  This convention is baked into most UNIXen,
but this capability is emulated in Windows which doesn't come with the capability out of the box.

If there is an error in opening the library then C<undef> will be returned and the diagnostic
for the failure can be retrieved with C<dlerror> as described below.

Not all flags are supported on all platforms.  You can test if a flag is available using can:

 if(FFI::Platypus::DL->can('RTLD_LAZY'))
 {
   ...
 }

Typically where flags are not mutually exclusive, they can be or'd together:

 my $handle = dlopen("libfoo.so", RTLD_LAZY | RTLD_GLOBAL);

Check your operating system documentation for detailed descriptions of these flags.

=over 4

=item RTLD_PLATYPUS_DEFAULT

This is the L<FFI::Platypus> default for C<dlopen> (NOTE: NOT the libdl default).  This is the only
flag supported on Windows.  For historical reasons, this is usually C<RTLD_LAZY> on Unix and C<0> on
Windows.

=item RTLD_LAZY

Perform lazy binding.

=item RTLD_NOW

Resolve all symbols before returning from C<dlopen>.  Error if all symbols cannot resolve.

=item RTLD_GLOBAL

Symbols are shared.

=item RTLD_LOCAL

Symbols are NOT shared.

=item RTLD_NODELETE

glibc 2.2 extension.

=item RTLD_NOLOAD

glibc 2.2 extension.

=item RTLD_DEEPBIND

glibc 2.3.4 extension.

=back

=head2 dlsym

 my $opaque = dlsym($handle, $symbol);

This looks up the given C<$symbol> in the library pointed to by C<$handle>.  If the symbol is found,
the address for that symbol is returned as an opaque pointer.  This pointer can be passed into
the L<FFI::Platypus> C<function> and C<attach> methods instead of a function name.

If the symbol cannot be found then C<undef> will be returned and the diagnostic for the failure can
be retrieved with C<dlerror> as described below.

=head2 dlclose

 my $status = dlclose($handle);

On success, C<dlclose> returns 0; on error, it returns a nonzero value, and the diagnostic for the
failure can be retrieved with C<dlerror> as described below.

=head2 dlerror

 my $error_string = dlerror;

Returns the human readable diagnostic for the reason for the failure for the most recent C<dl>
prefixed function call.

=head1 CAVEATS

Some flags for C<dlopen> are not portable.  This module may not be supported platforms added to
L<FFI::Platypus> in the future.  It does work as far as I know on all of the currently supported
platforms.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Bakkiaraj Murugesan (bakkiaraj)

Dylan Cali (calid)

pipcet

Zaki Mughal (zmughal)

Fitz Elliott (felliott)

Vickenty Fesunov (vyf)

Gregor Herrmann (gregoa)

Shlomi Fish (shlomif)

Damyan Ivanov

Ilya Pavlov (Ilya33)

Petr Písař (ppisar)

Mohammad S Anwar (MANWAR)

Håkon Hægland (hakonhagland, HAKONH)

Meredith (merrilymeredith, MHOWARD)

Diab Jerius (DJERIUS)

Eric Brine (IKEGAMI)

szTheory

José Joaquín Atria (JJATRIA)

Pete Houston (openstrike, HOUSTON)

Lukas Mai (MAUKE)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
