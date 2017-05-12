package FormValidator::LazyWay::Rule::Number::JA;

use strict;
use warnings;
use utf8;

sub int   {'整数'}
sub uint  {'正数'}
sub float {'小数点付き整数'}
sub ufloat{'小数点付き正数'}
sub range { '$_[min]以上$_[max]以下' }

1;

=head1 NAME

FormValidator::LazyWay::Rule::Number::JA - Messages of Number Rule

=cut
