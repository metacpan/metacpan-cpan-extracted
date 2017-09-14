#! /bin/false
# vim: ts=4:et

# Copyright (C) 2016-2017 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.

# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
# USA.

package Locale::XGettext::Text;

use strict;

use Locale::TextDomain qw(Locale-XGettext);

use base qw(Locale::XGettext);

sub readFile {
    my ($self, $filename) = @_;

    open my $fh, '<', $filename
        or die __x("Error reading '{filename}': {error}!\n",
                   filename => $filename, error => $!);
    
    my $chunk = '';
    my $last_lineno = 1;
    while (my $line = <$fh>) {
        if ($line =~ /^[\x09-\x0d ]*$/) {
            if (length $chunk) {
                chomp $chunk;
                $self->addEntry({msgid => $chunk,
                                 reference => "$filename:$last_lineno"});
            }
            $last_lineno = $. + 1;
            $chunk = '';
        } else {
            $chunk .= $line;
        }
    }
    
    if (length $chunk) {
        chomp $chunk;
        $self->addEntry({msgid => $chunk,
                         reference => "$filename:$last_lineno"});
    }

    return $self;
}

sub versionInformation {
    return __x('{program} (Locale-XGettext) {version}
Copyright (C) {years} Cantanea EOOD (http://www.cantanea.com/).
License LGPLv3+: GNU Lesser General Public Licence version 3 
or later <http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Written by Guido Flohr (http://www.guido-flohr.net/).
', program => $0, years => '2016-2017', version => $Locale::XGettext::VERSION);
}

sub fileInformation {
    return __(<<EOF);
Input files are interpreted as plain text files with each paragraph being
a separately translatable unit.
EOF
}

sub canExtractAll {
    shift;
}

sub canKeywords {
    return;
}

1;
