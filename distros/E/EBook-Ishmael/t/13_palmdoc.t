#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use EBook::Ishmael::EBook;

my $DOC = File::Spec->catfile(qw/t data gpl3.pdb/);

my $ebook = EBook::Ishmael::EBook->new($DOC);
isa_ok($ebook, 'EBook::Ishmael::EBook::PalmDoc');

like($ebook->{Source}, qr/\Q$DOC\E$/, "source ok");

subtest "PDB data ok" => sub {

	plan tests => 14;

	is($ebook->{_pdb}->name,          'gpl3',      "name ok");
	is($ebook->{_pdb}->attributes,    0,           "attributes ok");
	is($ebook->{_pdb}->version,       0,           "version ok");
	is($ebook->{_pdb}->cdate,         1738876110,  "creation date ok");
	is($ebook->{_pdb}->mdate,         1738876110,  "modification date ok");
	is($ebook->{_pdb}->bdate,         0,           "backup date ok");
	is($ebook->{_pdb}->modnum,        0,           "modification number ok");
	is($ebook->{_pdb}->app_info,      0,           "app info ok");
	is($ebook->{_pdb}->sort_info,     0,           "sort info ok");
	is($ebook->{_pdb}->type,          0x54455874,  "type ok");
	is($ebook->{_pdb}->creator,       0x52454164,  "creator ok");
	is($ebook->{_pdb}->uid_seed,      10,          "uid seed ok");
	is($ebook->{_pdb}->next_rec_list, 0,           "next record list ok");
	is($ebook->{_pdb}->recnum,        10,          "record number ok");

};

subtest "PalmDoc header data ok" => sub {

	plan tests => 5;

	is($ebook->{_compression}, 2,      "compression ok");
	is($ebook->{_textlen},     35550,  "text length ok");
	is($ebook->{_recnum},      9,      "record number ok");
	is($ebook->{_recsize},     4096,   "record size ok");
	is($ebook->{_curpos},      0,      "current position ok");

};

is(
	length(join('', map { $ebook->_decode_record($_) } 0 .. $ebook->{_recnum} - 1)),
	$ebook->{_textlen},
	"text decoding ok"
);

is_deeply(
	$ebook->metadata,
	{
		Title => [ 'gpl3' ],
		Created => [ scalar gmtime $ebook->{_pdb}->cdate ],
		Modified => [ scalar gmtime $ebook->{_pdb}->mdate ],
		Format => [ 'PalmDOC' ],
	},
	"metadata ok"
);

ok($ebook->html, "html ok");

ok(!$ebook->has_cover, "has no cover");

ok(! defined $ebook->cover, "has no cover");

is($ebook->image_num, 0, "image count ok");

is($ebook->image(0), undef, "image #0 ok");

done_testing();
