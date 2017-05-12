use strict;
use warnings;
package MetaCPAN::API::POD;
# ABSTRACT: POD information for MetaCPAN::API
$MetaCPAN::API::POD::VERSION = '0.50';
use Carp;
use Moo::Role;
use namespace::autoclean;

# /pod/{module}
# /pod/{author}/{release}/{path}
sub pod {
    my $self  = shift;
    my %opts  = @_ ? @_ : ();
    my $url   = '';
    my $error = "Either provide 'module' or 'author and 'release' and 'path'";

    %opts or croak $error;

    if ( defined ( my $module = $opts{'module'} ) ) {
        $url = "pod/$module";
    } elsif (
        defined ( my $author  = $opts{'author'}  ) &&
        defined ( my $release = $opts{'release'} ) &&
        defined ( my $path    = $opts{'path'}    )
      ) {
        $url = "pod/$author/$release/$path";
    } else {
        croak $error;
    }

    # check content-type
    my %extra = ();
    if ( defined ( my $type = $opts{'content-type'} ) ) {
        $type =~ m{^ text/ (?: html|plain|x-pod|x-markdown ) $}x
            or croak 'Incorrect content-type provided';

        $extra{headers}{'content-type'} = $type;
    }

    $url = $self->base_url . "/$url";

    my $result = $self->ua->get( $url, \%extra );
    $result->{'success'}
        or croak "Failed to fetch '$url': " . $result->{'reason'};

    return $result->{'content'};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaCPAN::API::POD - POD information for MetaCPAN::API

=head1 VERSION

version 0.50

=head1 DESCRIPTION

This role provides MetaCPAN::API with fetching POD information about modules
and distribution releases.

=head1 METHODS

=head2 pod

    my $result = $mcpan->pod( module => 'Moose' );

    # or
    my $result = $mcpan->pod(
        author  => 'DOY',
        release => 'Moose-2.0201',
        path    => 'lib/Moose.pm',
    );

Searches MetaCPAN for a module or a specific release and returns the POD.

Content type can also be specified, like so:

    my $result = $mcpan->pod( module => 'Moose', 'content-type' => 'x-pod' );

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
