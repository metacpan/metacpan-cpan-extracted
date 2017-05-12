use strict;
use warnings;
use Test::More;

use File::Spec;
use File::Temp;

use Text::Xslate;
use Localizer::Scanner::Xslate;

my $result = Localizer::Dictionary->new();
my $ext = Localizer::Scanner::Xslate->new(
    syntax => 'TTerse',
);
$ext->scan_file($result, 't/dat/Scanner/xslate.html');
# use Data::Dumper; warn Dumper($result->entries);
is_deeply $result->_entries,
  {
    'nest2' => {
        'position' => [ [ 't/dat/Scanner/xslate.html', 13 ] ]
    },
    'nest1' => {
        'position' => [ [ 't/dat/Scanner/xslate.html', 13 ] ]
    },
    'values: %1 %2' => {
        'position' => [ [ 't/dat/Scanner/xslate.html', 11 ] ]
    },
    'term' => {
        'position' => [ [ 't/dat/Scanner/xslate.html', 1 ], [ 't/dat/Scanner/xslate.html', 7 ] ]
    },
    'hello' => {
        'position' => [ [ 't/dat/Scanner/xslate.html', 4 ], [ 't/dat/Scanner/xslate.html', 12 ] ]
    },
    'nest3' => {
        'position' => [ [ 't/dat/Scanner/xslate.html', 13 ] ]
    },
    'word' => {
        'position' => [ [ 't/dat/Scanner/xslate.html', 10 ] ]
    },
    'xslate syntax' => {
        'position' => [ [ 't/dat/Scanner/xslate.html', 6 ] ]
    }
  };

done_testing;

sub slurp {
    my $fname = shift;
    open my $fh, '<', $fname
        or Carp::croak("Can't open '$fname' for reading: '$!'");
    do { local $/; <$fh> }
}
