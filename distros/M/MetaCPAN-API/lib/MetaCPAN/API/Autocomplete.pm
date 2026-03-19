use strict;
use warnings;
package MetaCPAN::API::Autocomplete;

our $VERSION = '0.52';

use Carp;
use Moo::Role;

# /search/autocomplete?q={search}
sub autocomplete {
    my $self  = shift;
    my %opts  = @_ ? @_ : ();
    my $url   = '';

    my $error      = "You have to provide a search term";
    my $size_error = "The size has to be between 0 and 100";

    %opts or croak $error;

    croak $error
        unless $opts{search} && ref $opts{search} eq 'HASH';

    my %extra_opts;

    if ( defined ( my $term = $opts{search}->{query} ) ) {
        $url           = 'search/autocomplete';
        $extra_opts{q} = $term;

        my $size = $opts{search}->{size};
        if ( defined $size && $size >= 0 && $size <= 100 ) {
            $extra_opts{size} = $size;
        } else {
            croak $size_error;
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

=for :stopwords Sawyer X autocompletion autocomplete

=head1 NAME

MetaCPAN::API::Autocomplete - Autocompletion info for MetaCPAN::API

=head1 DESCRIPTION

This role provides MetaCPAN::API with fetching autocomplete information

=head1 METHODS

=head2 autocomplete

    my $result = $mcpan->autocomplete(
        search => {
            query => 'Moose',
        },
    );

By default, you get 20 results (at maximum). If you need more, you
can also pass C<size>:

    my $result = $mcpan->autocomplete(
        search => {
            query => 'Moose',
            size  => 30,
        },
    );

There is a hardcoded limit of 100 results (hardcoded in MetaCPAN).

Searches MetaCPAN for autocompletion info.

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
