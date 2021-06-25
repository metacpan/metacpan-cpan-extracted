package Dist::Zilla::Plugin::EnsureMinimumPerl;

use Moose;
with qw(
  Dist::Zilla::Role::BeforeRelease
);
use namespace::autoclean;

our $VERSION = '0.02';

sub before_release {
  my $self     = shift;
  my $prereqs  = $self->zilla->prereqs->as_string_hash;

  foreach my $phase (keys %{$prereqs}) {
    foreach my $type (keys %{$prereqs->{$phase}}) {
      my $found = grep { $_ eq 'perl' } keys %{$prereqs->{$phase}{$type}};
      return if $found;
    }
  }

  $self->log_fatal('No minimum required version of Perl specified.');
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Dist::Zilla::Plugin::EnsureMinimumPerl - Ensure that you have specified a minimum version of Perl

=head1 SYNOPSIS

  # In your dist.ini
  [EnsureMinimumPerl]

=head1 DESCRIPTION

This C<Dist::Zilla> plugin checks to ensure that you have specified a minimum
required version of Perl, before allowing you to perform a release.

I kept forgetting to be explicit about this in my own releases, and so I
whipped this up to force me to do it.

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT

Copyright (C) 2021-, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
license as Perl itself.

=head1 SEE ALSO

=over

=item L<Dist::Zilla>

=back

=cut
