#!/usr/bin/perl
# Name: test1.pl
# draws a curve in the X window
# This file is a test file of Plotter.pm perl module
#
# Piotr Klaban <makler@man.torun.pl>
# Date: Mar 15 1999

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

$maxorder = 10;

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}

use Graphics::Plotter qw(parampl);

$loaded = 1;
print "ok 1\n";

open(NULL,"> /dev/null") || die "/dev/null: $!";

Graphics::Plotter::warning_handler(\&warning);
parampl ("VANISH_ON_DELETE", "yes");
parampl ("PAGESIZE", "a4");

$k = (defined $ENV{"DISPLAY"}) ?
	Graphics::Plotter::X->new(STDIN,NULL,STDERR) :
	Graphics::Plotter::PS->new(STDIN,NULL,STDERR);

if ($k->openpl() < 0) {
	die "Could not create plotter: $!\n";
}

$k->fspace(0.0,0.0,1000.0,1000.0);
$k->fmove(500.0, 500.0);
$k->alabel("c","c","Bill Gosper's \"C\" curve\n"); # issue warning
$k->flinewidth((defined $ENV{"DISPLAY"}) ? 0 : 0.25);
$k->pencolorname("red");
$k->erase();
$k->fmove(600.0,300.0);
$k->flinedash([10,4,30,2],0);
&draw_c_curve($k,0.0,400.0,0);
$k->endpath();
if ($k->closepl() < 0) {
	die "closepl: $!\n";
}
sleep 3 if defined $ENV{"DISPLAY"};

print "ok 3\n";

close(NULL);

sub draw_c_curve {
	my($p,$dx,$dy,$order) = @_;
	if ($order >= $maxorder) {
		$p->fcontrel($dx,$dy);
	} else {
		&draw_c_curve($p, 0.5 * ($dx - $dy),0.5*($dx+$dy),$order + 1);
		&draw_c_curve($p, 0.5 * ($dx + $dy),0.5*($dy-$dx),$order + 1);
	}
}

sub warning
{
	print "ok 2\n";
	# print "WARNING: @_\n";
}

