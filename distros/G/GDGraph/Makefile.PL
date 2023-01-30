# This -*- perl -*- script makes the Makefile
# $Id: Makefile.PL,v 1.1 2005/12/14 04:21:45 ben Exp $
 
#--- Distribution section ---
 
use ExtUtils::MakeMaker 6.76;
use Config;
 
#use ExtUtils::Manifest;
#ExtUtils::Manifest::skipcheck();
 
my @clean = qw(*.old *.save tags);
push @clean, map { "*/$_" } @clean;

WriteMakefile(
        'VERSION_FROM'  => 'Graph.pm',  #finds $VERSION
        'DISTNAME'      => 'GDGraph',
        'NAME'          => 'GD::Graph',

        ($] >= 5.005 ?
            ('ABSTRACT'	    => 'Produces charts with GD',
             'AUTHOR'       => [
                 'Martien Verbruggen <mgjv@tradingpost.com.au>',
                 'Benjamin Warfield <bwarfield@cpan.org>',
                 'Ruslan Zakirov <Ruslan.Zakirov@gmail.com>',
                 'Best Practical Solutions <modules@bestpractical.com>',
            ]
            ):()
        ),

        BUILD_REQUIRES   => {
            'ExtUtils::MakeMaker' => '6.76',
        },
        CONFIGURE_REQUIRES   => {
            'ExtUtils::MakeMaker' => '6.76',
        },
        TEST_REQUIRES => {
            'Capture::Tiny'       => '0.30',
            'Test::Exception'     => '0.40',
            'FindBin'             => '0',
            'Test::More'          => '0.88',
        },
        test => {
            RECURSIVE_TEST_FILES => 1,
        },

        'PREREQ_PM'     => { 
            'GD'	    => '1.18', 
            'GD::Text'      => '0.80',
        },
 
        'dist'          => {
            'COMPRESS'      => 'gzip -9f',
            'SUFFIX'        => 'gz', 
        },

        LICENSE         => 'perl',

        META_MERGE      => {
            'meta-spec' => { version => 2 },

            resources => {
                bugtracker => {
                    web => 'http://rt.cpan.org/Public/Dist/Display.html?Name=GDGraph',
                    mailto => 'bug-GDGraph@rt.cpan.org',
                },
                repository => {
                    type => 'git',
                    url  => 'git://github.com/bestpractical/gdgraph.git',
                    web  => 'https://github.com/bestpractical/gdgraph',
                },
            },

        },

        'clean'         => { 'FILES' => join(" ", @clean), },
);

sub MY::postamble 
{
qq(
samples: all
	\@(cd samples && make PERL=$Config{'perlpath'})
	\@echo Samples have been created in samples directory

tags:
	ptags lib/GD/*.pm lib/GD/Graph/*.pm
)
}

sub MY::libscan
{
    my ($self, $path) = @_;
    return if
	$path =~ m:(^|/)\..+\.swp$:	    or
	$path =~ m:(^|/)\.#.+\d$:	    or
	$path =~ m:\b(RCS|CVS|SCCS)\b:	    ;
    return $path;
}

print <<END;

The automatic tests for GDGraph are not really a solid workout of the
library. The best way to test the package is to run the examples
before installing it.  You can run the examples in the samples
directory with `make samples` or by going into that directory, and
just running `make`.
If that fails, please read samples/Makefile.

UPDATE 1: Running the examples is part of the test procedure now. You
are still encouraged to run check them out to learn from them and
to see the ouput images.

UPDATE 2 (2023-0-13): The samples fail if libgd is installed without
image support enabled, which is the default starting with version 2.3.3.
The samples should be automatically skipped if this is detected. To
run the tests from samples, install libgd with image support enabled.
END
