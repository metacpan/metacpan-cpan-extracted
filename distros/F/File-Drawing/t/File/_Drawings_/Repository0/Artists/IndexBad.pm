#!/usr/bin/perl
#
#
package _Drawings_::Repository1::Artists::Index;

use strict;
use warnings;
use warnings::register;

#<-- BLK ID="DRAWING" -->

use vars qw($VERSION  $contents $white_tape);
$VERSION = '0.05';

###
# Never know when Data::Dumper going to throw in a VARn
#
use vars qw($VAR1 $VAR2 $VAR3 $VAR4 $VAR5 $VAR6 $VAR7 $VAR8);

$white_tape =  # parts are marked with a pn and other data, many times with a white tape
   
     {
       #####
       # Configuration version control
       #
       version => '0.05',
       revision => '4',
       date_loc => '2004/04/04 18:59:03', 
       date_gm => '2004/04/04 22:59:03', 
       time_to_live => '', 
       active_obsolete => '2',
 
       #####
       # Drawing identification data
       #
       repository => '_Drawings_::Repository1::',
       drawing_number => 'Artists::Index',
       type => 'index',
       title => 'About Artists' ,
       description => 'List of Singers, Composers, Song Writers',
       keywords => 'Audio CD,Artists,music,singers,song writers,songs,composers,performers,concerts,performing arts',
       file => __FILE__,
       dod_fscm => 'none',
       dod_title => 'Audio Media Index, Artists',
       dod_drawing_number => '04040462178',

       ######
       # Drawing classification, authorization, and
       # revision history
       #
       classification => 'Public Domain',
       revision_block => {},
       authorization_block => {},

       ######
       # Detail drawing properties. These usually contain
       # information for hard copy or soft rendering of the
       # drawing such as HTML page.
       #
       properties => {},

     };

$contents =
   {
          'browse' => [
                        'Artists_M::Index',
                        'Artists_B::Index',
                        'Artists_E::Index       #****** TEST ERROR ****  missing ' and ,   *******
                        'Artists_F::Index'
                      ],
          'home' => [
                      'Music::Index'
                    ],
          'path' => []
        };

#<-- /BLK -->

1

__END__

# end of file

