#!perl -T
use strict;
use warnings;

use Test::More tests => 4;

use EJS::Template;
use FindBin qw($RealBin);
use IO::Scalar;

my $v1 = {
    customFunc => sub {
        my $context = EJS::Template->context;
        $context->bind({
            y => 4,
            z => 5,
        });
    }
};

my $output = EJS::Template->new(engine => 'JE')->apply(<<EJS, $v1);
<%
var x = 2;
var y = 3;
customFunc();
%>
x = <%=x%>
y = <%=y%>
z = <%=z%>
EJS

is $output, <<OUT;
x = 2
y = 4
z = 5
OUT

# Note: This test does not work with JavaScript::SpiderMonkey due to the shared
# $GLOBAL class variable. (See comment in JavaScript::SpiderMonkey::new)
my $t1 = EJS::Template->new(engine => 'JE');
my $t2 = EJS::Template->new(engine => 'JE');

my $v2 = {
    set_t1 => sub {
        my ($name, $value) = @_;
        $t1->bind({$name => $value});
        my $t = EJS::Template->context;
        $t->print("set_t1: $name = $value\n");
    },
    set_t2 => sub {
        my ($name, $value) = @_;
        $t2->bind({$name => $value});
        my $t = EJS::Template->context;
        $t->print("set_t2: $name = $value\n");
    },
};

my $result1;
my $output1 = IO::Scalar->new(\$result1);
my $result2;
my $output2 = IO::Scalar->new(\$result2);

$t1->process(\'<% var foo %>', $v2, $output1);
$t2->process(\'<% var bar %>', $v2, $output2);
$t1->process(\'<% set_t2("bar", 2) %>', undef, $output1);
$t2->process(\'<% set_t1("foo", bar * 3) %>', undef, $output2);
$t1->process(\'<% set_t2("bar", foo * 4) %>', undef, $output1);
$t2->process(\'<% set_t1("foo", bar * 5) %>', undef, $output2);
$t1->process(\"result: foo = <%=foo%>\n", undef, $output1);
$t2->process(\"result: bar = <%=bar%>\n", undef, $output2);

is $result1, <<OUT;
set_t2: bar = 2
set_t2: bar = 24
result: foo = 120
OUT

is $result2, <<OUT;
set_t1: foo = 6
set_t1: foo = 120
result: bar = 24
OUT

my $result3;

EJS::Template->process("$RealBin/data/include/index.ejs", {
    include => sub {
        my ($path) = @_;
        EJS::Template->context->process("$RealBin/data/include/$path");
    }
}, \$result3);

is $result3, <<OUT;
Header:
This is a header.
Content:
This is a content.
Footer:
This is a footer.
OUT
