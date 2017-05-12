use strict;
use warnings;
package MetaCPAN::API::Distribution;
# ABSTRACT: Distribution information for MetaCPAN::API
$MetaCPAN::API::Distribution::VERSION = '0.50';
use Carp;
use Moo::Role;
use namespace::autoclean;

# /distribution/{distribution}
sub distribution {
    my $self  = shift;
    my $url   = '';
    my $error = "Either provide a distribution or 'search'";

    my %extra_opts = ();

    if ( @_ == 1 ) {
        $url = 'distribution/' . shift;
    } elsif ( @_ ) {
        my %opts = @_;

        if ( defined ( my $dist = $opts{'distribution'} ) ) {
            $url = "distribution/$dist";
        } elsif ( defined ( my $search_opts = $opts{'search'} ) ) {
            ref $search_opts && ref $search_opts eq 'HASH'
                or croak $error;
    
            %extra_opts = %{$search_opts};
            $url        = 'distribution/_search';
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

MetaCPAN::API::Distribution - Distribution information for MetaCPAN::API

=head1 VERSION

version 0.50

=head1 DESCRIPTION

This role provides MetaCPAN::API with fetching information about distributions,
returning information about the distribution which is not specific to a version
(like RT bug counts).

=head1 METHODS

=head2 distibution

    my $result = $mcpan->distibution('DBIx-Class');

Searches MetaCPAN for a dist.

You can do complex searches using 'search' parameter:

    my $result = $mcpan->distribution(
        search => {
            filter => { exists => { field => 'bugs.source' } },
            fields => ['name', 'bugs.source'],
            size   => 5,
        },
    );

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
