use strict;
use warnings;

use 5.010;
use ExtUtils::MakeMaker;

my $IS_WIN32 = $^O eq 'MSWin32';

my $configure_requires =
	{
		'ExtUtils::MakeMaker' => '7.12', 
	};

my $test_requires =
	{
		'Test::More' => 0, # initial dev used: 1.001003
		'Test::Differences' => 0, # initial dev used: 0.62 
		'Test::Exception' => 0, # initial dev used: 0.32
	};
	
my $eumm_understands_meta_merge = $ExtUtils::MakeMaker::VERSION ge '6.46';
my $eumm_understands_conf_and_test_requires_properly = $ExtUtils::MakeMaker::VERSION ge '7.12';

WriteMakefile(
	NAME             => 'Grep::Query',
	AUTHOR           => q{Kenneth Olwing <knth@cpan.org>},
	VERSION_FROM     => 'lib/Grep/Query.pm',
	ABSTRACT_FROM    => 'lib/Grep/Query.pm',
	LICENSE          => 'artistic_2',
	EXE_FILES        => [ 'script/qgrep' ],
	# initial dev was made using: ActiveState: This is perl 5, version 20, subversion 1 (v5.20.1) built for MSWin32-x86-multi-thread-64int
	# we use named capture groups...
	#
	MIN_PERL_VERSION => 5.010,
	$eumm_understands_meta_merge
		? (
			META_MERGE =>
				{
					'meta-spec' =>
						{
							version => 2,
						},
					resources =>
						{
							repository =>
								{
									type => 'git',
									url => 'https://github.com/kenneth-olwing/Grep-Query.git',
									web => 'https://github.com/kenneth-olwing/Grep-Query'
								}
						}
				}
			)
		: (),
	$eumm_understands_conf_and_test_requires_properly
		? ( CONFIGURE_REQUIRES => $configure_requires, TEST_REQUIRES => $test_requires )
		: (),
	PREREQ_PM =>
		{
			$eumm_understands_conf_and_test_requires_properly
				? ()
				: ( %$configure_requires, %$test_requires ),
			'Parse::RecDescent'	=> 0, # initial dev used: 1.967013
			'IO::Scalar' => 0, # initial dev used: 2.111
		},
	dist  =>
		{
			$IS_WIN32 ? (TARFLAGS => '--mode=755 -cvf') : (),
			COMPRESS => 'gzip -9f',
			SUFFIX => 'gz',
			DIST_DEFAULT => 'test xtest tardist'
		},
	clean => { FILES => 'Grep-Query-* *.tmp' },
	test => { RECURSIVE_TEST_FILES => 1 },
);

package MY;

sub postamble
{
	return <<'MAKE_FRAG';

# make test: runs all 't' tests (pre-provided by EUMM)
# make test_v: runs all 't' tests verbose
#
.PHONY : test_v

test_v : dynamic pure_all
	$(NOECHO) prove -lvr t

# make xtest: runs all 'xt' tests
# make xtest_v: runs all 'xt' tests verbose
#
.PHONY : xtest xtest_v

xtest : dynamic pure_all
	$(NOECHO) prove -lr xt

xtest_v : dynamic pure_all
	$(NOECHO) prove -lvr xt

# make authortest: runs all 'xt/author' tests
# make authortest_v: runs all 'xt/author' tests verbose
#
.PHONY : authortest authortest_v

authortest : dynamic pure_all
	$(NOECHO) prove -lr xt/author

authortest_v : dynamic pure_all
	$(NOECHO) prove -lvr xt/author

# make alltest: runs all tests
# make alltest_v: runs all tests verbose
#
.PHONY : alltest alltest_v

alltest : test xtest
	$(NOECHO) $(NOOP)

alltest_v : test_v xtest_v
	$(NOECHO) $(NOOP)

MAKE_FRAG
}

