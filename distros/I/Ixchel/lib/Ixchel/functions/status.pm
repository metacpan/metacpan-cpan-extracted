package Ixchel::functions::status;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Exporter 'import';
our @EXPORT = qw(status);

=head1 NAME

Ixchel::functions::status - Helper function for creating status lines.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ixchel::functions::status;

    $status=$status.status(type=>'Foo', error=>0, status=>'Some status...', no_print=>0);

This creates a status text line in the format below...

    '[' . $timestamp . '] [' . $opts{type} . ', ' . $opts{error} . '] ' . $opts{status}."\n";

$timestamp is created as below.

    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
    my $timestamp = sprintf( "%04d-%02d-%02dT%02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );

=head1 Functions

=head2 status

Creates a new status line for use with functions.

=head3 opts

=head4 type

The type to use. If not set it is set to 'undef'.

=head4 status

The new status. If undef '' is just returned.

=head4 error

If it is an error or not. Defaults to 0.

=head4 no_print

If it should print it or not.

=cut

sub status {
	my (%opts) = @_;

	if ( !defined( $opts{status} ) ) {
		return '';
	}
	chomp( $opts{status} );

	if ( !defined( $opts{error} ) ) {
		$opts{error} = 0;
	}

	if ( !defined( $opts{type} ) ) {
		$opts{type} = 'undef';
	}

	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
	my $timestamp = sprintf( "%04d-%02d-%02dT%02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );

	my $status = '[' . $timestamp . '] [' . $opts{type} . ', ' . $opts{error} . '] ' . $opts{status} . "\n";

	if ( !$opts{no_print} ) {
		print $status;
	}

	return $status;
} ## end sub status

1;
