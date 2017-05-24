package Lab::Moose::DataFile::Gnuplot;

use 5.010;
use warnings;
use strict;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints 'enum';
use PDL::Core qw/topdl/;
use Data::Dumper;
use Carp;
use Scalar::Util 'looks_like_number';
use List::Util 'any';
use namespace::autoclean;

our $VERSION = '3.543';

extends 'Lab::Moose::DataFile';

has columns => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

has num_data_rows => (
    is       => 'ro',
    isa      => 'Int',
    default  => 0,
    writer   => '_num_data_rows',
    init_arg => undef
);

sub BUILD {
    my $self    = shift;
    my @columns = @{ $self->columns() };
    if ( @columns == 0 ) {
        croak "need at least one column";
    }
    $self->log_comment( comment => join( "\t", @columns ) );
}

=head1 NAME

Lab::Moose::DataFile::Gnuplot - Text based data file.

=head1 SYNOPSIS

 use Lab::Moose;

 my $folder = datafolder();
 
 my $file = datafile(
     type => 'Gnuplot',
     folder => $folder,
     filename => 'gnuplot-file.dat',
     columns => [qw/gate bias current/]
     );

 $file->log_comment(comment => "some extra comment");
 $file->log_newline();
 
 $file->log(gate => 1, bias => 2, current => 3);

 $block = [1, 2, 3, 4, 5, 6];
 $file->log_block(
    prefix => {gate => 1, bias => 2},
    block => $block
 );

=head1 METHODS

=head2 new

Requires a 'column' attribute in addition to the L<Lab::Moose::DataFile>
requirements.

=head2 log

 $file->log(column1 => $value1, column2 => $value2, ...);
 
Log one line of data.

=cut

sub log {
    my $self = shift;
    return $self->_log_bare(@_);
}

# Local routine, shell not be overidden in subclasses.

sub _log_bare {

    # We do not use MooseX::Params::Validate for performance reasons.
    my $self = shift;
    my %args;

    if ( ref $_[0] eq 'HASH' ) {
        %args = %{ $_[0] };
    }
    else {
        %args = @_;
    }

    my @columns = @{ $self->columns() };

    my $line = "";

    while ( my ( $idx, $column ) = each(@columns) ) {
        my $value = delete $args{$column};
        if ( not defined $value ) {
            croak "missing value for column '$column'";
        }
        if ( not looks_like_number($value) ) {
            croak "value '$value' for column '$column' isn't numeric";
        }

        $line .= sprintf( "%.17g", $value );
        if ( $idx != $#columns ) {
            $line .= "\t";
        }
    }
    $line .= "\n";

    if ( keys %args ) {
        croak "unknown colums in log call: ", join( ' ', keys %args );
    }

    my $fh = $self->filehandle();
    print {$fh} $line;

    my $num = $self->num_data_rows;
    $self->_num_data_rows( ++$num );
}

=head2 log_block

 $file->log_block(
     prefix => {column1 => $value1, ...},
     block => $block,
     add_newline => 0
 );

Log a 1D or 2D PDL or array ref. The first dimension runs over the datafile
rows. You can add prefix columns, which will be the same for each line in the
block. E.g. when using a spectrum analyzer inside a voltage sweep, one would
log the returned PDL prefixed with the sweep voltage.

=cut

sub log_block {
    my $self = shift;
    my ( $prefix, $block, $add_newline ) = validated_list(
        \@_,
        prefix      => { isa => 'HashRef[Num]', optional => 1 },
        block       => {},
        add_newline => { isa => 'Bool',         default  => 1 }
    );

    $block = topdl($block);

    my @dims = $block->dims();

    if ( @dims == 1 ) {
        $block = $block->dummy(1);
        @dims  = $block->dims();
    }
    elsif ( @dims != 2 ) {
        croak "log_block needs 1D or 2D piddle";
    }

    my $num_prefix_cols = $prefix ? ( keys %{$prefix} ) : 0;
    my $num_block_cols = $dims[1];

    my @columns = @{ $self->columns() };

    my $num_cols = @columns;

    if ( $num_prefix_cols + $num_block_cols != $num_cols ) {
        croak "need $num_cols columns, got $num_prefix_cols prefix columns"
            . " and $num_block_cols block columns";
    }

    my $num_rows = $dims[0];
    for my $i ( 0 .. $num_rows - 1 ) {
        my %log;

        # Add prefix columns to %log.
        for my $j ( 0 .. $num_prefix_cols - 1 ) {
            my $name = $columns[$j];
            $log{$name} = $prefix->{$name};
        }

        # Add block columns to %log.
        for my $j ( 0 .. $num_block_cols - 1 ) {
            my $name = $columns[ $j + $num_prefix_cols ];
            $log{$name} = $block->at( $i, $j );
        }
        $self->_log_bare(%log);
    }

    if ($add_newline) {
        $self->log_newline();
    }
}

=head2 log_newline

 $file->log_newline();

print "\n" to the datafile.

=cut

sub log_newline {
    my $self = shift;
    my $fh   = $self->filehandle;
    print {$fh} "\n";
}

=head2 log_comment

 $file->log_comment(comment => $string);

log a comment string, which will be prefixed with '#'. If C<$string> contains
newline characters, several lines of comments will be written.

=cut

sub log_comment {
    my $self = shift;
    my ($comment) = validated_list(
        \@_,
        comment => { isa => 'Str' }
    );
    my @lines = split( "\n", $comment );
    my $fh = $self->filehandle();
    for my $line (@lines) {
        print {$fh} "# $line\n";
    }
}

__PACKAGE__->meta->make_immutable();

1;
