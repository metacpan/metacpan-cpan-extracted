#!/usr/bin/perl
# $Header: $
#

use strict;
use Getopt::Long;
use Test::More tests => 73;
#use Test::More qw( no_plan );
use FindBin qw($Bin);  # Where was this script installed?
use lib "$Bin/.."; # Add .. to @INC;
use Data::Dumper;

use Refactor;

## Parse options
my ($verbose);
GetOptions( 
            "verbose"     => \$verbose,
          );


my $refactory = Devel::Refactor->new($verbose);

my ($where,$old_name,$new_name) = ('t/testfile_1.pl','oldSub','newSub');
ok ($refactory->is_perlfile($where),"$where is a perl file");
my $found;
eval { $found = $refactory->rename_subroutine($where,$old_name,$new_name);};
ok ( $found, "Call rename_subroutine with file '$where'") or
    die("Failed: rename_subroutine($where,$old_name,$new_name)");

# Check if we found all expected instances of $old_name in the file
my %file1_expected = (
    11 => q{# We will eventually want to change the name of newSub} . "\n",
    12 => q{my $string = newSub(1,2,3);} ."\n",
    16 => q{my $string2 = newSub ($string,'a','b');} . "\n",
    21 => q{my $string3 = $object->newSub(6,7);} . "\n",
    25 => q{newSub('d','e','f') or die("Couldn't execute newSub: $!");} . "\n",
    29 => 'sub newSub {' . "\n",
);
my @file1_expected_lines = sort keys %file1_expected;

_check_results ($old_name, $where, $found, \@file1_expected_lines, \%file1_expected);

($where,$old_name,$new_name) = ('t','oldSub','newSub');
eval { $found = $refactory->rename_subroutine($where,$old_name,$new_name);};
ok ( $found, "Call rename_subroutine with directory '$where' and depth of 0") or
    die("Failed: rename_subroutine($where,$old_name,$new_name)");

_check_results ($old_name, 't/testfile_1.pl', $found, \@file1_expected_lines, \%file1_expected);

my %file2_expected = (
    15 => '    $self->newSub(@args);' ."\n",
    18 => 'sub newSub {' . "\n",
);
my @file2_expected_lines = sort keys %file2_expected;

_check_results ($old_name, 't/testfile_2.pm', $found, \@file2_expected_lines, \%file2_expected);

my %file3_expected = (
    8 => 'finds this line of text, because it contains newSub, but it shouldn\'t find' . "\n",
);
my @file3_expected_lines = sort keys %file3_expected;

eval { $found = $refactory->rename_subroutine($where,$old_name,$new_name,1);};
ok ( $found, "Call rename_subroutine with directory '$where' and depth of 1") or
    die("Failed: rename_subroutine($where,$old_name,$new_name)");

_check_results ($old_name, 't/testfile_1.pl', $found, \@file1_expected_lines, \%file1_expected);
_check_results ($old_name, 't/testfile_2.pm', $found, \@file2_expected_lines, \%file2_expected);
_check_results ($old_name, 't/test_subdirectory/testfile_3.pod', $found, \@file3_expected_lines, \%file3_expected);


exit;

###############################################################################

sub _check_results {
    my $old_name       = shift;
    my $where          = shift;
    my $found          = shift;
    my $expected_lines = shift;
    my $expected       = shift;

    foreach my $exp_line (@$expected_lines) {
        my $hash = shift @{ $found->{$where} };
        my ( $line_num, $new_line ) = each %$hash;
      SKIP: {
            ok( $line_num, "Find expected line number $exp_line in $where") ||
                skip "Didn't get line_num/new_line pair for $exp_line in $where",2;
            ok( $exp_line == $line_num, "$where line $line_num - find $old_name" )
              || skip "Didn't find expected change in $where line $line_num", 1;
            ok( $new_line eq $expected->{$line_num},
                "$where line $line_num - replacement line looks correct" )
              || diag
              "Expected: '$expected->{$line_num}'\nGot       '$new_line'";
        }
    }
}

__END__
ok ($found == scalar @expected_line_numbers, "Found all $expected_count instances of $old_name") or
	diag "Found $found instances, expected $expected_count", Dumper($changed->{$where});
 
 # Try looking in a directory of files.

($where,$old_name,$new_name,$how_deep) = ('t','oldSub','newSub',1);
eval { $changed = $refactory->rename_subroutine($where,$old_name,$new_name,$how_deep);};
ok ( $changed && ($@ eq ''), "Call rename_subroutine with directory '$where'") or
   diag "$@\n", Dumper($changed);

# TODO: This hash could contain lists of expected line numbers
my %expected_files = ( 't/testfile_1.pl' => 1, 't/testfile_2.pm' => 1);
$found = 0;
my $extra = 0;
foreach my $f (keys %expected_files) {
    $found++ if exists $changed->{$f};
}

foreach my $f (keys %{$changed}) {
    $extra++ unless exists $expected_files{$f};
}

ok ($found == 2, "Found all files.") or
    diag "Found: $found\n", Dumper($changed);
ok ($extra == 0, "No extra files found.") or
    diag "Extra: $extra\n", Dumper($changed);