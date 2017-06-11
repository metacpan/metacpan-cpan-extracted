use strict;
use warnings;
package MetaCPAN::API::Rating;
# ABSTRACT: Rating information for MetaCPAN::API

our $VERSION = '0.51';

use Carp;
use Moo::Role;
use namespace::autoclean;

# /rating/{id}
# /rating/_search
sub rating {
    my $self  = shift;
    my $url   = '';
    my $error = "Either provide 'id' or 'search'";

    my %extra_opts = ();

    if ( @_ == 1 ) {
        $url = 'rating/' . shift;
    } elsif ( @_ ) {
        my %opts = @_;

        if ( defined ( my $id = $opts{'id'} ) ) {
            $url = "rating/$id";
        } elsif ( defined ( my $search_opts = $opts{'search'} ) ) {
            ref $search_opts && ref $search_opts eq 'HASH'
                or croak $error;

            %extra_opts = %{$search_opts};
            $url        = 'rating/_search';
        } else {
            croak $error;
        }
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

MetaCPAN::API::Rating - Rating information for MetaCPAN::API

=head1 VERSION

version 0.51

=head1 DESCRIPTION

This role provides MetaCPAN::API with fetching information about CPAN
ratings.

=head1 METHODS

=head2 rating

    my $result = $mcpan->rating( id => 'UC6tqabqR-y3xxZk0tgVXQ' );

Searches MetaCPAN for CPAN ratings.

You can do complex searches using 'search' parameter:

    my $result = $mcpan->rating(
        search => {
            filter => "distribution:Moose",
            fields => [ "date", "rating" ],
        },
    );

These searches will give you the right _id to use for more detailed
information.

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
