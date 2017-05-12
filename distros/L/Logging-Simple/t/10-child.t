#!/usr/bin/perl
use strict;
use warnings;

use File::Temp;
use Logging::Simple;
use Test::More;

is (mkdir('t/working'), 1, "created working dir ok") if ! -d 't/working';

my $mod = 'Logging::Simple';

my $fn = 't/working/append.log';
my $parent = 't/working/parent.log';
my $f1 = 't/working/one.log';
my $f2 = 't/working/two.log';
my $f3 = 't/working/three.log';
my $f4 = 't/working/four.log';

{ # append file
    my $log = $mod->new(
        file       => $fn,
        name       => 'parent',
        level      => 7
    );
    $log->display(time => 0);
    $log->_6( 'in parent main' );

    run();
    run();

    sub run {
        one( 'blah' );
        four( 'crap' );
        three( 'died' );
        three( 'whoops' );
        two( 'two' );
        two( 'xxx' );
        three( 'asdfas' );
        one( 'vbqewqrq' );
    }
    sub one {
        my $log = $log->child( 'one' );
        my $x = shift;
        $log->_6( $x );
    }
    sub two {
        my $log = $log->child( 'two' );
        my $x = shift;
        $log->_6( $x );
        $log->_7( $x );
    }
    sub three {
        my $log = $log->child( 'three' );
        $log->_6( shift );
        $log->_0( shift );
    }
    sub four {
        my $log = $log->child( 'four' );
        $log->_6( shift );
        $log->_2( shift );
    }
}
{ # individual files

    my $log = $mod->new(
        file       => $parent,
        name       => 'parent',
        write_mode => 'w',
        level      => 7
    );
    $log->display(time => 0);
    $log->_6( 'in parent main' );

    run1();

    sub run1 {
        one1( 'blah' );
        four1( 'crap' );
        three1( 'died' );
        three1( 'whoops' );
        two1( 'two' );
        two1( 'xxx' );
        three1( 'asdfas' );
        one1( 'vbqewqrq' );
    }
    sub one1 {
        my $log = $log->child( 'one' );
        $log->file($f1, 'w');
        my $x = shift;
        $log->_6( $x );
    }
    sub two1 {
        my $log = $log->child( 'two' );
        $log->file($f2, 'w');
        my $x = shift;
        $log->_6( $x );
        $log->_7( $x );
    }
    sub three1 {
        my $log = $log->child( 'three' );
        $log->file($f3, 'w');
        $log->_6( shift );
        $log->_0( shift );
    }
    sub four1 {
        my $log = $log->child( 'four' );
        $log->file($f4, 'w');
        $log->_6( shift );
        $log->_2( shift );
    }
}
{ # child subclassing
    my $msg;

    my $log = Logging::Simple->new(name => 'parent', print => 0);
    $log->display(0);
    $log->display(name => 1);

    my $c = $log->child('child');
    like ($c->_0("msg"), qr/\[parent\.child\]/, "first child ok");

    my $c1 = $c->child('c1');
    like ($c1->_0("msg"), qr/\[parent\.child\.c1\]/, "2nd child ok");

    my $c2 = $c1->child('c2');
    is ($c2->_0, "[parent.child.c1.c2] \n", "3rd child ok");

    my $c1c3 = $c1->child('c3');
    is ($c1c3->_0, "[parent.child.c1.c3] \n", "c1->c3 child ok");
}

done_testing();
