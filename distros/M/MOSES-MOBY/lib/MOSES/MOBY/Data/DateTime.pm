#-----------------------------------------------------------------
# MOSES::MOBY::Data::DateTime
# Author: Edward Kawas <edward.kawas@gmail.com>,
#         Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: DateTime.pm,v 1.5 2008/11/06 18:41:40 kawas Exp $
#-----------------------------------------------------------------

package MOSES::MOBY::Data::DateTime;
use base ("MOSES::MOBY::Data::Object");
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOSES::MOBY::Data::DateTime - A primite Moby data type for dates/times

=head1 SYNOPSIS

 use MOSES::MOBY::Data::DateTime;

 # create a Moby DateTime
 my $data = MOSES::MOBY::Data::DateTime->new (value => '1994-11-05T08:15:30-05:00');
 my $data = MOSES::MOBY::Data::DateTime->new ('1994-11-05T08:15:30-05:00');
 
=head1 DESCRIPTION
	
An object representing a DateTime, a Moby primitive data type.

The value of this object is stored internally as a string, but upon
setting it, the validity is checked. The value should follow the W3C
profile of the ISO-8601 specification for specifying dates and
times. For example:

    1994-11-05T08:15:30-05:00

corresponds to November 5, 1994, 8:15:30 am, US Eastern Standard Time,
and

    1994-11-05T13:15:30Z

corresponds to the same instant.

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

A value of this datatype. Must be a string in a particular format.

=back

=cut

{
    my %_allowed =
	(
	 value  => {type => MOSES::MOBY::Base->DATETIME},
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
