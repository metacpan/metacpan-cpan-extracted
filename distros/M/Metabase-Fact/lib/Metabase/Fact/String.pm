use 5.006;
use strict;
use warnings;

package Metabase::Fact::String;

our $VERSION = '0.025';

use Carp ();

use Metabase::Fact;
our @ISA = qw/Metabase::Fact/;

# document that content must be characters, not bytes -- dagolden, 2009-03-28

sub validate_content {
    my ($self) = @_;
    Carp::confess "content must be scalar value"
      unless defined $self->content && ref \( $self->content ) eq 'SCALAR';
}

sub content_as_bytes {
    my ($self) = @_;
    my $bytes = $self->content;
    utf8::encode($bytes) if $] ge '5.008'; # converts in-place
    return $bytes;
}

sub content_from_bytes {
    my ( $class, $bytes ) = @_;
    utf8::decode($bytes) if $] ge '5.008'; # converts in-place
    return $bytes;
}

1;

# ABSTRACT: fact subtype for simple strings

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::Fact::String - fact subtype for simple strings

=head1 VERSION

version 0.025

=head1 SYNOPSIS

  # defining the fact class
  package MyFact;
  use Metabase::Fact::String;
  our @ISA = qw/Metabase::Fact::String/;

  sub content_metadata {
    my $self = shift;
    return {
      'size' => [ '//num' => length $self->content ],
    };
  }

  sub validate_content {
    my $self = shift;
    $self->SUPER::validate_content;
    die __PACKAGE__ . " content length must be greater than zero\n"
      if length $self->content < 0;
  }

...and then...

  # using the fact class
  my $fact = MyFact->new(
    resource => 'RJBS/Metabase-Fact-0.001.tar.gz',
    content  => "Hello World",
  );

  $client->send_fact($fact);

=head1 DESCRIPTION

Base class for facts that are just strings of text.  Strings must be
characters, not bytes.

You may wish to implement a C<content_metadata> method to generate metadata
about the hash contents.

You should also implement a C<validate_content> method to validate the
structure of the hash you're given.

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
