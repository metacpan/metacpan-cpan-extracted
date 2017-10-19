#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Parse ':all';
use Unicode::UTF8 'decode_utf8';
binmode STDOUT, ":encoding(utf8)";
no utf8;
my $highbytes = "か";
my $not_utf8 = "$highbytes\\u3042";
my $test = "{\"a\":\"$not_utf8\"}";
my $out = parse_json ($test);
# JSON::Parse does something unusual here in promoting the first part
# of the string into UTF-8.
print "JSON::Parse gives this: ", $out->{a}, "\n";
# Perl cannot assume that $highbytes is in UTF-8, so it has to just
# turn the initial characters into garbage.
my $add_chr = $highbytes . chr (0x3042);
print "Perl's output is like this: ", $add_chr, "\n";
# In fact JSON::Parse's behaviour is equivalent to this:
my $equiv = decode_utf8 ($highbytes) . chr (0x3042);
print "JSON::Parse did something like this: ", $equiv, "\n";
# With character strings switched on, Perl and JSON::Parse do the same
# thing.
use utf8;
my $is_utf8 = "か";
my $test2 = "{\"a\":\"$is_utf8\\u3042\"}";
my $out2 = parse_json ($test2);
print "JSON::Parse: ", $out2->{a}, "\n";
my $add_chr2 = $is_utf8 . chr (0x3042);
print "Native Perl: ", $add_chr2, "\n";
