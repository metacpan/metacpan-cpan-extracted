package FirstGoodURL;

$VERSION = '1.11';

use LWP::UserAgent;
use Carp;
use strict;

my $status = { 200 => 1 };
my $ctype = {};
my $ua;


sub import { $ua ||= LWP::UserAgent->new }


sub with {
  my $class = shift;
  carp "no content-type or status given" if not @_;

  $status = { 200 => 1 };
  $ctype = {};
  (/\D/ ? $ctype->{$_} : $status->{$_}) = $_ for @_;

  return $class;
}


sub in {
  shift;

  my $match;

  for (@_) {
    my $req = $ua->request(HTTP::Request->new(HEAD => $_));
    my ($rc,$rt) = ($req->code, $req->content_type);

    if (not keys %$ctype) { $match = $_ and last if $status->{$rc} }
    else { next if not $status->{$rc} }

    if (keys %$ctype == 1 and my($regex) = (each %$ctype)[1]) {
      $match = $_ and last if $rt =~ $regex;
    }

    else { for (keys %$ctype) { $match = $_ and last if $ctype->{$rt} } }
  }

  $status = { 200 => 1 };
  $ctype = {};
  return $match;
}


1;

__END__

=head1 NAME

FirstGoodURL - determines first successful URL in list

=head1 SYNOPSIS

  use FirstGoodURL;
  use strict;
  
  my @URLs = (...);
  my $match;
  
  if ($match = FirstGoodURL->in(@URLs)) {
    print "good URL: $match\n";
  }
  else {
    print "no URL was alive\n";
  }
  
  if ($match = FirstGoodURL->with('image/png')->in(@URLs)) {
    print "PNG found at $match\n";
  }
  else {
    print "no PNG found\n";
  }
  
  if ($match = FirstGoodURL->with(200,204)->in(@URLs)) {
    print "Status: OK or No Content at $match\n";
  }
  else {
    print "no 200/204 found\n";
  }

=head1 DESCRIPTION

This module uses the LWP suite to scan through a list of URLs.  It determines
the first URL that returns a specified status code (with defaults to C<200>),
and optionally, a specified Content-type.

=head1 Methods

=over 4

=item * C<FirstGoodURL-E<gt>in(...)>

Scans a list of URLs for a specified response code, and possibly a requisite
Content-type (see the C<with> method below)

=item * C<FirstGoodURL-E<gt>with(...)>

Sets a Content-type and/or Status requisite value for future calls to C<in>.
It is destructive to the previous settings given, so you must send all
settings at once.

B<This is not backward compatible.>

The argument list can contain a list of Status response codes, and either a
list of Content-type response values B<or> a regex to match acceptable
Content-type response values.  These can appear in any order.  The regex must
be a compiled one (formed by using C<qr//>).

This method returns the class name, so that you can daisy-chain calls for
readability/snazziness:

  my $match = FirstGoodURL->with(qr/image/)->in(@URLs);

=back

=head1 TODO

Here is a listing of things that might be added to future versions.

=over 4

=item * Object support (C<with> attributes per object)

=back

=head1 AUTHOR

  Jeff "japhy" Pinyan
  CPAN ID: PINYAN
  japhy@pobox.com
  http://www.pobox.com/~japhy/

=cut
