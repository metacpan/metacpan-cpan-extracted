package IO::CSVHeaderFile;
# $Id: CSVHeaderFile.pm,v 1.2 2007/07/06 08:44:46 vasek Exp $

use strict;
use Text::CSV_XS;
use IO::File;
use vars qw(@ISA @EXPORT $VERSION);
use Exporter;
use Carp;

@ISA = qw(IO::File Exporter);

@EXPORT = qw(
        
);

$VERSION = '0.04';

my $SUPPORTED_XS_ARGS;

sub open {
	my $self = shift;
	my $args = {}; $args = pop @_ if ref($_[$#_]) eq 'HASH';
	_init_supported_xs_args();
	my %xs_args = ( 'eol' => "\n", map {exists $SUPPORTED_XS_ARGS->{$_} ? ($_ => $args->{$_}):()} keys %$args);
	my $csv = Text::CSV_XS->new(\%xs_args);
	my $mode;
	if(@_ > 1){
		croak 'usage: $fh->open(FILENAME [ ,< > >> ][,CSVOPT])' if $_[2] =~ /^\d+$/;
		$mode = IO::Handle::_open_mode_string($_[1]);
	}else{
		$mode = $_[0];
		$mode =~ s/^(\+?<|>>?)(.*)$/$1/ 
			or croak 'usage: $fh->open(FILENAME [,< > >> ][,CSVOPT])';
	}
	my ($fh, $firstline);
	if($mode =~ /^<$/){
		$fh = $self->SUPER::open( @_ ) or return;
		unless($args->{noheader}){
			unless( $firstline = $self->getline ){
				$self->close;
				return;
			}
			$csv->parse($firstline) and $args->{col} = [ $csv->fields ]
				unless $args->{col};
		}
		unless(${*$self}{io_csvheaderfile_cols} = $args->{col}){
			$self->close;
			croak "IO::CSVHeaderFile: Can't find the column names in '$_[0]'";
			return;
		}	
	}elsif( $mode =~ /^>>?$/){
		unless(${*$self}{io_csvheaderfile_cols} = $args->{col}){
			$self->close;
			croak "IO::CSVHeaderFile: Can't find the column names in '$_[0]'";
			return;
		}
		$fh = $self->SUPER::open( @_ ) or return;
		$csv->print($self, $args->{col})
			unless $mode =~ /^>>$/ or $args->{noheader};
	}else{
		croak "IO::CSVHeaderFile: Invalid mode '$mode'";
		return;
	}
	${*$self}{io_csvheaderfile_csv} = $csv;
	$fh
}

sub csv_read{
	my $self = shift;
	my $line = $self->getline() or return;
	my @result = ();
	if( ${*$self}{io_csvheaderfile_csv}->parse($line) ){
		my @cols = ${*$self}{io_csvheaderfile_csv}->fields;
		my $colnames = ${*$self}{io_csvheaderfile_cols};
		my $avail_cols = (@cols > @$colnames)? @$colnames : @cols;
		for(my $i = 0; $i < $avail_cols; $i++){
			push @result, $colnames->[$i] => $cols[$i];
		}
	}
	wantarray? @result : { @result }
}

sub csv_print{
	my $self = shift;
	return undef unless @_;
	my $rec = $_[0];
	my @columns = ();
	my $colnames = ${*$self}{io_csvheaderfile_cols};
	unless( ref $rec ){
		my %map = ();
		for(my $i = 0; $i < @$colnames; $i++){
			$map{$colnames->[$i]} = [] unless exists $map{$colnames->[$i]};
			push @{$map{$colnames->[$i]}}, $i;
		}
		while ( my ($key, $value) = splice(@_, 0, 2) ) {
			my $idx = $map{$key} or next;
			$columns[$idx->[0]] = $value;
			shift @$idx if @$idx > 1;
		}
	}elsif( ref ($rec) eq 'HASH' ){
		push( @columns, $rec->{$_}) foreach (@$colnames);		
	}elsif( ref ($rec) eq 'ARRAY' ){
		for( my $i = 0; $i < @$colnames; $i++){
			push @columns, $rec->[$i];
		}
	}
	${*$self}{io_csvheaderfile_csv}->print($self,\@columns);
}

sub _init_supported_xs_args {
	return if defined $SUPPORTED_XS_ARGS;
	my $tmpcsvxs = Text::CSV_XS->new();
	$SUPPORTED_XS_ARGS = UNIVERSAL::isa($tmpcsvxs, "HASH")?
		{%$tmpcsvxs}: {map {$_ => undef} qw(eol sep_char allow_whitespace quote_char
		allow_loose_quotes escape_char allow_loose_escapes binary types always_quote 
		keep_meta_info)};
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

IO::CSVHeaderFile - Perl extension for CSV Files 

=head1 SYNOPSIS

  # to read ...
  use IO::CSVHeaderFile;
  my $csv = IO::CSVHeaderFile->new( "< $filename" );
  while(my $hash = $csv->csv_read ){
  	print "$hash->{ColHeaderTitle}\n";
  }
  $csv->close;
  
  # or for same named columns
  my $csv = IO::CSVHeaderFile->new( "< $filename" );
  my $data;
  while(@array = $csv->csv_read ){
  	for(my $i=0; $i< @array; $i++) {
  		print "Column '$array[$i]': $array[$i]\n";
  	}
  	print "-- end of record\n";
  }
  $csv->close;
  
  
  # to write ...
  use IO::CSVHeaderFile;
  my $csv = IO::CSVHeaderFile->new( "> $filename" , 
  	{col => ['ColHeaderTitle1','ColHeaderTitle2','ColHeaderTitle1'], noheaders => 1} );
    $csv->csv_print({ColHeaderTitle1 => 'First', ColHeaderTitle2 => 'Second'}) or return;
    $csv->csv_print(['Uno', 'Duo', 'Tre']) or return;
    $csv->csv_print(
    	ColHeaderTitle1 => 'One',
    	ColHeaderTitle2 => 'Two',
    	ColHeaderTitle1 => 'Three with the same name as One'
    	) or return;
  $csv->close;

=head1 DESCRIPTION

Read from and write to csv file.


=head2 EXPORT

None by default.

=head2 FUNCTIONS

=over 4

=item csv_print RECORD | LIST

Store the C<RECORD> into file,  C<RECORD> can be hash reference as
returned from C<csv_read> or an array ref with values ordered same 
as respctive headers in file.

If LIST variant is used it can be a hash definition like a list in form
of headers and values, but the header names doesn't have to be unique. This 
is usefull when creating a CSV file with several same named columns.

=item csv_read

Return the next record (hash reference in scalar context, 
array of header names and values in list context) from the file.
Returns C<undef> if C<eof>.

=cut

=head1 AUTHOR

Vasek Balcar, E<lt>vasek@ti.czE<gt>

=head1 SEE ALSO

L<IO::File>, L<IO::Handle>, L<perl>.

=cut
