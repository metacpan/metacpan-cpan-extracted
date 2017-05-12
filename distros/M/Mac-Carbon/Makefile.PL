use Config;
use 5.006;
use ExtUtils::MakeMaker;
require 'fixargs.pl';

if ($bits_are_64) {
	$| = 1;
	print "*** 64-BIT WARNING ***  *** 64-BIT WARNING ***  *** 64-BIT WARNING ***\n",
		"Mac-Carbon does not run under 64-bit perl, and it appears you're running\n",
		"a 64-bit perl.  We can try to compile anyway, in case this is a fat binary;\n",
		"we'll try to leave out the 64-bit compilation.\n\n";

	if ($bits_are_64 && $defarch eq 'x86_64' && $noarch) {
		print "My guess is that you're running a 64-bit, non-fat, perl and that there's no\n",
			"real chance this will work.  ";

		unless (grep { /TRY_ANYWAY=1/ } @ARGV) {
			print "If you want to try anyway, run:\n\n",
				"    perl Makefile.PL TRY_ANYWAY=1\n\nExiting.\n\n";
			exit;
		} else {
			print "But you set TRY_ANYWAY=1 so we'll try anyway.\n\n";
		}
	}

	print "If you want to use these modules, it must be in 32-bit mode.  For more\n",
		"information, see:\n\n",
		"    http://use.perl.org/~pudge/journal/39596\n\n";
}

@ARGV = grep { ! /TRY_ANYWAY=1/ } @ARGV;


my %ARGS= (
	'NAME'                  => 'Mac::Carbon',
	'VERSION_FROM'          => 'Carbon.pm',
	'PM'                    => { 'Carbon.pm' => '$(INST_LIBDIR)/Carbon.pm' },
	'PREREQ_PM'  => {
    		'Test::More'    => 0,
	},
	'clean'      => {
		'FILES'         => 'Mac-Carbon-*'
	},
	'test'       => {
		'TESTS'         => 't/*.t */t/*.t'
	},
	'NO_META'               => 1,
);

for (qw(LDDLFLAGS LDFLAGS CCFLAGS)) {
	$ARGS{$_} = $Config{lc $_};
}
fixargs(\%ARGS);

package MY;
if ($^O eq 'darwin') {
	sub test_via_harness {
	    my($self, $perl, $tests) = @_;
	    return $self->SUPER::test_via_harness("VERSIONER_PERL_PREFER_32_BIT=yes $perl", $tests);
	}

	sub test_via_script {
	    my($self, $perl, $script) = @_;
	    return $self->SUPER::test_via_script("VERSIONER_PERL_PREFER_32_BIT=yes $perl", $script);
	}
}

package main;
WriteMakefile(%ARGS);
