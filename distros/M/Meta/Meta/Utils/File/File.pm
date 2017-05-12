#!/bin/echo This is a perl module and should not be run

package Meta::Utils::File::File;

use strict qw(vars refs subs);
use Meta::Utils::Output qw();
use Meta::Baseline::Aegis qw();
#require 'sys/ioctl.ph';
use Meta::IO::File qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.32";
@ISA=qw();

#sub check_mult_regexp($$$);
#sub check_sing_regexp($$$);
#sub save($$);
#sub old_load($);
#sub load($$);
#sub load_deve($$);
#sub load_line($$);
#sub cmp($$);
#sub exist($);
#sub notexist($);
#sub exec($);
#sub notexec($);
#sub check_exist($);
#sub check_notexist($);
#sub check_exec($);
#sub check_notexec($);
#sub create_new($);
#sub subst($$$);
#sub TEST($);

#__DATA__

sub check_mult_regexp($$$) {
	my($file,$rege,$prin)=@_;
	my($sing)=0;
	my($io)=Meta::IO::File->new_reader($file);
	my($result)=0;
	while(!$io->eof() && (!$sing && !$result)) {
		my($line)=$io->cgetline();
		my($curr);
		for $curr (@$rege) {
			# the \b are to do it right
			if($line=~/\b$curr\b/) {
				Meta::Utils::Output::verbose($prin,$file.":".$io->input_line_number().":".$line."\n");
				$result=1;
			}
		}
	}
	$io->close();
	return($result);
}

sub check_sing_regexp($$$) {
	my($file,$rege,$prin)=@_;
	my($sing)=0;
	my($io)=Meta::IO::File->new_reader($file);
#	Meta::Utils::Output::print("rege is [".$rege."]\n");
	my($result)=0;
	while(!$io->eof() && (!$sing && !$result)) {
		my($line)=$io->cgetline();
		# the \b are to do it right
		if($line=~/\b$rege\b/) {
			Meta::Utils::Output::verbose($prin,$file.":".$io->input_line_number().":".$line."\n");
			$result=1;
		}
	}
	$io->close();
	return($result);
}

sub save($$) {
	my($file,$text)=@_;
	my($io)=Meta::IO::File->new_writer($file);
	print $io $text;
	$io->close();
}

sub load($$) {
	my($file,$text)=@_;
	open(FILE,$file) || throw Meta::Error::Simple("unable to open file [".$file."]");
	binmode(FILE);
	#find out how many bytes to read
	my($size);
	$size=pack("L",0);
	ioctl(FILE,0x541b,$size);
	$size=unpack("L",$size);
	my($ret)=read(FILE,$$text,$size);
	if($ret!=$size) {
		throw Meta::Error::Simple("could not read file");
	}
	close(FILE) || throw Meta::Error::Simple("unable to close file [".$file."]");
}

sub old_load($$) {
	my($file,$text)=@_;
	$$text="";
	open(FILE,$file) || throw Meta::Error::Simple("unable to open file [".$file."]");
	binmode(FILE);
	my($line);
	while($line=<FILE> || 0) {
		$$text.=$line;
	}
	close(FILE) || throw Meta::Error::Simple("unable to close file [".$file."]");
}

sub load_deve($$) {
	my($file,$content)=@_;
	&load(Meta::Baseline::Aegis::which($file),$content);
}

sub load_line($$) {
	my($file,$numb)=@_;
	my($io)=Meta::IO::File->new_reader($file);
	my($over)=0;
	my($coun)=0;
	my($resu);
	while(!$io->eof() && !$over) {
		my($line)=$io->cgetline();
		if($coun==$numb) {
			$resu=$line;
			chop($resu);
			$over=1;
		} else {
			$coun++;
		}
	}
	$io->close();
	if(!$over) {
		throw Meta::Error::Simple("file [".$file."] has no line number [".$numb."]");
	}
	return($resu);
}

sub cmp($$) {
	my($file,$comp)=@_;
	my($buff);
	&load($file,\$buff);
	if($buff eq $comp) {
		return(1);
	} else {
		return(0);
	}
}

sub exist($) {
	my($file)=@_;
	if(-f $file) {
		return(1);
	} else {
		return(0);
	}
}

sub notexist($) {
	my($file)=@_;
	return(!exist($file));
}

sub exec($) {
	my($file)=@_;
	if(-x $file) {
		return(1);
	} else {
		return(0);
	}
}

sub notexec($) {
	my($file)=@_;
	if(-x $file) {
		return(0);
	} else {
		return(1);
	}
}

sub check_exist($) {
	my($file)=@_;
	if(!exist($file)) {
		throw Meta::Error::Simple("file [".$file."] does not exist and it should");
	}
}

sub check_notexist($) {
	my($file)=@_;
	if(!notexist($file)) {
		throw Meta::Error::Simple("file [".$file."] does exist and it should not");
	}
}

sub check_exec($) {
	my($file)=@_;
	if(!exec($file)) {
		throw Meta::Error::Simple("file [".$file."] is not executable as it should");
	}
}

sub check_notexec($) {
	my($file)=@_;
	if(!notexec($file)) {
		throw Meta::Error::Simple("file [".$file."] is unexecutable as it should");
	}
}

sub create_new($) {
	my($file)=@_;
	check_notexist($file);
	open(FILE,"> ".$file) || throw Meta::Error::Simple("unable to open file [".$file."]");
	close(FILE) || throw Meta::Error::Simple("unable to close file [".$file."]");
}

sub subst($$$) {
	my($file,$sour,$targ)=@_;
	my($verb)=0;
	if($verb) {
		Meta::Utils::Output::print("file is [".$file."]\n");
		Meta::Utils::Output::print("sour is [".$sour."]\n");
		Meta::Utils::Output::print("targ is [".$targ."]\n");
	}
	my($text);
	load($file,\$text);
	if($text=~/$sour/) {
		if($verb) {
			Meta::Utils::Output::print("text is [".$text."]\n");
		}
		$text=~s/$sour/$targ/g;
		if($verb) {
			Meta::Utils::Output::print("text is [".$text."]\n");
		}
		save($file,$text);
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::File::File - library to do operations on files.

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

	MANIFEST: File.pm
	PROJECT: meta
	VERSION: 0.32

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::File::File qw();
	my($file)="/etc/passwd";
	if(Meta::Utils::File::File::exist($file)) {
		# try to break into the system
	} else {
		# we are in windows, just remove the kernel.dll from c:\windows
	}

=head1 DESCRIPTION

This is a library to help you do things with files with meaningful names.
For instance: check if a file exists, compare two files etc...

=head1 FUNCTIONS

	check_mult_regexp($$$)
	check_sing_regexp($$$)
	save($$)
	old_load($)
	load($)
	load_deve($$)
	load_line($$)
	cmp($$)
	exist($)
	notexist($)
	exec($)
	check_exist($)
	check_notexist($)
	check_exec($)
	create_new($)
	subst($$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<check_mult_regexp($$$)>

This routine does exactly the same as check_sing_regexp except it
gets a list of regular expressions and matches any of them.
This also receives a variable telling it whether to print the matched lines
or not.

=item B<check_sing_regexp($$$)>

This routine checks whether a single regular expression given to it
is present in the file given to it.
This also receives a variable telling it whether to print the matched lines
or not.

=item B<save($$)>

This routine receives a file name and text to write into it.
The routine assumes that it has permissions, and writes a new file (recreates
it) and writes the string into it, and then closes the file.
The routine throws an exception if something goes wrong.

=item B<old_load($)>

This is the old implementation of the load routine which gulps the file
down one line at a time.

=item B<load($$)>

This routine loads up a files into a single string and gives it to you.
The routine will throw an exception if something goes wrong.
The implementation finds what the size of the file is and then reads
that amount from the file.

=item B<load_deve($$)>

This method loads a file from a development framework.

=item B<load_line($$)>

This routine loads a specific text line from the source file given to it.
You better make sure that the specified file has that line in it..!!!:)

=item B<cmp($$)>

This routines receives a file to compare a variable with.
It returns a boolean value which is the result of the comparison.
The implementation attemps to read length(input) characters from
the file. If it fails it return false and else it just does a eq
comparison...

=item B<exist($)>

This routine returns whether a cetain file is a regular file
I cannot just return the result of "-f $file" since it will be
nothing (which is not good for boolean arithmetic) if the file is not there.
This means that I need the if switch there.

=item B<notexist($)>

This routine returns whether a certain file does not exist as a regular file
Same notes as for "exist" apply.

=item B<exec($)>

This routine returns whether a certain file is executable or not.
I cannot just return the result of "-x $file" since it will be
nothing (which is not good for boolean arithmetic) if the file is not there.
This means that I need the if switch there.

=item B<check_exist($)>

This routine checks if a file given to it exists and if indeed it is a
regular file. If something fails it dies.

=item B<check_notexist($)>

This routine checks if a file given to it not exists.
If something fails it dies.

=item B<check_exec($)>

This routine will check if a file given to it exists and is executable.
If something fails it dies.

=item B<create_new($)>

This function receives a file name and creates that file (it supposes the
file does not exist and if it does it fails...).

=item B<subst($$$)>

This function receives the following arguments:
1. File to be modifield.
2. Pattern to be searched for.
3. Pattern to be replaced with.
And modifies the file by replacing the required pattern with the target pattern.

=item B<TEST($)>

Test suite for this module.

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

	0.00 MV initial code brought in
	0.01 MV this time really make the databases work
	0.02 MV make quality checks on perl code
	0.03 MV more perl checks
	0.04 MV make Meta::Utils::Opts object oriented
	0.05 MV check that all uses have qw
	0.06 MV fix todo items look in pod documentation
	0.07 MV more on tests/more checks to perl
	0.08 MV correct die usage
	0.09 MV perl code quality
	0.10 MV more perl quality
	0.11 MV more perl quality
	0.12 MV perl documentation
	0.13 MV more perl quality
	0.14 MV perl qulity code
	0.15 MV more perl code quality
	0.16 MV revision change
	0.17 MV languages.pl test online
	0.18 MV perl packaging
	0.19 MV tree type organization in databases
	0.20 MV md5 project
	0.21 MV database
	0.22 MV perl module versions in files
	0.23 MV movies and small fixes
	0.24 MV thumbnail user interface
	0.25 MV more thumbnail issues
	0.26 MV website construction
	0.27 MV web site automation
	0.28 MV SEE ALSO section fix
	0.29 MV move tests to modules
	0.30 MV download scripts
	0.31 MV finish papers
	0.32 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Baseline::Aegis(3), Meta::IO::File(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

-Cant the load() fundtion return a reference to the data instead of the actual data ? (the return value may be long...). (The same goes for load_line...).

-Do the create_new function more effiently (isnt there a perl function for it?).

-stop using the hardcoded hexa value in ioctl (I only did it because of error in requiring the required ph files).

-cant the load method be nicer if implemented using file handles ?
