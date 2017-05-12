package Hostfile::Manager;

use strict;
use warnings;
use Moose;
use File::Find;
use File::Slurp;
use File::Basename qw/dirname/;

our $VERSION = '0.08';

=head1 NAME

Hostfile::Manager - Manage a hostfile by composing multiple fragments into a whole.

=head1 SYNOPSIS

	use Hostfile::Manager;

	$manager = Hostfile::Manager->new;
	$manager->enable_fragment($fragment_name);
	$manager->write_hostfile;

=head1 ACCESSORS

=over 6

=item B<< Str path_prefix( [Str $prefix] ) >>

Defines the prefix that will be searched for hostfile fragments.  Defaults to '/etc/hostfiles/'.

=cut

has path_prefix => (
    is      => 'rw',
    isa     => 'Str',
    default => '/etc/hostfiles/',
);

=item B<< Str hostfile_path( [Str $path] ) >>

Defines the path to the hostfile to manage.  Defaults to '/etc/hosts'.

=cut

has hostfile_path => (
    is      => 'rw',
    isa     => 'Str',
    default => '/etc/hosts',
);

=item B<< Str hostfile >>

The contents of the hostfile under management.

=cut

has hostfile => (
    is       => 'ro',
    isa      => 'Str',
    writer   => '_set_hostfile',
    lazy     => 1,
    builder  => 'load_hostfile',
    init_arg => undef,
);

has blocks => (
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { {} },
    init_arg => undef,
);

=item B<< HashRef fragments >>

The available hostfile fragments.

=item B<< Array fragment_list >>

A list of the names of available fragments.

=item B<< Str get_fragment( Str $fragment_name ) >>

The contents of an individual hostfile fragment.

=back

=cut

has fragments => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    traits  => ['Hash'],
    lazy    => 1,
    builder => '_load_fragments',
    handles => {
        fragment_list => 'keys',
        get_fragment  => 'get',
    },
    init_arg => undef,
);

=head1 METHODS

=over 6

=item B<< Hostfile::Manager->new( [\%options] ) >>

Create a new manager instance.  Available options are B<path_prefix> and B<hostfile_path>, listed in the L<ACCESSORS|/"ACCESSORS"> section.

=cut

sub load_hostfile {
    my ( $self, $filename ) = @_;

    $filename = $self->hostfile_path unless defined $filename;

    unless ( -e $filename ) {
        Carp::croak("Hostfile must exist.  File not found at $filename");
    }

    my $file = read_file($filename);
    $self->_set_hostfile($file);
}

=item B<< Bool write_hostfile >>

Write the contents of the hostfile to disk.

=cut

sub write_hostfile {
    my $self = shift;

    my $filename = $self->hostfile_path;

    unless ( ( !-e $filename && -w dirname($filename) ) || -w $filename ) {
        Carp::croak("Unable to write hostfile to $filename");
    }

    write_file( $filename, $self->hostfile );
}

=item B<< Bool fragment_enabled( Str $fragment_name ) >>

Test whether a named fragment is enabled in the hostfile under management.

=cut

sub fragment_enabled {
    my ( $self, $fragment_name ) = @_;

    $self->hostfile =~ $self->block($fragment_name);
}

=item B<< enable_fragment( Str $fragment_name ) >>

Enable a named fragment.  If the fragment is currently enabled, it will be disabled first, removing any modifications that may have been made out-of-band.

=cut

sub enable_fragment {
    my ( $self, $fragment_name ) = @_;

    my $fragment = $self->get_fragment($fragment_name) or return;

    $self->disable_fragment($fragment_name)
      if $self->fragment_enabled($fragment_name);
    $self->_set_hostfile( $self->hostfile
          . "# BEGIN: $fragment_name\n$fragment# END: $fragment_name\n" );
}

=item B<< disable_fragment( Str $fragment_name ) >>

Disable a named fragment.

=cut

sub disable_fragment {
    my ( $self, $fragment_name ) = @_;

    my $hostfile = $self->hostfile;
    $hostfile =~ s/@{[$self->block($fragment_name)]}//g;

    $self->_set_hostfile($hostfile);
}

=item B<< toggle_fragment( Str $fragment_name ) >>

Enable a fragment if it is disabled, disable it otherwise.

=cut

sub toggle_fragment {
    my ( $self, $fragment_name ) = @_;

    if ( $self->fragment_enabled($fragment_name) ) {
        $self->disable_fragment($fragment_name);
    }
    else {
        $self->enable_fragment($fragment_name);
    }
}

sub block {
    my ( $self, $block_name ) = @_;

    $self->blocks->{$block_name} ||=
qr/#+\s*BEGIN: $block_name[\r\n](.*)#+\s*END: $block_name[\r\n]/ms;
    return $self->blocks->{$block_name};
}

sub _load_fragments {
    my $self      = shift;
    my $fragments = {};
    my $prefix    = $self->path_prefix;

    find(
        {
            wanted => sub {
                return if -d $_;
                $_ =~ s{^$prefix}{};
                $fragments->{$_} = $self->_load_fragment($_);
            },
            no_chdir => 1
        },
        $prefix
    );

    $fragments;
}

sub _load_fragment {
    my ( $self, $fragment_name ) = @_;

    my $filename = $self->path_prefix . $fragment_name;

    unless ( -e $filename ) {
        Carp::carp("Fragment not found at $filename");
        return;
    }

    read_file($filename);
}

=item B<< Str fragment_status_flag( Str $fragment_name ) >>

Returns a string indicating the current status of a named fragment.

=over 2

=item B<"+">

The named fragment is enabled.

=item B<"*">

The named fragment is enabled and has been modified in the sourced hostfile.

=item B<" ">

The named fragment is not enabled.

=back

=back

=cut

sub fragment_status_flag {
    my ( $self, $fragment_name ) = @_;
    my $fragment_contents = $self->get_fragment($fragment_name);

    my ($found) = $self->hostfile =~ /@{[$self->block($fragment_name)]}/g;
    return $found ? ( $found eq $fragment_contents ? "+" : "*" ) : " ";
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 LICENSE

Copyright (c) 2010-11 Anthony J. Mirabella. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Anthony J. Mirabella <mirabeaj AT gmail DOT com>
