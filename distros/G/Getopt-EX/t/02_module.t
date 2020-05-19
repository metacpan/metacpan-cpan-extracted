use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

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
    local %INC = %INC;
    my $rcloader = new Getopt::EX::Loader
	BASECLASS => "App::example";
    my @argv = qw(-Mexample_test --drink-me --shift-here howdy --deprecated --ignore-me --remove-next remove-me --double-next double-me --exch 2nd 1st);
    $rcloader->deal_with(\@argv);
    is_deeply(\@argv, [ qw(--default poison --shift-howdy double-me double-me 1st 2nd) ], "deal_with");
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
    local %INC = %INC;
    my($comment, $baseclass) = @$param;
    my $rcloader = new Getopt::EX::Loader
	BASECLASS => $baseclass;
    my $mod = $rcloader->load_module('example_test');
    is($mod->{Module}, "App::example::example_test", $comment);
}

done_testing();
