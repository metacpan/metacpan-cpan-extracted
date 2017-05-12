# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Helpers::CSVFilter;
use strict;
use warnings;

use Carp;

use Maplat::Helpers::FileSlurp qw(slurpTextFile);

our $VERSION = 0.995;

sub new {
    my ($class, %config) = @_;
    my $self = bless \%config, $class;
    return $self;
}

sub filter {
    my $self = shift;
    
    my (@headers, @headcount, @lines);
    
    $self->{logger}->debuglog("Loading input file");
    @lines = slurpTextFile($self->{source});
    
    my $filecount = 0;
    my $linecount = 0;
    
    $self->{logger}->debuglog("Parsing Header");
    my $header = shift @lines;
    chomp $header;
    @headers = split/;/, $header;
    for(my $i = 0; $i < $#headers; $i++) {
        $headcount[$i] = 0;
    }
    
    # First round... get count of used columns
    $self->{logger}->debuglog("Checking for empty columns");
    foreach my $line (@lines) {
        chomp $line;
        my @parts = split/;/o, $line;
        for(my $i = 0; $i < $#parts; $i++) {
            if(length($parts[$i]) > 0) {
                $headcount[$i]++;
            }
        }
    }
    
    # Second round... write out file
    $self->{logger}->debuglog("Writing Header");
    my $ofh;
    my $outline;
    foreach my $line(@lines) {       
        if($linecount == 0) {
            my $ofname = $self->{destination};
            $filecount++;
            $ofname =~ s/#/$filecount/g;

            # Special filehandle handling (i most likely know what i'm doing here), don't use Perl::Critic on this one
            open($ofh, ">", $ofname) or croak($!); ## no critic (InputOutput::RequireBriefOpen)
            $self->{logger}->debuglog("Opening new output file $ofname");
            $outline = "";
            for(my $i = 0; $i < $#headers; $i++) {
                if($headcount[$i] > 0) {
                    $outline .= "=\"" . $headers[$i] . "\";";
                }
            }
            $self->{logger}->debuglog("Writing data");
            print $ofh "$outline\n";
        }
        $linecount++;
    
        chomp $line;
        my @parts = split/;/o, $line;
        $outline = "";
        for(my $i = 0; $i < $#headers; $i++) {
            if($headcount[$i] > 0) {
                if(!defined($parts[$i])) {
                    $parts[$i] = "";
                }
                # HACK! FIXME! All columns expect the second (which is a date)
                # will be quotet as string
                if($i == 1) {
                    $outline .= "\"" . $parts[$i] . "\";";
                } else {
                    $outline .= "=\"" . $parts[$i] . "\";";
                }
            }
        }
        print $ofh "$outline\n";
    }
    $self->{logger}->debuglog("Closing output file");
    if(defined($ofh)) {
        close $ofh;
    }
    return;
}

1;
__END__

=head1 NAME

Maplat::Helpers::CSVFilter - remove unused columns from CSV files

=head1 SYNOPSIS

  use Maplat::Helpers::CSVFilter;
  
  my $filter = new Maplat::Helpers::CSVFilter(%config);
  $filter->filter();

=head1 DESCRIPTION

This module is an internal helper module to filter and split
CSV files.

This module is undocumented, because, frankly it is only
used in a specific case. If you really want to use it, look at the
source code...

=head2 new

Get a new filter instance.

=head2 filter

Do the filtering.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
