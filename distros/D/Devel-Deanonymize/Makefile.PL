use v5.20.0;

use strict;
use warnings;
use ExtUtils::MakeMaker;
use FindBin;

sub get_version() {
    open my $fh, 'VERSION';
    chomp(my $v = <$fh>);
    close $fh;
    return $v;
}

my $version = get_version();

WriteMakefile(
    NAME           => 'Devel::Deanonymize',
    VERSION        => $version,
    ABSTRACT       => 'A tool do make anonymous sub visible to Devel::Cover',
    AUTHOR         => 'Tobias Bossert <tobib at cpan.org>',
    LICENSE        => 'mit',
    PREREQ_PM      => {},
    BUILD_REQUIRES => {},
    MAKE           => 'gmake',
    EXE_FILES      => [],
    META_MERGE     => {
        requires  => { perl => '5.020000' },
        resources => {
            license    => 'https://opensource.org/licenses/mit',
            repository => 'https://github.com/oposs/devel-deanonymize',
            bugtracker => 'https://github.com/oposs/devel-deanonymize/issues'
        },
        no_index  => { directory => [ 't' ] }
    },
    test           => { TESTS => 't/*.t' }
);

sub MY::postamble {
    my $self = shift;
    return <<"EOF";

VERSION_FILES := \$(shell grep -Rl 'our \$\$VERSION = ' .)
\$(VERSION_FILES): VERSION
	\$(PERL) -i -p -e 's/\$VERSION\\s*=\\s*"[\\d|\.]*[A-z]*"/\$VERSION = "\$(VERSION)"/;' \$\@

EOF
}
