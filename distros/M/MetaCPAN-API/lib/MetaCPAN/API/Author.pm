use strict;
use warnings;
package MetaCPAN::API::Author;

our $VERSION = '0.52';

use Carp;
use Moo::Role;
use namespace::autoclean;

# /author/{author}
sub author {
    my $self = shift;
    my ( $url, %extra_opts );

    if ( @_ == 1 ) {
        $url = 'author/' . shift;
    } elsif ( @_ == 2 ) {
        my %opts = @_;

        if ( defined $opts{'pauseid'} ) {
            $url = "author/" . $opts{'pauseid'};
        } elsif ( defined $opts{'search'} ) {
            my $search_opts = $opts{'search'};

            croak "'search' key must be hashref"
                unless ref $search_opts && ref $search_opts eq 'HASH';

            %extra_opts = %{$search_opts};
            $url        = 'author/_search';
        } else {
            croak 'Unknown option given';
        }
    } else {
        croak 'Please provide an author PAUSEID or a "search"';
    }

    return $self->fetch( $url, %extra_opts );
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Sawyer X

=head1 NAME

MetaCPAN::API::Author - Author information for MetaCPAN::API

=head1 DESCRIPTION

This role provides MetaCPAN::API with fetching information about authors.

=head1 METHODS

=head2 author

    my $result1 = $mcpan->author('XSAWYERX');
    my $result2 = $mcpan->author( pauseid => 'XSAWYERX' );

Searches MetaCPAN for a specific author.

You can do complex searches using 'search' parameter:

    # example lifted from MetaCPAN docs
    my $result = $mcpan->author(
        search => {
            q    => 'profile.name:twitter',
            size => 1,
        },
    );

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/xsawyerx/metacpan-api/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
