#!perl -w
use strict;
use Test::More tests => 4;
use Data::Dumper;

require Filter::signatures;

# Anonymous
$_ = <<'SUB';
sub (
$name
    , $value
    ) {
        return "'$name' is '$value'"
    };
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Multiline signatures get converted for anonymous subs";
sub  { my ($name,$value)=@_;



        return "'$name' is '$value'"
    };
RESULT

# Named
$_ = <<'SUB';
sub foo
(
  $name
, $value
) {
    return "'$name' is '$value'"
};
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Multiline signatures get converted for named subroutines";
sub foo { my ($name,$value)=@_;




    return "'$name' is '$value'"
};
RESULT

# Multiline defaults
$_ = <<'SUB';
sub (
$name
    , $value
='bar'
    ) {
        return "'$name' is '$value'"
    };
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Multiline default values";
sub  { my ($name,$value)=@_;$value ='bar' if @_ <= 1;




        return "'$name' is '$value'"
    };
RESULT

# Weirdo comments
{
local $TODO = "Comments in signatures are not supported";
$_ = <<'SUB';
sub foo
(
  $name  # foo
, $value # bar
) {
    return "'$name' is '$value'"
};
SUB
Filter::signatures::transform_arguments();
is $_, <<'RESULT', "Multiline signatures with comments get converted";
sub foo { my ($name,$value)=@_;




    return "'$name' is '$value'"
};
RESULT
}