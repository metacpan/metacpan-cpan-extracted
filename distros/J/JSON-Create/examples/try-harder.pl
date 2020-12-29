#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use JSON::Create 'create_json';
use Mojo::URL;
use Path::Tiny;

sub try_harder
{
    my ($obj) = @_;
    my $type = ref $obj;
    if ($obj->can ('TO_JSON')) {
	print "Jsonifying $type with 'TO_JSON'.\n";
	return create_json ($obj->TO_JSON ());
    }
    elsif ($obj->can ('to_string')) {
	print "Stringifying $type with 'to_string'.\n";
	# The call to "create_json" makes sure that the string is
	# valid as a JSON string.
	return create_json ($obj->to_string ());
    }
    else {
	return create_json ($obj);
    }
}

my $jc = JSON::Create->new (indent => 1, sort => 1, validate => 1);
$jc->obj_handler (\& try_harder);
print $jc->run ({
    url => Mojo::URL->new('http://sri:foo@example.com:3000/foo?foo=bar#23'),
    path => path ('/home/ben/software/install/bin/perl'),
}), "\n";


