package Message::Passing::DSL;
use Message::Passing::DSL::Factory;
use Carp qw/ confess /;
use Scalar::Util qw/ blessed weaken /;
use AnyEvent;
use Exporter qw/ import /;

our @EXPORT = qw/
    run_message_server message_chain input filter output decoder encoder error_log
/;

our $FACTORY;
sub _check_factory {
    confess("Not inside a message_chain { block!!") unless $FACTORY;
}

sub message_chain (&) {
    my $code = shift;
    if ($FACTORY) {
        confess("Cannot chain within a chain");
    }
    local $FACTORY = Message::Passing::DSL::Factory->new;
    $code->();
    my %items = %{ $FACTORY->registry };
    $FACTORY->clear_registry;
    weaken($items{$_}) for
        grep { blessed($items{$_}) && $items{$_}->can('consume') }
        keys %items;
    foreach my $name (keys %items) {
        next if $items{$name};
        warn "Unused output or filter $name in chain\n";
    }
    return [
        grep { ! ( blessed($_) && $_->can('consume') ) }
        grep { blessed($_) && $_->can('output_to') }
        values %items
    ];
}

sub error_log {
    my %opts = @_;
    _check_factory();
    $FACTORY->set_error(
        %opts,
    );
}

sub input {
     my ($name, %opts) = @_;
    _check_factory();
    $FACTORY->make(
        %opts,
        name => $name,
        _type => 'Input',
    );
}

sub filter {
     my ($name, %opts) = @_;
    _check_factory();
    $FACTORY->make(
        %opts,
        name => $name,
        _type => 'Filter',
    );
}

sub output {
    my ($name, %opts) = @_;
    _check_factory();
    $FACTORY->make(
        %opts,
        name => $name,
        _type => 'Output',
    );
}

sub decoder {
     my ($name, %opts) = @_;
    _check_factory();
    $FACTORY->make(
        %opts,
        name => $name,
        _type => 'Filter::Decoder',
    );
}

sub encoder {
     my ($name, %opts) = @_;
    _check_factory();
    $FACTORY->make(
        %opts,
        name => $name,
        _type => 'Filter::Encoder',
    );
}

sub run_message_server {
    my $chain = shift;
    AnyEvent->condvar->recv;
}

1;

=head1 NAME

Message::Passing::DSL - An easy way to make chains of Message::Passing components.

=head1 SYNOPSIS

    package mylogcollectorscript;
    use Moo;
    use MooX::Options;
    use Message::Passing::DSL;
    use MooX::Types::MooseLike::Base qw/ Str /;
    use namespace::clean -except => [qw( meta _options_data _options_config )];

    with 'Message::Passing::Role::Script';

    option socket_bind => (
        is => 'ro',
        isa => Str,
        default => sub { 'tcp://*:5558' },
    );

    sub build_chain {
        my $self = shift;
        message_chain {
            output console => (
                class => 'STDOUT',
            );
            input zmq => (
                class => 'ZeroMQ',
                output_to => 'console',
                socket_bind => $self->socket_bind,
            );
        };
    }

    __PACKAGE__->start unless caller;
    1;

=head1 DESCRIPTION

This module provides a simple to use helper system for writing
scripts which implement a L<Message::Passing> server, like
the built in L<message-pass> script.

Rather than having to pass instances of an output to each input in the
C<output_to> attribute, and full class names, you can use short names
for component classes, and strings for the C<output_to> attribute,
the DSL resolves these and deals with instance construction for you.

See example in the SYNOPSIS, and details for the exported sugar
functions below.

=head2 FUNCTIONS

=head3 message_chain

Constructs a message chain (i.e. a series of Message::Passing objects
feeding into each other), warns about any unused parts of the chain,
and returns an array ref to the heads of the chain (i.e. the input class(es)).

Maintains a registry / factory for the log classes, which is used to
allow the resolving of symbolic names in the output_to key to function.

=head3 output

Constructs a named output within a chain.

    message_chain {
        output foo => ( class => 'STDOUT' );
        ....
    };

Class names will be assumed to prefixed with 'Message::Passing::Output::',
unless you prefix the class with + e.g. C<< +My::Own::Output::Class >>

=head3 encoder

Constructs a named encoder within a chain.

    message_chain {
        encoder fooenc => ( output_to => 'out', class => 'JSON' );
        ....
    };

Class names will be assumed to prefixed with 'Message::Passing::Filter::Encoder::',
unless you prefix the class with + e.g. C<< +My::Own::Encoder::Class >>

=head3 filter

Constructs a named filter (which can act as both an output and an input)
within a chain.

    message_chain {
        ...
        filter bar => ( output_to => 'fooenc', class => 'Null' );
        ...
    };

Class names will be assumed to prefixed with 'Message::Passing::Filter::',
unless you prefix the class with + e.g. C<< +My::Own::Filter::Class >>

=head3 decoder

Constructs a named decoder within a chain.

    message_chain {
        decoder zmq_decode => ( output_to => 'filter', class => 'JSON' );
        ....
    };

Class names will be assumed to prefixed with 'Message::Passing::Filter::Decoder::',
unless you prefix the class with + e.g. C<< +My::Own::Encoder::Class >>


=head3 input

The last thing in a chain - produces data which gets consumed.

    message_chain {
        ...
        input zmq => ( output_to => 'zmq_decode', class => 'ZeroMQ', bind => '...' );
        ....
    }

Class names will be assumed to prefixed with 'Message::Passing::Output::',
unless you prefix the class with + e.g. C<< +My::Own::Output::Class >>

=head3 error_log

Setup the error logging output. Takes the same arguments as an C<< input xxx => () >> block, except without a name.

=head3 run_message_server

This enters the event loop and causes log events to be consumed and
processed.

Can be passed a message_chain to run, although this is entirely optional
(as all chains which are still in scope will run when the event
loop is entered).

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API -
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut
