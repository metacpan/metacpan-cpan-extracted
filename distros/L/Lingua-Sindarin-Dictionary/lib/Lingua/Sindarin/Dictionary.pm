package Lingua::Sindarin::Dictionary;

use warnings;
use strict;
use v5.12;
use utf8;
use Moose;
use namespace::autoclean;

our $VERSION = '0.01';

has 'dictionary' => (
    is  =>  'rw',
    isa =>  'ArrayRef',
    );

sub BUILD {
    my $self = shift;
    my $opt  = shift;

    my %opt = %{$opt};
    
    if ( $opt{'dict'} eq 'sindarin-english' ) {

        open( my $file, '<:encoding(UTF-8)', 'data/sindeng.txt' );
        $self->dictionary(&parse_file($file));

    } elsif ( $opt{'dict'} eq 'english-sindarin' ) {
        
        open( my $file, '<:encoding(UTF-8)', 'data/engsind.txt' );
        $self->dictionary(&parse_file($file));

    } else {

        warn "Unknown option";
    }
    
}

sub parse_file {
    my $file = shift;

    my @map;

    while ( my $line = <$file> ) {

        if ( $line =~ m/^(\w+)[,-]?:\s(.+)/ ) {
            push(@map, $line);
        }
    }

    return \@map;
}


sub search {
    my $self = shift;
    chomp (my $word = shift);

    my @map = @{$self->dictionary};
    my $result = '';

    for my $entry ( @map ) {

        if ( $entry =~ m/^($word)[,-]?:\s(.+)/i ) {

            $result .= $2."\n";
        }
    }

    if ( $result eq "" ) {
        say "Word not found";
    }

    return $result;

}

1;
