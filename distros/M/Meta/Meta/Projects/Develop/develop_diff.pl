#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Utils qw();
use Meta::Utils::Chdir qw();
#use Meta::Utils::File::Mkdir qw();
use Meta::Tool::Tar qw();
use Meta::Tool::Diff qw();
use Meta::Utils::Output qw();

my($pack_from,$pack_to,$output,$verbose);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_file("from","package to diff from",undef,\$pack_from);
$opts->def_file("to","package to diff to",undef,\$pack_to);
$opts->def_newf("output","patch to output",undef,\$output);
$opts->def_bool("verbose","should I be noisy ?",1,\$verbose);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

Meta::Utils::Output::verbose($verbose,"making temp directory\n");
my($temp_dir)=Meta::Utils::Utils::get_temp_dire();
#Meta::Utils::File::Mkdir::mkdir($temp_dir);
Meta::Utils::Output::verbose($verbose,"unpacking [".$pack_from."]\n");
Meta::Tool::Tar::unpack($pack_from,$temp_dir);
Meta::Utils::Output::verbose($verbose,"unpacking [".$pack_to."]\n");
Meta::Tool::Tar::unpack($pack_to,$temp_dir);

# check that temp_dir now has exactly two directories and give
# them to dir_diff
#Meta::Utils::Chdir::chdir($temp_dir);
#my(@array)=CORE::glob("*");
#Meta::Utils::Chdir::popd();
#Meta::Utils::Output::print("array is [".join(',',@array)."]\n");

my($from_basename)=Meta::Utils::Utils::remove_suf($pack_from,".tar.bz2");
my($to_basename)=Meta::Utils::Utils::remove_suf($pack_to,".tar.bz2");
Meta::Utils::Output::verbose($verbose,"from_basename is [".$from_basename."]\n");
Meta::Utils::Output::verbose($verbose,"to_basename is [".$to_basename."]\n");
my($abs_output)=Meta::Utils::Utils::to_absolute($output);

Meta::Utils::Output::verbose($verbose,"diffing\n");
Meta::Tool::Diff::diff_dir($from_basename,$to_basename,$abs_output,$temp_dir);
Meta::Utils::Output::verbose($verbose,"removing the directory\n");
#Meta::Utils::File::Remove::rmrecursive($temp_dir);

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

develop_diff.pl - produce diff between two archived packages.

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

	MANIFEST: develop_diff.pl
	PROJECT: meta
	VERSION: 0.00

=head1 SYNOPSIS

	develop_diff.pl [options]

=head1 DESCRIPTION

Give this script two archives and it will produce a diff between them.
How does this work ? It opens the two archives to a temp directory
and runs diff giving you the result.

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

=item B<from> (type: file, default: )

package to diff from

=item B<to> (type: file, default: )

package to diff to

=item B<output> (type: newf, default: )

patch to output

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

	0.00 MV md5 issues

=head1 SEE ALSO

Meta::Tool::Diff(3), Meta::Tool::Tar(3), Meta::Utils::Chdir(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

Nothing.
