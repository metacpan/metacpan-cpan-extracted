package Dist::Zilla::Role::Stash 6.032;
# ABSTRACT: something that stores options or data for later reference

use Moose::Role;

use Dist::Zilla::Pragmas;

use namespace::autoclean;

sub register_component {
  my ($class, $name, $arg, $section) = @_;

  # $self->log_debug([ 'online, %s v%s', $self->meta->name, $version ]);
  my $entry = $class->stash_from_config($name, $arg, $section);

  $section->sequence->assembler->register_stash($name, $entry);

  return;
}

sub stash_from_config {
  my ($class, $name, $arg, $section) = @_;

  my $self = $class->new($arg);
  return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::Stash - something that stores options or data for later reference

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
