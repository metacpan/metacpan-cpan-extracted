package Mesos::Channel;
use Mesos::XS;
use Mesos::Messages;
use Moo;
use namespace::autoclean;

=head1 NAME

Mesos::Channel

=head1 DESCRIPTION

A channel for sending and receiving events between C and Perl.

=head1 METHODS

=head2 new

=head2 recv

=head2 send

=head2 size

The current size of the channel. Indicates the number of pending events, waiting to be dispatched.

=cut

sub _decode_arg {
    my ($data, $type) = @_;
    if (ref $data eq 'ARRAY') {
        return [map {$type->decode($_)} @$data];
    } else {
        return $type->decode($data);
    }
}

sub deserialize_channel_args {
    my (@in) = @_;
    return map {
        my ($data, $type) = @$_;
        my $deserialized  = $data;
        if (($type||'') ne 'String') {
            # allow for XS to not use the package prefix
            $type = "Mesos::$type" unless $type =~ /^Mesos::/;
            $deserialized = _decode_arg($data, $type);
        }
        $deserialized;
    } @in;
}

sub BUILD { shift->_xs_init }

around recv => sub {
    my ($orig, $self, @input_args) = @_;
    my ($command, @output_args) = @{$self->$orig(@input_args)||[]};
    return wantarray ? () : undef if !$command and !@output_args;
    return ($command, deserialize_channel_args(@output_args));
};

around send => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(\@args);
};

1;
