#===============================================================================
#
#  DESCRIPTION:  Test export and import from JXML
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
#$Id$
use strict;
use warnings;
use Flow;
use Flow::Test;
use Data::Dumper;

use Test::More tests => 7;                      # last test to print
#use Test::More qw(no_plan);    # last test to print
use_ok('Flow::To::JXML');
use_ok('Flow::From::JXML');

my @test_flow = ( 1, 2, 3 );
my $str1      = '';
my $f1        = create_flow( ToJXML => \$str1 );
$f1->parser->run(@test_flow);
ok $str1, "Serialize";
my @from_flow = ();
my $str2      = $str1;
my $f2        = create_flow(
    FromJXML => \$str2,
    sub {
        push @from_flow, @_;
    }
);
$f2->run();
is_deeply( \@from_flow, \@test_flow, 'Restore' );
{
    my @dset1 = ( 1 .. 5 );
    my @dset2 = ( 40 .. 45 );
    my ( $f30, $f40 ) =
      ( create_flow( sub { \@dset1 } ), create_flow( sub { \@dset2 } ) );
    my $str1 = "";
    my $f1 =
      create_flow( Join => { Flow1 => $f30, Flow2 => $f40 }, ToJXML => \$str1 );
    $f1->parser->run;
    ok $str1, "serialize join";

    my ( @fset1, @fset2 ) = ();
    my $str2 = $str1;
    my $f2   = create_flow(
        FromJXML => \$str2,
        Split    => {
            Flow1 => create_flow( sub { push @fset1, @_ } ),
            Flow2 => create_flow( sub { push @fset2, @_ } ),
        },
    );
    $f2->run();
    is_deeply \@fset1, \@dset1, "check data set1";
    is_deeply \@fset2, \@dset2, "check data set2";

}

