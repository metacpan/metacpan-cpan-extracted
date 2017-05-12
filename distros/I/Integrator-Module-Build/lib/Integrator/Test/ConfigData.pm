package Integrator::Test::ConfigData;

use strict;
use warnings;

use base 'Exporter';
use vars qw($VERSION);

=head1 NAME

Integrator::Test::ConfigData - Configuration information transfered in the TAP output

=head1 VERSION

$Revision: 1.11 $

=cut

$VERSION = sprintf "%d.%03d", q$Revision: 1.11 $ =~ /(\d+)/g;

=head1 SYNOPSIS

This module provides test functions to automate measurement and state
information gathering from a test script to the TAP output with the
intent of loading the information in the Integrator tool from Cydone
Solutions. These functions are mostly wrappers around ok functions.
See Test::Simple on www.cpan.org as a reference. If you need more
information for the TAP format see Test::TAP::Model on www.cpan.org.

Each of these functions is considered a single test statement and must
be counted in your test plan. This module is a sub-class of Test::Builder.

    #... your typical test.t file ...
    #!/usr/bin/perl
    
    use Test::More tests => 3;			#you declare your tests as usual
    use Integrator::Test::ConfigData;		#you add this to have access this module's functions

    # a test to produce a measurement in the TAP output.
    my $fan_speed = function_that_returns_some_fan_speed();
    measure( 'fan speed on FAN1', 'FAN_TACH1', $fan_speed, 'RPM', 0.1, 'TACH_123' );

    # a test to declare a component state in the TAP output.
    component( 'locking a blade in place', 'CPU_BLADE', 'SN0010023', 'HANDLE', 'LOCKED' );

    # a test to store a config file in the TAP output.
    config_file( 'last night temperature log', '/var/log/heat.log.00');

    # a test to store config data in the TAP output.
    my $string = 'SERIAL_NUMER=1234;18Sept1970';
    config_data( 'last night temperature log', 'serial_number_and_date', $string);

=head1 EXPORT

=over 4

=item measure

=item component

=item config_data

=back

=cut

our @EXPORT = qw( measure component config_string config_data config_file);

use MIME::Base64;
use Test::Builder;
my $Test = Test::Builder->new();

=head1 FUNCTIONS

=head2 measure 

This function is used to generate integrator_measurement tags in the TAP
output. In turn, this data will be interpreted by Cydone Integrator as
a measurement. The arguments to the function are:

 measurement ( COMMENT, MEASURMENT_NAME, VALUE, UNIT, TOLERANCE, EQUIPMENT );

Where COMMENT, MEASURMENT_NAME and VALUE are required. Fields are evaluated as
SCALARs.

If fields are empty, the corresponding values in the test results will
be blank, which is valid but not a good practice since the measurement
is not traceable.

=cut

sub measure ($$$;$$$) {
	my @params = @_;
	foreach my $param (@params) {
		$param =~ s/:/_COLON_/g;
		$param =~ s/;/_SEMICOLON_/g;
	}

	my ($cmt, @values) = @params;
	my $value_string = join(';',@values);

	return $Test->ok(1==1, "$cmt integrator_measurement:$value_string");	
}

=head2 component

This function is used to generate integrator_component tags in the TAP
output. In turn, this data will be interpreted by Cydone Integrator as
a component and state declaration. The arguments to the function are:

 component ( COMMENT, COMPONENT_NAME, COMPONENT_SERIAL_NUMBER,STATE_NAME, STATE_VALUE );

Where COMMENT and COMPONENT_NAME are required. Fields are evaluated as SCALARs

If fields are empty, the corresponding values in the test results will
be blank, which is valid but not a good practice since the declaration
is not complete.

=cut

sub component ($$;$$$) {
	my @params = @_;
	foreach my $param (@params) {
		$param =~ s/:/_COLON_/g;
		$param =~ s/;/_SEMICOLON_/g;
	}

	my ($cmt, @values) = @params;
	my $value_string = join(';',@values);

	return $Test->ok(1==1, "$cmt integrator_component:$value_string");	
}

=head2 config_data

This function is used to attach text data from a string in the TAP
output. The string will be encoded and the data will be interpreted by
Cydone Integrator as a log file with a name coresponding to the NAME
parameter for the current test case. The arguments to the function are:

 config_data ( COMMENT, NAME, STRING );

Notes: No string size limit is specified in this version. Use with care...

=cut

sub config_data {
	my $cmt    = shift;
	my $name   = shift;
	my $string = shift;

	$string ||= "";
	my $size = length($string);
	my $encoded_string = encode_base64($string);

	$Test->ok(1==1, "Loaded data: $cmt\n"
		       ."integrator_config_data:$name;$size;\n"
		       ."$encoded_string integrator_config_data_end:$name;" );
}

=head2 config_file

This function is used to attach a file in the TAP output. The file will be
encoded and the data will be interpreted by Cydone Integrator as a log file
for the current test case. The arguments to the function are:

 config_file ( COMMENT, FILE_NAME );

Notes: No file size limit is specified in this version. Use with care...

Other Note: If you must specify a file in a different directory, beware
that your test might not be portable because different path specifier
conventions (forward slashes versus backslashes).

=cut

sub config_file {
	my $cmt  = shift;
	my $file = shift;

	if (-r $file) {
		open FCONF, "<$file" or die "Error: unable to load config file $file, $?";
		my $size = (stat FCONF)[7];
		my $encoded_file = encode_base64(join '', (<FCONF>));
		close FCONF or die "Error: unable to close config file $file, $?";

		$Test->ok(1==1, "Loaded file $file: $cmt\n"
			       ."integrator_config_data:$file;$size;\n"
			       ."$encoded_file integrator_config_data_end:$file;"          );
	}
	else {
		$Test->ok(2==1, "Could not read config_data in file $file");
	}
}

=head1 AUTHOR

Cydone Solutions Inc, C<< <fxfx at cydone.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-integrator-test-configdata at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Integrator-Test-ConfigData>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Integrator::Test::ConfigData

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Integrator-Test-ConfigData>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Integrator-Test-ConfigData>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Integrator-Test-ConfigData>

=item * Search CPAN

L<http://search.cpan.org/dist/Integrator-Test-ConfigData>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Cydone Solutions Inc, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Integrator::Test::ConfigData
