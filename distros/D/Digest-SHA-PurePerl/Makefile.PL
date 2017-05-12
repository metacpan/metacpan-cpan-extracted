require 5.003000;

use strict;
use ExtUtils::MakeMaker;

my $PM = 'lib/Digest/SHA/PurePerl.pm';
my $SHASUM = 'shasum';

	# 'use warnings' if possible, but stay portable

my($use_warnings, @EDITs);
my $warn_1 = 'BEGIN { $^W = 1 }';
my $warn_0 = 'BEGIN { $^W = 0 }';
{
	eval "require warnings; import warnings";
	$use_warnings = $@ ? 0 : 1;

	local(@ARGV) = ($PM, $SHASUM);
	while (<>) {
		if (
		(!$use_warnings && /^(use|no) warnings\b/) ||
		( $use_warnings && /^\Q$warn_1\E # use warnings\b/) ||
		( $use_warnings && /^\Q$warn_0\E # no warnings\b/)) {
			push @EDITs, $ARGV;
			close ARGV;
		}
	}
}

if (@EDITs) {
	local($^I, @ARGV) = ('', @EDITs);
	while (<>) {
		if ($use_warnings) {
			s/^\Q$warn_1\E # (.*)$/$1/;
			s/^\Q$warn_0\E # (.*)$/$1/;
		}
		else {
			s/^(use warnings\b.*)$/$warn_1 # $1/;
			s/^(no warnings\b.*)$/$warn_0 # $1/;
		}
		print;
	}
}

my %attr = (
	'NAME'		=> 'Digest::SHA::PurePerl',
	'VERSION_FROM'	=> $PM,
	'EXE_FILES'	=> [ $SHASUM ],
);

my $MMversion = $ExtUtils::MakeMaker::VERSION || '0.00_00';
$attr{NO_META} = 1 if $MMversion ge '6.10_03';

WriteMakefile(%attr);
