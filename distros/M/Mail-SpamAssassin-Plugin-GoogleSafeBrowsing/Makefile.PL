use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mail::SpamAssassin::Plugin::GoogleSafeBrowsing',
    AUTHOR              => 'Dan Born <danborn@cpan.org>',
    VERSION_FROM        => 'lib/Mail/SpamAssassin/Plugin/GoogleSafeBrowsing.pm',
    ABSTRACT_FROM       => 'lib/Mail/SpamAssassin/Plugin/GoogleSafeBrowsing.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Pod' => 0,
        'Net::Google::SafeBrowsing::Blocklist' => 0,
        'Net::Google::SafeBrowsing::UpdateRequest' => 0,
        'Mail::SpamAssassin' => 0,
        'Mail::SpamAssassin::Plugin' => 0,
        'Mail::SpamAssassin::Logger' => 0,
        'URI' => 0,
        'File::Spec' => 0,
        'base' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mail-SpamAssassin-Plugin-GoogleSafeBrowsing-*' },
);
