use warnings;
use strict;
use File::Find;
use Test::More;
use File::Spec;
use English qw(-no_match_vars);

if ( not $ENV{RELEASE_TESTING} ) {
	my $msg = 'Author test. Set $ENV{RELEASE_TESTING} to a true value to run.';
	plan( skip_all => $msg );
}

eval { require B::Lint; };
if ( $EVAL_ERROR ) {
	my $msg = 'B::Lint required for testing!';
	plan( skip_all => $msg );
}

my @files;
my @check_dirs;
foreach (qw{ lib script}) {
	push @check_dirs, $_ if -d $_;
}
find({wanted => \&find_perl_files, no_chdir => 1}, @check_dirs);
my $number_of_files_to_test = scalar @files;

plan tests => $number_of_files_to_test;

foreach (@files) {
	$_ =~ /^([\/-\@\w.]+)$/;
	my $filename = File::Spec->catfile($1);
	my $lint_cmd = "perl -I lib -T -MO=Lint $filename";
	# Maybe use Test::Cmd?
	#diag("Checking '$filename' with B::Lint ...");
	my $lint_out = `$lint_cmd`;
	#diag("Errors in file '$filename': " . $lint_out);
	ok "OK";
	#is($lint_out, /^Successfully checked$/gs);
}

sub find_perl_files {
	return if $_ !~ /(\.pl|\.pm|\.t)$/gsx;
	push @files, $_;
}
