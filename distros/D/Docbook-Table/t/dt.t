#!perl -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
    my($class) = shift;
    return bless {}, $class;
}

sub PRINT  {
    my($self) = shift;
    $main::_STDOUT_ .= join '', @_;
}

sub READ {}
sub READLINE {}
sub GETC {}

package main;

local $SIG{__WARN__} = sub { $_STDERR_ .= join '', @_ };
tie *STDOUT, 'Catch' or die $!;


{
#line 47 lib/Docbook/Table.pm

BEGIN {
    use lib "./lib";
    use_ok('Docbook::Table');
    use vars qw($t);
}
$t = Docbook::Table->new();
isa_ok($t, 'Docbook::Table');


}

{
#line 74 lib/Docbook/Table.pm
$t->title("foo");
is($t->{title}, "foo", "Setting title");

}

{
#line 95 lib/Docbook/Table.pm
is($t->headings(), undef, "Set headings fails for empty list");
$t->headings(qw(foo bar baz));
is(ref($t->{headings}), "ARRAY", "Setting headings");
is($t->{headings}[0], "foo", "Setting headings");

}

{
#line 145 lib/Docbook/Table.pm
is($t->body("foo"), undef, "body fails on non hash/arrayref");
$t->body({ a => "apple", b => "banana" });
is(ref($t->{body}), "HASH", "body sets hashref");
$t->body([ [1,2,3], [4,5,6], [7,8,9] ]);
is(ref($t->{body}), "ARRAY", "body sets arrayref");

}

{
#line 175 lib/Docbook/Table.pm
is($t->sort("foo"), undef, "sort fails on non-subref");
$t->sort( sub { $b cmp $a } );
is(ref($t->{sortsub}), "CODE", "sort sets a subroutine ref");

}

{
#line 216 lib/Docbook/Table.pm
like($t->table_opening(), qr/<table>/, "Open table");

}

{
#line 232 lib/Docbook/Table.pm
like($t->table_head(), qr/<thead>/, "table heading");
like($t->table_head(), qr/baz/, "table heading");

}

{
#line 293 lib/Docbook/Table.pm

my $expected = "\t<row>\n\t\t<entry>foo</entry>\n\t</row>\n";
is($t->row("foo"), $expected, "generate a row");


}

