
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Google::AJAX::Library',
                       'DISTNAME' => 'Google-AJAX-Library',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Robert Krimen <robertkrimen@gmail.com>',
                       'BUILD_REQUIRES' => {
                                             'Test::Most' => '0',
                                             'File::Temp' => '0'
                                           },
                       'ABSTRACT' => 'Access the Google AJAX Libaries API in Perl',
                       'EXE_FILES' => [],
                       'VERSION' => '0.022',
                       'PREREQ_PM' => {
                                        'HTML::Declare' => '0',
                                        'URI' => '0',
                                        'LWP::UserAgent' => '0',
                                        'Carp::Clan::Share' => '0',
                                        'Path::Class' => '0',
                                        'Moose' => '0'
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



