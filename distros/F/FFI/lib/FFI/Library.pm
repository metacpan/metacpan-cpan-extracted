package FFI::Library;

use strict;
use warnings;
use Carp qw( croak );
use FFI;

our $VERSION = '1.10';

if ($^O eq 'MSWin32') {
    require Win32;
}
else {
    require DynaLoader;
}

sub new {
    my $class = shift;
    my $libname = shift;
    scalar(@_) <= 1
        or croak 'Usage: $lib = new FFI::Library($filename [, $flags])';
    my $lib;
    if ($^O eq 'MSWin32') {
        $lib = Win32::LoadLibrary($libname) or return undef;
    }
    else {
        my $so = $libname;
        -e $so or $so = DynaLoader::dl_findfile($libname) || $libname;
        $lib = DynaLoader::dl_load_file($so, @_)
            or return undef;
    }
    bless \$lib, $class;
}

sub DESTROY {
    if ($^O eq 'MSWin32') {
        Win32::FreeLibrary(${$_[0]});
    }
    else {
        DynaLoader::dl_free_file(${$_[0]})
            if defined (&DynaLoader::dl_free_file);
    }
}

sub function {
    my $self = shift;
    my $name = shift;
    my $sig = shift;
    my $addr;
    if ($^O eq 'MSWin32') {
        $addr = Win32::GetProcAddress(${$self}, $name);
    }
    else {
        $addr = DynaLoader::dl_find_symbol(${$self}, $name);
    }
    croak "Unknown function $name" unless defined $addr;

    sub { FFI::call($addr, $sig, @_); }
}

1;
__END__

=head1 NAME

FFI::Library - Perl Access to Dynamically Loaded Libraries

=head1 SYNOPSIS

    use FFI::Library;
    $lib = FFI::Library->new("mylib");
    $fn = $lib->function("fn", "signature");
    $ret = $fn->(...);

=head1 DESCRIPTION

This module provides access from Perl to functions exported from dynamically
linked libraries. Functions are described by C<signatures>, for details of
which see the L<FFI> module's documentation.

Newer FFI modules such as L<FFI::Platypus> and L<FFI::Raw> provide more
functionality and should probably be considered for new projects.

=head1 EXAMPLES

    $clib_file = ($^O eq "MSWin32") ? "MSVCRT40.DLL" : "-lc";
    $clib = FFI::Library->new($clib_file);
    $strlen = $clib->function("strlen", "cIp");
    $n = $strlen->($my_string);

=head1 SUPPORT

Please open any support tickets with this project's GitHub repository 
here:

L<https://github.com/plicease/FFI/issues>

=head1 SEE ALSO

=over 4

=item L<FFI>

Low level interface to ffcall that this module is based on

=item L<FFI::CheckLib>

Portable functions for finding libraries.

=item L<FFI::Platypus>

Platypus is another FFI interface based on libffi.  It has a more
extensive feature set, and libffi has a less restrictive license.

=item L<FFI::Raw>

Another FFI interface based on libffi.

=item L<Win32::API>

An FFI interface for Perl on Microsoft Windows.

=back

=head1 AUTHOR

Paul Moore, C<< <gustav@morpheus.demon.co.uk> >> is the original author
of L<FFI>.

Mitchell Charity C<< <mcharity@vendian.org> >> contributed fixes.

Anatoly Vorobey C<< <avorobey@pobox.com> >> and Gaal Yahas C<<
<gaal@forum2.org> >> are the current maintainers.

Graham Ollis C<< <plicease@cpan.org >> is the current maintainer

=head1 LICENSE

This software is copyright (c) 1999 by Paul Moore.

This is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License

=cut
