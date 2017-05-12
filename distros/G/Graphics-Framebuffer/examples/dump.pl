#!/usr/bin/perl

# This is used as a diagnostic to send to the module author

use strict;

use Data::Dumper;
use Graphics::Framebuffer;
$Data::Dumper::Sortkeys = 1;
my $dev = 0;
$dev    = $ARGV[0] if (scalar(@ARGV));
print "Using /dev/fb$dev\n";
sleep 1;
if (open(my $FILE,'>','dump.log')) {
    eval {
        my $fb = Graphics::Framebuffer->new('SHOW_ERRORS' => 1, 'FB_DEVICE' => "/dev/fb$dev");
        $fb->cls();

        my $copy = $fb;

        delete($copy->{'SCREEN'});
        foreach my $name (sort(keys %{$copy})) {
            unless (ref($copy->{$name}) =~ /Imager|threads|GLOB|ARRAY|HASH|SUB/i) {
                print FILE "$name = " . $copy->{$name} . "\n";
            }
        }
        print $FILE '=' x 79 . "\n";
        print $FILE Dumper($copy);
    };
    if ($@) {
        print $FILE "\nCRASH\n\n$@\n";
    }
    close($FILE);
}

=head1 NAME

Framebuffer Information Dump

=head1 DESCRIPTION

This script is used to help the author diagnose (and fix) any problems you may be having with the Graphics::Framebuffer module

It creates a file called B<dump.log> in the same directory.  Please send this file as requested by the author.

=head1 SYNOPSIS

 perl dump.pl [frambuffer_number]

=cut
