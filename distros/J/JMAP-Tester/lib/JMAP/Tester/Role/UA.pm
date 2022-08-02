use v5.10.0;
use warnings;

package JMAP::Tester::Role::UA 0.102;

use Moo::Role;

# $ua->request( HTTP::Request ) returns Future( HTTP::Response )
requires qw( request );

# Is this a terrible idea?
requires qw( set_cookie );
requires qw( scan_cookies );

# Is this also a terrible idea?
requires qw( get_default_header );
requires qw( set_default_header );

no Moo::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Role::UA

=head1 VERSION

version 0.102

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by FastMail, Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
