#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use lib File::Spec->catdir($Bin, 'lib');
use Hook::Modular::Test ':all';
use Test::More tests => 1;
use parent 'Hook::Modular';

# Two plugins: one uses "Always", one "Never". This tests that rules can be
# found in different namespaces: Hook::Modular::Rule::Always and
# My::Test::Rule::Never.
# specifying the appropriate plugin namespace for this program saves you from
# having to specify it in every config file.
use constant PLUGIN_NAMESPACE => 'My::Test::Plugin';

sub run {
    my $self = shift;
    $self->SUPER::run(@_);
    my %result;
    $self->run_hook('init.greet',   { result => \%result });
    $self->run_hook('output.print', { result => \%result });
    is( $result{text},
        "My::Test::Plugin::Just::Greet says hello\n",
        'only one plugin runs'
    );
}
my $config_filename = write_config_file(
    do { local $/; <DATA> }
);
main->bootstrap(config => $config_filename);
__DATA__
global:
  log:
    level: error
  cache:
    base: /tmp/test-hook-modular
  rule_namespaces: My::Test::Rule

plugins:
  - module: Some::Printer
    rule:
      module: Never
    config:
      indent: 4
      indent_char: '*'
      text: 'this is some printer'
  - module: Just::Greet
    rule:
      module: Always
