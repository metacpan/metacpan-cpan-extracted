package HTTP::Retry;

use 5.008008;
use strict;
use warnings;
use HTTP::Tiny;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( http );
our $VERSION = '0.05';

sub http
{
	my %conf;
	my $url;
	my $timeout;
	my $retry;
	my $sleep;
	unless($#_)
	{
		$url = shift;
		$timeout = 5;
		$retry = 3;
		$sleep = 0;
	}
	else
	{
		%conf = @_;
		$url = $conf{'url'};
		$timeout = $conf{'timeout'} || 5;
		$retry = $conf{'retry'} || 3;
		$sleep = $conf{'sleep'} || 0;
	}
	return "failed cause empty url" unless $url;

	my $http_tiny = HTTP::Tiny->new( 'timeout' => $timeout , 'agent' => 'HTTP::Retry');
	my $resp;
	for(1 .. $retry)
	{
		$resp = $http_tiny->get($url);
		return $resp if $resp->{success};
		sleep $sleep if $sleep > 0 ;
	}
	return "failed at timeout=$timeout, retry=$retry, sleep=$sleep";
}
1;
__END__

=head1 NAME

HTTP::Retry - Wrapped HTTP::Tiny with timeout and retry

=head1 SYNOPSIS

  use HTTP::Retry qw(http);
  $response = http("http://www.example.com");
  $response = http('url' => 'http://www.example.com', 'timeout' => 1, 'retry' => 10, 'sleep' => 1);
  print $response->{status};
  print $response->{content} if $response->{success};

=head1 DESCRIPTION

Another HTTP client library.

LWP is too complex and too slow.

HTTP::Tiny and Furl is wonderful, but no autoretry.

HTTP::Retry resolves this, then make your code clearer.

Enjoy it!

=head2 EASY MODE

Easy write and understand with 3 seconds timeout and 3 times retry.

  my $response = http("http://www.example.com");
  print $response->{content};


=head2 COMPLEX MODE

Set timeout and retry times as your wish.

  my $response = http('url' => 'http://www.example.com', 'timeout' => 1, 'retry' => 10, 'sleep' => 1);
  print $response->{content};


=head1 SEE ALSO

L<HTTP::Tiny>, L<Furl>, L<Hijk>

=head1 AUTHOR

Chen Gang, E<lt>yikuyiku.com@google.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Chen Gang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
