use strict;
use warnings;

package # no_index
  TestBundles;

package
  Pod::Weaver::PluginBundle::RoundHere;

sub pkg { 'Pod::Weaver::' . $_[0] }

sub mvp_bundle_config {
  return (
    [Omaha   => pkg('Plugin::Jones'),         { salutation => 'mr' }],
    [Perfect => pkg('Section::BlueBuildings'), { ':version' => '0.003' }],
  );
}

package
  TestBundles::AnnaBegins;

sub pkg { __PACKAGE__ . '::' . $_[0] }

sub bundle_config {
  return (
    # in prereqs version should be 1.2
    [Time      => pkg('Time'), {':version' => '1.2', needs_feature => 'b',}],
    [TimeAgain => pkg('Time'), {':version' => '1.1', only_needs => ['feature', 'a'] }],
    [Rain      => pkg('King')],
  );
}

package
  Dist::Zilla::PluginBundle::SullivanStreet;

sub pkg { 'Dist::Zilla::' . $_[0] }

our $Easy = 0;
sub does_easy { $Easy = $_[1] }
sub DOES { $Easy }

sub add_bundle {
  my ($self) = @_;
  push @{ $self->{plugins} }, (
    [August => pkg('Plugin::Everything')],
    [After  => pkg('Plugin::Everything')],
  );
}

sub new {
  my $self = bless { plugins => [], }, shift;
  push @{ $self->{plugins} }, (
    [Ghost   => pkg('Plugin::Train')],
    [Raining => 'In::Baltimore', { ':version' => 'v1.23.45' }],
    [Murder  => pkg('PluginBundle::Of::One'),  { 'version'  => 'not :version' }],
  );
  $self->add_bundle('EverythingAfter'),
  return $self;
}

sub bundle_config {
  return @{ $_[0]->new->plugins }
}

sub plugins { $_[0]->{plugins} }

1;
