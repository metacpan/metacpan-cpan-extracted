use Device::Velleman::K8055 qw(:all);
use Test::More tests => 1;
use strict;
use warnings;
diag("Please press the digital input buttons 1 to 5, one at the time\n\n");
is(digital_input_test(),1, "Digital input Test");

sub digital_input_test
{
    return -1 unless OpenDevice(0) == 0;
    my ($input1,$input2,$input3,$input4,$input5) = (0,0,0,0,0);
    do
    {
        my $value = ReadAllDigital();
           if ($value & 0x01) {$input1++; diag("button 1 OK\n") if $input1 == 1}
        elsif ($value & 0x02) {$input2++; diag("button 2 OK\n") if $input2 == 1}
        elsif ($value & 0x04) {$input3++; diag("button 3 OK\n") if $input3 == 1}
        elsif ($value & 0x08) {$input4++; diag("button 4 OK\n") if $input4 == 1}
        elsif ($value & 0x10) {$input5++; diag("button 5 OK\n") if $input5 == 1}
    } until ($input1 && $input2 && $input3 && $input4 && $input5);

    CloseDevice();
    return 1;
}