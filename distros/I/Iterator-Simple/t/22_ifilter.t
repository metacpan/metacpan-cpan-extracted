use Test::More tests=>5;

use strict;
use warnings;

use Iterator::Simple qw(:all);

my $itr;

{
	$itr = [1,2,'STR',4, 52, 'foo', 12, 3];
	eval {
		no warnings 'numeric';
		$itr = ifilter $itr, sub{
			if($_ eq 'STR') {
				return iter([ split '', $_]);
			}
			elsif($_ >= 1 and $_ < 11) {
				return $_ + 10;
			}
			elsif($_ >= 11 and $_ <= 21) {
				return; #skip
			}
			elsif($_ > 21) {
				return $_ % 10;
			}
			else {
				return $_
			}
		};
	};
	is($@, '', 'ifilter creation');
	ok is_iterator($itr), 'ifilter confirm';
	is_deeply list($itr) => [11,12,'S','T','R',14, 2, 'foo', 13], 'ifilter result';
}

{
  $itr = [ 1, 2, 3 ];
  eval { 
    $itr = ifilter $itr, bless({ code => sub { $_ + 1 } } => 'ifiltertest');
  };
  is($@, '', 'ifilter creation');
  is_deeply list($itr) => [ 2, 3, 4 ], 'ifilter result';
}

package ifiltertest;

use overload (
  '&{}' => '_call',
  fallback => 1,
);

sub _call { shift->{code} }
