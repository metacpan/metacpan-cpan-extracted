#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 8;
use Filter::Heredoc qw ( hd_getstate ); 

my %state;
my ( $state, $line );
my $EMPTY_STR = q{};

# Test with indent removal (<<-) second ingress only, nested ingress

$line = q{# Tests with <<- (note that only tabs are removed, not multiple spaces};
%state = hd_getstate( $line );
is( $state{is_tabremoveflag}, $EMPTY_STR, 'hd_getstate(source)');

$line = q{cat << END1; cat <<-END2};
%state = hd_getstate( $line );
is( $state{is_tabremoveflag}, $EMPTY_STR, 'hd_getstate(nested ingress)');

$line = q{Greeting you are one of the top consumer of diskspace};
%state = hd_getstate( $line );
is( $state{is_tabremoveflag}, $EMPTY_STR, 'hd_getstate(1st heredoc)');

$line = q{on the system. Your home directory uses $amount disk blocks.};
%state = hd_getstate( $line );
is( $state{is_tabremoveflag}, $EMPTY_STR, 'hd_getstate(2nd heredoc)');

$line = q{END1};
%state = hd_getstate( $line );
is( $state{is_tabremoveflag}, $EMPTY_STR, 'hd_getstate(1st egress)');

$line = q{		Your friendly Sysadmin};
%state = hd_getstate( $line );
is( $state{is_tabremoveflag}, '1', 'hd_getstate(1st heredoc)');

$line = q{		END2};
%state = hd_getstate( $line );
is( $state{is_tabremoveflag}, '1', 'hd_getstate(2nd egress)');

$line = q{# eof};
%state = hd_getstate( $line );
is( $state{is_tabremoveflag}, $EMPTY_STR, 'hd_getstate(source)');

