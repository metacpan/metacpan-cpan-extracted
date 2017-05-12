package Git::TagVersion;

use Moose;

our $VERSION = '1.01'; # VERSION
# ABSTRACT: module to manage version tags in git

use Git::TagVersion::Version;
use Git::Wrapper;


has 'fetch' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'push' => ( is => 'rw', isa => 'Bool', default => 0 );

has 'root' => ( is => 'ro', isa => 'Str', default => '.' );
has 'repo' => (
  is => 'ro', isa => 'Git::Wrapper', lazy => 1,
  default => sub {
    my $self = shift;
    return Git::Wrapper->new( $self->root );
  },
);

has 'version_regex' => ( is => 'ro', isa => 'Str', default => '^v(\d.+)$' );

has 'versions' => (
  is => 'ro', isa => 'ArrayRef[Git::TagVersion::Version]', lazy => 1,
  default => sub {
    my $self = shift;
    my @versions;

    if( $self->fetch ) {
      $self->repo->fetch;
    }

    my $regex = $self->version_regex;
    foreach my $tag ( $self->repo->tag ) {
      if( my ($v_str) = $tag =~ /$regex/) {
        my $version;
        eval {
          $version = Git::TagVersion::Version->new(
            repo => $self->repo,
          );
          $version->parse_version( $v_str );
          $version->tag( $tag );
        };
        if( $@ ) { next; }
        push( @versions, $version );
      }
    }
    @versions = sort @versions;
    my $prev;
    foreach my $version ( @versions ) {
      if( defined $prev ) {
        $version->prev( $prev );
      }
      $prev = $version;
    }

    @versions = reverse @versions;
    return \@versions;
  },
);

has 'last_version' => (
  is => 'ro', isa => 'Maybe[Git::TagVersion::Version]', lazy => 1,
  default => sub {
    my $self = shift;
    return( $self->versions->[0] );
  },
);

has 'incr_level' => ( is => 'rw', isa => 'Int', default => 0 );

has 'add_level' => ( is => 'rw', isa => 'Int', default => 0 );

has 'next_version' => (
  is => 'ro', isa => 'Maybe[Git::TagVersion::Version]', lazy => 1,
  default => sub {
    my $self = shift;
    if( ! defined $self->last_version ) {
      return;
    }
    if( $self->incr_level && $self->add_level ) {
      die('use increment or new minor version, not both');
    }
    my $next = $self->last_version->clone;
    if( $self->add_level ) {
      $next->add_level( $self->add_level );
    } else {
      $next->increment( $self->incr_level );
    }
    return $next;
  },
);

sub tag_next_version {
  my $self = shift;
  my $next = $self->next_version;

  if( ! defined $next ) {
    die('next version is not defined');
  }

  my $tag = 'v'.$next->as_string;
  $self->repo->tag($tag);

  if( $self->push ) {
    $self->repo->push('origin', $tag);
  }

  return $tag;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::TagVersion - module to manage version tags in git

=head1 VERSION

version 1.01

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning <ich@markusbenning.de>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
