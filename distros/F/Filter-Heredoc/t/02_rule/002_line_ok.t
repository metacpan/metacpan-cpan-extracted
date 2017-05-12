#!perl

use strict;
use warnings;
use Test::More; 

# Tests start here (the logic of existing syntax rules)

use Filter::Heredoc::Rule qw ( _hd_is_rules_ok_line hd_syntax );

my $EMPTY_STR = q{};
my %state;
my $line = q{ cat <<};

# Any line and without any rules are always trusted(ok) -- return true
hd_syntax ( 'none' );
is( _hd_is_rules_ok_line( $line ), 1, 'hd_is_rules_ok_line() with none');

# A dubious line with effective should return false line (i.e. not real ingress)
hd_syntax ( 'pod' );
is( _hd_is_rules_ok_line( $line ),$EMPTY_STR, 'hd_is_rules_ok_line() with pod');

# Any line and without any rules are always trusted(ok) -- return true
hd_syntax ( 'none' );
is( _hd_is_rules_ok_line( $line ), 1, 'hd_is_rules_ok_line() with none');

# A dubious line with effective should return false line (i.e. not real ingress)
hd_syntax ( 'pod' );
is( _hd_is_rules_ok_line( $line ), $EMPTY_STR, 'hd_is_rules_ok_line() with pod');

done_testing (4);