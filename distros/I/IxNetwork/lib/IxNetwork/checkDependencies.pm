#!/usr/bin/perl
#
# Copyright 1997 - 2018 by IXIA Keysight
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

use File::Spec;
my $dependenciespath;
BEGIN {
    my ($volume, $directory, $file) = File::Spec->splitpath(__FILE__);
    $directory = File::Spec->catdir( (File::Spec->rel2abs($directory), 'dependencies') );
    $dependenciespath = $directory;
}
use lib $dependenciespath;

package checkDependencies;

sub checkDeps {
    my @missingDependencies = ();
    my $ret = eval {
        require IO::Socket::SSL;
        IO::Socket::SSL->import();
        1; 
    };
    if (!$ret and $@) {
        push(@missingDependencies, "IO::Socket::SSL");
    }
    my $ret = eval {
        require LWP::UserAgent;
        LWP::UserAgent->import();
        1; 
    };
    if (!$ret and $@) {
        push(@missingDependencies, "LWP::UserAgent");
    }
    my $ret = eval {
        require Protocol::WebSocket::Client;
        Protocol::WebSocket::Client->import();
        1; 
    };
    if (!$ret and $@) {
        push(@missingDependencies, "Protocol::WebSocket::Client");
    }
    my $ret = eval {
        require JSON::PP;
        JSON::PP->import();
        1; 
    };
    if (!$ret and $@) {
        push(@missingDependencies, "JSON::PP");
    }
    my $ret = eval {
        require URI::Escape;
        URI::Escape->import();
        1; 
    };
    if (!$ret and $@) {
        push(@missingDependencies, "URI::Escape");
    }
    my $ret = eval {
        require Net::SSLeay;
        Net::SSLeay->import();
        1; 
    };
    if (!$ret and $@) {
        push(@missingDependencies, "Net::SSLeay");
    }
    my $ret = eval {
        require LWP::Protocol::https;
        LWP::Protocol::https->import();
        1; 
    };
    if (!$ret and $@) {
        push(@missingDependencies, "LWP::Protocol::https");
    }
    my $ret = eval {
        require Time::Seconds;
        Time::Seconds->import();
        1; 
    };
    if (!$ret and $@) {
        push(@missingDependencies, "Time::Seconds");
    }

    if (scalar(@missingDependencies) > 0) {
        my $enumeratedDependencies = join(', ', @missingDependencies);
        die 'Cannot load required dependencies: '.$enumeratedDependencies.". \nPlease consult documentation for installing required dependencies.\n";
    }

}

1;



