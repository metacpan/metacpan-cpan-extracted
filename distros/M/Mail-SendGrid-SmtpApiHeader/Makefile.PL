use strict;
use warnings;

use ExtUtils::MakeMaker;

sub main {
    my $site = 'https://github.com/potyl/perl-Mail-SendGrid-SmtpApiHeader';

    WriteMakefile(
        AUTHOR       => 'Emmanuel Rodriguez <potyl@cpan.org>',
        NAME         => 'Mail::SendGrid::SmtpApiHeader',
        VERSION_FROM => 'lib/Mail/SendGrid/SmtpApiHeader.pm',
        PREREQ_PM => {
            'JSON'   => 0,
        },
        LICENSE => 'perl',

        META_MERGE => {
            resources => {
                homepage   => $site,
                bugtracker => "$site/issues",
                repository => $site,
            },
        },
    );

    return 0;
}


exit main() unless caller;
