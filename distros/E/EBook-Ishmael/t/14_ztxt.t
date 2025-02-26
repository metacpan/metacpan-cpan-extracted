#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use EBook::Ishmael::EBook;

my $DOC = File::Spec->catfile(qw/t data gpl3.ztxt/);

my $ebook = EBook::Ishmael::EBook->new($DOC);
isa_ok($ebook, 'EBook::Ishmael::EBook::zTXT');

like($ebook->{Source}, qr/\Q$DOC\E$/, "source ok");

subtest "PDB data ok" => sub {

	plan tests => 14;

	is(
		$ebook->{_pdb}->name,
		'GNU General Public License',
		"name ok"
	);
	is($ebook->{_pdb}->attributes,    8,           "attributes ok");
	is($ebook->{_pdb}->version,       298,         "version ok");
	is($ebook->{_pdb}->cdate,         1011337408,  "creation date ok");
	is($ebook->{_pdb}->mdate,         1011337408,  "modification date ok");
	is($ebook->{_pdb}->bdate,         -2082844800, "backup date ok");
	is($ebook->{_pdb}->modnum,        0,           "modification number ok");
	is($ebook->{_pdb}->app_info,      0,           "app info ok");
	is($ebook->{_pdb}->sort_info,     0,           "sort info ok");
	is($ebook->{_pdb}->type,          2052347988,  "type ok");
	is($ebook->{_pdb}->creator,       1196452973,  "creator ok");
	is($ebook->{_pdb}->uid_seed,      0,           "uid seed ok");
	is($ebook->{_pdb}->next_rec_list, 0,           "next record list ok");
	is($ebook->{_pdb}->recnum,        5,           "record number ok");

};

subtest "zTXT header data ok" => sub {

	plan tests => 11;

	is($ebook->{_version},     298,   "version ok");
	is($ebook->{_recnum},      3,     "record number ok");
	is($ebook->{_size},        18007, "size ok");
	is($ebook->{_recsize},     8192,  "record size ok");
	is($ebook->{_bookmarknum}, 4,     "bookmark number ok");
	is($ebook->{_bookmarkrec}, 4,     "bookmark record ok");
	is($ebook->{_annotnum},    0,     "annotation number ok");
	is($ebook->{_annotrec},    0,     "annotation record ok");
	is($ebook->{_flags},       1,     "flags ok");
	is($ebook->{_reserved},    0,     "reserved ok");
	is($ebook->{_crc32},       0,     "crc32 ok");

};

is(
	length($ebook->_text),
	$ebook->{_size},
	"text decoding ok"
);

is_deeply(
	$ebook->metadata,
	{
		Title => [ 'GNU General Public License' ],
		Created => [ scalar gmtime $ebook->{_pdb}->cdate ],
		Modified => [ scalar gmtime $ebook->{_pdb}->mdate ],
		Format => [ 'zTXT 1.42' ],
	},
	"metadata ok"
);

ok($ebook->html, "html ok");

ok(!$ebook->has_cover, "has no cover");

ok(! defined $ebook->cover, "has no cover");

done_testing();
