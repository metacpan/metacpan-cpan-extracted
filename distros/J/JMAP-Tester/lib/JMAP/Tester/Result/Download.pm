use v5.10.0;
use strict;

package JMAP::Tester::Result::Download;
# ABSTRACT: what you get when you download a blob
$JMAP::Tester::Result::Download::VERSION = '0.022';
use Moo;
with 'JMAP::Tester::Role::HTTPResult';

use namespace::clean;

#pod =head1 OVERVIEW
#pod
#pod This is what you get when you download!  It's got an C<is_success> method.  It
#pod returns true. It also has:
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

version 0.022

=head1 OVERVIEW

This is what you get when you download!  It's got an C<is_success> method.  It
returns true. It also has:

=head1 METHODS

=head2 bytes_ref

The raw bytes of the blob.

It also has a C<bytes_ref> method which will return a reference to the
raw bytes of the download.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by FastMail, Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
