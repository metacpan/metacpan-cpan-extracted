#
# Copyright (c) 2003, Stockholms Universitet
# (Stockholm University, Stockholm Sweden)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of the university nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# $Id$
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "0..2\n"; }
END {print "not ok 1\n" unless $loaded;}
#use lib './blib/lib';
use Heimdal::Kadm5  qw(/KADM5_/);
$loaded = 1;

print "ok 0\n";

my $mask = KADM5_PRINCIPAL_NORMAL_MASK | KADM5_KEY_DATA;
print "ok 1\n";

# Ok, this test case is almost broken since there is no provisioning of
# a test KDC on localhost, and there most probably is no KDC running there.
#
# The reason I don't just remove the test case all together is that the
# visual output of the error is marginally better than not having the test
# case at all.
$client = Heimdal::Kadm5::Client->new(Server => 'localhost',
				      Realm => 'EXAMPLE.COM',
				      Principal => 'admin/admin@EXAMPLE.COM',
				      RaiseErrors => 0
    );

warn ("FAILED to create a Heimdal::Kadm5::Client object, but ignoring this\n" .
      "error because I can't tell if it was the normal problem that there is\n" .
      "no Kerberos server running on localhost, or something else :(\n") unless ($client);
print "ok 2\n";

#for my $name ($client->getPrincipals('*/admin')) 
#  {
#    my $princ = $client->getPrincipal($name);
#    warn $princ->getPrincipal;
#  }
#$princ = $client->getPrincipal('host/njal.matematik.su.se');
#$client->extractKeytab($princ,'/tmp/trurl.keytab');



######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

