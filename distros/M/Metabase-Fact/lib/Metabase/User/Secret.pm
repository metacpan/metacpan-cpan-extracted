use 5.006;
use strict;
use warnings;

package Metabase::User::Secret;

our $VERSION = '0.025';

use Metabase::Fact::String;
our @ISA = qw/Metabase::Fact::String/;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->set_creator( $self->resource ) unless $self->creator;
    return $self;
}

1;

# ABSTRACT: Metabase fact for user shared authentication secret

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::User::Secret - Metabase fact for user shared authentication secret

=head1 VERSION

version 0.025

=head1 SYNOPSIS

  my $secret = Metabase::User::Secret->new(
    resource => 'metabase:user:B66C7662-1D34-11DE-A668-0DF08D1878C0',
    content  => 'aixuZuo8',
  );

=head1 DESCRIPTION

This fact is a simple string, storing the shared secret that will be used to
authenticate user during fact submission.

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
