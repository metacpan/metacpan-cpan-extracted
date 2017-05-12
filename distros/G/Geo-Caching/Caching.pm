package Geo::Caching;

use strict;
use warnings;
use WWW::Mechanize;
use Geo::Cache;
use Geo::Gpx;
use XML::Simple;

# Docs {{{

=head1 NAME

Geo::Caching - Object interface for querying Geocaching.com website

=head1 SYNOPSIS

    use Geo::Caching;
    my $gc = new Geo::Caching( 
        login       => 'casey',   # Your Geocaching username
	password    => 'mypass',  # Your Geocaching password
	max_results => 500,	 # Max number of caches to return
	cache_days  => 3,	 # Cache results for 3 days
	cache_dir   => '/tmp/geocache' #directory to cache into
    );

    ### Get one Geo::Cache
    my $cache = $gc->get('GCMMVH');

    ### Get Geo::Cache list that my user found 
    my @caches = $gc->query(
	type => 'UL',
	username => 'cpnkr,
    );
		

    #### List of valid query types
    ####################################
    # ZIP => By Postal Code
    # WPT => By Coordinate
    # UL  => By Username (Found)
    # U   => By Username (Hidden)
    # WN  => By Waypoint Name
    ####################################
    ####

=head1 DESCRIPTION

Provide an object interface to query Geocaching.com 

=head1 AUTHOR

	Casey Lee
	cplee@cplee.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

# }}}

use vars qw($VERSION $AUTOLOAD);
$VERSION = '0.11';

# sub new {{{

sub new {
    my $class = shift;
    my $params = { @_ };
    my $self = {};
    my %config = ( login => ($params->{login} || ''),
		   password => ($params->{password} || ''),
		   max_results => ($params->{max_results} || 500),
		   sleep => ($params->{sleep} || 1),
		   cache_days => ($params->{cache_days} || 1),
		   cache_dir => ($params->{cache_dir} || '/tmp/geocache'),
		 );
		   
    $self = bless( \%config, ref($class) || $class );

    return ($self);
} # }}}

# AUTOLOADER {{{

sub AUTOLOAD {
    my $self = shift;
    my $val = shift;
    my ( $method );
    ( $method = $AUTOLOAD ) =~ s/.*:://;

    if (defined $val) {
        $self->{$method} = $val;
    } else {
        # Use the existing value
    }

    return $self->{$method};
} # }}}


sub get {
	my $self = shift;
	my $wpt  = shift;

	##########################
	my $login_url = 'http://www.geocaching.com/login/default.aspx';
	my $details_url = 'http://www.geocaching.com/seek/cache_details.aspx';
	##########################

	my $login = $self->{login};
	my $password = $self->{password};

	my $mech = new WWW::Mechanize(cookie_jar => {});

	# login to geocaching.com
	$mech->get($login_url);
	$mech->field('myUsername', $login);
	$mech->field('myPassword', $password);
	$mech->click_button(value => 'Login');

	# get the user's caches
	$mech->get("$details_url?WP=$wpt");
	my $res = $mech->click_button(name => 'btnGPXDL');
	my @caches = $self->parse_gpx(xml => $res->content());

	return $caches[0];
}

sub query {
	my $self = shift;
	my $args = {@_};

	##########################
	my $login_url = 'http://www.geocaching.com/login/default.aspx';
	my $nearest_url = 'http://www.geocaching.com/seek/nearest.aspx';
	##########################

	my $login = ($args->{login} || $self->{login});
	my $password = ($args->{password} || $self->{password});
	my $sleep = ($args->{sleep}      || $self->{sleep});
	my $max   = ($args->{max_results} || $self->{max_results} || 500);
	my $type  = $args->{type};
	my $cache_list = ($args->{cache_list} || []);
	my $cache_dir = ($args->{cache_dir} || $self->{cache_dir});
	my $cache_days = ($args->{cache_days} || $self->{cache_days});
	my $no_cache = $args->{no_cache};

	my $query;

        `mkdir -p $cache_dir`;

	####################################
	# ZIP => By Postal Code
	# WPT => By Coordinate
	# SC  => By State/Country
	# KW  => By Keyword
	# UL  => By Username (Found)
	# U   => By Username (Hidden)
	# WN  => By Waypoint Name
	####################################

	if($type eq 'ZIP') {
		my $zip = $args->{zipcode};
		if($zip =~ /^\d{5}$/) {
			$query = "ZIP=$zip";
		}
	} elsif ($type eq 'WPT') {
		my $lat = $args->{lat};
		my $lon = $args->{lon};

		if($lat =~ /^[-\d\.]+$/ &&
		   $lon =~ /^[-\d\.]+$/) {
			$query = "LAT=$lat&LON=$lon";
		}
	} elsif ($type eq 'SC') {
	} elsif ($type eq 'KW') {
	} elsif ($type eq 'UL') {
		my $user = $args->{username} || $self->{login};
		$query = "UL=$user";
	} elsif ($type eq 'U') {
		my $user = $args->{username} || $self->{login};
		$query = "U=$user";
	} elsif ($type eq 'WN') {
		my $wpt = $args->{waypoint};
		if($wpt =~ /^GC(\w+)$/) {
			$query = "WN=$wpt";
		}
	} else {
		warn "Unsupported type: $type\n";
	}


	unless($query) {
		warn "Error...bailing out";
		return;
	}

	### caching
        my $t_file = $query;
        $t_file =~ s/[\.\/]//g;
        my $t_path = "$cache_dir/$t_file";


        ### Use the cache
        if(!$no_cache
           && (-e $t_path)
           && (-M $t_path < $cache_days))
        {
		my $content;
		open (F, $t_path);
		while(<F>) {$content .= $_};
		close(F);
		$self->parse_gpx(xml => $content,
				 cache_list => $cache_list,
				 );
		return @$cache_list;
        }


	if($query =~ /^WN/) {
		push @$cache_list, $self->get($args->{waypoint});
	} else {
		my $mech = new WWW::Mechanize(cookie_jar => {});
		my $cache_attribs = {};

		# login to geocaching.com
		$mech->get($login_url);
		$mech->field('myUsername', $login);
		$mech->field('myPassword', $password);
		$mech->click_button(value => 'Login');

		# get the user's caches
		$mech->get("$nearest_url?$query");

		my $page = 1;
		while((scalar @$cache_list) < $max) {

			## Get some info about each cache
			my $c = $mech->content;
			$c =~ m{<table id="dlResults".*?>(.*?)</table>}is;
			my $t = $1;
			my @rows = $t =~ m{<tr.*?>\s*<td.*?>\s*<tr.*?>(.*?)</tr>\s*</td>\s*</tr>}gsi;
			shift @rows;
			foreach my $r (@rows) {
				my @cells = $r =~ m{<td.*?>(.*?)</td>}gsi;
				my $attribs = {};
				my $name = '';

				## force init of cells
				for(my $ci=0; $ci<8; $ci++) {
					$cells[$ci] ||= "";
				}
				
				## Get the cache name
				if($cells[5] =~ /\((GC.+)\)/) {
					$name = $1;
				}

				## Get the cache type
				if( $cells[2] =~ /<img src=.* title="(.*?)"/) {
					$attribs->{type} = $1;
				}

				## Get the difficulty/terrain/size
				if($cells[3] =~ /\(([\d\.]+)\/([\d\.]+)\).*title="Size: (.*)"/) {
					$attribs->{difficulty} = $1;
					$attribs->{terrain} = $2;
					$attribs->{size} = $3;
				}

				## Get the dates
				$attribs->{hidden_date} = $cells[4];
		
				if(my @fdates = $cells[6] =~ m{(\d{2} \w{3} \d{2})}gs) {
					$attribs->{last_found_date} = $fdates[0];
					$attribs->{user_found_date} = $fdates[1];
				}

				# Get and chek the box, if it exists
				if($cells[7] =~ /<INPUT type='checkbox' name='CID' value='(\d+)'>/i) {
				#	warn "$name -> $1: ".join(',',%$attribs)."\n";
					$mech->tick('CID',$1);

					## add the attribs to a hash keyed by GCNAME
					$cache_attribs->{$name} = $attribs;
				}
				else 
				{
				}
			}
	if(0) {
			my @images = $mech->find_all_images(
				url_regex => qr/\/images\/WptTypes\/\d/);
			my @sym;
			foreach my $i (@images) {
				my $a = $i->alt();
				push @sym, $a;
			}

			my $form = $mech->form_number(1);
			my @cids = $form->find_input('CID','checkbox');
			foreach my $cid (@cids) {
				$cid->check();
			}
	}
			my $res = $mech->click_button(value => 'Download Waypoints');
			$self->parse_loc(xml => $res->content(),
					 cache_attribs => $cache_attribs,
					 cache_list => $cache_list);

			$mech->back();


			my $next_link = $mech->find_link( text_regex => qr/Next/i );
			if($next_link) {
				my $url = $next_link->url();
				if($url =~ /javascript:__doPostBack\('(.+)\$(.+)','(.*)'\)/) {
					my $target = "$1:$2";
					my $argument = $3;

					$mech->field('__EVENTTARGET',$target);
					$mech->field('__EVENTARGUMENT',$argument);
					$mech->submit();
					
					sleep $sleep if $sleep;  # be nice to geocaching.com :)
				}
			} else {
				last;
			}
		}
	}

	if(open(F,">$t_path"))
	{
		my $gpx = new Geo::Gpx(@$cache_list);
		print F $gpx->xml();
		close(F);
	}


	return @$cache_list;
}




sub parse_gpx {
	my $self = shift;
	my $args = {@_};
	my $xml = $args->{xml};
	my $caches = $args->{cache_list} || [];
	my $xs = new XML::Simple();
	my $ref = $xs->XMLin($xml);
	if(ref $ref->{wpt} eq 'ARRAY') {
		foreach my $w (@{ $ref->{wpt} }) {
			my $gc = new Geo::Cache(%$w);
			push @$caches, $gc;
		} 
	} elsif(ref $ref->{wpt} eq 'HASH') {
		if(exists $ref->{wpt}->{name}) {
			my $gc = new Geo::Cache(%{$ref->{wpt}});
			push @$caches, $gc;
		} else {
			foreach my $k (keys %{ $ref->{wpt} }) {
				my $w = $ref->{wpt}->{$k};
				$w->{name} = $k;
				my $gc = new Geo::Cache(%$w);
				push @$caches, $gc;
			} 
		}
	}

	return @$caches;
}

sub parse_loc {
	my $self = shift;
	my $args = {@_};
	my $xml = $args->{xml};
	my $caches = $args->{cache_list} || [];
	my $xs = new XML::Simple();
	my $ref = $xs->XMLin($xml);

	my $cache_attribs = $args->{cache_attribs} || {};

	if(ref $ref->{waypoint} eq 'ARRAY') {
		foreach my $w (@{ $ref->{waypoint} }) {
			my $attribs = $cache_attribs->{$w->{name}->{id}};
#warn $w->{name}->{id}."-->".join(",",%$attribs)."\n";
			my $desc = $w->{name}->{content}." (".$attribs->{difficulty}."/".$attribs->{terrain}.")";
			my $gc = new Geo::Cache(
				lat => $w->{coord}->{lat},
				lon => $w->{coord}->{lon},
				name => $w->{name}->{id},
				desc => $desc,
				time => 0,
				sym => 'Geocache',
				type  => ($w->{type}."|".($attribs->{type}||'Traditional Cache')),
				url  => $w->{link}->{content},   );
			push @$caches, $gc;
		} 
	} else {
			my $w = $ref->{waypoint};
			my $attribs = $cache_attribs->{$w->{name}->{id}};
			my $desc = $w->{name}->{content}." (".$attribs->{difficulty}."/".$attribs->{terrain}.")";
			my $gc = new Geo::Cache(
				lat => $w->{coord}->{lat},
				lon => $w->{coord}->{lon},
				name => $w->{name}->{id},
				desc => $desc,
				time => 0,
				sym  => 'Geocache',
				type  => ($w->{type}."|".($attribs->{type}||'Traditional Cache')),
				url  => $w->{link}->{content},   );
			push @$caches, $gc;
	}

	return @$caches;
}

1; 


