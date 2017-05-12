
use strict;
use warnings;
use Test::NoWarnings;
use Test::More tests => 29;

use lib './lib';
use File::Util;

my $ftl = File::Util->new();

# ::Modern should be able to do everthing ::Classic does, so we're going to
# run all the same tests on ::Modern that we do on ::Classic, and after
# that we are going to target the things that only ::Modern can do.

# BEGIN BACK-COMPAT TESTS

# testing _myargs() with back-compat
is_deeply  [ $ftl->_myargs( qw/ a b c / ) ],
           [ qw/ a b c / ],
           '_myargs() understands a flat list';

is $ftl->_myargs( 'a' ),
   'a',
   '...and knows what to do in list context' ;

is scalar $ftl->_myargs( qw/ a b c / ),
   'a',
   '...and knows what to do in scalar context';

# testing $ftl->_remove_opts() with back-compat
is $ftl->_remove_opts( 'a' ),
   undef,
   '$ftl->_remove_opts() ignores non-opts type single arg, and returns undef';

is $ftl->_remove_opts( qw/ a b c / ),
   undef,
   '...and ignores non-opts type multi arg list, and returns undef';

is_deeply
   $ftl->_remove_opts( [ qw/ --name=Larry --lang=Perl --recurse --empty= / ] ),
   {
      '--name'    => 'Larry',
      'name'      => 'Larry',
      '--lang'    => 'Perl',
      'lang'      => 'Perl',
      '--recurse' => 1,
      'recurse'   => 1,
      '--empty'   => '',
      'empty'     => '',
   },
   '...and recognizes + returns --name=value pairs, --flags, and --empty=';

is_deeply
   $ftl->_remove_opts(
      [
         qw/ --verbose --8-ball=black --empty= /,
      ]
   ),
   {
      '--verbose' => 1,
      'verbose'   => 1,
      '--8-ball'  => 'black',
      '8_ball'    => 'black',
      '--empty'   => '',
      'empty'     => '',
   },
   '...and still does the same with some slightly different input';

is_deeply
   $ftl->_remove_opts( [ 0, '', undef, '--mcninja', undef ] ),
   { qw/ mcninja 1 --mcninja 1 / },
   '...and works right even with some bad args';


# testing $ftl->_names_values() with back-compat
is_deeply
   $ftl->_names_values( qw/ a a b b c c d d e e / ),
   { a => a => b => b => c => c => d => d => e => e => },
   '$ftl->_names_values() converts even-numbered args list to balanced hashref';

is_deeply
   $ftl->_names_values( a => 'a',  'b' ),
   { a => a => b => undef },
   '...and sets final name-value pair to value=undef for unbalanced lists';

is_deeply
   $ftl->_names_values( a => 'a',  b => 'b', ( undef, 'u' ), c => 'c' ), # foolishness
   { a => a => b => b => c => c => }, # ...should go ignored (at least here)
   '...and ignores name-value pair in balanced list when name itself is undef';


# BACK COMPAT TESTS DONE.  Now test ::Modern interface

# testing _myargs() - no testing needed because it works the same in ::Modern
# since it is imported from ::Classic

# testing $ftl->_remove_opts()
is_deeply
   $ftl->_remove_opts(
      [
         { name => 'Larry', lang => 'Perl', recurse => 1, empty => undef }
      ]
   ),
   {
      name      => 'Larry',
      lang      => 'Perl',
      recurse   => 1,
      empty     => undef,
   },
   '$ftl->_remove_opts() recognizes + returns { name => value } pairs, and flags';

is_deeply
   $ftl->_remove_opts(
      [
         { verbose => 1, '8_ball' => 'black', empty => '' },
      ]
   ),
   {
      verbose   => 1,
      '8_ball'  => 'black',
      empty     => '',
   },
   '...and does the same with slightly different input';

is $ftl->_remove_opts( ), undef, '...and returns undef if given no args';

is $ftl->_remove_opts( undef ), undef, '...and returns undef if given undef';

is_deeply $ftl->_remove_opts( [ undef, 0, '' ] ),
         { },
         '...and returns empty hashref if given listref of falsies';

is_deeply
   $ftl->_remove_opts( [ ] ),
   { },
   '...and returns an empty hashref if given an empty listref of args';

is_deeply
   $ftl->_remove_opts(
      [
         { verbose => 1, '8_ball' => 'black' }, { empty => '' },
      ]
   ),
   {
      verbose   => 1,
      '8_ball'  => 'black',
      empty     => '',
   },
   '...and still does the same if args list contains multiple hashrefs';

is_deeply
   $ftl->_remove_opts(
      [
         { verbose => 1, '8_ball' => 'black' }, undef, { empty => '' },
      ]
   ),
   {
      verbose   => 1,
      '8_ball'  => 'black',
      empty     => '',
   },
   '...and still does the same if args list is interspersed with undef\'s';


# testing $ftl->_names_values()
is_deeply
   $ftl->_names_values( { qw/ a a b b c c d d e e / } ),
   { a => a => b => b => c => c => d => d => e => e => },
   '$ftl->_names_values() compares perfectly from input hashref to args hashref';

is_deeply
   $ftl->_names_values( ),
   { },
   '...and returns an empty hashref if given no args';

is_deeply
   $ftl->_names_values( { } ),
   { },
   '...and returns an empty hashref if given an empty hashref as only arg';

is_deeply
   $ftl->_parse_in(
      { qw/ a a  b b c c d d e e / }
   ),
   { a => a => b => b => c => c => d => d => e => e => },
   '$ftl->_parse_in() and understands a hashref';

is_deeply $ftl->_parse_in( ), { },
         '...and returns an empty hashref if given no args';

is_deeply $ftl->_parse_in( { } ), { },
         '...and does the same if given an empty hashref';

is_deeply
   $ftl->_parse_in(
      { qw/ a a / }, { qw/ b b / }, { qw/ c c / }, { qw/ d d e e / }
   ),
   { a => a => b => b => c => c => d => d => e => e => },
   '...and understands and amalgamates a list of hashrefs';

is_deeply
   $ftl->_parse_in(
      { qw/ a a / }, b => 'b', '--c=c', { qw/ d d e e / }, '--f'
   ),
   {
      a => 'a',
      b => 'b',
      c => 'c',
      d => 'd',
      e => 'e',
      f => 1,
      '--c' => 'c',
      '--f' => 1,
   },
   '...and understands a mixture of old and new style input args';

is File::Util::Interface::Modern::DESTROY(), undef, '::DESTROY() returns undef';

exit;
