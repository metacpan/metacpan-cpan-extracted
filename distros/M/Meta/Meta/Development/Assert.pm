#!/bin/echo This is a perl module and should not be run

package Meta::Development::Assert;

use strict qw(vars refs subs);
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.00";
@ISA=qw();

#sub assert_true($$);
#sub assert_false($$);
#sub assert_eq($$$);
#sub assert_ne($$$);
#sub assert_ge($$$);
#sub assert_gt($$$);
#sub assert_le($$$);
#sub assert_lt($$$);
#sub assert_seq($$$);
#sub assert_sne($$$);
#sub assert_isa($$$);
#sub is_number($);
#sub TEST($);

#__DATA__

sub assert_true($$) {
	my($val,$msg)=@_;
	if(!$val) {
		throw Meta::Error::Simple("value [".$val."] should be true [".$msg."]");
	}
}

sub assert_false($$) {
	my($val,$msg)=@_;
	if($val) {
		throw Meta::Error::Simple("value [".$val."] should be false [".$msg."]");
	}
}

sub assert_eq($$$) {
	my($one,$two,$msg)=@_;
	if($one!=$two) {
		throw Meta::Error::Simple("[".$one."]!=[".$two."] [".$msg."]");
	}
}

sub assert_ne($$$) {
	my($one,$two,$msg)=@_;
	if($one==$two) {
		throw Meta::Error::Simple("[".$one."]==[".$two."] [".$msg."]");
	}
}

sub assert_ge($$$) {
	my($one,$two,$msg)=@_;
	if($one<$two) {
		throw Meta::Error::Simple("[".$one."]<[".$two."] [".$msg."]");
	}
}

sub assert_gt($$$) {
	my($one,$two,$msg)=@_;
	if($one<=$two) {
		throw Meta::Error::Simple("[".$one."]<=[".$two."] [".$msg."]");
	}
}

sub assert_le($$$) {
	my($one,$two,$msg)=@_;
	if($one>$two) {
		throw Meta::Error::Simple("[".$one."]>[".$two."] [".$msg."]");
	}
}

sub assert_lt($$$) {
	my($one,$two,$msg)=@_;
	if($one>=$two) {
		throw Meta::Error::Simple("[".$one."]>=[".$two."] [".$msg."]");
	}
}

sub assert_seq($$$) {
	my($one,$two,$msg)=@_;
	if($one ne $two) {
		throw Meta::Error::Simple("[".$one."] ne [".$two."] [".$msg."]");
	}
}

sub assert_sne($$$) {
	my($one,$two,$msg)=@_;
	if($one eq $two) {
		throw Meta::Error::Simple("[".$one."] eq [".$two."] [".$msg."]");
	}
}

sub assert_isa($$$) {
	my($object,$type,$msg)=@_;
	if(!$object->isa($type)) {
		throw Meta::Error::Simple("object [".$object."] not of type [".$type."] [".$msg."]");
	}
}

sub is_number($) {
	my($num)=@_;
	if($num!~/\d+/) {
		throw Meta::Error::Simple("string [".$num."] is not a number");
	}
}

sub TEST($) {
	my($context)=@_;
	Meta::Develop::Assert::assert_eq(3+4,7);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Development::Assert - object to inherit verbose objects from.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: Assert.pm
	PROJECT: meta
	VERSION: 0.00

=head1 SYNOPSIS

	package foo;
	use Meta::Development::Assert qw();
	Meta::Development::Assert::assert_meq(3+4,7);

=head1 DESCRIPTION

This module is a set of functions to ease making assertions in the
code and handling the result of a failed assertion in a centralized
manner. The modules default behaviour is to throw an Error::Simple
exception whenever an assertion fails.

=head1 FUNCTIONS

	assert_true($$)
	assert_false($$)
	assert_eq($$$)
	assert_ne($$$)
	assert_ge($$$)
	assert_gt($$$)
	assert_le($$$)
	assert_lt($$$)
	assert_seq($$$)
	assert_sne($$$)
	assert_isa($$$)
	is_number($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<assert_true($$)>

Assert that the value passed is indeed true.

=item B<assert_false($$)>

Assert that the value passed is indeed false.

=item B<assert_eq($$$)>

Assert that two numerical values are equal.

=item B<assert_ne($$$)>

Assert that two numerical values are different.

=item B<assert_ge($$$)>

Assert that one numeric value is greater or equal to the other.

=item B<assert_gt($$$)>

Assert that one numeric value is greater than the other.

=item B<assert_le($$$)>

Assert that one numeric value is less or equal to the other.

=item B<assert_lt($$$)>

Assert that one numeric value is less than the other.

=item B<assert_seq($$$)>

Assert that two values are the same string.

=item B<assert_sne($$$)>

Assert that two values are not the same string.

=item B<assert_isa($$$)>

Assert that an object is of a certain type.

=item B<is_number($)>

Assert that the string given is a number.

=item B<TEST($)>

This is a testing suite for the Meta::Development::Assert module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

Currently this test suite just makes a simple assertion.

=back

=head1 SUPER CLASSES

None.

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV md5 issues

=head1 SEE ALSO

Error(3), strict(3)

=head1 TODO

Nothing.
