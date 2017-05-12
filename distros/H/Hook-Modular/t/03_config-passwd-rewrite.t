#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use lib File::Spec->catdir($Bin, 'lib');
use Hook::Modular::Test ':all';
use Hook::Modular::Crypt;
use YAML 'LoadFile';
use Test::More tests => 3;
use parent 'Hook::Modular';

# specifying the appropriate plugin namespace for this program saves you from
# having to specify it in every config file.
use constant PLUGIN_NAMESPACE      => 'My::Test::Plugin';
use constant SHOULD_REWRITE_CONFIG => 1;
my $config_filename = write_config_file(
    do { local $/; <DATA> }
);

sub run {
    my $self = shift;
    $self->SUPER::run(@_);
    is($self->{config_path}, $config_filename, 'config_path');
    my $config   = LoadFile($config_filename);
    my $password = $config->{plugins}[0]{config}{password};
    is(substr($password, 0, 8), 'base64::', "password starts with 'base64::'");
    is(Hook::Modular::Crypt->decrypt($password),
        'flurble', 'password decrypted');
}
main->bootstrap(config => $config_filename);
__DATA__
global:
  log:
    level: error
  cache:
    base: /tmp/test-hook-modular
  # plugin_namespace: My::Test::Plugin

plugins:
  - module: Some::Printer
    config:
      password: flurble
      indent: 4
      indent_char: '*'
      text: 'this is some printer'
