#! perl

# File::Text::CSV -- Access to CSV data files
# Author          : Johan Vromans
# Created On      : Sun Feb 14 14:44:39 2016
# Last Modified By: Johan Vromans
# Last Modified On: Tue Feb 16 10:02:50 2016
# Update Count    : 117
# Status          : Unknown, Use with caution!

=head1 NAME

File::Text::CSV -- Easy access to CSV data files

=head1 SYNOPSIS

  use File::Text::CSV;

  # Open a CSV file with headers.
  my $fh = File::Text::CSV->open( "current.csv",
			          { header => 1 } );

  # Read the rows.
  while ( my $row = $fh->read ) {
    print( $row->{Time}, ": ", $row->{Amount}, "\n");
  }

  # Create a new CSV file, with header row.
  my $out = File::Text::CSV->create( "foo.csv",
			             { header => [ qw( Time User Amount ) ],
			               sep_char => ";" }
			           );

  # Print some.
  $out->write( [ '13:21', 'root', 24 ] );
  $out->write( { Time => '15:43', User => 'me', Amount => 42 } );
  $out->close;

=head1 DESCRIPTION

File::Text::CSV is like many other CSV processing modules, but it
focuses on the file side.

CSV data is a file data format, so in practice one has to work with a
file, reading lines, then unpacking the data from the lines using some
other module, and so on. This module combines all that.

It uses Text::CSV_XS to handle the CSV details.

File::Text::CSV requires all rows of the CSV data to have the same
number of columns.

=cut

package File::Text::CSV;

use strict;
use warnings;
use Carp;
use Encode;

our $VERSION = "0.02";

use parent qw( Text::CSV_XS );	# it's safe to use Text::CSV instead

=head1 METHODS

=over

=item open

  $csv = File::Text::CSV::->open( $file, $opts )

B<open> creates a new File::CSV object associated with an input file.

The named file is opened and available for further processing.

The second parameter is a hashref with options. You can pass all
Text::CSV options here.

Additional options specific to this function:

=over

=item header

If present, it must be either an arrayref with column names, or a
truth value. If the latter value is true, the column names are read
from the first row of the CSV file.

=item encoding

Encoding to open the file with. Default encoding is UTF-8, unless
header processing is enabled and the file starts with a byte order
mark (BOM).

=item append

If true, new records written will be appended to the file.

=back

=cut

sub open {
    my ( $pkg, $file, $opts ) = @_;

    # Private options.
    my $header = delete $opts->{header};
    my $append = delete $opts->{append};
    my $encoding = delete $opts->{encoding};

    # Default options.
    $opts->{binary} = 1 unless exists $opts->{binary};

    # Create the object.
    my $self = $pkg->SUPER::new( $opts );
    croak( $pkg->SUPER::error_diag ) unless $self;

    # Open the file.
    if ( $file eq "-" ) {
	croak("Cannot append to standard input") if $append;
	$self->{_fh} = \*STDIN;
    }
    else {
	my $mode = $append ? '+<' : '<';
	CORE::open( $self->{_fh}, $mode, $file )
	  or croak( "$file: $!" );
	$self->{_append} = $append;
    }

    # If header is an aref, it should contain the fields.
    my $encset;
    if ( $header ) {
	if ( eval { $header->[0] || 1 } ) {
	    $self->{_column_names} = $header;
	    $self->{_columns} = @$header;
	    $self->column_names( @$header );
	}
	# Otherwise, if set, a file header is mandatory.
	elsif ( $encoding ) {
	    $self->{_fh}->binmode("encoding($encoding)");
	    $encset++;
	    my $res = $self->getline( $self->{_fh} );
	    croak( "Incomplete or missing header line" ) unless $res;
	    croak( "Incomplete or missing header line" )
	      if @$res == 1 && $res->[0] eq '';	# empty line
	    $self->{_column_names} = $res;
	    $self->{_columns} = @$res;
	    $self->column_names( @$res );
	}
	else {
	    my $line = readline($self->{_fh});
	    if ( $line ) {
		if ( $line =~ /^\x{ff}\x{fe}\0\0(.*)/s ) {
		    $line = $1;
		    $encoding = 'UTF-32LE';
		    # Line end is "\n\0\0\0" - get rid of excess.
		    getc( $self->{_fh} );
		    getc( $self->{_fh} );
		    getc( $self->{_fh} );
		}
		elsif ( $line =~ /^\0\0\x{fe}\x{ff}(.*)/s ) {
		    $line = $1;
		    $encoding = 'UTF-32BE';
		    # Line end is "\0\0\0\n" - stopped at \n.
		}
		elsif ( $line =~ /^\x{ef}\x{bb}\x{ff}(.*)/s ) {
		    $line = $1;
		    $encoding = 'UTF-8';
		}
		elsif ( $line =~ /^\x{ff}\x{fe}(.*)/s ) {
		    $line = $1;
		    $encoding = 'UTF-16LE';
		    # Line end is "\n\0" - get rid of excess.
		    getc( $self->{_fh} );
		}
		elsif ( $line =~ /^\x{fe}\x{ff}(.*)/s ) {
		    $line = $1;
		    $encoding = 'UTF-16BE';
		    # Line end is "\0\n" - stopped at \n.
		}
	    }
	    if ( $encoding ||= "UTF-8" ) {
		$line = Encode::decode( $encoding, $line, 1 );
	    }
	    my $res = $self->parse($line);
	    croak( "Incomplete or missing header line" ) unless $res;
	    my @res = $self->fields;
	    croak( "Incomplete or missing header line" )
	      if @res == 1 && $res[0] eq '';	# empty line
	    $self->{_column_names} = \@res;
	    $self->{_columns} = @res;
	    $self->column_names( @res );
	}
    }

    $encoding ||= "UTF-8";
    carp("Encoding set to $encoding") if $ENV{File_CSV_ENC_DEBUG};
    $self->{_fh}->binmode("encoding($encoding)") unless $encset;

    return $self;
}

=item create

  $csv = File::Text::CSV::->create( $file, $opts )

B<open> creates a new File::Text::CSV object associated with an output file.

The named file is created and available for further processing.

The second parameter is a hashref with options. You can pass all
Text::CSV_XS options here.

Additional options specific to this function:

=over

=item header

If present, it must be a arrayref with column names. The column names
are written to the first row of the CSV file.

=item encoding

Encoding to create the file with. Default encoding is UTF-8.

=back

=cut

sub create {
    my ( $pkg, $file, $opts ) = @_;

    # Private options.
    my $header = delete $opts->{header};

    # Default options.
    $opts->{binary} = 1 unless exists $opts->{binary};

    # Create the object.
    my $self = $pkg->SUPER::new( $opts );
    croak( $pkg->SUPER::error_diag ) unless $self;

    # Open (create) the file.
    if ( $file eq "-" ) {
	$self->{_fh} = \*STDOUT;
    }
    else {
	my $mode = '>';
	$opts->{encoding} = "utf8" unless defined $opts->{encoding};
	$mode .= ':' . $opts->{encoding} if $opts->{encoding};
	CORE::open( $self->{_fh}, $mode, $file )
	    or croak( "$file: $!" );
    }

    # If header is set, it must be an aref containing the fields.
    if ( $header ) {
	my $status = $self->print( $self->{_fh}, $header );
	croak( $self->error_diag ) unless $status;
	$self->{_fh}->print("\n");
	$self->{_columns} = @$header;
	$self->{_column_names} = $header;
	$self->column_names( @$header );
    }

    return $self;
}

# Internal: Check (or set) the number of columns.

sub _check_columns {
    my ( $self, $n ) = @_;
    unless ( defined $self->{_columns} ) {
	$self->{_columns} = $n;
	return;
    }
    croak( "Incorrect number of fields: $n (should be " .
	   $self->{_columns} . ")" )
      unless $n == $self->{_columns};
}

=item read

  $row = $csv->read

B<read> reads the next row from the file, parses it into columns, and
delivers the result.

When column names have been specified upon object create time, this
method returns a hashref. Otherwise it behaves like B<read_arrayref>.

=cut

sub read {
    my ( $self ) = @_;
    goto &read_arrayref unless $self->{_column_names};
    my $res = $self->getline_hr( $self->{_fh} );
    return if $self->eof;
    croak( $self->error_diag ) unless $res;
    $self->_check_columns(0+keys(%$res));
    return $res;
}

=item read_arrayref

  $row = $csv->read_arrayref

B<read_arrayref> reads the next row from the file, parses it into
columns, and delivers the result as an arrayref.

=cut

sub read_arrayref {
    my ( $self ) = @_;
    my $res = $self->getline( $self->{_fh} );
    return if $self->eof;
    croak( $self->error_diag ) unless $res;
    $self->_check_columns(0+@$res);
    return $res;
}

=item write

  $row = $csv->write( @data )
  $row = $csv->write( \@data )
  $row = $csv->write( \%data )

A new row of data is assembled using the content of the supplied hash
or array, and written to the file.

=cut

sub write {
    my ( $self, @row ) = @_;

    my $status;
    if ( !ref($row[0]) ) {
	$self->_check_columns( 0+@row );
    }
    elsif ( eval { $row[0]->[0] || 1 } ) {	# aref
	@row = @{ $row[0]->[0] };
	$self->_check_columns( 0+@row );
    }
    else {				# hashref
	my $row = $row[0];
	@row = ();
	$self->_check_columns( 0+keys(%$row) );
	my %row = %$row;
	foreach ( @{ $self->{_column_names} } ) {
	    push( @row, delete($row{$_}) );
	}
	croak("Unused column names: " . join(" ", keys(%row)))
	  if %row;
    }
    seek( $self->{_fh}, 0, 2 ) if $self->{_append};
    $status = $self->print( $self->{_fh}, \@row );
    $self->{_fh}->print("\n");
    croak( $self->error_diag ) unless $status;
}

=item close

  $csv->close

Close the file.

=cut

sub close {
    my ( $self ) = @_;
    $self->{_fh}->close or croak("$!");
    delete $self->{_fh};
}

=back

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File::Text::CSV>

For other issues, contact the author.

=head1 AUTHOR

Johan Vromans E<lt>jv@cpan.orgE<gt>.

=head1 SEE ALSO

L<Text::CSV_XS>, L<Text::CSV>.

=head1 LICENSE

Copyright (C) 2016, Johan Vromans,

This module is free software. You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

1;
