#!/bin/echo This is a perl module and should not be run

package Meta::Utils::Options;

use strict qw(vars refs subs);
use Meta::Utils::File::File qw();
use Meta::Utils::Env qw();
use Meta::Utils::Utils qw();
use Meta::Ds::Ohash qw();

our($VERSION,@ISA);
$VERSION="0.36";
@ISA=qw(Meta::Ds::Ohash);

#sub new_file($$);
#sub new_modu($$);
#sub read($$);
#sub getd($$$);
#sub getenv($$);
#sub TEST($);

#__DATA__

sub new_file($$) {
	my($class,$file)=@_;
	my($object)=Meta::Utils::Options->new();
	$object->read($file);
	return($object);
}

sub new_modu($$) {
	my($class,$modu)=@_;
	return(&new_file($class,$modu->get_abs_path()));
}

sub read($$) {
	my($self,$file)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Utils::Options");
	my($text);
	Meta::Utils::File::File::load($file,\$text);
	$text=Meta::Utils::Utils::remove_comments($text);
	my(@line)=split(/;/,$text);
	for(my($i)=0;$i<=$#line;$i++) {
		my($current)=$line[$i];
		if($current=~/=/) {
			my($elem,$val)=($current=~/^\s*(\S+)\s*=\s*(.*)\s*$/);
			$self->insert($elem,$val);
		}
	}
	return(1);
}

sub getd($$$) {
	my($self,$elem,$defa)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Utils::Options");
	if($self->has($elem)) {
		return($self->get($elem));
	} else {
		return($defa);
	}
}

sub getenv($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Utils::Options");
	my($resu)=$self->get($elem);
	if(Meta::Utils::Env::has($elem)) {
		$resu=Meta::Utils::Env::get($elem);
	}
	return($resu);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::Options - utilities to let you manipulate option files.

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

	MANIFEST: Options.pm
	PROJECT: meta
	VERSION: 0.36

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::Options qw();
	my($opti)=Meta::Utils::Options->new_modu($my_module);
	$opti->read("my_configuration_file");
	$obje=$opti->get("my_variable");

=head1 DESCRIPTION

This library lets you read and write configuration files.

=head1 FUNCTIONS

	new_file($$)
	new_modu($$)
	read($$)
	getd($$$)
	getenv($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new_file($$)>

This method will give you a new Options object read from a file.

=item B<new_modu($$)>

Gives you a new options object according to a development module.

=item B<read($$)>

This lets you read a file in options format.

=item B<getd($$$)>

This will get a value but will return a default value if no value exists.

=item B<getenv($$)>

This is a new get routine which is overridable by the envrionment.
Mind you, that a default value must be available in the options file.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Meta::Ds::Ohash(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV initial code brought in
	0.01 MV bring databases on line
	0.02 MV handle architectures better
	0.03 MV make quality checks on perl code
	0.04 MV more perl checks
	0.05 MV make Meta::Utils::Opts object oriented
	0.06 MV check that all uses have qw
	0.07 MV fix todo items look in pod documentation
	0.08 MV more on tests/more checks to perl
	0.09 MV make options a lot better
	0.10 MV perl code quality
	0.11 MV more perl quality
	0.12 MV more perl quality
	0.13 MV perl documentation
	0.14 MV more perl quality
	0.15 MV perl qulity code
	0.16 MV more perl code quality
	0.17 MV revision change
	0.18 MV languages.pl test online
	0.19 MV remove old c++ files
	0.20 MV PDMT/SWIG support
	0.21 MV Pdmt stuff
	0.22 MV perl packaging
	0.23 MV md5 project
	0.24 MV database
	0.25 MV perl module versions in files
	0.26 MV movies and small fixes
	0.27 MV thumbnail project basics
	0.28 MV more thumbnail stuff
	0.29 MV thumbnail user interface
	0.30 MV more thumbnail issues
	0.31 MV website construction
	0.32 MV web site automation
	0.33 MV SEE ALSO section fix
	0.34 MV bring movie data
	0.35 MV teachers project
	0.36 MV md5 issues

=head1 SEE ALSO

Meta::Ds::Ohash(3), Meta::Utils::Env(3), Meta::Utils::File::File(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

-slowly remove usage of this class and use some off the shelf XML option parser instead and then remove this completely.
