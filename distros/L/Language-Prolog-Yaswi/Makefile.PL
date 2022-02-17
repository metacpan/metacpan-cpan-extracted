use 5.006;
use utf8;
use ExtUtils::MakeMaker;

my %hash;

my $github_slug = 'salva/p5-Language-Prolog-Yaswi';
$hash{META_MERGE} = {
  "meta-spec" => { version => 2 },
  resources => {
    bugtracker  => { web => "https://github.com/$github_slug/issues" },
    repository  => {
       url => "git://github.com/$github_slug.git",
       type => 'git',
       web => "https://github.com/$github_slug",
    },
  },
  prereqs => {
    develop => {
      requires => {
        'Test::Pod'      => '1.00',
      },
    },
  },
};

WriteMakefile(
    'NAME'              => 'Language::Prolog::Yaswi',
    'VERSION_FROM'      => 'Yaswi.pm',
    CONFIGURE_REQUIRES  => {
        'Alien::SWIProlog'        => '0.002',
    },
    'PREREQ_PM'         => {
        'Language::Prolog::Types' => '0.09',
        'Language::Prolog::Sugar' => '0.03',
        'Alien::SWIProlog'        => '0.002',
    },
    TEST_REQUIRES => {
        'Test::More'              => '0',
    },
    'OPTIMIZE'          => '-g -O0',
    'ABSTRACT_FROM'     => 'Yaswi.pm',
    'AUTHOR'            => 'Salvador Fandiño <sfandino@yahoo.com>',
    %hash,
);
