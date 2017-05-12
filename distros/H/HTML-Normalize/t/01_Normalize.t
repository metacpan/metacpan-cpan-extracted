use strict;
use warnings;

use Test::More;
use HTML::TreeBuilder;

=head1 NAME

HTML::Normalize test suite

=head1 DESCRIPTION

In conjunction with *.NorTR? and *.NorFR? files this code exercises
HTML::Normalize. NorT files are expected to succeed and NorF files are expected
to fail. Both file types are text files. A trailing R indicates that the raw
rendered output should be compared with the reference HTML rather than parsing
the reference HTML and comparing the rendered reference HTML with the processed
and rendered given HTML.

Test files are initially placed in the test folder. When the test succeeds the
file is moved to the OkTests subfolder. OkTests folder tests may be omitted by
passing -d on the command line.

Generally only tests in the test folder should fail. If the OkTests start
failing we have broken something.

=head2 Test file format

Test files consist of three sections. The first section comprises options to be
passed to Normalize. Theses lines must all have a - as the first character. The
options section is optional.

The second section comprises the given HTML to be parsed. It is required.

Section two is followed by a section separator of the form:

    <!--expected-->

The section separator must be on a line of its own and the line must not include
leading or trailing white space.

The third section comprises the reference HTML that is the expected result of
rendering the parsed HTML with any options given applied.

=cut

BEGIN {
    use lib 'lib'; # For develpment testing
    plan (tests => 39);
    use_ok ("HTML::Normalize");
}

my $debug = (exists ($ARGV[0]) && $ARGV[0] eq '-d');

my @okFiles;
my @failFiles;
my $extMatch = qr/\.Nor([FT])R?$/;

# Build list of test data files
opendir SCAN, "t";
while (defined ($_ = readdir SCAN)) {
    next if $_ !~ $extMatch;
    my $arg = $1 eq 'T' ? \@okFiles : \@failFiles;
    push @$arg, $_;
}
closedir SCAN;

if (!$debug) {
    opendir SCAN, "t/OkTests";
    while (defined ($_ = readdir SCAN)) {
        next if $_ !~ $extMatch;
        my $arg = $1 ne 'F' ? \@okFiles : \@failFiles;
        push @$arg, "t/OkTests/$_";
    }
    closedir SCAN;
}

# Test the test system file parsing
for my $test (@failFiles) {
    my ($testName) = $test =~ /(\S+)\.\S*$/;
    my $options;
    my $given;
    my $expected;

    ok (!loadTestData ($test, $options, $given, $expected), "Load $test");
}

# Test Normalize
for my $test (@okFiles) {
    my ($testName) = $test =~ /(\S+)\.\S*$/;
    my $rawCompare = $test =~ /R$/;
    my @options;
    my $given;
    my $expected;

    ok (loadTestData ($test, \@options, $given, $expected), "Load $test");
    next if !defined $given || !defined $expected;

    my @params = (-html => $given);

    while (@options) {
        my ($param, $value) = splice @options, 0, 2;

        next unless defined $param;
        $value ||= 0;
        push @params, $param => $value;
    }

    my $rendered = HTML::Normalize->new (@params)->cleanup ();

    if ($rawCompare) {
        is ($rendered, $expected, $testName);
    } else {
        my $root1 = HTML::TreeBuilder->new;
        my $root2 = HTML::TreeBuilder->new;

        $root1->parse_content ($rendered)->elementify ()
          ->delete_ignorable_whitespace ();

        $root2->parse_content ($expected)->elementify ()
          ->delete_ignorable_whitespace ();
        is ($root1->as_HTML (undef, '   ', {}),
            $root2->as_HTML (undef, '   ', {}), $testName);
    }
}

sub loadTestData {
    my $filename = $_[0];
    my $options  = $_[1];
    my $given    = \$_[2];
    my $expected = \$_[3];

    if (!open inFile, '<', $filename) {
        $@ = "Open failed on $filename: $!\n";
        return undef;
    }

    local $/ = "<!--expected-->\n";
    ($$given, $$expected) = <inFile>;
    close inFile;

    $/ = "\n";
    if (!defined $$given) {
        print "Error: Sample HTML missing from test file $filename\n";
        return undef;
    }

    push @$options, ($1, $2) while $$given =~ s/^(-\w+)\s*=\s*(.*?)\n//;

    if (!defined $$expected) {
        print "Error: Reference HTML missing from test file $filename\n";
        return undef;
    }

    chomp $$given if defined $$given;
    return defined $$given && defined $$expected;
}

