use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # developer release
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
  NAME	          => 'Lingua::EN::MatchNames',
  AUTHOR          => 'Brian Lalonde (brian@webcoder.info)',
  LICENSE         => 'perl',
  VERSION_FROM    => 'MatchNames.pm', 
  ABSTRACT_FROM   => 'MatchNames.pm',
  PREREQ_PM       => 
  {
    'Lingua::EN::NameParse' => 0,
    'Lingua::EN::Nickname'  => 0,
    'String::Approx'        => 0,
    'Text::Metaphone'       => 0,
    'Text::Soundex'         => 0,
  },

  ($mm_ver <= 6.45
    ? ()
    : (META_MERGE => {
      'meta-spec' => { version => 2 },
        resources => {
          repository  => {
            type => 'git',
            web  => 'https://github.com/brianary/Lingua-EN-MatchNames',
            url  => 'https://github.com/brianary/Lingua-EN-MatchNames.git',
          },
        },
      })
  ),

);
