#!/usr/bin/perl
#
#
package _Drawings_::Repository0::Artists::Index;

use strict;
use warnings;
use warnings::register;

#<-- BLK ID="DRAWING" -->

use vars qw($VERSION );
$VERSION = '0.01';

###
# Never know when Data::Dumper going to throw in a VARn
#
use vars qw($VAR1 $VAR2 $VAR3 $VAR4 $VAR5 $VAR6 $VAR7 $VAR8);

$white_tape =  # parts are marked with a pn and other data, many times with a white tape
   
     {
       #####
       # Configuration version control
       #
       version => '0.01',
       revision => '0',
       date_loc => '2004/04/04 13:16:18', 
       date_gm => '2004/04/04 17:16:18', 
       time_to_live => '', 
       active_obsolete => '2',
 
       #####
       # Drawing identification data
       #
       repository => '_Drawings_::Repository0::',
       drawing_number => 'Artists::Index',
       type => 'index',
       title => 'About Artists' ,
       description => 'List of Singers, Composers, Song Writers',
       keywords => 'Audio CD,Artists,music,singers,song writers,songs,composers,performers,concerts,performing arts',
       file => __FILE__,
       dod_fscm => 'none-SoftDia',
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
          'browse' => [],
          'home' => [
                      'Music::Index'
                    ],
          'path' => []
        };


#<-- /BLK -->

1

__END__

# end of file

