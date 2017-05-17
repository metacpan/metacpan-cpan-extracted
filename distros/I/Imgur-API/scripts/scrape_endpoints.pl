
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

my $template = Template->new();

my @endpoints = qw(account album comment custom_gallery gallery image conversation notification memegen topic);
my $api = {};

my $uri_skip = length("https://api.imgur.com");

foreach my $ep (@endpoints) {
	my $endpoint = ucfirst($ep);
	my $tree = get_page("https://api.imgur.com/endpoints/$ep");
	my @options;
	$api->{$endpoint} = [];
	say STDERR "Endpoint: $endpoint";

	foreach my $command ($tree->look_down(_tag=>"div",class=>"textbox",sub {defined $_[0]->attr('id') && $_[0]->attr('id') ne "current";})) {
		my $details = {
			name=>($command->find("h2"))[0]->as_text,
			description=>($command->find("p"))[0]->as_text,
			params=>{},
			url_params=>{},
		};

		my $id = $command->attr("id");
		$id=~s/^$ep\-//;
		$id=~s/-(\w)/uc($1)/eg;

		if ($id eq lc($ep)) {
			$id = "get";
		};
		$details->{sub} = $id;

		
	
		say STDERR "\tMethod: $details->{name}";
		$details->{description}=~s/\n//g;
		$details->{description}=~s/\s+/ /g;

		my ($request_table,$params_table) = $command->find("table");
		next if (!$request_table);

		my $request={};


		foreach my $request_row (($request_table->find("tr"))) {
			my ($name,$value) = map {$_->as_text} $request_row->find("td");
			$request->{lc($name)} = $value;
		}
		$details->{method} = lc($request->{method});

		if ($params_table) {
			foreach my $tr ($params_table->find("tr")) {
				if ($tr->attr('class') ne "header") {
					my ($name,$required,$desc) = map {$_->as_text} $tr->find("td");
					$details->{params}->{$name} = {desc=>$desc,required=>($required eq "optional")?0:1};
					
        		}
			}
		}

		my @sprintf_args;	

		my @urlparts = split(/\//,substr($request->{route},$uri_skip+1));
		my @finalparts=();
		my @urlparams;
		my @urlparams_opt;

		my $idfield;

		foreach my $part (@urlparts) {
			my ($p) = ($part=~/[{](\w+)[}]/);
			if (!$p) {
				push(@finalparts,$part);
			} else {
				if ($p eq "id") {
					if (!$idfield) {
						$idfield=$p=$ep;
						
					} else {
						$p=$details->{sub};
					}
				}
				if (!$details->{params}->{$p}) {
					$details->{params}->{$p} = {required=>1,desc=>ucfirst($p)};
					push(@urlparams,$p);
					push(@finalparts,"%s");
				} else {
					if ($details->{params}->{$p}->{required}) {
						push(@urlparams,$p);
						push(@finalparts,"%s");
					} else {
						push(@urlparams_opt,$p);
					}
				}
			}
		}
		$details->{url} = {
			base=>join("/",@finalparts),
			required=>join(",",map {qq('$_')} @urlparams),
			optional=>join(",",map {qq('$_')} @urlparams_opt),
		};
		push(@{$api->{$endpoint}},$details);
	}
}

my $json =  JSON::XS->new->pretty;
say $json->encode($api);


sub get_page {
	my ($url) = @_;

	my $ua = LWP::UserAgent->new();	
	$ua->agent('Mozilla/5.0 (X11; U; Linux x86_64; en-US) AppleWebKit/532.0 (KHTML, like Gecko) Chrome/4.0.202.0 Safari/532.0');
    my $res = $ua->get($url,'Accept-Encoding'=>HTTP::Message::decodable);
    if ($res->code == 200) {
    	my $content = HTML::TreeBuilder::LibXML->new_from_content($res->decoded_content);
    	return $content->elementify;
	}
	return undef;
}

