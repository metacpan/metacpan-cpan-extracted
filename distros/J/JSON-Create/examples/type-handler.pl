#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use JSON::Create 'create_json';
binmode STDOUT, ":encoding(utf8)";
my %crazyhash = (
    'code' => sub { return "강남스타일"; },
    'regex' => qr/.*/,
    'glob' => *STDOUT,
);
my $jc = JSON::Create->new ();
# Let's validate the output of the subroutine below.
$jc->validate (1);
$jc->indent (1);
# Try this one weird old trick to convert your Perl type.
$jc->type_handler (
    sub {
	my ($thing) = @_;
	my $value;
	my $type = ref ($thing);
	if ($type eq 'CODE') {
	    $value = &$thing;
	}
	else {
	    $value = "$thing";
	}
	return create_json ({ type => $type, value => $value, });
    }
);
print $jc->run (\%crazyhash), "\n";
