
use strict;
use warnings;
use Test::More tests => 19;
BEGIN { use_ok 'Image::Pbm' }

my $file = 'test.pbm';
my $string = "#####\n#---#\n-###-\n--#--\n--#--\n#####";
my $binstring = '11111100010111000100001001111100';

my $i = Image::Pbm->new_from_string( $string );
ok( $i,'new_from_string');
is( $i->as_binstring, $binstring,'as_binstring');
{
  my $s = $i->as_string;
  chomp $s;
  is( $s, $string,'as_string');
}
my $j = $i->new;
ok( $j,'new');
is( $j->as_binstring, $binstring,'as_binstring');

$i->save( $file );
ok( -e $file,'-e');

my $s = $i->serialise;
ok( $s,'serialise');

my $k = Image::Pbm->new_from_serialised( $s );
ok( $k,'new_from_serialised');
ok( $k->is_equal( $i ),'is_equal');

$i = undef;
ok( !defined $i,'undef');

$i = Image::Pbm->new(-file => $file );
ok( $i,'new(-file )');
is( $i->as_binstring, $binstring,'as_binstring');
{
  my $s = $i->as_string;
  chomp $s;
  is( $s, $string,'as_string');
}

is( $i->get(-file   ), $file,'get(-file   )');
is( $i->get(-width  ), 5    ,'get(-width  )');
is( $i->get(-height ), 6    ,'get(-height )');

is( $i->xy( 3, 2 ),'black','xy( 3, 2 )');
is( $i->xy( 3, 3 ),'white','xy( 3, 3 )');

unlink $file;
