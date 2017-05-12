#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();

my($file);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_file("file","what file to work on ?",undef,\$file);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

sub double_lines($) {
	my($file)=@_;
	my($text);
	open(FILE,$file) || die("unable to open [$file]");
	my($line);
	while($line=<FILE> || 0) {
		$text.=$line;
	}
	close(FILE) || die("unable to close [$file]");
	$text=~s/\n\n\n/\n\n/g;
	my($outf)="tmp.tmp";
	open(OUTX,"> ".$outf) || die("unable to open [$outf]");
	print OUTX $text;
	close(OUTX) || die("unable to close [$outf]");
	if(!rename($outf,$file)) {
		die("unable to rename [$outf] to [$file]");
	}
}

double_lines($file);
Meta::Utils::System::exit_ok();

__END__

=head1 NAME

utils_remove_empty_line.pl - remove empty lines from files.

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

	MANIFEST: utils_remove_empty_line.pl
	PROJECT: meta
	VERSION: 0.06

=head1 SYNOPSIS

	utils_remove_empty_line.pl [options]

=head1 DESCRIPTION

Give this script a file and it will remove all empty lines from it.

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

=item B<file> (type: file, default: )

what file to work on ?

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

	0.00 MV paper writing
	0.01 MV website construction
	0.02 MV improve the movie db xml
	0.03 MV web site automation
	0.04 MV SEE ALSO section fix
	0.05 MV move tests to modules
	0.06 MV md5 issues

=head1 SEE ALSO

Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
