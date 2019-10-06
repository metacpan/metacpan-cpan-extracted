#!perl

use 5.010;
use strict;
use warnings;

use Data::Dumper;
use English qw( -no_match_vars );
use Scalar::Util qw(looks_like_number weaken);
use Getopt::Long;

use Test::More tests => 4;

use MarpaX::Hoonlint;

my @tests = (
    ['hoons/examples/fizzbuzz.hoon', 't/examples.d/fizzbuzz.lint.out', 'suppressions/examples.suppressions'],
    ['hoons/examples/sieve_b.hoon', 't/examples.d/sieve_b.lint.out', 'suppressions/examples.suppressions'],
    ['hoons/examples/sieve_k.hoon', 't/examples.d/sieve_k.lint.out', 'suppressions/examples.suppressions'],
    ['hoons/examples/toe.hoon', 't/examples.d/toe.lint.out', 'suppressions/examples.suppressions'],
);

local $Data::Dumper::Deepcopy    = 1;
local $Data::Dumper::Terse    = 1;

## no critic (InputOutput::RequireBriefOpen)
open my $original_stdout, q{>&STDOUT};
## use critic

sub save_stdout {
    my $save = '';
    my $save_ref = \$save;
    close STDOUT;
    open STDOUT, q{>}, $save_ref;
    return $save_ref;
} ## end sub save_stdout

sub restore_stdout {
    close STDOUT;
    open STDOUT, q{>&}, $original_stdout;
    return 1;
}

sub slurp {
    my ($fileName) = @_;
    local $RS = undef;
    my $fh;
    open $fh, q{<}, $fileName or die "Cannot open $fileName";
    my $file = <$fh>;
    close $fh;
    return \$file;
}

sub parseReportItems {
    my ( $config, $reportItems ) = @_;
    my $fileName       = $config->{fileName};
    my %itemHash       = ();
    my %unusedItemHash = ();

    my $itemError = sub {
        my ( $error, $line ) = @_;
        return qq{Error in item file "$fileName": $error\n}
          . qq{  Problem with line: $line\n};
    };

  ITEM: for my $itemLine ( split "\n", ${$reportItems} ) {
        my $rawItemLine = $itemLine;
        $itemLine =~ s/\s*[#].*$//;   # remove comments and preceding whitespace
        $itemLine =~ s/^\s*//;        # remove leading whitespace
        $itemLine =~ s/\s*$//;        # remove trailing whitespace
        next ITEM unless $itemLine;
        my ( $thisFileName, $lc, $policy, $subpolicy, $message ) = split /\s+/, $itemLine, 5;
        return undef, $itemError->( "Problem in report line", $rawItemLine )
          if not $thisFileName;

        return undef,
          $itemError->( qq{Malformed line:column in item line: "$lc"},
            $rawItemLine )
          unless $lc =~ /^[0-9]+[:][0-9]+$/;
        my ( $line, $column ) = split ':', $lc, 2;
        $itemError->( qq{Malformed line:column in item line: "$lc"}, $rawItemLine )
          unless Scalar::Util::looks_like_number($line)
          and Scalar::Util::looks_like_number($column);
        next ITEM unless $thisFileName eq $fileName;

        # We reassemble line:column to "normalize" it -- be indifferent to
        # leading zeros, etc.
        my $lcTag = join ':', $line, $column;
        $itemHash{$lcTag}{$policy}{$subpolicy}       = $message;
        $unusedItemHash{$lcTag}{$policy}{$subpolicy} = 1;
    }
    return \%itemHash, \%unusedItemHash;
}

my $contextSize = 0;
my $displayDetails = 1;

for my $testData (@tests) {
    my ( $fileName, $output, $suppressionFileName ) = @{$testData};

    # Config is essentially a proto-lint-instance, containing all
    # variables which are from some kind of "environment", which
    # the lint instance must treat as a constant.  From the POV
    # of the lint instance, the config is a global, but this is
    # not necessarily the case.
    #
    # The archetypal example of a config is the "environment"
    # created by the invocation of the `hoonlint` Perl script
    # which contains information taken from the command line
    # arguments and read from various files.

    my %config = ();

    $config{fileName} = $fileName;

    $config{topicLines}   = {};
    $config{mistakeLines} = {};

    my $shortPolicyName = 'Test::Whitespace';
    {
        my $fullPolicyName = 'MarpaX::Hoonlint::Policy::' . $shortPolicyName;

        # "require policy name" is a hack until I create the full directory
        # structure required to make this a Perl module
        my $eval_ok = eval "require $fullPolicyName";
        die $EVAL_ERROR if not $eval_ok;
      $config{policies} = { $shortPolicyName => $fullPolicyName };
    }

    my $pSuppressions;
    {
        my @suppressions = ${ slurp($suppressionFileName) };
        $pSuppressions = \( join "", @suppressions );
    }

    my ( $suppressions, $unusedSuppressions ) =
      parseReportItems( \%config, $pSuppressions );
    $config{suppressions}       = $suppressions;
    $config{unusedSuppressions} = $unusedSuppressions;

    my $pHoonSource = slurp($fileName);

    $config{pHoonSource} = $pHoonSource;
    $config{contextSize} = $contextSize;
  SET_DISPLAY_DETAILS: {
        if ( not defined $displayDetails ) {
            $config{displayDetails} = $contextSize >= 1 ? 1 : 0;
            last SET_DISPLAY_DETAILS;
        }
        $config{displayDetails} = $displayDetails;
    }

    my $actual_output = save_stdout();

    MarpaX::Hoonlint->new( \%config );

    restore_stdout();

    Test::More::is( ${$actual_output}, '');

}
