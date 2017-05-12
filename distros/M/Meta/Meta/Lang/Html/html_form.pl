#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Output qw();
use Meta::Utils::File::File qw();
use HTML::Form qw();
use Error qw(:try);

my($file,$verbose);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_devf("file","what file to use ?","html/import/projects/Imdb/search.html",\$file);
$opts->def_bool("verbose","should I be noisy ?",1,\$verbose);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($html);
Meta::Utils::File::File::load_deve($file,\$html);

my(@forms)=HTML::Form->parse($html,"r");
if($#forms==-1) {
	throw Meta::Error::Simple("problem: didnt get any forms");
}
Meta::Utils::Output::verbose($verbose,"got [".($#forms+1)."] forms\n");
for(my($i)=0;$i<=$#forms;$i++) {
	Meta::Utils::Output::verbose($verbose,"form [".$i."]\n");
	my($form)=$forms[$i];
	my(@inputs)=$form->inputs();
	for(my($j)=0;$j<=$#inputs;$j++) {
		my($input)=$inputs[$j];
		Meta::Utils::Output::verbose($verbose,"\ttype is [".$input->type()."]\n");
		Meta::Utils::Output::verbose($verbose,"\tname is [".$input->name()."]\n");
	}
}
Meta::Utils::System::exit_ok();

__END__

=head1 NAME

html_form.pl - analyze HTML forms.

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

	MANIFEST: html_form.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	html_form.pl [options]

=head1 DESCRIPTION

Give this program an HTML file and it will show you the form fields
that are there to fill.

=head1 OPTIONS

=over 4

=item B<help> (type: bool, default: 0)

display help message

=item B<pod> (type: bool, default: 0)

display pod options snipplet

=item B<man> (type: bool, default: 0)

display manual page

=item B<quit> (type: bool, default: 0)

quit without doing anything

=item B<gtk> (type: bool, default: 0)

run a gtk ui to get the parameters

=item B<license> (type: bool, default: 0)

show license and exit

=item B<copyright> (type: bool, default: 0)

show copyright and exit

=item B<description> (type: bool, default: 0)

show description and exit

=item B<history> (type: bool, default: 0)

show history and exit

=item B<file> (type: devf, default: html/import/projects/Imdb/search.html)

what file to use ?

=item B<verbose> (type: bool, default: 1)

should I be noisy ?

=back

no free arguments are allowed

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV move tests to modules
	0.01 MV md5 issues

=head1 SEE ALSO

Error(3), HTML::Form(3), Meta::Utils::File::File(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
