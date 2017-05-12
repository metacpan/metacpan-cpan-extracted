#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use lib File::Spec->catdir($Bin, 'lib');
use Hook::Modular::Test ':all';
use Test::More tests => 1;
use parent 'Hook::Modular';

# Test that rules like My::Test::Rule::Maybe can take config themselves.
# specifying the appropriate plugin namespace for this program saves you from
# having to specify it in every config file.
use constant PLUGIN_NAMESPACE => 'My::Test::Plugin';

sub run {
    my $self = shift;
    $self->SUPER::run(@_);
    my %result;

    # Only call the 'init.greet' hook since by default, rules dispatch on the
    # first hook a plugin registers, and the My::Test::Plugin::Just::Greet
    # only registers with one hook, so there's no confusion.
    $self->run_hook('init.greet', { result => \%result });
    is( $result{text},
        ("My::Test::Plugin::Just::Greet says hello\n" x 2),
        'two out of three plugins get dispatched'
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
  - module: Just::Greet
    rule:
      module: Maybe
      chance: 1
  - module: Just::Greet
    rule:
      module: Maybe
      chance: 0
  - module: Just::Greet
    rule:
      module: Maybe
      chance: 1
