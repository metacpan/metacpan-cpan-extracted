package Geo::GeoNames::File;

=head1 NAME

Geo::GeoNames::File - Perl module for handling GeoNames.org data files

=head1 SYNOPSIS

use Geo::GeoNames::File;

my $file = Geo::GeoNames::File->open( qw/US.txt GB.txt/ );

while( my $rec = $file->next() )
{
    print $rec->name . "\n";
}

$file->close();

=head1 DESCRIPTION

Provides a Perl extention for handling GeoNames.org data files. You may
use this module to load GeoNames.org records from several seperate files.

=head1 AUTHOR

Xiangrui Meng <mengxr@stanford.edu>

=head1 COPYRIGHT

Copyright (C) 2009 by Xiangrui Meng

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

use 5.008007;
use strict;
use warnings;

use Carp ();

require Geo::GeoNames::Record;

=over

=item open()

Open files.

    my $file = Geo::GeoNames::File->open( @geonames_filenames );

=cut

sub open
{
    my $class = shift;
    my @filenames = @_;

    my $self = {
	filenames    => \@filenames,
	cur_filename => undef,
	cur_fh       => undef,
    };

    bless $self, $class;

    return $self;
}

=item close()

Close open file handles.

=cut

sub close
{
  my $self = shift;

  if( $self->{cur_fh} )
  {
    CORE::close $self->{cur_fh};
  }
}

=item next()

    my $record = $batch->next();

Return the next record in the file as a Geo::GeoNames::Record object. If a
filter function is supplied, it will return the next filtered record.

    sub pop_gt_100000
    {
       return (shift->population > 100000);
    }

    my $record = $file->next( \&pop_gt_100000 );

=cut

sub next 
{
    my ( $self, $filter ) = @_;
    
    if ( $filter and ref($filter) ne 'CODE' )
    {
	Carp::croak( "filter function must be a subroutine reference." );
    }
    
    if( $self->{cur_fh} )	# if cur_fh is active
    {
      while(1)
      {
	if( eof($self->{cur_fh}) )
	{
	  CORE::close $self->{cur_fh};
	  $self->{cur_fh} = undef;
	  
	  return $self->next($filter);
	}
	else
	{
	  my $fh = $self->{cur_fh};
	  my $line = <$fh>;
	
	  next if $line =~ /^\s*#/;

	  my $rec = Geo::GeoNames::Record->new( $line );

	  next if( $filter and !($filter->($rec)) );

	  return $rec;
	}
      }
    }
    else			# open next file
    {
      $self->{cur_filename} = shift @{$self->{filenames}} 
	or return;
      
      CORE::open( $self->{cur_fh}, "<:utf8", $self->{cur_filename} ) 
	  or Carp::croak( "Couldn't open $self->{cur_filename}!" );
    
      return $self->next($filter);
    }
}

=back

=cut

1;
__END__
