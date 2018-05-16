#!perl -w
use strict;
use Test::More tests => 1;
use Data::Dumper;

require Filter::signatures;
# Mimic parts of the setup of Filter::Simple
my $extractor =
$Filter::Simple::placeholder = $Filter::Simple::placeholder
    = qr/\Q$;\E(.{4})\Q$;\E/s;

# Check that we are immune against Filter::Simple embedding a comma in its
# placeholders for strings:

my $placeholder = qq(\$value = $;   ,$;);
my $stuff = Filter::signatures::parse_argument_list("foo","\$name, $placeholder");
is $stuff, 'sub foo { my ($name,$value)=@_;' . $placeholder . ' if @_ <= 1;();',
    "Filter::Simple string substitution doesn't throw us off";
