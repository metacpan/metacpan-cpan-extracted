#!/bin/echo This is a perl module and should not be run

package Meta::Tool::Editor;

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Env qw();
use Meta::Utils::File::File qw();
use Meta::Utils::Utils qw();
use Meta::Utils::File::Patho qw();
use Meta::Utils::File::Remove qw();

our($VERSION,@ISA);
$VERSION="0.13";
@ISA=qw();

#sub BEGIN();
#sub set_editor($);
#sub edit($);
#sub edit_list($);
#sub edit_hash($);
#sub edit_set($);
#sub edit_set_pat($$);
#sub edit_line($$);
#sub edit_line_char($$$);
#sub edit_pat($$);
#sub edit_content($);
#sub TEST($);

#__DATA__

our($editor);
our($env_var)="EDITOR";
our($tool_path);

sub BEGIN() {
	if(Meta::Utils::Env::has($env_var)) {
		$editor=Meta::Utils::Env::get($env_var);
	} else {
		$editor="vim";
	}
	my($patho)=Meta::Utils::File::Patho->new_path();
	$tool_path=$patho->resolve($editor);
}

sub set_editor($) {
	my($ieditor)=@_;
	$editor=$ieditor;
}

sub edit($) {
	my($file)=@_;
	Meta::Utils::System::system($editor,[$file]);
}

sub edit_list($) {
	my($list)=@_;
	Meta::Utils::System::system($editor,$list);
}

sub edit_hash($) {
	my($hash)=@_;
	if($hash->size()>0) {
		my(@list);
		for(my($i)=0;$i<$hash->size();$i++) {
			my($curr)=$hash->key($i);
			push(@list,$curr);
		}
		Meta::Utils::System::system($editor,\@list);
	}
}

sub edit_set($) {
	my($set)=@_;
	if($set->size()>0) {
		my(@list);
		for(my($i)=0;$i<$set->size();$i++) {
			my($curr)=$set->elem($i);
			push(@list,$curr);
		}
		Meta::Utils::System::system($editor,\@list);
	}
}

sub edit_set_pat($$) {
	my($set,$pat)=@_;
	if($set->size()>0) {
		my(@list);
		for(my($i)=0;$i<$set->size();$i++) {
			my($curr)=$set->elem($i);
			push(@list,$curr);
		}
		Meta::Utils::System::system($editor,["+/".$pat,@list]);
	}
}

sub edit_line($$) {
	my($file,$line)=@_;
	Meta::Utils::System::system($editor,\[$file,"+".$line]);
}

sub edit_line_char($$$) {
	my($file,$line,$char)=@_;
	Meta::Utils::System::system($editor,\[$file,"+".$line]);
}

sub edit_pat($$) {
	my($file,$pat)=@_;
	Meta::Utils::System::system($editor,\[$file,"+/".$pat]);
}

sub edit_content($) {
	my($content)=@_;
	my($temp)=Meta::Utils::Utils::get_temp_file();
	Meta::Utils::File::File::save($temp,$content);
	&edit($temp);
	my($ncontent);
	Meta::Utils::File::File::load($temp,\$ncontent);
	Meta::Utils::File::Remove::rm($temp);
	return($ncontent);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Tool::Editor - library to activate your faivorite editor.

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

	MANIFEST: Editor.pm
	PROJECT: meta
	VERSION: 0.13

=head1 SYNOPSIS

	package foo;
	use Meta::Tool::Editor qw();
	my($system_exit_code)=Meta::Tool::Editor::edit("myfile.txt");

=head1 DESCRIPTION

This package will activate your favorite editor on a set of files.
It will consult the EDITOR environment variable and other options and
data to determine what that editor is and how to run it.
Currently just activation of the editor is supported (vi...).

=head1 FUNCTIONS

	BEGIN()
	set_editor($)
	edit($)
	edit_list($)
	edit_hash($)
	edit_set($)
	edit_set_pat($$)
	edit_line($$)
	edit_line_char($$$)
	edit_pat($$)
	edit_content($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This is a bootstrap method which sets the editor to the preferred
editor.

=item B<set_editor($)>

This class method sets the editor to be used.

=item B<edit($)>

Edit a file using your favorite editor.

=item B<edit_list($)>

Edit a list of files using your favorite editor.

This method will open up an editor on the specified file and will place the
cursor on the specified line and character.

=item B<edit_hash($)>

Edit a hash of files using your favorite editor.

This method receives a hash object and runs your favorite editor on each
key of the hash.

=item B<edit_set($)>

Edit a set of files using your favorite editor.

This method receives a set object and runs your favorite editor on each
key of the hash.

=item B<edit_set_pat($$)>

This method will open a set of files using an editor and make the editor
seek a specific pattern.

=item B<edit_line($$)>

This will open an editor on a specified line.

=item B<edit_line_char($$$)>

This will open an editor at the specified line and character number.

=item B<edit_pat($$)>

This will open an editor seeking a specific pattern.

=item B<edit_content($)>

This will open the favourite editor on a specific content.

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

	0.00 MV perl reorganization
	0.01 MV get imdb ids of directors and movies
	0.02 MV perl packaging
	0.03 MV md5 project
	0.04 MV database
	0.05 MV perl module versions in files
	0.06 MV movies and small fixes
	0.07 MV thumbnail user interface
	0.08 MV more thumbnail issues
	0.09 MV website construction
	0.10 MV web site automation
	0.11 MV SEE ALSO section fix
	0.12 MV teachers project
	0.13 MV md5 issues

=head1 SEE ALSO

Meta::Utils::Env(3), Meta::Utils::File::File(3), Meta::Utils::File::Patho(3), Meta::Utils::File::Remove(3), Meta::Utils::System(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

-Support other editors (emacs etc..)

-implement the edit_line_char method.

-read the editor from an XML configuration file or from envrionment variable.
