package Message::Passing::Output::MongoDB;

# ABSTRACT: Module for Message::Passing to send log to mongodb

use Moose;
use MongoDB;
use AnyEvent;
use Scalar::Util qw/ weaken /;
use MooseX::Types::Moose qw/ ArrayRef HashRef Str Bool Int Num /;
use Moose::Util::TypeConstraints;
use aliased 'DateTime' => 'DT';
use MooseX::Types::ISO8601 qw/ ISO8601DateTimeStr /;
use Data::Dumper;
use Tie::IxHash;
use namespace::autoclean;

our $VERSION = '0.052';
$VERSION = eval $VERSION;

with qw/
    Message::Passing::Role::Output
    Message::Passing::Role::HasUsernameAndPassword
/;

has connection_options => (
    is => 'ro',
    isa => 'HashRef',
    required => 1,
);

has '+password' => (
    required => 0,
);

has '+username' => (
    required => 0,
);

has database => (
    isa => Str,
    is => 'ro',
    required => 1,
);

has _client  => (
    is  => 'ro',
    isa => 'MongoDB::MongoClient',
    lazy => 1,
    default => sub {
        my $self = shift;
        MongoDB::MongoClient->new( 
            $self->connection_options
        );
    },
);

has _db => (
    is => 'ro',
    isa => 'MongoDB::Database',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $client = $self->_client;

        my $database = $self->database;
        if (defined $self->username) {
            $client->authenticate($database, $self->username, $self->password)
            or die "MongoDB authentication failure";
        }

        return $client->get_database($self->database);
    },
);

has collection => (
    isa => Str,
    is => 'ro',
    required => 1,
);

has _collection_of_day => (
    is       => 'rw',
    isa      => 'MongoDB::Collection',
    lazy => 1,
    builder => '_build_collection_of_day',
);

sub _build_collection_of_day {
    my ($self) = @_;

    my $dt = DateTime->now;
    my $collection_name_by_date = $self->collection .'_'. $dt->strftime('%Y%m%d');

    return $self->_db->get_collection($collection_name_by_date);
}

sub _ensure_collection_indexes {
    my ($self, $collection) = @_;
    $collection //= $self->_collection_of_day;

    if ($self->_has_indexes) {
        foreach my $index (@{$self->indexes}){
            $collection->ensure_index(@$index);
            warn("ensure index " . Dumper($index)) if $self->verbose;
        }
    }

    return $collection;
}

has _collection_of_day_name  => (
    is => 'rw',
    isa => Str,
);

sub _get_collection_by_date {
    my ($self, $dt) = @_;
    
    my $collection_name_by_date = $self->collection .'_'. $dt->strftime('%Y%m%d');
    # a new collection 
    if (!defined $self->_collection_of_day_name || $self->_collection_of_day_name ne $collection_name_by_date) {
        $self->_flush;
        my $collection_by_date = $self->_db->get_collection($collection_name_by_date);
        $self->_ensure_collection_indexes($collection_by_date);
        $self->_collection_of_day 
            and $self->_remove_expired_collection();
        $self->_collection_of_day($collection_by_date);
        $self->_collection_of_day_name($collection_name_by_date)
    }

    return $collection_name_by_date;
}

sub _remove_expired_collection{
    my ($self) = @_;
    
    my $retention_date = DT->now()->subtract(days => $self->retention );
    my $expired_collection_name = $self->collection .'_'. $retention_date->strftime('%Y%m%d');

    $self->_db->get_collection($expired_collection_name)->drop; 
}

sub _default_port { 27017 }

has _log_counter => (
    traits  => ['Counter'],
    is => 'rw',
    isa => Int,
    default => sub {0},
    handles => { _inc_log_counter => 'inc', },
);

has verbose => (
    isa => 'Bool',
    is => 'ro',
    default => sub {
        -t STDIN
    },
);

sub consume {
    my ($self, $data) = @_;
     return unless $data;
    
    my $date;
    if (my $epochtime = delete($data->{epochtime})) {
        $date = DT->from_epoch(epoch => $epochtime);
        delete($data->{date});
    }
    elsif (my $try_date = delete($data->{date})) {
        if (is_ISO8601DateTimeStr($try_date)) {
            $date = to_DateTime($try_date);
        }
    }
    $date ||= DT->from_epoch(epoch => time());
    
    my $collection = $self->_get_collection_by_date($date);

    push (@{$self->queue}, $data);

    if (scalar(@{$self->queue}) > 1000) {
        $self->_flush;
    }

    #$collection->insert($data)
        #or warn "Insertion failure: " . Dumper($data) . "\n";
    if ($self->verbose) {
        $self->_inc_log_counter;
        warn("Total " . $self->_log_counter . " records inserted in MongoDB\n");
    }
}

sub _flush {
    my $self = shift;
    weaken($self);
    return if $self->_am_flushing;
    my $queue = $self->queue;
    return unless scalar @$queue;
    $self->_am_flushing(1);

    eval {
        $self->_collection_of_day->batch_insert($queue);
        1;
    } or do {
        $self->_client->connect();
        warn("Failed to do the insertion of logs. \n");
    };
    $self->_clear_queue;
    $self->_am_flushing(0);
}

has queue => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [] },
    init_arg => undef,
    lazy => 1,
    clearer => '_clear_queue',
);

has _am_flushing => (
    isa => Bool,
    is => 'rw',
    default => 0,
);

has _flush_timer => (
    is => 'ro',
    lazy => 1,
    builder => '_build_flush_time',
);

sub _build_flush_time {
    my $self = shift;
    weaken($self);
    AnyEvent->timer(
        after => 10,
        interval => 10,
        cb => sub { $self->_flush },
    );
}

has indexes => (
    isa => ArrayRef[ArrayRef[HashRef]],
    is => 'ro',
    predicate => '_has_indexes',
);

has retention => (
    is => 'ro',
    isa => Num,
    default => 7, # days
    documentation => 'Int, days to retent log, set 0 to always keep log',
);

has collect_fields => (
    isa => 'Bool',
    is => 'ro',
    default => 0,
);

has _observer => (
    is => 'ro',
    lazy => 1,
    builder => '_build_observer'
);

sub _build_observer {
    my $self = shift;
    weaken($self);
    my $retention_date = DT->now()->subtract(days => $self->retention);
    AnyEvent->timer(
        after => 30,
        interval => 24*3600,
        cb => sub {
        }
    );
}

sub BUILD {
    my ($self) = @_;
    $self->_flush_timer;
    $self->_observer
        if $self->collect_fields;
}

1;

=head1 NAME

Message::Passing::Output::MongoDB - message-passing out put to MongoDB

=head1 SYNOPSIS

    message-pass --input STDIN 
      --output MongoDB --output_options '{ "database":"log_database", "collection":"logs"}'
    
    {"foo":"bar"}

=head1 DESCRIPTION

Module for L<Message::Passing>, send output to MongoDB

=head1 METHODS

=over

=item consume

Consumes a message by JSON encoding it save it in MongoDB

=back

=head1 ATTRIBUTES

=over

=item database

Required, Str, the database to use.

=item collection

Required, Str, the collection to use.

=item connection_options

HashRef, takes any options as MongoDB::MongoClient->new(\%options) do

=item username

Str, mongodb authentication user

=item password

Str, mongodb authentication password

=item indexes

ArrayRef[ArrayRef[HashRef]], mongodb indexes

    ...
    indexes => [
        [{"foo" => 1, "bar" => -1}, { unique => true }],
        [{"foo" => 1}],
    ]
    ...

=item collect_fields

Bool, default to 0, set to 1 to collect the fields' key and inserted in collection
$self->collection . "_keys", execution at the starting and once per day.

=item retention

Int, time in seconds to conserver logs, set 0 to keep it permanent, default is
a week

=item verbose

Boolean, verbose

=back

=head1 SEE ALSO

L<Message::Passing>

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API - 
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut

