use strict;
use Test::More tests => 10;

use lib qw(t/lib);

use Devel::IntelliPerl;
use Scalar::Util qw(refaddr);

my $source = <<'SOURCE';
use Foo;
my $foo = new Foo;

$foo->foo
SOURCE

ok(my $ip = Devel::IntelliPerl->new(source => $source, line_number => 4, column => 7));

ok(grep { $_ eq 'bar' } $ip->methods, 'found method "bar"');

$source =~ s/foo->/foo->bar->/;

ok($ip = Devel::IntelliPerl->new(source => $source, line_number => 4, column => 12));

is($ip->keyword, '$foo->bar');

is($ip->guess_class('$foo->bar'), 'Bar', '$foo->bar isa Bar');

is($ip->guess_class('$foo->bar->bar'), 'Bar', '$foo->bar->bar isa Bar');

is($ip->guess_class('$foo->foo->bar->foo'), 'Foo', '$foo->foo->bar->one->foo isa Foo');

is($ip->guess_class('$foo->bar->two'), 'Signatures', '$foo->bar->two isa Signatures');

is($ip->guess_class('$foo->signatures->file'), 'Path::Class::File', '$foo->signatures->file isa Path::Class::File');

ok(grep { $_ eq 'bar' } $ip->methods, 'found method "bar"');
