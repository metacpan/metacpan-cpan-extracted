package Linux::Info::Distribution::OSRelease;

use warnings;
use strict;
use Carp qw(confess);
use parent 'Linux::Info::Distribution';
use Hash::Util qw(lock_hash unlock_hash);
use Class::XSAccessor getters => {
    get_pretty_name => 'pretty_name',
    get_id_like     => 'id_like',
    get_home_url    => 'home_url',
};

use constant DEFAULT_FILE => '/etc/os-release';

our $VERSION = '2.15'; # VERSION

# ABSTRACT: a subclass with data from /etc/os-release file


sub _validate_file_path {
    my $file_path = shift;
    confess 'Must receive the complete path to a file'
      unless ( defined $file_path );
    confess( 'must be a scalar (string), not ' . ref($file_path) )
      unless ( ref $file_path eq '' );
}

sub _parse {
    my $file_path = shift;
    _validate_file_path($file_path);

    open( my $in, '<', $file_path ) or confess "Cannot read $file_path: $!";
    my %data;

    while (<$in>) {
        chomp;
        next if $_ eq '';
        my @pieces = split( '=', $_ );
        $pieces[1] =~ tr/"//d;
        $data{ ( lc $pieces[0] ) } = $pieces[1];
    }

    close $in or confess "Cannot close $file_path: $!";
    return \%data;
}


sub parse {
    my $self = shift;
    confess 'This is a instance method call, use parse_from_file instead'
      unless ( ref $self ne '' );

    $self->{source} = DEFAULT_FILE unless ( defined $self->{source} );
    return _parse( $self->{source} );
}


sub parse_from_file {
    return _parse( $_[1] )      if ( length( scalar(@_) ) == 2 );
    return _parse(DEFAULT_FILE) if ( $_[0] eq __PACKAGE__ );
    return _parse( $_[0] );
}


sub _handle_missing { }


sub new {
    my ( $class, $file_path ) = @_;

    if ( defined($file_path) ) {
        _validate_file_path($file_path);
    }
    else {
        $file_path = DEFAULT_FILE;
    }

    my $info_ref = parse_from_file($file_path);
    $class->_handle_missing( $info_ref, $file_path );

    my $self = $class->SUPER::new($info_ref);
    unlock_hash( %{$self} );
    $self->{source} = $file_path;
    $self->{cache}  = $info_ref;

    if ( exists $info_ref->{id_like} ) {
        my @distros = split( /\s/, $info_ref->{id_like} );
        $self->{id_like} = \@distros;
        delete $info_ref->{id_like};
    }
    else {
        $self->{id_like} = [];
    }

    foreach my $attrib (qw(pretty_name home_url)) {
        $self->{$attrib} = $info_ref->{$attrib};
    }

    lock_hash( %{$self} );
    return $self;
}


sub clean_cache {
    my $self = shift;
    delete( $self->{cache} );
}


sub get_source {
    return shift->{source};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::Distribution::OSRelease - a subclass with data from /etc/os-release file

=head1 VERSION

version 2.15

=head1 SYNOPSIS

    use Linux::Info::Distribution::OSRelease;
    my $os = Linux::Info::Distribution::OSRelease->new;

    # fetch the default file location
    print Linux::Info::Distribution::OSRelease::DEFAULT_FILE, "\n";

=head1 DESCRIPTION

This is a subclass of L<Linux::Info::Distribution>, which data is retrieved by
reading the standard F</etc/os-release> file, which usually provides more
fields than custom files.

Such file might contain only the minimal informatior required by the base
class, but most probably will provide more fields.

    NAME="Ubuntu"
    VERSION_ID="22.04"
    VERSION="22.04.4 LTS (Jammy Jellyfish)"
    ID=ubuntu

This classes provides a parser to retrieve those fields and more from the
default location or any other provided.

For subclasses that doesn't provide all those fields, it will be required
to setup some workaround, like setting the key value with C<undef>. In order to
achieve that, subclasses B<must> override the "private" class method
C<_handle_missing>.

=head1 METHODS

=head2 parse

A class method, i.e., doesn't require a instance to be invoked.

Optionally, accepts a file path to the different file instead using the
default one.

Returns a hash reference, with all fields/values retrieve from the file.

The fields, stored as keys, will be forced to be on lowercase.

=head2 parse

Instance method. Parses a file with the expected format of F</etc/os-release>.

=head2 parse_from_file

Class method. Parses a file with the expected format of F</etc/os-release>.

Optionally, accepts a string as the complete path to a file to be parsed.

=head2 _handle_missing

"Private" method that handles missing fields.

It should be overrided by subclasses of this class.

It expects as positional parameter a hash reference with the content returned
from C<parse> method.

This method returns nothing.

=head2 new

Creates and returns a new instance.

Expects the same optional parameter of C<parse>, and uses this same method
to parse the file content.

=head2 clean_cache

This class caches the information read from the source file into memory, so
subclasses can reuse this information to handle additional attributes.

After that, the information is usually not necessary anymore and should be
removed by invoking this method.

=head2 get_source

Returns a string with the file path from where the information was retrieved.

=head2 get_pretty_name

Returns the "pretty" name of distribution, which is actually just a longer
string than the name.

=head2 get_id_like

Returns an array reference containing the distribution ID of all distributions
directly related to this one (a parent distribution, or siblings).

Not all distributions will have such value, but a default empty array will be
provided by this class.

=head2 get_home_url

Returns the home URL of distribution.

=head1 EXPORTS

Nothing.

The default location of the source file can be retrieved with the
C<DEFAULT_FILE> constant.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
