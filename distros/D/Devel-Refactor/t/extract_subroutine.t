#!/usr/bin/perl
# $Header: $
#

use strict;
use Getopt::Long;
use Test::More tests => 3;
use FindBin qw($Bin);  # Where was this script installed?
use lib "$Bin/.."; # Add .. to @INC;

use Refactor;

## Parse options
my ($verbose);
GetOptions( 
            "verbose"     => \$verbose,
          );


my $code = <<'eos';
  my @results;
  my %hash;
  my $date = localtime;
  $hash{foo} = 'value 1';
  $hash{bar} = 'value 2';
  for my $loopvar (@array) {
     print "Checking $loopvar\n";
     push @results, $hash{$loopvar} || '';
  }

eos

my $refactory = Devel::Refactor->new($verbose);
my ($new_sub_call,$new_code) = $refactory->extract_subroutine('newSub',$code);
if ($verbose) {
    diag "new sub call:\n####\n$new_sub_call\n####";
    diag "new code:\n####\n$new_code\n####";
    diag "Scalars:\n  " , join "\n  ", $refactory->get_scalars, "\n";
    diag "Arrays: \n  ", join "\n  ", $refactory->get_arrays, "\n";
    diag "Hashes:\n  ",join "\n  ",  $refactory->get_hashes, "\n";
}

# Check return values
my $expected_result = 'my ($date, $hash, $results) = newSub (\@array);';
my $result = $new_sub_call;
chop $result; # remove newline, just to make diagnostic message prettier.
ok ($result eq $expected_result, 'New subroutine signature') or
  diag("Expected '$expected_result'\ngot      '$result' instead");

eval $new_code;
ok ( $@ eq '', 'eval extracted subroutine declaration') or diag "New code failed to eval\n####\n$new_code\n####\n$@";

$code = <<'eos';
    my @array = qw( foo bar baz );
eos
$code .=  $new_sub_call;
$code .= <<'eos';
    if ($verbose) {
        diag "\$date: $date";
        diag "\@results: ", join ', ', @$results;
    }
eos
diag "About to eval code\n####\n$code\n####" if $verbose;
eval $code;

ok ( $@ eq '', 'run extracted subroutine') or diag "Error eval'ing '$code': $@";

__END__
