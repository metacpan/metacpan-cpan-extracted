#! perl

use 5.006;
use strict;
use warnings;

use Test::More tests => 1;
use Hook::WrapSub qw( wrap_subs unwrap_subs );

my $expected = <<'END_EXPECTED';
0B('0')[0]
foo('0')
0A('0')[0]
1B('1')[1]
0B('X')[1]
foo('X')
0A('X')[1]
1A('X')[1]
0B('2')[undef]
foo('2')
0A('2')[undef]
foo('3')
END_EXPECTED


my $result = '';

sub foo { $result .= "foo(@_)\n" }

wrap_subs
  sub { $result .= "0B(@_)[".caller_wantarray()."]\n" },
  'foo',
  sub { $result .= "0A(@_)[".caller_wantarray()."]\n" }
  ;

my $r = foo( "'0'" );

wrap_subs
  sub { $result .= "1B(@_)[".caller_wantarray()."]\n"; @_ = ("'X'"); },
  'foo',
  sub { $result .= "1A(@_)[".caller_wantarray()."]\n" }
  ;

my @r = foo( "'1'" );

unwrap_subs 'foo' ;

foo( "'2'" );

unwrap_subs 'foo' ;

foo( "'3'" );


is($result, $expected);

sub caller_wantarray
{
    my $wantarray = $Hook::WrapSub::caller[5];

    if (not defined $wantarray) {
        return 'undef';
    } else {
        return $wantarray ? 1 : 0;
    }
}
