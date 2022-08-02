use strict; use warnings;

use Test::More tests => 16;

our $DESTROY=0;

my @TO_REMOVE = my $FILE = "/tmp/FlatFile.$$";
END { unlink @TO_REMOVE }
open F, ">", $FILE or die "$FILE: $!";
print F <DATA>;
close F;

is($DESTROY, 0);
{ my $f = FF->new(FILE => $FILE, FIELDS => [qw(fruit color)], MODE => "<") 
    or die; 1; 1;}
is($DESTROY, 1);
my $f = FF->new(FILE => $FILE, FIELDS => [qw(fruit color)], MODE => "<") 
  or die;
undef $f;
is($DESTROY, 2);

{ my $f = FF->new(FILE => $FILE, FIELDS => [qw(fruit color)], MODE => "<") 
    or die;
  $f->lookup(color => "red");
}
is($DESTROY, 3);

{ my $f = FF->new(FILE => $FILE, FIELDS => [qw(fruit color)], MODE => "<") 
    or die;
  my @recs = $f->lookup(color => "red");
}
is($DESTROY, 4);

$DESTROY = 0;
is($DESTROY, 0);
{ my $f = FF->new(FILE => $FILE, FIELDS => [qw(fruit color)], MODE => "+<") 
    or die; }
is($DESTROY, 1);
$f = FF->new(FILE => $FILE, FIELDS => [qw(fruit color)], MODE => "+<")
  or die;
undef $f;
is($DESTROY, 2);

{ my $f = FF->new(FILE => $FILE, FIELDS => [qw(fruit color)], MODE => "+<") 
    or die;
  $f->lookup(color => "red");
}
is($DESTROY, 3);

{ my $f = FF->new(FILE => $FILE, FIELDS => [qw(fruit color)], MODE => "+<") 
    or die;
  my @recs = $f->lookup(color => "red");
}
is($DESTROY, 4);

{ my $f = FF->new(FILE => $FILE, FIELDS => [qw(fruit color)], MODE => "+<") 
    or die;
  my @recs = $f->lookup(fruit => "apple");
  $recs[0]->set_color("purple");
}
is($DESTROY, 5);

{ my $f = FF->new(FILE => $FILE, FIELDS => [qw(fruit color)], MODE => "+<") 
    or die;
  my @recs = $f->lookup(fruit => "apple");
  is($recs[0]->color, "purple");
}
is($DESTROY, 6);

{ my $f = FF->new(FILE => $FILE, FIELDS => [qw(fruit color)], MODE => "+<") 
    or die;
  my @recs = $f->lookup(color => "purple");
  $recs[0]->delete;
}
is($DESTROY, 7);

{ my $f = FF->new(FILE => $FILE, FIELDS => [qw(fruit color)], MODE => "+<") 
    or die;
  my @recs = $f->lookup(color => "purple");
  is(scalar(@recs), 0);
}
is($DESTROY, 8);


BEGIN {
package FF;
use FlatFile;
our @ISA = 'FlatFile';

sub DESTROY {
  $main::DESTROY++;
  $_[0]->SUPER::DESTROY;
}
}

__DATA__
apple  red
banana green
cherry red
kiwi brown
