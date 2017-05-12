package
  Dist::Zilla::PluginBundle::Catapult;

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

sub configure {
  my ($self) = @_;

  # these are reversed: [ $package_moniker, $name, \%paylod ]
  $self->add_plugins(
    [Angels => 'Of::The::Silences', {':version' => 3}],
    [Daylight => 'Fading'],
    ImNotSleeping =>
  );

  $self->add_bundle('@Goodnight' => {to => 'Elisabeth', ':version' => 2.2});
}

__PACKAGE__->meta->make_immutable;
1;

=head1 Config

=bundle_ini_string

=cut
