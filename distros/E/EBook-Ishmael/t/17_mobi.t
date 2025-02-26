#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use EBook::Ishmael::EBook;

my $DOC = File::Spec->catfile(qw/t data gpl3.mobi/);

my $ebook = EBook::Ishmael::EBook->new($DOC);
isa_ok($ebook, 'EBook::Ishmael::EBook::Mobi');

like($ebook->{Source}, qr/\Q$DOC\E$/, "source ok");

subtest "PDB data ok" => sub {

	plan tests => 14;

	is($ebook->{_pdb}->name,          'gpl3',      "name ok");
	is($ebook->{_pdb}->attributes,    0,           "attributes ok");
	is($ebook->{_pdb}->version,       0,           "version ok");
	is($ebook->{_pdb}->cdate,         -342345385,  "creation date ok");
	is($ebook->{_pdb}->mdate,         -342345385,  "modification date ok");
	is($ebook->{_pdb}->bdate,         -2082844800, "backup date ok");
	is($ebook->{_pdb}->modnum,        0,           "modification number ok");
	is($ebook->{_pdb}->app_info,      0,           "app info ok");
	is($ebook->{_pdb}->sort_info,     0,           "sort info ok");
	is($ebook->{_pdb}->type,          1112493899,  "type ok");
	is($ebook->{_pdb}->creator,       1297039945,  "creator ok");
	is($ebook->{_pdb}->uid_seed,      33,          "uid seed ok");
	is($ebook->{_pdb}->next_rec_list, 0,           "next record list ok");
	is($ebook->{_pdb}->recnum,        17,          "record number ok");

};

subtest "PalmDoc header data ok" => sub {

	plan tests => 5;

	is($ebook->{_compression}, 2,      "compression ok");
	is($ebook->{_textlen},     41672,  "text length ok");
	is($ebook->{_recnum},      11,     "record number ok");
	is($ebook->{_recsize},     4096,   "record size ok");
	is($ebook->{_encryption},  0,      "encryption ok");

};

subtest "Mobi header data ok" => sub {

	plan tests => 8;

	is($ebook->{_doctype},    'MOBI',     "doctype ok");
	is($ebook->{_length},     232,        "header length ok");
	is($ebook->{_type},       2,          "type ok");
	is($ebook->{_codepage},   65001,      "codepage ok");
	is($ebook->{_uid},        1261166645, "uid ok");
	is($ebook->{_version},    6,          "mobi version ok");
	is($ebook->{_exth_flag},  80,         "exth flag ok");
	is($ebook->{_extra_data}, 1,          "extra data ok");

};

TODO: {

	local $TODO = 'Mobi text decode length does not agree with PalmDoc header text length';

	is(
		length(join('', map { $ebook->_decode_record($_) } 0 .. $ebook->{_recnum} - 1)),
		$ebook->{_textlen},
		"text decoding ok"
	);

}

is_deeply(
	$ebook->metadata,
	{
		Contributor => [ 'calibre (7.16.0) [https://calibre-ebook.com]' ],
		Author => [ 'Unknown' ],
		Created => [ '0101-01-01T00:00:00+00:00' ],
		Language => [ 'en' ],
		Title => [ 'gpl3' ],
		Format => [ 'MOBI' ],
		Modified => [ scalar gmtime $ebook->{_pdb}->mdate ],
	},
	"metadata ok"
);

ok($ebook->html, "html ok");

ok($ebook->has_cover, "has cover");

is(
	substr($ebook->cover, 0, 3),
	pack("CCC", 0xff, 0xd8, 0xff),
	"cover looks like a jpeg"
);

done_testing();
