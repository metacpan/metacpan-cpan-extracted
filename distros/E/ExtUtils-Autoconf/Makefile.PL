use strict;
use warnings;
use inc::Module::Install;

name     ( 'ExtUtils-Autoconf'        );
all_from ( 'lib/ExtUtils/Autoconf.pm' );
license  ( 'perl'                     );

requires ( 'Cwd'                      );
requires ( 'Carp'                     );
requires ( 'Config'                   );
requires ( 'File::Spec'               );
requires ( 'File::Path'               );
requires ( 'Test::More'               );
requires ( 'File::Which'              );
requires ( 'perl' => '5.006'          );

build_requires( 'Test::Exception' );

include( 'Test::Exception' );
include( 'Sub::Uplevel'    );

auto_install();
WriteAll();
