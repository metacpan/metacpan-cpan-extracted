package HTTP::Request::FromFetch;
use strict;
use warnings;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';
use Carp 'croak';
use JSON;
use PerlX::Maybe;
use HTTP::Request::CurlParameters;

our $VERSION = '0.37';

=head1 NAME

HTTP::Request::FromFetch - turn a Javascript fetch() statement into HTTP::Request

=head1 SYNOPSIS

  my $ua = LWP::UserAgent->new();
  my $req = HTTP::Request::FromFetch->new(<<'JS')->as_request;

      await fetch("https://www.example.com/index.html", {
          "credentials": "include",
          "headers": {
              "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:74.0) Gecko/20100101 Firefox/74.0",
              "Accept": "text/javascript, text/html, application/xml, text/xml, */*",
              "Accept-Language": "de,en-US;q=0.7,en;q=0.3",
              "X-CSRF-Token": "secret",
              "X-Requested-With": "XMLHttpRequest"
          },
          "referrer": "https://www.example.com/",
          "method": "GET",
          "mode": "cors"
      });

  JS
  $ua->request( $req );

=head1 DESCRIPTION

This module parses a call to the L<Javascript Fetch API|https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API>
and returns an object that you can turn into a L<HTTP::Request> to use
with L<LWP::UserAgent> or other user agents to perform a largely identical
HTTP request.

The parsing of the Javascript stanza is done through a regular expression, so
the test must largely follow the pattern shown in the synopsis. Usually, the
C<fetch()> stanzas come from a browsers "Copy as fetch" context menu, so there
is no problem parsing these.

This is mostly a factory class for L<HTTP::Request::CurlParameters> objects.

=cut

sub new( $class, $fetch, @rest ) {
    my %options;

    if( @rest ) {
        %options = ($fetch, @rest);
    } else {
        $options{ fetch } = $fetch;
    };

    $fetch = delete $options{ fetch };

    $fetch =~ m!\A\s*(await\s+)?
                  fetch\s*\(\s*"(?<uri>(?:[^[\\"]+|\\.)+)"\s*(?:,\s*
                  (?<options>\{.*\}))?\s*
                  \)\s*;?
                  \s*\z!msx
        or croak "Couldn't parse fetch string '$fetch'";

    my $options;
    my $o = $+{options};
    my $u = $+{uri};
    if( defined $o and $o =~ /\S/ ) {
        $options = decode_json($o);
    } else {
        $options = {};
    };

    $options->{uri} = $u;
    $options->{method} ||= 'GET';
    $options->{mode} ||= 'cors';
    $options->{cache} ||= 'default';
    $options->{credentials} ||= 'same-origin';
    $options->{headers} ||= {};


    HTTP::Request::CurlParameters->new({
            method     => delete $options->{method} || 'GET',
            uri        => $options->{uri},
            headers    => $options->{headers},
            maybe body => $options->{body},
            #maybe credentials => $options->{ user },
    });
}

1;

=head1 SEE ALSO

L<Javascript Fetch API|https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API>

=head1 REPOSITORY

The public repository of this module is
L<http://github.com/Corion/HTTP-Request-FromCurl>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Request-FromCurl>
or via mail to L<filter-signatures-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2018 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
