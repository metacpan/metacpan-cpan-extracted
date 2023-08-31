#!/usr/bin/env perl

# This is used as a diagnostic to send to the module author

use strict;

use Graphics::Framebuffer;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1; $Data::Dumper::Purity = 1;

BEGIN {
    our $VERSION = '2.01';
}

unlink('dump.log') if (-e 'dump.log');

foreach my $path (qw( /dev/fb /dev/fb/ /dev/graphics/fb )) {
    foreach my $dev (0 .. 31) {
        if (-e "$path$dev") {
            dumpit("$path$dev");
        }
    }
}

exec('reset');

sub dumpit {
    my $path = shift;
    if (open(my $FILE, '>>', 'dump.log')) {
        print $FILE '=' x 79,"\nUsing $path\n",'-' x 79,"\n";
        eval {
            my $fb = Graphics::Framebuffer->new('SHOW_ERRORS' => 0, 'FB_DEVICE' => $path, 'RESET' => 0);
            
            my $copy = $fb;
            
            delete($copy->{'SCREEN'});
            print $FILE Data::Dumper->Dump([$copy],["FB-$path"]);
        };
        if ($@) {
            print "\nCRASH LOGGED\n\n$@\n";
            print $FILE "\nCRASH\n\n$@\n";
        }
        close($FILE);
    }
}

=head1 NAME

Framebuffer Information Dump

=head1 DESCRIPTION

This script is used to help the author diagnose (and fix) any problems you may be having with the Graphics::Framebuffer module

It creates a file called B<dump.log> in the same directory.  Please send this file as requested by the author.

=head1 SYNOPSIS

 perl dump.pl

=cut
