package Image::Grab;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

# $Id: Grab.pm,v 1.6 2002/01/19 21:14:01 mah Exp $
$VERSION = '1.4.2';

use Carp;
use Config;
require HTTP::Request;
require HTML::TreeBuilder;
require URI::URL;
require Image::Grab::RequestAgent;
use POSIX qw(strftime);

require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(
  &expand_url &grab
);

# %fields, new, AUTOLOAD are from perltoot

my %fields = (
	      cookiefile => undef,
	      cookiejar  => undef,
	      date       => undef,
	      image      => undef,
	      "index"    => undef,
	      md5        => undef,
	      refer      => undef,
	      regexp     => undef,
	      type       => undef,
	      ua         => undef,
	      url        => undef,
	      search_url => undef,
	      debug      => undef,
	      do_posix   => ($Config{patchlevel} && $Config{patchlevel} >= 5 and
			     $Config{baserev} && $Config{baserev}    >= 5) ? 1 : undef,
	     );

sub DESTROY {}

sub new {
  my $that  = shift;
  my $class = ref($that) || $that;
  my $self = {
	      _permitted => \%fields,
	      %fields,
	     };

  if(@_) {
    my %arg = @_;

    foreach (keys %arg) {
      croak "Can't access `$_' field"
	unless exists $self->{_permitted}->{lc($_)};
      $self->{lc($_)} = $arg{$_};
    }
  }

  bless ($self, $class);
  $self->ua(new Image::Grab::RequestAgent);
  $self->{have_DigestMD5} = eval {require Digest::MD5};
  $self->{have_MD5} = eval {require MD5;};
  $self->{have_magick} = eval {require Image::Magick;};
  return $self;
}

sub AUTOLOAD {
  my $self = shift;
  my $type = ref($self)
    or croak "$self is not an object";

  my $name = $AUTOLOAD;
  $name =~ s/.*://;

  unless (exists $self->{_permitted}->{$name} ) {
    croak "Can't access `$name' field in class $type";
  }

  if(@_) {
    my $val = shift;
    carp "$name: $val" if $self->debug;
    return $self->{$name} = $val;
  } elsif (defined $self->{$name}) {
    return $self->{$name};
  }

  return undef;

}

# Accessor functions that we have to write.
sub realm {
  my $self = shift;
  my $type = ref($self)
    or croak "$self is not an object";

  if($#_ == 2){
    $self->ua->register_realm(shift, shift, shift);
    return 1;
  } 

  croak "usage: realm(\$realm, \$user, \$pass)";
}

sub getAllURLs {
  my $self = shift;
  my $type = ref($self)
    or croak "$self is not an object";
  my $times = (shift or 10);
  my $req;
  my $count = 0;
  my @link;
  my @now;

  # Need to load Cookie Jar?
  $self->loadCookieJar;

  @now = localtime;
  $self->search_url(strftime $self->search_url, @now) 
    if defined $self->search_url and defined $self->do_posix;
  croak "Need to specify a search_url!" if !defined $self->search_url;
  $req = $self->ua->request(new HTTP::Request 'GET', $self->search_url);

  # Try $times until successful
  while( (!$req->is_success) && $count < $times){
    $req = $self->ua->request(new HTTP::Request 'GET', $self->search_url);
    $count = $count + 1;
  }

  # return failure if we couldn't connect within $times tries
  if($count == $times && !$req->is_success){
    return undef;
  }

  # Get the base url
  my $base_url = $req->base;

  # Get the img tags out of the document.
  my $parser = new HTML::TreeBuilder;
  $parser->parse($req->content);
  $parser->eof;
  foreach (@{$parser->extract_links(qw(img td body))}) {
    push @link, URI::URL::url($$_[0])->abs($base_url)->as_string;
  }
  $parser->delete;

  return @link;
}

sub getRealURL {
  my $self = shift;
  my $type = ref($self)
    or croak "$self is not an object";
  my $times = (shift or 10);

  carp "getRealURL has been deprecated.  Use expand_url.";
  $self->expand_url(@_);
}

sub expand_url {
  my $self = shift;
  my $type = ref($self)
    or croak "$self is not an object";
  my $times = (shift or 10);
  my $req;
  my $count = 0;
  my @link;
  my @now;

  # Expand any POSIX time escapes
  @now = localtime;

  if(defined $self->url) {
    $self->url(strftime($self->url, @now)) 
      if defined $self->do_posix;
    return $self->url;
  }
  $self->regexp(strftime($self->regexp, @now))
    if defined $self->regexp and defined $self->do_posix;

  @link = $self->getAllURLs($times);
  return undef if !@link;

  # if this is a relative position tag...
  if($self->regexp || $self->index) {
    my (@match, $re);

    $self->refer($self->search_url);
    # set index to match first image
    $self->index(0) if !defined $self->index;
    $re = $self->regexp || '.';
    @match = grep {defined && /$re/} @link;
    # Return the nth
    return $match[$self->index]
      if @match;
  }

  # only if we fail.
  return undef;
}

sub loadCookieJar {
  my $self = shift;
  my $type = ref($self)
    or croak "$self is not an object";

  # need to do CookieJar initialization?
  if($self->cookiefile and !-f $self->cookiefile){
    carp $self->cookiefile, " is not a file";
  } elsif ($self->cookiefile and !defined $self->cookiejar) {
    use HTTP::Cookies;

    $self->cookiejar(
      HTTP::Cookies::Netscape->new( File => $self->cookiefile,
				    AutoSave => 0,
				  ));
    $self->cookiejar->load();
  }

}

sub grab {
  my $self = shift;
  my $times = 1;

  if(ref($self)) {
    if(my $c = shift) {
      $times = $c;
    }
  } else {
    if($self eq __PACKAGE__) {
      $self = Image::Grab->new(@_);
    } else {
      $self = Image::Grab->new(lc $self, @_);
    }
  }
  my $req;
  my $count;
  my $rc;

  # need to do CookieJar initialization?
  $self->loadCookieJar;

  # need to find image on page?
  my $url = $self->expand_url($times);

  # make sure we have a url
  croak "Couldn't determine an absolute URL!\n" unless defined $url;
  carp "Fetching URL: ", $url if $self->debug;

  # Set it up
  $req = new HTTP::Request 'GET', $url;
  $req->push_header('Referer', $self->refer) if defined $self->refer;
  if($self->cookiejar){
    $self->cookiejar->add_cookie_header($req);
  }

  # Knock it down
  $count = 0;
  do{
    $count++;
    $rc = $self->ua->request($req);
    carp "Got: ", $rc->content
      if $self->debug;
  } while($count <= $times and not $rc->is_success);

  # Did we fail?
  return 0 unless $rc->is_success;

  carp "Message: ", $rc->message if $self->debug;

  # save what we got
  $self->image($rc->content);
  $self->date($rc->last_modified);

  if($self->{have_DigestMD5}) {
    $self->md5(Digest::MD5::md5_hex($self->image));
  } elsif ($self->{have_MD5}) {
    $self->md5(MD5->hexhash($self->image));
  }


  $self->type($rc->content_type);

  $self->image;
}

sub grab_new {
  my $self = shift;
  my $type = ref($self)
    or croak "$self is not an object";
  my $tries = shift || 10;

  return $self->grab($tries)
    unless defined $self->date || defined $self->md5;

  my $tmp = $type->new;
  $tmp->url($self->url);
  $tmp->search_url($self->search_url);
  $tmp->index($self->index);
  $tmp->regexp($self->regexp);
  $tmp->grab;

  my $grab_new = 1;

  $grab_new = 0
    if defined $self->date && $self->date >= $tmp->date;
  $grab_new = 0
    if defined $self->md5 && $self->md5 eq $tmp->md5;

  return $self->grab($tries)
    if $grab_new;
  return undef;
}

1;
__END__
