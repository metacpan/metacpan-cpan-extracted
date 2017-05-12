# NAME

Fabnewsru::Parser - Parser of fabnews.ru

# VERSION

version 0.01

# SYNOPSIS

    use Fabnewsru::Parser qw(parse_lab get_paginated_urls parse_labs_list get_lab_by_page_and_tr);

        my $urls = get_paginated_urls("http://fabnews.ru/fablabs/");
    my $labs = parse_labs_list("http://fabnews.ru/fablabs/list/:all/page1/");
    my $h = parse_lab("http://fabnews.ru/fablabs/item/ufo/");
    my $longlat = yandex_geocoder($h->{location});

    Here are listed only public functions

# METHODS

## parse\_lab

This method is doing parsing page like http://fabnews.ru/fablabs/item/\* (e.g. http://fabnews.ru/fablabs/item/ufo/) and return hashref

Uses Fabnewsru::Utils::table2hash function

e.g. parse\_lab("http://fabnews.ru/fablabs/item/ufo/"); 

Result will  be like this:

{
	"business\_fields" => "3d печать, CAM",
	"foundation\_date" => "03 Декабрь 2013",
	"location" => "Россия, Ростов-на-Дону, ул. Мильчакова 5/2 лаб.5а",
	"phone" => "+79885851900",
	"email" => "team@fablab61.ru",
	"website" => "http://fablab61.ru/"
};

## get\_lab\_by\_page\_and\_tr

Useful for debugging and production both

Getting info about FabLab at particular page of fabnews.ru and at particular table row

As option, makes geocoding via Yandex Maps API

Uses get\_paginate\_numbers, parse\_labs\_list and parse\_lab functions

my $lab\_data = get\_lab\_by\_page\_and\_tr({ page => 2, tr => 0, validate => 1, make\_geocoding => 1 });

page enumeration starts from 2, tr from 0

Will hash ref address like 

                {
          'longlat' => '45.16511,53.199109',
          'email' => 't.salyukov@gmail.com',
          'url' => 'http://fabnews.ru/fablabs/item/deistvui/',
          'location' => 'Россия, Заречный (Пензенская обл.), ул. Конституции СССР, д.39А',
          'fabnews_subscribers' => '1',
          'business_fields' => 'робототехника, электроника, программирование, 3d печать, дизайн',
          'name' => 'ЦМИТ Действуй',
          'website' => 'http//www.cmitdeistvui.ru',
          'phone' => '+79061560868',
          'foundation_date' => '12 Июль 2013',
          'fabnews_rating' => '0'
        };

## parse\_labs\_list

Parses list of fablabs into an array of hashes

my $labs = parse\_labs\_list("http://fabnews.ru/fablabs/list/:all/page1/");

Return arrayref

## get\_paginate\_numbers

Define how much pages there are in pagination.

Returns scalar

Method: checks url at last href

E.g. if url is like list/:all/page8/ so get\_paginate\_numbers will return 8

Works good with standart LiveStreet CMS pagination html, haven't tested it at other CMS

## get\_paginated\_urls

Generate links to each paginated page. Use get\_paginate\_numbers() method

Input: url with pagination

Return: list of urls

## get\_native\_paginated\_urls

Experimental alternative to get\_paginated\_urls

In a Livestreet CMS result could be without first page

# AUTHOR

Pavel Serikov <pavelsr@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
