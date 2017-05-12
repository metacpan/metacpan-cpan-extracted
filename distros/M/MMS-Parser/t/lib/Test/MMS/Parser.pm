# vim: filetype=perl :
package Test::MMS::Parser;
use Test::More;
use strict;
use warnings;
use Exporter;

our @ISA = 'Exporter';
our @EXPORT = qw(
   make_checker numerify_range check_cases char_range immediate
   create_generator destroy_generator check_generator
);

sub make_checker {
   my ($parser, $subname) = @_;
   return sub {
      my ($input, $expected_output, $msg) = @_;
      $msg = $subname unless $msg;
      my $output = $parser->$subname($input);
      return ::is_deeply($output, $expected_output, $msg);
   };
} ## end sub make_checker

sub check_cases {
   my ($parser, $tests_ref) = @_;
   while (my ($subname, $spec) = each %$tests_ref) {
      my $checker = make_checker($parser, $subname);
      foreach my $test (@$spec) {

         #   diag("$subname\t@$test\n");
         $checker->(@$test);
      }
   } ## end while (my ($subname, $spec...
   return;
} ## end sub check_cases

sub char_range {
   my $checker = make_checker(@_[0, 1]);
   my %allowed = map { $_ => 1 } @_[2 .. $#_];
   foreach my $ord (0 .. 255) {
      my $c = chr $ord;
      my $m = "$_[1](chr($ord))" . ($allowed{$ord} ? '' : ' (neg)');
      my $e = $allowed{$ord} ? $c : undef;
      $checker->($c, $e, $m);
   }
   return;
} ## end sub char_range

sub numerify_range {
   map { ord $_; } @_;
}

sub immediate {
   my $parser = shift;
   my ($name, $ord, $expected) = @_;
   $expected = $name unless defined $expected;

   my $checker = make_checker($parser, $name);
   $checker->(chr($ord), $expected, "$name(chr($ord)) is $expected");
   foreach my $o (0 .. 255) {
      next if $ord == $o;
      $checker->(chr($o), undef, "$name(chr($o)) (neg)");
   }

   return;
}

"True value at the end of the module";
