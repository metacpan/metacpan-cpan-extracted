use 5.006;    # our
use strict;
use warnings;

package       # no index
  Bundled::Plugin;

our $VERSION = '0.001000';

use Moose qw( with has around );
with "Dist::Zilla::Role::Plugin", "Dist::Zilla::Role::ConfigDumper";

# ABSTRACT: An example dzil plugin to load from inc/

# AUTHORITY

has "property" => (
  is       => 'ro',
  required => 1
);
around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $localconf = $config->{ +__PACKAGE__ } = {};

  $localconf->{property} = $self->property;

  $localconf->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION;

  return $config;
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
