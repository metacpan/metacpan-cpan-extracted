package Lithium::WebDriver::Utils;

use strict;
use warnings;

use DateTime;
use Data::Dumper;

use base 'Exporter';
our @EXPORT = qw/
	BIND_LOGGING DISABLE_MSGS
	error dump debug
/;

my $ENABLED = 1;

sub DISABLE_MSGS
{
	$ENABLED = 0;
}

my $OUT = {
	ERROR => sub {
		my ($line) = @_;
		for (split "\n", $line) {
			print STDERR "\e[0;31mERROR> $_\e[0m\n";
		}
	},
	DUMP => sub {
		my ($obj) = @_;
		for (split "\n", Dumper($obj)){
			print STDERR "DEBUG> $_\n";
		}
	},
	DEBUG => sub {
		my ($line) = @_;
		for (split "\n", $line) {
			print STDERR "DEBUG> $_\n";
		}
	}
};

sub BIND_LOGGING
{
	my (%options) = @_;
	$OUT->{ERROR} = $options{error}
		if $options{error};
	$OUT->{DEBUG} = $options{debug}
		if $options{debug};
	$OUT->{DUMP}  = $options{dump}
		if $options{dump};
}

sub error
{
	my ($line) = @_;
	return unless $ENABLED;
	$OUT->{ERROR}->($line);
}

sub debug
{
	my ($line) = @_;
	return unless $ENABLED && $ENV{DEBUG};
	$OUT->{DEBUG}->($line);
}

sub dump
{
	my ($obj) = @_;
	return unless $ENABLED && $ENV{DEBUG};
	$OUT->{DUMP}->($obj);
}

=head1 NAME

Lithium::WebDriver::Utils - Utility functions used throughout the driver framework

=head1 DESCRIPTION

Shared utility functions to simplify the code base.
Additionally timestamps can be added if the value of debug is set to 'timestamp'

=head1 FUNCTIONS

=head2 error

Print a line of text to standard error (B<STDERR>) prefixed by 'ERROR >'.

=head2 debug

Print a string of text to standard error prefixed by 'DEBUG >', but only when debuging is turned on.

=head2 dump

Print a clean represenation of a single perl datastructure to standard error, but only when debugging
is enabled in the configs.
All output lines will be prefixed by 'DEBUG >'

=head2 DISABLE_MSGS

Disable all output messages, note this dangerous as you no longer get any debug level output.

=head2 BIND_LOGGING

Rebind logging functions to different functions. All rebinding lambda functions take a single
parameter which is the log message.

I<Parameters>

=over

=item debug

The debug function to rebind to.

=item dump

The dumping function to rebind to.

=item error

The error function to rebind to.

=back

I<EXAMPLE>

To rebind the error function, an anonymous function is passed to the error parameter key,
it's important to note that the lambda function takes exactly 1 input.

    BIND_LOGGING
        error => sub { print "ERROR BAD> $_[0]\n };

=head1 AUTHOR

Written by Dan Molik C<< <dan at d3fy dot net> >>

=cut

1;
