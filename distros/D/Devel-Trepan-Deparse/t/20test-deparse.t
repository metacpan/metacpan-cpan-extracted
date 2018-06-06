#!/usr/bin/env perl
use warnings; use strict;
use English;
use rlib '.';
use Helper;

my $TREPAN_DIR;
BEGIN {
    $TREPAN_DIR =
	File::Spec->catfile(dirname(__FILE__), '..', 'lib', 'Devel', 'Trepan',
			    'CmdProcessor', 'Command');
}

use rlib $TREPAN_DIR;
use Test::More;

# plan skip_all => "Not ready yet";

if ($OSNAME eq 'MSWin32') {
    plan skip_all => "Strawberry Perl doesn't handle exec well"
} else {
    plan;
}

my $opts = {
    do_test => 1,
    filter => sub{
	my ($got_lines, $correct_lines) = @_;
	my @result = ();
	for my $line (split(/\n/, $got_lines)) {
	    $line =~ s/(^    [A-Z]+) \(0x[a-f0-9]+\)/$1 (0x1234567)/;
	    $line =~ s/(^=>  [A-Z]+) \(0x[a-f0-9]+\)/$1 (0x1234567)/;
	    $line =~ s/SCALAR\(0x[a-f0-9]+\)/SCALAR(0x1234567)/;
	    $line =~ s/at address 0x[a-f0-9]+/code at address 0x1234567/;
	    $line =~ s{^(..) main::\((.+) \@0x([a-f0-9]+)\)}
                      {$1 main::($2 \@0x1234567)};
            # use Enbugger; Enbugger->load_debugger('trepan');
	    # Enbugger->stop() if $line =~ /^op_first/;
	    $line =~ s/^    \top_(first|last|next|sibling|sv)(\s+)(0x[a-f0-9]+)/    \top_$1${2}0x7654321/;
	    $line =~ s/^    \top_type(\s+)(\d+)/    \top_type${1}1955/;
	    $line =~ s/^    \top_private(.+)$/    \top_private 1027/;
	    $line =~ s/# 1: use Devel::Trepan;BEGIN.*$/# 1: use Devel::Trepan;/;

	    $line =~ s/use Devel::Trepan;BEGIN.*$/use Devel::Trepan;/;


	    push @result, $line unless ($line =~ /op_seq/);
	}
	$got_lines = join("\n", @result);
	return ($got_lines, $correct_lines);
    }
};

my $test_prog = File::Spec->catfile(dirname(__FILE__),
				    qw(.. example five.pl));
my $ok = Helper::run_debugger("$test_prog", $TREPAN_DIR,
			      'deparse.cmd', undef, $opts);
is $ok, 0, "Exit code zero";
done_testing;
