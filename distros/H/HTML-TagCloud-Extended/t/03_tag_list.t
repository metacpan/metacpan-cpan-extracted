use strict;
use Test::More tests => 20;
use HTML::TagCloud::Extended::TagList;
use HTML::TagCloud::Extended::Tag;

my $list = HTML::TagCloud::Extended::TagList->new;

my $tag = HTML::TagCloud::Extended::Tag->new(
	name      => 'perl',
	url       => 'http://www.perl.org/',
	count     => 30,
	timestamp => '2005-01-01 00:00:00'
);

$list->add($tag);

is( $list->count, 1 );

my $tag2 = HTML::TagCloud::Extended::Tag->new(
	name      => 'python',
	url       => 'http://www.python.org/',
	count     => 20,
	timestamp => '2005-08-01 00:00:00'
);

$list->add($tag2);

is( $list->count, 2 );

my $tag3 = HTML::TagCloud::Extended::Tag->new(
	name      => 'ruby',
	url       => 'http://www.ruby.org/',
	count     => 40,
	timestamp => '2005-06-01 00:00:00'
);

$list->add($tag3);

is( $list->count, 3 );

my $tag4 = $list->get_tag_at(0);

isa_ok( $tag4, "HTML::TagCloud::Extended::Tag" );
is( $tag4->name, 'perl'                        );
is( $tag4->url,  'http://www.perl.org/'        );
is( $tag4->count, 30                           );

my $ite = $list->iterator;

isa_ok( $ite, "HTML::TagCloud::Extended::TagList::Iterator" );
my $tag5 = $ite->next;
my $tag6 = $ite->next;
my $tag7 = $ite->next;
my $tag8 = $ite->next;

is( $tag5->name, 'perl'   );
is( $tag6->name, 'python' );
is( $tag7->name, 'ruby'   );
is( $tag8, undef );

$list->sort('name_desc');
$ite = $list->iterator;

my $tag9  = $ite->next;
my $tag10 = $ite->next;
my $tag11 = $ite->next;

is( $tag9->name,  'ruby'   );
is( $tag10->name, 'python' );
is( $tag11->name, 'perl'   );

$list->sort('count');
$ite = $list->iterator;

my $tag12 = $ite->next;
my $tag13 = $ite->next;
my $tag14 = $ite->next;

is( $tag12->name, 'python' );
is( $tag13->name, 'perl'   );
is( $tag14->name, 'ruby'   );

is( $list->max_count, 40 );
is( $list->min_count, 20 );

