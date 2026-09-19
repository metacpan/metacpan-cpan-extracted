#!perl

# NO PLACEHOLDER TEXT SHIPS, and this file is able to say so.
#
# THE STOCK VERSION OF THIS TEST CANNOT FAIL. Module::Starter writes it with
# every assertion inside `TODO: { local $TODO = "Need to replace the
# boilerplate text" }`, which means a module still full of "The great new
# Game::Go" reports as an EXPECTED failure and the file goes green. The tell is
# in the output of the stock file: "TODO passed: 1-3", an unexpected pass, which
# is what a test says when the thing it was written to find is not there and it
# has no way to notice.
#
# So there is no TODO block here. It also checks EVERY module rather than the
# one Module::Starter names, because the placeholder that survives is always in
# the file nobody thought to list.

use 5.010;
use strict;
use warnings;
use Test::More;
use File::Find ();

my @MODULES;
File::Find::find(sub {
	push @MODULES, $File::Find::name if -f && /\.pm\z/;
}, 'lib');
@MODULES = sort @MODULES;

my @SCRIPTS = sort grep { -f } glob 'bin/*';

plan tests => scalar(@MODULES) + scalar(@SCRIPTS) + 3;

sub not_in_file_ok {
	my ($filename, %regex) = @_;
	open my $fh, '<', $filename or do {
		fail("$filename: $!");
		return;
	};

	my %violated;
	while (my $line = <$fh>) {
		while (my ($desc, $regex) = each %regex) {
			push @{ $violated{$desc} ||= [] }, $. if $line =~ $regex;
		}
	}
	close $fh;

	if (%violated) {
		fail("$filename contains boilerplate text");
		diag "$_ appears on lines @{$violated{$_}}" for sort keys %violated;
	}
	else {
		pass("$filename contains no boilerplate text");
	}
}

# The phrases Module::Starter leaves behind, plus the two this distribution
# could plausibly leave: an unedited ABSTRACT and a stub POD section.
my %MODULE_BOILERPLATE = (
	'the great new $MODULENAME' => qr/ - The great new /,
	'boilerplate description'   => qr/Quick summary of what the module/,
	'stub function definition'  => qr/\bfunction[12]\b/,
	'stub subroutine name'      => qr/^=head2 (?:function[12]|method[12])\b/,
	'unedited AUTHOR line'      => qr/\byour name here\b/i,
	'perl module boilerplate'   => qr/Perl extension for blah blah blah/,
);

not_in_file_ok($_ => %MODULE_BOILERPLATE) for @MODULES;

# The programs get the same treatment: a placeholder in a --help message is
# read by a person on the day they install this.
not_in_file_ok($_ => %MODULE_BOILERPLATE) for @SCRIPTS;

not_in_file_ok(README =>
	'The README is used...'      => qr/The README is used/,
	"'version information here'" => qr/to provide version information/,
	'stock installation stanza'  => qr/A README file is required/,
);

not_in_file_ok(Changes =>
	'placeholder date/time' => qr{Date/time},
	'unreleased placeholder' => qr/^\s*0\.01\s+(?:TBD|XXX)/,
);

not_in_file_ok('Makefile.PL' =>
	'unedited author'  => qr/\bA\.\s*U\.\s*Thor\b/,
	'unedited address' => qr/\ba\.u\.thor\@a\.galaxy\.far\.far\.away\b/,
);
