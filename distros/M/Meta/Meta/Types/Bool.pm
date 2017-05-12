#!/bin/echo This is a perl module and should not be run

package Meta::Types::Bool;

use strict qw(vars refs subs);
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.00";
@ISA=qw();

#sub new($);
#sub new_value($$);
#sub set_value($$);
#sub get_value($);
#sub new_version($$$);
#sub set_version($$$);
#sub get_version($$);
#sub not($);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)={};
	CORE::bless($self,$class);
	$self->set_value(1);
	return($self);
}

sub new_value($$) {
	my($class,$val)=@_;
	my($self)={};
	CORE::bless($self,$class);
	$self->set_value($val);
	return($self);
}

sub set_value($$) {
	my($self,$val)=@_;
	if($val) {
		$self->{VAL}=1;
	} else {
		$self->{VAL}=0;
	}
}

sub get_value($) {
	my($self)=@_;
	return($self->{VAL});
}

sub new_version($) {
	my($class,$version,$val)=@_;
	my($self)={};
	CORE::bless($self,$class);
	$self->set_version($version,$val);
	return($self);
}

sub set_version($$$) {
	my($self,$version,$val)=@_;
	if($version eq "of") {
		if($val eq "ok") {
			$self->{VAL}=1;return;
		}
		if($val eq "failed") {
			$self->{VAL}=0;return;
		}
		throw Meta::Error::Simple("what kind of a value is [".$val."]");
	}
	if($version eq "yn") {
		if($val eq "y") {
			$self->{VAL}=1;return;
		}
		if($val eq "n") {
			$self->{VAL}=0;return;
		}
		throw Meta::Error::Simple("what kind of a value is [".$val."]");
	}
	if($version eq "tf") {
		if($val eq "t") {
			$self->{VAL}=1;return;
		}
		if($val eq "f") {
			$self->{VAL}=0;return;
		}
		throw Meta::Error::Simple("what kind of a value is [".$val."]");
	}
	if($version eq "YN") {
		if($val eq "yes") {
			$self->{VAL}=1;return;
		}
		if($val eq "no") {
			$self->{VAL}=0;return;
		}
		throw Meta::Error::Simple("what kind of a value is [".$val."]");
	}
	if($version eq "TF") {
		if($val eq "true") {
			$self->{VAL}=1;return;
		}
		if($val eq "false") {
			$self->{VAL}=0;return;
		}
		throw Meta::Error::Simple("what kind of a value is [".$val."]");
	}
	if($version eq "01") {
		if($val eq "1") {
			$self->{VAL}=1;return;
		}
		if($val eq "0") {
			$self->{VAL}=0;return;
		}
		throw Meta::Error::Simple("what kind of a value is [".$val."]");
	}
	throw Meta::Error::Simple("what kind of a version is [".$version."]");
}

sub get_version($$) {
	my($self,$version)=@_;
	if($version eq "of") {
		if($self->{VAL} eq "1") {
			return("ok");
		}
		if($self->{VAL} eq "0") {
			return("failed");
		}
		throw Meta::Error::Simple("what kind of a value is [".$self->{VAL}."]");
	}
	if($version eq "yn") {
		if($self->{VAL} eq "1") {
			return("y");
		}
		if($self->{VAL} eq "0") {
			return("m");
		}
		throw Meta::Error::Simple("what kind of a value is [".$self->{VAL}."]");
	}
	if($version eq "tf") {
		if($self->{VAL} eq "1") {
			return("t");
		}
		if($self->{VAL} eq "0") {
			return("f");
		}
		throw Meta::Error::Simple("what kind of a value is [".$self->{VAL}."]");
	}
	if($version eq "TF") {
		if($self->{VAL} eq "1") {
			return("true");
		}
		if($self->{VAL} eq "0") {
			return("false");
		}
		throw Meta::Error::Simple("what kind of a value is [".$self->{VAL}."]");
	}
	if($version eq "YN") {
		if($self->{VAL} eq "1") {
			return("yes");
		}
		if($self->{VAL} eq "0") {
			return("no");
		}
		throw Meta::Error::Simple("what kind of a value is [".$self->{VAL}."]");
	}
	if($version eq "01") {
		return($self->{VAL});
	}
	throw Meta::Error::Simple("what kind of version is [".$version."]");
}

sub not($) {
	my($self)=@_;
	if($self->{VAL}) {
		$self->{VAL}=0;
	} else {
		$self->{VAL}=1;
	}
}

sub TEST($) {
	my($context)=@_;
	my($object)=__PACKAGE__->new_version("tf","t");
	Meta::Utils::Output::print("yn value is [".$object->get_version("yn")."]\n");
	my($obj)=__PACKAGE__->new_value(0);
	Meta::Utils::Output::print("of value is [".$obj->get_version("of")."]\n");
	return(1);
}

1;

__END__

=head1 NAME

Meta::Types::Bool - an object oriented boolean type.

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

	MANIFEST: Bool.pm
	PROJECT: meta
	VERSION: 0.00

=head1 SYNOPSIS

	package foo;
	use Meta::Types::Bool qw();
	my($object)=Meta::Types::Bool->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class provides you with a boolean object which can accept many
forms of input and output itself in many forms. The idea is for
this class to hold only the boolean value in a pure form (either 0
or 1) and be able to do boolean arithmetic on that value while the
input (at construction or at arithmetic time) and the output could
have many forms like y/n, 0/1, yes/no, true/false, t/f etc...
The versions currently supported are :

=head1 FUNCTIONS

	new($)
	new_value($$)
	set_value($$)
	get_value($)
	new_version($$$)
	set_version($$$)
	get_version($$)
	not($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This is a constructor for the Meta::Types::Bool object.
By default the value of it is 1 (true).

=item B<new_value($$)>

This is a value constructor for the Meta::Types::Bool object.
If the value you passed evaluates to true then the type will have
a 1 (true) value.

=item B<set_value($$)>

Give this method a value and it will set the internal value of
the boolean according to whether your value evaluates to true.

=item B<get_value($)>

This method retrieves the current value of the boolean.

=item B<new_version($$$)>

Pass a value and a version to this constructor and it will
give you an object with the internal value stored accordingly.

=item B<set_version($$$)>

Pass a version and value to this method and it will set the
internal boolean value accordingly.

=item B<get_version($$)>

Pass a version to this method and you will get the boolean
value converted to this version.

=item B<not($)>

This method will perform a boolean NOT operation on the value stored.

=item B<TEST($)>

This is a testing suite for the Meta::Types::Bool module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.
Currently this test just produces an object with one version and prints it
out with another.

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
