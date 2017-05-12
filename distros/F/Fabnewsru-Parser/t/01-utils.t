#!perl -T
# use strict;
use warnings;

use lib './lib';
use Fabnewsru::Utils qw(table2hash table2array_of_hashes merge_hashes);
use Mojo::DOM;
use Data::Dumper::AutoEncode; # eDumper for cyrillic symbols
use common::sense;

use Test::More;

my $h1 = {
	foundation_date => "Дата основания",
	website => "Сайт",
	business_fields => "Виды деятельности",
	location => "Местоположение",
	email => "E-mail",
	phone => "Телефон"
};

my $h2 = {
	'Дата основания' => '03 Декабрь 2013',
	'Сайт' => 'http://fablab61.ru/',
	'Виды деятельности' => '3d печать, CAM',	
	'Местоположение' => 'Россия,	Ростов-на-Дону,	ул. Мильчакова 5/2 лаб.5а',
	'E-mail' => 'team@fablab61.ru',
	"Телефон" => '+79885851900'
};


ok( eq_hash 
	(
		merge_hashes($h1, $h2), 
		{
			foundation_date => '03 Декабрь 2013',
			website => 'http://fablab61.ru/',
			business_fields => '3d печать, CAM',
			location => 'Россия,	Ростов-на-Дону,	ул. Мильчакова 5/2 лаб.5а',
			email => 'team@fablab61.ru',
			phone => '+79885851900'
		}
	)
);


my $file = "t/html/test.html";
my $one_lab = do {
    local $/ = undef;
    open my $fh, "<:utf8", $file   # "<:utf8" convert into internal format and set utf8 flag. < just convert
        or die "could not open $file: $!";
    <$fh>;
};

my $dom = Mojo::DOM->new($one_lab);
my $res = table2hash($dom, ".company-profile-table");

my $desired = {
          'Местоположение' => 'Россия, Ростов-на-Дону, ул. Мильчакова 5/2 лаб.5а',
          'Дата основания' => '03 Декабрь 2013',
          'Виды деятельности' => '3d печать, CAM',
          'Сайт' => 'http//fablab61.ru/',
          'Телефон' => '+79885851900',
          'E-mail' => 'team@fablab61.ru'
        };


ok( eq_hash ( $res, $desired ));


done_testing();