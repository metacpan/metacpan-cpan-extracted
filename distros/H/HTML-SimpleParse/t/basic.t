#!/usr/bin/perl -w

use Test;
BEGIN { plan tests => 23 }
use HTML::SimpleParse;
ok 1;

use Carp;
$SIG{__WARN__} = \&Carp::cluck;

{
	my %hash = HTML::SimpleParse->parse_args('A="xx" B=3');
	ok $hash{A}, "xx";
	ok $hash{B}, 3;
}

{
	my %hash = HTML::SimpleParse->parse_args('A="xx" B');
	ok $hash{A}, "xx";
	ok exists $hash{B};
}

{
	my %hash = HTML::SimpleParse->parse_args('A="xx" B c="hi" ');
	ok $hash{A}, "xx";
	ok exists $hash{B};
	ok $hash{C}, "hi";
}

{
	my $text = 'type=checkbox checked name=flavor value="chocolate or strawberry"';
	my %hash = HTML::SimpleParse->parse_args( $text );
	ok $hash{TYPE}, "checkbox";
	ok exists $hash{CHECKED};
	ok $hash{VALUE}, "chocolate or strawberry";
}

{
	my %hash=HTML::SimpleParse->parse_args(' A="xx" B');
	ok $hash{A}, 'xx';
	ok exists $hash{B};
}

{
	my $text = <<EOF;
	<html><head>
	<title>Hiya, tester</title>
	</head>
	
	<body>
	<center><h1>Hiya, tester</h1></center>
	<!-- here is a comment -->
	<!DOCTYPE here is a markup>
	<!--# here is an ssi -->
	</body>
	</html>
EOF
	my $p = new HTML::SimpleParse( $text );
	
	ok $p->get_output(), $text;
}

{
	my %hash = HTML::SimpleParse->parse_args('a="b=c"');
	ok $hash{A}, "b=c";
}

{
	my %hash = HTML::SimpleParse->parse_args('val="a \"value\""');
	ok $hash{VAL}, 'a "value"';
}

{
  my %hash = HTML::SimpleParse->parse_args('val = "a \"value\""');
  ok $hash{VAL}, 'a "value"';
}

{
  # Avoid 'uninitialized value' warning
  my $ok=1;
  local $^W=1;
  local $SIG{__WARN__} = sub {$ok=0};
  HTML::SimpleParse->new();
  ok $ok;
}

{
  my %hash = HTML::SimpleParse->parse_args("val='a value'");
  ok $hash{VAL}, 'a value';
}

{
  local $HTML::SimpleParse::FIX_CASE = 0;
  my %hash = HTML::SimpleParse->parse_args("val='a value'");
  ok $hash{val}, 'a value';
}

{
  local $HTML::SimpleParse::FIX_CASE = 0;
  my %hash = HTML::SimpleParse->parse_args("Val='a value'");
  ok $hash{Val}, 'a value';
}

{
  my $p = new HTML::SimpleParse('', fix_case => 0);
  my %hash = $p->parse_args("Val='a value'");
  ok $hash{Val}, 'a value';
}

{
  my $text = <<EOF;
    <html><head>
    <title>Hiya, tester</title>
    </head>
	
    <body>
    <center><h1>Hiya, tester</h1></center>
    <!-- here is a comment -->
    <!DOCTYPE here is a markup>
    <!--# here is an ssi -->
    </body>
    </html>
EOF
  my $p = new HTML::SimpleParse($text);
  my $ok = 1;
  foreach ($p->tree) {
    $ok = 0 unless substr($text, $_->{offset}) =~ /^<?\Q$_->{content}/;
  }
  ok $ok;
}
