#!perl

package main;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my %parms = (
    NAME                => 'List::Cycle',
    AUTHOR              => 'Andy Lester <andy@petdance.com>',
    VERSION_FROM        => 'Cycle.pm',
    ABSTRACT_FROM       => 'Cycle.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp'       => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'List-Cycle-* cover_db' },
);

if ( $ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/ and $ExtUtils::MakeMaker::VERSION > 6.30 ) {
    $parms{LICENSE} = 'artistic_2';
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
    $parms{META_MERGE} = {
        resources => {
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=List-Cycle',
            repository  => 'git://github.com/petdance/list-cycle.git',
            license     => 'http://www.opensource.org/licenses/artistic-license-2.0.php',
        }
    };
}

WriteMakefile( %parms );

sub MY::postamble {
    my $postamble = <<'MAKE_FRAG';
critic:
	perlcritic -1 -q -profile perlcriticrc Cycle.pm t/*.t
MAKE_FRAG

    return $postamble;
}
