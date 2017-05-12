package Fabnewsru::Parser;
$Fabnewsru::Parser::VERSION = '0.01';
# ABSTRACT: Parser of fabnews.ru



use warnings;
use Mojo::UserAgent;
use Exporter qw(import);
# use Encode;
use Data::Dumper;
use feature 'say';
use Fabnewsru::Utils qw(table2hash table2array_of_hashes merge_hashes rm_spec_symbols_from_string);
use Fabnewsru::Geo qw(yandex_geocoder);
# use Devel::Peek;
# use common::sense;

# our @EXPORT_OK = qw(parse_lab get_paginated_urls get_paginate_numbers parse_labs_list get_lab_by_page_and_tr);

my $ua = Mojo::UserAgent->new;

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}



sub parse_lab {
	my ($self, $url) = @_;
	my $dom = $ua->get($url)->res->dom;
	my $match = {
		foundation_date => "Дата основания",
		website => "Сайт",
		business_fields => "Виды деятельности",
		location => "Местоположение",
		email => "E-mail",
		phone => "Телефон"
	};
	my $h = table2hash($dom, ".company-profile-table");
	return merge_hashes($match, $h);
}




sub get_lab_by_page_and_tr {

	#my ($page, $tr, $make_geocoding, $validate) = @_;
	my ($self, $params) = @_; # hashref

	my $is_valid = 1;

	if ($params->{validate}) {

		my $pages_total = $self->get_paginate_numbers("http://fabnews.ru/fablabs/");
		my $rows_total = $self->parse_labs_list('http://fabnews.ru/fablabs/list/:all/page'.$params->{page}.'/');
		warn "pages:".$pages_total.",rows:".scalar @$rows_total;

		if ($params->{page} > $pages_total || $params->{tr} > scalar @$rows_total) {
			$is_valid = 0;
		}
	}

	if ($is_valid) {

		my $t = $self->parse_labs_list('http://fabnews.ru/fablabs/list/:all/page'.$params->{page}.'/');    #array of hashes

		my $hash1 = $t->[$params->{tr}];
		my $hash2 = $self->parse_lab($t->[$params->{tr}]->{url});
		my $hash3;
		%$hash3 = (%$hash1, %$hash2); # combine results

		if ($params->{make_geocoding}) {

			# warn "Location string: ".$hash3->{'location'};
			# Dump $hash3->{'location'};
			# warn "End of DUMP! ####################";

			my $longlat = yandex_geocoder($hash3->{'location'}); 
			
			$longlat = join(',', split(' ', $longlat)); # долгота, широта
			$hash3->{'longlat'} = $longlat;
		}

		delete $hash3->{urls};
	
		return $hash3;
	
	} else {

		die "specified page or row does not exist";
	
	} 
}




sub parse_labs_list {
	my ($self, $url) = @_;
	my $dom = $ua->get($url)->res->dom;
	my @fields = ("name", "fabnews_subscribers", "fabnews_rating");
	my $a = table2array_of_hashes($dom, "table", \@fields);

	# warn Dumper $a;
	# filter results
	for (@$a) {
		if ($_->{name} =~ /Последний пост из блога/) {
			my ($name, $last_post) = split("Последний пост из блога", $_->{name});
			$_->{name} = rm_spec_symbols_from_string($name);
			$_->{last_post} = rm_spec_symbols_from_string($last_post);
		}
		$_->{url} = $_->{urls}->[0]."/";
	}
	return $a;
}



sub get_paginate_numbers {
	my ($self, $url) = @_;
	my $pagination = $ua->get($url)->res->dom->at(".pagination");
	my @a = $pagination->find("ul")->each;
	my @ref = $a[1]->find("li")->each;
	my $q = scalar @ref;
	my $last_link = $ref[$q-1]->at("a[href]")->attr("href");    # target link with page
	$last_link =~ /page(\d{1})/;							
	return $1;
}




sub get_paginated_urls {
	my ($self, $url) = @_;
	my $n = $self->get_paginate_numbers ($url);
	my @urls;
	for (my $i=1; $i <= $n; $i++) {
    	push @urls, 'http://fabnews.ru/fablabs/list/:all/page'.$i.'/';
    }
	return \@urls;
}


sub get_native_paginated_urls {
	my ($self, $url_with_pagination) = @_;
	my $ua = Mojo::UserAgent->new;
	my $pagination = $ua->get($url_with_pagination)->res->dom->at(".pagination");
	my @a = $pagination->find("ul")->each;
	my @urls;
	for my $e ($a[1]->find("li")->each) {
		if (length $e) {
			my $j = $e->at("a[href]");
			if (length $j || $j ne "") {
				# say $j->attr("href");
				push @urls, $j->attr("href");
			}
		}
	}
	return \@urls;
}




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Fabnewsru::Parser - Parser of fabnews.ru

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Fabnewsru::Parser qw(parse_lab get_paginated_urls parse_labs_list get_lab_by_page_and_tr);

	my $urls = get_paginated_urls("http://fabnews.ru/fablabs/");
    my $labs = parse_labs_list("http://fabnews.ru/fablabs/list/:all/page1/");
    my $h = parse_lab("http://fabnews.ru/fablabs/item/ufo/");
    my $longlat = yandex_geocoder($h->{location});

    Here are listed only public functions

=head1 METHODS

=head2 parse_lab

This method is doing parsing page like http://fabnews.ru/fablabs/item/* (e.g. http://fabnews.ru/fablabs/item/ufo/) and return hashref

Uses Fabnewsru::Utils::table2hash function

e.g. parse_lab("http://fabnews.ru/fablabs/item/ufo/"); 

Result will  be like this:

{
	"business_fields" => "3d печать, CAM",
	"foundation_date" => "03 Декабрь 2013",
	"location" => "Россия, Ростов-на-Дону, ул. Мильчакова 5/2 лаб.5а",
	"phone" => "+79885851900",
	"email" => "team@fablab61.ru",
	"website" => "http://fablab61.ru/"
};

=head2 get_lab_by_page_and_tr

Useful for debugging and production both

Getting info about FabLab at particular page of fabnews.ru and at particular table row

As option, makes geocoding via Yandex Maps API

Uses get_paginate_numbers, parse_labs_list and parse_lab functions

my $lab_data = get_lab_by_page_and_tr({ page => 2, tr => 0, validate => 1, make_geocoding => 1 });

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

=head2 parse_labs_list

Parses list of fablabs into an array of hashes

my $labs = parse_labs_list("http://fabnews.ru/fablabs/list/:all/page1/");

Return arrayref

=head2 get_paginate_numbers

Define how much pages there are in pagination.

Returns scalar

Method: checks url at last href

E.g. if url is like list/:all/page8/ so get_paginate_numbers will return 8

Works good with standart LiveStreet CMS pagination html, haven't tested it at other CMS

=head2 get_paginated_urls

Generate links to each paginated page. Use get_paginate_numbers() method

Input: url with pagination

Return: list of urls

=head2 get_native_paginated_urls

Experimental alternative to get_paginated_urls

In a Livestreet CMS result could be without first page

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
