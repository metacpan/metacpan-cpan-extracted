=head2 link_url

C<link_url> looks at a candidate.

=cut

package WWW::Link_Controller::URL;
$REVISION=q$Revision: 1.8 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );
use URI;
use Carp;
use strict;
use warnings;

our $verbose;
our $no_warn;

#charset definitions

sub RESERVED () { '[;/?:@&=+$]';}
sub ALPHA () { '[A-Za-z]'; }
sub ALPHA_NUM () { '[A-Za-z0-9]'; }
sub SCHEME_CHAR () { '[A-Za-z0-9+.-]'; }
sub MARK () { "[-_.!~*'()]"; }
sub UNRESERVED () { '(?:' . ALPHA_NUM . '|' . MARK . ')' };
sub ESCAPE () { '[%]'; }
sub SCHEME () { '(?:(?i)[a-z][a-z0-9+.-]*)';}
sub ABSURI () { SCHEME . ':' . '/';}

sub CONTROL () { '[\x00-\x1F\x7F]'; }

#N.B. % and # normally included here.  We don't include % since it is
#allowed as the escape character. and we don't include # since within
#LinkController we consider the fragment as part of the URL in
#contradiction with the standards, since we may be interested to check
#that the exact fragment of the resource exists
sub DELIMS () { '[<>"]'; }
sub UNWISE () { '[{}|\^[]`]'; }
sub EXCLUDED () { '(?:'. CONTROL .'|'. DELIMS .'|'. UNWISE .'|'.' '.'|'.'#'.')' };
sub URIC () { '(?:' . RESERVED . '|' . UNRESERVED . '|' . ESCAPE . ')' };

#sub AUTHORITY () { '(?:(?i)[a-z][a-z0-9+.-]*)';}
#sub NET_PATH () { '//' . AUTHORITY . '/' . ABS_PATH; }


=head2 verify_url

verify url checks that a url is a valid and possible uri in the terms
of RFC2396

=cut

sub verify_url ($) {
  my $url=shift;
  my $control=CONTROL;
  # we don't print it out directly..  maybe we shouldn't even print out
  # the warning.
  do { carp "url $url contains control characters" unless $no_warn;
       return undef; } if $url =~  m/$control/;
  my $exclude=EXCLUDED;
  my $ex;
  do { carp "url $url contains excluded character: $ex" unless $no_warn;
       return undef; } if ($ex) =  $url =~ m/($exclude)/;

  #try to identify invalid schemes.  The problem here is that it's possible
  #to have a : elsewhere in a URL so we have to be very careful.

  my $scheme=$url;

  #chop off anything which is definitely not the scheme.. this gets rid of
  #the second part of any paths etc.  This protects us against relative urls
  #which have a : in them (N.B.

  $scheme =~ s,[#/].*,, ;

  #now keep the bit preceeding the :

  ($scheme) = $scheme =~ m/^([^:]*):/;

  if ( defined $scheme ) {
    my $scheme_re= '^' . ALPHA .'('. ALPHA_NUM ."|". SCHEME_CHAR .')*$'  ;
    do { carp "url $url has illegal scheme: $scheme" unless $no_warn;
	 return undef; } unless $scheme =~ m/$scheme_re/;
  }

  return 1;
}

=head2 untaint_url

Used in our CGI bin programs, untaint_url takes a scalar and returns
it untainted if and only if it's contains only valid url characters
and it is a valid url according to verify_url.

A fundamental assumption in using this function is that your software
can handle B<anything> which looks like a valid URL, even if it isn't
a valid url.  E.g. C<news://www.a.b.com/directory/otherdir>.

=cut

sub untaint_url {
  my $url=shift;
  my $re='^'. URIC .'+$';
  my ($ret)= $url =~ m/($re)/;
  defined $ret or do {
#    $url =~ y/[A-Za-z0-9]/_/c;# clean url so we can print it out
    warn "bad url passed to url_untaint" unless $no_warn;
    return undef;
  };
  return undef unless verify_url($ret);
  return $ret;
}

=head2 verify_fragment

Fragments have fairly free syntax but RFC 2396 says clearly they
should conform to the same character set as URIs.  Unfortunately, it
seems that many people put spaces in their fragments in contradiction
with the RFC since it works in HTML in practice.

We choose not to accept those and people should be able to change over?

If it turns out, as it probably will, that there is a real need for
spaces in cross references to other people's documents which can't be
fixed then maybe we will have to reconsider.

=cut

sub verify_fragment ($) {
  my $fragment=shift;
  defined $fragment or return undef;
  my $control=CONTROL;
  # we don't print it out directly..  maybe we shouldn't even print out
  # the warning.
  do { carp "url $fragment contains control characters" unless $no_warn;
       return undef; } if $fragment =~  m/$control/;
  my $exclude=EXCLUDED;
  my $ex;
  do { carp "url $fragment contains excluded character: $ex" unless $no_warn;
       return undef; } if ($ex) =  $fragment =~ m/($exclude)/;

  return 1;
}

sub extract_fragment {
  my $link=shift;
  my ($url,$fragment)= $link =~ m/([^#]*)(?:#(.*))?/;
  $::verbose & 16 and do {
    print STDERR "URL is $url and fragment is $fragment\n"
      if defined $fragment;
    print STDERR "URL is $url no fragment\n" unless defined $fragment;
  };
  return $url,$fragment;
}

sub fixup_link_url ($$) {
  my $link=shift;
  my $base=shift;
  croak "usage link_url(<url>,<base>)" unless defined $link;

  my ($url,$fragment)=extract_fragment($link);

  unless (verify_url($url)) {
    warn "dropping url: $url" unless $no_warn;
    return undef;
  };

  unless (verify_fragment($fragment)) {
    warn "dropping illegal fragment: $fragment for url $url" if defined $fragment;
    $fragment=undef;
  };

  $url =~ m,^(?:ftp|gopher|http|https|ldap|rsync|telnet):(?:[^/]|.[^/]),
    and do {
    warn "ERROR: ignoring relative url with scheme $url";
    return undef;
  };

  my $urlo=URI->new($url);
  my $aurlo=$urlo->abs($base);
  my $ret_url;
  if ( URI::eq($urlo,$aurlo) ) {
    $ret_url = $url;
  } else {
    $ret_url=$aurlo->as_string();
  }

  $ret_url =~ m,^(?:ftp|gopher|http|https|ldap|rsync|telnet):(?:[^/]|.[^/]),
    and do {
    warn "ERROR: abs(url) $url gave $ret_url";
    return undef;
  };

  print STDERR "fixed up link name $url\n"
    if $::verbose & 16 and defined $url;
  return $ret_url;
}

99;
