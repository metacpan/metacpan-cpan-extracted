package Hardware::SensorsParser;

use strict;
use warnings;

=head1 NAME

Hardware::SensorsParser - Simple parser for Lm-sensors output

This module parse the output of 'sensors' and make it usable for programming. 
To get this module working you must have package 'lm-sensors' (http://www.lm-sensors.org) installed, configured and working.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Hardware::SensorsParser;

    my $s = new Hardware::SensorsParser();
    
    my @chipset_names = $s->list_chipsets();
    
    my @sensors_names = $s->list_sensors('smsc47b397-isa-0480');

    my @flags_names   = $s->list_sensor_flags('smsc47b397-isa-0480','temp2');

    my $value         = $s->get_sensor_value('smsc47b397-isa-0480','temp2','input');

=head1 CONSTRUCTOR

=head2 new

=cut

sub new {
 	my $class = shift;
    my %opts  = @_;
    my $self  = {};  
    
    %{$self->{_chips}} = ();
    
    bless $self, $class;
    
    $self->parse();
    
    return $self;
}

=head1 SUBROUTINES/METHODS

=head2 list_chipsets

Returns an array of recognized chipsets names.

Example:

    my @chipset_names = $s->list_chipsets();
    
    # Dump @chipset_names
    $VAR1 = 'smsc47b397-isa-0480';
    $VAR2 = 'coretemp-isa-0000'; 
    
=cut

sub list_chipsets {
 	my ($self) = @_;
 	
 	my @list_of_chipsets;
 	my ($key, $value);
 	
 	while (($key, $value) = each(%{ $self->{_chips} })){
        push(@list_of_chipsets, $key);
    }
        
    return @list_of_chipsets;
}

=head2 list_sensors

Returns an array of recognized sensor's names for a given chipset.

Example:
    
    my @sensors_names = $s->list_sensors('smsc47b397-isa-0480');
    
    # Dump @sensors_names
    $VAR1 = 'fan1';
    $VAR2 = 'temp1';
    $VAR3 = 'temp4';
    $VAR4 = 'temp3';
    $VAR5 = 'fan4';
    $VAR6 = 'fan3';
    $VAR7 = 'fan2';
    $VAR8 = 'temp2';

=cut

sub list_sensors {
    my ($self, $chipset) = @_;
    
    if (!defined $self->{_chips}{$chipset}) {
        die("Unable to find chipset '".$chipset."'");
    }
    my @list_of_sensors;
    my ($key, $value);
    
    while (($key, $value) = each(%{ $self->{_chips}{$chipset}})){
        push(@list_of_sensors, $key);
    }
    
    return @list_of_sensors;
}

=head2 list_sensor_flags

Returns an array of recognized flags for a given sensor.

Example:

    my @flags_names = $s->list_sensor_flags('smsc47b397-isa-0480','temp2');
    
    # Dump @flags_names
    $VAR1 = 'input';
    $VAR2 = 'max';
    $VAR3 = 'min';
    $VAR4 = 'critic_alarm';
    
=cut

sub list_sensor_flags {
    my ($self, $chipset, $sensor) = @_;
    
    if (!defined $self->{_chips}{$chipset}) {
        die("Unable to find chipset '".$chipset."'");
    }
    if (!defined $self->{_chips}{$chipset}{$sensor}) {
        die("Unable to find sensor '".$sensor."'");
    }
    my @list_of_flags;
    my ($key, $value);
    
    while (($key, $value) = each(%{ $self->{_chips}{$chipset}{$sensor}})){
        push(@list_of_flags, $key);
    }
    
    return @list_of_flags;
}

=head2 get_sensor_value

Return the current value of a sensor's flag.

Example:
    
    my $value = $s->get_sensor_value('smsc47b397-isa-0480','temp2','input');
    
    # Dump $value
    $VAR1 = '21.000';

=cut

sub get_sensor_value {
    my ($self, $chipset, $sensor, $flag) = @_;
    
    if (!defined $self->{_chips}{$chipset}) {
        die("Unable to find chipset '".$chipset."'");
    }
    if (!defined $self->{_chips}{$chipset}{$sensor}) {
        die("Unable to find sensor '".$sensor."'");
    }
    if (!defined $self->{_chips}{$chipset}{$sensor}{$flag}) {
        die("Unable to find flag '".$flag."'");
    }
    
    return $self->{_chips}{$chipset}{$sensor}{$flag};
}

=head2 parse

Parse sensors again. The first time is called automatically by the constructor.  

=cut

sub parse {
 	my ($self) = @_;
 	
 	open(OUT, "/usr/bin/sensors -Au |");
    
    my $f_new_chip = 1;
    my ($current_chip, $current_sensor);
    my (%chips, %sensors, %values);
    
    while (my $line = <OUT>){
        
        chomp($line);
        
        if ($f_new_chip) {
            $line         =~ s/ //g;
            $current_chip = $line;     

            $f_new_chip = 0;
            undef %sensors;
            next; 
        }
        my @tokens = split(':',$line);
        
        if (scalar(@tokens) == 1) {
            $tokens[0]      =~ s/ //g;
            $current_sensor = $tokens[0];

            undef %values;
            next;
        } 
        elsif (scalar(@tokens) == 2) {
            $tokens[0] =~ s/ //g;
            $tokens[1] =~ s/ //g;
            $tokens[0] = substr($tokens[0],index($tokens[0], '_')+1);
            
            $values{$tokens[0]} = $tokens[1];
        } 
        elsif (scalar(@tokens) == 0) {

            $f_new_chip = 1;
            next;
        }
        
        %{$sensors{$current_sensor}} = %values;
        %{$chips{$current_chip}}     = %sensors;
    }
    
    %{$self->{_chips}} = %chips;
    
    close OUT;
}

=head1 AUTHOR

"Davide Ticozzi", C<< <"dticozzi at gmail.com"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Hardware-SensorsParser at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hardware-SensorsParser>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hardware::SensorsParser


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hardware-SensorsParser>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hardware-SensorsParser>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hardware-SensorsParser>

=item * Search CPAN

L<http://search.cpan.org/dist/Hardware-SensorsParser/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 "Davide Ticozzi".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Hardware::SensorsParser
