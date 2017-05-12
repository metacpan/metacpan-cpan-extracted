package Dist::Zilla::PluginBundle::Alien;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Dist::Zilla::PluginBundle::Basic for Alien
$Dist::Zilla::PluginBundle::Alien::VERSION = '0.023';
use Moose;
use Dist::Zilla;
use Dist::Zilla::Plugin::Alien;
with 'Dist::Zilla::Role::PluginBundle::Easy';


use Dist::Zilla::PluginBundle::Basic;

# multiple build/install commands return as an arrayref
sub mvp_multivalue_args {
  Dist::Zilla::Plugin::Alien->mvp_multivalue_args;
};

sub configure {
  my ($self) = @_;

  $self->add_bundle('Filter' => {
    -bundle => '@Basic',
    -remove => ['MakeMaker'],
  });

  $self->add_plugins([ 'Alien' => {
    map { $_ => $self->payload->{$_} } keys %{$self->payload},
  }]);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Dist::Zilla::PluginBundle::Alien - Dist::Zilla::PluginBundle::Basic for Alien

=head1 VERSION

version 0.023

=head1 SYNOPSIS

In your B<dist.ini>:

  name = Alien-ffmpeg

  [@Alien]
  repo = http://ffmpeg.org/releases

=head1 DESCRIPTION

This plugin bundle allows to use L<Dist::Zilla::Plugin::Alien> together
with L<Dist::Zilla::PluginBundle::Basic>.

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
