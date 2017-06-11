#!/usr/bin/env perl
use warnings;
use strict;
use JSON::Create;
package My::Cool::Object;
sub new { return bless {}; }
sub serialize { return ('true', 'false'); };
1;
package main;
my $object = My::Cool::Object->new ();
my $jc = JSON::Create->new ();
my ($arg1, $arg2);
$jc->obj (
    'My::Cool::Object' => sub {
	my ($obj) = @_;
	my ($value1, $value2) = My::Cool::Object::serialize ($obj, $arg1, $arg2);
	return $value2;
    },
);
print $jc->run ({cool => $object});
