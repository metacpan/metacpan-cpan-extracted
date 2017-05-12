use 5.006;    # our
use strict;
use warnings;

package Git::Wrapper::Plus::Support::Range;

our $VERSION = '0.004011';

# ABSTRACT: A record describing a range of supported versions

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY



















use Moo qw( has );

our @CARP_NOT;



























has 'min' => ( is => ro =>, predicate => 'has_min' );
has 'max' => ( is => ro =>, predicate => 'has_max' );

has 'min_tag' => ( is => ro =>, predicate => 'has_min_tag' );
has 'max_tag' => ( is => ro =>, predicate => 'has_max_tag' );

has 'min_sha1' => ( is => ro =>, predicate => 'has_min_sha1' );
has 'max_sha1' => ( is => ro =>, predicate => 'has_max_sha1' );






sub BUILD {
  my ($self) = @_;
  if ( not $self->min and not $self->max ) {
    require Carp;
    ## no critic (Variables::ProhibitLocalVars)
    local (@CARP_NOT) = ('Git::Wrapper::Plus::Support::Range');
    Carp::croak('Invalid range, must specify either min or max, or both');
  }
}














sub supports_version {
  my ( $self, $versions_object ) = @_;
  if ( $self->has_min and not $self->has_max ) {
    return 1 if $versions_object->newer_than( $self->min );
    return;
  }
  if ( $self->has_max and not $self->has_min ) {
    return 1 if $versions_object->older_than( $self->max );
    return;
  }
  return unless $versions_object->newer_than( $self->min );
  return unless $versions_object->older_than( $self->max );
  return 1;
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Wrapper::Plus::Support::Range - A record describing a range of supported versions

=head1 VERSION

version 0.004011

=head1 SYNOPSIS

    my $range = Git::Wrapper::Plus::Support::Range->new(
        min => '1.5.0',
        # min_sha1 => ...
        # min_tag  => ...
        max => '1.6.0',
        # max_sha1 => ...
        # max_tag  => ...
    );
    if ( $range->supports_version( $gwp->versions ) ) {
        print "Some feature is supported!"
    }

B<NOTE:> Either C<min> or C<max> is mandatory, or both.

=head1 METHODS

=head2 C<supports_version>

Determines if the given range supports a version or not.

    my $gg = Git::Wrapper::Plus->new( ... );
    my $range =  ...;
    if ( $range->supports_version( $gg->versions ) ) {
        $range is supported
    }

=head1 ATTRIBUTES

=head2 C<min>

The minimum version this range supports

=head2 C<max>

The maximum version this range supports

=head2 C<min_tag>

The minimum tag that contained C<min_sha1>. Annotative only, not used.

=head2 C<max_tag>

The first tag that contained C<max_sha1>. Annotative only, not used.

=head2 C<min_sha1>

The C<sha1> this feature was added in. Annotative only, not used.

=head2 C<max_sha1>

The C<sha1> this feature was removed in. Annotative only, not used.

=for Pod::Coverage::TrustPod BUILD has_max has_max_sha1 has_max_tag has_min has_min_sha1 has_min_tag

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
