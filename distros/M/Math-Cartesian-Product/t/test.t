use Test::More tests=>88;

use Math::Cartesian::Product;
use warnings FATAL => qw(all);
use strict;

# 0

 {ok 0 == cartesian {};
  ok 1 == cartesian {1};

   {my $r = cartesian {1}; ok 1 == $r;}                                         # Called in scalar context
   {my @r = cartesian {1}; ok 0 == length(join ",", map {join '', @$_} @r)}     # Called in array context
 }

# 3

 {my $a = '';

  ok 0 == cartesian {0}               [qw(a b c)];
  ok 1 == cartesian {shift() eq 'b'}  [qw(a b c)];
  ok 2 == cartesian {shift() ne 'b'}  [qw(a b c)];
  ok 3 == cartesian {$a .= "@_\n"; 1} [qw(a b c)];
  ok $a eq << "end";
a
b
c
end

   {my $r = cartesian {1} [qw(a b c)]; ok 3 == $r}                                    # Called in scalar context
   {my @r = cartesian {1} [qw(a b c)]; ok "a,b,c" eq join ",", map {join '', @$_} @r} # Called in array context
 }

# 3*2

 {my $a = '';
  ok 6 == cartesian {$a .= "@_\n"; 1} [qw(a b c)], [1,2];
  ok $a eq << "end";
a 1
a 2
b 1
b 2
c 1
c 2
end

   {my $r = cartesian {1} [qw(a b c)], [1,2]; ok 6 == $r}                                                 # Called in scalar context
   {my @r = cartesian {1} [qw(a b c)], [1,2]; ok "a1,a2,b1,b2,c1,c2" eq join ",", map {join '', @$_} @r}  # Called in array context
 }

# 3*2*0

 {my $a = '';

  ok 0 == cartesian {$a .= "@_\n"; 1} [qw(a b c)], [1,2], [];
  ok $a eq << "end";
end

   {my $r = cartesian {1} [qw(a b c)], [1,2], []; ok 0 == $r}                                      # Called in scalar context
   {my @r = cartesian {1} [qw(a b c)], [1,2], []; ok 0 == length(join ",", map {join '', @$_} @r)} # Called in array context
 }

# 2*2*2*2

 {my $a = '';
  my $b = [qw(a b)];
  ok 16 == cartesian {$a .= "@_\n"; 1} $b,$b,$b,$b;
  ok $a eq << "end";
a a a a
a a a b
a a b a
a a b b
a b a a
a b a b
a b b a
a b b b
b a a a
b a a b
b a b a
b a b b
b b a a
b b a b
b b b a
b b b b
end
 }

# (2*2)*(2*2)

 {my $a = '';
  my $b = [qw(a b)];
  my $c = [cartesian {$a .= "@_\n"; 1} $b,$b];
  ok 4 == @$c;
  ok $a eq << "end";
a a
a b
b a
b b
end

  my $d = '';
  ok 16 == cartesian {$d .= "@_\n"; 1} $c, $c;
  ok $d eq << "end";
a a a a
a a a b
a a b a
a a b b
a b a a
a b a b
a b b a
a b b b
b a a a
b a a b
b a b a
b a b b
b b a a
b b a b
b b b a
b b b b
end

  ok 8 == cartesian {$_[1] eq 'a'} $c, $c;

  {my $r = cartesian {my @a = reverse      @_; "@a" eq "@_"} $c, $c; ok 4 == $r}
  {my @r = cartesian {my @a = reverse      @_; "@a" eq "@_"} $c, $c; ok "aaaa,abba,baab,bbbb"      eq join ",", map {join '', @$_} @r}
  {my @r = cartesian {my @a = sort         @_; "@a" eq "@_"} $c, $c; ok "aaaa,aaab,aabb,abbb,bbbb" eq join ",", map {join '', @$_} @r}
  {my @r = cartesian {my @a = reverse sort @_; "@a" eq "@_"} $c, $c; ok "aaaa,baaa,bbaa,bbba,bbbb" eq join ",", map {join '', @$_} @r}
 }

# (3*3)*3*(3*3)

 {my $a = '';
  my $b = [qw(a b c)];
  my $c = [cartesian {$a .= "@_\n"; 1} $b,$b];
  ok 9 == @$c;
  ok $a eq << "end";
a a
a b
a c
b a
b b
b c
c a
c b
c c
end

  ok 81 == cartesian {$_[1] eq 'a'} $c, $b, $c;

  {my $r = cartesian {my @a = reverse      @_; "@a" eq "@_"} $c, $b, $c; ok 27 == $r}
  {my @r = cartesian {my @a = reverse      @_; "@a" eq "@_"} $c, $b, $c; ok "aaaaa,aabaa,aacaa,ababa,abbba,abcba,acaca,acbca,accca,baaab,babab,bacab,bbabb,bbbbb,bbcbb,bcacb,bcbcb,bcccb,caaac,cabac,cacac,cbabc,cbbbc,cbcbc,ccacc,ccbcc,ccccc" eq join ",", map {join '', @$_} @r}
  {my @r = cartesian {my @a = sort         @_; "@a" eq "@_"} $c, $b, $c; ok "aaaaa,aaaab,aaaac,aaabb,aaabc,aaacc,aabbb,aabbc,aabcc,aaccc,abbbb,abbbc,abbcc,abccc,acccc,bbbbb,bbbbc,bbbcc,bbccc,bcccc,ccccc"                                     eq join ",", map {join '', @$_} @r}
  {my @r = cartesian {my @a = reverse sort @_; "@a" eq "@_"} $c, $b, $c; ok "aaaaa,baaaa,bbaaa,bbbaa,bbbba,bbbbb,caaaa,cbaaa,cbbaa,cbbba,cbbbb,ccaaa,ccbaa,ccbba,ccbbb,cccaa,cccba,cccbb,cccca,ccccb,ccccc"                                     eq join ",", map {join '', @$_} @r}
 }

# 2**8

 {my $b = ['0', '1'];
  my @c = cartesian {my @r = reverse @_; "@r" eq "@_"} map {$b} 1..8;
  ok 16 == @c;
  my $c = join "\n", map {join '', @$_} @c;
  my $r = << "end"; chomp($r);
00000000
00011000
00100100
00111100
01000010
01011010
01100110
01111110
10000001
10011001
10100101
10111101
11000011
11011011
11100111
11111111
end
  ok $c eq $r;
 }

# 40*40*40*40

 {my $a = [1..40];
  ok 2_560_000 == cartesian {1} $a,$a,$a,$a;
 }

# Tests from Philipp Rumpf

# The empty product contains one element, the empty list

 {my $a = '';
  ok 1 ==  cartesian { $a .= "@_\n" };
  ok $a eq "\n";
 }

 {ok 0 ==  @{[cartesian {1}]->[0]};
  ok defined [cartesian {1}]->[0];
  ok ref([cartesian {1}]->[0]) =~ /Math::Cartesian::Product/;
  ok defined([cartesian {1}]->[0]);
 }

# Including the empty set in the product list produces the empty set

 {my $a = '';
  ok 0 == cartesian { $a .= "@_\n" } [];
  ok $a eq '';
 }

 {my $a = '';
  ok 0 == cartesian { $a .= "@_\n" } [], [];
  ok $a eq '';
 }

 {my $a = '';
  ok 0 == cartesian { $a .= "@_\n" } [], [], [];
  ok $a eq '';
 }
 {my $a = '';
  ok 0 == cartesian { $a .= "@_\n" } [1,2,3], [];
  ok $a eq '';
 }

 {my $a = '';
  ok 0 == cartesian { $a .= "@_\n" } [], [1,2,3];
  ok $a eq '';
 }

 {my $a = '';
  ok 0 == cartesian { $a .= "@_\n" } [], [1,2,3], [];
  ok $a eq '';
 }


# Cartesian products split, so the cartesian product of (@a,@b) can be
# achieved by taking the cartesian product of @a inside the cartesian
# product of @b.

 {my @a = ([1,2]);
  my @b = ([3,4]);

  my $a = '';
  ok 2 == cartesian { my @c = @_; cartesian { my @d = (@c, @_); $a .= "@d\n"} @b } @a;

  my $b = '';
  ok 4 == cartesian { $b .= "@_\n"} @a, @b;

  ok $a eq $b;
 }

# Cartesian products split even when the first list is empty

 {my @a = ();
  my @b = ([2,3]);

  my $a = '';
  ok 1 == cartesian { my @c = @_; cartesian { my @d = (@c, @_); $a .= "@d\n"} @b } @a;

  my $b = '';
  ok 2 == cartesian { $b .= "@_\n"} @a, @b;

  ok $a eq $b;
 }

# Cartesian products split even when the second list is empty

 {my @a = ([1,2]);
  my @b = ();

  my $a = '';
  ok 2 == cartesian { my @c = @_; cartesian { my @d = (@c, @_); $a .= "@d\n"} @b } @a;

  my $b = '';
  ok 2 == cartesian { $b .= "@_\n"} @a, @b;

  ok $a eq $b;
 }

# Exponentiation can be performed using the cartesian product

 {my @a = ([1,2]);
  ok 2**$_ == cartesian {1} ((@a) x $_) for 0..20
 }
