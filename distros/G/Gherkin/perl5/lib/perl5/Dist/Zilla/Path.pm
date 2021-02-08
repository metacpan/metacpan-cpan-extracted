use strict;
use warnings;
use utf8;

package Dist::Zilla::Path 6.017;
# ABSTRACT: a helper to get Path::Tiny objects

use parent 'Path::Tiny';

use Path::Tiny 0.052 qw();  # issue 427
use Scalar::Util qw( blessed );
use Sub::Exporter -setup => {
  exports => [ qw( path ) ],
  groups  => { default => [ qw( path ) ] },
};

sub path {
  my ($thing, @rest) = @_;

  if (@rest == 0 && blessed $thing) {
    return $thing if $thing->isa(__PACKAGE__);

    return bless(Path::Tiny::path("$thing"), __PACKAGE__)
      if $thing->isa('Path::Class::Entity') || $thing->isa('Path::Tiny');
  }

  return bless(Path::Tiny::path($thing, @rest), __PACKAGE__);
}

my %warned;

sub file {
  my ($self, @file) = @_;

  my ($package, $pmfile, $line) = caller;
  unless ($warned{ $pmfile, $line }++) {
    Carp::carp("->file called on a Dist::Zilla::Path object; this will cease to work in Dist::Zilla v7; downstream code should be updated to use Path::Tiny API, not Path::Class");
  }

  require Path::Class;
  Path::Class::dir($self)->file(@file);
}

sub subdir {
  my ($self, @subdir) = @_;
  Carp::carp("->subdir called on a Dist::Zilla::Path object; this will cease to work in Dist::Zilla v7; downstream code should be updated to use Path::Tiny API, not Path::Class");
  require Path::Class;
  Path::Class::dir($self)->subdir(@subdir);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Path - a helper to get Path::Tiny objects

=head1 VERSION

version 6.017

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
