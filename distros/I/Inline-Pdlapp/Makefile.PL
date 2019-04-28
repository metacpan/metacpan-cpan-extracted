use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'Inline::Pdlapp',
  VERSION_FROM => 'lib/Inline/Pdlapp.pm',
  PREREQ_PM => {
    'Inline' => 0.68,
    'Inline::C' => 0.62,
    'PDLA::Core' => '2.019104',
    'ExtUtils::MakeMaker' => '7.34',
  },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      homepage => 'http://pdlporters.github.io',
      bugtracker  => {web=>'https://github.com/PDLPorters/pdla-inline-pdlapp/issues'},
      repository  => {
        url => 'git://github.com/PDLPorters/pdla-inline-pdlapp',
        type => 'git',
        web => 'https://github.com/PDLPorters/pdla-inline-pdlapp',
      },
      x_IRC => 'irc://irc.perl.org/#pdl',
    },
    no_index => { directory => ['examples'] },
  },
);

sub MY::postamble {
  <<EOF;
pure_all :: README.md

README.md : \$(VERSION_FROM)
\tpod2markdown \$< >\$\@
EOF
}
