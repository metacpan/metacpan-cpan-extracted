package Journal::ImpactFactor;

use v5.12;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use Storable;
use Journal::JournalEntry;

our $VERSION = '0.04';

has 'journal_list' => (
    is  =>  'rw',
    isa =>  'ArrayRef[Journal::JournalEntry]',
    );


sub BUILD {
    my $self = shift;

    my $hashref = retrieve('journals') or die "[Error]: Could not find journal list";
    my %journals = %{$hashref};

    my $j;
    my @list;

    for my $key ( keys %journals ) {
        
        $j = Journal::JournalEntry->new();

        my @line = split(/\t/, $journals{$key});
        
        $j->name($line[0]) if defined ($line[0]);        
        $j->issn($line[1]) if defined ($line[1]);
        $j->year_2008($line[2]) if defined ($line[2]);
        $j->year_2009($line[3]) if defined ($line[3]);
        $j->year_2010($line[4]) if defined ($line[4]);
        $j->year_2011($line[5]) if defined ($line[5]);
        $j->year_2012($line[6]) if defined ($line[6]);
        $j->year_2013_2014($line[7]) if defined ($line[7]);

        push(@list, $j);
    }

    $self->journal_list(\@list);
}

sub search_by_name {
    my $self = shift;
    my $name = shift;

    my @list = @{$self->journal_list};

    my $result;

    for my $j ( @list ) {

        if ( $j->name =~ m/^$name$/ig ) {
            
            $result = $j;
        }
    }

    if ($result) {
        
        return $result;

    } else {
        
        say "Journal not found";
        return undef;

    }

}

sub search_by_issn {
    my $self = shift;
    my $issn = shift;

    my @list = @{$self->journal_list};

    my $result;

    for my $j ( @list ) {

        if ( $j->issn =~ m/^$issn$/ig ) {
            
            $result = $j;
        }
    }

    if ($result) {
        
        return $result;

    } else {
        
        say "Journal not found";
        return undef;

    }

}

1;
