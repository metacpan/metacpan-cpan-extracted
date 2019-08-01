# Copyright 1997 - 2019 by IXIA Keysight
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
package validate;
my $LEVEL = 1;

#------------------------------------------------------------------------------
# Verify if a address is IPv6
#------------------------------------------------------------------------------
sub isIpv6 {
    my $address      = @_[0];
    my @addressBytes = split(':', $address);
    my $isIpv6Addr   = 0;
    my $len          = @addressBytes;
    if ($len <= 8) {
        foreach $bytes (@addressBytes) {
            if (length($bytes) <= 4) {
               if ($bytes ne '') {
                   if (($bytes =~ /[a-f,A-F]|[0-9]/) &&
                      !($bytes =~ /[g-z,G-Z]/)) {
                       $isIpv6Addr = 1;
                   } else {
                       $isIpv6Addr = 0;
                       return $isIpv6Addr;
                   }
               }
            } else {
                $isIpv6 = 0;
                return $isIpv6Addr
            }
        }
    }
    return $isIpv6Addr;
}

#------------------------------------------------------------------------------
# Verify if a address is IPv4
#------------------------------------------------------------------------------
sub isIpv4 {
    $DB::single=1;
    my $address      = @_[0];
    my @addressBytes = split('\.', $address);
    my $isIpv4Addr   = 0;

    my $len = @addressBytes;
    if ($len == 4) {
        foreach $bytes (@addressBytes) {
            if ((int($bytes) >= 0) && (int($bytes) <= 255)) {
                $isIpv4Addr = 1;
            } else {
                $isIpv4Addr = 0;
                return $isIpv4Addr
            }
        }
    }
    return $isIpv4Addr;
}

1;