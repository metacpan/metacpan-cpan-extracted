use strict;
use Test::More tests => 13;
use HTML::TagCloud::Extended::Tag;
use POSIX;

my $time = time;

my $format1 = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime($time) );
my $format2 = POSIX::strftime("%Y/%m/%d %H:%M:%S", localtime($time) );
my $format3 = POSIX::strftime("%Y%m%d%H%M%S", localtime($time) );

my $tag = HTML::TagCloud::Extended::Tag->new(
	name      => 'perl',
	url       => 'http://www.perl.org/',
	count     => 30,
	timestamp => $format1,
);

is( $tag->name, 'perl'                 );
is( $tag->url,  'http://www.perl.org/' );
is( $tag->count, 30                    );
is( $tag->epoch, $time                 );

my $tag2 = HTML::TagCloud::Extended::Tag->new(
	name      => 'apache',
	url       => 'http://www.apache.org/',
	count     => 20,
	timestamp => $format2,
);

is( $tag2->name, 'apache'                 );
is( $tag2->url,  'http://www.apache.org/' );
is( $tag2->count, 20                      );
is( $tag2->epoch, $time                   );

my $tag3 = HTML::TagCloud::Extended::Tag->new(
	name      => 'ruby',
	url       => 'http://www.ruby.jp/',
	count     => 10,
	timestamp => $format3,
);

is( $tag3->name, 'ruby'                 );
is( $tag3->url,  'http://www.ruby.jp/'  );
is( $tag3->count, 10                    );
is( $tag3->epoch, $time                 );

eval{
	my $tag4 = HTML::TagCloud::Extended::Tag->new(
		name      => 'catalyst',
		url       => 'http://catalyst.perl.org/',
		count     => 20,
		timestamp => '2005-08-30 23:59:59:59',
	);
};
like( $@, qr/Wrong timestamp format/ );

