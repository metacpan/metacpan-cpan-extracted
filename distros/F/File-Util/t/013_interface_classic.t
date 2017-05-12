
use strict;
use warnings;
use Test::NoWarnings;
use Test::More tests => 14;

use lib './lib';
use File::Util;

my $ftl = File::Util->new();

# testing _myargs()
is_deeply  [ $ftl->_myargs( qw/ a b c / ) ],
           [ qw/ a b c / ],
           '_myargs() understands a flat list';

is $ftl->_myargs( 'a' ),
   'a',
   '...and knows what to do in list context' ;

is scalar $ftl->_myargs( qw/ a b c / ),
   'a',
   '...and knows what to do in scalar context';

# testing _remove_opts()
is $ftl->_remove_opts( 'a' ),
   undef,
   '_remove_opts() ignores non-opts type single arg, and returns undef';

is $ftl->_remove_opts( undef ), undef, '...and returns undef if given undef';

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
   '...same test as above, with different input';

is_deeply
   $ftl->_remove_opts( [ 0, '', undef, '--mcninja', undef ] ),
   { qw/ mcninja 1 --mcninja 1 / },
   '...and recognizes args-as-listref, works right even with some bad args';



# testing _names_values
is_deeply
   $ftl->_names_values( qw/ a a b b c c d d e e / ),
   { a => a => b => b => c => c => d => d => e => e => },
   '_names_values() converts even-numbered args list to balanced hashref';

is_deeply
   $ftl->_names_values( a => 'a',  'b' ),
   { a => a => b => undef },
   '...and sets final name-value pair to value=undef for unbalanced lists';

is_deeply
   $ftl->_names_values( a => 'a',  b => 'b', ( undef, 'u' ), c => 'c' ), # foolishness
   { a => a => b => b => c => c => }, # ...should go ignored (at least here)
   '...and ignores name-value pair in balanced list when name itself is undef';

is File::Util::Interface::Classic::DESTROY(), undef, '::DESTROY() returns undef';

exit;
