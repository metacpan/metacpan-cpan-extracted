#==============================================================================
# LibWeb::Class -- A base class for libweb modules.

package LibWeb::Class;

# Copyright (C) 2000  Colin Kong
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#=============================================================================

# $Id: Class.pm,v 1.4 2000/07/18 06:33:30 ckyc Exp $

#-#############################
# Use standard library.
require 5.004;
use strict;
use vars qw($VERSION);

$VERSION = '0.02';

#-#############################
# Methods.
sub new {
    my $class = shift;
    bless( {}, ref($class) || $class );
}

sub DESTROY {}

sub rearrange {
    #
    # Stolen from CGI.pm and modified.
    #
    # Smart rearrangement of parameters to allow named parameter
    # calling.  We do the rearrangement if:
    # 1. The first parameter begins with a -
    #
    my($self,$order,@param) = @_;
    return () unless @param;

    if (ref($param[0]) eq 'HASH') {
	@param = %{$param[0]};
    } else {
	return @param 
	    unless (defined($param[0]) && substr($param[0],0,1) eq '-');
    }

    # map parameters into positional indices
    my ($i,%pos);
    $i = 0;
    foreach (@$order) {
	foreach (ref($_) eq 'ARRAY' ? @$_ : $_) { $pos{$_} = $i; }
	$i++;
    }

    my (@result);                          #leave out %leftover.
    $#result = $#$order;                   #preextend
    while (@param) {
	my $key = uc(shift(@param));         #uc(shift(@param));
	$key =~ s/^\-//;
	$result[$pos{$key}] = shift(@param) if (exists $pos{$key});
	#} else {
	#    $leftover{$key} = shift(@param);
	#}
    }

    #push (@result,$self->make_attributes(\%leftover)) if %leftover;
    return @result;
}

1;
__DATA__

1;
__END__

=head1 NAME

LibWeb::Class - A base class for libweb modules

=head1 SUPPORTED PLATFORMS

=over 2

=item BSD, Linux, Solaris and Windows.

=back

=head1 REQUIRE

=over 2

=item *

perl 5.004

=back

=head1 ISA

=over 2

=item *

None

=back

=head1 SYNOPSIS

  require LibWeb::Class;
  @ISA = qw(LibWeb::Class);

=head1 ABSTRACT

This class contains common object-oriented methods inherited by all
LibWeb modules.  It is intended to be ISA by LibWeb modules and
extensions and not used by client codes outside LibWeb.

The current version of LibWeb::Class is available at

   http://libweb.sourceforge.net

Several LibWeb applications (LEAPs) have be written, released and are
available at

   http://leaps.sourceforge.net

=head1 DESCRIPTION

=head2 METHODS

=over 2

=item B<rearrange()>

=back

This is not really OO related but makes LibWeb's API look sexy.  This
is stolen from CGI.pm and modified.  It allows smart rearrangement of
parameters for named parameter calling.  This does the rearrangement
if the first parameter begins with a `-'.  For example,

  sub your_class_method {

      my $self = shift;
      my ($parameter1, $parameter2, $parameter3);
        = $self->rearrange( ['PARA1', 'PARA2', 'PARA3'], @_ );

      ....

  }

and your method will be called as

  use your_class;
  my $object = new your_class();

  $object->your_class_method( 
                              -para1 => $para1,
                              -para2 => $para2,
                              -para3 => $para3
                            );

=head1 AUTHORS

=over 2

=item Colin Kong (colin.kong@toronto.edu)

=back

=head1 CREDITS

=over 2

=item Lincoln Stein (lstein@cshl.org)

=back

=head1 BUGS

=head1 SEE ALSO

=cut
