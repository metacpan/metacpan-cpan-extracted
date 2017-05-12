
# Basic grammar driver.
# @author Joel Dalley
# @version 2014/Mar/21

use JBD::Core::List 'pairsof';
use File::Slurp 'read_file';

use JBD::Parser::DSL;
use JBD::JSON 'std_parse';

# Optionally specify a single json_corpus file to test.
# If no argument, then all inline & corpus tests run.
my $file = shift;

# Inline tests.
my @cfg = $file ? () : (
    [json_space        => ' '],
    [json_escape_seq   => '\\"'],
    [json_null_literal => 'null'],
    [json_bool_literal => 'true'],
    [json_bool_literal => 'false'],
    [json_string_char  => 'chars'],
    [star_string_char  => "String chars?\n"],
    [json_string       => qq|"This. Is\na string?\r\f"|],
    [json_member_list  => '"nada":null'],
    [json_element_list => 'true, false, null, 1, 2'],
    [json_array        => '[1, 2]'],
    [json_member_list  => '"one" : 1, "two": [1, 2]'],
    [json_object       => '{ "one": {"one_A": true} , '
                        . '  "two": 2.0, "tre": 3.0E0 }'], 
    );

# Corpus tests.
push @cfg, [json_text => $_], for corpus_texts($file);

# Print.
binmode STDOUT, ':utf8';
for (@cfg) {
    my ($sym, $text) = @$_;
    my $parsed = std_parse $sym, "$text";
    print "$sym->($text) <<<";
    for (my $n = 0; $n < @$parsed; $n++) {
        print "\n\t[$n] ", to_str($parsed->[$n]);
    }
    print "\n>>>\n";
}


exit;
####


# @param string [opt] A single file to return text for.
# @return array Array of strings to JSON corpus texts.
sub corpus_texts { 
    map read_file($_), glob $_[0] ? $_[0] : 'json_corpus/*.json';
}

# @param JBD::Parser::Token A token.
# @return string Token representation, for printing.
sub to_str {
    my $t = $_[0]->type;
    my $v = defined $_[0]->value ? $_[0]->value : 'UNDEF';

    FORMAT_WHITESPACE: {
        my $r = qr/^(JsonEscape\w+|JsonSpace)$/o;
        $v = "#[\\$1]" if $t =~ $r;
    }

    "$t<$v>";
}
