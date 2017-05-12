use strict;
use warnings;
use Test::More;

my @attributes = (
    [ ropub => ( is => 'ro', required => 1) ],
    [ _ropriv => ( is => 'ro', required => 1) ],
    [ rwpub => ( is => 'rw', required => 1) ],
    [ _rwpriv => ( is => 'rw', required => 1) ],
    [ barepub => ( is => 'bare', required => 1) ],
    [ _barepriv => ( is => 'bare', required => 1) ],
    [ abcd => ( is => 'ro', required => 1) ],
    [ efg => ( is => 'ro', required => 1) ],
    [ hij => ( is => 'ro', required => 0) ],
);

{ package TestEventAttributeFilter1; use Moose; has(@$_) foreach @attributes;
  with 'Log::Message::Structured'; with 'Log::Message::Structured::Stringify::AsJSON';
  with 'Log::Message::Structured::Component::AttributesFilter' => { type => 'public' }; }
{ package TestEventAttributeFilter2; use Moose; has(@$_) foreach @attributes;
  with 'Log::Message::Structured'; with 'Log::Message::Structured::Stringify::AsJSON';
  with 'Log::Message::Structured::Component::AttributesFilter' => { type => 'private' }; }
{ package TestEventAttributeFilter3; use Moose; has(@$_) foreach @attributes;
  with 'Log::Message::Structured'; with 'Log::Message::Structured::Stringify::AsJSON';
  with 'Log::Message::Structured::Component::AttributesFilter' => { filter => 'out', name => qr/^_/ }; }
{ package TestEventAttributeFilter4; use Moose; has(@$_) foreach @attributes;
  with 'Log::Message::Structured'; with 'Log::Message::Structured::Stringify::AsJSON';
  with 'Log::Message::Structured::Component::AttributesFilter' => { custom => sub { 0 } }; }
{ package TestEventAttributeFilter5; use Moose; has(@$_) foreach @attributes;
  with 'Log::Message::Structured'; with 'Log::Message::Structured::Stringify::AsJSON';
  with 'Log::Message::Structured::Component::AttributesFilter' => { name => qr/^[^_]/ }; }
{ package TestEventAttributeFilter6; use Moose; has(@$_) foreach @attributes;
  with 'Log::Message::Structured'; with 'Log::Message::Structured::Stringify::AsJSON';
  with 'Log::Message::Structured::Component::AttributesFilter' => { name => qr/^abc/ }; }
{ package TestEventAttributeFilter7; use Moose; has(@$_) foreach @attributes;
  with 'Log::Message::Structured'; with 'Log::Message::Structured::Stringify::AsJSON';
  with 'Log::Message::Structured::Component::AttributesFilter' => { name => sub { $_ =~ qr/^efg/ } }; }
{ package TestEventAttributeFilter8; use Moose; has(@$_) foreach @attributes;
  with 'Log::Message::Structured'; with 'Log::Message::Structured::Stringify::AsJSON';
  with 'Log::Message::Structured::Component::AttributesFilter' => { value => sub { $_ eq 2 } }; }
{ package TestEventAttributeFilter9; use Moose; has(@$_) foreach @attributes;
  with 'Log::Message::Structured'; with 'Log::Message::Structured::Stringify::AsJSON';
  with 'Log::Message::Structured::Component::AttributesFilter' => { value => qr/^2$/ }; }

my @expected = (
{class => 'TestEventAttributeFilter1', "barepub" => 1,"efg" => 1,"ropub" => 1,"hij" => 1,"abcd" => 1,"rwpub" => 1}, # public
{"_barepriv" => 1,"_ropriv" => 1,"_rwpriv" => 1}, # private
{class => 'TestEventAttributeFilter3', abcd => 1, efg => 1, hij => 1, rwpub => 1, barepub => 1, ropub => 1}, # filter out
{ }, # custom
{class => 'TestEventAttributeFilter5', "barepub" => 1,"efg" => 1,"ropub" => 1,"hij" => 1,"abcd" => 1,"rwpub" => 1}, # ^[^_]
{"abcd" => 1}, # ^abc
{"efg" => 1}, # ^efg
{"hij" => 2}, # $_ eq 2
{"hij" => 2}, # ^2$
);
my $j = JSON::Any->new;
foreach my $i (1..7) {
    my $c = 'TestEventAttributeFilter' . $i;
    my $e = $c->new(map { $_->[0] => 1 } @attributes);
    is_deeply $j->jsonToObj("$e"), $expected[$i - 1];
}
foreach my $i (8..9) {
    my $c = 'TestEventAttributeFilter' . $i;
    my $e = $c->new(map { $_->[0] => 1, hij => 2 } @attributes);
    is_deeply $j->jsonToObj("$e"), $expected[$i - 1];
}

done_testing;
