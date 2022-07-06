#!perl

use v5.26;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
use Test::Warnings;

plan tests => 5 + 8 + 8 + 1;


use Mac::Alias qw(is_alias read_alias_perl parse_alias);

my ($r);


ok is_alias 't/eg/folder.alias', 'is_alias folder.alias';
ok is_alias 't/eg/removable.alias', 'is_alias removable.alias';
ok is_alias 't/eg/root.alias', 'is_alias root.alias';
ok ! is_alias __FILE__, 'not is_alias self';
ok ! is_alias '.', 'not is_alias dir';


lives_and {
	is $r = read_alias_perl 't/eg/folder.alias', '/System/Library/Perl';
} 'read_alias folder.alias';
isa_ok $r, Path::Tiny::, 'read_alias folder.alias type';

lives_and {
	is $r = read_alias_perl 't/eg/removable.alias', '/Volumes/SANDISK/untitled';
} 'read_alias removable.alias';
isa_ok $r, Path::Tiny::, 'read_alias removable.alias type';

lives_and {
	is $r = read_alias_perl 't/eg/root.alias', '/';
} 'read_alias root.alias';
isa_ok $r, Path::Tiny::, 'read_alias root.alias type';

lives_and {
	is scalar read_alias_perl __FILE__, undef;
} 'read_alias self lives';

lives_and {
	is scalar read_alias_perl '.', undef;
} 'read_alias dir lives';


my $folder_parsed = {
	"creationDate" => 1594633443,
	"creationOptions" => {
		"kCFURLBookmarkCreationSuitableForBookmarkFile" => 1024,
	},
	"displayName" => "Perl",
	"fileIDs" => [
		'1152921500311902579',
		'1152921500311902703',
		'1152921500312062052',
	],
	"header" => "book\0\0\0\0mark\0\0\0\0008\0\0\0008\0\0\0t\2\0\0\0\0\4\20\0\0\0\0/ali\230\207\214\327\3656\304A\0\0\0\0\0\0\0\0",  # TODO
	"level" => 1,
	"path" => "/System/Library/Perl",
	"pathComponents" => [
		"System",
		"Library",
		"Perl",
	],
	"resourceProps" => "\2\0\0\0\0\0\0\0\37\2\0\0\0\0\0\0\37\2\0\0\0\0\0\0",  # TODO
	"typeBindingData" => "dnib\0\0\0\0\1\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0rdlf\2\2\0\0\0\0\0\0",
	"volCapacity" => '499963174912',
	"volCreationDate" => "1594641815.0816462",
	"volName" => "Macintosh HD",
	"volPath" => "/",
	"volProps" => "\201\0\0\0\1\0\0\0\357\23\0\0\1\0\0\0\357\23\0\0\1\0\0\0",  # TODO
	"volURL" => "file:///",
	"volUUID" => "07FD1A5D-7D66-475A-AF51-934CDEF2D60C",
	"volWasBoot" => 1,
	"wasFileIDFormat" => 1,
};

my $removable_parsed = {
	"creationDate" => 1656841329,
	"creationOptions" => {
		"kCFURLBookmarkCreationSuitableForBookmarkFile" => 1024,
	},
	"displayName" => "untitled",
	"fileIDs" => [
		23589,
		undef,
		undef,
	],
	"header" => "book\0\0\0\0mark\0\0\0\0008\0\0\0008\0\0\0\250\3\0\0\0\0\4\20\0\0\0\0\0\0\0\0\221\16\e\0\3168\304A\0\0\0\0\0\0\0\0",  # TODO
	"level" => 1,
	"next" => {
		"level" => 61440,
		"volCapacity" => '499963174912',
		"volCreationDate" => "1594641815.0816462",
		"volName" => "Macintosh HD",
		"volPath" => "/",
		"volProps" => "\201\0\0\0\1\0\0\0\357\23\0\0\1\0\0\0\357\23\0\0\1\0\0\0",  # TODO
		"volURL" => "file:///",
		"volUUID" => "07FD1A5D-7D66-475A-AF51-934CDEF2D60C",
	},
	"path" => "/Volumes/SANDISK/untitled",
	"pathComponents" => [
		"Volumes",
		"SANDISK",
		"untitled",
	],
	"resourceProps" => "\1\0\0\0\0\0\0\0\37\2\0\0\0\0\0\0\37\2\0\0\0\0\0\0",  # TODO
	"typeBindingData" => "dnib\0\0\0\0\1\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\1\0\0\0\0\0\0\0",
	"volCapacity" => 8003780608,
	"volCreationDate" => 0,
	"volInfoDepths" => [
		61440,
		0,
		1,
		0,
	],
	"volName" => "SANDISK",
	"volPath" => "/Volumes/SANDISK",
	"volProps" => "\341\0\0\0\0\0\0\0\357\23\0\0\1\0\0\0\357\23\0\0\1\0\0\0",  # TODO
	"volURL" => "file:///Volumes/SANDISK/",
	"volUUID" => "66D290A3-6692-3D78-ABD5-A2FE6F3F4DBD",
	"wasFileIDFormat" => 1,
};

my $root_parsed = {
	"creationDate" => "1594641815.0816462",
	"creationOptions" => {
		"kCFURLBookmarkCreationSuitableForBookmarkFile" => 1024,
	},
	"displayName" => "Macintosh HD",
	"fileName" => "Macintosh HD",
	"header" => "book\0\0\0\0mark\0\0\0\0008\0\0\0008\0\0\0l\2\0\0\0\0\4\20\0\0\0\0\0\0\0\0\244\344\373w\3148\304A\0\0\0\0\376\177\0\0",  # TODO
	"level" => 1,
	"path" => "/",
	"pathComponents" => [],
	"resourceProps" => "\n\0\0\0\0\0\0\0\37\2\0\0\0\0\0\0\37\2\0\0\0\0\0\0",  # TODO
	"typeBindingData" => "dnib\0\0\0\0\4\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\35\0\0\0\0\0\0\0\34\0\0\0\0\0\0\0file:///System/Volumes/Data/\322\22\207vf\360\303A\\\0\0\0\0\0\0\0dnib\0\0\0\0\t\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0ksdh\37\0\0\0\0\0\0\0com.apple.iokit.IOStorageFamily\r\0\0\0\0\0\0\0Internal.icns",
	"volCapacity" => '499963174912',
	"volCreationDate" => "1594641815.0816462",
	"volName" => "Macintosh HD",
	"volPath" => "/",
	"volProps" => "\201\0\0\0\1\0\0\0\357\23\0\0\1\0\0\0\357\23\0\0\1\0\0\0",  # TODO
	"volURL" => "file:///",
	"volUUID" => "07FD1A5D-7D66-475A-AF51-934CDEF2D60C",
	"volWasBoot" => 1,
	"wasFileIDFormat" => 1,
};


# Created with:
# $Data::Dumper::Sortkeys = 1;
# $Data::Dumper::Trailingcomma = 1;
# $Data::Dumper::Useqq = 1;


sub fmt_dates {
	my $data = shift;
	my $f = '%.12g';
	$data->{creationDate} = sprintf $f, $data->{creationDate}
		if $data->{creationDate};
	$data->{volCreationDate} = sprintf $f, $data->{volCreationDate}
		if $data->{volCreationDate};
	$data->{next}{creationDate} = sprintf $f, $data->{next}{creationDate}
		if $data->{next}{creationDate};
	$data->{next}{volCreationDate} = sprintf $f, $data->{next}{volCreationDate}
		if $data->{next}{volCreationDate};
	$data;
}

lives_ok { $r = parse_alias 't/eg/folder.alias' } 'parse_alias folder.alias lives';
is_deeply fmt_dates($r), fmt_dates($folder_parsed), 'parse_alias folder.alias';

lives_ok { $r = parse_alias 't/eg/removable.alias' } 'parse_alias removable.alias lives';
is_deeply fmt_dates($r), fmt_dates($removable_parsed), 'parse_alias removable.alias';

lives_ok { $r = parse_alias 't/eg/root.alias' } 'parse_alias root.alias lives';
is_deeply fmt_dates($r), fmt_dates($root_parsed), 'parse_alias root.alias';

throws_ok { parse_alias __FILE__} qr/\bNot a data fork alias\b/i, 'no parse_alias self';
throws_ok { parse_alias '.'} qr/\bNot a data fork alias\b/i, 'no parse_alias self';


done_testing;
