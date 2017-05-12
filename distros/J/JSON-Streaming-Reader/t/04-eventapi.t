
use Test::More tests => 62;
use JSON::Streaming::Reader::TestUtil;

compare_event_parse("");
compare_event_parse(" ");
compare_event_parse("  ");
compare_event_parse(" ", "");
compare_event_parse("", " ");
compare_event_parse(" ", " ");

compare_event_parse("12");
compare_event_parse("12.4");
compare_event_parse("true");
compare_event_parse("[]");
compare_event_parse("{}");

compare_event_parse("1", "2");
compare_event_parse("fal", "se");
compare_event_parse("[", "]");
compare_event_parse("{", "}");

compare_event_parse("[12]");
compare_event_parse("[12,22]");

compare_event_parse("[1","2]");
compare_event_parse("[","12,22]");
compare_event_parse("[12,","22]");
compare_event_parse("[12",",22]");
compare_event_parse("[12,22","]");
compare_event_parse("[12,2","2]");

compare_event_parse('{"hello":"world"}');
compare_event_parse('{"hel','lo":"world"}');
compare_event_parse('{"hello"',':"world"}');
compare_event_parse('{"hello":','"world"}');
compare_event_parse('{"hello":"wo','rld"}');

compare_event_parse('{"hello":"world","json":"nosj"}');
compare_event_parse('{"hello":"world",','"json":"nosj"}');
compare_event_parse('{"hello":"world"',',"json":"nosj"}');
compare_event_parse('{"hello"',':"world","json":"nosj"}');
compare_event_parse('{"hello":','"world","json":"nosj"}');
compare_event_parse('{"hello":"world","json"',':"nosj"}');
compare_event_parse('{"hello":"world","json":','"nosj"}');
compare_event_parse('{','"hello":"world","json":"nosj"}');
compare_event_parse('{"hello":"world","json":"nosj"','}');

compare_event_parse("[12,22]","");
compare_event_parse("","[12,22]");
compare_event_parse("[12","",",22]");

compare_event_parse("fal");
compare_event_parse("fal", " ", "se");
compare_event_parse("12.");
compare_event_parse("-");
compare_event_parse('"');

compare_event_parse("{");
compare_event_parse("}");
compare_event_parse("[");
compare_event_parse("]");
compare_event_parse("[1");
compare_event_parse("[1 1]");
compare_event_parse("1 1");

compare_event_parse("{} null");
compare_event_parse("{}","null");
compare_event_parse("{} n","ull");
compare_event_parse("{} n");
compare_event_parse("blue");

compare_event_parse("[1,]");
compare_event_parse("[1,,2]");

compare_event_parse("1.2.2");
compare_event_parse("1.2",".2");
compare_event_parse("1.2.","2");


