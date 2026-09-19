#!perl
use 5.010;
use strict;
use warnings;
use File::Find ();
use Test::More;

# NO TODO BLOCK, AND THAT IS THE WHOLE POINT OF THIS REWRITE.
#
# The stock Module::Starter version of this file wraps every check in a TODO
# block, so placeholder text reports as an expected failure and text that has
# been replaced reports as "TODO passed". Neither outcome is a failure, so the
# file cannot tell anybody anything. A check that cannot fail is not a check.

unless ($ENV{RELEASE_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
}

my @BOILERPLATE = (
	'boilerplate description'      => qr/boilerplate description/i,
	'the Module::Starter summary'  => qr/Quick summary of what the module/i,
	'blah blah blah'               => qr/blah blah blah/i,
	'a stub date'                  => qr{Date/time},
	'an unwritten TODO'            => qr/TODO:? *(?:write|fill|replace|add)/i,
	'a FIXME'                      => qr/\bFIXME\b/,
	'an XXX'                       => qr/\bXXX\b/,
	'your name here'               => qr/your name here/i,
	'an example address'           => qr/EXAMPLE\.COM/i,
	'foo\@bar'                     => qr/foo\@bar/i,
	'an unsuspecting world'        => qr/unsuspecting world/i,
	'a stub synopsis'              => qr/Perhaps a little code snippet/i,
);

my @files = qw(README Changes Makefile.PL MANIFEST bin/oware);

File::Find::find({
	no_chdir => 1,
	wanted   => sub { push @files, $File::Find::name if /\.pm\z/ },
}, 'lib');

plan tests => scalar @files;

for my $file (@files) {
	subtest $file => sub {
		open my $fh, '<', $file or do {
			fail("cannot read $file");
			return;
		};
		my $text = do { local $/; <$fh> };
		close $fh;

		my @found;
		for (my $i = 0; $i < @BOILERPLATE; $i += 2) {
			my ($name, $pattern) = @BOILERPLATE[ $i, $i + 1 ];
			push @found, $name if $text =~ $pattern;
		}

		is_deeply(\@found, [], 'no placeholder text')
			or diag "$file still contains: " . join ', ', @found;
	};
}
