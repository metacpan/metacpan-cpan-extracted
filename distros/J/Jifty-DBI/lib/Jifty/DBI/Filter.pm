use warnings;
use strict;

package Jifty::DBI::Filter;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(record column value_ref handle));

=head1 NAME

Jifty::DBI::Filter - base class for Jifty::DBI filters

=head1 SYNOPSIS

  # To implement your own filter
  package MyApp::Filter::Uppercase;
  use base qw/ Jifty::DBI::Filter /;

  # Setup for DB storage, store in lowercase
  sub encode {
      my $self = shift;

      my $value_ref = $self->value_ref;
      return unless defined $$value_ref; # don't blow up on undef

      $$value_ref = lc $$value_ref;
  }

  # Setup for Perl code to use, always sees uppercase
  sub decode {
      my $self = shift;

      my $value_ref = $self->value_ref;
      return unless defined $$value_ref; # don't blow up on undef

      $$value_ref = uc $$value_ref;
  }

  # To use a filter
  use MyApp::Record schema {
      column filtered =>
          type is 'text',
          filters are qw/ MyApp::Filter::Uppercase /;
  };


=head1 DESCRIPTION

A filter allows Jifty::DBI models to tweak data prior to being stored and/or loaded. This is useful for marshalling and unmarshalling complex objects.

=head1 METHODS

=head2 new

Takes three arguments in a parameter hash:

=over

=item value_ref

A reference to the current value you're going to be
massaging. C<encode> works in place, massaging whatever value_ref
refers to.

=item column

A L<Jifty::DBI::Column> object, whatever sort of column we're working
with here.

=item handle

A L<Jifty::DBI::Handle> object, because some filters (i.e.
L<Jifty::DBI::Filter::Boolean>) depend on what database system is being used.

=back

=cut

sub new {
    my $class = shift;
    my %args  = (
        column    => undef,
        value_ref => undef,
        handle    => undef,
        @_
    );
    my $self = $class->SUPER::new( {
        record    => delete $args{record},
        column    => delete $args{column},
        value_ref => delete $args{value_ref},
        handle    => delete $args{handle},
    } );
    
    for ( grep $self->can($_), keys %args ) {
        $self->$_( $args{$_} );
    }

    return ($self);
}

=head2 encode

C<encode> takes data that users are handing to us and marshals it into
a form suitable for sticking it in the database. This could be anything
from flattening a L<DateTime> object into an ISO date to making sure
that data is utf8 clean.

=cut

sub encode {

}

=head2 decode

C<decode> takes data that the database is handing back to us and gets
it into a form that's OK to hand back to the user. This could be
anything from inflating an ISO date to a L<DateTime> object to
making sure that the string properly has the utf8 flag.

=cut

sub decode {

}

=head1 SEE ALSO

L<Jifty::DBI::Filter::Date>, L<Jifty::DBI::Filter::DateTime>, L<Jifty::DBI::Filter:SaltHash>, L<Jifty::DBI::Filter::Storable>, L<Jifty::DBI::Filter::Time>, L<Jifty::DBI::Filter::Truncate>, L<Jifty::DBI::Filter::YAML>, L<Jifty::DBI::Filter::base64>, L<Jifty::DBI::Filter::utf8>

=head1 LICENSE

Jifty::DBI is Copyright 2005-2007 Best Practical Solutions, LLC.
Jifty::DBI is distributed under the same terms as Perl itself.

=cut

1;
