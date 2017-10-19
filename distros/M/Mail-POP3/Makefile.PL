use ExtUtils::MakeMaker;

# must make sure mpopd.conf gets backed up by install!
# must make sure mpopd_trusted and mpopd-allow_deny get preserved by install!

WriteMakefile(
  NAME => 'Mail::POP3',
  VERSION_FROM => 'lib/Mail/POP3.pm',
  PREREQ_PM => {
    'HTTP::Cookies' => 0,
    'HTML::Form' => 0,
    'Email::MIME' => 0,
    'HTML::FormatText' => 0,
  },
  EXE_FILES => [map "scripts/$_", qw(
    testp3 installscript mpopd mpopdctl mpopdstats update-conf
  )],
  PL_FILES => {map { ("scripts/$_.PL" => "scripts/$_") } qw(
    mpopd mpopdctl mpopdstats update-conf
  )},
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      repository => {
        type => 'git',
        url => 'git@github.com:mohawk2/Mail-POP3.git',
        web => 'https://github.com/mohawk2/Mail-POP3',
      },
      bugtracker  => {
        web => 'https://github.com/mohawk2/Mail-POP3/issues',
      },
      license => [ 'http://dev.perl.org/licenses/' ],
    },
    prereqs => {
      develop => {
        requires => {
          'Test::CheckManifest' => '0.9',
          'Test::Pod::Coverage' => '1.08',
          'Test::Pod' => '1.22',
          'Pod::Markdown' => 0,
        },
      },
    },
  },
);

sub MY::postamble {
  <<EOF;
pure_all :: README.md

README.md : lib/Mail/POP3.pm
\tpod2markdown \$< >\$\@
EOF
}
