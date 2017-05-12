package   MyDocument;
use Mandel::Document;

field 'foo';
field with_builder_cb => (builder => sub {123});
field with_builder_method => (builder => '_build_me');
field [qw( bar baz )];

sub _build_me {'yay'}

package main;
use Mojo::Base -strict;
use Test::More;

can_ok 'MyDocument', 'foo';
can_ok 'MyDocument', 'bar';
can_ok 'MyDocument', 'baz';

my $doc = MyDocument->new;

is $doc->foo, undef, 'foo is undef';

$doc->data->{bar} = 123;
is $doc->bar, 123, 'bar is 123';

is $doc->baz(42), $doc, 'baz setter return self';
is $doc->baz, 42, 'baz is 42';

is $doc->with_builder_cb,     123,   'with_builder_cb()';
is $doc->with_builder_method, 'yay', 'with_builder_method()';

is_deeply $doc->TO_JSON, $doc->data, 'TO_JSON() is alias for data()';

done_testing;
