# Copyright (c) 2018  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
use Test::More tests => 6;
use v5.12;
use lib 't/lib/';
use Device::WebIO;
use MockDigitalInputAnyEvent;
use AnyEvent;


my $input_cv = AnyEvent->condvar;
$input_cv->cb( sub {
    my ($cv) = @_;
    my ($pin, $setting) = $cv->recv;
    cmp_ok( $pin, '==', 3, "Pin set" );
    cmp_ok( $setting, '==', 1, "Pin set to correct value" );
});

my $input = MockDigitalInputAnyEvent->new({
    input_pin_count => 8,
});
my $webio = Device::WebIO->new;
$webio->register( 'foo', $input );

ok( $input->does( 'Device::WebIO::Device' ), "Does Device role" );
ok( $input->does( 'Device::WebIO::Device::DigitalInputAnyEvent' ),
    "Does DigitalInputAnyEvent role" );

# We look for interrupts on pin 3 only
$webio->set_anyevent_condvar( 'foo', 3, $input_cv );

# Mock getting input
my $input_timer; $input_timer = AnyEvent->timer(
    after => 0.5,
    cb => sub {
        $input->mock_set_input( 3, 1 );
        $input->mock_set_input( 4, 1 );
    },
);
# Make sure we can do it twice
my $input_timer2; $input_timer2 = AnyEvent->timer(
    after => 0.75,
    cb => sub {
        $input->mock_set_input( 3, 1 );
        $input->mock_set_input( 4, 1 );
    },
);

# Timeout after a second
my $cv = AE::cv;
my $timer; $timer = AnyEvent->timer(
    after => 1,
    cb => sub {
        $cv->send;
    },
);
$cv->recv;
