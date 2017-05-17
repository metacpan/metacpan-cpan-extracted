#!/usr/bin/env perl
use strict;
use feature qw(say);
use Web::Scraper;
use URI;
use Data::Dumper;
use JSON::XS;
use HTML::TreeBuilder::LibXML;
use LWP::UserAgent;
use HTTP::Message;
use Template;
use Try::Tiny;

my $template = Template->new();

my $json = JSON::XS->new->pretty;

my @pages = qw(account account_settings album basic comment conversation custom_gallery gallery_album gallery_image gallery_profile image meme_metadata message notification tag tag_vote topic vote);
my $models = {};

foreach my $model (@pages) {
	
	my $tree = get_page("https://api.imgur.com/models/$model");
	my @options;
	say STDERR $model;
	$models->{$model} = [];
	my $res = {fields=>[]};
	my $pname = $model;
	$pname=~s/_([a-z])/uc($1)/eg;
	$res->{pname} = ucfirst($pname);
	
	
	my ($content_tree) = ($tree->look_down(_tag=>"div",id=>"content"));

	my $content = parse_html($content_tree->as_HTML);
	my ($description,$main) = $content->look_down(_tag=>'div',class=>'textbox');

	my ($example) = ($content->look_down(_tag=>"div",class=>"json"));
	if ($example) {
		my $ext = $example->as_text;
		$ext=~s/\n//g;
		$ext=~s/\s{2,}//g;
		$ext=~s/\,([}\]])/$1/g;

		$ext=~s/\[\.*?[^'|"|}|{].*?\]/[]/g;

		#$ext=~s/\[ \.\.\. \]/[]/g;
		$ext=~s/\.\.\.//g;
		$ext=~s/\]"/],"/g;
		$ext=~s/\\ //g;

		$ext=~s/[^'|"](\w+):[^\/]/"$1":/g;
		$ext=~s/""/","/g;

		
			
		try {	
			$res->{example} = $json->encode($json->decode($ext));
		} catch {		
			$res->{example} = $example->as_text;
		};
	}

	$res->{description}=$description->as_text;
	$res->{description}=~s/Description//;
	$res->{description}=~s/\s{2,}/ /g;

	
	
	#my ($main) = $tree->look_down(_tag=>'div',id=>'gallery_images');
	#if (!$main) {
		#($main) = $tree->look_down(_tag=>'div',id=>'model');
	#}

	next if (!$main);
	my ($fields_table) = $main->find("table");
	next if (!$fields_table);
	foreach my $fields_row (($fields_table->find("tr"))) {
		if ($fields_row->attr('class') ne "header") {
			my ($name,$type,$desc) = map {$_->as_text} $fields_row->find("td");
			my $field = {name=>$name,type=>$type,desc=>$desc};
			push(@{$res->{fields}},$field);
		}
	}
	push(@{$models->{$model}},$res);
	
}

my $json =  JSON::XS->new->relaxed->pretty;
say $json->encode($models);


sub get_page {
	my ($url) = @_;

	my $ua = LWP::UserAgent->new();	
	$ua->agent('Mozilla/5.0 (X11; U; Linux x86_64; en-US) AppleWebKit/532.0 (KHTML, like Gecko) Chrome/4.0.202.0 Safari/532.0');
    my $res = $ua->get($url,'Accept-Encoding'=>HTTP::Message::decodable);
    if ($res->code == 200) {
		return parse_html($res->decoded_content);
	}
	return undef;
}

sub parse_html {
	my $html = shift;

	my $content = HTML::TreeBuilder::LibXML->new_from_content($html);
    return $content->elementify;
}

