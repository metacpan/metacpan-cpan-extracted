#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Utils qw();
use Meta::Utils::File::Move qw();
use Meta::IO::File qw();

my($verb,$demo,$star,$jump,$colu,$ldel,$vdel);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("verb","noisy or quiet ?",0,\$verb);
$opts->def_bool("demo","just play around or do it for real ?",0,\$demo);
$opts->def_inte("star","what will be the start value on the column ?",0,\$star);
$opts->def_inte("jump","how much should I just between records ?",1,\$jump);
$opts->def_inte("colu","what column to fix ?",0,\$colu);
$opts->def_stri("ldel","what line delimiter to use ?","\n",\$ldel);
$opts->def_stri("vdel","what field delimiter to use ?","\t",\$vdel);
$opts->set_free_allo(1);
$opts->set_free_stri("[files]");
$opts->set_free_mini(1);
$opts->set_free_noli(1);
$opts->analyze(\@ARGV);

for(my($i)=0;$i<=$#ARGV;$i++) {
	my($icur)=$star;
	my($curr)=$ARGV[$i];
	my($in)=Meta::IO::File->new_reader($curr);
	my($file)=Meta::Utils::Utils::get_temp_file();
	my($out)=Meta::IO::File->new_writer($file);
	while(!$in->eof()) {
		my($line)=$in->cgetline();
		my(@fiel)=CORE::split($vdel,$line);
		$fiel[$colu]=$icur;
		$icur+=$jump;
		print $out CORE::join($vdel,@fiel)."\n";
	}
	$out->close();
	$in->close();
	Meta::Utils::File::Move::mv($file,$curr);
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

db_fix_column.pl - fix a column up in a text table.

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

	MANIFEST: db_fix_column.pl
	PROJECT: meta
	VERSION: 0.14

=head1 SYNOPSIS

	db_fix_column.pl

=head1 DESCRIPTION

This will fix a column in a text table for you. It will assume that the
text file is a reflection of a table in a database and has a certain delimiter
to make it such (both for lines and for entries within lines) and will make
the values in that column sequential.

Take heed when using this script since it actually modifies the file given
to it. The change that this script makes is also non reversible. This means
you should back up your data. Really.

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

=item B<verb> (type: bool, default: 0)

noisy or quiet ?

=item B<demo> (type: bool, default: 0)

just play around or do it for real ?

=item B<star> (type: inte, default: 0)

what will be the start value on the column ?

=item B<jump> (type: inte, default: 1)

how much should I just between records ?

=item B<colu> (type: inte, default: 0)

what column to fix ?

=item B<ldel> (type: stri, default: 
)

what line delimiter to use ?

=item B<vdel> (type: stri, default: 	)

what field delimiter to use ?

=back

minimum of [1] free arguments required
no maximum limit on number of free arguments placed

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV more on data sets
	0.01 MV perl packaging
	0.02 MV license issues
	0.03 MV more database issues
	0.04 MV md5 project
	0.05 MV database
	0.06 MV perl module versions in files
	0.07 MV thumbnail user interface
	0.08 MV more thumbnail issues
	0.09 MV website construction
	0.10 MV improve the movie db xml
	0.11 MV web site automation
	0.12 MV SEE ALSO section fix
	0.13 MV move tests to modules
	0.14 MV md5 issues

=head1 SEE ALSO

Meta::IO::File(3), Meta::Utils::File::Move(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

Nothing.
