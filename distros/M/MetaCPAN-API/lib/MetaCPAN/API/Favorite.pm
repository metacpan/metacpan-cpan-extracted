use strict;
use warnings;
package MetaCPAN::API::Favorite;
# ABSTRACT: Favorite ++ information for MetaCPAN::API

our $VERSION = '0.51';

use Carp;
use Moo::Role;
use namespace::autoclean;

# /favorite/_search only
sub favorite {
    my $self  = shift;
    my %opts  = @_ ? @_ : ();
    my $url   = '';
    my $error = "Only 'search' can be used here";

    %opts or croak $error;

    my %extra_opts = ();

    if ( defined ( my $search_opts = $opts{'search'} ) ) {
        ref $search_opts && ref $search_opts eq 'HASH'
            or croak $error;

        %extra_opts = %{$search_opts};
        $url        = 'favorite/_search';
    } else {
        croak $error;
    }

    return $self->fetch( $url, %extra_opts );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaCPAN::API::Favorite - Favorite ++ information for MetaCPAN::API

=head1 VERSION

version 0.51

=head1 DESCRIPTION

This role provides MetaCPAN::API with fetching information about favorite
++ information.

=head1 METHODS

=head2 favorite

    # example lifted from MetaCPAN docs
    my $result = $mcpan->favorite(
        search => {
            user   => "SZABGAB",
            fields => "distribution",
            size   => 100,
        },
    );

Searches MetaCPAN for favorite ++ information.

Only complex searches are currently available.

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
