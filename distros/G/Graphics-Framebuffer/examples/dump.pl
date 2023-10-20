#!/usr/bin/env perl

# This is used as a diagnostic tool to send to the module author

use strict;

use Graphics::Framebuffer;
use Data::Dumper;
eval { # Data::Dumper::Simple is preferred.  Try to load it without dying.
	require Data::Dumper::Simple;
	Data::Dumper::Simple->import();
	1;
};

$Data::Dumper::Sortkeys = 1; $Data::Dumper::Purity = 1;

BEGIN {
    our $VERSION = '2.02';
}

if (open(my $FILE, '>', 'dump.log')) {
	print $FILE "Directory of available framebuffers\n" . '=' x 79 . "\n";
	my $temp = `ls -l /dev/fb* 2> /dev/null`;
	chomp($temp);
	$temp ||= 'NONE';
	print $FILE "/dev/fb* ->\n    $temp\n";
	$temp = `ls -l /dev/fb/* 2> /dev/null`;
	chomp($temp);
	$temp ||= 'NONE';
	print $FILE "/dev/fb/* ->\n    $temp\n";
	$temp = `ls -l /dev/graphics/fb/* 2> /dev/null`;
	chomp($temp);
	$temp ||= 'NONE';
	print $FILE "/dev/graphics/fb/* ->\n    $temp\n";
	foreach my $path (qw( /dev/fb /dev/fb/ /dev/graphics/fb )) {
		foreach my $dev (0 .. 31) {
			if (-e "$path$dev") {
				dumpit($FILE,"$path$dev");
			}
		}
	}
	close($FILE);
}

exec('reset');

sub dumpit {
	my $FILE = shift;
    my $path = shift;
	print $FILE '=' x 79,"\nUsing $path\n",'-' x 79,"\n";
	eval {
		my $fb = Graphics::Framebuffer->new('SHOW_ERRORS' => 0, 'FB_DEVICE' => $path, 'RESET' => 0, 'SPLASH' => 0);

		my $copy = $fb;

		delete($copy->{'SCREEN'});
		print $FILE Data::Dumper->Dump([$copy],["FB-$path"]);
	};
	if ($@) {
		print "\nCRASH LOGGED\n\n$@\n";
		print $FILE "\nCRASH\n\n$@\n";
	}
}

=head1 NAME

Framebuffer Information Dump

=head1 DESCRIPTION

This script is used to help the author diagnose (and fix) any problems you may be having with the Graphics::Framebuffer module.  It finds all available framebuffers.

It creates a file called B<dump.log> in the same directory.  Please send this file as requested by the author.

=head1 SYNOPSIS

 perl dump.pl

=cut
