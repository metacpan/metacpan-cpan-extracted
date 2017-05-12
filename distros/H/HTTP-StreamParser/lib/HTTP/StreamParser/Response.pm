package HTTP::StreamParser::Response;
{
  $HTTP::StreamParser::Response::VERSION = '0.101';
}
use strict;
use warnings;
use parent qw(HTTP::StreamParser);

=head1 NAME

HTTP::StreamParser::Response - streaming parser for HTTP response data

=head1 VERSION

version 0.101

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut

use List::Util qw(min);

use constant BODY_CHUNK_SIZE => 4096;

=head1 METHODS

=cut

=head2 state_sequence

Returns the sequence of states this response can be in, as a list.

=cut

sub state_sequence {
	qw(
		http_version single_space http_code single_space http_status newline
		http_headers
		http_body
	)
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2013. Licensed under the same terms as Perl itself.
