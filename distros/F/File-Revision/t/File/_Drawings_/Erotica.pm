#!/usr/bin/perl
#
#
package _Drawings_::Erotica;

use strict;
use warnings;
use warnings::register;

#<-- BLK ID="DRAWING" -->

###
# Changing the data in this block may prohibit it from being automatically
# processed by File::Drawing and other modules. See File::Drawing POD before
# making any changes.
#

use vars qw($VERSION);
$VERSION = '0.02';

###
# Never know when Data::Dumper going to throw in a VARn
#
use vars qw($VAR1 $VAR2 $VAR3 $VAR4 $VAR5 $VAR6 $VAR7 $VAR8);

use vars qw($contents $white_tape);

$white_tape =  # parts are marked with a pn and other data, many times with a white tape

     {

       #####
       # Configuration revision version control
       #
       version => '0.01',
       revision => '0',
       date_loc => '2004/04/05 13:34:13', 
       date_gm => '2004/04/05 17:34:13', 
       time_to_live => '', 
       active_obsolete => '',

       #####
       # Drawing identification data
       #
       repository => '',
       drawing_number => '_Drawings_::Erotica',
       type => 'source_control',
       title => 'Erotica' ,
       description => 'Madonna\'s Erotica Audio CD - narcissistic, dark, brooding, hint of S&M',
       keywords => 'cd single,madonna,music,pop music,madonna,adult contemporary singles,erotica,audio cd,pop,adult,contemporary,erotica,narcissistic,dark,brooding,S&M',
       file => __FILE__,

       ######
       # Drawing classification, authorization, and
       # revision history
       #
       classification => 'Top Secret',
       revision_history => {},
       authorization => {},

       ######
       # Detail drawing properties. These usually contain
       # information for hard copy or soft rendering of the
       # drawing such as HTML page.
       #
       properties => {
           dod_fscm => 'none-SoftDia',
           dod_title => 'Madonna, Erotica',
           dod_drawing_number => '04040364301',
       },

     };

$contents =
   {
          'amazon' => {
                        'part_number' => 'B000002M32'
                      },
          'in_house' => {
                          'UPC' => {
                                     'part_number' => '093624058526'
                                   },
                          'artists' => [
                                         'Madonna'
                                       ],
                          'discs' => [
                                       [
                                         'Erotica (Album Edit)',
                                         'Erotica (Kenlou B-Boy Mix)',
                                         'Erotica (WO 12 Inch)',
                                         'Erotica (Underground Club Mix)',
                                         'Erotica (Masters At Work Dub)',
                                         'Erotica (Jeep Beats)',
                                         'Erotica (William Orbit 12")'
                                       ]
                                     ],
                          'features' => [
                                          'CD-single'
                                        ],
                          'home' => [
                                      'Artists_M::Madonna::Index,music',
                                      'Pop_Music::Artists_M::Madonna',
                                      'Pop_Music::Adult_Contemporary_Singles'
                                    ],
                          'image_url' => 'images/erotica.jpg',
                          'manufacturer' => 'Warner Brothers',
                          'num_media' => 1,
                          'part_number' => 'Artists_M::Madonna::Erotica',
                          'path' => [
                                      'Index',
                                      'Music::Index',
                                      'Artists::Index',
                                      'Artists_M::Index',
                                      'Artists_M::Madonna::Index',
                                      'Artists_M::Madonna::Erotica'
                                    ],
                          'product_name' => 'Erotica',
                          'product_type' => 'Audio CD',
                          'release_date' => '05 November, 1992',
                          'thumb_url' => 'thumbs/erotica.jpg'
                        }
        };

#<-- /BLK -->

#####
# This section may be used for Perl subroutines and expressions.
#
print "Hello world from _Drawings_::Erotica\n";


1

__END__

# end of file

