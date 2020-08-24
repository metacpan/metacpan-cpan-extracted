use strict;
use warnings;
package MetaCPAN::Client::Module;
# ABSTRACT: A Module data object
$MetaCPAN::Client::Module::VERSION = '2.028000';
use Moo;
extends 'MetaCPAN::Client::File';

sub metacpan_url {
    my $self = shift;
    sprintf("https://metacpan.org/pod/release/%s/%s/%s",
            $self->author, $self->release, $self->path );
}

sub package {
    my $self = shift;
    return $self->client->package( $self->documentation );
}

sub permission {
    my $self = shift;
    return $self->client->permission( $self->documentation );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaCPAN::Client::Module - A Module data object

=head1 VERSION

version 2.028000

=head1 SYNOPSIS

    my $module = MetaCPAN::Client->new->module('Moo');

=head1 DESCRIPTION

A MetaCPAN module entity object.

This is currently the exact same as L<MetaCPAN::Client::File>.

=head1 ATTRIBUTES

Whatever L<MetaCPAN::Client::File> has.

=head1 METHODS

=head2 metacpan_url

Returns a link to the module page on MetaCPAN.

=head2 package

Returns an L<MetaCPAN::Client::Package> object for the module.

=head2 permission

Returns an L<MetaCPAN::Client::Permission> object for the module.

=head1 AUTHORS

=over 4

=item *

Sawyer X <xsawyerx@cpan.org>

=item *

Mickey Nasriachi <mickey@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
