#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Fugu must load with core Perl only. A module that wraps a CPAN
# library requires it lazily, so an installation without that library
# still loads the module and fails with a clear message at the call.
#
# The test compiles every module in a subprocess whose @INC holds only
# the core paths plus lib/. That prunes site_perl and vendor_perl, so
# the missing-CPAN environment is reproduced deterministically instead
# of depending on what the build host happens to have installed.

use v5.36;
use Test::More;
use Config;
use FindBin qw($RealBin);
use File::Spec;

my $lib = File::Spec->rel2abs("$RealBin/../../lib");

# A missing directory is a hard failure, not a skip. A skip would hide
# the whole core-Perl guarantee behind a typo in the path.
opendir my $dh, "$lib/Fugu" or die "Cannot read $lib/Fugu: $!";
my @modules = sort grep { s/\.pm$// } readdir $dh;
closedir $dh;

die "No Fugu modules found in $lib/Fugu\n" unless @modules;

# The core paths of this perl, and nothing else. A -I flag only adds
# to @INC and would leave site_perl in place, so the child assigns the
# list instead. PERL5LIB would put the pruned directories back, so the
# child does not get it.
my @core = grep { defined && length } @Config{qw(privlibexp archlibexp)};
my $prune = 'BEGIN { @INC = (' . join( ', ', map { "'$_'" } $lib, @core ) . ') }';

# run($code):
#	Run one line of Perl against the pruned @INC and return what it
#	printed, with standard error folded in.
sub run ($code)
{
	my $pid = open my $out, '-|';
	die "fork: $!" unless defined $pid;

	if ( $pid == 0 ) {
		delete $ENV{PERL5LIB};
		open STDERR, '>&', \*STDOUT or exit 127;
		exec { $^X } $^X, '-f', '-e', "$prune $code" or exit 127;
	}

	my $output = do { local $/; <$out> };
	close $out;

	return $output // '';
}

# The pruned list must really be pruned. Without this check, a test
# host that shipped every CPAN module in its core paths would pass the
# whole file while proving nothing.
{
	my $output = run('require JSON::XS; print qq{loaded\n}');
	unlike( $output, qr/^loaded$/m,
		'the pruned @INC hides a CPAN module' )
	    or diag('JSON::XS is reachable, so this file proves nothing');
}

for my $module (@modules) {
	my $output = run("require Fugu::$module; print qq{ok\n}");
	like( $output, qr/^ok$/m, "Fugu::$module loads with core Perl" )
	    or diag( length($output) ? $output : '(no output)' );
}

done_testing();
