use v5.20.0;

package JMAP::Tester::Result::Download 0.110;
# ABSTRACT: what you get when you download a blob

use Moo;
with 'JMAP::Tester::Role::HTTPResult';

use namespace::clean;

#pod =head1 OVERVIEW
#pod
#pod A JMAP::Tester::Result::Download object represents the successful download of a
#pod JMAP blob.  It is a successful L<JMAP::Tester::Role::HTTPResult>, meaning it
#pod has a C<http_response> method that returns an L<HTTP::Response> object.
#pod
#pod =method bytes_ref
#pod
#pod The raw bytes of the blob.
#pod
#pod It also has a C<bytes_ref> method which will return a reference to the
#pod raw bytes of the download.
#pod
#pod =cut

sub is_success { 1 }

has bytes_ref => (
  is   => 'ro',
  lazy => 1,
  default => sub {
    my $str = $_[0]->http_response->decoded_content(charset => 'none');
    return \$str;
  },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Result::Download - what you get when you download a blob

=head1 VERSION

version 0.110

=head1 OVERVIEW

A JMAP::Tester::Result::Download object represents the successful download of a
JMAP blob.  It is a successful L<JMAP::Tester::Role::HTTPResult>, meaning it
has a C<http_response> method that returns an L<HTTP::Response> object.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 METHODS

=head2 bytes_ref

The raw bytes of the blob.

It also has a C<bytes_ref> method which will return a reference to the
raw bytes of the download.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Fastmail Pty. Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
