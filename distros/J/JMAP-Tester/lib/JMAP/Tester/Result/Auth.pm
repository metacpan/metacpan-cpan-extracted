use v5.10.0;
use strict;

package JMAP::Tester::Result::Auth;
# ABSTRACT: what you get when you authenticate
$JMAP::Tester::Result::Auth::VERSION = '0.019';
use Moo;
with 'JMAP::Tester::Role::Result';

use namespace::clean;

#pod =head1 OVERVIEW
#pod
#pod This is what you get when you authenticate!  It's got an C<is_success> method.
#pod It returns true.
#pod
#pod =cut

sub is_success { 1 }

has client_session => (
  is => 'ro',
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Result::Auth - what you get when you authenticate

=head1 VERSION

version 0.019

=head1 OVERVIEW

This is what you get when you authenticate!  It's got an C<is_success> method.
It returns true.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by FastMail, Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
