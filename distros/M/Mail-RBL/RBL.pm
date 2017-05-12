package Mail::RBL;

require 5.005_62;
use Carp;
use Socket;
use strict;
use warnings;
use Net::DNS;
use NetAddr::IP ':aton';

# $Id: RBL.pm,v 1.10 2007/04/25 04:22:04 lem Exp $

our $VERSION = do { sprintf " %d.%02d", (q$Revision: 1.10 $ =~ /\d+/g) };

=pod

=head1 NAME

Mail::RBL - Perl extension to access RBL-style host verification services

=head1 SYNOPSIS

  use Mail::RBL;

  my $list = new Mail::RBL('list.org');

  # You can also specify a resolver to use with Net::DNS::Resolver

  my $list = new Mail::RBL('list.org', $res);

  if ($list->check($host)) {
      print "$host is in the list";
  }

  my ($ip_result, $optional_info_txt) = $list->check($host);
  # $optional_info_txt will be undef if the list does not provide TXT
  # RRs along with the A RRs.

  print "The list says ", ($list->check($host))[1], " in its TXT RR\n";

  my ($ip_result, $optional_info_txt) = $list->check_rhsbl($hostname);

=head1 DESCRIPTION

This module eases the task of checking if a given host is in the
list. The methods available are described below:

=over

=item C<-E<gt>new(suffix, resolver)>

Creates a list handle. The C<suffix> parameter is mandatory and
specifies which suffix to append to the queries. If left unspecified,
defaults to C<bl.spamcop.net>.

An optional DNS resolver can be specified. An object of the
Net::DNS::Resolver(3) class is expected.

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type || "Mail::RBL";
    my $suffix = shift;
    my $res = shift || Net::DNS::Resolver->new;
    
    my $self = {
	suffix	=> defined $suffix ? $suffix : 'bl.spamcop.net',
	res	=> $res,
    };

    bless $self, $class;
}

=pod

=item C<-E<gt>check($host)>

C<$host> can be either a hostname or an IP address. In the case of an
IP Address. In the case of a hostname, all the IP addresses will be
looked up and checked against the list. If B<any> of the addresses is
in the list, the host will be considered in the list as a whole.

Returns either a C<NetAddr::IP> object as returned by the RBL itself,
or C<undef> in case the RBL does not supply an answer. This is
important because many lists inject some semantics on the DNS response
value, which now can be recovered easily with the program that uses
this module.

In array context,  any IP addresses are returned,  followed by any TXT
RR (or undef if none). If no match is found, an empty list is returned
instead. In  scalar context, only the  first IP address  (or undef) is
returned.

=back

=cut

sub check ($$)
{
    my $self = shift;
    my $host = shift;

    croak "Must call ->check() with a host to check"
	unless length $host;

    foreach my $addr (_inverted_addresses($host)) {
	if (my $val = $self->_do_check($addr)) 
	{ 
	    if (wantarray)
	    {
		return ($val, $self->_do_txt($addr));
	    }
	    else
	    {
		return $val; 
	    }
	}
    }

    return;
}

=pod

=item C<-E<gt>check_rhsbl($host)>

Analogous to C<-E<gt>check()>, but  queries RHSBLs instead of IP-based
lists.   This  is   useful   for   using  lists   such   as  some   of
B<http://www.rfc-ignorant.org/>.

Results and return values are the same as C<-E<gt>check()>.

=cut

sub check_rhsbl ($$)
{
    my $self = shift;
    my $host = shift;

    croak "Must call ->check_rhsbl() with a host to check"
	unless length $host;

    if (my $val = $self->_do_check($host)) 
    { 
	if (wantarray)
	{
	    return ($val, $self->_do_txt($host));
	}
	else
	{
	    return $val; 
	}
    }

    return;
}

sub _do_txt {
    my $self = shift;
    my $host = shift;

    my $res = $self->{res};
    my $q = $res->query($host . '.' . $self->{suffix}, "TXT");
    my @txt = ();

    if ($q)
    {
	for my $rr ($q->answer)
	{
	    next unless $rr->class eq 'IN' and $rr->type eq 'TXT';
	    push @txt, $rr->rdatastr;
	}
    }

    return @txt;
}

sub _do_check {
    my $self = shift;
    my $host = shift;

    my $res = $self->{res};
    my $q = $res->query($host . '.' . $self->{suffix}, "A");

    if ($q)
    {
	for my $rr ($q->answer)
	{
	    next unless $rr->class eq 'IN' and $rr->type eq 'A';
	    return NetAddr::IP->new($rr->address);
	}
    }
    return;
}

sub _inverted_addresses {
    my $host = shift;
    my @addresses;
    my @ret;

    if ($host =~ /^\d+\.\d+\.\d+\.\d+$/) {
	push @ret, join('.', reverse split(/\./, $host));
    }
    else {
	@addresses = (gethostbyname($host))[4];
    }
    
    foreach my $addr (@addresses) {
	push @ret, join('.', reverse unpack('C4', $addr));
    }
    
    return @ret;
}

1;
__END__

=pod

=head1 HISTORY

  $Log: RBL.pm,v $
  Revision 1.10  2007/04/25 04:22:04  lem
  Finished adding support for the custom resolver code - Implementation
  was incomplete

  Revision 1.9  2006/12/08 00:01:14  lem
  Get version straight from the CVS revision.

  Revision 1.8  2006/12/07 23:58:07  lem
  Allow the user to provide a Net::DNS::Resolver object to perform DNS
  resolution - This allows finer control over how the queries are
  performed. Suggested by Eric Langheinrich.


=over

=item 1.00

Original version.

=item 1.01

Minor bug fixes. Cleaned up MS-DOS line endings. Changed test cases
(more and better tests). Now requires Test::More. More useful return
values. Improved docs. First crypto-signed distribution of this
module.

=back

=head1 AUTHOR

Luis E. Munoz <luismunoz@cpan.org>

=head1 SEE ALSO

Net::DNS::Resolver(3), perl(1).

=cut
