package HTTP::ProxySelector;

use 5.006;
use strict;
use warnings;
use integer;
use LWP::UserAgent;
our $VERSION = '0.02';

# rand() is used, let's try to make the most of it...
srand;

# Constructor. Enables Inheritance
sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;

	if (@_) {
		my %options = @_;
		$self->{options} = \%options;
	}

	# Defaults
	unless ($self->{options}{sites}) {
		@{$self->{options}{sites}} = ('http://www.multiproxy.org/txt_anon/proxy.txt','http://www.samair.ru/proxy/fresh-proxy-list.htm');
	}
	$self->{options}{num_tries} ||= 5;
	$self->{options}{testsite} ||= 'http://www.google.com';
	$self->{options}{testflag} ||= 1;

	# Return initialized object
	return $self;
}

# Accept an anonymous proxy
sub set_proxy {
	my ($self) = @_;
	my ($counter, $rc) = (0,0);
	do {
		$rc = _set_proxy(@_);
		++$counter;
	}
	until (($rc ne 'retest') || ($counter > $self->{options}{num_tries}));
	$rc = 'All proxies checked failed to perform as expected' if ($rc eq 'retest');
	return $rc;
}

sub _set_proxy {
	my ($self, $ua) = @_;
	my $rc;
	eval {
		# From now, things can only go wrong :-)
		$rc = 0;

		my $list_page = $self->{options}{sites}[int(rand(scalar(@{$self->{options}{sites}})))];
		my $response = $ua->get($list_page);
		my @proxy_list = $response->content() =~ /([\w\.\-]{7,}:\d{1,5})/g;
		unless (@proxy_list) {
			warn "Couldn't find any proxies in $list_page\n";
			$rc = 1;
		}
		$self->{selected_proxy} = $proxy_list[int(rand(@proxy_list))];
		$ua->proxy(['http', 'ftp'], 'http://' . $self->{selected_proxy});

		# Proxy test, if required
		$rc = $self->test_proxy($ua) if (($self->{options}{testflag}) && ($rc == 0));
	};
	if ($@) {
		warn("Error occured in set_proxy - $@, Last system error: $!\n");
		return $@;
	}
	return $rc;

}
# Tell the caller what proxy has been selected
sub get_proxy {
	my $self = shift;
	return $self->{selected_proxy};
}

# Test the proxy by trying to access a site
# Return 0 for success, 1 for failure.
sub test_proxy {
	my ($self, $ua) = @_;
	my $response = $ua->get($self->{options}{testsite});
	$response->is_success() ? return 0 : return 1;
}

1;
__END__

=head1 NAME

HTTP::ProxySelector - Perl extension for automatically setting an anonymous proxy

=head1 SYNOPSIS

  use HTTP::ProxySelector;
  use LWP::UserAgent;

  # Instanciate
  my $selector = HTTP::ProxySelector->new();
  my $ua = LWP::UserAgent->new();

  # Assign an anonymous proxy to the UserAgent object.
  $selector->set_proxy($ua);
  
  # Just in case you need to know the chosen proxy
  print 'Selected proxy: ',$selector->get_proxy(),"\n";

=head1 DESCRIPTION

Automatically selects you an anonymous proxy for use of your UserAgent instance.
Just hand it your favorite proxy list site, or use the defaults. The package will then
use your existing useragent instance to access the site and set it's proxy settings according
to a random entry in the list.

=head1 METHODS

=over 4


=item B<new> - Constructor
   $select = HTTP::ProxySelector->new();
	  
B<new> is the constructor for HTTP::ProxySelector objects

Arguments:

- Accepts an Key-Value list with the list attributes.

General

  Key: sites     - Reference to a list of sites containing the proxy lists.
                   Example : $select = HTTP::ProxySelector->new(sites =>
				                             ['http://www.proxylist.com/list.htm']);
				   Default - http://www.multiproxy.org/txt_anon/proxy.txt
				             http://www.samair.ru/proxy/fresh-proxy-list.htm


Proxy testing

  Key: testflag  - Flag indicating whether the randomly selected proxy should be checked.
                   Example : $select = HTTP::ProxySelector->new(testflag => 0);
				   Default - 1.

	   num_tries - Number of proxies you wish to test before giving up.
                   Example : $select = HTTP::ProxySelector->new(num_tries => 10);
				   Default - 5.

	   testsite  - Destination site to test the proxy with.
                   Example : $select = HTTP::ProxySelector->new(testsite => 'http://yahoo.com');
				   Default - http://www.google.com


=item B<set_proxy> - Assign anonymous proxy

  $result = $select->set_proxy($useragent);
	  
Assign anonymous proxy to the useragent proxy

Arguments:

 LWP::UserAgent object.

Return value:

0 on success, a string describing the error upon failure

=item B<get_proxy> - Get selected proxy information

  $proxy = $select->get_proxy();
	  
Extract the address of the currently selected proxy.

Arguments:

None.

Return value:

String, describing the address of the proxy.


=head1 EXPORT

None by default.

=head1 TODO

This is becoming a dangerous habbit, but testing should really be implemented sometime soon.

=head1 AUTHOR

Eyal Udassin, E<lt>eyal@cpan.orgE<gt>

=head1 SEE ALSO

L<perl>, L<LWP::UserAgent>.

=cut
