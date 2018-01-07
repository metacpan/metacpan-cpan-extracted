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
## mode_function
##
{
    my $rcloader = Getopt::EX::Loader->new(BASECLASS => "App::example");
    my @argv;

    @argv = qw(-Mmode_function --bye);
    $rcloader->deal_with(\@argv);
    $" = '-';
    is("@argv", "hasta-la-vista", "function");
}

##
## mod_wildcard
##
{
    my $rcloader = Getopt::EX::Loader->new(BASECLASS => "App::example");
    my @argv;

    @argv = qw(-Mmode_wildcard --expm);
    $rcloader->deal_with(\@argv);
    is($argv[0], "lib/Getopt/EX.pm", "wildcard");

    @argv = qw(-Mmode_wildcard --wildcard lib/Getopt/*.pm);
    $rcloader->deal_with(\@argv);
    is($argv[0], "lib/Getopt/EX.pm", "wildcard: \$<shift>");

    @argv = ('-Mmode_wildcard',
	     '--wildcard', 'lib/Getopt/EX/{Module,Loader}.pm');
    $rcloader->deal_with(\@argv);
    is($argv[0], "lib/Getopt/EX/Module.pm", "wildcard: multi");

    @argv = qw(-Mmode_wildcard --wildcard *.never);
    $rcloader->deal_with(\@argv);
    is($argv[0], "*.never", "wildcard: no match");
}

done_testing;
