#!/usr/bin/perl
use strict;
use warnings;
use FindBin '$Bin';
use lib File::Spec->catdir($Bin, 'lib');
use Hook::Modular::Test ':all';
use Test::More tests => 1;
use parent 'Hook::Modular';

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
  # plugin_namespace: My::Test::Plugin

plugins:
  - module: Some::Printer
    config:
      indent: 4
      indent_char: '*'
      text: 'this is some printer'
