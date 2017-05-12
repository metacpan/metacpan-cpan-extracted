#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Output qw();
use Meta::Math::Pad qw();
use Meta::Math::MinMax qw();
use Meta::Ds::Hash qw();
use Heap::Fibonacci qw();
use Heap::Elem::NumRev qw();
use Heap::Elem::Num qw();
use Meta::Utils::File::Dir qw();
#use Meta::Template qw();

my($dire,$pattern,$num_pattern,$hi_pattern);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_dire("directory","what directory to use",".",\$dire);
$opts->def_stri("pattern","what pattern to use",'^series[% num_pad_2 %].*$',\$pattern);
$opts->def_stri("num_pattern","what num pattern to use","[% num_pad_2 %]",\$num_pattern);
$opts->def_stri("hi_pattern","pattern to identify numbers",'^series(\d+).*$',\$hi_pattern);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($files)=Meta::Utils::File::Dir::file_list($dire);

my($check)=0;
my($hash)=Meta::Ds::Hash->new();
my($heap)=Heap::Fibonacci->new();
my($minmax)=Meta::Math::MinMax->new();
for(my($k)=0;$k<$files->size();$k++) {
	my($curr)=$files->get($k);
	my($curr_num)=($curr=~/$hi_pattern/);
	if(defined($curr_num)) {
		my($unpad_num)=Meta::Math::Pad::unpad($curr_num);
		$minmax->add($curr_num);
		$hash->insert($unpad_num,$curr);
		my($elem)=Heap::Elem::NumRev->new($curr_num);
		$heap->add($elem);
		$check++;
	} else {
		#Meta::Utils::Output::print("didnt match [".$curr."]\n");
	}
}
my($max)=$minmax->get_max();
#Meta::Utils::Output::print("max is [".$max."]\n");

# pay attension that we iterate to less than $max since $max is there (we
# found it earlier).
my($missing_heap)=Heap::Fibonacci->new();
for(my($i)=0;$i<$max;$i++) {
#	my($vars)={
#		"num",$i,
#		"num_pad_2",Meta::Math::Pad::pad_easy($i,2),
#		"num_pad_3",Meta::Math::Pad::pad_easy($i,3),
#		"num_pad_4",Meta::Math::Pad::pad_easy($i,4),
#	};
#	my($template)=Meta::Template->new();
#	my($out);
#	$template->process(\$num_pattern,$vars,\$out);
	if($hash->hasnt($i)) {
		my($elem)=Heap::Elem::Num->new($i);
		$missing_heap->add($elem);
		#Meta::Utils::Output::print("found hole [".$out."]\n");
	}
}
my($missing_elem)=$missing_heap->extract_minimum();
my($over)=0;
while(defined($missing_elem) && !$over) {
	my($missing_val)=$missing_elem->val();
	my($elem)=$heap->extract_minimum();
	my($val)=$elem->val();
	my($file)=$hash->get($val);
	# i have series230_lin to go to series170_lin
	my($missing_file)="missing";# translate $missing_val to pattern;
	if($missing_val>$val) {
		$over=1;
	} else {
		#Meta::Utils::Output::print("moving [".$val."] -> [".$missing_val."]\n");
		Meta::Utils::Output::print("moving [".$file."] -> [".$missing_file."]\n");
		$missing_elem=$missing_heap->extract_minimum();
	}
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

utils_find_holes.pl - find files which don't match a numeric pattern.

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

	MANIFEST: utils_find_holes.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	utils_find_holes.pl [options]

=head1 DESCRIPTION

Lets say that you have a directory with files : name00.data name01.data...
Now you want to find the number i such that files name[i] is missing.
This script will do it for you.

What to you need to supply:
1. directory to scan.
2. pattern to look for.

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

=item B<directory> (type: dire, default: .)

what directory to use

=item B<pattern> (type: stri, default: ^series[% num_pad_2 %].*$)

what pattern to use

=item B<num_pattern> (type: stri, default: [% num_pad_2 %])

what num pattern to use

=item B<hi_pattern> (type: stri, default: ^series(\d+).*$)

pattern to identify numbers

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

	0.00 MV weblog issues
	0.01 MV md5 issues

=head1 SEE ALSO

Heap::Elem::Num(3), Heap::Elem::NumRev(3), Heap::Fibonacci(3), Meta::Ds::Hash(3), Meta::Math::MinMax(3), Meta::Math::Pad(3), Meta::Utils::File::Dir(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-use some kind of directory file iterator.

-add capability to actually move files/directories and shrink the space.
