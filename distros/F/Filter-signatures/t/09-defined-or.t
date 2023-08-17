#!perl -w
use strict;
use Test::More tests => 2;
use Data::Dumper;

use  Text::Balanced 'extract_multiple', 'extract_quotelike';

require Filter::signatures;

# Mimic parts of the setup of Filter::Simple
my $extractor =
$Filter::Simple::placeholder = $Filter::Simple::placeholder
    = qr/\Q$;\E(.{4})\Q$;\E/s;

# Defined-or
$_ = <<'SUB';
sub (
$name
    , $value //= 'bar'
    ) {
        return "'$name' is '$value'"
    };
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Multiline signatures get converted for anonymous subs";
sub  { my ($name,$value)=@_;$value //= 'bar';();



        return "'$name' is '$value'"
    };
RESULT

$_ = <<'SUB';
sub (
$name
    , $value ||= 'bar'
    ) {
        return "'$name' is '$value'"
    };
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Multiline signatures get converted for anonymous subs";
sub  { my ($name,$value)=@_;$value ||= 'bar';();



        return "'$name' is '$value'"
    };
RESULT
