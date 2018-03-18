use v5.10.0;
use strict;

package JMAP::Tester::Result::Failure;
# ABSTRACT: what you get when your JMAP request utterly fails
$JMAP::Tester::Result::Failure::VERSION = '0.018';
use Moo;
with 'JMAP::Tester::Role::Result';

use namespace::clean;

#pod =head1 OVERVIEW
#pod
#pod This is the sort of worthless object you get back when your JMAP request fails.
#pod This class should be replaced, in most cases, by more useful classes in the
#pod future.
#pod
#pod It's got an C<is_success> method.  It returns false.
#pod
#pod =cut

sub is_success { 0 }

has ident => (is => 'ro', predicate => 'has_ident');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Result::Failure - what you get when your JMAP request utterly fails

=head1 VERSION

version 0.018

=head1 OVERVIEW

This is the sort of worthless object you get back when your JMAP request fails.
This class should be replaced, in most cases, by more useful classes in the
future.

It's got an C<is_success> method.  It returns false.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by FastMail, Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
