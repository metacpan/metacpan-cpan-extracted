package HTTP::Request::FromTemplate;
use strict;
use HTTP::Request;
use Template;
use base 'Class::Accessor';

use vars qw($VERSION);

$VERSION = '0.05';

=head1 NAME

HTTP::Request::FromTemplate - Create HTTP requests from templates

=head1 SYNOPSIS

  use HTTP::Request::FromTemplate;
  use LWP::UserAgent;

  my $ua = LWP::UserAgent->new();

  # A request, snarfed from your network monitor logs:
  my $template = <<TEMPLATE
  POST http://[% host %][% path %][% query %] HTTP/1.1
  Host: [% host %]
  Connection: keep-alive
  Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
  Accept-Encoding: gzip,deflate
  Accept-Language: en-us,en;q=0.5
  User-Agent: QuickTime (qtver=5.0.2;os=Windows NT 5.1)
  Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5
  Keep-Alive: 300
  Referer: http://[% host %][% path %][% query %]

  TEMPLATE
  my $t = HTTP::Request::FromTemplate->new(template => $template);
  my $req = $t->process({ 'host' => 'apple.com',
                          'path' => '/',
                          'query' => '?',
                           });
  my $response = $ua->request($request); # replay the request

=head1 ABSTRACT

I wanted this for a long time already. It makes it very convenient
to just paste a logged session from the
L<Live HTTP Headers|http://livehttpheaders.mozdev.org/>
into a template file and be able to faithfully replay a request
or to parametrize it without needing to manually compare what
is sent against what I want.

=head1 PREDEFINED TEMPLATE PARAMETERS

There is one predefined/magic template parameter. C<content_length>
will be set to the length of the content (after the template has
been filled out) unless it was passed in via the template
parameters.

=head1 FEEDBACK

This is one of the modules that I created because the idea hit
me as crazy but useful. So if you use the module, please tell
me what enhancements you'd like, or where it falls short
of your expectations.

=head1 KNOWN BUGS

=over 4

=item * While this module tries to faithfully replicate a HTTP request
from a template, it uses L<HTTP::Request>. This means that the order
of the headers will be as L<HTTP::Request> thinks and not as your
template prescribes.

=item * Only rudimentary testing has been done.

=item * The test suite uses L<Test::Base>, which uses L<Spiffy>. I
know I will rot in hell for that, but it was so convenient at the time.

Patches are welcome.

=back

=head1 REPORTING BUGS

If you find bugs, please report them via
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-Request-FromTemplate>
or, preferrably via mail to L<bug-HTTP-Request-FromTemplate@rt.cpan.org>.

=cut

__PACKAGE__->mk_accessors(qw(template tt));
our $content_length_cookie = __PACKAGE__ . "_content_length_cookie_";

sub new {
  my $class = shift;
  my %args;
  if (@_ == 1) {
    $args{template} = $_[0];
  } else {
    %args = @_;
  };

  $args{tt} ||= Template->new(delete $args{config} || {});

  return $class->SUPER::new(\%args);
};

sub process {
  my ($self,$data) = @_;

  my $replace_content_length_cookie;
  if (not exists $data->{content_length}) {
    $data->{content_length} = $content_length_cookie;
    $replace_content_length_cookie = 1;
  };

  $self->tt->process($self->template,$data, \(my $output));

  # This should also set the Content-Length properly.
  if ($replace_content_length_cookie) {
    if ($output =~ m!^(.*?)(?:\r?\n\r?\n)(.*)\Z!sm) {
      # We have content, so we should set the content length
      my $content_length = length $2;
      my $header_len = length $1;
      substr($output,0,$header_len) =~ s!$content_length_cookie!$content_length!gms;
    };
  };

  # This should also set/have a way for providing the Transfer-Encoding: chunked
  # in a proper fashion

  my $r = HTTP::Request->parse($output); # Wrong! This destroys the order of the headers :-(

  $r
};

1;

__END__

=head1 AUTHOR

Max Maischein (corion@cpan.org)

=head1 COPYRIGHT

Copyright (C) 2005 Max Maischein.  All Rights Reserved.

This code is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<LWP>,L<HTTP::Request>,Mozilla Live HTTP Headers