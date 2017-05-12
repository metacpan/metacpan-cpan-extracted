package Hash::Storage::Driver::Files;

our $VERSION = '0.03';

use v5.10;
use strict;
use warnings;

use File::Slurp;
use Carp qw/croak/;
use Digest::MD5 qw/md5_hex/;

use base 'Hash::Storage::Driver::Base';

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(%args);
    croak "WRONG DIR [$self->{dir}]" unless -d $self->{dir};
    return $self;
}

sub init {
    my ($self) = @_;
}

sub get {
    my ( $self, $id ) = @_;

    my $file = $self->_file_by_id($id);
    return unless -e $file;

    my $serialized = read_file($file);
    return $self->{serializer}->deserialize($serialized);
}

sub set {
    my ( $self, $id, $fields ) = @_;

    $self->do_exclusively( sub {
        my $data = $self->get($id) || {};
        @{$data}{ keys %$fields } = values %$fields;

        my $serialized = $self->{serializer}->serialize($data);
        write_file( $self->_file_by_id($id), { atomic => 1 }, $serialized );
    } );
}

sub del {
    my ( $self, $id ) = @_;
    $self->do_exclusively( sub {
        unlink( $self->_file_by_id($id) );
    });
}

sub list {
    my ( $self, @query ) = @_;
    my $dir = $self->{dir};
    my @hashes;

    opendir( my $dh , $dir ) or die "Cannot open dir [$dir]";
    while ( my $file = readdir($dh) ){
        next if $file !~ /^[a-f0-9]+\.hst$/;

        my $serialized = read_file("$dir/$file");
        push @hashes, $self->{serializer}->deserialize($serialized);
    }

    return $self->do_filtering(\@hashes, \@query);
}

sub count {
    my ( $self, $filter ) = @_;
    my $hashes = $self->list(where => $filter);
    return scalar(@$hashes);
}

sub _file_by_id {
    my ( $self, $id ) = @_;
    return $self->{dir} . '/' . md5_hex($id)  . '.hst';
}

1;
