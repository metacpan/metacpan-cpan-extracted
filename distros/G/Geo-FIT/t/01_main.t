# t/01_main.t - main testing file (for FIT.pm)
use strict;
use warnings;

use Test::More tests => 75;
use Geo::FIT;
use File::Temp qw/ tempfile tempdir /;

my $o = Geo::FIT->new();
isa_ok($o, 'Geo::FIT');

#
# open a file
$o->file( 't/10004793344_ACTIVITY.fit' );
$o->open();
# TODO: add a test here

#
# A - Fetch header
# may reconsider what is returned by fetch_header (potentially split into 2 methods -- do one thing, do it well)
my ($f_size, $protocol, $profile, $h_extra, $h_crc_expected, $h_crc_calculated) = $o->fetch_header;
is(	$f_size,      11074,                    "   test fetch_header() -- size");
is(	$protocol,       16,                    "   test fetch_header() -- protocol version");
is(	$profile,      2172,                    "   test fetch_header() -- profile  version");
is(	$h_extra,        '',                    "   test fetch_header() -- extra bytes in header");
is(	$h_crc_expected, $h_crc_calculated,     "   test fetch_header() -- crc (expected should match calculated");

#
# B - Definition Messages - Testing that we get expected definition/descriptors get defined

my @msg_names = (qw/ file_id file_creator/, undef, qw/ event device_info source /, undef,
                qw/ device_settings user_profile sensor /, undef, qw/ sport /,  undef,
                qw/ zones_target record battery / );

my ($i, $n_descriptors, $n_previous_pass) = (0, 0, 0);
while ( $o->fetch ) {

    $n_descriptors = @{$o->{data_message_descriptor}};

    if ($n_descriptors > $n_previous_pass) {
        my $msg_name = $msg_names[$i];

        is( defined $o->{data_message_descriptor}[$i], 1,                 "   test_fetch() -- data_message_descriptor");
        is( $o->{data_message_descriptor}[$i++]{message_name}, $msg_name, "   test_fetch() -- data_message_descriptor")
    }
    $n_previous_pass = $n_descriptors
}
$o->close();

#
# C - Data Messages - Testing that we get the expected data messages (checking with a callback)

#
# $o->reset;
# TODO: test reset

$o = Geo::FIT->new();
isa_ok($o, 'Geo::FIT');
$o->file( 't/10004793344_ACTIVITY.fit' );
$o->open();

($f_size, $protocol, $profile, $h_extra, $h_crc_expected, $h_crc_calculated) = $o->fetch_header;

# definining a message callback

my $message_name_from_callback;
sub callback_get_message_name {
    my ($self, $desc, $v, $o_cbmap) = @_;
    my $ret_val;
    if (defined $desc->{message_name} and $desc->{message_name} ne '') {
        $message_name_from_callback = $desc->{message_name};
        print "Local message type: $desc->{local_message_type} ($desc->{message_length} octets";
        print ", message name: $desc->{message_name}";
        print ", message number: $desc->{message_number})\n";
        $ret_val = $desc->{message_name}
    } else { $ret_val = 1 }                 # ensure we return true
    return $ret_val
}

my $o_cbmap = $o->data_message_callback_by_name('');
# need the following loop for names where a callback is already registered (there are 2 names) to replace the callback with our callback
for my $msgname (keys %$o_cbmap) {
    $o->data_message_callback_by_name($msgname, \&callback_get_message_name, $o_cbmap)
}
$o->data_message_callback_by_name('', \&callback_get_message_name, $o_cbmap);

# callback does not get called for unknown messages, so need a new list of message names
my @msg_names_data = (qw/ file_id file_creator event device_info device_info device_info device_info /,
                      qw/ source device_settings user_profile sensor sport /,
                      qw/ zones_target record battery record record / );

$i = 0;
while ( my $ret = $o->fetch ) {
    # test that we can indeed call callbacks and, for instance, get the message names

    if (defined $message_name_from_callback) {          # won't be defined for undef/unknown messages
        my $msg_name = $msg_names_data[$i++];
        is( $message_name_from_callback, $msg_name,  "   test_fetch() -- message name from callback function");
        is( $ret,                        $msg_name,  "   test_fetch() -- return value of fetch()");
        undef $message_name_from_callback;
    }
    last if $i==@msg_names_data
}
$o->close();

#
# Test errors

$o = Geo::FIT->new();
isa_ok($o, 'Geo::FIT');
$o->file( 't/10004793344_ACTIVITY.fit' );
my $c = $o->clone;
$o->open();
my @header_things = $o->fetch_header;
my $ret_val;
$ret_val = $o->fetch;        # we know it's a definition message
delete $o->{data_message_descriptor}[0];
$ret_val = $o->fetch;        # should encounter an error since no descriptor for the local message type
is( $ret_val, undef,  "   test_fetch() -- should encounter error and return undef, not croak");
$o->close();


my $callback_die_on_error = sub {
    my $self = shift;
    die "got an error: ", $self->error, "\n"
    };
$c->error_callback( $callback_die_on_error );
$c->open;
@header_things = $c->fetch_header;

$ret_val = $c->fetch;        # we know it's a definition message
# uncomment next line to test that it dies:
# delete $c->{data_message_descriptor}[0];
$ret_val = $c->fetch;        # should now die of error
$c->close();

print "so debugger doesn't exit\n";

