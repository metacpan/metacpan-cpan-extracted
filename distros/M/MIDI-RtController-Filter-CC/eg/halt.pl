#!/usr/bin/env perl
use strict;
use warnings;

use curry;
use MIDI::RtController ();
use MIDI::RtController::Filter::CC ();
use Term::TermKey::Async qw(FORMAT_VIM KEYMOD_CTRL);

my $input_name  = shift || 'keyboard';
my $output_name = shift || 'usb';

my $controller = MIDI::RtController->new(
    input   => $input_name,
    output  => $output_name,
    verbose => 1,
);

my $filter = MIDI::RtController::Filter::CC->new(rtc => $controller);

$filter->control(1); # CC#01 = mod-wheel
$filter->trigger(25);

$controller->add_filter('breathe', all => $filter->curry::breathe);

my $tka = Term::TermKey::Async->new(
    term   => \*STDIN,
    on_key => sub {
        my ($self, $key) = @_;
        my $pressed = $self->format_key($key, FORMAT_VIM);
        print "Got key: $pressed\n";
        if ($pressed eq 'h') { $filter->halt(1) }
        $controller->loop->loop_stop if $key->type_is_unicode and
                                        $key->utf8 eq 'C' and
                                        $key->modifiers & KEYMOD_CTRL;
    },
);
$controller->loop->add($tka);

$controller->run; # ...and now trigger a MIDI message!
