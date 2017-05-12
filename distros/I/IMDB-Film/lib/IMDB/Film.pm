=head1 NAME

IMDB::Film - OO Perl interface to the movies database IMDB.

=head1 SYNOPSIS

	use IMDB::Film;

	#
	# Retrieve a movie information by its IMDB code
	#
	my $imdbObj = new IMDB::Film(crit => 227445);

	or

	#
	# Retrieve a movie information by its title
	#
	my $imdbObj = new IMDB::Film(crit => 'Troy');

	or

	#
	# Parse already stored HTML page from IMDB
	#
	my $imdbObj = new IMDB::Film(crit => 'troy.html');

	if($imdbObj->status) {
		print "Title: ".$imdbObj->title()."\n";
		print "Year: ".$imdbObj->year()."\n";
		print "Plot Symmary: ".$imdbObj->plot()."\n";
	} else {
		print "Something wrong: ".$imdbObj->error;
	}

=head1 DESCRIPTION

=head2 Overview

IMDB::Film is an object-oriented interface to the IMDB.
You can use that module to retrieve information about film:
title, year, plot etc. 

=cut

package IMDB::Film;

use strict;
use warnings;

use base qw(IMDB::BaseClass);

use Carp;
use Data::Dumper;

use fields qw(	_title
				_kind
				_year
				_episodes
				_episodeof
				_summary
				_cast
				_directors
				_writers
				_cover
				_language
				_country
				_top_info
				_rating
				_genres
				_tagline
				_plot
				_also_known_as
				_certifications
				_duration
				_full_plot
				_trivia
				_goofs
				_awards
				_official_sites
				_release_dates
				_aspect_ratio
				_mpaa_info
				_company
				_connections
				_full_companies
				_recommendation_movies
				_plot_keywords
				_big_cover_url
				_big_cover_page
				_storyline
				full_plot_url
		);
	
use vars qw( $VERSION %FIELDS %FILM_CERT %FILM_KIND $PLOT_URL );

use constant CLASS_NAME 	=> 'IMDB::Film';
use constant FORCED			=> 1;
use constant USE_CACHE		=> 1;
use constant DEBUG_MOD		=> 1;
use constant EMPTY_OBJECT	=> 0;
use constant MAIN_TAG		=> 'h4';

BEGIN {
		$VERSION = '0.53';
						
		# Convert age gradation to the digits		
		# TODO: Store this info into constant file
		%FILM_CERT = ( 	G 		=> 'All', 
						R 		=> 16, 
						'NC-17' => 16, 
						PG 		=> 13, 
						'PG-13' => 13
					);							

		%FILM_KIND = ( 	''		=> 'movie',
						TV		=> 'tv movie',
						V		=> 'video movie',
						mini	=> 'tv mini series',
						VG		=> 'video game',
						S		=> 'tv series',
						E		=> 'episode'
					);				
}

{
	my %_defaults = (
		cache			=> 0,
		debug			=> 0,
		error			=> [],
		cache_exp		=> '1 h',
		cache_root		=> '/tmp',
		matched			=> [],
        host			=> 'www.imdb.com',
        query			=> 'title/tt',
        search 			=> 'find?s=tt&exact=true&q=',	
		status			=> 0,		
		timeout			=> 10,
		user_agent		=> 'Mozilla/5.0',
		decode_html		=> 1,
		full_plot_url	=> 'http://www.imdb.com/rg/title-tease/plotsummary/title/tt',		
		_also_known_as	=> [],
		_official_sites	=> [],
		_release_dates	=> [],
		_duration		=> [],
		_top_info		=> [],
		_cast			=> [],
	);	
	
	sub _get_default_attrs { keys %_defaults }		
	sub _get_default_value {
		my($self, $attr) = @_;
		$_defaults{$attr};
	}
}

=head2 Constructor

=over 4

=item new()

Object's constructor. You should pass as parameter movie title or IMDB code.

	my $imdb = new IMDB::Film(crit => <some code>);

or	

	my $imdb = new IMDB::Film(crit => <some title>);

or 
	my $imdb = new IMDB::Film(crit => <HTML file>);

For more infomation about base methods refer to IMDB::BaseClass.

=item _init()

Initialize object.

=cut

sub _init {
	my CLASS_NAME $self = shift;
	my %args = @_;

	croak "Film IMDB ID or Title should be defined!" if !$args{crit} && !$args{file};
	
	$self->SUPER::_init(%args);
	
	$self->title(FORCED, \%args);
	
	unless($self->title) {
		$self->status(EMPTY_OBJECT);
		$self->error('Not Found');
		return;
	} 

	for my $prop (grep { /^_/ &&
	!/^(_title|_code|_full_plot|_official_sites|_release_dates|_connections|_full_companies|_plot_keywords|_big_cover_url|_big_cover_page)$/ } sort keys %FIELDS) {
		($prop) = $prop =~ /^_(.*)/;
		$self->$prop(FORCED);
	}
}

=back

=head2 Options

=over 4

=item year

Define a movie's year. It's useful to use it to get the proper movie by its title:

	my $imdbObj = new IMDB::Film(crit => 'Jack', year => 2003);
	print "Got #" . $imdbObj->code . " " . $imdbObj->title . "\n"; #0379836

=item proxy

defines proxy server name and port:

	proxy => 'http://proxy.myhost.com:80'

By default object tries to get proxy from environment

=item debug

switches on debug mode to display useful debug messages. Can be 0 or 1 (0 by default)

=item cache

indicates use cache or not to store retrieved page content. Can be 0 or 1 (0 by default)

=item cache_root

specifies a directory to store cache data. By default it use /tmp/FileCache for *NIX OS

=item cache_exp

specifies an expiration time for cache. By default, it's 1 hour

=item clear_cache

indicates clear cached data before get request to IMDB.com or not

=item timeout

specifies a timeout for HTTP connection in seconds (10 sec by default)

=item user_agent 

specifies an user agent for request ('Mozilla/5.0' by default)

=item full_plot_url

specifies a full plot url for specified movie

=item host

specifies a host name for IMDB site. By default it's www.imdb.com

=item query

specifies a query string to get specified movie by its ID. By defualt it's 'title/tt'

=item search

specifies query string to make a search movie by its title. By default it's  'find?tt=on;mx=20;q='


Example:

	my $imdb = new IMDB::Film(	crit		=> 'Troy',
								user_agent	=> 'Opera/8.x',
								timeout		=> 2,
								debug		=> 1,
								cache		=> 1,
								cache_root	=> '/tmp/imdb_cache',
								cache_exp	=> '1 d',
							);

It'll create an object with critery 'Troy', user agent 'Opera', timeout 2 seconds, debug mode on,
using cache with directory '/tmp/imdb_cache' and expiration time in 1 day.

=cut

sub full_plot_url {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{full_plot_url} = shift }
	return $self->{full_plot_url}
}

sub fields {
	my CLASS_NAME $self = shift;
	return \%FIELDS;
}

=back

=head2 Object Private Methods

=over 4

=item _search_film()

Implemets functionality to search film by name.

=cut

sub _search_film {
	my CLASS_NAME $self = shift;
	my $args = shift || {};

	return $self->SUPER::_search_results('^\/title\/tt(\d+)', '/td', $args->{year});
}

=back

=head2 Object Public Methods

=over 4

=item status()

Indicates a status of IMDB object:

0 - empty object;
1 - loaded from file;
2 - loaded from internet request;
3 - loaded from cache.

=item status_descr()

Return a description for IMDB object status. Can be 'Empty', 'Filed', 'Fresh' and 'Cached':


	if($film->status) {
		print "This is a " . $film->status_descr . " object!";
	} else {
		die "Cannot retrieve IMDB object!";
	}

=item title()

Retrieve film title from film page. If was got search page instead
of film page this method calls method _search_film to get list
matched films and continue to process first one:

	my $title = $film->title();

=cut

sub title {	
	my CLASS_NAME $self = shift;
	my $forced 	= shift || 0;
	my $args	= shift || {};

	if($forced) {
		my $parser = $self->_parser(FORCED);
	
		$parser->get_tag('title');
		my $title = $parser->get_text();
		if($title =~ /Find \- IMDb/i) {
			$self->_show_message("Go to search page ...", 'DEBUG');
			$title = $self->_search_film($args);				
		} 
		
		if($title) {
			$self->retrieve_code($parser, 'http://www.imdb.com/title/tt(\d+)') unless $self->code;
			$title =~ s/\*/\\*/g;
			$title = $self->_decode_special_symbols($title);
			
			$self->_show_message("title: $title", 'DEBUG');

			# TODO: implement parsing of TV series like ALF (TV Series 1986–1990)
			$title =~ s/^imdb\s+\-\s+//i;
			($self->{_title}, $self->{_year}, $self->{_kind}) = $title =~ m!(.*?)\s+\((\d{4})(?:/[IVX]+)\)(?:\s\((\w*)\))?!;
			unless($self->{_title}) {
				($self->{_title}, $self->{_kind}, $self->{_year}) = $title =~ m!(.*?)\s+\((.*?)?\s?([0-9\-]*\s?)\)!;
			}
			$self->{_kind} = 'Movie' unless $self->{_kind}; # Default kind should be movie
			
       		# "The Series" An Episode (2005)
			# "The Series" (2005)
       		if( $self->{_title} =~ /\"[^\"]+\"(\s+.+\s+)?/ ) {
       			$self->{_kind} = $1 ? 'E' : 'S';
       		}		
		}	
	}	
	
	return $self->{_title};
}

=item kind()

Get kind of movie:

	my $kind = $film->kind();

	Possible values are: 'movie', 'tv series', 'tv mini series', 'video game', 'video movie', 'tv movie', 'episode'.

=cut

sub kind {
	my CLASS_NAME $self = shift;
	return exists $FILM_KIND{$self->{_kind}} ? $FILM_KIND{$self->{_kind}} : lc($self->{_kind});
}

=item year()

Get film year:

	my $year = $film->year();

=cut

sub year {
	my CLASS_NAME $self = shift;
	return $self->{_year};
}

=item connections()

Retrieve connections for the movie as an arrays of hashes with folloeing structure

 	{ 
 		follows 		=> [ { id => <id>, title => <name>, year => <year>, ...,  } ],
  		followed_by  	=> [ { id => <id>, title => <name>, year => <year>, ...,  } ],
  		references 		=> [ { id => <id>, title => <name>, year => <year>, ...,  } ],
  		referenced_in 	=> [ { id => <id>, title => <name>, year => <year>, ...,  } ],
  		featured_in 	=> [ { id => <id>, title => <name>, year => <year>, ...,  } ],
  		spoofed_by 		=> [ { id => <id>, title => <name>, year => <year>, ...,  } ],
	}

  	my %connections = %{ $film->connections() };

=cut

sub connections {
  	my CLASS_NAME $self = shift;

  	unless($self->{_connections}) {
    	my $page;
    	$page = $self->_cacheObj->get($self->code . '_connections') if $self->_cache;

    	unless($page) {
      		my $url = "http://". $self->{host} . "/" . $self->{query} .  $self->code . "/trivia?tab=mc";
      		$self->_show_message("URL for movie connections is $url ...", 'DEBUG');

      		$page = $self->_get_page_from_internet($url);
      		$self->_cacheObj->set($self->code.'_connections', $page, $self->_cache_exp) if $self->_cache;
    	}

    	my $parser = $self->_parser(FORCED, \$page);

    	my $group = undef;
    	my %result;
    	my @lookFor = ('h4');
   	 	while (my $tag = $parser->get_tag(@lookFor)) {
      		if ($tag->[0] eq 'h4') {
        		$group = HTML::Entities::encode_entities($parser->get_text);
				$group = lc($group);
				$group =~ s/\s+/_/g;
				$group =~ s/(&nbsp;|\?|\:)//;
				$group =~ s/&amp;/and/;
        		$result{$group} = [];
        		@lookFor = ('h4', 'a', 'hr', 'hr/');
      		} elsif ($tag->[0] eq 'a') {
        		my $id;
				($id)= $tag->[1]->{href} =~ /(\d+)/ if $tag->[1]->{href};
        		my $name = $parser->get_trimmed_text;

        		# Handle series episodes (usually in 'referenced' sections)
        		my($series,$t,$s,$e) = ($name =~ /^(.*?): *(.*?) *\(?#(\d+)\.(\d+)\)?$/);
          		$name = $series if defined $series;
        	
				$tag = $parser->get_tag('/a');
				my $next = $parser->get_trimmed_text();
				my %film = ('id' => $id, 'title' => $name);
				if(defined $t) {
					$film{'series_title'} = $t;
					$film{'season'} = $s;
					$film{'episode'} = $e;
				}

				$film{'year'} = $1 if $next =~ /\((\d{4})\)/;				
				next if ($next =~ /\(VG\)/);
				push @{$result{$group}}, \%film;
      		} else {
        		# Stop when we hit the divider
        		last;
      		}
    	}
    	
		$self->{_connections} = \%result;
  	}

  	return $self->{_connections};
}


=item full_companies()

Retrieve companies for the movie as an array where each item has following stucture:

	{ 
		production 		=> [ { name => <company name>, url => <imdb url>, extra => <specific task> } ],
  		distributors  	=> [ { name => <company name>, url => <imdb url>, extra => <specific task> } ],
 	 	special_effects => [ { name => <company name>, url => <imdb url>, extra => <specific task> } ],
  		other 			=> [ { name => <company name>, url => <imdb url>, extra => <specific task> } ],
	}

  my %full_companies = %{ $film->full_companies() };

=cut

sub full_companies {
  	my CLASS_NAME $self = shift;

  	unless($self->{_full_companies}) {
    	my $page;
    	$page = $self->_cacheObj->get($self->code . '_full_companies') if $self->_cache;

    	unless($page) {
      		my $url = "http://". $self->{host} . "/" . $self->{query} .  $self->code . "/companycredits";
      		$self->_show_message("URL for company credits is $url ...", 'DEBUG');

      		$page = $self->_get_page_from_internet($url);
      		$self->_cacheObj->set($self->code.'_full_companies', $page, $self->_cache_exp) if $self->_cache;
    	}

   	 	my $parser = $self->_parser(FORCED, \$page);
    	my $group = undef;
    	my %result;
    	my @lookFor = ('h2');
    	while (my $tag = $parser->get_tag(@lookFor)) {
      		if ($tag->[0] eq 'h2') {
        		$group = $parser->get_text;
        		$group =~ s/ compan(y|ies)//i;
        		$group =~ tr/A-Z/a-z/;
        		$group =~ s/\s+/_/g;
        		$result{$group} = [];
        		@lookFor = ('h2', 'a', 'hr', 'hr/');
      		} elsif($tag->[0] eq 'a') {
        	
			my($url) = $tag->[1]->{href};
			my $name = $parser->get_trimmed_text;

				$tag = $parser->get_tag('/a');
				my $next = $parser->get_trimmed_text();
				$next =~ s/^[\t \xA0]+//; # nbsp comes out as \xA0
				my %company = ( 'url' => $url,
								'name' => $name,
								'extra' => $next );
				push @{$result{$group}}, \%company;
			} else {
				# Stop when we hit the divider
				last;
			}
    	}
    
		$self->{_full_companies} = \%result;
  	}

  	return $self->{_full_companies};
}

=item company()

Returns a list of companies given for a specified movie:

  my $company = $film->company();

or  

 my @companies = $film->company();

=cut

sub company {
  	my CLASS_NAME $self = shift;
	
	unless($self->{_company}) {
  		my @companies = split /\s?\,\s?/, $self->_get_simple_prop('Production Co');
		$self->{_company} = \@companies;
	}	
  	
	return wantarray ? $self->{_company} : $self->{_company}[0];
}

=item episodes()

Retrieve episodes info list each element of which is hash reference for tv series -
{ id => <ID>, title => <Title>, season => <Season>, episode => <Episode>, date => <Date>, plot => <Plot> }:

	my @episodes = @{ $film->episodes() };

=cut

sub episodes {
	my CLASS_NAME $self = shift;

	return [] if !$self->kind or $self->kind !~ /tv serie/i;

	unless($self->{_episodes}) {
		my $page;
		$page = $self->_cacheObj->get($self->code . '_episodes') if $self->_cache;

		unless($page) {
			my $url = "http://". $self->{host} . "/" . $self->{query} .  $self->code . "/epcast";
			$self->_show_message("URL for episodes is $url ...", 'DEBUG');

			$page = $self->_get_page_from_internet($url);
			$self->_cacheObj->set($self->code.'_episodes', $page, $self->_cache_exp) if $self->_cache;
		}

		my $parser = $self->_parser(FORCED, \$page);
		while(my $tag = $parser->get_tag('h4')) {
			my $id;
            my($season, $episode);
            next unless(($season, $episode) = $parser->get_text =~ /Season\s+(.*?),\s+Episode\s+([^:]+)/); 
			my $imdb_tag = $parser->get_tag('a');
			($id) = $imdb_tag->[1]->{href} =~ /(\d+)/ if $imdb_tag->[1]->{href};
			my $title = $parser->get_trimmed_text;
			$parser->get_tag('b');
			my($date) = $parser->get_trimmed_text;
			$parser->get_tag('br');
			my $plot = $parser->get_trimmed_text;
			
			push @{ $self->{_episodes} }, { 	
								season 	=> $season, 
								episode => $episode, 
								id 		=> $id,
								title 	=> $title,
								date 	=> $date,
								plot 	=> $plot
							};
		}
	}

	return $self->{_episodes};
}

=item episodeof()

Retrieve parent tv series list each element of which is hash reference for episode -
{ id => <ID>, title => <Title>, year => <Year> }:

	my @tvseries = @{ $film->episodeof() };

=cut

sub episodeof {
   my CLASS_NAME $self = shift;
   my $forced = shift || 0;

   return if !$self->kind or $self->kind ne "episode";

   if($forced) {
	   my($episodeof, $title, $year, $episode, $season, $id);
	   my($parser) = $self->_parser(FORCED);

	   while($parser->get_tag(MAIN_TAG)) {
		   last if $parser->get_text =~ /^TV Series/i;
	   }

	   while(my $tag = $parser->get_tag('a')) {
		   ($title, $year) = ($1, $2) if $parser->get_text =~ m!(.*?)\s+\(([\d\?]{4}).*?\)!;
		   last unless $tag->[1]{href} =~ /title/i;
		   ($id) = $tag->[1]{href} =~ /(\d+)/;
	   }

	   #start again
	   $parser = $self->_parser(FORCED);
	   while($parser->get_tag(MAIN_TAG)) {
		   last if $parser->get_text =~ /^Original Air Date/i;
	   }
	   
	   $parser->get_token;	   
	   ($season, $episode) = $parser->get_text =~ /\(Season\s+(\d+),\s+Episode\s+(\d+)/;

	   push @{ $self->{_episodeof} }, {title => $title, year => $year, id => $id, season => $season, episode => $episode};
   }

   return $self->{_episodeof};
}

=item cover()

Retrieve url of film cover:

	my $cover = $film->cover();

=cut

sub cover {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;

	if($forced) {
		my $parser = $self->_parser(FORCED);
		my $cover;

		my $title = quotemeta($self->title);
		while(my $img_tag = $parser->get_tag('img')) {
			$img_tag->[1]{alt} ||= '';	
		
			last if $img_tag->[1]{alt} =~ /^poster not submitted/i;			

			if($img_tag->[1]{alt} =~ /Poster$/) {
				$cover = $img_tag->[1]{src};
				last;
			}
		}
		$self->{_cover} = $cover;
	}	

	return $self->{_cover};
}	

sub top_info {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;
	if($forced or !$self->{'_top_info'}) {
		my $parser = $self->_parser(FORCED);
		while(my $tag = $parser->get_tag('div')) {
			last if $tag->[1]->{class} && $tag->[1]->{class} eq 'article highlighted';
		}
		my $text = $parser->get_trimmed_text('span');
		my @top_items = split /\s?\|\s?/, $text;
		$self->{_top_info} = \@top_items;
	}
	return $self->{_top_info};
}

=item recommendation_movies()

Return a list of recommended movies for specified one as a hash where each key is a movie ID in IMDB and
value - movie's title:

	$recommendation_movies = $film->recommendation_movies();

For example, the list of recommended movies for Troy will be similar to that:

	__DATA__
	$VAR1 = {                                                                                                                                 
          '0416449' => '300',                                                                                                             
          '0167260' => 'The Lord of the Rings: The Return of the King',                                                                   
          '0442933' => 'Beowulf',                                                                                                         
          '0320661' => 'Kingdom of Heaven',                                                                                               
          '0172495' => 'Gladiator'                                                                                                        
        };   

=cut

sub recommendation_movies {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;

	if($forced) {
		my $parser = $self->_parser(FORCED);

		while(my $tag = $parser->get_tag('h2')) {
			my $text = $parser->get_text();
			last if $text =~ /recommendations/i;
		}
		
		my %result = ();
		while(my $tag = $parser->get_tag()) {
			last if $tag->[0] eq '/table';
			
			my $text = $parser->get_text();
			if($tag->[0] eq 'a' && $text && $tag->[1]{href} =~ /tt(\d+)/) {
				$result{$1} = $text;
			}
		}
		
		$self->{_recommendation_movies} = \%result;
	}

	return $self->{_recommendation_movies};
}

=item directors()

Retrieve film directors list each element of which is hash reference -
{ id => <ID>, name => <Name> }:

	my @directors = @{ $film->directors() };

=cut

sub directors {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;

	if($forced) {
		my ($parser) = $self->_parser(FORCED);
		my (@directors, $tag);
	
		while($tag = $parser->get_tag(MAIN_TAG)) {
			my $text = $parser->get_text;
			last if $text =~ /direct(?:ed|or)/i;
		}
		
		while ($tag = $parser->get_tag() ) {
			my $text = $parser->get_text();
			
			last if $text =~ /^writ(?:ing|ers)/i or $tag->[0] eq '/div';
			
			if($tag->[0] eq 'a' && $tag->[1]{href} && $text !~ /(img|more)/i) {
				my($id) = $tag->[1]{href} =~ /(\d+)/;	
				push @directors, {id => $id, name => $text};
			}			
		}
		
		$self->{_directors} = \@directors;		
	}	

	return $self->{_directors};
}

=item writers()

Retrieve film writers list each element of which is hash reference -
{ id => <ID>, name => <Name> }:

	my @writers = @{ $film->writers() };

<I>Note: this method returns Writing credits from movie main page. It maybe not 
contain a full list!</I>	

=cut

sub writers {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;

	if($forced) {
		my ($parser) = $self->_parser(FORCED);
		my (@writers, $tag);
		
		while($tag = $parser->get_tag(MAIN_TAG)) {
			last if $parser->get_text =~ /writ(?:ing|ers|er)/i;
		}
			
		while($tag = $parser->get_tag()) {
			my $text = $parser->get_text();
			last if $tag->[0] eq '/div';
			
			if($tag->[0] eq 'a' && $tag->[1]{href} && $text !~ /more/i && $text !~ /img/i) {
				if(my($id) = $tag->[1]{href} =~ /nm(\d+)/) {
					push @writers, {id => $id, name => $text};
				}	
			}		
		}
		
		$self->{_writers} = \@writers;
	}	

	return $self->{_writers};
}

=item genres()

Retrieve film genres list:

	my @genres = @{ $film->genres() };

=cut

sub genres {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;

	if($forced) {
		my ($parser) = $self->_parser(FORCED);
		my (@genres);
		
		while(my $tag = $parser->get_tag(MAIN_TAG)) {
			last if $parser->get_text =~ /^genre/i;
		}

		while(my $tag = $parser->get_tag('a')) {
			my $genre = $parser->get_text;	
			last unless $tag->[1]{href} =~ m!/genre/!i;
			last if $genre =~ /more/i;
			push @genres, $genre;
		}	

		$self->{_genres} = \@genres;
	}	

	return $self->{_genres};
}

=item tagline()

Retrieve film tagline:

	my $tagline = $film->tagline();

=cut

sub tagline {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;

	if($forced) {
		my ($parser) = $self->_parser(FORCED);		

		while(my $tag = $parser->get_tag(MAIN_TAG)) {
			last if($parser->get_text =~ /tagline/i);
		}	
				
		$self->{_tagline} = $parser->get_trimmed_text(MAIN_TAG, 'a');
	}	

	return $self->{_tagline};
}

=item plot()

Returns a movie plot:

	my $plot = $film->plot;

=cut

sub plot {
	my CLASS_NAME $self = shift;

	return $self->{_plot};
}

=item storyline()

Retrieve film plot summary:

	my $storyline = $film->storyline();

=cut

sub storyline {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;

	if($forced) {
		my $parser = $self->_parser(FORCED);

		while(my $tag = $parser->get_tag('h2')) {
			last if $parser->get_text =~ /^storyline$/i;
		}
 		
		my $plot = $parser->get_trimmed_text(MAIN_TAG, 'em');
		$self->{_storyline} = $self->_decode_special_symbols($plot);
	}	

	return $self->{_storyline};
}

=item rating()

In scalar context returns film user rating, in array context returns 
film rating, number of votes and info about place in TOP 250 or some other TOP and avards:

	my $rating = $film->rating();

	or

	my($rating, $vnum, $avards) = $film->rating();
	print "RATING: $rating ($vnum votes)";

Note, that $avards is array reference where the first elemen is a TOP info if so, and the next element is other avards - Oscar, nominations and etc	

=cut

sub rating {
	my CLASS_NAME $self = shift;
	my ($forced) = shift || 0;

	if($forced) {
		my $parser = $self->_parser(FORCED);
	
		while(my $tag = $parser->get_tag('div')) {
			last if $tag->[1]{class} && $tag->[1]{class} eq 'star-box-details';
		}
		
		my $text = $parser->get_trimmed_text('/a');

		my($rating, $val) = $text =~ m!(\d+\.?\d*)/10.*?(\d+,?\d*)!;
		$val =~ s/\,// if $val;
		
		$self->{_rating} = [$rating, $val, $self->top_info];
		
		unless($self->{_plot}) {
			my $tag = $parser->get_tag('p');
			my $text = $parser->get_trimmed_text('/p');
			$self->{_plot} = $text;
		}
	}

	return wantarray ? @{ $self->{_rating} } : $self->{_rating}[0];
}

=item cast()

Retrieve film cast list each element of which is hash reference -
{ id => <ID>, name => <Full Name>, role => <Role> }:

	my @cast = @{ $film->cast() };

<I>
Note: this method retrieves a cast list first billed only!
</I>

=cut

sub cast {
	my CLASS_NAME $self = shift;
	my ($forced) = shift || 0;

	if($forced) {
		my (@cast, $tag, $person, $id, $role);
		my $parser = $self->_parser(FORCED);
	
		while($tag = $parser->get_tag('table')) {
			last if $tag->[1]->{class} && $tag->[1]->{class} =~ /^cast_list$/i;
		}
		while($tag = $parser->get_tag()) {
			last if $tag->[0] eq 'a' && $tag->[1]{href} && $tag->[1]{href} =~ /fullcredits/i;
			if($tag->[0] eq 'td' && $tag->[1]{class} && $tag->[1]{class} eq 'name') {
				$tag = $parser->get_tag('a');
				if($tag->[1]{href} && $tag->[1]{href} =~ m#name/nm(\d+?)/#) {
					$person = $parser->get_text;
					$id = $1;	
					my $text = $parser->get_trimmed_text('/tr');
					($role) = $text =~ /.*?\s+(.*)$/;
					push @cast, {id => $id, name => $person, role => $role};
				}
			}
		}	
		
		$self->{_cast} = \@cast;
	}

	return $self->{_cast};
}

=item duration()

In the scalar context it retrieves a film duration in minutes (the first record):

	my $duration = $film->duration();

In array context it retrieves all movie's durations:

	my @durations = $film->duration();

=cut

sub duration {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;
	
	if($forced) {

		my $parser = $self->_parser(FORCED);
		while(my $tag = $parser->get_tag(MAIN_TAG)) {
			my $text = $parser->get_text();
			last if $text =~ /runtime:/i;
		}	
		my $duration_str = $self->_decode_special_symbols($parser->get_trimmed_text(MAIN_TAG, '/div'));
		my @runtime = split /\s+(\/|\|)\s+/, $duration_str;
		
		$self->{_duration} = \@runtime;		
	}

	return wantarray ? @{ $self->{_duration} } : $self->{_duration}->[0];
}

=item country()

Retrieve film produced countries list:

	my $countries = $film->country();

=cut

sub country {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;
	
	if($forced) {
		my $parser = $self->_parser(FORCED);
		while (my $tag = $parser->get_tag(MAIN_TAG)) {
			last if $parser->get_text =~ /country/i;
		}	

		my (@countries);
		while(my $tag = $parser->get_tag()) {

			if( $tag->[0] eq 'a' && $tag->[1]{href} && $tag->[1]{href} =~ m!/country/[a-z]{2}!i ) {
				my $text = $parser->get_text();
				$text =~ s/\n//g;
				push @countries, $text;
			} 
			
			last if $tag->[0] eq 'br';
		}

		$self->{_country} = \@countries; 
	}
	
	return $self->{_country}
}

=item language()

Retrieve film languages list:

	my $languages = $film->language();

=cut

sub language {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;
	
	if($forced) {
		my (@languages, $tag);
		my $parser = $self->_parser(FORCED);
		while ($tag = $parser->get_tag(MAIN_TAG)) {
			last if $parser->get_text =~ /language/i;
		}	
		
		while($tag = $parser->get_tag()) {
			if( $tag->[0] eq 'a' && $tag->[1]{href} && $tag->[1]{href} =~ m!/language/[a-z]{2}!i ) {
				my $text = $parser->get_text();
				$text =~ s/\n//g;
				push @languages, $text;
			} 
			
			last if $tag->[0] eq '/div';
		}

		$self->{_language} = \@languages; 
	}
	
	return $self->{_language};

}

=item also_known_as()

Retrieve AKA information as array, each element of which is string:

	my $aka = $film->also_known_as();

	print map { "$_\n" } @$aka;

=cut

sub also_known_as {
	my CLASS_NAME $self= shift;
	unless($self->{_also_known_as}) {
		my $parser = $self->_parser(FORCED);

        while(my $tag = $parser->get_tag(MAIN_TAG)) {
        	my $text = $parser->get_text();
			$self->_show_message("AKA: $text", 'DEBUG');
            last if $text =~ /^(aka|also known as)/i;
        }

		my $aka = $parser->get_trimmed_text('span');
		
		$self->_show_message("AKA: $aka", 'DEBUG');
		my @aka = ($aka);
		$self->{_also_known_as} = \@aka;
	}	
	
	return $self->{_also_known_as};
}

=item trivia()

Retrieve a movie trivia:

	my $trivia = $film->trivia();

=cut

sub trivia {
	my CLASS_NAME $self = shift;

	$self->{_trivia} = $self->_get_simple_prop('trivia') unless $self->{_trivia};
	return $self->{_trivia};
}

=item goofs()

Retrieve a movie goofs:

	my $goofs = $film->goofs();

=cut

sub goofs {
	my CLASS_NAME $self = shift;

	$self->{_goofs} = $self->_get_simple_prop('goofs') unless($self->{_goofs});
	return $self->{_goofs};
}

=item awards()

Retrieve a general information about movie awards like 1 win & 1 nomination:

	my $awards = $film->awards();

=cut	

sub awards {
	my CLASS_NAME $self = shift;

	return $self->{_top_info};
}

=item mpaa_info()

Return a MPAA for the specified move:

	my mpaa = $film->mpaa_info();

=cut

sub mpaa_info {
	my CLASS_NAME $self = shift;
	unless($self->{_mpaa_info}) {
	
		my $parser = $self->_parser(FORCED);

        while(my $tag = $parser->get_tag(MAIN_TAG)) {
        	my $text = $parser->get_trimmed_text(MAIN_TAG, '/a');
            last if $text =~ /^Motion Picture Rating/i;
        }

		my $mpaa = $parser->get_trimmed_text('/span');
		$mpaa =~ s/^\)\s//;
		$self->{_mpaa_info} = $mpaa;
	}

	return $self->{_mpaa_info};
}

=item aspect_ratio()

Returns an aspect ratio of specified movie:

	my $aspect_ratio = $film->aspect_ratio();

=cut

sub aspect_ratio {
	my CLASS_NAME $self = shift;

	$self->{_aspect_ratio} = $self->_get_simple_prop('aspect ratio') unless $self->{_aspect_ratio};

	return $self->{_aspect_ratio};
}

=item summary()

Retrieve film user summary:

	my $descr = $film->summary();

=cut

sub summary {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;
		
	if($forced) {
		my($tag, $text);
		my($parser) = $self->_parser(FORCED);

		while($tag = $parser->get_tag('b')) {
			$text = $parser->get_text();
			last if $text =~ /^summary/i;
		}	

		$text = $parser->get_text('b', 'a');
		$self->{_summary} = $text;
	}	
	
	return $self->{_summary};
}

=item certifications()

Retrieve list of film certifications each element of which is hash reference -
{ country => certificate }:

	my @cert = $film->certifications();

=cut

sub certifications {
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;
	my (%cert_list, $tag);

	if($forced) {
		my $parser = $self->_parser(FORCED);
		while($tag = $parser->get_tag(MAIN_TAG)) {
			last if $parser->get_text =~ /certification/i;
		}

		while($tag = $parser->get_tag()) {
			
			if($tag->[0] eq 'a' && $tag->[1]{href} && $tag->[1]{href} =~ /certificates/i) {
				my $text = $parser->get_text();
				$text =~ s/\n//g;
				my($country, $range) = split /\:/, $text;
				$cert_list{$country} = $range;
			}

			last if $tag->[0] eq '/td';
		}

		$self->{_certifications} = \%cert_list;
	}

	return $self->{_certifications};
}

=item full_plot

Return full movie plot. 

	my $full_plot = $film->full_plot();

=cut

sub full_plot {
	my CLASS_NAME $self = shift;

	$self->_show_message("Getting full plot ".$self->code."; url=".$self->full_plot_url." ...", 'DEBUG');
	#
	# TODO: move all methods which needed additional connection to the IMDB.com
	#		to the separate module.
	#
	unless($self->{_full_plot}) {
		my $page;		
		$page = $self->_cacheObj->get($self->code.'_plot') if $self->_cache;
		unless($page) {		
			my $url = $self->full_plot_url . $self->code() . '/plotsummary';

			$self->_show_message("URL is $url ...", 'DEBUG');
		
			$page = $self->_get_page_from_internet($url);
			unless($page) {
				return;
			}
			
			$self->_cacheObj->set($self->code.'_plot', $page, $self->_cache_exp) if $self->_cache;
		}	

		my $parser = $self->_parser(FORCED, \$page);
		
		my($text);
		while(my $tag = $parser->get_tag('p')) {
			if(defined $tag->[1]{class} && $tag->[1]{class} =~ /plotpar/i) {
				$text = $parser->get_trimmed_text();
				last;
			}
		}
			
		$self->{_full_plot} = $text;			
	}

	return $self->{_full_plot};
}

sub big_cover {
	my CLASS_NAME $self = shift;

	unless($self->{'_big_cover_url'}) {
		unless($self->{'_big_cover_page'}) {
			my $parser = $self->_parser(FORCED);
			my $regexp = '^/media/.+/tt' . $self->code . '$';
			while(my $tag = $parser->get_tag('a')) {
				$self->_show_message("$regexp --> " . $tag->[1]->{href}, 'DEBUG');
				if($tag->[1]->{'href'} =~ m!$regexp!) {	
					$self->{'_big_cover_page'} = $tag->[1]->{'href'};
					last;
				}
			}
		}
		if($self->{'_big_cover_page'}) {
			my $page = $self->_get_page_from_internet('http://' . $self->{'host'} . $self->{'_big_cover_page'});
			return unless $page;

			my $parser = $self->_parser(FORCED, \$page);
			while(my $tag = $parser->get_tag('img')) {
				if($tag->[1]->{'id'} && $tag->[1]->{'id'} eq 'primary-img') {
					$self->{'_big_cover_url'} = $tag->[1]->{'src'};
					last;
				}
			}
		}
	}

	return $self->{_big_cover_url};
}

=item official_sites()

Returns a list of official sites of specified movie as array reference which contains hashes
with site information - URL => Site Title:

	my $sites = $film->official_sites();
	for(@$sites) {
		print "Site name - $_->{title}; url - $_->{url}\n";
	}

=cut

sub official_sites {
	my CLASS_NAME $self = shift;

	unless($self->{_official_sites}) {
		my $page;
		$page = $self->_cacheObj->get($self->code . '_sites') if $self->_cache;

		unless($page) {
			my $url = "http://". $self->{host} . "/" . $self->{query} . $self->code . "/officialsites";
			$self->_show_message("URL for sites is $url ...", 'DEBUG');

			$page = $self->_get_page_from_internet($url);
			
			$self->_cacheObj->set($self->code.'_sites', $page, $self->_cache_exp) if $self->_cache;
		}
	

		my $parser = $self->_parser(FORCED, \$page);
		while(my $tag = $parser->get_tag()) {
			last if $tag->[0] eq 'ol';
		}

		while(my $tag = $parser->get_tag()) {
			my $text = $parser->get_text();
			if($tag->[0] eq 'a' && $tag->[1]->{href} !~ /sections/i) {
				push @{ $self->{_official_sites} }, { $tag->[1]->{href} => $text };
			}	

			last if $tag->[0] eq '/ol' or $tag->[0] eq 'hr';
		}
	}	

	return $self->{_official_sites};
}

=item release_dates()

Returns a list of release dates of specified movie as array reference:

	my $sites = $film->release_dates();
	for(@$sites) {
		print "Country - $_->{country}; release date - $_->{date}; info - $_->{info}\n";
	}

Option info contains additional information about release - DVD premiere, re-release, restored version etc	

=cut

sub release_dates {
	my CLASS_NAME $self = shift;

	unless($self->{_release_dates}) {
		my $page;
		$page = $self->_cacheObj->get($self->code . '_dates') if $self->_cache;

		unless($page) {
			my $url = "http://". $self->{host} . "/" . $self->{query} .  $self->code . "/releaseinfo";
			$self->_show_message("URL for sites is $url ...", 'DEBUG');

			$page = $self->_get_page_from_internet($url);
			$self->_cacheObj->set($self->code.'_dates', $page, $self->_cache_exp) if $self->_cache;
		}

		my $parser = $self->_parser(FORCED, \$page);
		# Searching header of release dates table
		while(my $tag = $parser->get_tag('th')) {
			last if $tag->[1]->{class} && $tag->[1]->{class} eq 'xxxx';
		}
		
		#
		# The table has three columns. So we parse then one by one and grab their text
		#
		my $count = 0;
		my @dates = ();
		while(my $tag = $parser->get_tag()) {
			last if $tag->[0] eq '/table';			
			next unless $tag->[0] eq 'td';

			$dates[$count] = $parser->get_trimmed_text('/td');
			
			# When rish 3rd column we should store dates into object property
			if(++$count > 2) {
				$dates[2] =~ s/\)\s\(/, /g;
				$dates[2] =~ s/(\(|\))//g;
				push @{ $self->{_release_dates} }, {country => $dates[0], date => $dates[1], info => $dates[2]};
				$count = 0;
			}	
		}
	}

	return $self->{_release_dates};
}
=item 

Retrieve a list of plot keywords as an array reference:

	my $plot_keywords = $film->plot_keywords();
	for my $keyword (@$plot_keywords) {
		print "keyword: $keyword\n";
	}

=cut

sub plot_keywords {
	my CLASS_NAME $self = shift;
	
	unless($self->{_plot_keywords}) {
		my $page;
		$page = $self->_cacheObj->get($self->code . '_keywords') if $self->_cache;

		unless($page) {
			my $url = "http://". $self->{host} . "/" . $self->{query} .  $self->code . "/keywords";
			$self->_show_message("URL for sites is $url ...", 'DEBUG');

			$page = $self->_get_page_from_internet($url);
			$self->_cacheObj->set($self->code.'_keywords', $page, $self->_cache_exp) if $self->_cache;
		}

		my $parser = $self->_parser(FORCED, \$page);
		
		my @keywords = ();
		while(my $tag = $parser->get_tag('a')) {
			my $text = $parser->get_text(); 
			$text = $self->_decode_special_symbols($text);
			#$self->_show_message("*** $tag->[1]->{href} --> $text ***", 'DEBUG');
			push @keywords, $text if $tag->[1]->{href} && $tag->[1]->{href} =~ m#/keyword/#;
		}

		$self->{_plot_keywords} = \@keywords;
	}

	return $self->{_plot_keywords};
}

=back

=cut

sub DESTROY {
	my CLASS_NAME $self = shift;
}

1;

__END__

=head2 Class Variables

=over 4

=item %FIELDS

Contains list all object's properties. See description of pragma C<fields>.

=item @FILM_CERT

Matches USA film certification notation and age.

=back

=head1 EXPORTS

Nothing

=head1 HOWTO CACTH EXCEPTIONS

If it's needed to get information from IMDB for a list of movies in some case it can be returned
critical error:

	[CRITICAL] Cannot retrieve page: 500 Can't read entity body ...

To catch an exception can be used eval:

	for my $search_crit ("search_crit1", "search_crit2", ..., "search_critN") {
    	my $ret;
    	eval {
        	$ret = new IMDB::Film(crit => "$search_crit") || print "UNKNOWN ERROR\n";
    	};

    	if($@) {
        	# Opsssss! We got an exception!
        	print "EXCEPTION: $@!";
        	next;
    	}
	}

=head1 BUGS

Please, send me any found bugs by email: stepanov.michael@gmail.com or create 
a bug report: http://rt.cpan.org/NoAuth/Bugs.html?Dist=IMDB-Film

=head1 SEE ALSO

IMDB::Persons 
IMDB::BaseClass
WWW::Yahoo::Movies
IMDB::Movie
HTML::TokeParser 

http://videoguide.sf.net

=head1 AUTHOR

Michael Stepanov AKA nite_man (stepanov.michael@gmail.com)

=head1 COPYRIGHT

Copyright (c) 2004 - 2007, Michael Stepanov.
This module is free software. It may be used, redistributed and/or 
modified under the same terms as Perl itself.

=cut
