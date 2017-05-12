#!/usr/bin/perl -w

# for Math::String::Charset.pm (simple set)

use Test;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../lib'; # to run manually
  chdir 't' if -d 't';
  plan tests => 155;
  }

use Math::String::Charset;

$Math::String::Charset::die_on_error = 0;	# we better catch them
my $a;

my $c = 'Math::String::Charset';

###############################################################################
# invalid input combinations

$a = $c->new( { type => 3 } );
ok ($a->error(),"Illegal type '3'");

$a = $c->new( { type => -1 } );
ok ($a->error(),"Illegal type '-1'");

$a = $c->new( { order => 2, type => 1 } );
ok ($a->error(),"Illegal combination of type '1' and order '2'");

$a = $c->new( { order => 3, type => 0 } );
ok ($a->error(),"Illegal order '3'");

$a = $c->new( { type => 0, sets => 'foo' } );
ok ($a->error(),"Illegal type '0' used with 'sets'");

$a = $c->new( { type => 1, bi => 'foo' } );
ok ($a->error(),"Illegal type '1' used with 'bi'");

$a = $c->new( { order => 1, type => 0, end => ' ' } );
ok ($a->error(),"Illegal combination of order '1' and 'end'");

$a = $c->new( { charlen => 2, sep => 'a' } );
ok ($a->error(),"Can not have both 'sep' and 'charlen' in new()");

$a = $c->new( { bi => {}, sets => 'b' } );
ok ($a->error(),"Can not have both 'bi' and 'sets' in new()");

###############################################################################
# simple charset's

$a = $c->new( ['a'..'z'] );

ok ($a->error(),"");

ok ($a->order(),1); ok ($a->type(),0);

my $ok = 0;
my $aa = [ 'a'..'z' ];
my @ab = $a->start();

for (my $i = 0; $i < @$aa; $i++)
  {
  $ok ++ if $aa->[$i] ne $ab[$i];
  }
ok ($ok,0);

ok ($a->length(),26);

$a = $c->new( ['a'..'c'] );
ok ($a->error(),"");
ok ($a->length(),3);

ok ($a->class(0),1);
ok ($a->class(1),3);
ok ($a->class(2),3*3);
ok ($a->class(3),3*3*3);
ok ($a->class(4),3*3*3*3);

ok ($a->first(),'');
ok ($a->last(),'');
ok ($a->first(0),'');
ok ($a->last(0),'');

ok ($a->first(1),'a');
ok ($a->last(1),'c');

ok ($a->first(2),'aa');
ok ($a->last(2),'cc');

ok ($a->first(3),'aaa');
ok ($a->last(3),'ccc');

ok ($a->lowest(1),1);
ok ($a->lowest(2),1+3);
ok ($a->lowest(3),1+3+3*3);
ok ($a->lowest(4),1+3+3*3+3*3*3);

ok ($a->highest(1),3);
ok ($a->highest(2),3+3*3);
ok ($a->highest(3),3+3*3+3*3*3);
ok ($a->highest(4),3+3*3+3*3*3+3*3*3*3);

ok ($a->str2num(''),0);
ok ($a->str2num('a'),1);
ok ($a->str2num('aa'),1+3);
ok ($a->str2num('aaa'),1+3+3*3);
ok ($a->str2num('cba'),1+2*3+3*3*3);

ok ($a->num2str(0),'');
ok ($a->num2str(1),'a');
ok ($a->num2str(2),'b');
ok ($a->num2str(3),'c');

ok ($a->num2str(1+2),'c');
ok ($a->num2str(1+3),'aa');
ok ($a->num2str(1+3+2*3+2),'cc');
ok ($a->num2str(1+3+3*3),'aaa');
ok ($a->num2str(1+3+2*3*3),'baa');
ok ($a->num2str(1+2*3+3*3*3),'cba');

# is valid
ok_undef ($a->{_sep});
ok ($a->is_valid('abcbca'),1);
ok ($a->is_valid(),0);			# undef string is never valid
ok ($a->is_valid('abcxbca'),0);
ok ($a->is_valid('abcx'),0);
ok ($a->is_valid('xabca'),0);
ok ($a->is_valid('a'),1);

###############################################################################
# char()
ok ($a->char(0),'a');
ok ($a->char(1),'b');
ok ($a->char(-1),'c');
ok_undef ($a->char(3));

# map()
ok ($a->map('a'),0);
ok_undef ($a->map('ab'));
ok ($a->map('b'),1);
ok ($a->map('c'),2);
ok_undef ($a->map('d'));

# check charlength
$a = $c->new( ['a','b','foo','c'] );
if ($a->error() !~ /Illegal.*char.*length.*not/)
  {
  ok ($a->error(),"not '" . $a->error() . "'");
  }
else
  {
  ok (1,1);
  }

$a = $c->new( ['foo','bar','baz'] );
ok ($a->error(),'');
ok ($a->char(0),'foo');
ok ($a->char(1),'bar');
ok ($a->char(-1),'baz');

ok ($a->num2str(1),'foo');
ok ($a->num2str(2),'bar');
ok ($a->num2str(3),'baz');
ok ($a->num2str(3+1),'foofoo');

ok ($a->str2num('foo'),1);
ok ($a->str2num('foofoo'),1+3);
ok ($a->str2num('foobaz'),1+3+2);
ok ($a->str2num('barfoo'),1+3+3);

ok ($a->is_valid('barfoo'),1);
ok ($a->is_valid('barfoobar'),1);
ok ($a->is_valid('barfotbar'),0);
ok ($a->is_valid('barfoofot'),0);
ok ($a->is_valid('fotbarfoo'),0);
ok ($a->is_valid('bar'),1);
ok ($a->is_valid(''),1);
ok ($a->is_valid('fuh'),0);

###############################################################################
# first/last with sep char

$a = $c->new( { start => ['a'..'z'], sep => '-' } );
ok ($a->first(0),''); ok ($a->last (0),'');
ok ($a->first(1),'a'); ok ($a->last (1),'z');
ok ($a->first(2),'a-a'); ok ($a->last (2),'z-z');
ok ($a->first(3),'a-a-a'); ok ($a->last (3),'z-z-z');

$a = $c->new( { start => [qw/FOO BAR/], sep => '-' } );
ok ($a->first(0),''); ok ($a->last (0),'');
ok ($a->first(1),'FOO'); ok ($a->last (1),'BAR');
ok ($a->first(2),'FOO-FOO'); ok ($a->last (2),'BAR-BAR');
ok ($a->first(3),'FOO-FOO-FOO'); ok ($a->last (3),'BAR-BAR-BAR');

###############################################################################
# min/max len

$a = $c->new( { start => ['f','o','o'] } );
ok ($a->error(),''); ok ($a->minlen(),'-inf'); ok ($a->maxlen(),'inf');

$a = $c->new( { start => ['f','o','o'],
  minlen => 2, maxlen => 4, } );
ok ($a->error(),''); ok ($a->minlen(),2);     ok ($a->maxlen(),4);
ok ($a->is_valid('fooo'),1);
ok ($a->is_valid('foo'),1);
ok ($a->is_valid('fo'),1);
ok ($a->is_valid(''),0);			# 0 is smaller than minlen
ok ($a->is_valid('f'),0);
ok ($a->is_valid('fooof'),0);

$a = $c->new( { start => ['f','o','o'],
  minlen => 2, maxlen => 1, } );
ok ($a->error(),'Maxlen is smaller than minlen!');


###############################################################################
# simple charset's with sep char

ok_undef ($a->{_sep});
$a = $c->new( { start => ['hans','mag','blumen'],
   sep => ' ',} );
ok ($a->{_sep},' ');
ok ($a->{_order},1);
ok ($a->num2str(3+1),'hans hans');

ok ($a->str2num('hans hans'),3+1);
ok ($a->str2num('hans hans hans'),3+3*3+1);
ok ($a->str2num('hans mag blumen'),3+3*3+6);

# front/end stripping
ok ($a->str2num(' hans mag blumen'),3+3*3+6);
ok ($a->str2num('hans mag blumen '),3+3*3+6);
ok ($a->str2num(' hans mag blumen '),3+3*3+6);

$a = $c->new( { start => ['foooo','bar','buuh'],
  sep => ' ',} );
ok ($a->error(),"");

ok ($a->is_valid('foooo bar buuh'),1);
ok ($a->is_valid('fooo bar buuh'),0);
ok ($a->is_valid(' foooo bar buuh bar buuh '),1);

$a = $c->new( { start => ['foo','bar'], sep => '',} );
ok ($a->error(),"Field 'sep' must not be empty");

###############################################################################
# normalize

$a = $c->new( { start => ['foo','bar'], sep => ' ',} );
ok ($a->norm(' foo bar '),'foo bar');
ok ($a->norm('foo bar '), 'foo bar');
ok ($a->norm(' foo bar'), 'foo bar');
ok ($a->norm('foo bar'),  'foo bar');
$a = $c->new( { start => ['foo','bar'],} );
ok ($a->norm('foo bar baz'), 'foo bar baz');	# no check for validity

###############################################################################
# map

$a = $c->new( ['0'..'9'] );
for ('0'..'9')
  {
  ok ($a->map($_),$_);
  }

###############################################################################
# scale

$a = $c->new( { start => ['a'..'z'], scale => 2 } );
ok ($a->error(),"");
ok ($a->scale(),2);

###############################################################################
# copy

$b = $a->copy();

ok (ref($b), $c);
ok ($b->error(),"");
ok ($b->isa('Math::String::Charset'));

###############################################################################
# Perl 5.005 does not like ok ($x,undef)

sub ok_undef
  {
  my $x = shift;

  ok (1,1) and return if !defined $x;
  ok ($x,'undef');
  }
