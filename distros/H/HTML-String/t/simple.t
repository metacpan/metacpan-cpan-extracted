use strictures 1;
use Test::More;
use HTML::String;

my $hi = 'Hi <bob>';

my $one = html('<tag>').$hi.html('</tag>');

is("$one", '<tag>Hi &lt;bob&gt;</tag>');

my $two = do {
  use HTML::String::Overload;

  "<tag>${hi}</tag>";
};

is("$two", '<tag>Hi &lt;bob&gt;</tag>');

my $three = html('<tag>');

$three .= $hi;

$three .= html('</tag>');

is("$three", '<tag>Hi &lt;bob&gt;</tag>');

my $four; {
  use HTML::String::Overload { ignore => { non_existant_package_name => 1 } };

  #$four = "<tag>".$hi."</tag>\n";
  $four = "<tag>$hi</tag>"."\n";
};

chomp($four);

is("$four", '<tag>Hi &lt;bob&gt;</tag>');

{
    package MyPkg;

    sub new { 'foo' }

    sub load { 'bar' }
}

is(html('MyPkg')->new, 'foo');

is(html('MyPkg')->load, 'bar');

# Test that all characters that should be escaped are escaped

my $raw_characters = q{<>&"'};
my $expected_output = q{<tag>&lt;&gt;&amp;&quot;&#39;</tag>};
my $html = html('<tag>').$raw_characters.html('</tag>');
is($html, $expected_output);

ok(HTML::String::Value->isa('HTML::String::Value'), 'isa on class ok');

is($@, '', '$@ not set by check');

is do {
    use HTML::String::Overload;
    '' . '0'
}, '0', 'concatenating strings which are false in boolean context';

done_testing;
