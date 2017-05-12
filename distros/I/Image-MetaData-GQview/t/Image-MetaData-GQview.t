#!perl -T
#
# $Id$
#

use Test::More tests => 13;

use Image::MetaData::GQview;

my $md = eval {Image::MetaData::GQview->new};
ok(!$@, "Instanting the class");
ok(defined $md, "new");
isa_ok($md,'Image::MetaData::GQview');
is($md->{error}, undef, "error with new");

# Now create a testfile and a dir...
-e 'test.jpg' and unlink 'test.jpg';
open my $file, ">", 'test.jpg';
print $file "\n";
close $file;

eval {$md->comment("This is a comment")};
ok(!$@, "Setting comment ($@)");
eval {$md->keywords(qw(foo bar))};
ok(!$@, "Setting Keywords ($@)");

ok(eval {$md->save('test.jpg', 'test.jpg.meta')}, 'save("test.jpg", ".metadata/test.jpg.meta")');
ok(!$@, "Save ($@)");

my $md2 = eval {Image::MetaData::GQview->new({fields => [qw(keywords comment test)]})};
ok(!$@, "Instanting the class with options ($@)");
eval {$md2->load('test.jpg', 'test.jpg.meta')};
ok(!$@, "Load a file ($@)");

is(eval {$md2->comment}, "This is a comment\n", "Comment correct written and read?");
my %kw = map {($_ => $_)} eval {$md2->keywords};
ok(($kw{bar} && $kw{foo} && !$kw{gna}), "Keywords correct written and read?");

# Clean up ...
-e 'test.jpg' and unlink 'test.jpg';
-e 'test.jpg.meta' and unlink 'test.jpg.meta';

eval {$md->load('test.jpg')};
ok($@, "Load a (not existing) file (should give an error ($@))");
