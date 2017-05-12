use strict;
use warnings;
use Test::More 'no_plan';
use Dependencies::Searcher;
use IO::File;
use Path::Class;

my $searcher = Dependencies::Searcher->new();

# Choose these one because it will NEVER be included in core (or so I
# think...) (but modules are real, you can check on cpan !).
my @non_core_modules = (
    "Lingua::Romana::Perligata",
    "Acme::Smirch",
    "Acme::Bleach",
    "Acme::Pony",
    "Bone::Easy",
    "Tie::Hash::Cannabinol"
);

my @bug = (
    "This::Is::Crap",
    "And::This::Is::Too",
    "Because::We::Love::Tests",
    "Even::When::It:Is::Stupid",
);

my @bugged_non_core_modules = (@non_core_modules, @bug);

$searcher->dissociate(@non_core_modules);
$searcher->generate_report();

my $cpanfile = file('cpanfile'); # Should check possible errors
ok($cpanfile, "cpanfile exists");

if (not defined $cpanfile) {
    die "Can't open cpanfile";
} else {
    my @lines = $cpanfile->slurp;
    ok(@lines ne 0, "cpanfile is not empty");

    # For some reason, the array comparison through the 2 arrays in
    # scalar context don't work on some cpantesters reports.
    # That's maybe because the ok(xx, ,xx , xx) is a list context ???
    # http://www.perlmonks.org/?node_id=296455

    # Or more probably, this is because one of the distribution's
    # non-core module has been inserted into corelist ?
    # See issue #39

    # This test is totaly stupid (AKA this is a bug) when using real
    # modules (for example those used by this distribution) because the core
    # modules will be different on different machines. For example,
    # this module has been developped on a v5.14.2 Perl, so the
    # Module::Corelist shipped with Perl far from the one used (2.99,
    # with killer is_core() function). However, I've seen on on the
    # Cpantesters reports that recent Perl don't pass this test
    # because of the mentionned problem.

    my $lines_number   = @lines;
    my $modules_number = @non_core_modules;
    my $bugged_modules_number = @bugged_non_core_modules;

    cmp_ok($modules_number, '!=', $bugged_modules_number,
       "The 2 arrays should not contain same number of elements");

    cmp_ok(
	$modules_number,
	'==',
	$lines_number,
	'modules number is the same than cpanfile lines'
    );

    cmp_ok(
	$bugged_modules_number,
	'!=', $lines_number,
	'modules =! cpanfile lines'
    );

    # This test check that each lines respects the cpanfile syntax
    foreach my $line (@lines) {

	# If line contains a version number
	if ( $line =~ m/(\*|\d+(\.\d+){0,2}(\.\*)?)/ ) {
	    ok($line =~ m{
			     requires
			     \s
			     '.*?' # Module name
			     ,
			     \s
			     '
			     (\*|\d+(\.\d+) # Version number
				 {0,2}       # http://stackoverflow.com/questions/82064/
				 (\.\*)?)    #
			     '
			     ;
		     }x
		     ,
	       "Lines should look like the cpanfile syntax with version number");
	} else {
	    ok($line =~ m{
			     requires
			     \s
			     '.*?' # Module name
			     ;
		     }x
		     ,
	       "Lines should look like the cpanfile syntax with version number");
	}
    }
}

# More stuff to test

# only one space between require and name, etc
# same number of lines in cpanfile than in final modules array
# cpanfile contains a known number of lines (number of modules)

ok 1;

