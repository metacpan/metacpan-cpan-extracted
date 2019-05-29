#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use Data::Dumper;
use JSON;

package Helper;



sub get_counter {
    
    my $counter_file = shift;

     my $json_text = do {
         open(my $fh, "<:encoding(UTF-8)", $counter_file) or die("Can't open \$counter_file\": $!\n");
         local $/;
         <$fh>
     };
     
     my $json = JSON->new;
     my $data = $json->decode($json_text);
     
     return $data;

}

sub clear_counter {

    my $counter_file = shift;

    my $json = JSON->new;
    my $data = {};
    $data->{'retries'} = 0;
    $data->{'max_retries'} = 0;
    open( my $fh, ">$counter_file");
    print $fh $json->encode($data) . "\n";
    close( $fh );
    
}

sub increment_counter {

    my $counter_file = shift;

    my $count = get_counter( $counter_file );
    my $retries     = $count->{'retries'};
    my $max_retries = $count->{'max_retries'};
    my $json = JSON->new;
    my $data = {};
    
    $data->{'retries'} = $retries + 1;
    $data->{'max_retries'} = $max_retries + 1;
    open( my $fh, ">$counter_file");
    print $fh $json->encode($data) . "\n";
    close( $fh );
    
}

1;
