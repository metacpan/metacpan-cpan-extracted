# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..113\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Math::Base::Convert qw(oct basemap);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

sub ok {
  print "ok $test\n";
  ++$test;
}

$test = 2;

sub equal {
  my($a,$b) = @_;
  if ($a.$b =~ /\D/) {
    return $a eq $b;
  } else {
    return $a == $b;
  }
}

# test 2	user array returned
my @userary = reverse (0..9);
my $hsh = basemap(\@userary);
my $exp = 'HASH';
# check what returned
print "got: '". ref $hsh ."', exp: '$exp'\nnot "
	unless ref $hsh eq $exp;
&ok;

# test 3	size
my @keys = sort keys %$hsh;
my $len = @keys;
print "length not 10, got: $len\nnot "
	unless $len == 10;
&ok;

# test 4 - 13	check for correct map, sum of key + val equal 9
while (my ($key,$val) = each %$hsh) {
  print "mismatched key/val pair '$key, $val'\nnot "
	unless $key + $val == 9;
  &ok;
}

# test 14	check hex, which is special
$hsh = basemap(16);
# check what returned
print "got: '". ref $hsh ."', exp: '$exp'\nnot "
	unless ref $hsh eq $exp;
&ok;

# test 15	size, 22 = 16 + 6 extra digits
@keys = sort keys %$hsh;
$len = @keys;
print "length not 22, got: $len\nnot "
	unless $len == 22;
&ok;

# test 16 - 59	content
my @hex = qw( 0 1 2 3 4 5 6 7 8 9 A B C D E F a b c d e f);
foreach(0..$#hex) {
  print "key mismatch got: $keys[$_], exp: $hex[$_]\nnot "
	unless equal($keys[$_],$hex[$_]);
  &ok;

  my $val = $keys[$_] =~ /[a-f]/ ? $_ -6 : $_;
  print "index value mismatch got: $hsh->{$keys[$_]}, exp: $val\nnot "
	unless $hsh->{$keys[$_]} == $val;
  &ok;
}

# test 60 - 113	check array specifier variants
foreach(8,oct,'oct') {
  $hsh = basemap($_);
# check what returned
  print "got: '". ref $hsh ."', exp: '$exp'\nnot "
	unless ref $hsh eq $exp;
  &ok;

# size
  @keys = sort keys %$hsh;
  $len = @keys;
  print "octal hash length not 8, got: $len\nnot "
	unless $len == 8;
  &ok;

# content;
  foreach(0..$#keys) {	# there are eight in order
    print "index '$_' does not match key '$keys[$_]'\nnot "
	unless $_ == $keys[$_];
    &ok;

    print "index '$_' does not match value '$hsh->{$keys[$_]}'\nnot "
	unless $_ == $hsh->{$keys[$_]};
    &ok;
  }
}

  