use Test::More tests=>11;
use File::Spec;

use lib '../Directory-Iterator-PP/blib/lib';
use lib '../Directory-Iterator-XS/blib/lib';
use lib '../Directory-Iterator-XS/blib/arch';
use Directory::Iterator;

is (@Directory::Iterator::ISA, 1, 'found parent');


my $obj = Directory::Iterator->new('t');

#isa_ok($obj, 'Directory::Iterator::XS');
isa_ok($obj, 'Directory::Iterator');

foreach my $method ('get', 'next', 'prune', 'show_dotfiles', 'show_directories', 'prune_directory') {
  ok ($obj->can($method), "can $method");
};

do {
	my $list = Directory::Iterator->new( File::Spec->join('t','data'));
	my $count;
	++ $count while <$list>;
	is ($count, 1, 'found 1 file');
};

do {
	my $list = Directory::Iterator->new( File::Spec->join('t','data'));
	$list->show_dotfiles(1);
	my $count;
	++ $count while <$list>;
	is ($count, 2, 'found 2 files');
};

do {
	my $list = Directory::Iterator->new( File::Spec->join('t','data'), show_dotfiles=>1);
	my $count;
	++ $count while <$list>;
	is ($count, 2, 'found 2 files');
};

#my $list = Directory::Iterator->new('/tmp/', blah=>1);
