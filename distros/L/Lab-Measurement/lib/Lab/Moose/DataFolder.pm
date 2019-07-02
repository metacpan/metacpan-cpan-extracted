package Lab::Moose::DataFolder;
$Lab::Moose::DataFolder::VERSION = '3.682';
#ABSTRACT: Create a data directory with meta data

use 5.010;
use warnings;
use strict;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Params::Validate;

use Carp;

use Lab::Moose::Catfile 'our_catfile';
use File::Basename qw/basename dirname/;
use File::Copy 'copy';
use List::Util 'max';
use Sys::Hostname;
use Time::HiRes qw/gettimeofday tv_interval/;
use POSIX qw/strftime/;
use namespace::autoclean;
use Encode 'decode';

use utf8;

use Lab::Moose::DataFile::Meta;

# Get a copy of @ARGV, before it get's mangled by the user script.

our @ARGV_COPY;

BEGIN {
    @ARGV_COPY = ( $0, @ARGV );
}


has path => (
    is        => 'ro',
    isa       => 'Str',
    writer    => '_path',
    predicate => 'has_path',
);

has date_prefix => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

has time_prefix => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

has meta_file => (
    is       => 'ro',
    isa      => 'Lab::Moose::DataFile::Meta',
    init_arg => undef,
    writer   => '_meta_file'
);

has script_name => (
    is  => 'ro',
    isa => 'Str',
);

sub BUILD {
    my $self = shift;

    if ( not $self->has_path() ) {
        $self->_path('MEAS');
    }

    my $folder   = $self->path();
    my $dirname  = dirname($folder);
    my $basename = basename($folder);

    if ( $self->time_prefix ) {
        $basename = strftime( '%H-%M-%S', localtime() ) . "_$basename";
        $folder = our_catfile( $dirname, $basename );
    }

    if ( $self->date_prefix ) {
        $basename = strftime( '%Y-%m-%d', localtime() ) . "_$basename";
        $folder = our_catfile( $dirname, $basename );
    }

    my $folder_number = _get_folder_number(
        basename => $basename,
        dirname  => $dirname
    );

    $folder .= sprintf( '_%03d', $folder_number );

    mkdir $folder
        or croak "cannot make directory '$folder': $!";

    $self->_path($folder);

    $self->_create_meta_file();

    $self->_copy_user_script();

}

sub _copy_user_script {
    my $self   = shift;
    my $script = $0;

    my $basename;
    my $script_name = $self->script_name();

    if ($script_name) {
        $basename = $script_name;
    }
    else {
        $basename = basename($script);
    }

    my $copy = our_catfile( $self->path, $basename );

    copy( $script, $copy )
        or croak "copy of $script to $copy failed: $!";
}

sub _create_meta_file {
    my $self = shift;
    my $time = [ gettimeofday() ];

    my %meta_data = (
        argv => [@ARGV_COPY],

        # See http://stackoverflow.com/questions/3526420/how-do-i-get-the-current-user-in-perl-in-a-portable-way
        user => getlogin() || getpwuid($<),
        host => hostname(),
        date      => strftime( "%c", localtime() ),
        timestamp => join( '.',      @{$time} ),
        version   => _get_version(),
    );

    my $meta_file = Lab::Moose::DataFile::Meta->new(
        folder   => $self,
        filename => 'META.yml',
    );

    $self->_meta_file($meta_file);

    $meta_file->log( meta => \%meta_data );
}

sub _get_version {
    no strict 'vars';    ## no critic
    if ( defined $VERSION ) {
        return $VERSION;
    }
    else {
        return 'git';
    }
}

sub _get_folder_number {
    my ( $basename, $dirname ) = validated_list(
        \@_,
        basename => { isa => 'Str' },
        dirname  => { isa => 'Str' },
    );

    opendir my $dh, $dirname
        or croak "cannot open directory '$dirname'";

    my @entries = readdir $dh;

    @entries = map { decode( 'UTF-8', $_ ) } @entries;

    my $max = max map {
        my $entry = $_;
        if ( $entry =~ /^\Q${basename}\E_([0-9]+)$/ ) {
            my $num = $1;
        }
        else {
            my $num = 0;
        }
    } @entries;

    return $max + 1;
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::DataFolder - Create a data directory with meta data

=head1 VERSION

version 3.682

=head1 DESCRIPTION

A data logging setup consists of one Lab::Moose::DataFolder and one or more
L<Lab::Moose::DataFile> objects which live inside the DataFolder.

=head1 METHODS

=head2 new

 my $folder = Lab::Moose::DataFolder->new(path => 'foldername');
 # or equivalently use Lab::Moose loader:
 use Lab::Moose; my $folder = datafolder(path => 'foldername');

The actual foldername will consist of the C<path> argument and a numeric
suffix. Calling this function repeatedly will create the directories
F<foldername_001>, F<foldername_002>, ..., F<foldername_999>,
F<foldername_1000>.

After creation, the actual filename is contained in the C<path> attribute:

 my $path = $folder->path();

This method will create the following files in the folder:

=over

=item F<< <SCRIPT> .pl >>

A copy of the user script. You can change the name of this script by setting
the C<script_name> attribute in the constructor.

=item F<META.yml>

A YAML file containing meta data.
The L<Lab::Moose::DataFile::Meta> object is contained in the C<meta_file>
attribute:

 my $meta_file = $folder->meta_file();

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017-2018  Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
