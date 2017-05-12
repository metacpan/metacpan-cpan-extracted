use 5.006;
use strict;
use warnings;

package Metabase::User::FullName;

our $VERSION = '0.025';

use Metabase::Fact::String;
our @ISA = qw/Metabase::Fact::String/;

1;

# ABSTRACT: Metabase fact for user full name

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::User::FullName - Metabase fact for user full name

=head1 VERSION

version 0.025

=head1 SYNOPSIS

  my $email = Metabase::User::FullName->new(
    resource => 'metabase:user:B66C7662-1D34-11DE-A668-0DF08D1878C0',
    content => 'John Doe',
  );

=head1 DESCRIPTION

This is just a simple string fact that stores the real name of a user in his
profile.

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
