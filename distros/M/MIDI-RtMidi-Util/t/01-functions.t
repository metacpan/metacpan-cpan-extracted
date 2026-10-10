#!/usr/bin/env perl
use v5.36;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'MIDI::RtMidi::Util', qw(
        in_port out_port stop_device input_ports output_ports stop_all_notes program_changer
    );
}

# A minimal stand-in for a MIDI::RtMidi::FFI::Device that records calls.
package Local::MockDevice {
    sub new ($class, %args) { bless { calls => [], fail_on => $args{fail_on} }, $class }
    sub calls ($self) { $self->{calls}->@* }
    sub _record ($self, $name, @args) {
        die "mock $name failed\n" if ($self->{fail_on} // '') eq $name;
        push $self->{calls}->@*, [ $name, @args ];
        return 1;
    }
    sub stop           ($self, @args) { $self->_record(stop           => @args) }
    sub panic          ($self, @args) { $self->_record(panic          => @args) }
    sub note_off       ($self, @args) { $self->_record(note_off       => @args) }
    sub control_change ($self, @args) { $self->_record(control_change => @args) }
    sub program_change ($self, @args) { $self->_record(program_change => @args) }
}

subtest exports => sub {
    can_ok 'main', qw(
        in_port out_port stop_device input_ports output_ports stop_all_notes program_changer
    );
};

subtest throws => sub {
    throws_ok { in_port() }
        qr/Too few arguments/,
        'in_port() dies without port name';
    throws_ok { out_port() }
        qr/Too few arguments/,
        'out_port() dies without port name';
    throws_ok { stop_device() }
        qr/Too few arguments/,
        'stop_device() dies without a port';
    throws_ok { stop_all_notes() }
        qr/Too few arguments/,
        'stop_all_notes() dies without a port';
    throws_ok { program_changer() }
        qr/Too few arguments/,
        'program_changer() dies without a device';
    throws_ok { input_ports(1) }
        qr/Too many arguments/,
        'input_ports() takes no arguments';
    throws_ok { output_ports(1) }
        qr/Too many arguments/,
        'output_ports() takes no arguments';
};

subtest defaults => sub {
    my $got = input_ports();
    is ref($got), 'ARRAY', 'input_ports';
    $got = output_ports();
    is ref($got), 'ARRAY', 'output_ports';
};

subtest 'unknown port' => sub {
    my $name = 'no-such-midi-port-' . $$;
    throws_ok { in_port($name) }
        qr/\ACan't open MIDI port: \Q$name\E\n\z/,
        'in_port() dies on an unknown port';
    throws_ok { out_port($name) }
        qr/\ACan't open MIDI port: \Q$name\E\n\z/,
        'out_port() dies on an unknown port';
};

subtest stop_device => sub {
    my $dev = Local::MockDevice->new;
    lives_ok { stop_device($dev) } 'stop_device() lives';
    is_deeply [ map { $_->[0] } $dev->calls ], [qw(stop panic)],
        'stop then panic are called, in order';

    for my $method (qw(stop panic)) {
        my $bad = Local::MockDevice->new(fail_on => $method);
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        lives_ok { stop_device($bad) } "stop_device() survives $method failure";
        is scalar @warnings, 1, "one warning when $method fails";
        like $warnings[0], qr/\ACan't stop the MIDI device: mock \Q$method\E failed\n\z/,
            "warning describes the $method failure";
    }
};

subtest stop_all_notes => sub {
    my $dev = Local::MockDevice->new;
    stop_all_notes($dev);

    my @calls = $dev->calls;
    is scalar @calls, 16 * 128, 'a note_off for every channel and note';
    ok !( grep { $_->[0] ne 'note_off' } @calls ), 'only note_off messages sent';
    ok !( grep { $_->[3] != 0 } @calls ), 'all velocities are 0';

    my %seen;
    $seen{ $_->[1] }{ $_->[2] }++ for @calls;
    is_deeply [ sort { $a <=> $b } keys %seen ], [ 0 .. 15 ],
        'all 16 channels are covered (not just 0 and 15)';
    my @short = grep { keys $seen{$_}->%* != 128 } keys %seen;
    is scalar @short, 0, 'every channel gets all 128 notes';
};

subtest program_changer => sub {
    my $dev = Local::MockDevice->new;
    program_changer($dev);
    is_deeply [ $dev->calls ],
        [ [ control_change => 0, 0, 0 ], [ program_change => 0, 0 ] ],
        'defaults: bank MSB 0, no LSB, program 0 on channel 0';

    $dev = Local::MockDevice->new;
    program_changer($dev, 5, 3, 1);
    is_deeply [ $dev->calls ],
        [ [ control_change => 3, 0, 1 ], [ program_change => 3, 5 ] ],
        'program, channel and MSB are passed through';

    $dev = Local::MockDevice->new;
    program_changer($dev, 5, 3, 1, 7);
    is_deeply [ $dev->calls ],
        [
            [ control_change => 3,  0, 1 ],
            [ control_change => 3, 32, 7 ],
            [ program_change => 3,  5 ],
        ],
        'a bank LSB is sent as CC 32 before the program change';

    $dev = Local::MockDevice->new;
    program_changer($dev, 5, 3, 1, 0);
    is_deeply [ $dev->calls ],
        [
            [ control_change => 3,  0, 1 ],
            [ control_change => 3, 32, 0 ],
            [ program_change => 3,  5 ],
        ],
        'a bank LSB of 0 is still sent';

    for my $method (qw(control_change program_change)) {
        my $bad = Local::MockDevice->new(fail_on => $method);
        throws_ok { program_changer($bad, 1, 1, 1, 1) }
            qr/\AERROR: mock \Q$method\E failed\n\z/,
            "program_changer() wraps a $method failure";
    }
};

done_testing();
