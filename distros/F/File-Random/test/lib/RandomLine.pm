package RandomLine;
use base qw/Test::Class/;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp qw/tempfile/;
use Set::Scalar;
use Test::Warn;
use Test::ManyParams;

use File::Random qw/random_line/;

use constant LINES => <<'EOF';
Random
Lines
can
contain
randomly
appearing things like
PI = 3.1415926535
but of course that's not neccessary
EOF

use constant WRONG_PARAMS => (undef, '', '&');

use constant SAMPLE_SIZE => 200;

sub fill_tempfile : Test(setup) {
    my $self = shift;
    (my $normal_fh, $self->{normal_file}) = tempfile();
    (undef,         $self->{empty_file})  = tempfile();
    print $normal_fh LINES;
}

sub clear_tempfile : Test(teardown) {
    my $self = shift;
    close $self->{'normal_file'};
    close $self->{'empty_file'};
}

sub empty_file_returns_undef : Test(1) {
    my $self = shift;
    is random_line($self->{empty_file}), undef, "random_file( Empty file )";
}

sub lines_are_the_expected_ones : Test(1) {
    my $self = shift;
    my $exp = Set::Scalar->new( map {"$_\n"} split /\n/, LINES);
    my $got = Set::Scalar->new();
    $got->insert( scalar random_line($self->{normal_file}) ) for (1 .. SAMPLE_SIZE);
    is $got, $exp, "random_line( Normal File )";
}

sub multiple_lines_are_the_expected_ones : Test(2) {
    my $self = shift;
    my $exp = Set::Scalar->new( map {"$_\n"} split /\n/, LINES);
    my $got = Set::Scalar->new();
    $got->insert( random_line($self->{normal_file},3) ) for (1 .. SAMPLE_SIZE()/3);
    is $got, $exp, "random_line( Normal File, 3 ) [expected files]";
    $got->clear;
    for (1 .. SAMPLE_SIZE()/3) {
        my ($line1, $line2, $line3) = random_line($self->{normal_file});
        $got->insert($line1, $line2, $line3);
    }
    is $got, $exp, '($line1, $line2, $line3) = random_line $fname  [expected files]';
}

sub multiple_lines_are_the_expected_ones_random_line_with_sample_size : Test(1) {
    my $self = shift;
    my $exp = Set::Scalar->new( map {"$_\n"} split /\n/, LINES);
    my $got = Set::Scalar->new(random_line($self->{normal_file}, SAMPLE_SIZE()));
    is $got, $exp, "random_line( Normal File, 3 ) [expected files]";
}

sub get_really_lines : Test(8) {
    my $self = shift;
    SIZE_IS_KNOWN: {
        my ($line1, $line2, $line3) = random_line($self->{normal_file},3);
        ok defined($line1), "1st returned line of random_line should be defined";
        ok defined($line2), "2nd returned line of random_line should be defined";
        ok defined($line3), "3rd returned line of random_line should be defined";
        ok( ($line1 ne $line2 or $line1 ne $line3),
            "3 random lines should be a bit different" );
    }

    SIZE_IS_UNKNOWN: {
        my ($line1, $line2, $line3) = random_line($self->{normal_file});
        ok defined($line1), "1st returned line of random_line should be defined";
        ok defined($line2), "2nd returned line of random_line should be defined";
        ok defined($line3), "3rd returned line of random_line should be defined";
        ok( ($line1 ne $line2 or $line1 ne $line3),
            "3 random lines should be a bit different" );
    }
}

sub warns_if_called_with_line_nr_in_scalar_context : Test(1) {
    my $self = shift;
    warning_like {scalar random_line($self->{normal_file},3)}
                 {carped => qr/called in scalar context/},
                 "should give a warning random_line(fname,3) is called in scalar context";
}

sub warns_if_zero_random_lines : Test(1) {
    my $self = shift();
    warning_like { (random_line($self->{normal_file},0)) }
                 {carped => qr/0 random lines/},
                 "should give a warning random_line(fname,0)";
}

sub warns_not_if_called_in_list_context_without_line_nr_specification : Test(1) {
    my $self = shift();
    warnings_are { [ random_line($self->{normal_file}) ] }
                 [],
                 "should give a warning if random_line(fname) in list context";
}

sub nr_of_lines_greater_than_lines_in_file : Test(2) {
    my $self = shift;
    my @line = random_line($self->{normal_file},100);
    ok @line ==  100, "random_line(file, 100) should return a list of 100 elements";
    all_ok {defined($_[0])} \@line, "random_line(file, 100) - all lines should be defined";
}

sub wrong_parameters : Test(5) {
    my $self = shift;
    no warnings;    # $_ shall be undefined for a moment !
    foreach (WRONG_PARAMS) {
        dies_ok(sub {random_line($_)}, "random_line( '$_' ) should die");
        next unless defined;
        dies_ok(sub {(random_line($self->{normal_file},$_))},           
               "random_line(fname, '$_' ) should die");
    }
    use warnings;   # warnings back
}

1;
