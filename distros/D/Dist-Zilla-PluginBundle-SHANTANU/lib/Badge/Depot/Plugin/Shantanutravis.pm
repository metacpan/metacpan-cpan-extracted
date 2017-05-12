use strict;
use warnings;

package Badge::Depot::Plugin::Shantanutravis;

our $VERSION = '0.43'; # VERSION

# Dependencies
use Moose;
use namespace::autoclean;
use Types::Standard qw/Str HashRef/;
use Path::Tiny;
use JSON::MaybeXS 'decode_json';
with 'Badge::Depot';

# ABSTRACT: Shantanu Bhadoria's Travis plugin for Badge::Depot based off Badge::Depot::Plugin::Travis


has user => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $self = shift;
        if ( $self->has_meta ) {
            return $self->_meta->{'username'}
              if exists $self->_meta->{'username'};
        }
    },
);


has repo => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $self = shift;
        if ( $self->zilla ) {
            return 'perl-' . $self->zilla->name;
        }
    },
);


has branch => (
    is      => 'ro',
    isa     => Str,
    default => 'build/master',
);

has _meta => (
    is        => 'ro',
    isa       => HashRef,
    predicate => 'has_meta',
    builder   => '_build_meta',
);

sub _build_meta {
    my $self = shift;

    if ( $self->zilla ) {
        return {
            repo    => 'perl-' . $self->zilla->name,
            version => $self->zilla->version,
        };
    }

    return {} if !path('META.json')->exists;

    my $json = path('META.json')->slurp_utf8;
    my $data = decode_json($json);

    return {} if !exists $data->{'resources'}{'repository'}{'web'};

    my $repository = $data->{'resources'}{'repository'}{'web'};
    return {}
      if $repository !~
      m{^https://(?:www\.)?github\.com/([^/]+)/(.*)(?:\.git)?$};

    return {
        username => $1,
        repo     => $2,
    };
}


sub BUILD {
    my $self = shift;
    $self->link_url( sprintf 'https://travis-ci.org/%s/%s',
        $self->user, $self->repo );
    $self->image_url( sprintf 'https://api.travis-ci.org/%s/%s.svg?branch=%s',
        $self->user, $self->repo, $self->branch );
    $self->image_alt('Travis status');
}

1;

__END__

=pod

=head1 NAME

Badge::Depot::Plugin::Shantanutravis - Shantanu Bhadoria's Travis plugin for Badge::Depot based off Badge::Depot::Plugin::Travis

=head1 VERSION

version 0.43

=head1 ATTRIBUTES

=head2 user

=head2 repo

=head2 branch

=head1 METHODS

=head2 BUILD

=head1 AUTHOR

Shantanu Bhadoria <shantanu@cpan.org> L<https://www.shantanubhadoria.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
