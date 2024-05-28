package Dist::Zilla::Path 6.032;
# ABSTRACT: a helper to get Path::Tiny objects

use Dist::Zilla::Pragmas;

use parent 'Path::Tiny';

use Path::Tiny 0.052 qw();  # issue 427
use Scalar::Util qw( blessed );
use Sub::Exporter -setup => {
  exports => [ qw( path ) ],
  groups  => { default => [ qw( path ) ] },
};

use namespace::autoclean -except => 'import';

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

  my $key = join qq{\0}, $pmfile, $line;
  unless ($warned{ $key }++) {
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

version 6.032

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
