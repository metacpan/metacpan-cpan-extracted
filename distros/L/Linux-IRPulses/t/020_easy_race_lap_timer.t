# Copyright (c) 2016  Timm Murray
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
use Test::More tests => 2;
use v5.14;
use Linux::IRPulses;


# Data comes from the example in EasyRaceLapTimer's IR protocol document, corrected
# so that long pulses/spaces are brought together the way
# https://github.com/polyvision/EasyRaceLapTimer/blob/master/docs/ir_pulses.md
#
my $PULSE_DATA = <<END;
    pulse 300
    space 300
    pulse 300
    space 300
    pulse 600
    space 600
    pulse 600
    space 300
    pulse 300
END
$PULSE_DATA =~ s/^\s+//gm;
open( my $IN, '<', \$PULSE_DATA ) or die $!;


my $callback = sub {
    my ($args) = @_;
    my $code = $args->{code};
    my $checksum = $code & 1;
    my $id_value = $code >> 1;
    cmp_ok( $id_value, '==', 14, "Got expected ID value" );
    cmp_ok( $checksum, '==', 0, "Got expected checksum" );
    $args->{pulse_obj}->end;
};
my $pulse = Linux::IRPulses->new({
    fh => $IN,
    header => [ pulse 300, space 300 ],
    zero => [ pulse_or_space 300 ],
    one => [ pulse_or_space 600 ],
    bit_count => 7,
    callback => $callback,
});
$pulse->run;


close $IN;
