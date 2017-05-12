use strict;
use warnings;
package MetaCPAN::API::Release;
# ABSTRACT: Distribution and releases information for MetaCPAN::API
$MetaCPAN::API::Release::VERSION = '0.50';
use Carp;
use Moo::Role;
use namespace::autoclean;

# /release/{distribution}
# /release/{author}/{release}
sub release {
    my $self  = shift;
    my %opts  = @_ ? @_ : ();
    my $url   = '';
    my $error = "Either provide 'distribution', or 'author' and 'release', " .
                "or 'search'";

    %opts or croak $error;

    my %extra_opts = ();

    if ( defined ( my $dist = $opts{'distribution'} ) ) {
        $url = "release/$dist";
    } elsif (
        defined ( my $author  = $opts{'author'}  ) &&
        defined ( my $release = $opts{'release'} )
      ) {
        $url = "release/$author/$release";
    } elsif ( defined ( my $search_opts = $opts{'search'} ) ) {
        ref $search_opts && ref $search_opts eq 'HASH'
            or croak $error;

        %extra_opts = %{$search_opts};
        $url        = 'release/_search';
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

MetaCPAN::API::Release - Distribution and releases information for MetaCPAN::API

=head1 VERSION

version 0.50

=head1 DESCRIPTION

This role provides MetaCPAN::API with fetching information about distribution
and releases.

=head1 METHODS

=head2 release

    my $result = $mcpan->release( distribution => 'Moose' );

    # or
    my $result = $mcpan->release( author => 'DOY', release => 'Moose-2.0001' );

Searches MetaCPAN for a dist.

You can do complex searches using 'search' parameter:

    # example lifted from MetaCPAN docs
    my $result = $mcpan->release(
        search => {
            author => "OALDERS AND ",
            filter => "status:latest",
            fields => "name",
            size   => 1,
        },
    );

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
