#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 7;
use Filter::Heredoc qw ( hd_labels hd_getstate hd_init _state );

my %marker;
my %state;
my $EMPTY_STR = q{};

# read out the default labels
%marker = hd_labels();

# Run a few lines to reach heredoc state
%state = hd_getstate( 'echo "This a shell script"' );  # source line
is( $state{statemarker}, $marker{source}, 'source: hd_getstate()');

%state = hd_getstate( 'echo cat <<- END;' );     # ingress
is( $state{statemarker}, $marker{ingress}, 'ingress: hd_getstate()');

%state = hd_getstate( 'Hello there there!' );     # heredoc
is( $state{statemarker}, $marker{heredoc}, 'heredoc: hd_getstate()');
is( $state{is_tabremoveflag}, '1', 'heredoc-tabflag: hd_getstate()');

# set(re) state to source and flush the terminator array (holding any delimiters)
hd_init();

# now use private sub to read it out marker
is( _state(), q{S}, 'hd_init: source marker');  # now get the expected source 

# now we should have reset the delimiter 'END' and the tab flag true.
%state = hd_getstate( 'Hello there there!' );
is( $state{is_tabremoveflag}, $EMPTY_STR, 'hd_init: reset-tabflag');
is( $state{blockdelimiter}, $EMPTY_STR, 'init-state: reset of the delimiter array');

