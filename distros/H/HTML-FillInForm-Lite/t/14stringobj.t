#!perl -w

use strict;
use Test::More tests => 1;

use HTML::FillInForm::Lite;

{
    package MyString;
    use overload '""' => sub { q{<input type="text" name="foo" value="" />} };
    sub new { bless {} }
}

my $s = MyString->new();
like(
    HTML::FillInForm::Lite->fill(\$s, { foo => "bar" }),
    qr/value="bar"/xms,
);
