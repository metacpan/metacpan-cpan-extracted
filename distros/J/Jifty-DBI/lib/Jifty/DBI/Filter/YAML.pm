use strict;
use warnings;

package Jifty::DBI::Filter::YAML;
use base qw/ Jifty::DBI::Filter /;

my ($Dump, $Load);

eval "use YAML::Syck ()";
if ($@) { 
    # We don't actually need to "use", which is checked at compile 
    # time and would cause error when YAML is not installed.
    # Or, eval this, too?
    require YAML;
    $Dump = \&YAML::Dump;
    $Load = \&YAML::Load;
}

else {
    $Dump = \&YAML::Syck::Dump;
    $Load = \&YAML::Syck::Load;
}

=head1 NAME

Jifty::DBI::Filter::YAML - This filter stores arbitrary Perl via YAML

=head1 SYNOPSIS

  use Jifty::DBI::Record schema {
      column my_data =>
          type is 'text',
          filters are qw/ Jifty::DBI::Filter::YAML /;
  };

  my $thing = __PACKAGE__->new;
  $thing->create( my_data => { foo => 'bar', baz => [ 1, 2, 3 ] } );

  my $my_data = $thing->my_data;
  while (my ($key, $value) = %$my_data) {
      # do something...
  }

=head1 DESCRIPTION

This filter provides the ability to store arbitrary data structures into a database column using L<YAML>. This is very similar to the L<Jifty::DBI::Filter::Storable> filter except that the L<YAML> format remains human-readable in the database. You can store virtually any Perl data, scalar, hash, array, or object into the database using this filter. 

In addition, YAML (at least the storage of scalars, hashes, and arrays) is compatible with data structures written in other languages, so you may store or read data between applications written in different languages.

=head1 METHODS

=head2 encode

This method is used to encode the Perl data structure into YAML formatted text.

=cut

sub encode {
    my $self = shift;

    my $value_ref = $self->value_ref;
    return unless defined $$value_ref;

    $$value_ref = $Dump->($$value_ref);
}

=head2 decode

This method is used to decode the YAML formatted text from the database into the Perl data structure.

=cut

sub decode {
    my $self = shift;

    my $value_ref = $self->value_ref;
    return unless defined $$value_ref;

    $$value_ref = $Load->($$value_ref);
}

=head1 IMPLEMENTATION

This class will attempt to use L<YAML::Syck> if it is available and then fall back upon L<YAML>. This has been done because the Syck library is written in C and is considerably faster.

=head1 SEE ALSO

L<Jifty::DBI::Filter>, L<YAML>, L<YAML::Syck>

=head1 AUTHOR

Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE

This program is free software and may be modified or distributed under the same terms as Perl itself.

=cut

1
