#!/usr/bin/env perl
# Convert XML::LibXML exceptions into report

use warnings;
use strict;

use Log::Report;
use Log::Report::Die 'exception_decode';
use Test::More;

#use Data::Dumper;

BEGIN {
    eval 'require XML::LibXML::Error';
    plan skip_all => 'XML::LibXML::Error not available' if $@;

    eval 'require XML::LibXML';
    plan skip_all => 'Your installation of XML::LibXML is broken' if $@;
}

# The XML::LibXML::Error object does not have a constructor, so we
# need to trigger one.
my $xml = eval { XML::LibXML->load_xml(string => \'<bad-xml>') };
ok ! defined $xml, 'parse broken xml';
my $error = $@;
isa_ok $error, 'XML::LibXML::Error';

#warn Dumper exception_decode($error);
my @dec = exception_decode($error);
my $msg = delete $dec[2];

# error code changed from libxml2 2.9.9 to 2.9.10
my $rc = delete $dec[0]{errno};
$dec[0]{errno} = 'RC';
cmp_ok $rc, '>', 13000, 'error code';

is_deeply \@dec,
  , [ { location => [ 'libxml', '', '1', 'parser' ], errno => 'RC' }
    , 'ERROR'
    , undef    # removed into $msg
    , 'exception, libxml'
    ], 'error 1';

# the message may vary over libxml2 versions
$msg =~ s/\r?\n\s*/ /g;
like $msg, qr/bad\-xml|Start tag expected/, $msg;

done_testing;

1;
