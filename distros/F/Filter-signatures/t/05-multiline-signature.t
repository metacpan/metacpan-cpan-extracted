#!perl -w
use strict;
use Test::More tests => 4;
use Data::Dumper;

use  Text::Balanced 'extract_multiple', 'extract_quotelike';

require Filter::signatures;

# Mimic parts of the setup of Filter::Simple
my $extractor =
$Filter::Simple::placeholder = $Filter::Simple::placeholder
    = qr/\Q$;\E(.{4})\Q$;\E/s;

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
sub  { my ($name,$value)=@_;();



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
sub foo { my ($name,$value)=@_;();




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
sub  { my ($name,$value)=@_;$value = 'bar' if @_ <= 1;();




        return "'$name' is '$value'"
    };
RESULT

# Weirdo comments
# Filter::Simple resp. Text::Balanced do that filtering for us

$_ = <<'SUB';
sub foo
(
  $name  # foo
, $value # bar
) {
    return "'$name' is '$value'"
};
SUB

# Replicate the setup that Filter::Simple does for us:

our @components;
no warnings 'once';
local *components = \@Filter::Simple::components;

        my $comment = qr/(?<![\$\@%])#.*/;
        my $ncws = qr/\s+/;
        my $EOP = qr/\n\n|\Z/;
        my $CUT = qr/\n=cut.*$EOP/;
        my $pod_or_DATA = qr/
              ^=(?:head[1-4]|item) .*? $CUT
            | ^=pod .*? $CUT
            | ^=for .*? $CUT
            | ^=begin .*? $CUT
            | ^__(DATA|END)__\r?\n.*
            /smx;
        my $id = qr/\b(?!([ysm]|q[rqxw]?|tr)\b)\w+/;
        my $variable = qr{
        [\$*\@%]\s*
            \{\s*(?!::)(?:\d+|[][&`'#+*./|,";%=~:?!\@<>()-]|\^[A-Z]?)\}
            | (?:\$#?|[*\@\%]|\\&)\$*\s*
               (?:  \{\s*(?:\^(?=[A-Z_]))?(?:\w|::|'\w)*\s*\}
                  |      (?:\^(?=[A-Z_]))?(?:\w|::|'\w)*
                  | (?=\{)  # ${ block }
               )
                )
            | \$\s*(?!::)(?:\d+|[][&`'#+*./|,";%=~:?!\@<>()-]|\^[A-Z]?)
        }x;
        my $code_no_comments = [ { DONT_MATCH => $comment },
                    $ncws, { DONT_MATCH => $pod_or_DATA }, $variable,
                    $id, { DONT_MATCH => \&extract_quotelike }   ];
        my $instr;
		for (Text::Balanced::extract_multiple($_,$code_no_comments)) {
            if (ref())     { push @components, $_; $instr=0 }
            elsif ($instr) { $components[-1] .= $_ }
            else           { push @components, $_; $instr=1 }
        };
        my $count = 0;
            $_ = join "",
                  map { ref $_ ? $;.pack('N',$count++).$; : $_ }
                      @components;
            @components = grep { ref $_ } @components;
Filter::signatures::transform_arguments();

    # Now restore all the surviving placeholders:
    s/$extractor/${$components[unpack('N',$1)]}/g;

is $_, <<'RESULT', "Multiline signatures with comments get converted";
sub foo { my ($name,$value)=@_;();




    return "'$name' is '$value'"
};
RESULT
