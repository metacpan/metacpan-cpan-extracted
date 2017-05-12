# Benjamin H Kram <ben@base16consulting.com>
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

=head1 NAME

MasonX::Resolver::Polyglot - Component path resolver for easy internationalization

=head1 SYNOPSIS

In your http.conf:

    PerlInitHandler MasonX::Resolver::Polyglot
    <Directory /var/www/html>
     PerlSetVar PolyglotDefaultLang en
     PerlSetVar PolyglotDefaultURILang en
     PerlAddVar MasonDataDir "/var/www/mason"
     PerlAddVar MasonCompRoot "/var/www/html"
     <FilesMatch "^..$|\.html(\...)?$">
           SetHandler perl-script
           PerlSetVar MasonResolverClass MasonX::Resolver::Polyglot
           PerlHandler HTML::Mason::ApacheHandler
     </FilesMatch>
    </Directory>

Or, in your Mason guts:

  my $resolver = MasonX::Resolver::Polyglot->new( comp_root => '/var/www/mason' );
  my $info = $resolver->get_info('/some/comp.html');
  my $comp_root = $resolver->comp_root;

=head1 CONFIGURATION

=item C<PolyglotDefaultLang> sets the fall back language.  If unset, Polyglot will fall back on a file with no suffix (foo.html).

=item C<PolyglotDefaultURILang> overrides language selection based upon Language-Accept.  It is equivalent to prefixing the url with a language code (http://foo.com/en-us/foo.html)

=head1 DESCRIPTION

This C<HTML::Mason::Resolver::File::ApacheHandler> subclass enables Mason to determine the client's language preference and find the best matching component to fulfill it.

This allows a web designer to provide structure in language independant components, and confine language-centric HTML to other components that the top level pages use.

Components are labeled by suffix.  

Examples:
    index.html - language independant component.  Either last try component (if no other languages are acceptable) or the default language (if C<PolyglotDefaultLang> is set).
    index.html.es - Spanish component.  If a browser's Language-Accept describes Spanish as more preferable than English, requests for index.html will return this component.

There is nothing magic about the html suffix; these do not have to be top level components.  Let us suppose that index.html has a component called "menubar" which has text or image buttons of the site map.  We may write the following components:
    menubar - the English version (we have set PolyglotDefaultLang to "en")
    menubar.en-us - the American English version
    menubar.fr - the French version
    menubar.it - the Italian version

The code in index.html just calls "menubar" normally, and the resolver will pick the "right" component, ultimately falling back on the unsuffixed version if it can't find a better match.

There are really two pieces to Polyglot. The Mason resolver piece is a child of HTML::Mason::Resolver::File::ApacheHandler and compares the Language-Accept preferences a web client presents with what is available on the filesystem, and finds the best match.

The other piece is the PerlInitHandler which scans (and potentially alters) the URL for a leading language code.  The effect this has is to override all preferences.    
If, for some reason, you want to peek at the URI that actually was typed in before Polyglot ate the language code, it is stashed away in $r->pnotes('POLYGLOT_URI'). 

Like our aformentioned English/Spanish site, we have an English index.html, and a Spanish index.html.es.  My site wants to provide the ability to choose the site language without mucking with the brower's language preference.
In my index.html, I have a "Spanish" link which links to "/es/index.html", and an "English" link in my index.html.es that links to "/index.html".  I make all other links in the site _relative_.

The effect this has is to propagate the /es/ prefix, consistantly overriding the browser's language preference until the user clicks on an absolute URL.

Polyglot now makes its language decision order array available through the Apache request pnotes() interface as an array ref.
If you call:

    my @langs   = @{$r->pnotes('POLYGLOT_LANGS')};

@langs will contain a ranked list of language preference.

It makes the language decision it made available by:

    my $lang    =   $r->pnotes('POLYGLOT_LANG');

And also, the original pre-language-stripped URI available like so:

    my $origuri =   $r->pnotes('POLYGLOT_URI')

=cut

package MasonX::Resolver::Polyglot;
$VERSION = q(0.95);

use strict;

# We need this, since our parent is embedded in the HTML::Mason::ApacheHandler file
use HTML::Mason::ApacheHandler;
use base qw(HTML::Mason::Resolver::File);

use HTML::Mason::Tools qw(paths_eq);
use Locale::Language qw(code2language);
use Locale::Country  qw(LOCALE_CODE_ALPHA_2 LOCALE_CODE_ALPHA_3 code2country);
use Apache::Constants;

my $DEBUG = 0;
# This is the name of the env variable that uri_override uses
my $POLYGLOT_LANG       = q(POLYGLOT_LANG);
my $PolyglotDefaultLang = q(PolyglotDefaultLang);
my $PolyglotDefaultURILang = q(PolyglotDefaultURILang);

sub new{
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{default_lang} = lc Apache->request->dir_config($PolyglotDefaultLang);
    $self->{default_uri_lang} = lc Apache->request->dir_config($PolyglotDefaultURILang);
    return $self;
}    

sub get_info{
    my ($self, $path, $comp_root_key, $comp_root_path) = @_;
    
    # Is this already stored somewhere I can grab it?
    # I suspect this is wasteful.
    my $r = Apache->request;
    
    $DEBUG && $r->log_error(qq(URI:) . $r->uri . qq(, path: $path)); 
    $DEBUG && $r->log_error(qq(Header says: ), $r->header_in('Accept-Language'));
    # Get a ranked list of language prefs based on the Accept-Language and URI
    # everything in get_langs will need an $r
    $self->{r} = $r;
    my @langs = @{$self->get_langs(\$path)};
    $DEBUG && $r->log_error("Languages Accepted: ", join(",", @langs));
    delete $self->{r};
 
    # If we have a default language set, then "" gets spliced in 
    #  immediately after that language in the pref list.

    if($self->{default_lang}){
	for(0..$#langs){
	    if($langs[$_] eq $self->{default_lang}){
		splice(@langs, $_+1, 0, "");
	    }
	}
    }
	
    # No matter what, lastly look for the "pure" version
    push @langs, ""; # so we check a no extension lang last
    
     # CHECK to see if any exist in filesystem
    my $comp;

    # Make language order available through $r->pnotes
    my @POLYGLOT_LANGS = @langs;
    $r->pnotes('POLYGLOT_LANGS', \@POLYGLOT_LANGS);
    while(defined ($_ = shift @langs)){
        $DEBUG && $r->log_error(join("", $path, $_?('.', $_):""), $comp_root_key, $comp_root_path);
	if($comp = $self->SUPER::get_info(join("", $path, $_?('.', $_):""), $comp_root_key, $comp_root_path)){
	    $DEBUG && $r->log_error("picked '$_'");
	    return $comp;
	}
    }
    return;
}

=head1 METHODS

=over 4

=cut

# This resolver has a few new methods that it uses internally to determine what component to choose.
#=item get_langs
#This stores and returns a ranked list of components to try, using the URL and the client's language preferences to order them.  
#=cut

sub get_langs{
    my ($self, $path) = @_;
    # path is a scalar ref to the path that was fed to the resolver

    my %Accept;
    $self->_get_client_pref(\%Accept);
    # URL overrides browser
    $self->_get_env_pref(\%Accept);
    my @langs = sort { $Accept{$b}{q} <=> $Accept{$a}{q} } keys %Accept;
    $self->{langs} = \@langs;
}


# =item _get_client_pref

# This takes a hashref, which it will populate with the client's language preferences.
# This looks for and parses the I<Accept-Language> header, and stores the q values as values.

#=cut

sub _get_client_pref{
    my ($self, $Accept) = @_;
    
    my $r = $self->{r};
    # Determine Client preference
    my $accept = $r->header_in('Accept-Language');
    my ($lang, @quality);
    my ($qkey, $qval);
    if($accept){
	for(split(/\s*,\s*/, $accept)){
	    ($lang, @quality) = split(/\s*;\s*/);
	    $lang =~ tr/A-Z_/a-z-/;
	    unless(@quality){
		$$Accept{$lang}{q} = 1;
	    }
	    # Can there be more than one ';' tag on a lang?
	    for(@quality){
		($qkey,$qval) = split(/\s*=\s*/);
		# Thanks to Dorian Taylor <dorian@foobarsystems.com> for this
		# Some UAs use 'qs'
		if($qkey =~ /^qs?$/){
		    $$Accept{$lang}{q} = 
			$qval eq '' ? 1 :
			$qval  > 1  ? 1 :
			$qval  < 0  ? 0 : $qval;
		}else{
		    # Some other key type
		    $$Accept{$lang}{$qkey} = $qval;
		}
	    }
	}
    }
}

=item uri_override

This has an alias as I<handler> so you don't have to specify the method if you set MasonX::Resolver::Polyglot as a PerlInitHandler.

This examines the URL for a leading, lowercase language tag of the format langcode<-sublangcode> (I<en>, I<en-us>, I<es> etc.).  

If it finds one, it will give that language the highest precidence, and MODIFY THE URL, REMOVING THE LANGUAGE TAG.

The upshot of this is that regardless of the browser's Accept-Language preference, it can be overriden using the URL.

=over 4 

http://www.mydomain.com/colors/red.html - gives me an English page

http://www.mydomain.com/es/colors/red.html - forces it to give me the Spanish page (if it exists)

=cut

# This is so we can just use the class as a PerlInitHandler without one of them fancy arrows
*handler = \&uri_override;

sub uri_override{
    # This a a mod_perl Apache handler - 
    #   it is intended as a PerlInitHandler so it can manipulate the incoming request's URL
    my $r = shift;
    # CHECK URL to see preferred language - it will be prepended
    # This method allows the url to override the client pref, 
    #  but still expresses it as a preference - 
    #  we can still fall back on another lang for a component
       # !!! This will MODIFY the URI, extracting out the leading language tag
    $DEBUG && $r->log_error("URI: uri is: @{[$r->uri]}");
    my $urilang;
    # Save uri in case we need it
    $r->pnotes('POLYGLOT_URI' => $r->uri);
    my @uri = split(/\/+/, $r->uri);
    # leading slash = leading ""
    shift @uri;
    # check to see if first segment is std lang tag with optional sub lang 
    $DEBUG && $r->log_error("URI: checking URL: tag $uri[0]");
    if($uri[0] =~ /^([a-z]{2})(?:-([a-z]{2,3}))?$/
       and code2language($1) and
       (!$2 || 
	code2country($2, length($2) == 2 
		     ? LOCALE_CODE_ALPHA_2 : LOCALE_CODE_ALPHA_3 ))){
	$DEBUG && $r->log_error("$uri[0] is a valid lang tag!");
	$urilang = $2?join('-', lc($1), lc($2)):$1;
    # Stash language preference in ENV and pnotes
	$ENV{$POLYGLOT_LANG} = $urilang || lc $r->dir_config($PolyglotDefaultLang);
	$r->pnotes('POLYGLOT_URILANG', $urilang);
	$r->pnotes('POLYGLOT_LANG', $urilang);
    # 86 the language tag, rebuild the URI
	shift @uri;
	$r->uri(join('/', "", @uri));
	$DEBUG && $r->log_error("new path is " . $r->uri);
    }else{
	$DEBUG && $r->log_error("Path unchanged: " . $r->uri);
    }
}

# =item _get_env_pref 

# This takes a hashref as its argument (usually the hash that I<get_client_pref> populated), 
# and alters it to reflect the preference stashed in the environment.

# =cut

sub _get_env_pref{
    my $self = shift;
    my $Accept = shift||{};
    
    # Check the environment to see if there is a favoured language
    if($self->{default_uri_lang}){
	$$Accept{$self->{default_uri_lang}}{q} = 100; # trump everything - top the list
	$self->{r}->pnotes('POLYGLOT_URILANG', $self->{default_uri_lang});
	return $Accept;
    }

}

1;

=head1 SEE ALSO

L<HTML::Mason::Resolver::File|HTML::Mason::Resolver::File>

=head1 CREDIT

Thanks to Dorian Taylor <dorian@foobarsystems.com> for his nice Accept-Language code.

=head1 AUTHOR

Benjamin H Kram <ben@base16consulting.com>

=cut

__END__
