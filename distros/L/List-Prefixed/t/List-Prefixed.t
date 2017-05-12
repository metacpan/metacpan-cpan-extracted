# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl List-Prefixed.t'

#########################

use strict;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN { use_ok('List::Prefixed') };

# http://perldoc.perl.org/Test/More.html

#########################

# empty list
do {
  my $prefixed = List::Prefixed->fold();
  isa_ok $prefixed => 'List::Prefixed';
  is $prefixed->regex => '';
};

# singleton list
do {
  my $prefixed = List::Prefixed->fold(qw( X ));
  isa_ok $prefixed => 'List::Prefixed';
  is_deeply $prefixed => ['X',[],undef];
  is_deeply scalar $prefixed->list => ['X'];
  is_deeply scalar $prefixed->list('X') => ['X'];
  is_deeply scalar $prefixed->list('a') => [];
  is $prefixed->regex => 'X';
};

# singleton, where string occurs twice
do {
  my $prefixed = List::Prefixed->fold(qw( X X ));
  isa_ok $prefixed => 'List::Prefixed';
  is_deeply $prefixed => ['X',[],undef];
  is_deeply scalar $prefixed->list => ['X'];
  is_deeply scalar $prefixed->list('X') => ['X'];
  is_deeply scalar $prefixed->list('a') => [];
  is $prefixed->regex => 'X';
};

# sub string
do {
  my $prefixed = List::Prefixed->fold(qw( X XX ));
  isa_ok $prefixed => 'List::Prefixed';
  is_deeply $prefixed => ['X',[['X']],1];
  is_deeply scalar $prefixed->list => ['X','XX'];
  is_deeply scalar $prefixed->list('X') => ['X','XX'];
  is_deeply scalar $prefixed->list('a') => [];
  is $prefixed->regex => 'X(?:X)?';
};

# 2 disjoint strings
do {
  my $prefixed = List::Prefixed->fold(qw( X Y ));
  isa_ok $prefixed => 'List::Prefixed';
  is_deeply $prefixed => ['',[['X'],['Y']],undef];
  is_deeply scalar $prefixed->list => ['X','Y'];
  is_deeply scalar $prefixed->list('X') => ['X'];
  is_deeply scalar $prefixed->list('Y') => ['Y'];
  is_deeply scalar $prefixed->list('b') => [];
  is $prefixed->regex => '(?:X|Y)';
};

# 3 disjoint strings, re-ordered
do {
  my $prefixed = List::Prefixed->fold(qw( Y Z X ));
  isa_ok $prefixed => 'List::Prefixed';
  is_deeply $prefixed => ['',[['X'],['Y'],['Z']],undef];
  is_deeply scalar $prefixed->list => ['X','Y','Z'];
  is_deeply scalar $prefixed->list('X') => ['X'];
  is_deeply scalar $prefixed->list('Y') => ['Y'];
  is_deeply scalar $prefixed->list('Z') => ['Z'];
  is_deeply scalar $prefixed->list('b') => [];
  is $prefixed->regex => '(?:X|Y|Z)';
};

# sub strings
do {
  my @s = qw( X XY XXY XXXY XXYX );
  my $prefixed = List::Prefixed->fold(@s);
  isa_ok $prefixed => 'List::Prefixed';
  is_deeply $prefixed => ['X',[['X',[['XY'],['Y',[['X']],1]],undef],['Y']],1];
  
  # list
  is_deeply scalar $prefixed->list => ['X','XXXY','XXY','XXYX','XY'];
  is_deeply scalar $prefixed->list('X') => ['X','XXXY','XXY','XXYX','XY'];
  is_deeply scalar $prefixed->list('XX') => ['XXXY','XXY','XXYX'];
  is_deeply scalar $prefixed->list('XY') => ['XY'];
  is_deeply scalar $prefixed->list('Y') => [];
  
  # regex
  my $re = $prefixed->regex;
  is $re => 'X(?:X(?:XY|Y(?:X)?)|Y)?';
  my $qr = qr/^$re$/;
  like $_ => $qr foreach @s;
  unlike $_ => $qr foreach variants(@s);
  
  # unfold
  my $prefixed2 = List::Prefixed->unfold($re);
  isa_ok $prefixed2 => 'List::Prefixed';
  is_deeply $prefixed2 => $prefixed;
};

# common prefix, does not appear in list
do {
  my $prefixed = List::Prefixed->fold(qw( AY AZ AX ));
  isa_ok $prefixed => 'List::Prefixed';
  is_deeply $prefixed => ['A',[['X'],['Y'],['Z']],undef];
  is_deeply scalar $prefixed->list => ['AX','AY','AZ'];
  is_deeply scalar $prefixed->list('A') => ['AX','AY','AZ'];
  is_deeply scalar $prefixed->list('AX') => ['AX'];
  is_deeply scalar $prefixed->list('AY') => ['AY'];
  is_deeply scalar $prefixed->list('AZ') => ['AZ'];
  is_deeply scalar $prefixed->list('b') => [];
  is $prefixed->regex => 'A(?:X|Y|Z)';
};

# common prefix, appears in list
do {
  my @s = qw( AY AZ AX A );
  my $prefixed = List::Prefixed->fold(@s);
  isa_ok $prefixed => 'List::Prefixed';
  is_deeply $prefixed => ['A',[['X'],['Y'],['Z']],1];
  
  # list
  is_deeply scalar $prefixed->list => ['A','AX','AY','AZ'];
  is_deeply scalar $prefixed->list('A') => ['A','AX','AY','AZ'];
  is_deeply scalar $prefixed->list('AX') => ['AX'];
  is_deeply scalar $prefixed->list('AY') => ['AY'];
  is_deeply scalar $prefixed->list('AZ') => ['AZ'];
  is_deeply scalar $prefixed->list('b') => [];
  
  # regex
  my $re = $prefixed->regex;
  is $re => 'A(?:X|Y|Z)?';
  my $qr = qr/^$re$/;
  like $_ => $qr foreach @s;
  unlike $_ => $qr foreach variants(@s);
  
  # unfold
  my $prefixed2 = List::Prefixed->unfold($re);
  isa_ok $prefixed2 => 'List::Prefixed';
  is_deeply $prefixed2 => $prefixed;
};

# common prefix plus a disjoint element
do {
  my @s = qw( AY AZ AX A B );
  my $prefixed = List::Prefixed->fold(@s);
  isa_ok $prefixed => 'List::Prefixed';
  is_deeply $prefixed => ['',[['A',[['X'],['Y'],['Z']],1],['B']],undef];
  
  is_deeply scalar $prefixed->list => ['A','AX','AY','AZ','B'];
  is_deeply scalar $prefixed->list('A') => ['A','AX','AY','AZ'];
  is_deeply scalar $prefixed->list('AX') => ['AX'];
  is_deeply scalar $prefixed->list('AY') => ['AY'];
  is_deeply scalar $prefixed->list('AZ') => ['AZ'];
  is_deeply scalar $prefixed->list('B') => ['B'];
  is_deeply scalar $prefixed->list('b') => [];
  
  # regex
  my $re = $prefixed->regex;
  is $re => '(?:A(?:X|Y|Z)?|B)';
  my $qr = qr/^$re$/;
  like $_ => $qr foreach @s;
  unlike $_ => $qr foreach variants(@s);
  
  # unfold
  my $prefixed2 = List::Prefixed->unfold($re);
  isa_ok $prefixed2 => 'List::Prefixed';
  is_deeply $prefixed2 => $prefixed;
};

# AB ABC ABD ACE
do {
  my @s = qw( AB ABC ABD ACE );
  my $prefixed = List::Prefixed->fold(@s);
  isa_ok $prefixed => 'List::Prefixed';
  is_deeply $prefixed => ['A',[['B',[['C'],['D']],1],['CE']],undef];
  
  # list
  is_deeply scalar $prefixed->list => ['AB','ABC','ABD','ACE'];
  is_deeply scalar $prefixed->list('A') => ['AB','ABC','ABD','ACE'];
  is_deeply scalar $prefixed->list('AB') => ['AB','ABC','ABD'];
  is_deeply scalar $prefixed->list('AC') => ['ACE'];
  is_deeply scalar $prefixed->list('b') => [];
  
  # regex
  my $re = $prefixed->regex;
  is $re => 'A(?:B(?:C|D)?|CE)';
  my $qr = qr/^$re$/;
  like $_ => $qr foreach @s;
  unlike $_ => $qr foreach variants(@s);
  
  # unfold
  my $prefixed2 = List::Prefixed->unfold($re);
  isa_ok $prefixed2 => 'List::Prefixed';
  is_deeply $prefixed2 => $prefixed;
};

# white space strings
do {
  my @s = (" \n ", " \n \t", " \n \t ", "\n\t", "\n\t\n");
  my $prefixed = List::Prefixed->fold(@s);
  isa_ok $prefixed => 'List::Prefixed';
  is_deeply $prefixed => ['',[["\n\t",[["\n"]],1],[" \n ",[["\t",[[' ']],1]],1]],undef];
  
  # list
  is_deeply scalar $prefixed->list => ["\n\t","\n\t\n"," \n "," \n \t"," \n \t "];
  is_deeply scalar $prefixed->list(' ') => [" \n "," \n \t"," \n \t "];
  is_deeply scalar $prefixed->list("\n") => ["\n\t","\n\t\n"];
  
  # regex
  my $re = $prefixed->regex;
  is $re => "(?:\\\n\\\t(?:\\\n)?|\\ \\\n\\ (?:\\\t(?:\\ )?)?)";
  my $qr = qr/^$re$/;
  like $_ => $qr foreach @s;
  # unlike $_ => $qr foreach variants(@s); # doesn't work well because ( "X\n" =~ /^X$/ )
  
  # unfold
  my $prefixed2 = List::Prefixed->unfold($re);
  isa_ok $prefixed2 => 'List::Prefixed';
  is_deeply $prefixed2 => $prefixed;
};

# strings containing regex control characters
do {
  my @s = ('$/','\\$/','(','((','(((','\\','\\\\','\\(','\\$');
  my $prefixed = List::Prefixed->fold(@s);
  isa_ok $prefixed => 'List::Prefixed';
  is_deeply $prefixed => ['',[['$/'],['(',[['(',[['(']],1]],1],['\\',[['$',[['/']],1],['('],['\\']],1]],undef];
  
  # list
  is_deeply scalar $prefixed->list => ['$/','(','((','(((','\\','\\$','\\$/','\\(','\\\\'];
  is_deeply scalar $prefixed->list('\\') => ['\\','\\$','\\$/','\\(','\\\\'];
  is_deeply scalar $prefixed->list('$') => ['$/'];
  is_deeply scalar $prefixed->list('\\$') => ['\\$','\\$/'];
  is_deeply scalar $prefixed->list('(') => ['(','((','((('];
  is_deeply scalar $prefixed->list('((') => ['((','((('];
  is_deeply scalar $prefixed->list('x') => [];
  
  # regex
  my $re = $prefixed->regex;
  is $re => '(?:\$\/|\((?:\((?:\()?)?|\\\\(?:\$(?:\/)?|\(|\\\\)?)';
  my $qr = qr/^$re$/;
  like $_ => $qr foreach @s;
  unlike $_ => $qr foreach variants(@s);
  
  # unfold
  my $prefixed2 = List::Prefixed->unfold($re);
  isa_ok $prefixed2 => 'List::Prefixed';
  is_deeply $prefixed2 => $prefixed;
};

# Unicode escaped \x{FFFF}
do {
  my @s = sort { $a cmp $b } (
    "Test",
    "T\x{E4}st", # 'Täst'
    "T\x{E4}\x{DF}t", # 'Täßt'
    "T\x{E4}\x{DF}t\x{E2}n", # 'Täßtân'
    "\x{442}\x{435}\x{441}\x{442}", # 'тест'
    "\x{442}\x{435}\x{441}\x{442}\x{44B}", # 'тесты'
    "\x{442}\x{435}\x{441}\x{442}\x{438}\x{440}\x{43E}\x{432}\x{430}\x{43D}\x{438}\x{435}", # 'тестирование'
  );
  my $prefixed = List::Prefixed->fold(@s);
  isa_ok $prefixed => 'List::Prefixed';

  # list
  is_deeply scalar $prefixed->list => \@s;
  is_deeply scalar $prefixed->list('T') => ["Test","T\x{E4}st","T\x{E4}\x{DF}t","T\x{E4}\x{DF}t\x{E2}n"];

  my $re = $prefixed->regex;
  is $re => '(?:T(?:est|\x{E4}(?:st|\x{DF}t(?:\x{E2}n)?))|\x{442}\x{435}\x{441}\x{442}(?:\x{438}\x{440}\x{43E}\x{432}\x{430}\x{43D}\x{438}\x{435}|\x{44B})?)';
  my $qr = qr/^$re$/;
  like $_ => $qr foreach @s;
  unlike $_ => $qr foreach variants(@s);

  # unfold
  my $prefixed2 = List::Prefixed->unfold($re);
  isa_ok $prefixed2 => 'List::Prefixed';
  is_deeply $prefixed2 => $prefixed;
};


#########################
done_testing;

# helpers

# randomly permutate @array in place
sub fisher_yates_shuffle     # credits to: http://www.perlmonks.org/?node_id=1869
{
    my $array = shift;
    my $i = @$array;
    while ( --$i )
    {
        my $j = int rand( $i+1 );
        @$array[$i,$j] = @$array[$j,$i];
    }
}

# From a given list, create a list of variants, none of them not contained in the list
sub variants {
  my (%v,%chr,%str);
  foreach ( @_ ) {
    $chr{$_} = 1 foreach (split //);
    $str{$_} = 1;
  }
  
  foreach my $i ( keys %chr ) {
    $v{$i} = 1 unless exists $str{$i};
    foreach my $j ( keys %chr ) {
      $v{$i.$j} = 1 unless exists $str{$i.$j};
      $v{$j.$i} = 1 unless exists $str{$j.$i};
    }
  }
  
  foreach ( @_ ) {
  
    my @c = split //;
    fisher_yates_shuffle(\@c);
    my $w = join '', @c;
    $v{$w} = 1 unless exists $str{$w};
    
    push @c, $c[0];
    fisher_yates_shuffle(\@c);
    my $w2 = join '', @c;
    $v{$w2} = 1 unless exists $str{$w2};
    
  }
  
  return sort keys %v;
}


