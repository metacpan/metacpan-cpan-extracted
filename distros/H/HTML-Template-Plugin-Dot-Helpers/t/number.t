#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

plan tests => 4 +
              5;

use_ok('HTML::Template::Pluggable');
use_ok('HTML::Template::Plugin::Dot');
use_ok('HTML::Template::Plugin::Dot::Helpers');
use_ok('Number::Format');

my $t1 = HTML::Template::Pluggable->new(
    scalarref       => \q{<tmpl_var name="Number.format_picture(some.value, '#,###,###.##')">=<tmpl_var some.value>},
    global_vars     => 1,
    case_sensitive  => 1,
    die_on_bad_params => 0,
    );
$t1->param( some => { value => 3_105_345.239_5 } );
my $o1 = $t1->output;
# diag("output: ", $o1);
like( $o1, qr/3,10/ );


my $t2 = HTML::Template::Pluggable->new(
    scalarref       => \q{<tmpl_if Number.gt(some.value,3)><tmpl_var name="Number.format_picture(some.value, '#,###,###.##')">=<tmpl_var some.value><tmpl_else>No</tmpl_if>},
    global_vars     => 1,
    case_sensitive  => 1,
    die_on_bad_params => 0,
    );
$t2->param( some => { value => 3_105_345.239_5 } );
my $o2 = $t2->output;
# diag("output: ", $o2);
like( $o2, qr/3,10/ );

$t2->param( some => { value => 1.053_45 } );
my $o3 = $t2->output;
# diag("output: ", $o3);
like( $o3, qr/No/ );

{
   package My::Obj;
   use overload q{""} => \&stringify, '0+' => \&stringify, fallback => 1;

   sub new { bless {id=>3}, shift }
   sub stringify { return $_[0]->{id} }
}

my $t3 = HTML::Template::Pluggable->new(
    scalarref       => \q{<tmpl_if name="Number.lt(some.obj, some.value)">Yes<tmpl_else>No</tmpl_if> (<tmpl_var some.value> <tmpl_var some.obj>)},
    global_vars     => 1,
    case_sensitive  => 1,
    die_on_bad_params => 0,
    );
$t3->param( some => { value => 3_105_345.239_5, obj => My::Obj->new  } );
my $o4 = $t3->output;
# diag("output: ", $o4);
like( $o4, qr/Yes/ );

my $num = Number::Format->new->format_price(2.25);
my $t4 = HTML::Template::Pluggable->new(
    scalarref       => \q{<tmpl_loop o.v:h><tmpl_var h.n> <tmpl_var name="Number.format_price(h.n)"></tmpl_loop>},
    global_vars     => 1,
    case_sensitive  => 1,
    die_on_bad_params => 0,
    );
$t4->param( o => { v => [ { n => 1.25 }, { n => 2.25 } ] } );
my $o5 = $t4->output;
# diag("output: ", $o4);
like( $o5, qr/$num/ );


__END__
