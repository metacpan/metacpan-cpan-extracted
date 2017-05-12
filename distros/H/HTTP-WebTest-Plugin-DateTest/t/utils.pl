#!/usr/bin/perl -w

# $Id: utils.pl,v 1.2 2002/12/26 21:16:39 m_ilya Exp $
# based on utils.pl 1.4 2002/02/21 01:02:10 m_ilya

# some subs common for all tests are defined here

use strict;
use Algorithm::Diff qw(diff);

# just reads file and returns its content
sub read_file {
    my $file = shift;
    my $dont_die = shift;

    local *FILE;
    if(open FILE, "< $file") {
	my $data = join '', <FILE>;
	close FILE;

	return $data;
    } else {
	die "Can't open file '$file': $!" unless $dont_die;
    }

    return '';
}

# just writes some dat into file
sub write_file {
    my $file = shift;
    my $data = shift;

    local *FILE;
    open FILE, "> $file" or die "Can't open file '$file': $!";
    print FILE $data;
    close FILE;
}

# runs webtest and compares its output with file
sub check_webtest {
    my %param = @_;

    my $webtest = $param{webtest};
    my $tests = $param{tests};
    my $opts = $param{opts} || {};

    my $output = '';

    $webtest->run_tests($tests, { %$opts, output_ref => \$output });
    compare_output(%param, output_ref => \$output);
}

sub compare_output {
    my %param = @_;

    my $check_file = $param{check_file};
    my $output2 = ${$param{output_ref}};

    my $output1 = read_file($check_file, 1);
    print_diff($output1, $output2);
    ok(($output1 eq $output2) or defined $ENV{TEST_FIX});

    if(defined $ENV{TEST_FIX} and $output1 ne $output2) {
	# special mode for writting test report output files

	write_file($check_file, $output2);
    }
}

# print diff of outputs
sub print_diff {
    my $output1 = shift;
    my $output2 = shift;

    my @diff = diff([split /\n/, $output1], [split /\n/, $output2]);

    for my $hunk (@diff) {
	for my $diff_str (@$hunk) {
	    print "@$diff_str\n";
	}
    }
}

1;
