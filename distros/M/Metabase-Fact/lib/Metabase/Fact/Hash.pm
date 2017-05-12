use 5.006;
use strict;
use warnings;

package Metabase::Fact::Hash;

our $VERSION = '0.025';

use Carp ();
use JSON::MaybeXS ();

use Metabase::Fact;
our @ISA = qw/Metabase::Fact/;

sub validate_content {
    my ($self)  = @_;
    my $content = $self->content;
    my $class   = ref $self;
    Carp::confess "content must be a hashref"
      unless ref $content eq 'HASH';
    my $get_req = $self->can('required_keys') || sub { () };
    my $get_opt = $self->can('optional_keys') || sub { () };
    # find missing
    my @missing = grep { !exists $content->{$_} } $get_req->();
    Carp::croak "missing required keys for $class\: @missing\n" if @missing;
    # check for invalid
    my %valid = map { $_ => 1 } ( $get_req->(), $get_opt->() );
    my @invalid = grep { !exists $valid{$_} } keys %$content;
    Carp::croak "invalid keys for $class\: @invalid\n" if @invalid;
    return 1;
}

sub content_as_bytes {
    my ($self) = @_;
    return JSON::MaybeXS->new(ascii => 1)->encode( $self->content );
}

sub content_from_bytes {
    my ( $class, $bytes ) = @_;
    return JSON::MaybeXS->new(ascii => 1)->decode($bytes);
}

1;

# ABSTRACT: fact subtype for simple hashes

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::Fact::Hash - fact subtype for simple hashes

=head1 VERSION

version 0.025

=head1 SYNOPSIS

  # defining the fact class
  package MyComment;
  use Metabase::Fact::Hash;
  our @ISA = qw/Metabase::Fact::Hash/;

  sub required_keys { qw/poster/ }

  sub optional_keys { qw/comment/ }

  sub content_metadata {
    my $self = shift;
    return {
      poster => [ '//str' => $self->content->{poster} ],
    };
  }

  sub validate_content {
    my $self = shift;
    $self->SUPER::validate_content; # required and optional keys

    # other analysis of values
  }

...and then...

  # using the fact class
  my $fact = MyFact->new(
    resource => 'RJBS/Metabase-Fact-0.001.tar.gz',
    content => {
      poster  => 'larry',
      comment => 'Metabase rocks!',
    }
  );

  $client->send_fact($fact);

=head1 DESCRIPTION

Many (if not most) facts to be stored in a Metabase are just hashes of simple
data.  Metabase::Fact::Hash is a subclass of L<Metabase::Fact|Metabase::Fact>
with most of the required Fact methods already implemented.  If you write your
class as a subclass of Metabase::Fact::Hash, you can store simple hashes in it.

You should implement C<required_keys> and/or C<optional_keys> as shown in the
SYNOPSIS.  The superclass C<valiate_content> will ensure that required keys
exist and that only required an optional keys exist.  You may wish to subclass
C<validate_content> to validate the specific content of the hash given to the
constructor.

You may wish to implement a C<content_metadata> method to generate metadata
about the hash contents.

=head1 ATTRIBUTES

=head2 Arguments provided to new

=head3 resource

B<required>

The canonical resource (URI) the Fact relates to.  For CPAN distributions, this
would be a C<cpan:///distfile/> URL.  (See L<URI::cpan>.)

=head3 content

B<required>

A reference to the actual information associated with the fact.
The exact form of the content is up to each Fact class to determine.

=head1 METHODS

For information on the methods provided by this class, see
L<Metabase::Fact|Metabase::Fact>.

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.
Bugs can be submitted through the web interface at
L<http://rt.cpan.org/Dist/Display.html?Queue=Metabase-Fact>

When submitting a bug or request, please include a test file or a patch to an
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
