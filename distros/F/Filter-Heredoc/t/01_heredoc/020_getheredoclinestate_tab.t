#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 6;
use Filter::Heredoc qw ( hd_getstate ); 

my %state;
my ( $state, $line );
my $EMPTY_STR = q{};

# Test with indent removal (<<-), but only tabs are removed

$line = q{# Tests with <<- (note that only tabs are removed, not multiple spaces};
%state = hd_getstate( $line );
is( $state{is_tabremoveflag}, $EMPTY_STR, 'hd_getstate(source)');

$line = q{cat <<- END};
%state = hd_getstate( $line );
is( $state{is_tabremoveflag}, $EMPTY_STR, 'hd_getstate(ingress)');

$line = q{		Greeting you are one of the top consumer of diskspace};
%state = hd_getstate( $line );
is( $state{is_tabremoveflag}, '1', 'hd_getstate(1st heredoc)');

$line = q{		on the system. Your home directory uses $amount disk blocks.};
%state = hd_getstate( $line );
is( $state{is_tabremoveflag}, '1', 'hd_getstate(2nd heredoc)');

$line = q{		END};
%state = hd_getstate( $line );
is( $state{is_tabremoveflag}, '1', 'hd_getstate(egress)');

$line = q{# eof};
%state = hd_getstate( $line );
is( $state{is_tabremoveflag}, $EMPTY_STR, 'hd_getstate(source)');

