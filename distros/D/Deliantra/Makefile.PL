use ExtUtils::MakeMaker;

use Config;

my $mm = MM->new({
    dist         => {
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
    },
    PREREQ_PM   => {
       common::sense => 0,
       AnyEvent      => 4,
       JSON::XS      => 2.01,
       Compress::LZF => 3.11,
    },
    NAME         => "Deliantra",
    VERSION_FROM => "Deliantra.pm",
    EXE_FILES    => [qw(bin/cfarch-normalize bin/cfmap-normalize bin/cfarch-normalize bin/cfmap-plushify
                        bin/cfmap-cavehify bin/cfmap-tagify bin/cfxmlrender bin/cf-slotutil)],
});

$mm->flush;

