use v5.10.0;
use strict;

package JMAP::Tester::Result::Download;
# ABSTRACT: what you get when you download a blob
$JMAP::Tester::Result::Download::VERSION = '0.020';
use Moo;
with 'JMAP::Tester::Role::Result';

use namespace::clean;

#pod =head1 OVERVIEW
#pod
#pod This is what you get when you download!  It's got an C<is_success> method.  It
#pod returns true.
#pod
#pod =cut

sub is_success { 1 }

has bytes_ref => (
  is   => 'ro',
  lazy => 1,
  default => sub {
    my $str = $_[0]->http_response->decoded_content(charset => 'none');
    return $str;
  },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Result::Download - what you get when you download a blob

=head1 VERSION

version 0.020

=head1 OVERVIEW

This is what you get when you download!  It's got an C<is_success> method.  It
returns true.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by FastMail, Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
