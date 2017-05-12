#!/usr/bin/perl

package KiokuX::User::Util;

use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [qw(
        crypt_password
    )],
};


use Class::MOP;

sub crypt_password {
    my @args = @_;

    unshift @args, "passphrase" if @args % 2 == 1;

    my %args = @args;

    unless ( exists $args{class} ) {
        %args = (
            class       => "Authen::Passphrase::SaltedDigest",
            salt_random => 20,
            algorithm   => "SHA-1",
            %args,
        );
    }

    my $class = delete $args{class};

    Class::MOP::load_class($class);

    $class->new(%args);
}

__PACKAGE__

__END__

=pod

=head1 NAME

KiokuX::User::Util - Utility functions for L<KiokuX::User>

=head1 SYNOPSIS

    use KiokuX::User::Util;

    MyFoo::User->new(
        id       => "cutegirl17",
        password => crypt_password("justin timberlake!!!"),
    );

=head1 DESCRIPTION

This module provides utility functions.

=head1 EXPORTS

=over 4

=item crypt_password @args

If an even sized list is passed the first argument is assumed to be 'passphrase'.

Defaults to creating a L<Authen::Passphrase::SaltedDigest> with a 20 byte
random salt.

=back

=cut

# ex: set sw=4 et:

