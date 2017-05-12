=head1 NAME

IMDB::BaseClass - a base class for IMDB::Film and IMDB::Persons.

=head1 SYNOPSIS

  use base qw(IMDB::BaseClass);

=head1 DESCRIPTION

IMDB::BaseClass implements a base functionality for IMDB::Film
and IMDB::Persons.

=cut

package IMDB::BaseClass;

use strict;
use warnings;

use HTML::TokeParser;
use LWP::Simple qw($ua get);
use Cache::FileCache;
use Text::Unidecode qw(unidecode);
use HTML::Entities;
use Carp;

use Data::Dumper;

use constant MAIN_TAG	=> 'h4';
use constant ID_LENGTH	=> 6;

use vars qw($VERSION %FIELDS $AUTOLOAD %STATUS_DESCR);

BEGIN {
	$VERSION = '0.53';

	%STATUS_DESCR = (
		0 => 'Empty',
		1 => 'Filed',
		2 => 'Fresh',
		3 => 'Cached',
	);	
}

use constant FORCED 		=> 1;
use constant CLASS_NAME 	=> 'IMDB::BaseClass';

use constant FROM_FILE		=> 1;
use constant FROM_INTERNET	=> 2;
use constant FROM_CACHE		=> 3;

use fields qw(	content
				parser
				matched
				proxy
				error
				cache
				host
				query
				search
				cacheObj
				cache_exp
				cache_root
				clear_cache
				debug
				status
				file
				timeout
				user_agent
				decode_html
				exact
				_code
	);

=head2 Constructor and initialization

=over 4

=item new()

Object's constructor. You should pass as parameter movie title or IMDB code.

	my $imdb = new IMDB::Film(crit => <some code>);

or	

	my $imdb = new IMDB::Film(crit => <some title>);

Also, you can specify following optional parameters:

	- proxy - define proxy server name and port;
	- debug	- switch on debug mode (on by default);
	- cache - cache or not of content retrieved pages.

=cut

sub new {
	my $caller = shift;
	my $class = ref($caller) || $caller;
	my $self = fields::new($class);
	$self->_init(@_);
	return $self;
}

=item _init()

Initialize object. It gets list of service class properties and assign value to them from input
parameters or from the hash with default values.

=cut

sub _init {
	my CLASS_NAME $self = shift;
	my %args = @_;

	no warnings 'deprecated';

	for my $prop ( keys %{ $self->fields } ) {		
		unless($prop =~ /^_/) {
			$self->{$prop} = defined $args{$prop} ? $args{$prop} : $self->_get_default_value($prop);	
		}	
	}
	
	if($self->_cache()) {
		$self->_cacheObj( new Cache::FileCache( { 	default_expires_in 	=> $self->_cache_exp, 
													cache_root 			=> $self->_cache_root } ) );

		$self->_cacheObj->clear() if $self->_clear_cache;											
	}												
	
	if($self->_proxy) { $ua->proxy(['http', 'ftp'], $self->_proxy()) }
	else { $ua->env_proxy() }

	$ua->timeout($self->timeout);
	$ua->agent($self->user_agent);

	$self->_content( $args{crit} );
	$self->_parser();
}

=item user_agent()

Define an user agent for HTTP request. It's 'Mozilla/5.0' by default.
For more information refer to LWP::UserAgent.

=cut

sub user_agent {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{user_agent} = shift }
	return $self->{user_agent}
}

=item timeout()

Define a timeout for HTTP request in seconds. By default it's 10 sec.
For more information refer to LWP::UserAgent.

=cut

sub timeout {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{timeout} = shift }
	return $self->{timeout}
}

=item code()

Get IMDB film code.

	my $code = $film->code();

=cut

sub code {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{_code} = shift }
	return $self->{_code};
}

=item id()

Get IMDB film id (actually, it's the same as code).

	my $id = $film->id();

=cut

sub id {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{_code} = shift }
	return $self->{_code};
}

=item _proxy()

Store address of proxy server. You can pass a proxy name as parameter into
object constructor:

	my $imdb = new IMDB::Film(code => 111111, proxy => 'my.proxy.host:8080');

or you can define environment variable 'http_host'. For exanple, for Linux
you shoud do a following:

	export http_proxy=my.proxy.host:8080

=cut

sub _proxy {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{proxy} = shift }
	return $self->{proxy};
}

sub _decode_html {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{decode_html} = shift }
	return $self->{decode_html};
}	

=item _cache()

Store cache flag. Indicate use file cache to store content page or not:

	my $imdb = new IMDB::Film(code => 111111, cache => 1);

=cut

sub _cache {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{cache} = shift }
	return $self->{cache}
}

=item _clear_cache

Store flag clear_cache which is indicated clear exisisting cache or not (false by default):

	my $imdb = new IMDB::Film(code => 111111, cache => 1, clear_cache => 1);

=cut

sub _clear_cache {
	my CLASS_NAME $self = shift;
	if($_) { $self->{clear_cache} = shift }
	return $self->{clear_cache};
}

=item _cacheObj()

In case of using cache, we create new Cache::File object and store it in object's
propery. For more details about Cache::File please see Cache::Cache documentation.

=cut

sub _cacheObj {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{cacheObj} = shift }
	return $self->{cacheObj}
}

=item _cache_exp()

In case of using cache, we can define value time of cache expire.

	my $imdb = new IMDB::Film(code => 111111, cache_exp => '1 h');

For more details please see Cache::Cache documentation.

=cut

sub _cache_exp {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{cache_exp} = shift }
	return $self->{cache_exp}
}

sub _cache_root {
	my CLASS_NAME $self = shift;
	$self->{cache_root} = shift if @_;

	$self->_show_message("CACHE ROOT is " . $self->{cache_root}, 'DEBUG');
	
	return $self->{cache_root};
}

sub _show_message {
	my CLASS_NAME $self = shift;
	my $msg = shift || 'Unknown error';
	my $type = shift || 'ERROR';

	return if $type =~ /^debug$/i && !$self->_debug();
	
	if($type =~ /(debug|info|warn)/i) { carp "[$type] $msg" } 
	else { croak "[$type] $msg" }
}

=item _host()

Store IMDB host name. You can pass this value in object constructor:

	my $imdb = new IMDB::Film(code => 111111, host => 'us.imdb.com');

By default, it uses 'www.imdb.com'.

=cut

sub _host {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{host} = shift }
	return $self->{host}
}

=item _query()

Store query string to retrieve film by its ID. You can define
different value for that:

	my $imdb = new IMDB::Film(code => 111111, query => 'some significant string');

Default value is 'title/tt'.

B<Note: this is a mainly service parameter. So, there is no reason to pass it in the
real case.>

=cut

sub _query {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{query} = shift }
	return $self->{query}
}

=item _search()

Store search string to find film by its title. You can define
different value for that:

	my $imdb = new IMDB::Film(code => 111111, seach => 'some significant string');

Default value is 'Find?select=Titles&for='.

=cut	

sub _search {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{search} = shift }
	return $self->{search}
}

sub _exact {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{exact} = shift }
	return $self->{exact};
}

=item _debug()

Indicate to use DEBUG mode to display some debug messages:

	my $imdb = new IMDB::Film(code => 111111, debug => 1);

By default debug mode is switched off.	

=cut

sub _debug {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{debug} = shift }
	return $self->{debug}
}

=item _content()

Connect to the IMDB, retrieve page according to crit: by film
IMDB ID or its title and store content of that page in the object
property. 
In case using cache, first check if page was already stored in the
cache then retrieve page from the cache else store content of the 
page in the cache.

=cut

sub _content {
	my CLASS_NAME $self = shift;
	if(@_) {
		my $crit = shift || '';
		my $page;
	
		$self->code($crit) if $crit =~ /^\d{6,8}$/;
		$page = $self->_cacheObj()->get($crit) if $self->_cache();
		
		$self->_show_message("CRIT: $crit", 'DEBUG');
		
		unless($page) {			
			if( -f $crit ) {
				$self->_show_message("Parse IMDB HTML file ...", 'DEBUG');
				
				local $/;
				undef $/;
				open FILE, $crit or die "Cannot open off-line IMDB file: $!!";
				$page = <FILE>;
				close FILE;
				$self->status(FROM_FILE);
			} else {
				$self->_show_message("Retrieving page from internet ...", 'DEBUG');
					
				my $url = 'http://'.$self->_host().'/'.
						($crit =~ /^\d+$/ && length($crit) >= ID_LENGTH ? $self->_query() : $self->_search()) . $crit;				
				
				$page = $self->_get_page_from_internet($url);
				$self->status(FROM_INTERNET);
			}
			
			$self->_cacheObj()->set($crit, $page, $self->_cache_exp()) if $self->_cache();
		} else {
			$self->_show_message("Retrieving page from cache ...", 'DEBUG');
			$self->status(FROM_CACHE);
		}
		
		$self->{content} = \$page;
	}

	$self->{content};
}

sub _get_page_from_internet {
	my CLASS_NAME $self = shift;
	my $url = shift;
	
	$self->_show_message("URL is [$url]...", 'DEBUG');

	my $page = get($url);

	unless($page) {
		$self->error("Cannot retieve an url: [$url]!");				
		$self->_show_message("Cannot retrieve url [$url]", 'CRITICAL');				
	}
	
	return $page;
}

=item _parser()

Setup HTML::TokeParser and store. To have possibility to inherite that class
we should every time initialize parser using stored content of page.
For more information please see HTML::TokeParser documentation.

=cut

sub _parser {	
	my CLASS_NAME $self = shift;
	my $forced = shift || 0;
	my $page = shift || undef;

	if($forced) {
		my $content = defined $page ? $page : $self->_content();

		my $parser = new HTML::TokeParser($content) or croak "[CRITICAL] Cannot create HTML parser: $!!";
		$self->{parser} = $parser;
	}
	
	return $self->{parser};
}

=item _get_simple_prop()

Retrieve a simple movie property which surrownded by <B>.

=cut

sub _get_simple_prop {
	my CLASS_NAME $self = shift;
	my $target = shift || '';
	
	my $parser = $self->_parser(FORCED);

	while(my $tag = $parser->get_tag(MAIN_TAG)) {
		my $text = $parser->get_text;

		$self->_show_message("[$tag->[0]] $text --> $target", 'DEBUG');
		last if $text =~ /$target/i;
	}

	my $end_tag = '/a';
	$end_tag = '/div' if $target eq 'trivia';
	$end_tag = 'span' if $target eq 'Production Co';
	$end_tag = '/div' if $target eq 'aspect ratio';
	
	my $res = $parser->get_trimmed_text($end_tag);	

	$res =~ s/\s+(see )?more$//i;

	$self->_show_message("RES: $res", 'DEBUG');
	
	$res = $self->_decode_special_symbols($res);

	return $res;
}

sub _search_results {
	my CLASS_NAME $self = shift;
	my $pattern = shift || croak 'Please, specify search pattern!';
	my $end_tag = shift || '/li';
	my $year	= shift;
	
	my(@matched, @guess_res, %matched_hash);
	my $parser = $self->_parser();
	
	my $count = 0;
	while( my $tag = $parser->get_tag('a') ) {
		my $href = $tag->[1]{href};
		my $title = $parser->get_trimmed_text('a', $end_tag);
		
		$self->_show_message("TITLE: " . $title, 'DEBUG');
		next if $title =~ /\[IMG\]/i or !$href or $href =~ /pro.imdb.com/;
		
		# Remove garbage from the first title
		$title =~ s/(\n|\r)//g;
		$title =~ s/\s*\.media_strip_thumbs.*//m;

		if(my($id) = $href =~ /$pattern/) {
			$matched_hash{$id} = {title => $title, 'pos' => $count++};
			@guess_res = ($id, $title) if $year && $title =~ /$year/ && !@guess_res;
		}	
	}

	@matched = map { {title => $matched_hash{$_}->{title}, id => $_} }  
				sort { $matched_hash{$a}->{'pos'} <=> $matched_hash{$b}->{'pos'} } keys %matched_hash;
	
	$self->matched(\@matched);

	$self->_show_message("matched: " . Dumper(\@matched), 'DEBUG');
	$self->_show_message("guess: " . Dumper(\@guess_res), 'DEBUG');

	my($title, $id);
	if(@guess_res) {
		($id, $title) = @guess_res;
	} else {
		$title = $matched[0]->{title};
		$id = $matched[0]->{id};
	}

	$self->_content($id);
	$self->_parser(FORCED);

	return $title;
}

=item matched()

Retrieve list of matched films each element of which is hash reference - 
{ id => <Film ID>, title => <Film Title>:

	my @matched = @{ $film->matched() };

Note: if movie was matched by title unambiguously it won't be present in this array!	

=cut

sub matched {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{matched} = shift }
	return $self->{matched};
}

sub status {
	my CLASS_NAME $self = shift;
	if(@_) { $self->{status} = shift }
	return $self->{status};
}

sub status_descr {
	my CLASS_NAME $self = shift;
	return $STATUS_DESCR{$self->{status}} || $self->{status};	
}

sub retrieve_code {
	my CLASS_NAME $self = shift;
	my $parser = shift;
	my $pattern = shift;
	my($id, $tag);			
	
	while($tag = $parser->get_tag('link')) {
		if($tag->[1]{href} && $tag->[1]{href} =~ m!$pattern!) {
			$self->code($1);
			last;
		}	
	}	
}

=item error()

Return string which contains error messages separated by \n:

	my $errors = $film->error();

=cut

sub error {
	my CLASS_NAME $self = shift;
	if(@_) { push @{ $self->{error} }, shift() }
	return join("\n", @{ $self->{error} }) if $self->{error};
}

sub _decode_special_symbols {
	my($self, $text) = @_;
	if($self->_decode_html) {
		$text = unidecode(decode_entities($text));
	}	
	return $text;
}

sub AUTOLOAD {
 	my $self = shift;
	my($class, $method) = $AUTOLOAD =~ /(.*)::(.*)/;
	my($pack, $file, $line) = caller;

	carp "Method [$method] not found in the class [$class]!\n Called from $pack	at line $line";
}

sub DESTROY {
	my $self = shift;
}

1;

__END__

=back

=head1 EXPORTS

Nothing

=head1 BUGS

Please, send me any found bugs by email: stepanov.michael@gmail.com. 

=head1 SEE ALSO

IMDB::Persons 
IMDB::Film
WWW::Yahoo::Movies
HTML::TokeParser 

=head1 AUTHOR

Mikhail Stepanov AKA nite_man (stepanov.michael@gmail.com)

=head1 COPYRIGHT

Copyright (c) 2004 - 2007, Mikhail Stepanov.
This module is free software. It may be used, redistributed and/or 
modified under the same terms as Perl itself.

=cut
