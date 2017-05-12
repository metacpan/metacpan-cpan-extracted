#!/usr/bin/env perl

use warnings;
use strict;


package Gwybodaeth::Read;

# Methods for reading in data from either a file or URL;
use LWP::UserAgent;
use HTTP::Request;
use Carp qw(croak);

=head1 NAME

Read - input data reader class for gwybodaeth

=head1 SYNOPSIS

    use Read;

    my $r = Read->new();

    $r->get_file_data("/home/foo/bar.csv");
    $r->get_url_data("www.example.org/bar.csv");

    $r->get_input_data();


=head1 DESCRIPTION

This module imports data from the URIs given to it.

=over

=item new()

Create a new instance of Read.

$r = Read->new();

=cut

sub new {
    my $class = shift;
    my $self = {'Data' => [] };
    bless $self, $class;
    return $self;
}

=item get_file_data($filename)

This function gets data from $filename.

=cut

# Open a file and store its contents
# Returns length of file data
sub get_file_data {
    ref(my $self = shift) or croak "instance variable needed";
    my $file = shift;

    my $fh;    

    if (fileno($file)) { # Check if its a file handle
        $fh = $file;
    } else {             # If it's just a file name open a file handle
        # Return if file doesn't exist
        unless ( -e $file ) { return 0 };

        open $fh, q{<}, $file or croak "Couldn't open $file: $!";
    }

    @{ $self->{Data} }= (<$fh>);

    close $fh;
    
    return int $self->{Data};
}

=item get_url_data($url)

This function gets data from $url.

=cut

# Open a URL download the body and store it
# Returns true if successful
sub get_url_data {
    my($self, $url) = @_;

    ref($self) or croak "instance variable needed";

    my $browser = LWP::UserAgent->new(); 
    my $req = HTTP::Request->new(GET => $url);
    my $res = $browser->get($url);

    if ($res->is_success) {
        @{ $self->{Data} } = split /
                            \n\r? # new line feed and possible carriage return 
                            |     # OR
                            \r\n? # carriage return and possible new line feed
                            /x, $res->decoded_content;
    } 

    return $res->is_success;
}

=item get_input_data()

This function returns an array contiaining the ingested data.

=cut

# Data return methods:
sub get_input_data {
    ref(my $self = shift) or croak "instance variable needed";
    return $self->{Data};
}

1; 
__END__

=back

=head1 AUTHOR

Iestyn Pryce, <imp25@cam.ac.uk>

=head1 ACKNOWLEDGEMENTS

I'd like to thank the Ensemble project (L<www.ensemble.ac.uk>) for funding me to work on this project in the summer of 2009.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Iestyn Pryce <imp25@cam.ac.uk>

This library is free software; you can redistribute it and/or modify it under
the terms of the BSD license.
