#-----------------------------------------------------------------
# MOSES::MOBY::Data::Integer
# Author: Edward Kawas <edward.kawas@gmail.com>,
#         Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: Integer.pm,v 1.4 2008/04/29 19:35:57 kawas Exp $
#-----------------------------------------------------------------

package MOSES::MOBY::Data::Integer;
use base ("MOSES::MOBY::Data::Object");
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOSES::MOBY::Data::Integer - A primite Moby data type for integers

=head1 SYNOPSIS

 use MOSES::MOBY::Data::Integer;

 # create a Moby Integer with initial value of -15
 my $data = MOSES::MOBY::Data::Integer->new (value => -15);
 
 # set/get the value of this data object
 $data->value (79);
 print $data->value();

=head1 DESCRIPTION
	
An object representing an Integer, a Moby primitive data type.

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)
 Martin Senger (martin.senger [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------
# A list of allowed attribute names. See MOSES::MOBY::Base for details.
#-----------------------------------------------------------------

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<MOSES::MOBY::Base>. Here just a list of them (additionally
to the attributes from the parent classes)

=over

=item B<value>

A value of this datatype. Must be an integer.

=back

=cut

{
    my %_allowed =
	(
	 value  => {type => MOSES::MOBY::Base->INTEGER},
	 );

    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
}

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
    my ($self) = shift;
    $self->SUPER::init();
    $self->primitive ('yes');
}

1;
__END__
