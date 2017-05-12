
use strict;
use warnings;
use Test::More tests => 2;
use Hook::LexWrap;

my $str='';
sub doit { $str.= "[doit:{".join(',',caller)."}]"; return {my=>"data"} }

SCOPED: {
 no warnings 'uninitialized'; #last argument in wrapper sub
 wrap doit =>
  pre => sub { $str.="[pre1: @_]" },
  post => sub { $str.="[post1:@_]"; $_[1]=9; };

 my $temporarily = wrap doit =>
  post => sub { $str.="[post2:@_]" },
  pre => sub { $str.="[pre2: @_]"};

 my @args = (1,2,3);
 doit(@args); # pre2->pre1->doit->post1->post2
 is ($str,'[pre2: 1 2 3 ][pre1: 1 2 3 ][doit:{main,'.__FILE__.','.(__LINE__-1).'}][post1:1 2 3 ][post2:1 9 3 ]');
}

$str='';
my @args = (4,5,6);
doit(@args); # pre1->doit->post1
is ($str,'[pre1: 4 5 6 ][doit:{main,'.__FILE__.','.(__LINE__-1).'}][post1:4 5 6 ]');
