#!/usr/bin/perl

use lib qw(lib examples);
use datasource;
use Iterator::BreakOn;

my $resultset = datasource->new(); 

#
#   Data source is ordered by location, zipcode and name
#
my $iter = Iterator::BreakOn->new( 
                datasource      => $resultset,
                getmethod       => 'get',
                private         =>  { 
                        zipcode_totals => 0,
                        location_totals => 0,
                                },
                break_before    =>  [
                    location    =>  \&before,
                    zipcode     =>  \&before,
                    ],
                break_after     =>  [
                    location    =>  \&after,
                    zipcode     =>  \&after,
                    ],
                on_every        => \&on_every,
                        );

$iter->run();

sub before {
    my  ($self, $field, $value) = @_;
    my  $data = $self->private();

    if ($field eq 'location') {
        print sprintf("%s: %s\n", $field, $value);
        $data->{location_totals} = 0;
    }
    elsif ($field eq 'zipcode') {
        $data->{zipcode_totals} = 0;
    }
}

sub after {
    my  ($self, $field, $value) = @_;
    my  $data = $self->private();

    if ($field eq 'zipcode') {
        print sprintf("\n\t\tTotals for zipcode %s: %.2f\n\n", $value,
                            $data->{zipcode_totals});
        $data->{location_totals} += $data->{zipcode_totals}; 
        $data->{zipcode_totals} = 0;
    }
    elsif ($field eq 'location') {
        print sprintf("\n\tTotals for location %s: %.2f\n\n", $value,
                            $data->{location_totals});
        $data->{location_totals} = 0;
    }

    return;
}

sub on_every {
    my  $self   =   shift;
    my  %values =   $self->item->getall();
    my  $data = $self->private();

    print sprintf("\t%s\t%-30s\t%.2f\n", $values{zipcode}, $values{name},
                    $values{amount} );

    $data->{zipcode_totals} += $values{amount};                            
}

    
