#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 21;
use Filter::Heredoc qw ( hd_getstate hd_labels ); 

my $SPACE = q{ };
my %marker;
my %state;

# read out the default labels
%marker = hd_labels();

%state = hd_getstate( 'echo "This a shell script"' );
is( $state{statemarker}, $marker{source}, 'source: hd_getstate()');

%state = hd_getstate( 'echo "cat << E\ND"' );
is( $state{statemarker}, $marker{ingress} , '<<END: hd_getstate()');

%state = hd_getstate( 'Mail from sysadmin' );
is( $state{statemarker}, $marker{heredoc} , 'heredoc: hd_getstate()');

%state = hd_getstate( 'END' );
is( $state{statemarker}, $marker{egress} , 'END: hd_getstate()');

%state = hd_getstate( $SPACE . 'done' );
is( $state{statemarker}, $marker{source}, 'source: hd_getstate()');

%state = hd_getstate( 'echo "Back in the shell script"' );
is( $state{statemarker}, $marker{source}, 'source: hd_getstate()');


# Run this a second time
%state = hd_getstate( 'echo "This a shell script"' );
is( $state{statemarker}, $marker{source}, 'source: hd_getstate()');

%state = hd_getstate( 'echo "cat << E\ND"' );
is( $state{statemarker}, $marker{ingress} , '<<END: hd_getstate()');

%state = hd_getstate( 'Mail from sysadmin' );
is( $state{statemarker}, $marker{heredoc} , 'heredoc: hd_getstate()');

%state = hd_getstate( 'END' );
is( $state{statemarker}, $marker{egress} , 'END: hd_getstate()');

%state = hd_getstate( $SPACE . 'done' );
is( $state{statemarker}, $marker{source}, 'source: hd_getstate()');

%state = hd_getstate( 'echo "Back in the shell script"' );
is( $state{statemarker}, $marker{source}, 'source: hd_getstate()');


# Run this a third time, now with multiple lines at source/heredoc state
%state = hd_getstate( 'echo "This a shell script"' );
is( $state{statemarker}, $marker{source}, 'source: hd_getstate()');

%state = hd_getstate( 'echo "This a 2nd line in the shell script"' );
is( $state{statemarker}, $marker{source}, '2nd source: hd_getstate()');

%state = hd_getstate( 'echo "cat << E\ND"' );
is( $state{statemarker}, $marker{ingress} , '<<END: hd_getstate()');

%state = hd_getstate( 'Mail from sysadmin' );
is( $state{statemarker}, $marker{heredoc} , 'heredoc: hd_getstate()');

%state = hd_getstate( 'Please empty your inbox' );
is( $state{statemarker}, $marker{heredoc} , '2nd heredoc: hd_getstate()');

%state = hd_getstate( 'END' );
is( $state{statemarker}, $marker{egress} , 'END: hd_getstate()');

%state = hd_getstate( $SPACE . 'done' );
is( $state{statemarker}, $marker{source}, 'source: hd_getstate()');

%state = hd_getstate( 'echo "Back in the shell script"' );
is( $state{statemarker}, $marker{source}, 'source: hd_getstate()');

%state = hd_getstate( 'echo "Back in the shell script 2nd line"' );
is( $state{statemarker}, $marker{source}, '2nd source: hd_getstate()');



