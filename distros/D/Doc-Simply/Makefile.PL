
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Doc::Simply',
                       'DISTNAME' => 'Doc-Simply',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Robert Krimen <robertkrimen@gmail.com>',
                       'BUILD_REQUIRES' => {
                                             'Test::Most' => '0'
                                           },
                       'ABSTRACT' => 'Generate POD-like documentation from embedded comments in JavaScript, Java, C, C++ source',
                       'EXE_FILES' => [
                                        'bin/doc-simply'
                                      ],
                       'VERSION' => '0.032',
                       'PREREQ_PM' => {
                                        'HTML::Declare' => '0',
                                        'Text::FixEOL' => '0',
                                        'Carp::Clan::Share' => '0',
                                        'Any::Moose' => '0',
                                        'String::Comments::Extract' => '0',
                                        'Template' => '0',
                                        'Getopt::Usaginator' => '0',
                                        'Text::MultiMarkdown' => '0',
                                        'Tree::DAG_Node' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM}; 
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod}; 
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



