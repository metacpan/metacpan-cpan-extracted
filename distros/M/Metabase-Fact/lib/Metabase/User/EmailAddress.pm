use 5.006;
use strict;
use warnings;

package Metabase::User::EmailAddress;

our $VERSION = '0.025';

use Metabase::Fact::String;
our @ISA = qw/Metabase::Fact::String/;

1;

# ABSTRACT: Metabase fact for user email address

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::User::EmailAddress - Metabase fact for user email address

=head1 VERSION

version 0.025

=head1 SYNOPSIS

  my $email = Metabase::User::EmailAddress->new(
    resource => 'metabase:user:B66C7662-1D34-11DE-A668-0DF08D1878C0',
    content => 'jdoe@example.com',
  );

=head1 DESCRIPTION

This is a simple string fact meant to be used to represent the email address of
a user.

At present, no email address validation is performed, but this may change in
the future.

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted through the web interface at 
L<http://rt.cpan.org/Dist/Display.html?Queue=Metabase-Fact>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

H.Merijn Brand <hmbrand@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
