#!/usr/bin/env perl 
use strict;
use warnings;

use IO::Buffered;
use Benchmark qw(cmpthese);

my $buffer = new IO::Buffered(Split => qr/\n/);

my $regexp = qr/(.*)\n/;
my $char = qr/\n/;
my $comp = qr/(.*)$char/;
my $str = "hello\n";

my $ref = { comp => $comp };
my %hash = ( comp => $comp );
#cmpthese (-1, {
#    static  => sub { $str =~ $regexp },
#    var     => sub { $str =~ /$regexp/ },
#    replace => sub { $str =~ /(.*)$char/ },
#    comp    => sub { $str =~ $comp },
#    ref     => sub { $str =~ $ref->{comp} },
#    hash    => sub { $str =~ $hash{comp} },
#});

cmpthese (-1, {
    'split'   => sub { 
        $buffer->write("hello\nhello\nhello\n");
        $buffer->read(qr/\n/);
    },
    'simple' => sub {
        my $str = '';
        $str .= "hello\nhello\nhello\n";

        my @records;
        while ($str =~ s/(.*?)\n//) {
            if($1 ne '') {
                CORE::push(@records, $1);
            }
        }
    },
    'double' => sub {
        my $str = '';
        $str .= "hello\nhello\nhello\n";

        my @records = ($str =~ /(.*?)\n/g);
        $str =~ s/(.*?)\n//g;
    },
});

