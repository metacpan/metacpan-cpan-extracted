package Geo::TigerLine::Record::Accessor;

use strict;
use vars qw($VERSION);
$VERSION = '0.03';

use base qw(Class::Accessor Class::Data::Inheritable);

use Carp::Assert;


=pod

=head1 NAME

Geo::TigerLine::Record::Accessor - Accessor generation for Geo::TigerLine::Record::*

=head1 SYNOPSIS

  package Geo::TigerLine::Record::1001001;

  use base qw(Geo::TigerLine::Record::Accessor);

  # Generate accessors for each field of the record.
  foreach my $def (values %{__PACKAGE__->Fields}) {
      __PACKAGE__->mk_accessor($def);
  }

  # Turn off input checks, makes inserting raw data faster.
  __PACKAGE__->input_checks(0);

=head1 DESCRIPTION

Allows accessor generation for all the fields of each TIGER/Line record type.
You probabably shouldn't be here.

This is a subclass of Class::Accessor.

=cut

#'#
{
    no strict 'refs';

    sub mk_accessor {
        my($self, $def) = @_;
        
        my $class = ref $self || $self;
        my $field = $def->{field};

        if( $field eq 'DESTROY' ) {
            require Carp;
            &Carp::carp("Having a data accessor named DESTROY  in ".
                        "'$class' is unwise.");
        }

        my $accessor = $self->make_accessor($def);
        my $alias = "_${field}_accessor";
            
        *{$class."\:\:$field"}  = $accessor
          unless defined &{$class."\:\:$field"};
            
        *{$class."\:\:$alias"}  = $accessor
          unless defined &{$class."\:\:$alias"};
    }
}


sub get {
    my($self, $def) = @_;
    return $self->{$def->{field}};
}


sub set {
    my($self, $def, $val) = @_;

    if( $self->input_check ) {
        if ( $val !~ /\S/ && !$def->{bv} ) {
            Carp::carp("$def->{field} is not allowed to be blank.");
        }
        
        if ( $val =~ /[^\d+\-]/ && $def->{type} eq 'N' ) {
            Carp::carp("$def->{field} can contain only numbers.  ('$val')");
        }
        
        if ( $val =~ /[^A-Z'\/()&\d+\-\]\[\# ]/i ) { #']) {
            Carp::carp("$def->{field} can only contain alphanumeric ".
                       "characters.  ('$val')");
        }
        
        if ( length $val > $def->{len} ) {
            Carp::carp("$def->{field} can only be $def->{len} characters long.  ".
                       "('$val')");
        }
    }

    $self->{$def->{field}} = $val;
}

=head2 Additional Methods

=over 4

=item B<input_check>

  Class->input_check($true_or_false);
  $true_or_false = Class->input_check;
  $true_or_false = $obj->input_check;

If true, turns on the input checks done each time a value is set.
False turns them off.

This setting is inherited.

By default, the checks are on.

=cut

#'#
__PACKAGE__->mk_classdata('__Input_Check');
__PACKAGE__->input_check(1);       # Start out doing the checks.
sub input_check {
    my($class) = shift;
    my($check) = @_;

    if( @_ ) {
        assert( !ref $class ) if DEBUG;
        $class->__Input_Check($check);
    }
    else {
        $check = $class->__Input_Check;
    }

    return $check;
}

=pod

=back

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Class::Accessor>, L<Geo::TigerLine::Record>

=cut


return 'Bloody balls up';
