package # no_index
  Dist::Zilla::PluginBundle::EasyRemover;
use Moose;
with qw(
  Dist::Zilla::Role::PluginBundle::Easy
  Dist::Zilla::Role::PluginBundle::PluginRemover
);

sub mvp_multivalue_args { 'prefixes' }

sub add_prefix {
  my ($self, $str) = @_;
  return join '/', @{ $self->payload->{prefixes} || [] }, $str;
}

around add_plugins => sub {
  my ($orig, $self, @args) = @_;
  $_->[1] = $self->add_prefix($_->[1]) for @args;
  return $self->$orig(@args);
};

sub configure {
  my $self = shift;
  $self->add_plugins(
    # ::Easy takes these name/package in reverse order
    [AutoPrereqs => 'Scan4Prereqs'],
    [PruneCruft  => 'GoodbyeGarbage'],
  );
}

__PACKAGE__->meta->make_immutable;
1;
