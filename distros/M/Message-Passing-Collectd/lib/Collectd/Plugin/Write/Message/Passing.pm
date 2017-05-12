package Collectd::Plugin::Write::Message::Passing;
use strict;
use warnings;
use Collectd ();
use JSON;
use Module::Runtime qw/ require_module /;
use String::RewritePrefix ();
use Try::Tiny;
use namespace::clean;

our $OUTPUT;
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

sub _output {
    if (!$OUTPUT) {
        try {
            my $out = $CONFIG{outputclass}->new(
                %{ $CONFIG{outputoptions} }
            );
            $OUTPUT = $CONFIG{encoderclass}->new(
                %{ $CONFIG{encoderoptions} },
                output_to => $out,
            );
        }
        catch {
            Collectd::plugin_log(Collectd::LOG_WARNING, "Got exception building outputs: $_ - DISABLING");
            undef $OUTPUT;
        }
    }
    return $OUTPUT;
}

sub init {
    if (!$CONFIG{outputclass}) {
        Collectd::plugin_log(Collectd::LOG_WARNING, "No outputclass config for Message::Passing plugin - disabling");
        return 0;
    }
    $CONFIG{outputclass} = String::RewritePrefix->rewrite(
        { '' => 'Message::Passing::Output::', '+' => '' },
        $CONFIG{outputclass}
    );
    if (!eval { require_module($CONFIG{outputclass}) }) {
        Collectd::plugin_log(Collectd::LOG_WARNING, "Could not load outputclass=" . $CONFIG{OutputClass} . " error: $@");
        return 0;
    }
    $CONFIG{encoderclass} ||= '+Message::Passing::Filter::Encoder::JSON';
    $CONFIG{encoderclass} = String::RewritePrefix->rewrite(
        { '' => 'Message::Passing::Filter::Encoder::', '+' => '' },
        $CONFIG{encoderclass}
    );
    if (!eval { require_module($CONFIG{encoderclass}) }) {
        Collectd::plugin_log(Collectd::LOG_WARNING, "Could not load encoderclass=" . $CONFIG{EncoderClass} . " error: $@");
        return 0;
    }
    $CONFIG{outputoptions} ||= {};
    $CONFIG{encoderoptions} ||= {};
    _output() || return 0;
    return 1;
}

my %_TYPE_LOOKUP = (
    0 => 'COUNTER',
    1 => 'GAUGE',
);
sub write {
    my ($name, $types, $data) = @_;
    # ["load",[{"min":0,"max":100,"name":"shortterm","type":1},{"min":0,"max":100,"name":"midterm","type":1},{"min":0,"max":100,"name":"longterm","type":1}],{"plugin":"load","time":1341655869.22588,"type":"load","values":[0.41,0.13,0.08],"interval":10,"host":"ldn-dev-tdoran.youdevise.com"}]
    # "transport.tx.size",[{"min":0,"max":0,"name":"transport.tx.size","type":0}],{"plugin":"ElasticSearch","time":1341655799.77979,"type":"transport.tx.size","values":[9725948078],"interval":10,"host":"ldn-dev-tdoran.youdevise.com"}
    my @values;
    foreach my $val (@{ $data->{values} }) {
        my $meta = shift(@$types);
        $meta->{value} = $val;
        push(@values, $meta);
        $meta->{type} = $_TYPE_LOOKUP{$meta->{type}} || $meta->{type};
    }
    $data->{values} = \@values;
    my $output = _output() || return 0;
    $output->consume($data);
    return 1;
}

Collectd::plugin_register(
    Collectd::TYPE_INIT, 'Write::Message::Passing', 'Collectd::Plugin::Write::Message::Passing::init'
);
Collectd::plugin_register(
    Collectd::TYPE_CONFIG, 'Write::Message::Passing', 'Collectd::Plugin::Write::Message::Passing::config'
);
Collectd::plugin_register(
    Collectd::TYPE_WRITE, 'Write::Message::Passing', 'Collectd::Plugin::Write::Message::Passing::write'
);

1;

=head1 NAME

Collectd::Plugin::Write::Message::Passing - Write collectd metrics via Message::Passing

=head1 SYNOPSIS

    <LoadPlugin perl>
        Globals true
    </LoadPlugin>
    <Plugin perl>
        BaseName "Collectd::Plugin"
        LoadPlugin "Write::Message::Passing"
        <Plugin "Write::Message::Passing">
            # MANDATORY - You MUST configure an output class
            outputclass "ZeroMQ"
            <outputoptions>
                connect "tcp://192.168.0.1:5552"
            </outputoptions>
            # OPTIONAL - Defaults to JSON
            #encoderclass "JSON"
            #<encoderoptions>
            #   pretty "0"
            #</encoderoptions>
        </Plugin>
    </Plugin>

    Will emit metrics like this:

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
                "min":0,
                "max":100,
                "name":"shortterm",
                "type":"GAUGE"
            },
            {
                "value":0.13,
                "min":0,
                "max":100,
                "name":"midterm",
                "type":"GAUGE"
            },
            {
                "value":0.08
                "min":0,
                "max":100,
                "name":"longterm",
                "type":"GAUGE"
            }
        ],
        "interval":10,
        "host":"t0m.local"
    }

=head1 DESCRIPTION

A collectd plugin to emit metrics from L<collectd|http://collectd.org/> into L<Message::Passing>.

=head1 PACKAGE VARIABLES

=head2 %CONFIG

A hash containing the following:

=head3 outputclass

The name of the class which will act as the Message::Passing output. Will be used as-is if prefixed with C<+>,
otherwise C<Message::Passing::Output::> will be prepended. Required.

=head3 outputoptions

The hash of options for the output class. Not required, but almost certainly needed.

=head3 encoderclass

The name of the class which will act  the Message::Passing encoder. Will be used as-is if prefixed with C<+>,
otherwise C<Message::Passing::Filter::Encoder::> will be prepended. Optional, defaults to L<JSON|Message::Passing::Filter::Encoder::JSON>.

=head3 encoderoptions

The hash of options for the encoder class.

=head1 FUNCTIONS

=head2 config

Called first with configuration in the config file, munges it into the format expected
and places it into the C<%CONFIG> hash.

=head2 init

Validates the config, and initializes the C<$OUTPUT>

=head2 write

Writes a metric to the output in C<$OUTPUT>.

=head1 BUGS

Never enters the L<AnyEvent> event loop, and therefore may only work reliably with
(and is only tested with) L<Message::Passing::Output::ZeroMQ>.

=head1 AUTHOR, COPYRIGHT & LICENSE

See L<Message::Passing::Collectd>.

=cut

