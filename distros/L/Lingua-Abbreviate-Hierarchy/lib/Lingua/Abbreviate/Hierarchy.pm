package Lingua::Abbreviate::Hierarchy;

use warnings;
use strict;

use Carp qw( croak );
use List::Util qw( min max );

=head1 NAME

Lingua::Abbreviate::Hierarchy - Shorten verbose namespaces

=head1 VERSION

This document describes Lingua::Abbreviate::Hierarchy version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

  use Lingua::Abbreviate::Hierarchy;
  my $abr = Lingua::Abbreviate::Hierarchy->new( keep => 1 );

  $abr->add_namespace(qw(
    comp.lang.perl.misc
    comp.lang.perl.advocacy
  ));

  # gets 'c.l.p.misc'
  my $clpm = $abr->ab('comp.lang.perl.misc');

  # abbreviate an array
  my @ab = $abr->ab(qw(
    comp.lang.perl.misc
    comp.lang.perl.advocacy
  ));

=head1 DESCRIPTION

It's a common practice to abbreviate the elements of namespaces
like this:

  comp.lang.perl.misc     -> c.l.p.misc
  comp.lang.perl.advocacy -> c.l.p.advocacy

This module performs such abbreviation. It guarantees that generated
abbreviations are long enough to be unique within the current namespace.

=head1 INTERFACE

To abbreviate names within a namespace use the module:

  use Lingua::Ab::H;   # use abbreviated name

Create a new abbreviator:

  my $abr = Lingua::Ab::H->new( keep => 1 );

Set up the namespace:

  $abr->add_namespace(qw(
    comp.lang.perl.misc
    comp.lang.perl.advocacy
  ));

Get your abbreviations:

  # gets 'c.l.p.misc'
  my $clpm = $abr->ab('comp.lang.perl.misc');

  # abbreviate an array
  my @ab = $abr->ab(qw(
    comp.lang.perl.misc
    comp.lang.perl.advocacy
  ));

Often the namespace will be larger; for example if you wanted to
generate abbreviations that would be unique within the entire
comp.lang.* hierarchy you would add all the terms in that space to the
abbreviator.

=head2 C<< new >>

Create a new abbreviator. Options may be passed as key, value pairs:

  my $abr = Lingua::Ab::H->new(
    keep => 1,
    sep => '::'
  );

The following options are recognised:

=over

=item C<< sep => >> I<string>

The string that separates components in the namespace. For example '.'
for domain names or '::' for Perl package names;

=item C<< only => >> I<number>

Abbreviate only the initial I<N> elements in the name.

=item C<< keep => >> I<number>

Leave I<N> elements at the end of the name unabbreviated.

=item C<< max => >> I<number>

Abbreviate from the left until the generated abbreviation contains I<N>
or fewer characters. If C<only> is specified then at least that many
elements will be abbreviated. If C<keep> is specified that many trailing
elements will be unabbreviated.

May return more than I<N> characters if the fully abbreviated name is
still too long.

=item C<< trunc => >> I<string>

A truncation string (which may be empty). When C<trunc> is supplied the
generated abbreviation will always be <= C<max> characters and will be
prefixed by the truncation string.

=item C<< flip => >> I<bool>

Normally we consider the namespace to be rooted at the left (like a
filename or package name). Set C<flip> to true to process right-rooted
namespaces (like domain names).

=item C<< ns => >> I<array ref>

Supply a reference to an array containing namespace terms. See
C<add_namespace> for more details.

=back

=cut

{
  my %DEFAULT = (
    sep   => '.',
    only  => undef,
    keep  => undef,
    max   => undef,
    trunc => undef,
    flip  => 0,
  );

  sub new {
    my ( $class, %options ) = @_;

    my $ns = delete $options{ns};
    my @unk = grep { !exists $DEFAULT{$_} } keys %options;
    croak "Unknown option(s): ", join ', ', sort @unk if @unk;
    my $self = bless { %DEFAULT, %options, ns => {} }, $class;
    @{$self}{ 'flipa', 'flips' }
     = $self->{flip}
     ? ( sub { reverse @_ }, sub { $_[0] } )
     : ( sub { @_ }, sub { scalar reverse $_[0] } );
    $self->add_namespace( $ns ) if defined $ns;
    return $self;
  }
}

=head2 C<< add_namespace >>

Add terms to the abbreviator's namespace:

  $abr->add_namespace( 'foo.com', 'bar.com' );

When abbreviating a term only those elements of the term that fall
within the namespace will be abbreviated. Elements outside the namespace
will be untouched.

=cut

sub add_namespace {
  my $self = shift;
  croak "Can't add to namespace after calling ab()"
   if $self->{cache};
  my $sepp = quotemeta $self->{sep};
  for my $term ( map { 'ARRAY' eq ref $_ ? @$_ : $_ } @_ ) {
    my @path = $self->{flipa}( split /$sepp/o, $term );
    $self->{ns} = $self->_add_node( $self->{ns}, @path );
  }
}

sub _add_node {
  my ( $self, $nd, $wd, @path ) = @_;
  $nd ||= {};
  $nd->{$wd} ||= {};
  if ( @path ) {
    $nd->{$wd}{k} = $self->_add_node( $nd->{$wd}{k}, @path );
  }
  else {
    $nd->{$wd}{t} = 1;
  }
  return $nd;
}

=head2 C<< ab >>

Abbreviate one or more terms:

  my $short = $abr->ab( 'this.is.a.long.name' );

Or with an array:

  my @short = $abr->ab( @long );

=cut

sub ab {
  my $self = shift;
  $self->_init unless $self->{cache};
  my @ab = map { $self->{cache}{$_} ||= $self->_abb( $_ ) } @_;
  return wantarray ? @ab : $ab[0];
}

sub _abb {
  my ( $self, $term ) = @_;

  my $sepp = quotemeta $self->{sep};
  my @path = $self->{flipa}( split /$sepp/, $term );
  my $join = $self->_join;
  my $abc  = sub {
    my ( $cnt, @path ) = @_;
    join $join,
     $self->{flipa}( $self->_ab( $self->{ns}, $cnt, @path ) );
  };

  if ( defined( my $max = $self->{max} ) ) {
    my $from = $self->{only} || 0;
    my $to = scalar( @path ) - ( $self->{keep} || 0 );
    my $ab = $term;
    for my $cnt ( $from .. $to ) {
      $ab = $abc->( $cnt, @path );
      return $ab if length $ab <= $max;
    }
    if ( defined( my $trunc = $self->{trunc} ) ) {
      my $flp = $self->{flips};
      my $trc = sub {
        my ( $tr, $a ) = @_;
        return substr $tr, 0, $max if length $tr > $max;
        return substr( $a, 0, $max - length $tr ) . $tr;
      };
      return $flp->( $trc->( $flp->( $trunc ), $flp->( $ab ) ) );
    }
    return $ab;
  }
  else {
    my $lt = scalar @path;
    $lt = max( $lt - $self->{keep}, 0 ) if defined $self->{keep};
    $lt = min( $lt, $self->{only} ) if defined $self->{only};
    return $abc->( $lt, @path );
  }
}

sub _ab {
  my ( $self, $nd, $limit, $word, @path ) = @_;
  return $word, @path if $limit-- <= 0;
  return $word, @path unless $nd && $nd->{$word};
  return ( $nd->{$word}{a},
    @path ? $self->_ab( $nd->{$word}{k}, $limit, @path ) : () );
}

=head2 C<ex>

Expand an abbreviation created by calling C<ab>. When applied to
abbreviations created in the current namespace C<ex> will reliably
expand arbitrary abbreviated terms. It will also pass through 
non-abbreviated terms unmolested.

If the namespace for expansion is not identical to the namespace for
abbreviation then the results are unpredictable.

  my @ab = $abr->ab( @terms );      # Abbreviate terms...
  my @ex = $abr->ex( @ab );         # ...and get them back

=cut

sub ex {
  my $self = shift;
  $self->_init_rev unless $self->{rev};
  my @ex = map { $self->{rcache}{$_} ||= $self->_exx( $_ ) } @_;
  return wantarray ? @ex : $ex[0];
}

sub _join {
  my $self = shift;
  return defined $self->{join} ? $self->{join} : $self->{sep};
}

sub _exx {
  my ( $self, $term ) = @_;
  my $sepp = quotemeta $self->_join;
  my @path = $self->{flipa}( split /$sepp/, $term );
  return join $self->{sep},
   $self->{flipa}( $self->_ab( $self->{rev}, scalar @path, @path ) );
}

sub _rev {
  my ( $self, $nd ) = @_;
  my $ond = {};
  while ( my ( $k, $v ) = each %$nd ) {
    my $nnd = { %$v, a => $k };
    $nnd->{k} = $self->_rev( $nnd->{k} ) if $nnd->{k};
    $ond->{ $v->{a} } = $nnd;
  }
  return $ond;
}

sub _init_rev {
  my $self = shift;
  $self->_init unless $self->{cache};
  $self->{rev} = $self->_rev( $self->{ns} );
}

sub _init {
  my $self = shift;
  $self->_make_ab( $self->{ns} );
  $self->{cache} = {};
}

# Given a list of unique terms return a hash mapping each term onto an
# equally unique abbreviation.
sub _ab_list {
  my ( $self, @w ) = @_;

  my %a   = ();
  my $len = 1;
  my @bad = @w;

  while () {
    $a{$_} = $len < length $_ ? substr $_, 0, $len : $_ for @bad;
    $len++;
    my %cc = ();
    $cc{ $a{$_} }++ for keys %a;
    @bad = grep { $cc{ $a{$_} } > 1 } keys %a;
    return \%a unless @bad;
  }
}

# Traverse the namespace tree making abbreviations for each node.
sub _make_ab {
  my ( $self, $nd ) = @_;
  my @kk = keys %$nd;
  my $ab = $self->_ab_list( @kk );
  for my $k ( @kk ) {
    $nd->{$k}{a} = $ab->{$k};
    $self->_make_ab( $nd->{$k}{k} ) if $nd->{$k}{k};
  }

}

"Ceci n'est pas 'Modern Perl'";

__END__

=head1 DEPENDENCIES

None.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-lingua-abbreviate-hierarchy@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
