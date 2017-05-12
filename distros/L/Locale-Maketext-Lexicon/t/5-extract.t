#! /usr/bin/perl -w
use lib '../lib';
use strict;
use Test::More tests => 86;

use_ok('Locale::Maketext::Extract');
my $Ext = Locale::Maketext::Extract->new();

isa_ok( $Ext => 'Locale::Maketext::Extract' );

#### BEGIN WRAPPING TESTS ############

write_po_ok( <<'__EXAMPLE__' => <<'__EXPECTED__', "wrap off" );
_('string');
_('string');
__EXAMPLE__
#: :1 :2
msgid "string"
msgstr ""
__EXPECTED__

$Ext->{wrap} = 1;
write_po_ok( <<'__EXAMPLE__' => <<'__EXPECTED__', "wrap on" );
_('string');
_('string');
__EXAMPLE__
#: :1
#: :2
msgid "string"
msgstr ""
__EXPECTED__

#### END WRAPPING TESTS ############
$Ext->{wrap} = 0;


#### BEGIN HTML::Mason (aka Mason 1) TESTS ############
SKIP: {
    skip( 'HTML::Mason unavailable', 6 ) unless eval { require HTML::Mason };

    $Ext = Locale::Maketext::Extract->new( plugins => { mason => '*' } );

    write_po_ok( <<'__EXAMPLE__' => <<'__EXPECTED__', "HTML::Mason simple" );
<&|/l&>string1</&>
<&|/loc&>string2</&>
__EXAMPLE__
#: :1
msgid "string1"
msgstr ""

#: :2
msgid "string2"
msgstr ""
__EXPECTED__


    write_po_ok( <<'__EXAMPLE__' => <<'__EXPECTED__', "HTML::Mason simple with spaces" );
<&| /l&>string1</&>
<&|/l &>string2</&>
<&| /l &>string3</&>
<&| /loc&>string4</&>
<&|/loc &>string5</&>
<&| /loc &>string6</&>
__EXAMPLE__
#: :1
msgid "string1"
msgstr ""

#: :2
msgid "string2"
msgstr ""

#: :3
msgid "string3"
msgstr ""

#: :4
msgid "string4"
msgstr ""

#: :5
msgid "string5"
msgstr ""

#: :6
msgid "string6"
msgstr ""
__EXPECTED__


    write_po_ok( <<'__EXAMPLE__' => <<'__EXPECTED__', "HTML::Mason one argument" );
<&|/l,arg1=>value1&>string1</&>
<&|/loc,arg1=>value1&>string2</&>
__EXAMPLE__
#. (arg1=>value1)
#: :1
msgid "string1"
msgstr ""

#. (arg1=>value1)
#: :2
msgid "string2"
msgstr ""
__EXPECTED__


    write_po_ok( <<'__EXAMPLE__' => <<'__EXPECTED__', "HTML::Mason one argument with spaces" );
<&|/l, arg1=>value1&>string1</&>
<&|/loc, arg1=>value1&>string2</&>
<&|/l ,arg1=>value1&>string3</&>
<&|/loc ,arg1=>value1&>string4</&>
<&|/l , arg1=>value1&>string5</&>
<&|/loc , arg1=>value1&>string6</&>
<&| /l , arg1=>value1 &>string7</&>
<&| /loc , arg1=>value1 &>string8</&>
__EXAMPLE__
#. (arg1=>value1)
#: :1
msgid "string1"
msgstr ""

#. (arg1=>value1)
#: :2
msgid "string2"
msgstr ""

#. (arg1=>value1)
#: :3
msgid "string3"
msgstr ""

#. (arg1=>value1)
#: :4
msgid "string4"
msgstr ""

#. (arg1=>value1)
#: :5
msgid "string5"
msgstr ""

#. (arg1=>value1)
#: :6
msgid "string6"
msgstr ""

#. (arg1=>value1)
#: :7
msgid "string7"
msgstr ""

#. (arg1=>value1)
#: :8
msgid "string8"
msgstr ""
__EXPECTED__


    write_po_ok( <<'__EXAMPLE__' => <<'__EXPECTED__', "HTML::Mason two arguments" );
<&|/l,arg1=>value1,arg2=>value2&>string1</&>
<&|/loc,arg1=>value1,arg2=>value2&>string2</&>
__EXAMPLE__
#. (arg1=>value1,arg2=>value2)
#: :1
msgid "string1"
msgstr ""

#. (arg1=>value1,arg2=>value2)
#: :2
msgid "string2"
msgstr ""
__EXPECTED__


    write_po_ok( <<'__EXAMPLE__' => <<'__EXPECTED__', "HTML::Mason two arguments with spaces" );
<&|/l ,arg1=>value1,arg2=>value2&>string1</&>
<&|/loc ,arg1=>value1,arg2=>value2&>string2</&>
<&|/l , arg1=>value1,arg2=>value2&>string3</&>
<&|/loc , arg1=>value1,arg2=>value2&>string4</&>
<&|/l , arg1=>value1, arg2=>value2&>string5</&>
<&|/loc , arg1=>value1, arg2=>value2&>string6</&>
<&| /l , arg1=>value1, arg2=>value2 &>string7</&>
<&| /loc , arg1=>value1, arg2=>value2 &>string8</&>
__EXAMPLE__
#. (arg1=>value1,arg2=>value2)
#: :1
msgid "string1"
msgstr ""

#. (arg1=>value1,arg2=>value2)
#: :2
msgid "string2"
msgstr ""

#. (arg1=>value1,arg2=>value2)
#: :3
msgid "string3"
msgstr ""

#. (arg1=>value1,arg2=>value2)
#: :4
msgid "string4"
msgstr ""

#. (arg1=>value1, arg2=>value2)
#: :5
msgid "string5"
msgstr ""

#. (arg1=>value1, arg2=>value2)
#: :6
msgid "string6"
msgstr ""

#. (arg1=>value1, arg2=>value2)
#: :7
msgid "string7"
msgstr ""

#. (arg1=>value1, arg2=>value2)
#: :8
msgid "string8"
msgstr ""
__EXPECTED__

}
#### END HTML::Mason (aka Mason 1) TESTS ############


#### BEGIN Mason (aka Mason 2) TESTS ############
SKIP: {
    skip( 'Mason unavailable', 6 ) unless eval { require Mason };

    $Ext = Locale::Maketext::Extract->new( plugins => { mason => '*' } );

    write_po_ok( <<'__EXAMPLE__' => <<'__EXPECTED__', "Mason simple" );
<%$.fl {%>string1</%>
<%$.floc {%>string2</%>
<%$self->fl {%>string3</%>
<%$self->floc {%>string4</%>
__EXAMPLE__
#: :1
msgid "string1"
msgstr ""

#: :2
msgid "string2"
msgstr ""

#: :3
msgid "string3"
msgstr ""

#: :4
msgid "string4"
msgstr ""
__EXPECTED__


    write_po_ok( <<'__EXAMPLE__' => <<'__EXPECTED__', "Mason simple with spaces" );
<% $.fl {%>string1</%>
<% $.floc {%>string2</%>
<% $self->fl {%>string3</%>
<% $self->floc {%>string4</%>
<% $.fl { %>string5</%>
<% $.floc { %>string6</%>
<% $self->fl { %>string7</%>
<% $self->floc { %>string8</%>
__EXAMPLE__
#: :1
msgid "string1"
msgstr ""

#: :2
msgid "string2"
msgstr ""

#: :3
msgid "string3"
msgstr ""

#: :4
msgid "string4"
msgstr ""

#: :5
msgid "string5"
msgstr ""

#: :6
msgid "string6"
msgstr ""

#: :7
msgid "string7"
msgstr ""

#: :8
msgid "string8"
msgstr ""
__EXPECTED__


    write_po_ok( <<'__EXAMPLE__' => <<'__EXPECTED__', "Mason one argument" );
<%$.fl(arg1=>value1){%>string1</%>
<%$.floc(arg1=>value1){%>string2</%>
<%$self->fl(arg1=>value1){%>string3</%>
<%$self->floc(arg1=>value1){%>string4</%>
__EXAMPLE__
#. (arg1=>value1)
#: :1
msgid "string1"
msgstr ""

#. (arg1=>value1)
#: :2
msgid "string2"
msgstr ""

#. (arg1=>value1)
#: :3
msgid "string3"
msgstr ""

#. (arg1=>value1)
#: :4
msgid "string4"
msgstr ""
__EXPECTED__


    write_po_ok( <<'__EXAMPLE__' => <<'__EXPECTED__', "Mason one argument with spaces" );
<% $.fl(arg1=>value1){%>string1</%>
<% $.floc(arg1=>value1){%>string2</%>
<% $.fl(arg1=>value1) {%>string3</%>
<% $.floc(arg1=>value1) {%>string4</%>
<% $.fl(arg1=>value1) { %>string5</%>
<% $.floc(arg1=>value1) { %>string6</%>
__EXAMPLE__
#. (arg1=>value1)
#: :1
msgid "string1"
msgstr ""

#. (arg1=>value1)
#: :2
msgid "string2"
msgstr ""

#. (arg1=>value1)
#: :3
msgid "string3"
msgstr ""

#. (arg1=>value1)
#: :4
msgid "string4"
msgstr ""

#. (arg1=>value1)
#: :5
msgid "string5"
msgstr ""

#. (arg1=>value1)
#: :6
msgid "string6"
msgstr ""
__EXPECTED__


    write_po_ok( <<'__EXAMPLE__' => <<'__EXPECTED__', "Mason two arguments" );
<% $.fl(arg1=>value1,arg2=>value2){%>string1</%>
<% $.floc(arg1=>value1,arg2=>value2){%>string2</%>
<%$self->fl(arg1=>value1,arg2=>value2){%>string3</%>
<%$self->floc(arg1=>value1,arg2=>value2){%>string4</%>
__EXAMPLE__
#. (arg1=>value1,arg2=>value2)
#: :1
msgid "string1"
msgstr ""

#. (arg1=>value1,arg2=>value2)
#: :2
msgid "string2"
msgstr ""

#. (arg1=>value1,arg2=>value2)
#: :3
msgid "string3"
msgstr ""

#. (arg1=>value1,arg2=>value2)
#: :4
msgid "string4"
msgstr ""
__EXPECTED__



    write_po_ok( <<'__EXAMPLE__' => <<'__EXPECTED__', "Mason two arguments with spaces" );
<%$.fl(arg1=>value1,arg2=>value2){%>string1</%>
<%$.floc(arg1=>value1,arg2=>value2){%>string2</%>
<% $.fl (arg1=>value1,arg2=>value2){%>string3</%>
<% $.floc (arg1=>value1,arg2=>value2){%>string4</%>
<% $.fl (arg1=>value1, arg2=>value2){%>string5</%>
<% $.floc (arg1=>value1, arg2=>value2){%>string6</%>
<% $.fl (arg1=>value1, arg2=>value2) {%>string7</%>
<% $.floc (arg1=>value1, arg2=>value2) {%>string8</%>
<% $.fl (arg1=>value1, arg2=>value2) { %>string9</%>
<% $.floc (arg1=>value1, arg2=>value2) { %>string10</%>
__EXAMPLE__
#. (arg1=>value1,arg2=>value2)
#: :1
msgid "string1"
msgstr ""

#. (arg1=>value1, arg2=>value2)
#: :10
msgid "string10"
msgstr ""

#. (arg1=>value1,arg2=>value2)
#: :2
msgid "string2"
msgstr ""

#. (arg1=>value1,arg2=>value2)
#: :3
msgid "string3"
msgstr ""

#. (arg1=>value1,arg2=>value2)
#: :4
msgid "string4"
msgstr ""

#. (arg1=>value1, arg2=>value2)
#: :5
msgid "string5"
msgstr ""

#. (arg1=>value1, arg2=>value2)
#: :6
msgid "string6"
msgstr ""

#. (arg1=>value1, arg2=>value2)
#: :7
msgid "string7"
msgstr ""

#. (arg1=>value1, arg2=>value2)
#: :8
msgid "string8"
msgstr ""

#. (arg1=>value1, arg2=>value2)
#: :9
msgid "string9"
msgstr ""
__EXPECTED__

}
#### END Mason (aka Mason 2) TESTS ############


#### BEGIN FORMFU TESTS ############
SKIP: {
    skip( 'YAML.pm unavailable', 5 ) unless eval { require YAML };

    $Ext = Locale::Maketext::Extract->new( plugins => { formfu => '*' } );

    extract_ok( "    content_loc: foo bar\n" => "foo bar", "html-formfu 1" );
    write_po_ok( <<"__YAML__", <<"__PO__", 'html-formfu 2' );
---
    content_loc: foo bar
    name: something else
    value_loc: something else as well
__YAML__
#: :2
msgid "foo bar"
msgstr ""

#: :4
msgid "something else as well"
msgstr ""
__PO__

    write_po_ok( <<"__YAML__" => <<"__PO__", 'html-formfu 3' );
---
    content_loc: foo bar
    name: something else
---
    value_loc: something else as well
__YAML__
#: :2
msgid "foo bar"
msgstr ""

#: :5
msgid "something else as well"
msgstr ""
__PO__
    write_po_ok( <<"__YAML__" => <<"__PO__", 'html-formfu 4' );
---
    name: {content_loc: foo, other: bar, value_loc: baz }
    value_loc: other

__YAML__
#: :2
msgid "baz"
msgstr ""

#: :2
msgid "foo"
msgstr ""

#: :3
msgid "other"
msgstr ""
__PO__

    write_po_ok( <<"__YAML__" => <<"__PO__", 'html-formfu 5' );
---
    name: {content_loc: foo, other: bar, value_loc: baz }
    list:
        - { content_loc: hash1 }
        - more: { content_loc: hash2 }
        - and_more:
            - content_loc: nest_1
            - { value_loc: nest_2 }
            - content_loc:
                - foo
                - bar
            - content_loc: [foo, bar]
            - content_loc: {foo: bar}
    value_loc: other

__YAML__
#: :2
msgid "baz"
msgstr ""

#. (bar)
#: :12 :2 :9
msgid "foo"
msgstr ""

#: :4
msgid "hash1"
msgstr ""

#: :5
msgid "hash2"
msgstr ""

#: :7
msgid "nest_1"
msgstr ""

#: :8
msgid "nest_2"
msgstr ""

#: :14
msgid "other"
msgstr ""
__PO__

}

#### END FORMFU TESTS ############

#### BEGIN TT TESTS ############
SKIP: {
    skip( 'Template.pm unavailable', 50 ) unless eval { require Template };

    $Ext = Locale::Maketext::Extract->new( plugins => { tt2 => '*' } );

    extract_ok( <<'__EXAMPLE__' => 'foo bar baz', 'trim the string (tt)' );
[% |loc -%]
foo bar baz
[%- END %]
__EXAMPLE__

    write_po_ok( q([% l(string) %]) => '', 'TT l function - no string' );

    write_po_ok(
        q([% l('string') %]) => <<'__EXAMPLE__', 'TT l function - no arg' );
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

    write_po_ok(
        q([% l('string',arg) %]) =>
            <<'__EXAMPLE__', 'TT l function - variable arg' );
#. (arg)
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

    write_po_ok(
        q([% l('string','arg') %]) =>
            <<'__EXAMPLE__', 'TT l function - literal arg' );
#. ("arg")
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

    write_po_ok(
        q([% string | l %]) => '',
        'TT l inline filter - no string'
    );

    write_po_ok(
        q([% 'string' | l %]) =>
            <<'__EXAMPLE__', 'TT l inline filter - no arg' );
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

    write_po_ok(
        q([% 'string' | l('arg')  %]) =>
            <<'__EXAMPLE__', 'TT l inline filter - literal arg' );
#. ("arg")
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

    write_po_ok(
        q([% 'string' | l(arg)  %]) =>
            <<'__EXAMPLE__', 'TT l inline filter - variable arg' );
#. (arg)
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

    write_po_ok(
        q([% |l %][% string %][% END %]) => '',
        'TT l block filter - no string'
    );

SKIP: {
        skip "Can't handle directive embedded in text blocks", 1;

        write_po_ok(
            q([% |l %] string [% var %][% END %]) => '',
            'TT l block filter - embedded directive'
        );
    }

    write_po_ok(
        q([% |l %]string[% END %]) =>
            <<'__EXAMPLE__', 'TT l block filter - no arg' );
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

    write_po_ok(
        q([% |l('arg') %]string[% END %]) =>
            <<'__EXAMPLE__', 'TT l block filter - literal arg' );
#. ("arg")
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

    write_po_ok(
        q([% |l(arg) %]string[% END %]) =>
            <<'__EXAMPLE__', 'TT l block filter - variable arg' );
#. (arg)
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

    write_po_ok(
        q([% FILTER l(arg) %]string[% END %]) =>
            <<'__EXAMPLE__', 'TT block FILTER - variable arg' );
#. (arg)
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

    write_po_ok(
        q([% loc('string',arg) %]) =>
            <<'__EXAMPLE__', 'TT loc function - variable arg' );
#. (arg)
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

    write_po_ok(
        q([% 'string' | loc('arg')  %]) =>
            <<'__EXAMPLE__', 'TT loc inline filter - literal arg' );
#. ("arg")
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT multiline filter' );
[% | l(arg1,arg2) %]
my string
[% END %]
__TT__
#. (arg1, arg2)
#: :1
msgid ""
"\n"
"my string\n"
msgstr ""
__EXAMPLE__

    write_po_ok(
        <<'__TT__' => <<'__EXAMPLE__', 'TT multiline filter with chomp' );
[%- | l(arg1,arg2) -%]
my string
[%- END -%]
__TT__
#. (arg1, arg2)
#: :3
msgid "my string"
msgstr ""
__EXAMPLE__

    extract_ok(
        q([% l('catted ' _ 'string') %]) => "catted string",
        "TT catted string"
    );
    extract_ok( q([% l('catted ' _ string) %]) => "", "TT catted dir 1" );
    extract_ok( q([% l('catted ' _ string) %]) => "", "TT catted dir 2" );

    extract_ok(
        q([% l("embedded ${string}") %]) => "",
        "TT embedded string 1"
    );
    extract_ok(
        q([% l("embedded \${string}") %]) => 'embedded ${string}',
        "TT embedded string 2"
    );
    extract_ok(
        q([% l('embedded ${string}') %]) => 'embedded ${string}',
        "TT embedded string 3"
    );

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT quoted - 1' );
[% l('my \ string', 'my \ string') %]
[% l('my \\ string', 'my \\ string') %]
[% l("my \\ string", "my \\ string") %]
__TT__
#. ("my \\ string")
#: :1 :2 :3
msgid "my \\ string"
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT quoted - 2' );
[% l('my str\'ing','my str\'ing') %]
__TT__
#. ("my str'ing")
#: :1
msgid "my str'ing"
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT quoted - 3' );
[% l('my string"','my string"') %]
__TT__
#. ("my string\"")
#: :1
msgid "my string\""
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT quoted - 4' );
[% l("my string'","my string'") %]
__TT__
#. ("my string'")
#: :1
msgid "my string'"
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT quoted - 5' );
[% l("my \nstring","my \nstring") %]
__TT__
#. ("my \nstring")
#: :1
msgid ""
"my \n"
"string"
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT quoted - 6' );
[% l('my \nstring','my \nstring') %]
__TT__
#. ("my \\nstring")
#: :1
msgid "my \\nstring"
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT quoted - 7' );
[% 'my \ string'  | l('my \ string') %]
[% 'my \\ string' | l('my \\ string') %]
[% "my \\ string" | l("my \\ string") %]
__TT__
#. ("my \\ string")
#: :1 :2 :3
msgid "my \\ string"
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT quoted - 8' );
[% 'my str\'ing' | l('my str\'ing') %]
__TT__
#. ("my str'ing")
#: :1
msgid "my str'ing"
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT quoted - 9' );
[% 'my string"' | l('my string"') %]
__TT__
#. ("my string\"")
#: :1
msgid "my string\""
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT quoted - 10' );
[% "my string'" |l("my string'") %]
__TT__
#. ("my string'")
#: :1
msgid "my string'"
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT quoted - 11' );
[% "my \nstring" |l("my \nstring") %]
__TT__
#. ("my \nstring")
#: :0
msgid ""
"my \n"
"string"
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT quoted - 12' );
[% 'my \nstring' |l('my \nstring') %]
__TT__
#. ("my \\nstring")
#: :1
msgid "my \\nstring"
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT quoted - 13' );
[% | l('my \ string') %]my \ string[% END %]
[% | l('my \\ string') %]my \\ string[% END %]
__TT__
#. ("my \\ string")
#: :1
msgid "my \\ string"
msgstr ""

#. ("my \\ string")
#: :2
msgid "my \\\\ string"
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT quoted - 14' );
[% | l('my str\'ing') %]my str'ing[% END %]
__TT__
#. ("my str'ing")
#: :1
msgid "my str'ing"
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT quoted - 15' );
[% | l('my str\'ing') %]my str\'ing[% END %]
__TT__
#. ("my str'ing")
#: :1
msgid "my str\\'ing"
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT quoted - 16' );
[% | l("my str\"ing") %]my str"ing[% END %]
__TT__
#. ("my str\"ing")
#: :1
msgid "my str\"ing"
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT quoted - 17' );
[% | l("my str\"ing") %]my str\"ing[% END %]
__TT__
#. ("my str\"ing")
#: :1
msgid "my str\\\"ing"
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT quoted - 18' );
[% |l("my \nstring") %]my
string[% END %]
__TT__
#. ("my \nstring")
#: :1
msgid ""
"my\n"
"string"
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT quoted - 19' );
[% |l('my \nstring') %]my \nstring[% END %]
__TT__
#. ("my \\nstring")
#: :1
msgid "my \\nstring"
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT key values' );
[% l('string', key1=>'value',key2=>value, key3 => value.method) %]
__TT__
#. ({ 'key1' => 'value', 'key2' => value, 'key3' => value.method })
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'TT complex args' );
[% l('string',b.method.$var(arg),c('arg').method.5) %]
__TT__
#. (b.method.$var(arg), c("arg").method.5)
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

# Mojo tests

    extract_ok(
        q([% c.l('Hello, world!') %]) => "Hello, world!",
        "Mojolicious c.l syntax is supported correctly",
    );

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'Mojolicious and c.l filter syntax' );
[% 'my string' | c.l %]
__TT__
#: :1
msgid "my string"
msgstr ""
__EXAMPLE__

    extract_ok(
        q([% c.loc('Hello, world!') %]) => "Hello, world!",
        "Mojolicious c.loc syntax is supported correctly",
    );

    write_po_ok( <<'__TT__' => <<'__EXAMPLE__', 'Mojolicious and c.loc filter syntax' );
[% 'my string' | c.loc %]
__TT__
#: :1
msgid "my string"
msgstr ""
__EXAMPLE__

    #### END TT TESTS ############
}

#### BEGIN YAML TESTS ############
SKIP: {
    skip( 'YAML.pm unavailable', 9 ) unless eval { require YAML };

    $Ext = Locale::Maketext::Extract->new( plugins => { yaml => '*' } );

    extract_ok( qq(key: _"string"\n) => "string", "YAML double quotes" );
    extract_ok( qq(key: _'string'\n) => "string", "YAML single quotes" );
    extract_ok(
        qq(key: _"str"ing"\n) => 'str"ing',
        "YAML embedded double quote"
    );

    extract_ok(
        qq( key: { s1: _"string_1", s2: _'string_2', s3: _'string'3'}\n) =>
            q(string'3string_1string_2),
        'YAML inline hash'
    );

    extract_ok(
        qq( - _"string_1"\n - _'string_2'\n - _'string'3'\n) =>
            q(string'3string_1string_2),
        'YAML array'
    );

    extract_ok(
        qq(key: [ _"string_1", _'string_2', _'string'3' ]\n) =>
            q(string'3string_1string_2),
        'YAML Inline arrays'
    );

    write_po_ok(
        qq(---\nkey: _"string"\n---\nkey2: _"string2"\n\n\n\n) =>
            <<'__EXAMPLE__', 'YAML multiple docs' );
#: :2
msgid "string"
msgstr ""

#: :4
msgid "string2"
msgstr ""
__EXAMPLE__

    write_po_ok( <<__YAML__ => <<'__EXAMPLE__', 'YAML folded/block scalars' );
---
key: >
        _'My folded
        scalar'
key2: |-
        _'My block
        scalar
        '
__YAML__
#: :5
msgid ""
"My block\n"
"scalar\n"
msgstr ""

#: :2
msgid "My folded scalar"
msgstr ""
__EXAMPLE__

    write_po_ok( <<__YAML__ => <<'__EXAMPLE__', 'YAML nested' );
---
foo:
    bar:
        - _'first'
        - baz: >
                _'second'
    boo: |-
            _'My block
            scalar
            '
    bla:    [ _'inline_seq' , _'inline_seq2' ]


__YAML__
#: :7
msgid ""
"My block\n"
"scalar\n"
msgstr ""

#: :4
msgid "first"
msgstr ""

#: :11
msgid "inline_seq"
msgstr ""

#: :11
msgid "inline_seq2"
msgstr ""

#: :5
msgid "second"
msgstr ""
__EXAMPLE__

}
#### END YAML TESTS ############

#### BEGIN HAML TESTS ##########
SKIP: {
    skip( 'HAML unavailable', 6 ) unless eval { require Text::Haml };

    $Ext = Locale::Maketext::Extract->new( plugins => { haml => '*' } );

    extract_ok( '%a{:href=>"#"}= "[+] " . l("string")' => "string", "HAML double quotes." );
    extract_ok( '%a{:href=>"#"}= "[+] " . l("str\"ing")' => "str\"ing", "HAML double quotes with escaped \"." );
    extract_ok( q|%a{:href=>"#"}= "[+] " . l('string')| => "string", "HAML single quotes." );
    extract_ok( q|%a{:href=>"#"}= "[+] " . l('[_1] plus [_1] equals [_2].', 'two', 'five')| => "%1 plus %1 equals %2.", "HAML string with args." );
    extract_ok( '- stash(title => l("My Title"))' => "My Title", "HAML Perl block.");

    write_po_ok( <<'__EXAMPLE__' => <<'__EXPECTED__', "HAML file" );
!!! 5
%html
  %head
    %meta{:charset => "utf-8"}
      %title title
      %link{:rel=>"stylesheet", :href=>"/css/style.css"}
      %script{:type=>"text/javascript", :src=>"/js/jquery-1.8.2.min.js"}
  %body
    %ul#nav
      %li
        %a{:href=>"#"}= l("Home")
      %li
        %a{:href=>"#"}= "[+] " . l("About")
      %li
        %a{:href=>"#"}= "[+] " . l('[_1] plus [_1] equals [_2].', 'two', 'five')
__EXAMPLE__
#. ('two', 'five')
#: :1
msgid "%1 plus %1 equals %2."
msgstr ""

#: :1
msgid "About"
msgstr ""

#: :1
msgid "Home"
msgstr ""
__EXPECTED__
}
#### END HAML TESTS ############


sub extract_ok {
    my ( $text, $expected, $info, $verbatim ) = @_;
    $Ext->extract( '' => $text );
    $Ext->compile($verbatim);
    my %lexicon = %{ $Ext->lexicon };
    my $result = join( '', map { $_ => $lexicon{$_} } sort keys %lexicon );
    is( $result, $expected, $info );
    $Ext->clear;
}

sub write_po_ok {
    my ( $text, $expected, $info, $verbatim ) = @_;
    my $po_file = 't/5-extract.po';

    # create .po
    $Ext->extract( '' => $text );
    $Ext->compile($verbatim);
    $Ext->write_po($po_file);

    # read .po
    open( my $po_handle, '<', $po_file ) or die("Cannot open $po_file: $!");
    local $/ = undef;
    my $result = <$po_handle>;
    close($po_handle);
    unlink($po_file) or die("Cannot unlink $po_file: $!");

    # cut the header from result
    my $start_expected = length( $Ext->header );
    $start_expected++ if ( $start_expected < length($result) );

    # check result vs expected
    is( substr( $result, $start_expected ), $expected, $info );
    $Ext->clear;
}

