use 5.006;
use strict;
use warnings;

package Dist::Zilla::Util::ExpandINI::Reader;

our $VERSION = '0.003003';

# ABSTRACT: An order-preserving INI reader

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Carp qw(croak);

use parent 'Config::INI::Reader';

sub new {
  my ($class) = @_;

  my $self = {
    data     => [],
    sections => {},
  };

  bless $self => $class;
  $self->{current_section} = { name => $self->starting_section, lines => [], comment_lines => [] };

  return $self;
}

sub can_ignore {
  my ( $self, $line, ) = @_;
  if ( $line =~ /\A\s*;(.*?)\s*$/msx ) {
    push @{ $self->{current_section}->{comment_lines} }, "$1";
    return 1;
  }
  return $line =~ /\A\s*$/msx ? 1 : 0;
}

sub change_section {
  my ( $self, $section ) = @_;

  my ( $package, $name ) = $section =~ m{
    \A \s*                    # Ignore leading whitespace
    (?:                       # Optional Non Capture Group
      ([^/\s]+)               # Capture a bunch chars at the front
      \s*                     # then skip over subsequent whitespace
      /                       # and slash divider
      \s*
    )?
    (.+)                      # Capture the rest as a complete token
    \z
  }msx;
  $package = $name unless defined $package and length $package;

  Carp::croak qq{couldn't understand section header: "$section"}
    unless $package;

  push @{ $self->{data} }, $self->{current_section};

  if ( exists $self->{sections}->{$name} ) {
    Carp::croak qq{Duplicate section $name ( $package )};
  }
  $self->{sections}->{$name} = 1;
  $self->{current_section} = {
    name          => $name,
    package       => $package,
    lines         => [],
    comment_lines => [],
  };
  return;
}

sub set_value {
  my ( $self, $name, $value ) = @_;

  push @{ $self->{current_section}->{lines} }, $name, $value;
  return;
}

sub finalize {
  my ($self) = @_;
  push @{ $self->{data} }, $self->{current_section};
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::ExpandINI::Reader - An order-preserving INI reader

=head1 VERSION

version 0.003003

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
