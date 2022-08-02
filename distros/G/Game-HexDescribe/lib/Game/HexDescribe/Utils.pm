#!/usr/bin/env perl
# Copyright (C) 2018–2022  Alex Schroeder <alex@gnu.org>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

=encoding utf8

=head1 NAME

Game::HexDescribe::Utils - utilities to use the Hex Describe data

=head1 DESCRIPTION

L<Hex::Describe> is a web application which uses recursive random tables to
create the description of a map. This package contains the functions used to
access the information outside the web application framework.

=cut

package Game::HexDescribe::Utils;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(init markdown describe_text list_tables parse_table load_table
		    describe_map parse_map load_map);
use Text::Autoformat;
use Game::HexDescribe::Log;
use Modern::Perl;
use Mojo::URL;
use Mojo::File;
use List::Util qw(shuffle);
use Array::Utils qw(intersect);
use Encode qw(decode_utf8);
use utf8;

my $log = Game::HexDescribe::Log->get;

our $face_generator_url;
our $text_mapper_url;

=item list_tables($dir)

This function returns the table names in $dir. These are based on the following
filename convention: "$dir/hex-describe-$name-table.txt".

=cut

sub list_tables {
  my $dir = shift;
  $log->debug("Looking for maps in the contrib directory: $dir");
  my @names = map { $_->basename('.txt') } Mojo::File->new($dir)->list->each;
  return grep { $_ } map { $1 if /^hex-describe-(.*)-table$/ } @names;
}

=item load_table($name, $dir)

This function returns the unparsed table from the filename
"$dir/hex-describe-$name-table.txt".

=cut

sub load_table {
  my ($name, $dir) = @_;
  $log->debug("Looking for table '$name' in the contrib directory '$dir'");
  my $file = Mojo::File->new("$dir/hex-describe-$name-table.txt");
  return decode_utf8($file->slurp) if -e $file;
}

=item load_map($name, $dir)

This function returns the unparsed map from the filename
"$dir/hex-describe-$name-map.txt".

=cut

sub load_map {
  my ($name, $dir) = @_;
  $log->debug("Looking for map in the contrib directory: $dir");
  my $file = Mojo::File->new("$dir/hex-describe-$name-map.txt");
  return decode_utf8($file->slurp) if -e $file;
}

=item parse_table

This parses the random tables. This is also where *bold* gets translated to
HTML. We also do some very basic checking of references. If we refer to another
table in square brackets we check whether we've seen such a table.

Table data is a reference to a hash of hashes. The key to the first hash is the
name of the table; the key to the second hash is "total" for the number of
options and "lines" for a reference to a list of hashes with two keys, "count"
(the weight of this lines) and "text" (the text of this line).

A table like the following:

    ;tab
    1,a
    2,b

Would be:

    $table_data->{tab}->{total} == 3
    $table_data->{tab}->{lines}->[0]->{count} == 1
    $table_data->{tab}->{lines}->[0]->{text} eq "a"
    $table_data->{tab}->{lines}->[1]->{count} == 2
    $table_data->{tab}->{lines}->[1]->{text} eq "b"

=cut

my $dice_re = qr/^(save )?(?:(\d+)d(\d+)(?:x(\d+))?(?:([+-]\d+))?(?:>=(-?\d+))?(?:<=(-?\d+))?|(\d+))(?: as (.+))?$/;
my $math_re = qr/^(save )?([-+*\/%()0-9]+)(?: as (.+))?$/;

sub parse_table {
  my $text = shift;
  $log->debug("parse_table: parsing " . length($text) . " characters");
  my $data = {};
  my $words = "[^\[\]\n]*";
  my (%aliases, $key, $c, $t);
  for my $line (split(/\r?\n/, $text)) {
    if ($line =~ /^;([^#\r\n]+)/) {
      $key = $1;
      $log->warn("parse_table: reset '$key'") if exists $data->{$key};
      $data->{$key} = {}; # reset, don't merge
    } elsif ($key and ($c, $t) = $line =~ /^(\d+),(.*)/) {
      $t =~ s/\*\*(.*?)\*\*/<strong>$1<\/strong>/g;
      $t =~ s/\*(.*?)\*/<em>$1<\/em>/g;
      my %h = (text => $t);
      if ($c == 0) {
	$h{unique} = 1;
	$c = 1;
      }
      $h{count} = $c;
      $data->{$key}->{total} += $c;
      push(@{$data->{$key}->{lines}}, \%h);
      # [foo as bar]
      for my $alias ($h{text} =~ /\[$words as ($words)\]/g) {
	$aliases{$alias} = 1;
      }
      # [foo [baz] quux as bar] (one level of indirection allowed
      for my $alias ($h{text} =~ /\[$words\[$words\]$words as ($words)\]/g) {
	$aliases{$alias} = 1;
      }
    } elsif ($line ne '' and $line !~ /^\s*#/) {
      $log->warn("unknown line type: '$line'");
    }
  }
  # check tables
  for my $table (keys %$data) {
    for my $line (@{$data->{$table}->{lines}}) {
      for my $subtable ($line->{text} =~ /\[($words)\]/g) {
	next if index($subtable, '|') != -1;
	next if $subtable =~ /$dice_re/;
	next if $subtable =~ /$math_re/;
	next if $subtable =~ /^redirect https?:/;
	next if $subtable =~ /^names for (.*)/ and $data->{"name for $1"};
	next if $subtable =~ /^(?:capitalize|titlecase|highlightcase|normalize-elvish) (.*)/ and $data->{$1};
	next if $subtable =~ /^adjacent hex$/; # experimental
	next if $subtable =~ /^same (.*)/ and ($data->{$1} or $aliases{$1} or $1 eq 'adjacent hex');
	next if $subtable =~ /^(?:here|nearby|other|append|later|with|and|save|store) (.+?)( as (.+))?$/ and $data->{$1};
	$subtable = $1 if $subtable =~ /^(.+) as (.+)/;
	$log->error("Error in table $table: subtable $subtable is missing")
	    unless $data->{$subtable};
      }
    }
  }
  return $data;
}

=item init

When starting a description, we need to initialize our data. There are two
global data structures beyond the map.

B<$extra> is a reference to a hash of lists of hashes used to keep common data
per line. In this context, lines are linear structures like rivers or trails on
the map. The first hash uses the hex coordinates as a key. This gets you the
list of hashes, one per line going through this hex. Each of these hashes uses
the key "type" to indicate the type of line, "line" for the raw data (for
debugging), and later "name" will be used to name these lines.

    $extra->{"0101"}->[0]->{"type"} eq "river"

B<%names> is just a hash of names. It is used for all sorts of things. When
using the reference C<name for a bugbear band1>, then "name for a bugbear band1"
will be a key in this hash. When using the reference C<name for forest foo>,
then "name for forest foo: 0101" and will be set for every hex sharing that
name.

    $names{"name for a bugbear band1"} eq "Long Fangs"
    $names{"name for forest foo: 0101"} eq "Dark Wood"

Note that for C</describe/text>, C<init> is called for every paragraph.

B<%locals> is a hash of all the "normal" table lookups encountered so far. It is
is reset for every paragraph. To refer to a previous result, start a reference
with the word "same". This doesn't work for references to adjacent hexes, dice
rolls, or names. Here's an example:

    ;village boss
    1,[man] is the village boss. They call him Big [same man].
    1,[woman] is the village boss. They call her Big [same woman].

Thus:

    $locals{man} eq "Alex"

B<%globals> is a hash of hashes of all the table lookups beginning with the word
"here" per hex. In a second phase, all the references starting with the word
"nearby" will be resolved using these. Here's an example:

    ;ingredient
    1,fey moss
    1,blue worms
    ;forest
    3,There is nothing here but trees.
    1,You find [here ingredient].
    ;village
    1,The alchemist needs [nearby ingredient].

Some of the forest hexes will have one of the two possible ingredients and the
village alchemist will want one of the nearby ingredients. Currently, there is a
limitation in place: we can only resolve the references starting with the word
"nearby" when everything else is done. This means that at that point, references
starting with the word "same" will no longer work since C<%locals> will no
longer be set.

Thus:

    $globals->{ingredient}->{"0101"} eq "fey moss"

=cut

my $extra;
my %names;
my %locals;
my $globals;

sub init {
  %names = ();
  %locals = ();
  $globals = undef;
  $extra = undef;
}

=item parse_map_data

This does basic parsing of hexes on the map as produced by Text Mapper, for
example:

    0101 dark-green trees village

=cut

sub parse_map_data {
  my $map = shift;
  my $map_data;
  if ($map and $map->isa('Mojo::Upload')) {
    $map = $map->slurp();
  };
  for my $hex (split(/\r?\n/, $map)) {
    if (my ($x, $y) = $hex =~ /^(\d\d)(\d\d)\s*empty$/cg) {
      # skip
    } elsif (($x, $y) = $hex =~ /^(\d\d)(\d\d)\s+/cg) {
      my @types = ("system"); # Traveller
      while($hex =~ /\G([a-z]="[^"]+")\s*/cg or $hex =~ /(\S+)/cg) {
	push(@types, $1);
      }
      $map_data->{"$x$y"} = \@types;
    }
  }
  return $map_data;
}

=item parse_map_lines

This does basic parsing of linear structures on the map as produced by Text
Mapper, for example:

     0302-0101 trail

We use C<compute_missing_points> to find all the missing points on the line.

=cut

my $line_re = qr/^(\d\d\d\d(?:-\d\d\d\d)+)\s+(\S+)/m;

sub parse_map_lines {
  my $map = shift;
  my @lines;
  while ($map =~ /$line_re/g) {
    my ($line, $type) = ($1, $2);
    my @points = compute_missing_points(split(/-/, $line));
    push(@lines, [$type, @points]);
  }
  return \@lines;
}

=item process_map_merge_lines

As we process lines, we want to do two things: if a hex is part of a linear
structure, we want to add the B<type> to the terrain features. Thus, given the
following hex and river, we want to add "river" to the terrain features of 0101:

    0801-0802-0703-0602-0503-0402-0302-0201-0101-0100 river

The (virtual) result:

    0101 dark-green trees village river

Furthermore, given another river like the following, we want to merge these
where they meet (at 0302):

    0701-0601-0501-0401-0302-0201-0101-0100 river

Again, the (virtual) result:

    0302 dark-green trees town river river-merge

If you look at the default map, here are some interesting situations:

A river starts at 0906 but it immediately merges with the river starting at 1005
thus it should be dropped entirely.

A trail starts at 0206 and passes through 0305 on the way to 0404 but it
shouldn't end at 0305 just because there's also a trail starting at 0305 going
north to 0302.

=cut

sub process_map_merge_lines {
  my $map_data = shift;
  my $lines = shift;
  for my $line (@$lines) {
    my $type = $line->[0];
    my %data = (type => $type, line => $line);
    # $log->debug("New $type...");
    my $start = 1;
  COORD:
    for my $i (1 .. $#$line) {
      my $coord = $line->[$i];
      # don't add data for hexes outside the map
      last unless $map_data->{$coord};
      # don't start a line going in the same direction as an existing line in
      # the same hex (e.g. 0906) but also don't stop a line if it runs into a
      # merge and continues (e.g. 0305)
      my $same_dir = 0;
      for my $line2 (grep { $_->{type} eq $type } @{$extra->{$coord}}) {
	if (same_direction($coord, $line, $line2->{line})) {
	  # $log->debug("... at $coord, @$line and @{$line2->{line}} go in the same direction");
	  $same_dir = 1;
	  last;
	}
      }
      if ($start and $same_dir) {
	# $log->debug("... skipping");
	last COORD;
      }
      # add type to the hex description, add "$type-merge" when
      # running into an existing one
      my $merged;
      if (not grep { $_ eq $type } @{$map_data->{$coord}}) {
	# $log->debug("...$type leading into $coord");
	push(@{$map_data->{$coord}}, $type);
      } elsif (not grep { $_ eq "$type-merge" } @{$map_data->{$coord}}) {
	$merged = $same_dir; # skip the rest of the line, if same dir
	# $log->debug("...noted merge into existing $type at $coord");
	push(@{$map_data->{$coord}}, "$type-merge");
      } else {
	$merged = $same_dir; # skip the rest of the line, if same dir
	# $log->debug("...leads into existing $type merge at $coord");
      }
      $start = 0;
      # all hexes along a line share this hash
      push(@{$extra->{$coord}}, \%data);
      # if a river merges into another, don't add any hexes downriver
      last if $merged;
    }
  }
}

=item process_map_start_lines

As we process lines, we also want to note the start of lines: sources of rivers,
the beginning of trails. Thus, given the following hex and river, we want to add
"river-start" to the terrain features of 0801:

    0801-0802-0703-0602-0503-0402-0302-0201-0101-0100 river

Adds a river to the hex:

    0801 light-grey mountain river river-start

But note that we don't want to do this where linear structures have merged. If a
trail ends at a town and merges with other trails there, it doesn't "start"
there. It can only be said to start somewhere if no other linear structure
starts there.

In case we're not talking about trails and rivers but things like routes from A
to B, it might be important to note the fact. Therefore, both ends of the line
get a "river-end" (if a river).

=cut

sub process_map_start_lines {
  my $map_data = shift;
  my $lines = shift;
  # add "$type-start" to the first and last hex of a line, unless it is a merge
  for my $line (@$lines) {
    my $type = $line->[0];
    for my $coord ($line->[1], $line->[$#$line]) {
      # ends get marked either way
      push(@{$map_data->{$coord}}, "$type-end") unless grep { $_ eq "$type-end" } @{$map_data->{$coord}};
      # skip hexes outside the map
      last unless $map_data->{$coord};
      # skip merges
      last if grep { $_ eq "$type-merge" } @{$map_data->{$coord}};
      # add start
      push(@{$map_data->{$coord}}, "$type-start");
    }
  }
}

=item parse_map

This calls all the map parsing and processing functions we just talked about.

=cut

sub parse_map {
  my $map = shift;
  my $map_data = parse_map_data($map);
  my $lines = parse_map_lines($map);
  # longest rivers first
  @$lines = sort { @$b <=> @$a } @$lines;
  # for my $line (@$lines) {
  #   $log->debug("@$line");
  # }
  process_map_merge_lines($map_data, $lines);
  process_map_start_lines($map_data, $lines);
  # for my $coord (sort keys %$map_data) {
  #   $log->debug(join(" ", $coord, @{$map_data->{$coord}}));
  # }
  return $map_data;
}

=item pick_description

Pick a description from a given table. In the example above, pick a random
number between 1 and 3 and then go through the list, addin up counts until you
hit that number.

If the result picked is unique, remove it from the list. That is, set it's count
to 0 such that it won't ever get picked again.

=cut

sub pick_description {
  my $h = shift;
  my $total = $h->{total};
  my $lines = $h->{lines};
  my $roll = int(rand($total)) + 1;
  my $i = 0;
  for my $line (@$lines) {
    $i += $line->{count};
    if ($i >= $roll) {
      if ($line->{unique}) {
	$h->{total} -= $line->{count};
	$line->{count} = 0;
      }
      return $line->{text};
    }
  }
  $log->error("picked nothing");
  return '';
}

=item resolve_redirect

This handles the special redirect syntax: request an URL and if the response
code is a 301 or 302, take the location header in the response and return it.

=cut

sub resolve_redirect {
  # If you install this tool on a server using HTTPS, then some browsers will
  # make sure that including resources from other servers will not work.
  my $url = shift;
  my $redirects = shift;
  return '' unless $redirects;
  # Special case because table writers probably used the default face generator URL
  $url =~ s!^https://campaignwiki\.org/face!$face_generator_url! if $face_generator_url;
  $url =~ s!^https://campaignwiki\.org/text-mapper!$text_mapper_url! if $text_mapper_url;
  my $ua = Mojo::UserAgent->new;
  my $res = eval { $ua->get($url)->result };
  if (not $res) {
    my $warning = $@;
    chomp($warning);
    $log->warn("connecting to $url: $warning");
    return "";
  } elsif ($res->code == 301 or $res->code == 302) {
    return Mojo::URL->new($res->headers->location)
	->base(Mojo::URL->new($url))
	->to_abs;
  }
  $log->info("resolving redirect for $url did not result in a redirection");
  return $url;
}

=item pick

This function picks the appropriate table given a particular word (usually a map
feature such as "forest" or "river").

This is where I<context> is implemented. Let's start with this hex:

    0101 dark-green trees village river trail

Remember that parsing the map added more terrain than was noted on the map
itself. Our function will get called for each of these words, Let's assume it
will get called for "dark-green". Before checking whether a table called
"dark-green" exists, we want to check whether any of the other words provide
enough context to pick a more specific table. Thus, we will check "trees
dark-green", "village dark-green", "river dark-green" and "trail dark-green"
before checking for "dark-green".

If such a table exists in C<$table_data>, we call C<pick_description> to pick a
text from the table and then we go through the text and call C<describe> to
resolve any table references in square brackets.

Remember that rules for the remaining words are still being called. Thus, if you
write a table for "trees dark-green" (which is going to be picked in preference
to "dark-green"), then there should be no table for "trees" because that's the
next word that's going to be processed!

=cut

sub pick {
  my $map_data = shift;
  my $table_data = shift;
  my $level = shift;
  my $coordinates = shift;
  my $words = shift;
  my $word = shift;
  my $redirects = shift;
  my $text;
  # Make sure we're testing all the context combinations first. Thus, if $words
  # is [ "mountains" white" "chaos"] and $word is "mountains", we want to test
  # "white mountains", "cold mountains" and "mountains", in this order.
  for my $context (grep( { $_ ne $word } @$words), $word) {
    my $key = ($context eq $word ? $word : "$context $word");
    # $log->debug("$coordinates: looking for a $key table") if $coordinates eq "0109";
    if ($table_data->{$key}) {
      $text = pick_description($table_data->{$key});
      # $log->debug("$coordinates → $key → $text");
      my $seed = int(rand(~0)); # maxint
      $text =~ s/\[\[redirect (https:.*?)\]\]/my $url = $1; $url =~ s!\$seed!$seed!; resolve_redirect($url, $redirects)/ge;
      # this makes sure we recursively resolve all references, in order, because
      # we keep rescanning from the beginning
      my $last = $text;
      while ($text =~ s/\[([^][]*)\]/describe($map_data,$table_data,$level+1,$coordinates,[$1], $redirects)/e) {
	if ($last eq $text) {
	  $log->error("Infinite loop: $text");
	  last;
	}
	$last = $text;
      };
      last;
    }
  }
  # $log->debug("$word → $text ") if $text;
  return $text;
}

=item describe

This is where all the references get resolved. We handle references to dice
rolls, the normal recursive table lookup, and all the special rules for names
that get saved once they have been determined both globally or per terrain
features. Please refer to the tutorial on the help page for the various
features.

=cut

sub describe {
  my $map_data = shift;
  my $table_data = shift;
  my $level = shift;
  my $coordinates = shift;
  my $words = shift;
  my $redirects = shift;
  $log->error("Recursion level $level exceeds 20 in $coordinates (@$words)!") if $level > 20;
  return '' if $level > 20;
  if ($level == 1) {
    %locals = (); # reset once per paragraph
    for my $word (@$words) {
      if ($word =~ /^([a-z]+)="(.*)"/ or
	  $word =~ /(.*)-(\d+)$/) {
	# assigments in the form uwp=“777777” assign “777777” to “uwp”
	# words in the form law-5 assign “5” to “law”
	$locals{$1} = $2;
      } else {
	$locals{$word} = 1;
      }
    }
  }
  my @descriptions;
  for my $word (@$words) {
    # valid dice rolls: 1d6, 1d6+1, 1d6x10, 1d6x10+1
    if (my ($just_save, $n, $d, $m, $p, $min, $max, $c, $save_as) = $word =~ /$dice_re/) {
      my $r = 0;
      if ($c) {
	$r = $c;
      } else {
	for(my $i = 0; $i < $n; $i++) {
	  $r += int(rand($d)) + 1;
	}
	$r *= $m||1;
	$r += $p||0;
	$r = $min if defined $min and $r < $min;
	$r = $max if defined $max and $r > $max;
      }
      # $log->debug("rolling dice: $word = $r");
      $locals{$save_as} = $r if $save_as;
      push(@descriptions, $r) unless $just_save;
    } elsif (my ($save, $expression, $as) = $word =~ /$math_re/) {
      my $r = eval($expression);
      $locals{$as} = $r if $as;
      push(@descriptions, $r) unless $save;
    } elsif ($word =~ /^(\S+)\?\|\|(.*)/) {
      # [a?||b] return b if a is defined, or nothing
      push(@descriptions, $2) if $locals{$1};
    } elsif ($word =~ /^!(\S+)\|\|(.*)/) {
      # [!a||b] return b if a is undefined
      push(@descriptions, $2) if not $locals{$1};
    } elsif (index($word, "||") != -1) {
      # [a||b] returns a if defined, otherwise b
      for my $html (split(/\|\|/, $word)) {
	my $copy = $html;
	$copy =~ s/<.*?>|…//g; # strip tags, e.g. span elements, and ellipsis
	if ($copy =~ /\S/) {
	  push(@descriptions, $html);
	  last;
	}
      }
    } elsif (index($word, "|") != -1) {
      # [a|b] returns one of a or b
      push(@descriptions, one(split(/\|/, $word)));
    } elsif ($word =~ /^name for an? /) {
      # for global things like factions, dukes
      my $name = $names{$word};
      # $log->debug("memoized: $word is $name") if $name;
      return $name if $name;
      $name = pick($map_data, $table_data, $level, $coordinates, $words, $word, $redirects);
      next unless $name;
      $names{$word} = $name;
      # $log->debug("$word is $name");
      push(@descriptions, $name);
    } elsif ($word =~ /^names for (\S+)/) {
      my $key = $1; # "river"
      # $log->debug("Looking at $key for $coordinates...");
      if (my @lines = grep { $_->{type} eq $key } @{$extra->{$coordinates}}) {
	# $log->debug("...@lines");
	# make sure all the lines (rivers, trails) are named
	my @names = ();
	for my $line (@lines) {
	  my $name = $line->{name};
	  if (not $name) {
	    $name ||= pick($map_data, $table_data, $level, $coordinates, $words, "name for $key", $redirects);
	    $line->{name} = $name;
	  }
	  push(@names, $name);
	}
	my $list;
	if (@names > 2) {
	  $list = join(", ", @names[0 .. $#names-1], "and " . $names[-1]);
	} elsif (@names == 2) {
	  $list = join(" and ", @names);
	} else {
	  $log->error("$coordinates has merge but just one line (@lines)");
	  $list = shift(@names);
	}
	$log->error("$coordinates uses merging rule without names") unless $list;
	next unless $list;
	push(@descriptions, $list);
      }
    } elsif ($word =~ /^name for (\S+)/) {
      my $key = $1; # "white" or "river"
      # $log->debug("Looking at $key for $coordinates...");
      if (my @lines = grep { $_->{type} eq $key } @{$extra->{$coordinates}}) {
	# for rivers and the like: "name for river"
	for my $line (@lines) {
	  # $log->debug("Looking at $word for $coordinates...");
	  my $name = $line->{name};
	  # $log->debug("... we already have a name: $name") if $name;
	  # if a type appears twice for a hex, this returns the same name for all of them
	  return $name if $name;
	  $name = pick($map_data, $table_data, $level, $coordinates, $words, $word, $redirects);
	  # $log->debug("... we picked a new name: $name") if $name;
	  next unless $name;
	  push(@descriptions, $name);
	  $line->{name} = $name;
	  $globals->{$key}->{$_} = $name for @{$line->{line}}[1..$#{$line->{line}}];
	  # name the first one without a name, don't keep adding names
	  last;
	}
      } else {
	# regular features: "name for white big mountain"
	my $name = $names{"$word: $coordinates"}; # "name for white big mountain: 0101"
	# $log->debug("$word for $coordinates is $name") if $name;
	return $name if $name;
	$name = pick($map_data, $table_data, $level, $coordinates, $words, $word, $redirects);
	# $log->debug("new $word for $coordinates is $name") if $name;
	next unless $name;
	$names{"$word: $coordinates"} = $name;
	push(@descriptions, $name);
	spread_name($map_data, $coordinates, $word, $key, $name) if %$map_data;
      }
    } elsif ($word eq 'adjacent hex') {
      # experimental
      my $location = $coordinates eq 'no map' ? 'somewhere' : one(neighbours($map_data, $coordinates));
      $locals{$word} = $location;
      return $location;
    } elsif ($word =~ /^(?:nearby|other|later) ./) {
      # skip on the first pass
      return "｢$word｣";
    } elsif ($word =~ /^append (.*)/) {
      my $text = pick($map_data, $table_data, $level, $coordinates, $words, $1, $redirects);
      # remember it's legitimate to have no result for a table
      next unless $text;
      $locals{$word} = $text;
      push(@descriptions, "｢append $text｣");
    } elsif ($word =~ /^same (.+)/) {
      my $key = $1;
      return $locals{$key}->[0] if exists $locals{$key} and ref($locals{$key}) eq 'ARRAY';
      return $locals{$key} if exists $locals{$key};
      return $globals->{$key}->{global} if $globals->{$key} and $globals->{$key}->{global};
      $log->warn("[same $key] is undefined for $coordinates, attempt picking a new one");
      my $text = pick($map_data, $table_data, $level, $coordinates, $words, $key, $redirects);
      if ($text) {
	$locals{$key} = $text;
	push(@descriptions, $text . "*");
      } else {
	$log->error("[$key] is undefined for $coordinates");
	push(@descriptions, "…");
      }
    } elsif ($word =~ /^(?:(here|global) )?with (.+?)(?: as (.+))?$/) {
      my ($where, $key, $alias) = ($1, $2, $3);
      my $text = pick($map_data, $table_data, $level, $coordinates, $words, $key, $redirects);
      next unless $text;
      $locals{$key} = [$text]; # start a new list
      $locals{$alias} = $text if $alias;
      $globals->{$key}->{$coordinates} = $text if $where and $where eq 'here';
      $globals->{$alias}->{$coordinates} = $text if $where and $where eq 'here' and $alias;
      $globals->{$key}->{global} = $text if $where and $where eq 'global';
      $globals->{$alias}->{global} = $text if $where and $where eq 'global' and $alias;
      push(@descriptions, $text);
    } elsif ($word =~ /^(?:(here|global) )?and (.+?)(?: as (.+))?$/) {
      my ($where, $key, $alias) = ($1, $2, $3);
      my $found = 0;
      # limited attempts to find a unique entry for an existing list (instead of
      # modifying the data structures)
      for (1 .. 20) {
	my $text = pick($map_data, $table_data, $level, $coordinates, $words, $key, $redirects);
	$log->warn("[and $key] is used before [with $key] is done in $coordinates") if ref $locals{$key} ne 'ARRAY';
	$locals{$key} = [$text] if ref $locals{$key} ne 'ARRAY';
	next if not $text or grep { $text eq $_ } @{$locals{$key}};
	push(@{$locals{$key}}, $text);
	push(@descriptions, $text);
	$locals{$alias} = $text if $alias;
	$globals->{$key}->{$coordinates} = $text if $where and $where eq 'here';
	$globals->{$alias}->{$coordinates} = $text if $where and $where eq 'here' and $alias;
	$globals->{$key}->{global} = $text if $where and $where eq 'global';
	$globals->{$alias}->{global} = $text if $where and $where eq 'global' and $alias;
	$found = 1;
	last;
      }
      if (not $found) {
	$log->warn("[and $key] not unique in $coordinates");
	push(@descriptions, "…");
      }
    } elsif ($word =~ /^capitalize (.+)/) {
      my $key = $1;
      my $text = pick($map_data, $table_data, $level, $coordinates, $words, $key, $redirects);
      next unless $text;
      $locals{$key} = $text;
      push(@descriptions, ucfirst $text);
    } elsif ($word =~ /^titlecase (.+)/) {
      my $key = $1;
      my $text = pick($map_data, $table_data, $level, $coordinates, $words, $key, $redirects);
      next unless $text;
      $locals{$key} = $text;
      push(@descriptions, autoformat($text, { case => 'titlecase' }));
    } elsif ($word =~ /^highlightcase (.+)/) {
      my $key = $1;
      my $text = pick($map_data, $table_data, $level, $coordinates, $words, $key, $redirects);
      next unless $text;
      $locals{$key} = $text;
      push(@descriptions, autoformat($text, { case => 'highlight' }));
    } elsif ($word =~ /^normalize-elvish (.+)/) {
      my $key = $1;
      my $text = normalize_elvish($key);
      next unless $text;
      $locals{$key} = $text;
      push(@descriptions, $text);
    } elsif ($word =~ /^(?:(here|global) )?(?:(save|store|quote) )?(.+?)(?: as (.+))?$/) {
      my ($where, $action, $key, $alias) = ($1, $2, $3, $4);
      my $text;
      if (not $action or $action eq "save") {
	# no action and save are with lookup
	$text = pick($map_data, $table_data, $level, $coordinates, $words, $key, $redirects);
      } else {
	# quote and store are without lookup
	$text = $key;
      }
      next unless $text;
      $locals{$key} = $text;
      $locals{$alias} = $text if $alias;
      $globals->{$key}->{$coordinates} = $text if $where and $where eq 'here';
      $globals->{$alias}->{$coordinates} = $text if $where and $where eq 'here' and $alias;
      $globals->{$key}->{global} = $text if $where and $where eq 'global';
      $globals->{$alias}->{global} = $text if $where and $where eq 'global' and $alias;
      push(@descriptions, $text) if not $action or $action eq "quote";
    } elsif ($level > 1 and not exists $table_data->{$word} and not $locals{$word}) {
      # on level one, many terrain types do not exist (e.g. river-start)
      $log->error("unknown table for $coordinates/$level: $word");
    } elsif ($level > 1 and not $table_data->{$word} and not $locals{$word}) {
      # on level one, many terrain types do not exist (e.g. river-start)
      $log->error("empty table for $coordinates/$level: $word");
    } else {
      my $text = pick($map_data, $table_data, $level, $coordinates, $words, $word, $redirects);
      # remember it's legitimate to have no result for a table, and remember we
      # cannot use a local with the same name that's defined because sometimes
      # locals are simply defined as "1" since they start out as "words" and I
      # don't want to make "1" a special case to ignore, here
      next unless defined $text;
      $locals{$word} = $text;
      push(@descriptions, $text);
    }
  }
  return join(' ', @descriptions);
}

=item describe_text

This function does what C<describe> does, but for simple text without hex
coordinates.

=cut

sub describe_text {
  my $input = shift;
  my $table_data = shift;
  my $redirects = shift;
  my @descriptions;
  init();
  for my $text (split(/\r?\n/, $input)) {
    # recusion level 2 makes sure we don't reset %locals
    $text =~ s/\[(.*?)\]/describe({},$table_data,2,"no map",[$1],$redirects)/ge;
    push(@descriptions, process($text, $redirects));
    %locals = (); # reset once per paragraph
  }
  return \@descriptions;
}

=item normalize_elvish

We do some post-processing of words, inspired by these two web pages, but using
our own replacements.
http://sindarinlessons.weebly.com/37---how-to-make-names-1.html
http://sindarinlessons.weebly.com/38---how-to-make-names-2.html

=cut

sub normalize_elvish {
  my $original = shift;
  my $name = $original;

  $name =~ s/(.) \1/$1/g;
  $name =~ s/d t/d/g;
  $name =~ s/a ui/au/g;
  $name =~ s/nd m/dhm/g;
  $name =~ s/n?d w/dhw/g;
  $name =~ s/r gw/rw/g;
  $name =~ s/^nd/d/;
  $name =~ s/^ng/g/;
  $name =~ s/th n?d/d/g;
  $name =~ s/dh dr/dhr/g;
  $name =~ s/ //g;

  $name =~ tr/âêîôûŷ/aeioúi/;
  $name =~ s/ll$/l/;
  $name =~ s/ben$/wen/g;
  $name =~ s/bwi$/wi/;
  $name =~ s/[^aeiouúi]ndil$/dil/g;
  $name =~ s/ae/aë/g;
  $name =~ s/ea/ëa/g;

  $name = ucfirst($name);

  # $log->debug("Elvish normalize: $original → $name");
  return $name;
}

=item process

We do some post-processing after the description has been assembled: we move all
the IMG tags in a SPAN element with class "images". This makes it easier to lay
out the result using CSS.

=cut

sub process {
  my $text = shift;
  my $images = shift;
  if ($images) {
    $text =~ s/(<img[^>]+?>)/<span class="images">$1<\/span>/g;
  } else {
    $text =~ s/(<img[^>]+?>)//g;
  }
  # fix whilespace at the end of spans
  $text =~ s/\s+<\/span>/<\/span> /g;
  # strip empty paragraphs
  $text =~ s/<p>\s*<\/p>//g;
  $text =~ s/<p>\s*<p>/<p>/g;
  # strip other empty elements
  $text =~ s/<em><\/em>//g;
  return $text;
}

=item resolve_appends

This removes text marked for appending and adds it at the end of a hex
description. This modifies the third parameter, C<$descriptions>.

=cut

sub resolve_appends {
  my $map_data = shift;
  my $table_data = shift;
  my $descriptions = shift;
  my $redirects = shift;
  my $text;
  for my $coord (keys %$descriptions) {
    while ($descriptions->{$coord} =~ s/｢append ([^][｣]*)｣/$text = $1; ""/e) {
      $descriptions->{$coord} .= ' ' . $text;
    }
  }
}

=item resolve_nearby

We have nearly everything resolved except for references starting with the word
"nearby" because these require all of the other data to be present. This
modifies the third parameter, C<$descriptions>.

=cut

sub resolve_nearby {
  my $map_data = shift;
  my $table_data = shift;
  my $descriptions = shift;
  my $redirects = shift;
  for my $coord (keys %$descriptions) {
    $descriptions->{$coord} =~
	s/｢nearby ([^][｣]*)｣/closest($map_data,$table_data,$coord,$1, $redirects) or '…'/ge
	for 1 .. 2; # two levels deep of ｢nearby ...｣
    $descriptions->{$coord} =~ s!( \(<a href="#desc\d+">\d+</a>\))</em>!</em>$1!g; # fixup
  }
}

=item closest

This picks the closest instance of whatever we're looking for, but not from the
same coordinates, obviously.

=cut

sub closest {
  my $map_data = shift;
  my $table_data = shift;
  my $coordinates = shift;
  my $key = shift;
  my $redirects = shift;
  my @coordinates = grep { $_ ne $coordinates and $_ ne 'global' } keys %{$globals->{$key}};
  if (not @coordinates) {
    $log->info("Did not find any hex with $key ($coordinates)");
    return "…";
  }
  if ($coordinates !~ /^\d+$/) {
    # if $coordinates is "TOP" or "END" or something like that, we cannot get
    # the closest one and we need to return a random one
    my $random = one(@coordinates);
    return $globals->{$key}->{$random}
    . qq{ (<a href="#desc$random">$random</a>)}; # see resolve_later!
  } else {
    @coordinates = sort { distance($coordinates, $a) <=> distance($coordinates, $b) } @coordinates;
    # the first one is the closest
    return $globals->{$key}->{$coordinates[0]}
    . qq{ (<a href="#desc$coordinates[0]">$coordinates[0]</a>)}; # see resolve_later!
  }
}

=item distance

Returns the distance between two hexes. Either provide two coordinates (strings
in the form "0101", "0102") or four numbers (1, 1, 1, 2).

=cut

sub distance {
  my ($x1, $y1, $x2, $y2) = @_;
  if (@_ == 2) {
    ($x1, $y1, $x2, $y2) = map { xy($_) } @_;
  }
  # transform the coordinate system into a decent system with one axis tilted by
  # 60°
  $y1 = $y1 - POSIX::ceil($x1/2);
  $y2 = $y2 - POSIX::ceil($x2/2);
  if ($x1 > $x2) {
    # only consider moves from left to right and transpose start and
    # end point to make it so
    my ($t1, $t2) = ($x1, $y1);
    ($x1, $y1) = ($x2, $y2);
    ($x2, $y2) = ($t1, $t2);
  }
  if ($y2>=$y1) {
    # if it the move has a downwards component add Δx and Δy
    return $x2-$x1 + $y2-$y1;
  } else {
    # else just take the larger of Δx and Δy
    return $x2-$x1 > $y1-$y2 ? $x2-$x1 : $y1-$y2;
  }
}

=item resolve_other

This is a second phase. We have nearly everything resolved except for references
starting with the word "other" because these require all of the other data to
be present. This modifies the third parameter, C<$descriptions>.

=cut

sub resolve_other {
  my $map_data = shift;
  my $table_data = shift;
  my $descriptions = shift;
  my $redirects = shift;
  for my $coord (keys %$descriptions) {
    $descriptions->{$coord} =~
	s/｢other ([^][｣]*)｣/some_other($map_data,$table_data,$coord,$1, $redirects) or '…'/ge;
    $descriptions->{$coord} =~ s!( \(<a href="#desc\d+">\d+</a>\))</em>!</em>$1!g; # fixup
  }
}

=item some_other

This picks some other instance of whatever we're looking for, irrespective of distance.

=cut

sub some_other {
  my $map_data = shift;
  my $table_data = shift;
  my $coordinates = shift;
  my $key = shift;
  my $redirects = shift;
  # make sure we don't pick the same location!
  my @coordinates = grep !/$coordinates/, keys %{$globals->{$key}};
  if (not @coordinates) {
    $log->info("Did not find any other hex with $key");
    return "…";
  }
  # just pick a random one
  my $other = one(@coordinates);
  return $globals->{$key}->{$other}
  . qq{ (<a href="#desc$other">$other</a>)}; # see resolve_later!
}


=item resolve_later

This is a second phase. We have nearly everything resolved except for references
starting with the word "later" because these require all of the other data to be
present. This modifies the third parameter, C<$descriptions>. Use this for
recursive lookup involving "nearby" and "other".

This also takes care of hex references introduced by "nearby" and "other". This
is also why we need to take extra care to call C<quotemeta> on various strings
we want to search and replace: these hex references contain parenthesis!

=cut

sub resolve_later {
  my $map_data = shift;
  my $table_data = shift;
  my $descriptions = shift;
  my $redirects = shift;
  for my $coord (keys %$descriptions) {
    while ($descriptions->{$coord} =~ /｢later ([^][｣]*)｣/) {
      my $words = $1;
      my ($ref) = $words =~ m!( \(<a href=".*">.*</a>\))!;
      $ref //= ''; # but why should it ever be empty?
      my $key = $words;
      my $re = quotemeta($ref);
      $key =~ s/$re// if $ref;
      $re = quotemeta($words);
      my $result = $descriptions->{$coord} =~
	  s/｢later $re｣/describe($map_data,$table_data,1,$coord,[$key], $redirects) . $ref or '…'/ge;
      if (not $result) {
	$log->error("Could not resolve later reference in '$words'");
	last; # avoid infinite loops!
      }
    }
  }
}

=item describe_map

This is one of the top entry points: it simply calls C<describe> for every hex
in C<$map_data> and calls C<process> on the result. All the texts are collected
into a new hash where the hex coordinates are the key and the generated
description is the value.

=cut

sub describe_map {
  my $map_data = shift;
  my $table_data = shift;
  my $redirects = shift;
  my %descriptions;
  # first, add special rule for TOP and END keys which the description template knows
  for my $coords (qw(TOP END)) {
    # with redirects means we keep images
    my $description =
	process(describe($map_data, $table_data, 1,
			 $coords, [$coords], $redirects), $redirects);
    # only set the TOP and END key if there is a description
    $descriptions{$coords} = $description if $description;
  }
  # shuffle sort the coordinates so that it is reproducibly random
  for my $coord (shuffle sort keys %$map_data) {
    # with redirects means we keep images
    my $description =
	process(describe($map_data, $table_data, 1,
			 $coord, $map_data->{$coord}, $redirects), $redirects);
    # only set the description if there is one (empty hexes are not listed)
    $descriptions{$coord} = $description if $description;
  }
  resolve_nearby($map_data, $table_data, \%descriptions, $redirects);
  resolve_other($map_data, $table_data, \%descriptions, $redirects);
  resolve_later($map_data, $table_data, \%descriptions, $redirects);
  # as append might include the items above, it must come last
  resolve_appends($map_data, $table_data, \%descriptions, $redirects);
  return \%descriptions;
}

=item add_labels

This function is used after generating the descriptions to add the new names of
rivers and trails to the existing map.

=cut

sub add_labels {
  my $map = shift;
  $map =~ s/$line_re/get_label($1,$2)/ge;
  return $map;
}

=item get_label

This function returns the name of a line.

=cut

sub get_label {
  my $map_line = shift;
  my $type = shift;
  my @hexes = split(/-/, $map_line);
 LINE:
  for my $line (@{$extra->{$hexes[0]}}) {
    next unless $line->{type} eq $type;
    for my $hex (@hexes) {
      my @line = @{$line->{line}};
      next LINE unless grep(/$hex/, @line);
    }
    my $label = $line->{name};
    return qq{$map_line $type "$label"};
  }
  return qq{$map_line $type};
}

=item xy

This is a helper function to turn "0101" into ("01", "01") which is equivalent
to (1, 1).

=cut

sub xy {
  my $coordinates = shift;
  return (substr($coordinates, 0, 2), substr($coordinates, 2));
}

=item coordinates

This is a helper function to turn (1, 1) back into "0101".

=cut

sub coordinates {
  my ($x, $y) = @_;
  return sprintf("%02d%02d", $x, $y);
}

=item neighbour

This is a helper function that takes the coordinates of a hex, a reference like
[1,1] or regular coordinates like "0101", and a direction from 0 to 5, and
returns the coordinates of the neighbouring hex in that direction.

=cut

my $delta = [[[-1,  0], [ 0, -1], [+1,  0], [+1, +1], [ 0, +1], [-1, +1]],  # x is even
	     [[-1, -1], [ 0, -1], [+1, -1], [+1,  0], [ 0, +1], [-1,  0]]]; # x is odd

sub neighbour {
  # $hex is [x,y] or "0101" and $i is a number 0 .. 5
  my ($hex, $i) = @_;
  $hex = [xy($hex)] unless ref $hex;
  # return is a string like "0102"
  return coordinates(
    $hex->[0] + $delta->[$hex->[0] % 2]->[$i]->[0],
    $hex->[1] + $delta->[$hex->[0] % 2]->[$i]->[1]);
}

=item neighbours

This is a helper function that takes map_data and the coordinates of a hex, a
reference like [1,1] or regular coordinates like "0101", and returns a list of
existing neighbours, or the string "[…]". This makes a difference at the edge of
the map.

=cut

sub neighbours {
  my $map_data = shift;
  my $hex = shift;
  my @neighbours;
  $hex = [xy($hex)] unless ref $hex;
  for my $i (0 .. 5) {
    my $neighbour = neighbour($hex, $i);
    # $log->debug($neighbour);
    push(@neighbours, $neighbour) if $map_data->{$neighbour};
  }
  return "..." unless @neighbours;
  return @neighbours;
}

=item one

This is a helper function that picks a random element from a list. This works
both for actual lists and for references to lists.

=cut

sub one {
  my @arr = @_;
  @arr = @{$arr[0]} if @arr == 1 and ref $arr[0] eq 'ARRAY';
  return $arr[int(rand(scalar @arr))];
}

=item one_step_to

Given a hex to start from, check all directions and figure out which neighbour
is closer to your destination. Return the coordinates of this neighbour.

=cut

sub one_step_to {
  my $from = shift;
  my $to = shift;
  my ($min, $best);
  for my $i (0 .. 5) {
    # make a new guess
    my ($x, $y) = ($from->[0] + $delta->[$from->[0] % 2]->[$i]->[0],
		   $from->[1] + $delta->[$from->[0] % 2]->[$i]->[1]);
    my $d = ($to->[0] - $x) * ($to->[0] - $x)
          + ($to->[1] - $y) * ($to->[1] - $y);
    if (!defined($min) || $d < $min) {
      $min = $d;
      $best = [$x, $y];
    }
  }
  return $best;
}

=item compute_missing_points

Return a list of coordinates in string form. Thus, given a list like ("0302",
"0101") it will return ("0302", "0201", "0101").

=cut

sub compute_missing_points {
  my @result = ($_[0]); # "0101" not [01,02]
  my @points = map { [xy($_)] } @_;
  # $log->debug("Line: " . join(", ", map { coordinates(@$_) } @points));
  my $from = shift(@points);
  while (@points) {
    # $log->debug("Going from " . coordinates(@$from) . " to " . coordinates(@{$points[0]}));
    $from = one_step_to($from, $points[0]);
    shift(@points) if $from->[0] == $points[0]->[0] and $from->[1] == $points[0]->[1];
    push(@result, coordinates(@$from));
  }
  return @result;
}

=item same_direction

Given two linear structures and a point of contact, return 1 if the these
objects go in the same direction on way or the other.

=cut

sub same_direction {
  my $coord = shift;
  my $line1 = shift;
  my $line2 = shift;
  # $log->debug("same_direction: $coord, @$line1 and @$line2");
  # this code assumes that a line starts with $type at index 0
  my $j;
  for my $i (1 .. $#$line1) {
    if ($line1->[$i] eq $coord) {
      $j = $i;
      last;
    }
  }
  # $log->debug("same_direction: $coord has index $j in @$line1");
  for my $i1 ($j - 1, $j + 1) {
    next if $i1 == 0 or $i1 > $#$line1;
    my $next = $line1->[$i1];
    for my $i2 (1 .. $#$line2) {
      if ($line2->[$i2] eq $coord) {
	if ($line2->[$i2-1] and $next eq $line2->[$i2-1]
	    or $line2->[$i2+1] and $next eq $line2->[$i2+1]) {
	  # $log->debug("same direction at $coord: @$line1 and @$line2");
	  return 1;
	}
      }
    }
  }
  return 0;
}

=item spread_name

This function is used to spread a name along terrain features.

=cut

sub spread_name {
  my $map_data = shift;
  my $coordinates = shift;
  my $word = shift; # "name for white big mountain"
  my $key = shift; # "white"
  my @keys = split(/\//, $key); # ("white")
  my $name = shift; # "Vesuv"
  my %seen = ($coordinates => 1);
  $globals->{$key}->{$coordinates} = $name;
  # $log->debug("$word: $coordinates = $name");
  my @queue = map { neighbour($coordinates, $_) } 0..5;
  while (@queue) {
    # $log->debug("Working on the first item of @queue");
    my $coord = shift(@queue);
    next if $seen{$coord} or not $map_data->{$coord};
    $seen{$coord} = 1;
    if (intersect(@keys, @{$map_data->{$coord}})) {
      $log->error("$word for $coord is already something else")
	  if $names{"$word for $coord"};
      $names{"$word: $coord"} = $name; # "name for white big mountain: 0102"
      # $log->debug("$coord: $name for @keys");
      $globals->{$_}->{$coord} = $name for @keys;
      # $log->debug("$word: $coord = $name");
      push(@queue, map { neighbour($coord, $_) } 0..5);
    }
  }
}

=item markdown

This allows us to generate Markdown output.

=cut

sub markdown {
  my $descriptions = shift;
  my $separator = shift || "\n\n---\n\n";
  my @paragraphs = map {
    # remove inline images
    s!<img[^>]*>!!g;
    # empty spans left after img has been removed
    s!<span[^>]*>\s*</span>!!g;
    # remaining spans result in Japanese brackets around their text
    s!<span[^>]*>\s*!｢!g;
    s!\s*</span>!｣!g;
    # emphasis
    s!</?(strong|b)>!**!g;
    s!</?(em|i)>!*!g;
    s!</?u>!_!g;
    # remove links but leave their text
    s!</?a\b[^>]*>!!g;
    # closing paragraph tags are optional
    s!</p>!!g;
    # paragraph breaks
    s!<p.*?>!\n\n!g;
    # blockquotes
    s!<blockquote>(.*?)</blockquote>!local $_ = $1; s/^/\n> /g; $_!gem;
    # unreplaced references (nearby, other, later)
    s!(.*?)!$1!g;
    # return what's left
    markdown_lists($_);
  } @$descriptions;
  return join($separator, @paragraphs);
}

sub markdown_lists {
  $_ = shift;
  my ($str, @list);
  for (split(/(<.*?>)/)) {
    if (/^<ol.*>$/) { unshift(@list, '1.'); $str .= "\n" }
    elsif (/^<ul.*>$/) { unshift(@list, '*'); $str .= "\n" }
    elsif (/^<li>$/) { $str .= " " x (4 * @list) . $list[0] . " " }
    elsif (/^<\/(ol|ul)>$/) { shift(@list) }
    elsif (/^<\/li>$/) { $str .= "\n" unless $str =~ /\n$/ }
    else { $str .= $_ }
  }
  return $str;
}

1;
