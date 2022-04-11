#!/usr/bin/env perl

# Copyright (C) 2015-2022 Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.

package Game::CharacterSheetGenerator;
use Modern::Perl;
use Test::More;
use FindBin;

my $file = "$FindBin::Bin/../lib/Game/CharacterSheetGenerator.pm";
require $file;
open(my $fh, '<:utf8', $file) or die "Cannot read $file\n";
undef $/;
my $source = <$fh>;
my $translations = translations();
my %data;
while ($source =~ /'(.+?)'/g) {
  next if $1 eq "(.+?)";
  $data{$1} = $translations->{$1};
}

binmode(STDOUT, ':encoding(UTF-8)');

ok(%data, (keys %data) . " strings where found");
ok(%$translations, (keys %$translations) . " translations where found");

my @unused;
for my $english (sort keys %$translations) {
  if (not exists $data{$english}) {
    push(@unused, $english);
    diag("Unused translation: $english");
  }
}

ok(@unused == 0, "no unused translations");

my @missing;
for my $english (sort keys %data) {
  if (not $translations->{$english}) {
    push(@missing, $english);
    diag("Missing a translation: $english");
  }
}
ok(@missing == 0, "no missing translations");

done_testing();
