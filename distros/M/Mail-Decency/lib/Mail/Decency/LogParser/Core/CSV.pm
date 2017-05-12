package Mail::Decency::LogParser::Core::CSV;

use Moose::Role;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Data::Dumper;
use File::Basename qw/ dirname /;
use File::Path qw/ make_path /;

=head1 NAME

Mail::Decency::LogParser::CSV


=head1 DESCRIPTION

Logs 

=head1 CLASS ATTRIBUTES

=cut

has csv_log_classes => ( is => 'rw', isa => 'ArrayRef[Str]', predicate => 'enable_csv' );
has csv_log_ok      => ( is => 'rw', isa => 'HashRef' );
has csv_log_file    => ( is => 'rw', isa => 'Str' );
has csv_log_fh      => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has csv_data        => ( is => 'rw', isa => 'HashRef[ArrayRef]', default => sub { {} } );

=head1 METHODS


=head2 init

Extends init..

=cut

before 'init' => sub {
    my ( $self ) = @_;
    return unless $self->config->{ csv_log };
    
    
    # check wheter we have a csv file
    die "Require 'file' in csv_log\n"
        unless $self->config->{ csv_log }->{ file };
    my $dir = dirname( $self->config->{ csv_log }->{ file } );
    
    # create dir, unless existing
    make_path( $dir, { mode => 0700 } )
        unless ( -d $dir );
    die "Could not create directory '$dir' for csv files\n"
        unless ( -d $dir );
    
    # using csv log ?
    die "Require 'classes' in csv_log\n"
        unless $self->config->{ csv_log }->{ classes };
    $self->csv_log_classes( $self->config->{ csv_log }->{ classes } );
    
    # remember names of valid log classes
    $self->csv_log_ok( { map {
        ( $_ => 1 );
    } @{ $self->csv_log_classes } } );
    
    # setup file
    $self->csv_log_file( $self->config->{ csv_log }->{ file } );
    
    return;
};


=head2 handle

Checks wheter incoming mail is whilist for final recipient

=cut

before 'handle' => sub {
    my ( $self ) = @_;
    
    # empty data
    $self->csv_data( {} );
    
    return;
};

after 'handle' => sub {
    my ( $self, $parsed_ref ) = @_;
    
    return unless $self->enable_csv;
    
    # check all possible csv classes
    foreach my $class( @{ $self->csv_log_classes } ) {
        
        # not having any data of this kind ?
        next unless ( my $data_ref = $self->current_data->{ $class } );
        #print Dumper $data_ref;
        
        # get file handle 
        my $fh = $self->csv_log_fh->{ $class };
        my $file = $self->csv_log_file. ".$class";
        
        # no such file handle -> open now
        unless ( $fh ) {
            my $mode = -f $file ? '>>' : '>';
            open $fh, $mode, $file
                or die "Cannot open '$file' for append: $!\n";
            $self->csv_log_fh->{ $class } = $fh;
            $fh->autoflush( 1 );
            
            if ( $mode eq '>' ) {
                eval {
                    print $fh "time;". join( ";", sort keys %$data_ref ). "\n";
                };
            }
        }
        
        # try print
        eval {
            print $fh join( ";", time(), map {
                my $s = $data_ref->{ $_ };
                $s =~ s/;/\\;/g;
                $s =~ s/\n/\\n/g;
                $s;
            } sort keys %$data_ref ). "\n";
        };
        
        # catch error once (may be rotated or some)
        if ( $@ ) {
            open $fh, '>>', $file
                or die "Cannot open '$file' for append: $!\n";
            $fh->autoflush( 1 );
            $self->csv_log_fh->{ $class } = $fh;
            print $fh join( ";", @{ $self->csv_data->{ $class } } );
        }
    }
};


=head2 add_csv_data

Adding data to current queue

=cut

sub add_csv_data {
    my ( $self, $name, @data ) = @_;
    push @{ $self->csv_data->{ $name } ||= [] }, @data;
}

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;
