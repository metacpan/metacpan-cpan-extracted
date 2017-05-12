use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mail::SpamAssassin::Plugin::AttachmentPresent',
    AUTHOR              => 'Merijn van den Kroonenberg <merijn@web2all.nl>',
    VERSION_FROM        => 'lib/Mail/SpamAssassin/Plugin/AttachmentPresent.pm',
    ABSTRACT_FROM       => 'lib/Mail/SpamAssassin/Plugin/AttachmentPresent.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'  => 'perl', ) : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Pod' => 0,
        'Encode' => 0,
        'Encode::MIME::Header' => 0,
        'Archive::Zip' => 0,
        'IO::String' => 0,
        'Mail::SpamAssassin' => 0,
        'Mail::SpamAssassin::Plugin' => 0,
        'Mail::SpamAssassin::Logger' => 0,
        'File::Spec' => 0,
        'base' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mail-SpamAssassin-Plugin-AttachmentPresent-*' },
);
