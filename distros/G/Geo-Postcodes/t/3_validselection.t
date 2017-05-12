###############################################################################
#                                                                             #
#           Geo::Postcodes Test Suite 3 - Valid selection list                #
#         ------------------------------------------------------              #
#            Arne Sommer - perl@bbop.org - 01. October   2006                 #
#                                                                             #
###############################################################################

use Test::More tests => 54;

BEGIN { use_ok('Geo::Postcodes') };

###############################################################################

  valid('all');
  valid('all', 'xxxxxx'); # Everything after 'all' is silently ignored.

  valid('none');
  valid('none', 'xxxxxx'); # Everything after 'none' is silently ignored.

  valid('one');
  valid('one', 'postcode', '12..');
invalid('one', 'xxxxxx');
invalid('one', 'xxxxxx', 'yyyyy');

invalid('and');
  valid('and', 'postcode', '12..');

invalid('and not');
  valid('and not',    'postcode', '12..');
  valid('and', 'not', 'postcode', '12..');

invalid('nand');
  valid('nand', 'postcode', '12..');

invalid('nand not');
  valid('nand not',    'postcode', '12..');
  valid('nand', 'not', 'postcode', '12..');

invalid('not');
  valid('not', 'postcode', '12..');
  valid('not', 'postcode', '12..', 'postcode', '..9.');

invalid('or');
  valid('or', 'postcode', '12..');

invalid('or not');
  valid('or not', 'postcode', '12..');
  valid('or not', 'postcode', '12..');

invalid('nor');
  valid('nor', 'postcode', '12..');

invalid('nor not');
  valid('nor not',    'postcode', '12..');
  valid('nor', 'not', 'postcode', '12..');

invalid('xnor');
  valid('xnor', 'postcode', '12..');

invalid('xnor not');
  valid('xnor not',    'postcode', '12..');
  valid('xnor', 'not', 'postcode', '12..');

invalid('xor');
  valid('xor', 'postcode', '12..');

invalid('xor not');
  valid('xor not',    'postcode', '12..');
  valid('xor', 'not', 'postcode', '12..');

  valid('postcode', 'what do you think?'); # A valid method, and an arbitrary value
  valid('postcode', '12..', 'and not',    'postcode', '12..');
  valid('postcode', '12..', 'and', 'not', 'postcode', '12..');

  valid(           'postcode' => '12..',     # '12' followed by two additional digits
        'and not', 'location' => '%s%',      # Containing an 's'
        'or',      'borough'  => '.....',    # 4 letters
        'nor',     'type'     => 'ST',       # 'Street address'
       );

invalid('elephant', 'Dumbo');

  valid('address',  '%s%');
  valid('county',   'F%');
  valid('borough',  '%øy');

###############################################################################

  valid('procedure', \&test);      # But only because it is defined in this file.
invalid('procedure', \&test2);     # Procedure does not exist.
  valid('procedure', \&Geo::Postcodes::get_fields);
invalid('procedure', \&get_fields);

sub test {}

###############################################################################

sub valid
{
  my @arguments = @_;

  my($status, undef) = Geo::Postcodes::verify_selectionlist(@arguments);

  ok ($status, "Valid selection list for core postcodes (" .
      join(",", @arguments) . ").\n");
}

sub invalid
{
  my @arguments = @_;

  my($status, undef) = Geo::Postcodes::verify_selectionlist(@arguments);

  ok (! $status, "Invalid selection list for core postcodes (" .
      join(",", @arguments) . ").\n");
}

###############################################################################
