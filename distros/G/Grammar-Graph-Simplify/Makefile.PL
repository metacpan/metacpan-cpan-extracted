use 5.012000;
use ExtUtils::MakeMaker;

WriteMakefile(
  MIN_PERL_VERSION  => 5.012000,
  NAME              => 'Grammar::Graph::Simplify',
  VERSION_FROM      => 'lib/Grammar/Graph/Simplify.pm',
  PREREQ_PM         => {
    'Test::More'         =>  0,
    'Graph'              =>  0,
    'Grammar::Formal'    =>  0,
    'Grammar::Graph'     =>  0,
    'Modern::Perl'       =>  0,
    'Moose'              =>  0,
    'List::UtilsBy'      =>  0,
    'List::MoreUtils'    =>  0,
    'List::Util'         =>  0,
    'Storable'           =>  0,
    'Graph::SomeUtils'   =>  0,
    'Algorithm::ConstructDFA::XS' => 0,
  },
  ABSTRACT_FROM     => 'lib/Grammar/Graph/Simplify.pm',
  AUTHOR            => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>',
  LICENSE           => 'perl',

  'dist'            => {
    PREOP     => 'chmod 600 Makefile.PL',
    TARFLAGS	=> '--group=none --owner=bjoern --mode=a+rw -cvf',
  },

  META_MERGE        => {
    'meta-spec' => { version => 2 },
    resources => {
       repository => {
         type => 'git',
         url  => 'https://github.com/hoehrmann/Grammar-Graph-Simplify.git',
         web  => 'https://github.com/hoehrmann/Grammar-Graph-Simplify',
      },
    },
  },
);
