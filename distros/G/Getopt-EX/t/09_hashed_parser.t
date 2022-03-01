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

$ENV{HOME} = $home;
unshift @INC, $app_lib;

##
## GetOptions
##
{
    $0 = "/usr/bin/example";
    use Getopt::EX::Long;
    local @ARGV = qw(-Mexample_test
		     --string Alice
		     --number 42
		     --list foo --list bar
		     --hash animal=dolphin --hash fish=babel
		     --default
		     --set-number 42
		     --set-list dont --set-list panic
		     --set-hash dont=panic
		     --set-str  dontpanic
	);
    my %hash;
    my $parser = Getopt::EX::Long::Parser->new;
    $parser->getoptions(
	\%hash,
	"string=s",
	"number=i",
	"default:42",
	"list=s@",
	"hash=s%",
	);

    is_deeply($hash{string}, "Alice", "String");
    is_deeply($hash{number}, 42, "Number");
    is_deeply($hash{default}, 42, "Default");
    is_deeply($hash{list}, [ qw(foo bar) ], "List");
    is_deeply($hash{hash}, { animal => 'dolphin', fish => 'babel' }, "Hash");

    ##
    ## builtins
    ##
    no warnings 'once';
    is_deeply($App::example::example_test::opt_number, 42,
	      "Builtin Numnber");
    is_deeply(\@App::example::example_test::opt_list, [ qw(dont panic) ],
	      "Builtin List");
    is_deeply(\%App::example::example_test::opt_hash, { qw(dont panic) },
	      "Builtin Hash");
    is_deeply($App::example::example_test::opt_string, q(dontpanic),
	      "Builtin Sub");
}

done_testing;
