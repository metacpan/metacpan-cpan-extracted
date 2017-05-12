package LWP::UserAgent::CHICaching;

use 5.006000;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.04';

use Moo;

extends 'LWP::UserAgent';
with 'LWP::UserAgent::Role::CHICaching',
     'LWP::UserAgent::Role::CHICaching::SimpleKeyGen',
     'LWP::UserAgent::Role::CHICaching::SimpleMungeResponse';

1;


=pod

=encoding utf-8

=head1 NAME

LWP::UserAgent::CHICaching - LWP::UserAgent with caching based on CHI

=head1 SYNOPSIS

The usual way of using L<LWP::UserAgent>, really, just pass a C<cache>
parameter with a L<CHI> object to the constructor:

  my $cache = CHI->new( driver => 'Memory', global => 1 );
  my $ua = LWP::UserAgent::CHICaching->new(cache => $cache);
  my $res1 = $ua->get("http://localhost:3000/?query=DAHUT");

=head1 DESCRIPTION

This is YA caching user agent. When the client makes a request to the
server, sometimes the response should be cached, so that no actual
request has to be sent at all, or possibly just a request to validate
the cache. HTTP 1.1 defines how to do this. This class simply extends
L<LWP::UserAgent> with L<LWP::UserAgent::Role::CHICaching> (also in
this distribution) which is doing the real work to make it possible to
use the very flexible L<CHI> module to manage such a cache.

But why? Mainly because I wanted to use L<CHI> facilities, and partly
because I wanted to focus on HTTP 1.1 features.

=head1 TODO

This is an early release, but it supports RFC7234 quite well
already. Much work remains though. These are the things that I'd like
to do:

=over

=item * Enable smarter generation of keys, so that semantically
identical content can be cached efficiently even though they may have
different URIs. This can be done in a separate role with the current
code.

=item * Support all of L<RFC7234|http://tools.ietf.org/html/rfc7234>
and L<RFC7232|http://tools.ietf.org/html/rfc7232>

=back

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015, 2016 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

