# Games::Checkers, Copyright (C) 1996-2012 Mikhael Goikhman, migo@cpan.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

package Games::Checkers::PDNParser;

use Games::Checkers::LocationConversions;
use IO::File;

sub new ($$) {
	my $class = shift;
	my $filename = shift;

	-r "$filename.$_" and $filename .= ".$_"
		for qw(pdn.gz pdn.xz pdn.bz2 pdn gz xz bz2);
	my $file_to_open =
		$filename =~ /\.gz$/ ? "zcat $filename |" :
		$filename =~ /\.xz$/ ? "xzcat $filename |" :
		$filename =~ /\.bz2$/ ? "bzcat $filename |" :
		$filename;
	my $fd = new IO::File $file_to_open;
	die "Can't open PDN for reading ($filename)\n" unless $fd;

	my $self = { fn => $filename, fd => $fd, lineno => 0 };
	bless $self, $class;
	return $self;
}

sub error_prefix {
	my $self = shift;
	"Error parsing $self->{fn}, line $self->{lineno}, corrupted record:\n";
}

sub next_record ($) {
	my $self = shift;

	my $record_values = {};

	my $line;
	my $not_end = 0;
	while ($line = $self->{fd}->getline) {
		$self->{lineno}++;
		next if $line =~ /^\s*(([#;]|{.*}|\(.*\))\s*)?$/;
		$not_end = 1;
		if ($line =~ /\[(\w+)\s+"?(.*?)"?\]/) {
			$record_values->{$1} = $2;
			next;
		}
		last;
	}
	return undef unless $not_end;

	my $result = $record_values->{Result};
	die $self->error_prefix . "\tNon empty named value 'Result' is missing\n"
		unless $result;
	my $lineno = $self->{lineno};

	my $move_string = "";
	while (!$move_string || ($line = $self->{fd}->getline) && $self->{lineno}++) {
		$line =~ s/[\r\n]+$/ /;
		$move_string .= $line;
		last if $line =~ /$result/;

		# tolerate some broken PDNs without trailing result separator
		my $next_char = $self->{fd}->getc;
		$self->{fd}->ungetc(ord($next_char));
		last if $next_char eq "[";
	}

	# tolerate some broken PDNs without result separator
#	die $self->error_prefix . "\tSeparator ($result) is not found from line $lineno\n"
#		unless $line;

	$move_string =~ s/\b$result\b.*//;
	$move_string =~ s/{[^}]*}//g;  # remove comments
	$move_string =~ s/\([^\)]*(\)[^(]*)?\)//g;  # remove comments
	$move_string =~ s/([x:*-])\s+(\d|\w)/$1$2/gi;  # remove alignment spaces
	my @move_verge_strings = split(/(?:\s+|\d+\.\s*)+/, $move_string);
	shift @move_verge_strings while @move_verge_strings && !$move_verge_strings[0];

	my @move_verge_trios = map {
		/^((\d+)|\w\d)([x:*-])((\d+)|\w\d)$/i
			|| die $self->error_prefix . "\tIncorrect move notation ($_)\n";
		[
			$3 eq "-" ? 0 : 1,
			defined $2 ? num_to_location($1) : str_to_location($1),
			defined $5 ? num_to_location($4) : str_to_location($4),
		]
	} @move_verge_strings;

	return [ \@move_verge_trios, $record_values ];
}

1;
