package HTTP::StreamParser::Request;
{
  $HTTP::StreamParser::Request::VERSION = '0.101';
}
use strict;
use warnings;
use parent qw(HTTP::StreamParser);

=head1 NAME

HTTP::StreamParser::Request - streaming parser for HTTP response data

=head1 VERSION

version 0.101

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use List::Util qw(min);

=head1 METHODS

=cut

=head2 state_sequence

Returns the sequence of states this request can be in, as a list.

=cut

sub state_sequence {
	qw(
		http_method single_space http_uri single_space http_version newline
		http_headers
		http_body
	)
}

=head2 request_method

Parse the request method. Expects a single word.

=cut

sub request_method {
	my $self = shift;
	my $buf = shift;
	if($$buf =~ s/^([A-Z]+)(?=\s)//) {
		$self->{method} = $1;
		die "invalid method ". $self->{method} unless $self->validate_method($self->{method});
		$self->invoke_event(request_method => $self->{method});
		$self->parse_state('request_uri');
	}
	return $self
}

=head2 request_uri

Parse the URI. May be an empty string.

=cut

sub request_uri {
	my $self = shift;
	my $buf = shift;
	if($$buf =~ s/^([^ ]*)(?=\s)//) {
		$self->{uri} = $1;
		$self->invoke_event(request_uri => $self->{uri});
		$self->parse_state('request_version');
	}
	return $self
}

=head2 request_version

Parse the HTTP version stanza. Probably HTTP/1.1.

=cut

sub request_version {
	my $self = shift;
	my $buf = shift;
	if($$buf =~ s{^(HTTP)/(\d+.\d+)(?=\s)}{}) {
		$self->{proto} = $1;
		$self->{version} = $2;
		$self->invoke_event(request_version => $self->{proto}, $self->{version});
		$self->parse_state('request_headers');
	}
	return $self
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2013. Licensed under the same terms as Perl itself.
