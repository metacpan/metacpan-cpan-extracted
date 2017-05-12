use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # developer release
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
  NAME            => 'Lingua::EN::Nickname',
  AUTHOR          => 'Brian Lalonde (brian@webcoder.info)',
  LICENSE         => 'perl',
  VERSION_FROM    => 'Nickname.pm', 
  ABSTRACT_FROM   => 'Nickname.pm',

  ($mm_ver <= 6.45
    ? ()
    : (META_MERGE => {
      'meta-spec' => { version => 2 },
        resources => {
          repository  => {
            type => 'git',
            web  => 'https://github.com/brianary/Lingua-EN-Nickname',
            url  => 'https://github.com/brianary/Lingua-EN-Nickname.git',
          },
        },
      })
  ),

);
