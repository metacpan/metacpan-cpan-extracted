#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

BEGIN { plan skip_all => 'the op keyword needs perl 5.14' if $] < 5.014 }

use Ex::Op ();

sub op { 'the sub named op: ' . join ',', @_ }

{
    use Ex::Op;
    op inside ($x) { $x * 2 }
    ok( Ex::Op::is_op(\&inside), 'the keyword in the block that used Ex::Op' );
}

is( op(1, 2), 'the sub named op: 1,2', 'outside that block, op(...) calls a sub named op' );

my $outside = eval q{ op later ($x) { $x } 1 };
ok( !$outside, '... and op NAME is not the keyword there' );

{
    use Ex::Op;
    is( op(3), 'the sub named op: 3', 'where the keyword is on, op(...) still calls a sub named op' );
    my %h = (op => 1);
    is( $h{op}, 1, '... op as a hash key' );
    is( { op => 2 }->{op}, 2, '... op before =>' );
    is( EO::Kw::Meth->op, 'method', '... op as a method name' );
    no Ex::Op;
    my $r = eval q{ op after_no ($x) { $x } 1 };
    ok( !$r, 'no Ex::Op turns the keyword off' );
}

{
    package EO::Kw::Inh;
    BEGIN { our @ISA = ('Ex::Op') }
    package main;
    use Ex::Op;
    BEGIN { EO::Kw::Inh->unimport }
    op still_on ($x) { $x }
    ok( Ex::Op::is_op(\&still_on), 'a subclass\'s unimport does not turn the keyword off' );
}

{
    package EO::Kw::NoImport;
    use Ex::Op '-noimport';
    op no_import ($x) { $x }
    ::ok( Ex::Op::is_op(\&no_import), q{-noimport still gives the keyword} );
    ::ok( !defined &EO::Kw::NoImport::import, '... and installs no import' );
}

done_testing;

package EO::Kw::Meth;
sub op { 'method' }
