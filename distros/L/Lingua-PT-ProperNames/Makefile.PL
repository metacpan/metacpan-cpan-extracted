use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lingua::PT::ProperNames',
    AUTHOR              => 'Alberto Simoes <ambs@di.uminho.pt>',
    VERSION_FROM        => 'lib/Lingua/PT/ProperNames.pm',
    ABSTRACT_FROM       => 'lib/Lingua/PT/ProperNames.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'IO::String' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lingua-PT-ProperNames-*' },
);


package MY;

sub postamble {
      return <<"EOF";
database: pm_to_blib
\tperl ./data/cpdata.pl
\t\$(NOECHO) \$(TOUCH) \$@

clean_database:
\t\$(NOECHO) \$(RM_F) database

EOF
}

sub top_targets {
    my $class = shift;
    my $makefragment = $class->SUPER::top_targets(@_);
    $makefragment =~ s/^(pure_all ::)/$1 database/m;
    return $makefragment;
}

sub clean {
    my $class = shift;
    my $makefragment = $class->SUPER::clean(@_);
    $makefragment =~ s/^(clean ::)/$1 clean_database/m;
    return $makefragment;
}

