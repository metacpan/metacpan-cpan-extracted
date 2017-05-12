#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use lib File::Spec->catdir($Bin, 'lib');
use Test::More tests => 6;
use YAML;
use parent 'Hook::Modular';

# Test that we can't rewrite a password that didn't come from a config file.
# specifying the appropriate plugin namespace for this program saves you from
# having to specify it in every config file.
use constant PLUGIN_NAMESPACE => 'My::Test::Plugin';

sub run {
    my $self = shift;
    $self->SUPER::run(@_);
    my %result;
    $self->run_hook('output.print', { result => \%result });
    is( $result{text},
        "****this is some printer\n",
        'Some::Printer output.print'
    );
}
my $config_scalar = do { local $/; <DATA> };
my $self = main->bootstrap(config => \$config_scalar);
is($self->{rewrite_tasks}[0][0],
    'password', 'scalar ref: has rewrite task for password');
is($self->{trace}{ignored_rewrite_config},
    1, 'scalar ref: ignored rewrite tasks');
my $config_hash = Load $config_scalar;
$self = main->bootstrap(config => $config_hash);
is($self->{rewrite_tasks}[0][0],
    'password', 'hash ref: has rewrite task for password');
is($self->{trace}{ignored_rewrite_config}, 1,
    'hash ref: ignored rewrite tasks');
__DATA__
global:
  log:
    level: error
  cache:
    base: /tmp/test-hook-modular
  should_rewrite_config: 1
  # plugin_namespace: My::Test::Plugin

plugins:
  - module: Some::Printer
    config:
      password: somepassword
      indent: 4
      indent_char: '*'
      text: 'this is some printer'
