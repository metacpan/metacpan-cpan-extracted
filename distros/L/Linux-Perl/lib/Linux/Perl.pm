package Linux::Perl;

=encoding utf-8

=head1 NAME

Linux::Perl - Linux system calls with pure Perl

=head1 SYNOPSIS

    my $efd = Linux::Perl::eventfd->new();

    #...or, if you know your architecture:
    my $efd = Linux::Perl::eventfd::x86_64->new();

=head1 DESCRIPTION

In memory-sensitive environments it is useful to minimize the number
of XS modules that Perl loads. Oftentimes the CPAN modules that implement
support for various Linux system calls, though, will bring in XS for the
sake of writing platform-neutral code.

Linux::Perl accommodates use cases where platform neutrality is less of
a concern than minimizing memory usage.

=head1 MODULES

Each family of system calls lives in its own namespace under C<Linux::Perl>:

=over

=item * L<Linux::Perl::eventfd>

=item * L<Linux::Perl::aio>

=item * L<Linux::Perl::uname>

=back

The distribution contains a number of other modules, none of which is
intended for outside use.

=head1 PLATFORM-SPECIFIC INVOCATION

Each Linux::Perl system call implementation can be called with a
platform-neutral syntax as well as with a platform-specific one:

    my $efd = Linux::Perl::eventfd->new();

    my $efd = Linux::Perl::eventfd::x86_64->new();

The platform-specific call is a bit lighter because it avoids loading
L<Config> to determine the current platform.

=head1 PLATFORM SUPPORT

The following platforms are supported:

=over

=item * x86_64 (i.e., 64-bit Intel/AMD)

This is probably the only platform that will foreseeably receive substantial
testing during development.

=item * i386 (32-bit Intel/AMD)

=back

Support for adding new platforms is usually trivial; just send a pull request.

=cut

use strict;
use warnings;

use Linux::Perl::X ();

our $VERSION = '0.04';

sub call {
    local $!;
    my $ok = syscall(0 + $_[0], @_[1 .. $#_]);
    if ($ok == -1) {
        die Linux::Perl::X->create('Call', $_[0], $!);
    }

    return $ok;
}

=head1 REPOSITORY

L<https://github.com/FGasper/p5-Linux-Perl>

=head1 AUTHOR

Felipe Gasper (FELIPE)

=head1 COPYRIGHT

Copyright 2018 by L<Gasper Software Consulting|http://gaspersoftware.com>

=head1 LICENSE

This distribution is released under the same license as Perl.

=cut

1;
