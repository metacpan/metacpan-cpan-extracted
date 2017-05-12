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


# Data comes from an NEC-style pulse, which is documented here:
# https://techdocs.altium.com/display/FPGA/NEC+Infrared+Transmission+Protocol
#
my $PULSE_DATA = <<END;
    pulse 9038
    space 4481
    pulse 648
    space 1634
    pulse 647
    space 1612
    pulse 623
    space 1633
    pulse 651
    space 1608
    pulse 568
    space 1715
    pulse 547
    space 1685
    pulse 567
    space 1688
    pulse 591
    space 1667
    pulse 599
    space 1660
    pulse 647
    space 1614
    pulse 642
    space 1610
    pulse 649
    space 1609
    pulse 647
    space 1609
    pulse 650
    space 1634
    pulse 621
    space 1639
    pulse 619
    space 1636
    pulse 634
    space 1625
    pulse 633
    space 1625
    pulse 639
    space 1617
    pulse 629
    space 1628
    pulse 632
    space 1625
    pulse 659
    space 1599
    pulse 620
    space 1639
    pulse 648
    space 1612
    pulse 644
    space 1609
    pulse 630
    space 1627
    pulse 569
    space 1716
    pulse 539
    space 1717
    pulse 580
    space 1652
    pulse 641
    space 1616
    pulse 594
    space 1662
    pulse 595
    space 1690
    pulse 568
END
$PULSE_DATA =~ s/^\s+//gm;
open( my $IN, '<', \$PULSE_DATA ) or die $!;


my $callback = sub {
    my ($args) = @_;
    isa_ok( $args->{pulse_obj}, 'Linux::IRPulses' );
    cmp_ok( $args->{code}, 'eq', 0xFFFFFFFF,
        "Parsed code" );
    return;
};
my $pulse = Linux::IRPulses->new({
    fh => $IN,
    header => [ pulse 9000, space 4500 ],
    zero => [ pulse 563, space 563 ],
    one => [ pulse 562, space 1688 ],
    bit_count => 32,
    callback => $callback,
});


while( <$IN> ) {
    chomp;
    $pulse->handle_line( $_ );
}
close $IN;
