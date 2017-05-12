use Test::More tests => 22;
use_ok("Lingua::EN::NamedEntity");

open KELLY, "t/kelly" or die $!;
my $text; { local $/; $text = <KELLY>; }
my @entities = extract_entities($text);

my %ents = map { $_->{entity} => [$_->{class}, $_->{count}] } @entities;

my %expected = (
# "expected named entity" => [class, count]
"Ministry of Defence" => ["organisation", 2],
"Sir Richard Dearlove" => ["person", 1],
"Martin Howard" => ["person", 1],
"Oxfordshire" => ["place", 1],
"Nick Higham" => ["person", 1],
"Mr Gilligan" => ["person", 1],
"Dr Andy Shuttleworth" => ["person", 1]
);


for (keys %expected) {
    ok(exists $ents{$_}, "Found $_");
    is($ents{$_}->[0], $expected{$_}->[0], "Classified $_ as ".$ents{$_}->[0]);
    is($ents{$_}->[1], $expected{$_}->[1], "Counted ".$ents{$_}->[1]." instances of $_");
}


