package Hash::Storage::Driver::Base;

our $VERSION = '0.03';

use v5.10;
use strict;
use warnings;

use Carp qw/croak/;
use File::Spec;
use Fcntl qw/:flock/;

use Data::Serializer::Raw;
use Query::Abstract;

sub new {
    my $class = shift;
    my %args  = @_;

    my $serializer = $args{serializer};
    croak "Wrong serializer" unless $serializer;

    my $self = bless \%args, $class;

    if (! ref $serializer ) {
        if ($serializer ne 'Dummy') {
            $self->{serializer} = Data::Serializer::Raw->new(serializer => $serializer);
        }
    } elsif ( $serializer->can('serialize') && $serializer->can('deserialize') ) {
        $self->{serializer} = $serializer;
    } else {
        croak "Wrong serializer [$serializer]";
    }
    return $self;
}

sub init {
    my ($self) = @_;
    my $class = ref $self || $self;
    croak "Method [init] is not implemented in class [$class]";
}

sub get {
    my ( $self, $id ) = @_;
    my $class = ref $self || $self;
    croak "Method [get] is not implemented in class [$class]";
}

sub set {
    my ( $self, $id, $fields ) = @_;
    my $class = ref $self || $self;
    croak "Method [set] is not implemented in class [$class]";
}

sub del {
    my ( $self, $id ) = @_;
    my $class = ref $self || $self;
    croak "Method [del] is not implemented in class [$class]";
}

sub list {
    my ( $self, @query ) = @_;
    my $class = ref $self || $self;
    croak "Method [list] is not implemented in class [$class]";
}

sub count {
    my ( $self, $filter ) = @_;
    my $class = ref $self || $self;
    croak "Method [count] is not implemented in class [$class]";
}

sub do_filtering {
    my ( $self, $hashes, $query ) = @_;
    my $qa = Query::Abstract->new( driver => ['ArrayOfHashes'] );
    my $filter_sub = $qa->convert_query(@$query);
    return $filter_sub->($hashes);
}

sub do_exclusively {
    my ($self, $cb) = @_;
    croak "Subroutine reference required" unless ref($cb) eq 'CODE';

    state $semophore = File::Spec->tmpdir() . '/hash_storage.semaphore';
    open( my $fh, '>', $semophore ) or die "Cannot open semaphore [$semophore] $!";

    flock( $fh, LOCK_EX ) or die "Cannot lock  semaphore [$semophore] $!";
    $cb->();
    flock( $fh, LOCK_UN ) or die "Cannot unlock semaphore [$semophore] $!";
}

1;    # End of Hash::Storage