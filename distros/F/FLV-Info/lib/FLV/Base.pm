package FLV::Base;

use warnings;
use strict;
use 5.008;
use Data::Dumper;
use List::MoreUtils qw(any);

our $VERSION = '0.24';

my $verbose = 0;

=head1 NAME

FLV::Base - Utility methods for other FLV::* classes

=head1 LICENSE

See L<FLV::Info>

=head1 METHODS

=over

=item $pkg->new()

Creates a new, generic instance.

=cut

sub new
{
   my $pkg = shift;
   return bless {}, $pkg;
}

# utility method called by sub class get_info() methods
# Arguments:
#   $prefix is a string that is inserted with an underscore before all outgoing info keys
#   $fields is a hashref
#           the key is a field name for the tag instances
#           the value is undef or a lookup hashref
#               the key is the tag instance field value
#               the value is a human-readable string
#   $tags   is an arrayref of tag instances
# See FLV::Info::get_info() for more discussion

sub _get_info
{
   my $pkg    = shift;
   my $prefix = shift;    # string
   my $fields = shift;    # hashref
   my $tags   = shift;    # arrayref

   my %complex;
   my %info = (count => scalar @{$tags});
   my %types = map { $_ => {} } keys %{$fields};
   for my $tag (@{$tags})
   {
      for my $field (keys %{$fields})
      {
         my $value = $tag->{$field};
         if (defined $value)
         {
            if (ref $value)
            {
               $value = q{\\} . Data::Dumper->Dump([$value], ['VAR']);
               $complex{$value} = $tag->{$field};
            }

            $types{$field}->{$value}++;
         }
      }
   }
   for my $field (keys %{$fields})
   {
      my $counts = $types{$field};
      my @list = reverse sort { $counts->{$a} <=> $counts->{$b} || $a cmp $b }
          keys %{$counts};
      my $lookup = $fields->{$field};
      if ($lookup)
      {
         @list = map { $lookup->{$_} } @list;
      }
      if (any { m/\A\\/xms } @list)
      {
         $info{$field} = 1 == @list ? $complex{ $list[0] } : '<complex data>';
      }
      else
      {
         $info{$field} = join q{/}, @list;
      }
   }
   return map { $prefix . q{_} . $_ => $info{$_} } keys %info;
}

# This is only meaningful for FLV::*Tag classes.  See FLV::Tag::parse()
sub _pos
{
   my $self = shift;
   return $self->{_pos};
}

1;

__END__

=back

=head1 AUTHOR

See L<FLV::Info>

=cut
