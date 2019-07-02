package Lab::Moose::Sweep;
$Lab::Moose::Sweep::VERSION = '3.682';
#ABSTRACT: Base class for high level sweeps

# Step/List and Continuous sweep are implemented as subclasses


use 5.010;
use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints 'enum';
use MooseX::Params::Validate;
use Lab::Moose::Sweep::DataFile;
use Lab::Moose::Countdown 'countdown';
use Data::Dumper;

# Do not import all functions as they clash with the attribute methods.
use Lab::Moose::Catfile qw/our_catfile/;

use Carp;

#
# Public attributes set by the user
#

has filename_extension => ( is => 'ro', isa => 'Str', default => 'Value=' );

has delay_before_loop => ( is => 'ro', isa => 'Num', default => 0 );
has delay_in_loop     => ( is => 'ro', isa => 'Num', default => 0 );
has delay_after_loop  => ( is => 'ro', isa => 'Num', default => 0 );
has before_loop       => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub {
        sub { }
    }
);

#
# Private attributes used internally
#

has slave => (
    is     => 'ro', isa => 'Lab::Moose::Sweep', init_arg => undef,
    writer => '_slave'
);

has is_slave =>
    ( is => 'ro', isa => 'Bool', init_arg => undef, writer => '_is_slave' );

has datafile_params => (
    is     => 'ro',
    isa    => 'ArrayRef[Lab::Moose::Sweep::DataFile]', init_arg => undef,
    writer => '_datafile_params'
);

has foldername =>
    ( is => 'ro', isa => 'Str', init_arg => undef, writer => '_foldername' );

# real Lab::Moose::DataFile
has datafiles => (
    is => 'ro', isa => 'HashRef[Lab::Moose::DataFile]', init_arg => undef,
    writer => '_datafiles'
);

has logged_datafiles => (
    is     => 'ro', isa => 'HashRef[Bool]', init_arg => undef,
    writer => '_logged_datafiles'
);

has create_datafile_blocks => (
    is     => 'ro', isa => 'Bool', init_arg => undef,
    writer => '_create_datafile_blocks'
);

# Should this sweep create a new datafile for each measurement point?
has create_datafiles => (
    is  => 'ro',
    isa => 'Bool', init_arg => undef, writer => '_create_datafiles'
);

has datafolder => (
    is       => 'ro',
    isa      => 'Lab::Moose::DataFolder',
    init_arg => undef,
    writer   => '_datafolder'
);

has measurement => (
    is => 'ro', isa => 'CodeRef', init_arg => undef, writer => '_measurement',
    predicate => 'has_measurement',
);

#
has was_used => (
    is     => 'ro', isa => 'Bool', init_arg => undef, default => 0,
    writer => '_was_used'
);

sub _ensure_no_slave {
    my $self = shift;
    if ( $self->is_slave() ) {
        croak "cannot do this with slave";
    }
}

sub _ensure_sweeps_different {
    my $self   = shift;
    my @sweeps = @_;

    my %h = map { ( $_ + 0 ) => 1 } (@sweeps);
    my @keys = keys %h;
    if ( @keys != @sweeps ) {
        croak "all sweeps must be separate objects!";
    }
}

sub _add_plots {
    my $self     = shift;
    my $datafile = shift;
    my $handle   = shift;
    my @plots    = @{ $handle->plots };
    for my $plot_params (@plots) {
        $datafile->add_plot($plot_params);
    }
}

sub _parse_slave_arg {
    my %args = @_;
    if ( defined $args{slaves} ) {
        if ( defined $args{slave} ) {
            croak "give either slave or slaves arg";
        }
        return $args{slaves};
    }
    if ( defined $args{slave} ) {
        return [ $args{slave} ];
    }
    else {
        return [];
    }
}

sub _parse_datafile_arg {
    my %args = @_;
    if ( defined $args{datafiles} ) {
        if ( defined $args{datafile} ) {
            croak "give either datafile or datafiles arg";
        }
        return $args{datafiles};
    }
    if ( defined $args{datafile} ) {
        return [ $args{datafile} ];
    }
    else {
        croak "need either datafile or datafiles arg";
    }
}

# Called by user on master sweep
sub start {
    my ( $self, %args ) = validated_hash(
        \@_,
        slave    => { isa => 'Lab::Moose::Sweep',           optional => 1 },
        slaves   => { isa => 'ArrayRef[Lab::Moose::Sweep]', optional => 1 },
        datafile => { isa => 'Lab::Moose::Sweep::DataFile', optional => 1 },
        datafiles =>
            { isa => 'ArrayRef[Lab::Moose::Sweep::DataFile]', optional => 1 },
        measurement  => { isa => 'CodeRef' },
        datafile_dim => { isa => enum( [qw/2 1 0/] ), optional => 1 },

        # might allow point_dim = 2 in the future.
        point_dim => { isa => enum( [qw/1 0/] ), default => 0 },
        folder      => { isa => 'Str|Lab::Moose::DataFolder', optional => 1 },
        date_prefix => { isa => 'Bool',                       default  => 1 },
        time_prefix => { isa => 'Bool',                       default  => 1 },
        meta_data   => { isa => 'HashRef',                    optional => 1 },
    );

    my $slaves          = _parse_slave_arg(%args);
    my $datafile_params = _parse_datafile_arg(%args);
    my $measurement     = $args{measurement};
    my $datafile_dim    = $args{datafile_dim};
    my $point_dim       = $args{point_dim};
    my $folder          = $args{folder};
    my $date_prefix     = $args{date_prefix};
    my $time_prefix     = $args{time_prefix};
    my $meta_data       = $args{meta_data};

    $self->_ensure_no_slave();

    my $num_slaves = 0;
    my @slaves;
    my @sweeps = ($self);
    if ( defined $slaves ) {
        @slaves     = @{$slaves};
        $num_slaves = @slaves;
        push @sweeps, @slaves;
    }

    for my $sweep (@sweeps) {
        if ( $sweep->was_used() ) {
            croak "sweep was used before. cannot use it for multiple runs.";
        }
        $sweep->_was_used(1);
    }

    $self->_ensure_sweeps_different(@sweeps);

    if ( defined $datafile_dim ) {
        if ( $point_dim > $datafile_dim ) {
            croak "datafile_dim must be >= point_dim";
        }

        if ( $num_slaves + $point_dim == 0 and $datafile_dim == 2 ) {
            croak
                "cannot create 2D datafile without slaves and zero point_dim";
        }
    }
    else {
        # Set default log_structure
        if ( $num_slaves + $point_dim == 0 ) {
            $datafile_dim = 1,
        }
        else {
            $datafile_dim = 2,
        }
    }

    if ( $datafile_dim == 2 ) {
        if ( $point_dim == 0 ) {
            $sweeps[-2]->_create_datafile_blocks(1);
        }
        elsif ( $point_dim == 1 ) {
            $sweeps[-1]->_create_datafile_blocks(1);
        }
    }

    if ($num_slaves) {

        # Set slave/parent relationships
        my $parent = $self;
        for my $slave (@slaves) {
            $slave->_is_slave(1);
            $parent->_slave($slave);
            $parent = $slave;
        }
    }

    if ($num_slaves) {
        $slaves[-1]->_measurement($measurement);
    }
    else {
        $self->_measurement($measurement);
    }

    # Pass this to master sweep's _start method if we have a single datafile
    my $datafolder;
    if ( defined $folder ) {
        if ( ref $folder ) {
            $datafolder = $folder;
        }
        else {
            $datafolder = Lab::Moose::datafolder(
                path        => $folder,
                date_prefix => $date_prefix,
                time_prefix => $time_prefix,
            );
        }
    }
    else {
        $datafolder = Lab::Moose::datafolder(
            date_prefix => $date_prefix,
            time_prefix => $time_prefix
        );
    }

    $self->_foldername( $datafolder->path() );

    if ($meta_data) {
        $datafolder->meta_file->log( meta => $meta_data );
    }

    my $datafiles;

    if ( ( $num_slaves + $point_dim ) - $datafile_dim >= 0 ) {
        my $datafile_creating_sweep
            = $sweeps[ ( $num_slaves + $point_dim ) - $datafile_dim ];
        $datafile_creating_sweep->_create_datafiles(1);
        $datafile_creating_sweep->_datafile_params($datafile_params);
        $datafile_creating_sweep->_datafolder($datafolder);
    }
    else {
        # only top-level datafiles
        for my $handle ( @{$datafile_params} ) {
            my %params   = %{ $handle->params };
            my $filename = delete $params{filename};
            $filename .= '.dat';
            my $datafile = Lab::Moose::datafile(
                folder   => $datafolder,
                filename => $filename,
                %params
            );
            $self->_add_plots( $datafile, $handle );
            $datafiles->{$handle} = $datafile;
        }
    }

    $self->_start(
        datafiles           => $datafiles,
        filename_extensions => [],
    );

}

sub _gen_filename {
    my $self = shift;
    my ( $filename, $extensions ) = validated_list(
        \@_,
        filename   => { isa => 'Str' },
        extensions => { isa => 'ArrayRef[Str]' },
    );

    my @extensions = @{$extensions};

    my $basename = $filename . '_' . join( '_', @extensions ) . '.dat';

    pop @extensions;
    if ( @extensions >= 1 ) {

        # create subdirectories in datafolder
        return our_catfile( @extensions, $basename );
    }
    else {
        return $basename;
    }
}

# to be implemented in subclass:

# go_to_sweep_start

# sweep_finished

# go_to_next_point

# get_value

sub _start {
    my $self = shift;
    my ( $datafiles, $filename_extensions ) = validated_list(
        \@_,
        datafiles => { isa => 'Maybe[HashRef[Lab::Moose::DataFile]]' },
        filename_extensions => { isa => 'ArrayRef[Str]' },
    );

    my $slave                    = $self->slave();
    my $create_datafiles         = $self->create_datafiles;
    my $push_filename_extensions = not defined $datafiles;

    if ( $create_datafiles and defined $datafiles ) {
        croak "should not get datafile arg";
    }

    $self->go_to_sweep_start();

    my $before_loop_code = $self->before_loop();
    $self->$before_loop_code();

    countdown( $self->delay_before_loop );
    $self->start_sweep();
    while ( not $self->sweep_finished() ) {
        $self->go_to_next_point();
        countdown( $self->delay_in_loop );
        my @filename_extensions = @{$filename_extensions};

        # Only call get_value if we have to
        if ($push_filename_extensions) {
            push @filename_extensions,
                $self->filename_extension . $self->get_value();
        }

        # Create new datafile?
        if ($create_datafiles) {
            for my $handle ( @{ $self->datafile_params } ) {
                my %params   = %{ $handle->params };
                my $filename = delete $params{filename};

                $filename = $self->_gen_filename(
                    filename   => $filename,
                    extensions => [@filename_extensions],
                );

                my $datafile = Lab::Moose::datafile(
                    folder   => $self->datafolder,
                    filename => $filename,
                    %params,
                );
                $self->_add_plots( $datafile, $handle );
                $datafiles->{$handle} = $datafile;
            }
        }

        if ($slave) {

            $slave->_start(
                datafiles           => $datafiles,
                filename_extensions => [@filename_extensions],
            );

        }
        else {
            # do measurement
            $self->_datafiles($datafiles);
            $self->_logged_datafiles( {} );
            my $meas = $self->measurement();
            $self->$meas();
            my %logged = %{ $self->logged_datafiles };
            if ( keys(%logged) != keys( %{$datafiles} ) ) {
                croak
                    "unused datafiles. Make sure that a logging method is used for each datafile";
            }

        }
        if ( $self->create_datafile_blocks() ) {
            for my $datafile ( values %{$datafiles} ) {
                $datafile->new_block();
            }
        }
        countdown( $self->delay_after_loop );
    }

}

sub _validated_datafile_arg {

    # could only use validated_hash without caching
    my $self = shift;
    my %args = @_;

    my $handle = delete $args{datafile};

    my %datafiles = %{ $self->datafiles() };
    my $datafile;

    if ( keys(%datafiles) < 1 ) {
        croak "no datafiles available in log method";
    }
    if ( not defined $handle ) {
        my @keys = keys(%datafiles);
        if ( @keys != 1 ) {
            croak
                "no 'datafile => ...' argument for the 'log' method. Must be used for multiple datafiles.";
        }
        $handle = $keys[0];

    }
    $datafile = $datafiles{$handle};
    return ( $self, $datafile, $handle, %args );
}

sub _validated_log {
    my ( $self, $datafile, $handle, %args ) = _validated_datafile_arg(@_);
    $self->logged_datafiles()->{$handle} = 1;
    return ( $self, $datafile, %args );
}

sub log {
    my ( $self, $datafile, %args ) = _validated_log(@_);
    $datafile->log(%args);
}

sub log_block {
    my ( $self, $datafile, %args ) = _validated_log(@_);
    $datafile->log_block(%args);
}

sub _get_innermost_slave {
    my $self = shift;
    while ( defined $self->slave ) {
        $self = $self->slave;
    }
    return $self;
}

sub refresh_plots {
    my $self = shift;
    $self = $self->_get_innermost_slave();
    my ( $self2, $datafile, $handle, %args )
        = _validated_datafile_arg( $self, @_ );
    $datafile->refresh_plots(%args);
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Sweep - Base class for high level sweeps

=head1 VERSION

version 3.682

=head1 DESCRIPTION

The Sweep interface is documented in L<Lab::Measurement::Tutorial>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017       Simon Reinhardt
            2018       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
