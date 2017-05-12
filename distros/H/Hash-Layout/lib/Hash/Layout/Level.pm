package Hash::Layout::Level;
use strict;
use warnings;

# ABSTRACT: Level definition object for Hash::Layout

use Moo;
use Types::Standard qw(:all);

has 'index',     is => 'ro', isa => Int, required => 1;
has 'delimiter', is => 'ro', isa => Maybe[Str], default => sub {undef};

has 'name',      is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  return 'level-' . $self->index;
};

# Key names which we specifically expect to be at this level. This
# is a mechanism to resolve default/pad ambiguity when resolving
# composite key strings
has 'registered_keys', is => 'ro', isa => Maybe[
  Map[Str,Bool]
], coerce => \&_coerce_list_hash, default => sub {undef};


## TDB:
#has 'edge_keys', is => 'ro', isa => Maybe[
#  Map[Str,Bool]
#], coerce => \&_coerce_list_hash, default => sub {undef};
#
#has 'deep_keys', is => 'ro', isa => Maybe[
#  Map[Str,Bool]
#], coerce => \&_coerce_list_hash, default => sub {undef};
#
#has 'limit_keys', is => 'ro', isa => Bool, default => sub { 0 };



# Peel off the prefix key from a concatenated key string, according
# to this Level's delimiter:
sub _peel_str_key {
  my ($self,$key) = @_;
  
  return $key if (
    $self->registered_keys &&
    $self->registered_keys->{$key}
  );
  
  my $del = $self->delimiter or return undef;
  return undef unless ($key =~ /\Q${del}\E/);
  my ($peeled,$leftover) = split(/\Q${del}\E/,$key,2);
  return undef unless ($peeled && $peeled ne '');
  return ($leftover && $leftover ne '' && wantarray) ? 
    ($peeled,$leftover) : $peeled;
}

sub _coerce_list_hash {
  $_[0] && ! ref($_[0]) ? { $_[0] => 1 } :
  ref($_[0]) eq 'ARRAY' ? { map {$_=>1} @{$_[0]} } : $_[0];
}

1;

__END__

=pod

=head1 NAME

Hash::Layout::Level - Level definition object for Hash::Layout

=head1 DESCRIPTION

This class is used internally by L<Hash::Layout> and is not meant to be called directly. The list of
hashrefs supplied to the L<levels|Hash::Layout#new> param in the C<Hash::Layout> constructor are each
used as the constructor arguments passed to this class which create separate C<Hash::Layout::Level>
objects for each level.

Please refer to the main L<Hash::Layout> documentation for more info.

=head1 ATTRIBUTES

=head2 index

The index value of the level (first level is at index C<0>). This is automatically supplied
internally by C<Hash::Layout>.

=head2 name

An optional name/string value for this level. This is purely informational and is not currently
being used for anything.

=head2 delimiter

The character (or string) that is used by L<Hash::Layout> when resolving composite key strings
in to fully qualified key paths and identifying which part of the composite key should map to this level.

Defaults to a single forward-slash (C</>).

=head2 registered_keys

An optional list (ArrayRef coerced into HashRef) of keys that are associated specifically with
this level. Like C<delimiter>, this meta-data is used by L<Hash::Layout> purely for mapping the
sub-strings of a composite key to a specific level.

See the implementation of L<filter()|DBIx::Class::Schema::Diff#filter> in 
L<DBIx::Class::Schema::Diff> for the best example of how C<registered_keys> can be used.

=head1 SEE ALSO

=over

=item *

L<Hash::Layout>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
