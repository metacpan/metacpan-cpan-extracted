package Collectd::Plugin::Read::Message::Passing;
use strict;
use warnings;
use Collectd ();
use JSON;
use Module::Runtime qw/ require_module /;
use String::RewritePrefix ();
use Try::Tiny;
use Message::Passing::Output::Callback;
use AnyEvent;
BEGIN {
    *tid = eval {
        require threads;
    } ? sub { threads->tid } : sub { 0 };
}
use namespace::clean;

our $INPUT;
our %CONFIG;

sub _clean_value {
    my $val = shift;
    scalar(@$val) > 1 ? $val : $val->[0];
}

sub _flatten_item {
    my $item = shift;
    my $val;
    if (scalar(@{$item->{children}})) {
        $val = [ map { my $i = $_; _flatten_item($i) } @{$item->{children}} ];
    }
    else {
        $val = $item->{values};
    }
    return {
        $item->{key} => _clean_value($val)
    }
}

sub config {
    my @items = @{ $_[0]->{children} };
    foreach my $item (@items) {
        %CONFIG = ( %{_flatten_item($item)} , %CONFIG );
    }
}

my %_TYPE_LOOKUP = (
    'COUNTER' => 0,
    'GAUGE' => 1,
);

sub _do_message_passing_read {
    my $message = shift;
    Collectd::plugin_log(Collectd::LOG_WARNING, "Got message from Message::Passing " . JSON::encode_json($message));
    my $vl = {
        values => [ map { $_->{value} } @{$message->{values}} ],
        plugin => $message->{plugin},
        type => $_TYPE_LOOKUP{$message->{values}->[0]->{type}},
    };
    $vl = {
        values => [ map { $_->{value} } @{$message->{values}} ],
        plugin => $message->{plugin},
        type => $message->{type},
        $message->{plugin_instance} ? (plugin_instance => $message->{plugin_instance}) : (),
    };
    Collectd::plugin_log(Collectd::LOG_WARNING, "Got message for collectd " . JSON::encode_json($vl));
    Collectd::plugin_dispatch_values($vl);
}

# ["load",[{"min":0,"max":100,"name":"shortterm","type":1},{"min":0,"max":100,"name":"midterm","type":1},{"min":0,"max":100,"name":"longterm","type":1}],{"plugin":"load","time":1341655869.22588,"type":"load","values":[0.41,0.13,0.08],"interval":10,"host":"ldn-dev-tdoran.youdevise.com"}]
# "transport.tx.size",[{"min":0,"max":0,"name":"transport.tx.size","type":0}],{"plugin":"ElasticSearch","time":1341655799.77979,"type":"transport.tx.size","values":[9725948078],"interval":10,"host":"ldn-dev-tdoran.youdevise.com"}
sub _input {
    if (!$INPUT) {
        try {
            my $out = Message::Passing::Output::Callback->new(
                cb => \&_do_message_passing_read,
            );
            my $decoder = $CONFIG{decoderclass}->new(
                %{ $CONFIG{decoderoptions} },
                output_to => $out,
            );
            $INPUT = $CONFIG{inputclass}->new(
                %{ $CONFIG{inputoptions} },
                output_to => $decoder,
            );
        }
        catch {
            Collectd::plugin_log(Collectd::LOG_WARNING, "Got exception building inputs: $_ - DISABLING thread id " . tid());
            undef $INPUT;
        };
    }
    return $INPUT;
}

sub init {
    if (!$CONFIG{inputclass}) {
        Collectd::plugin_log(Collectd::LOG_WARNING, "No inputclass config for Message::Passing plugin - disabling PID $$ TID " . tid());
        return 0;
    }
    $CONFIG{inputclass} = String::RewritePrefix->rewrite(
        { '' => 'Message::Passing::Input::', '+' => '' },
        $CONFIG{inputclass}
    );
    if (!eval { require_module($CONFIG{inputclass}) }) {
        Collectd::plugin_log(Collectd::LOG_WARNING, "Could not load inputclass=" . $CONFIG{InputClass} . " error: $@");
        return 0;
    }
    $CONFIG{decoderclass} ||= '+Message::Passing::Filter::Decoder::JSON';
    $CONFIG{decoderclass} = String::RewritePrefix->rewrite(
        { '' => 'Message::Passing::Filter::Decoder::', '+' => '' },
        $CONFIG{decoderclass}
    );
    if (!eval { require_module($CONFIG{decoderclass}) }) {
        Collectd::plugin_log(Collectd::LOG_WARNING, "Could not load decoderclass=" . $CONFIG{decoderclass} . " error: $@");
        return 0;
    }
    $CONFIG{inputoptions} ||= {};
    $CONFIG{decoderoptions} ||= {};
    $CONFIG{readtimeslice} = 0.25;
    return 1;
}

sub read {
    _input();
    my $cv = AnyEvent->condvar;
    my $t = AnyEvent->timer(
        after => $CONFIG{readtimeslice},
        cb => sub { $cv->send },
    );
    $cv->recv;
    undef $t;

    return 1;
}

Collectd::plugin_register(
    Collectd::TYPE_INIT, 'Read::Message::Passing', 'Collectd::Plugin::Read::Message::Passing::init'
);
Collectd::plugin_register(
    Collectd::TYPE_CONFIG, 'Read::Message::Passing', 'Collectd::Plugin::Read::Message::Passing::config'
);
Collectd::plugin_register(
    Collectd::TYPE_READ, 'Read::Message::Passing', 'Collectd::Plugin::Read::Message::Passing::read'
);

1;

=head1 NAME

Collectd::Plugin::Read::Message::Passing - Read collectd metrics via Message::Passing

=head1 SYNOPSIS

    # Only tested with 1 read thread!
    ReadThreads   1
    # You MUST setup types.db for all types you emit!
    TypesDB       "/usr/share/collectd/types.db"
    TypesDB       "/usr/local/share/collectd/types_local.db"
    <LoadPlugin perl>
        Globals true
    </LoadPlugin>
    <Plugin perl>
        BaseName "Collectd::Plugin"
        LoadPlugin "Read::Message::Passing"
        <Plugin "Read::Message::Passing">
            # MANDATORY - You MUST configure an output class
            inputclass "ZeroMQ"
            <inputoptions>
                socket_bind "tcp://192.168.0.1:5552"
            </inputoptions>
            # OPTIONAL - Defaults to JSON
            #decoderclass "JSON"
            #<decoderoptions>
            #</decoderoptions>
        </Plugin>
    </Plugin>

    Will consume metrics like this:

    {
        "plugin":"ElasticSearch",
        "time":1341656031.18621,
        "values":[
            {
                "value":0,
                "min":0,
                "name":"indices.get.time",
                "max":0,
                "type":0
            }
        ],
        "type":"indices.get.time",
        "interval":10,
        "host":"t0m.local"
    }

    or, for multi-value metrics:

    {
        "plugin":"load",
        "time":1341655869.22588,
        "type":"load",
        "values":[
            {
                "value":0.41,
                "min":0,"max":100,"name":"shortterm","type":1
            },
            {
                "value":0.13,
                "min":0,
                "max":100,
                "name": "midterm",
                "type":1
            },
            {
                "value":0.08
                "min":0,
                "max":100,
                "name":"longterm",
                "type":1
            }
        ],
        "interval":10,
        "host":"t0m.local"
    }

=head1 DESCRIPTION

A collectd plugin to consume metrics from L<Message::Passing> into L<collectd|http://collectd.org/>.

B<WARNING:> This plugin is pre-alpha, and is only tested with 1 collectd thread and the ZeroMQ Input.

B<NOTE:> You B<MUST> have registered any types you ingest in a C<types.db> for collectd. Failure to do this can result in segfaults!

=head1 PACKAGE VARIABLES

=head2 %CONFIG

A hash containing the following:

=head3 inputclass

The name of the class which will act as the Message::Passing output. Will be used as-is if prefixed with C<+>,
otherwise C<Message::Passing::Input::> will be prepended. Required.

=head3 inputoptions

The hash of options for the input class. Not required, but almost certainly needed.

=head3 decoderclass

The name of the class which will act  the Message::Passing decoder. Will be used as-is if prefixed with C<+>,
otherwise C<Message::Passing::Filter::Decoder::> will be prepended. Optional, defaults to L<JSON|Message::Passing::Filter::Decoder::JSON>.

=head3 decoderoptions

The hash of options for the decoder class.

=head3 readtimeslice

The amount of time to block in Message::Passing's read loop. Defaults to 0.25 seconds, which could
not be enough if you are consuming a lot of metrics..

=head1 FUNCTIONS

=head2 config

Called first with configuration in the config file, munges it into the format expected
and places it into the C<%CONFIG> hash.

=head2 init

Validates the config, and initializes the C<$INPUT>

=head2 read

Blocks for a metric to the output in C<$INPUT>.

=head1 BUGS

Blocking collectd for a fixed time to allow the AnyEvent loop to run is a horrible horrible way
of reading.

=head1 AUTHOR, COPYRIGHT & LICENSE

See L<Message::Passing::Collectd>.

=cut

