use v5.10.0;
use strict;

package JMAP::Tester::Result::Logout;
# ABSTRACT: a successful logout
$JMAP::Tester::Result::Logout::VERSION = '0.016';
use Moo;
with 'JMAP::Tester::Role::Result';

use namespace::clean;

#pod =head1 OVERVIEW
#pod
#pod It's got an C<is_success> method.  It returns true.  Yup.
#pod
#pod =cut

sub is_success { 1 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Result::Logout - a successful logout

=head1 VERSION

version 0.016

=head1 OVERVIEW

It's got an C<is_success> method.  It returns true.  Yup.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by FastMail, Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
