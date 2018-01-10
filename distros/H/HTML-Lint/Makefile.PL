use strict;
use warnings;
use ExtUtils::MakeMaker qw( WriteMakefile );
use 5.006001;

if ( not eval { require LWP::Simple; 1; } ) {
    print <<'EOF';

NOTE: It seems that you don't have LWP::Simple installed.
      The weblint program will not be able to retrieve web pages.

EOF
}

my %parms = (
    NAME            => 'HTML::Lint',
    DISTNAME        => 'HTML-Lint',
    VERSION_FROM    => 'lib/HTML/Lint.pm',
    ABSTRACT_FROM   => 'lib/HTML/Lint.pm',
    PMLIBDIRS       => [qw(lib/)],
    AUTHOR          => 'Andy Lester <andy@petdance.com>',
    MIN_PERL_VERSION=> 5.006,
    PREREQ_PM       => {
        'Exporter'              => 0,
        'Test::More'            => 0,
        'Test::Builder'         => 0,
        'Test::Builder::Tester' => 0,

        'File::Find'            => 0,
        'HTML::Entities'        => 0,
        'HTML::Parser'          => '3.47',
        'HTML::Tagset'          => '3.03',
    },
    EXE_FILES   => [qw(bin/weblint)],
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX => 'gz',
    },
    clean => { FILES => 'HTML-Lint-*' },
);

if ( $ExtUtils::MakeMaker::VERSION =~ /^\d[.]\d\d$/ and $ExtUtils::MakeMaker::VERSION > 6.30 ) {
    $parms{LICENSE} = 'artistic_2';
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
    $parms{META_ADD} = {
        resources => {
            homepage   => 'http://search.cpan.org/dist/html-lint',
            bugtracker => 'https://github.com/petdance/html-lint/issues',
            license    => 'http://www.opensource.org/licenses/artistic-license-2.0.php',
            repository => 'https://github.com/petdance/html-lint',
        },
    };
}

WriteMakefile( %parms );

sub MY::postamble { ## no critic ( Subroutines::ProhibitQualifiedSubDeclarations )
    my $postamble = <<'MAKE_FRAG';

.PHONY: tags critic

tags:
	ctags -f tags --recurse --totals \
		--exclude=blib \
		--exclude=.svn \
		--exclude='*~' \
		--languages=Perl --langmap=Perl:+.t \

critic:
	perlcritic -1 -q -profile perlcriticrc $(ack -f --perl)

PROF_ARGS = -Mblib blib/script/weblint index.html

timed: all
	$(PERL) $(PROF_ARGS) >> /dev/null 2>&1

dprof: all
	$(PERL) -d:DProf $(PROF_ARGS) >> /dev/null 2>&1
	dprofpp -R

dproflb: all
	$(PERL) -d:DProfLB $(PROF_ARGS) >> /dev/null 2>&1
	dprofpp -R

fastprof: all
	$(PERL) -d:FastProf $(PROF_ARGS) >> /dev/null 2>&1
	fprofpp

profile: all
	$(PERL) -d:Profile $(PROF_ARGS) >> /dev/null 2>&1
	less prof.out

profiler: all
	$(PERL) -MDevel::Profiler $(PROF_ARGS) >> /dev/null 2>&1
	dprofpp -R

smallprof: all
	$(PERL) -d:SmallProf $(PROF_ARGS) >> /dev/null 2>&1
	sort -k 2nr,2 smallprof.out | less

nytprof: all
	$(PERL) -d:NYTProf $(PROF_ARGS) >> /dev/null 2>&1
	nytprofhtml

MAKE_FRAG

    return $postamble;
}
