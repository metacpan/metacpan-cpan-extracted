package File::Convert::CSV;

use 5.008007;use strict;use warnings;

our $VERSION = '0.03';

use IO::Extended qw(:all);

use Data::Iter qw(:all);

use Carp qw(confess croak cluck carp);

use Class::Debugable;

use Data::Dump qw(dump);

use Path::Class;

Class::Maker::class
{
    isa => [qw( Class::Debugable )],

    public => 
    {
	scalar => [qw( file separator has_header raw line skip_pattern skip_callback )],

	array => [qw( header data_array data_fields data_file )],

	#	    hash => [qw( fields )],
    },

    default =>
    {
	has_header => 1,

	separator => "\t",

	skip_pattern => qr/^#/,
	
	skip_callback => sub {}
    
    },
};

sub data_hash
{
    my $this = shift;

    return unless $this->has_header;

return transform_array_to_hash( scalar $this->data_array );
}

sub preformat_data_file : method
{
    my $this = shift;
}


sub iterate_each_line
{
    my $this = shift;

    my $file = Path::Class::File->new( $this->file )->absolute;

    my $callback_line = shift || sub { } ;

    my @args = @_;

    println STDERR __PACKAGE__, " iterate_each_line args = ", join( ', ', @args );

    my $separator = $this->separator;

    my $skip_pattern = $this->skip_pattern;

    $this->d_warn( "\n\nImporting from file %S...",  $file );
    
    open( FILE, $file ) or die "$! $file";
    
    my $cnt=0;

    my $line=0;
    
    my $limit = -1;
    
    my @slurp = <FILE>;

    $this->d_warn( "Input file %S has %d lines", $this->file, scalar @slurp );

    close( FILE );

    $this->data_file( \@slurp );

    $this->preformat_data_file();

    $this->d_warn_above( 10, "DATA_FILE %s", dump( $this->data_file ) );

    for ( @{ $this->data_file } ) 
    {
	$this->d_warn_above( 10, "LINE: %S", $_ );

	s/\r$//gi;
	
	chomp;

	$line++;            

	if( /$skip_pattern/ )
	{
	    $this->d_warn( "skipping line %d: %s", $line, $_ );

	    $this->skip_callback->();

	    next;
	}

	$cnt++;            

	$this->raw = $_;
	
	$this->line = $line;
	
	if( $cnt == 1 && $this->has_header ) 
	{
	    if( $this->has_header )
	    {
	        $this->header( [ split /$separator/ ] );
	    }
	    
	    $this->d_warn( "csv imported file header (rows) %s", dump( $this->header ) );
	} 
	else 
	{

	    if ( $limit > 0 ) 
	    {
		last if $cnt >= $limit;
	    }
	    
	    $this->data_fields( [ split /$separator/ ] );
	    
	    $this->data_array( [] );

	    if( $this->has_header )
	    {	    
		for ( iter scalar $this->header ) 
		{
		    push @{ $this->data_array }, VALUE(), $this->data_fields->[ COUNTER() ];
		}
	    }
	    
	    $this->d_warn( "DATA_HASH %s", dump( $this->data_hash ) );

	    $this->d_warn( "DATA_ARRAY %s", dump( $this->data_array ) );

	    $this->d_warn( "DATA_FIELDS %s", dump( $this->data_fields ) );

	    $callback_line->( $this, @args );
	    
	    if ( 0 == $cnt % 200 ) 
	    {
		$this->d_print( "Processing line nr $line\n" );
	    }
	}
    }

    $this->d_warn( "finished." );
    
    close( FILE );
}

sub iterate_each_line_from_string
{
    my $this = shift;

    my $string = shift; # string 

    my $callback_line = shift || sub { } ;

    my @args = @_;

    println STDERR __PACKAGE__, " iterate_each_line args = ", join( ', ', @args );

    my $separator = $this->separator;

    my $skip_pattern = $this->skip_pattern;

    $this->d_warn( "\n\nImporting from string of %d bytes...",  length $string );
    
    my $cnt=0;

    my $line=0;
    
    my $limit = -1;
    
    my @slurp = split( /\n/, $string );

    $this->d_warn( "Input file %S has %d lines", $this->file, scalar @slurp );

    close( FILE );

    $this->data_file( \@slurp );

    $this->preformat_data_file();

    $this->d_warn_above( 10, "DATA_FILE %s", dump( $this->data_file ) );

    for ( @{ $this->data_file } ) 
    {
	$this->d_warn_above( 10, "LINE: %S", $_ );

	s/\r$//gi;
	
	chomp;

	$line++;            

	if( /$skip_pattern/ )
	{
	    $this->d_warn( "skipping line %d: %s", $line, $_ );

	    $this->skip_callback->();

	    next;
	}

	$cnt++;            

	$this->raw = $_;
	
	$this->line = $line;
	
	if( $cnt == 1 && $this->has_header ) 
	{
	    if( $this->has_header )
	    {
	        $this->header( [ split /$separator/ ] );
	    }
	    
	    $this->d_warn( "csv imported file header (rows) %s", dump( $this->header ) );
	} 
	else 
	{

	    if ( $limit > 0 ) 
	    {
		last if $cnt >= $limit;
	    }
	    
	    $this->data_fields( [ split /$separator/ ] );
	    
	    $this->data_array( [] );

	    if( $this->has_header )
	    {	    
		for ( iter scalar $this->header ) 
		{
		    push @{ $this->data_array }, VALUE(), $this->data_fields->[ COUNTER() ];
		}
	    }
	    
	    $this->d_warn( "DATA_HASH %s", dump( $this->data_hash ) );

	    $this->d_warn( "DATA_ARRAY %s", dump( $this->data_array ) );

	    $this->d_warn( "DATA_FIELDS %s", dump( $this->data_fields ) );

	    $callback_line->( $this, @args );
	    
	    if ( 0 == $cnt % 200 ) 
	    {
		$this->d_print( "Processing line nr $line\n" );
	    }
	}
    }

    $this->d_warn( "finished." );
}

sub dot_to_comma_for_excel
{
    my $this = shift;

    for( @_ )
    {
	$_ = $_.'';
	
	$_ =~ s/\./,/;
    }
    
    return @_;
}

1;

__END__

=head1 NAME

File::Convert::CSV - Perl extension for converting CSV files

=head1 SYNOPSIS

  use File::Convert::CSV;

   my $converter = File::Convert::CSV->new( 
    d_verbosity => 3,
    file => 'examples/taqman_export.csv',
    separator => ";"
    );

  $converter->iterate_each_line( 
    sub 
    { 
      my $this = shift; 
    
      $this->d_warn( "DATA_HASH %s", dump( $this->data_hash ) );
    
      $this->d_warn( "DATA_ARRAY %s", dump( $this->data_array ) );
    
      $this->d_warn( "DATA_FIELDS %s", dump( $this->data_fields ) );
    
      $this->d_warn( "RAW %s", $this->raw );
   }
   );

   $converter = File::Convert::CSV->new( 
    d_verbosity => 3,
    separator => " "
    );

  $converter->iterate_each_line_from_string( << END_HERE );

ALPHA BETA
1 6
2 6
3 6
END_HERE

=head1 DESCRIPTION

A somewhat luxury but lighweight module for reading conveniently CSV files.

=head1 new() options

=head2 has_header
If set to false, will not fill the data_hash and data_array fields.

=head2 EXPORT

None by default.

=head1 SEE ALSO

DBD::AnyData, and type CSV into search.cpan.org to see visit the zoo of similar modules.

=head1 AUTHOR

murat, E<lt>muenalan@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Murat Uenalan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut

