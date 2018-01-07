use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use Data::Dumper;

my $lib = File::Spec->rel2abs('lib');
my $t = File::Spec->rel2abs('t');
my $home = "$t/home";
my $app_lib = "$home/lib";

use Getopt::EX::Loader;

unshift @INC, $app_lib;

##
## deal_with
##
{
    my $rcloader = new Getopt::EX::Loader
	BASECLASS => "App::example";
    my @argv = qw(-Mexample_test --drink-me arg1);
    $rcloader->deal_with(\@argv);
    is($argv[0], "--default", "deal_with");
    is($argv[1], "poison", "deal_with");
}

##
## BASECLASS
##
for my $param (
    [ "single",             'App::example' ],
    [ "array",              [ qw(App::foo App::bar App::example) ] ],
    [ "array w/empty base", [ '', 'App::example' ] ],
    )
{
    delete $INC{"App/example/example_test"};

    my($comment, $baseclass) = @$param;
    my $rcloader = new Getopt::EX::Loader
	BASECLASS => $baseclass;
    my $mod = $rcloader->load_module('example_test');
    is ($mod->{Module}, "App::example::example_test", $comment);
}

done_testing;
