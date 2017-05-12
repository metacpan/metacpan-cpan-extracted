package MS2::Parser;

use v5.12;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use MS2::Header;
use MS2::Scan;

our $VERSION = '0.062';

has 'header' => (
    is  =>  'rw',
    isa =>  'MS2::Header',
    );

has 'scanlist' => (
    is  =>  'rw',
    isa =>  'ArrayRef',
    );


sub parse {
    my $self = shift;
    my $path = shift;

    open (my $file, '<', $path) or die "[Error]: Could not opne file!\n";

    my $header  = MS2::Header->new();
    my $scan;
    my @scanlist;

    my $flag = 0;

    while ( my $line = <$file> ) {
        chomp $line;

        if ( $line =~ m/^H/ ) {

            $flag = 1;

        } elsif ( $line =~ m/^S/ ) {

            if ($scan) {
                push(@scanlist, $scan);
            }

            $flag = 2;
            $scan = MS2::Scan->new();

        } elsif ( $line =~ m/^[IZ]/ ) {

            $flag = 2;

        } elsif ( $line =~ m/^\d/ ) {

            $flag = 3;

        }
        
        if ( eof ) {

            push(@scanlist, $scan);
        }

        if ( $flag == 1 ) {
            
            $header->parse($line);

        } elsif ( $flag == 2 ) {

            $scan->parse($line);

        } elsif ( $flag == 3 ) {

            $scan->parse($line);
        }
    }

    $self->header($header);
    $self->scanlist(\@scanlist);
}

1;
