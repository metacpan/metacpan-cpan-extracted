package LWP::ConnCache::Resolving;

use strict;
use warnings;

use Carp;

use base 'LWP::ConnCache';

our $VERSION = '0.02';

sub new {
	my $class = shift;
	my $self = LWP::ConnCache->new(@_);

	bless $self, $class;
	$self->_initialize(@_);
	return $self;
}

sub _initialize
{
	my $self = shift;

	my %params = @_;

	$self->{resolver} = $params{resolver};
	
	unless ($self->{resolver} && ref($self->{resolver}) eq 'CODE')
	{
		croak "You must specify a resolver. Otherwise, just use LWP::ConnCache.";
	}

	# do_res_cache will default to yes - disable it if your resolution is very fast
	$self->{do_res_cache} = defined($params{do_res_cache}) ? $params{do_res_cache} : 1;
	$self->{res_cache} = {};
}

sub deposit {
	my($self, $type, $key, $conn) = @_;
	return ($self->SUPER::deposit($type, $self->_get_resolved_key($key), $conn));
}

sub withdraw {
	my($self, $type, $key) = @_;
	return ($self->SUPER::withdraw($type, $self->_get_resolved_key($key)));
}

sub _get_resolved_key
{
	my $self = shift;
	my $key = shift;

	my $newkey;
	
	if ($self->{do_res_cache})
	{
		$newkey = $self->{res_cache}->{$key};
		return $newkey if $newkey;
	}

	eval
	{
		$newkey = &{$self->{resolver}}($key);
	};

	if ($self->{do_res_cache})
	{
		$self->{res_cache}->{$key} = $newkey || $key;
	}

	return $newkey || $key;
}


1;
__END__

=head1 NAME

LWP::ConnCache::Resolving - resolving connection cache.

=head1 DESCRIPTION

C<LWP::ConnCache::Resolving> can be used to add resolution to C<LWP::ConnCache>.

It might be useful if you have multiple hostnames that result in the same
logical connection which can be interchangably used for all of them
(either have the same IP address or connect to the same farm of load
balanced servers, for example).

Module itself does not define a resolution mechanism leaving it to the
user to define (I'll probably write DNS resolver as pre-canned module
in the future) - see resolver constructor parameter.

=head2 WARNING

Be careful with HTTP load balancers which sometimes use Host header
to keep connection to different backend servers - this connection
might not be reusable for request with different Host headers even if
hostname resolves to the same IP address.


=head1 SYNOPSIS

  use LWP::UserAgent;
  use LWP::ConnCache::Resolving;

  my $ua = new LWP::UserAgent(
	conn_cache => new LWP::ConnCache::Resolving(
		total_capacity => 20,
		do_res_cache => 1,
		resolver => sub {
			# LWP::Protocol::http uses "host:port" pair as a key
			my $key = shift;
			return "www.$key" unless $key =~ /^www\./i;
			return $key; # otherwise return what we got
		})
	);

  my @urls = (
	'http://www.example.com/robots.txt',
	'http://example.com/robots.txt',
  );

  foreach my $url (@urls)
  {
	my $res = $ua->get($url);

	print $res->content;
  }

=head1 CONSTRUCTOR PARAMETERS

To configure resolution, you can pass some parameters to object constructor (see. SYNOPSYS section above)

=over

=item resolver

This parameter accepts a subroutine that gets C<LWP::ConnCache> cache key as single parameter
and must return a resolved version that will be used instead of original one.

If this subroutine returns false value, it'll be ignored and original key will be used.

This parameter is mandatory (otherwise you can simply use regular C<LWP::ConnCache> instead).

=item do_res_cache

This attribute allows you to enable resolution cache. This is C<true> (enabled) by default.
If your resolution is not deterministic (changes from call to call), then it makes sense
to disable it by setting do_res_cache to C<false>.

=back

=head1 SEE ALSO

For actual connection cacheing functionality see L<LWP::ConnCache>

=head1 AUTHOR

Sergey Chernyshev, E<lt>sergeyche@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Sergey Chernyshev E<lt>sergeyche@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
