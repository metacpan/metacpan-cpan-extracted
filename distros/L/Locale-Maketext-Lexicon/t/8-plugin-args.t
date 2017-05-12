#!/usr/bin/perl -w
#
# Check that the command line plugin args are parsed correctly
#

use strict;
use Test::More tests => 12;

use_ok('Locale::Maketext::Extract::Run');

test( undef, { warnings => undef,wrap => 0 }, 'no options' );
test( ['yaml'],
      { warnings => 1, wrap => 0, plugins => { yaml => [] } },
      'builtin - no file types' );
test( ['yaml=*'],
      { warnings => 1, wrap => 0, plugins => { yaml => ['*'] } },
      'builtin - all file types' );
test( ['yaml=yml'],
      { warnings => 1, wrap => 0, plugins => { yaml => ['yml'] } },
      'builtin - one file types' );
test( ['yaml=yaml,yml'],
      { warnings => 1, wrap => 0, plugins => { yaml => [ 'yaml', 'yml' ] } },
      'builtin - two file types' );
test( ['yaml=yaml,yml,conf'],
      { warnings => 1, wrap => 0, plugins => { yaml => [ 'yaml', 'yml', 'conf' ] } },
      'builtin - three file types' );
test( ['yaml=yaml,*,conf'],
      { warnings => 1, wrap => 0, plugins => { yaml => ['*'] } },
      'builtin - all plus file types' );
test( ['yaml=.yaml,.conf'],
      { warnings => 1, wrap => 0, plugins => { yaml => [ 'yaml', 'conf' ] } },
      'builtin - trim leading period' );
test( ['My::Module=.yaml,.conf'],
      { warnings => 1, wrap => 0, plugins => { 'My::Module' => [ 'yaml', 'conf' ] } },
      'custom - trim leading period' );
test_fail( ['y~aml=..yaml,.conf'],
           q(Couldn't understand plugin option 'y~aml=..yaml,.conf'),
           'Bad plugin' );
test_fail( ['yaml=..yaml,.conf'],
           q(Couldn't understand '..yaml' in plugin 'yaml=..yaml,.conf'),
           'Bad filetypes' );

sub test {
    my $P = shift;
    my $options = Locale::Maketext::Extract::Run->_parse_extract_options(
                                                                { P => $P } );
    delete $options->{verbose};
    is_deeply( $options, shift, shift );
}

sub test_fail {
    my $P     = shift;
    my $match = shift;
    eval {
        my $options
            = Locale::Maketext::Extract::Run->_parse_extract_options(
                                                                { P => $P } );
    };
    like( $@, qr/^\Q$match\E/, shift );
}
