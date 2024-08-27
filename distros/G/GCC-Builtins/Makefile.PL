use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker 7.12;

my %WriteMakefileArgs = (
	NAME             => 'GCC::Builtins',
	AUTHOR           => q{Andreas Hadjiprocopis <bliako ta cpan.org / andreashad2 ta gmail.com>},
	VERSION_FROM     => 'lib/GCC/Builtins.pm',
	ABSTRACT_FROM    => 'lib/GCC/Builtins.pm',
	LICENSE          => 'artistic_2',
	MIN_PERL_VERSION => '5.006',
	CONFIGURE_REQUIRES => {
	    'ExtUtils::MakeMaker' => '7.12',
	},
	TEST_REQUIRES => {
	    'Test::More' => '0',
	    'Benchmark' => '0',
	},
	PREREQ_PM => {
	    'ExtUtils::MakeMaker' => '7.12',
	    'Exporter' => '0',
	    'DynaLoader' => '0',
	},
	CCFLAGS  => '-Wall -std=c99',
	OPTIMIZE => '-O3',
	XSMULTI  => 1,
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'GCC-Builtins-*' },
	postamble => {
	    BENCHMARK_FILES => 'xt/benchmarks/*.b',
	},
	META_ADD => {
		# PAUSE do not index these files
		no_index => {
			# sbin/ contains a perl script to create Buildins.pm/.xs
			# and it contains pod, package name, etc.
			# we do not want that indexed by PAUSE
			# see https://www.effectiveperlprogramming.com/2012/04/hide-namespaces-from-pause/
			directory => [ qw/sbin/ ],
			#file => [...]
		}
	},
	# Thanks to marto @ Perlmonks.org
	# see https://perlmonks.org/?displaytype=displaycode;node_id=359256;part=1;abspart=1
	META_MERGE => {
          'meta-spec' => { version => 2 },
	  requires    => { perl => '5.0.8' },
          resources   => {
            license    => 'artistic_2',
	    homepage   => 'https://metacpan.org/module/GCC::Builtins',
            repository => {
                url  => 'https://github.com/hadjiprocopis/perl-gcc-builtins',
                web  => 'https://github.com/hadjiprocopis/perl-gcc-builtins',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/hadjiprocopis/perl-gcc-builtins/issues',
            }
	  },
	},
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
    my (undef,%h) = @_;
    # require Data::Dumper; print STDERR Data::Dumper->Dump([\%h], [qw(mm_args{postamble})]);
    return "BENCHMARK_FILES=$h{BENCHMARK_FILES}\n"
	. <<'POSTAMBLE';
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

benchmarks :: $(BENCHMARK_FILES)
	prove --blib $(INST_LIB) --blib $(INST_ARCHLIB) --verbose $^

POSTAMBLE
}

