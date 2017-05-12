package HTML::Spry::DataSet;

=pod

=head1 NAME

HTML::Spry::DataSet - Generate HTML Table Data Set files for the Spry Javascript toolkit

=head1 SYNOPSIS

  # Create the object
  my $dataset = HTML::Spry::DataSet->new;
  
  # Add the tables to the object
  $dataset->add( 'heavy100',
      [ 'Rank', 'Dependencies', 'Author',   'Distribution'           ],
      [ '1',    '748',          'APOCAL',   'Task-POE-All'           ],
      [ '2',    '276',          'MRAMBERG', 'MojoMojo-Formatter-RSS' ],
      ...
  );
  
  # Write out to the HTML file
  $dataset->write('dataset.html');

=head1 DESCRIPTION

Spry is a JavaScript framework produced by Adobe. The following is taken
from their website.

I<"The Spry framework for Ajax is a JavaScript library that provides
easy-to-use yet powerful Ajax functionality that allows designers
to build pages that provide a richer experience for their users.>

I<It is designed to take the complexity out of Ajax and allow designers
to easily create Web 2.0 pages.">

This package is used to generate simple HTML-formatted data sets that are
consumable by Spry DataSet objects, for use in generating various dynamic
JavaScript-driven page elements, such as dynamic tables, reports and so on.

The SYNOPSIS section covers pretty much everything you need to know about
using B<HTML::Spry::DataSet>. All methods throw an exception on error.

=cut

use 5.008005;
use strict;
use Carp         ();
use CGI          ();
use IO::File     ();
use Params::Util qw{ _IDENTIFIER _ARRAY _STRING };

our $VERSION = '0.01';

sub new {
	my $class = shift;
	my $self  = bless { }, $class;
	return $self;
}

sub add {
	my $self = shift;

	# Check the dataset name
	my $name = shift;
	unless ( _IDENTIFIER($name) ) {
		Carp::croak("Missing or invalid dataset identifier");
	}
	if ( $self->{$name} ) {
		Carp::croak("The dataset '$name' already exists");
	}

	# Check the records
	my $rowid = 0;
	foreach my $row ( @_ ) {
		unless ( _ARRAY($row) ) {
			Carp::croak("Row $rowid in dataset $name is not an ARRAY reference");
		}
		if ( scalar grep { not defined _STRING($_) } @$row ) {
			Carp::croak("Row $rowid in dataset $name contained a non-SCALAR column");
		}
		$rowid++;
	}

	# Add the dataset
	$self->{$name} = [ @_ ];

	return 1;
}

sub write {
	my $self = shift;

	# Open the file
	my $file = shift;
	my $html  = IO::File->new( $file, "w" );
	unless ( defined $html ) {
		Carp::croak("Failed to open '$file' for write");
	}

	# Write the file
	$html->say('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">');
	$html->say('<html>');
	$html->say('<head>');
	$html->say('<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />');
	$html->say('</head>');
	$html->say('<body>');
	foreach my $id ( sort keys %$self ) {
		$html->say("<table id='$id'>");
		foreach my $row ( @{ $self->{$id} } ) {
			$html->say('  <tr>');
			foreach my $cell ( @$row ) {
				my $text = CGI::escapeHTML($cell);
				$html->say("    <td>$text</td>");
			}
			$html->say('  </tr>');
		}
		$html->say('</table>');
	}
	$html->say('</body>');
	$html->say('</html>');

	# Clean up
	$html->close;

	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Spry-DataSet>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
