#!/usr/bin/env perl
# Copyright (C) 2009-2022  Alex Schroeder <alex@gnu.org>
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

package Game::TextMapper;

our $VERSION = 1.05;

use Game::TextMapper::Log;
use Game::TextMapper::Point;
use Game::TextMapper::Line;
use Game::TextMapper::Mapper::Hex;
use Game::TextMapper::Mapper::Square;
use Game::TextMapper::Smale;
use Game::TextMapper::Apocalypse;
use Game::TextMapper::Gridmapper;
use Game::TextMapper::Schroeder::Alpine;
use Game::TextMapper::Schroeder::Archipelago;
use Game::TextMapper::Schroeder::Island;
use Game::TextMapper::Traveller;

use Modern::Perl '2018';
use Mojolicious::Lite;
use Mojo::DOM;
use Mojo::Util qw(url_escape xml_escape);
use File::ShareDir 'dist_dir';
use Pod::Simple::HTML;
use Pod::Simple::Text;
use List::Util qw(none);
use Cwd;

# Commands for the command line!
push @{app->commands->namespaces}, 'Game::TextMapper::Command';

# Change scheme if "X-Forwarded-Proto" header is set (presumably to HTTPS)
app->hook(before_dispatch => sub {
  my $c = shift;
  $c->req->url->base->scheme('https')
      if $c->req->headers->header('X-Forwarded-Proto') } );

plugin Config => {
  default => {
    loglevel => 'warn',
    logfile => undef,
    contrib => undef,
  },
  file => getcwd() . '/text-mapper.conf',
};

my $log = Game::TextMapper::Log->get;
$log->level(app->config('loglevel'));
$log->path(app->config('logfile'));
$log->info($log->path ? "Logfile is " . $log->path : "Logging to stderr");

my $dist_dir = app->config('contrib') // dist_dir('Game-TextMapper');
$log->debug("Reading contrib files from $dist_dir");

get '/' => sub {
  my $c = shift;
  my $param = $c->param('map');
  if ($param) {
    my $mapper;
    if ($c->param('type') and $c->param('type') eq 'square') {
      $mapper = Game::TextMapper::Mapper::Square->new(dist_dir => $dist_dir);
    } else {
      $mapper = Game::TextMapper::Mapper::Hex->new(dist_dir => $dist_dir);
    }
    $mapper->initialize($param);
    $c->render(text => $mapper->svg, format => 'svg');
  } else {
    my $mapper = new Game::TextMapper::Mapper;
    my $map = $mapper->initialize('')->example();
    $c->render(template => 'edit', map => $map);
  }
};

any '/edit' => sub {
  my $c = shift;
  my $mapper = new Game::TextMapper::Mapper;
  my $map = $c->param('map') || $mapper->initialize('')->example();
  $c->render(map => $map);
};

any '/render' => sub {
  my $c = shift;
  my $mapper;
  if ($c->param('type') and $c->param('type') eq 'square') {
    $mapper = Game::TextMapper::Mapper::Square->new(dist_dir => $dist_dir);
  } else {
    $mapper = Game::TextMapper::Mapper::Hex->new(dist_dir => $dist_dir);
  }
  $mapper->initialize($c->param('map'));
  $c->render(text => $mapper->svg, format => 'svg');
};

get '/:type/redirect' => sub {
  my $self = shift;
  my $type = $self->param('type');
  my $rooms = $self->param('rooms');
  my $seed = $self->param('seed');
  my $caves = $self->param('caves');
  my %params = ();
  $params{rooms} = $rooms if $rooms;
  $params{seed} = $seed if $seed;
  $params{caves} = $caves if $caves;
  $self->redirect_to($self->url_for($type . "random")->query(%params));
} => 'redirect';

# alias for /smale
get '/random' => sub {
  my $c = shift;
  my $bw = $c->param('bw');
  my $width = $c->param('width');
  my $height = $c->param('height');
  $c->render(template => 'edit', map => Game::TextMapper::Smale->new->generate_map($width, $height, $bw));
};

get '/smale' => sub {
  my $c = shift;
  my $bw = $c->param('bw');
  my $width = $c->param('width');
  my $height = $c->param('height');
  if ($c->stash('format')||'' eq 'txt') {
    $c->render(text => Game::TextMapper::Smale->new->generate_map($width, $height));
  } else {
    $c->render(template => 'edit',
	       map => Game::TextMapper::Smale->new->generate_map($width, $height, $bw));
  }
};

get '/smale/random' => sub {
  my $c = shift;
  my $bw = $c->param('bw');
  my $width = $c->param('width');
  my $height = $c->param('height');
  my $map = Game::TextMapper::Smale->new->generate_map($width, $height, $bw);
  my $svg = Game::TextMapper::Mapper::Hex->new(dist_dir => $dist_dir)
      ->initialize($map)
      ->svg();
  $c->render(text => $svg, format => 'svg');
};

get '/smale/random/text' => sub {
  my $c = shift;
  my $bw = $c->param('bw');
  my $width = $c->param('width');
  my $height = $c->param('height');
  my $text = Game::TextMapper::Smale->new->generate_map($width, $height, $bw);
  $c->render(text => $text, format => 'txt');
};

sub alpine_map {
  my $c = shift;
  # must be able to override this for the documentation
  my $step = shift // $c->param('step');
  # need to compute the seed here so that we can send along the URL
  my $seed = $c->param('seed') || int(rand(1000000000));
  my $url = $c->url_with('alpinedocument')->query({seed => $seed})->to_abs;
  my @params = ($c->param('width'),
		$c->param('height'),
		$c->param('steepness'),
		$c->param('peaks'),
		$c->param('peak'),
		$c->param('bumps'),
		$c->param('bump'),
		$c->param('bottom'),
		$c->param('arid'),
		$c->param('wind'),
		$seed,
		$url,
		$step,
      );
  my $type = $c->param('type') // 'hex';
  if ($type eq 'hex') {
    return Game::TextMapper::Schroeder::Alpine
	->with_roles('Game::TextMapper::Schroeder::Hex')->new()
	->generate_map(@params);
  } else {
    return Game::TextMapper::Schroeder::Alpine
	->with_roles('Game::TextMapper::Schroeder::Square')->new()
	->generate_map(@params);
  }
}

get '/alpine' => sub {
  my $c = shift;
  my $map = alpine_map($c);
  if ($c->stash('format') || '' eq 'txt') {
    $c->render(text => $map);
  } else {
    $c->render(template => 'edit', map => $map);
  }
};

get '/alpine/random' => sub {
  my $c = shift;
  my $map = alpine_map($c);
  my $type = $c->param('type') // 'hex';
  my $mapper;
  if ($type eq 'hex') {
    $mapper = Game::TextMapper::Mapper::Hex->new(dist_dir => $dist_dir);
  } else {
    $mapper = Game::TextMapper::Mapper::Square->new(dist_dir => $dist_dir);
  }
  my $svg = $mapper->initialize($map)->svg;
  $c->render(text => $svg, format => 'svg');
};

get '/alpine/random/text' => sub {
  my $c = shift;
  my $map = alpine_map($c);
  $c->render(text => $map, format => 'txt');
};

get '/alpine/document' => sub {
  my $c = shift;
  # prepare a map for every step
  my @maps;
  my $type = $c->param('type') || 'hex';
  # use the same seed for all the calls
  my $seed = $c->param('seed');
  if (not defined $seed) {
    $seed = int(rand(1000000000));
    $c->param('seed' => $seed);
  }
  for my $step (1 .. 18) {
    my $map = alpine_map($c, $step);
    my $mapper;
    if ($type eq 'hex') {
      $mapper = Game::TextMapper::Mapper::Hex->new(dist_dir => $dist_dir);
    } else {
      $mapper = Game::TextMapper::Mapper::Square->new(dist_dir => $dist_dir);
    }
    my $svg = $mapper->initialize($map)->svg;
    $svg =~ s/<\?xml version="1.0" encoding="UTF-8" standalone="no"\?>\n//g;
    push(@maps, $svg);
  };
  $c->stash("maps" => \@maps);

  # The documentation needs all the defaults of Alpine::generate_map (but
  # we'd like to use a smaller map because it is so slow).
  my $width = $c->param('width') // 20;
  my $height = $c->param('height') // 5; # instead of 10
  my $steepness = $c->param('steepness') // 3;
  my $peaks = $c->param('peaks') // int($width * $height / 40);
  my $peak = $c->param('peak') // 10;
  my $bumps = $c->param('bumps') // int($width * $height / 40);
  my $bump = $c->param('bump') // 2;
  my $bottom = $c->param('bottom') // 0;
  my $arid = $c->param('arid') // 2;

  # Generate the documentation text based on the stashed maps.
  $c->render(template => 'alpine_document',
	     seed => $seed,
	     width => $width,
	     height => $height,
	     steepness => $steepness,
	     peaks => $peaks,
	     peak => $peak,
	     bumps => $bumps,
	     bump => $bump,
	     bottom => $bottom,
	     arid => $arid);
};

get '/alpine/parameters' => sub {
  my $c = shift;
  $c->render(template => 'alpine_parameters');
};

# does not handle z coordinates
sub border_modification {
  my ($map, $top, $left, $right, $bottom, $empty) = @_;
  my (@lines, @temp, %seen);
  my ($x, $y, $points, $text);
  my ($minx, $miny, $maxx, $maxy);
  # shift map around
  foreach (split(/\r?\n/, $map)) {
    if (($x, $y, $text) = /^(\d\d)(\d\d)\s+(.*)/) {
      $minx = $x if not defined $minx or $x < $minx;
      $miny = $y if not defined $miny or $y < $miny;
      $maxx = $x if not defined $maxx or $x > $maxx;
      $maxy = $y if not defined $maxy or $y > $maxy;
      my $point = Game::TextMapper::Point->new(x => $x + $left, y => $y + $top);
      $seen{$point->coordinates} = 1 if $empty;
      push(@lines, [$point, $text]);
    } elsif (($points, $text) = /^(-?\d\d-?\d\d(?:--?\d\d-?\d\d)+)\s+(.*)/) {
      my @numbers = $points =~ /\G(-?\d\d)(-?\d\d)-?/cg;
      my @points;
      while (@numbers) {
	my ($x, $y) = splice(@numbers, 0, 2);
	push(@points, Game::TextMapper::Point->new(x => $x + $left, y => $y + $top));
      }
      push(@lines, [Game::TextMapper::Line->new(points => \@points), $text]);
    } else {
      push(@lines, $_);
    }
  }
  # only now do we know the extent of the map
  $maxx += $left + $right;
  $maxy += $top + $bottom;
  # with that information we can now determine what lies outside the map
  @temp = ();
  foreach (@lines) {
    if (ref) {
      my ($it, $text) = @$_;
      if (ref($it) eq 'Game::TextMapper::Point') {
	if ($it->x <= $maxx and $it->x >= $minx
	    and $it->y <= $maxy and $it->y >= $miny) {
	  push(@temp, $_);
	}
      } else { # Game::TextMapper::Line
	my $outside = none {
	  ($_->x <= $maxx and $_->x >= $minx
	   and $_->y <= $maxy and $_->y >= $miny)
	} @{$it->points};
	push(@temp, $_) unless $outside;
      }
    } else {
      push(@temp, $_);
    }
  }
  @lines = @temp;
  # add missing hexes, if requested
  if ($empty) {
    for $x ($minx .. $maxx) {
      for $y ($miny .. $maxy) {
	my $point = Game::TextMapper::Point->new(x => $x, y => $y);
	if (not $seen{$point->coordinates}) {
	  push(@lines, [$point, "empty"]);
	}
      }
    }
    # also, sort regions before trails before others
    @lines = sort {
      (# arrays before strings
       ref($b) cmp ref($a)
       # string comparison if both are strings
       or not(ref($a)) and not(ref($b)) and $a cmp $b
       # if we get here, we know both are arrays
       # points before lines
       or ref($b->[0]) cmp ref($a->[0])
       # if both are points, compare the coordinates
       or ref($a->[0]) eq 'Game::TextMapper::Point' and $a->[0]->cmp($b->[0])
       # if both are lines, compare the first two coordinates (the minimum line length)
       or ref($a->[0]) eq 'Game::TextMapper::Line' and ($a->[0]->points->[0]->cmp($b->[0]->points->[0])
				      or $a->[0]->points->[1]->cmp($b->[0]->points->[1]))
       # if bot are the same point (!) …
       or 0)
    } @lines;
  }
  $map = join("\n",
	      map {
		if (ref) {
		  my ($it, $text) = @$_;
		  if (ref($it) eq 'Game::TextMapper::Point') {
		    Game::TextMapper::Point::coord($it->x, $it->y) . " " . $text
		  } else {
		    my $points = $it->points;
		    join("-",
			 map { Game::TextMapper::Point::coord($_->x, $_->y) } @$points)
			. " " . $text;
		  }
		} else {
		  $_;
		}
	      } @lines) . "\n";
  return $map;
}

any '/borders' => sub {
  my $c = shift;
  my $map = border_modification(map { $c->param($_) } qw(map top left right bottom empty));
  $c->param('map', $map);
  $c->render(template => 'edit', map => $map);
};

sub island_map {
  my $c = shift;
  # must be able to override this for the documentation
  my $step = shift // $c->param('step');
  # need to compute the seed here so that we can send along the URL
  my $seed = $c->param('seed') || int(rand(1000000000));
  my $url = $c->url_with('islanddocument')->query({seed => $seed})->to_abs;
  my @params = ($c->param('width'),
		$c->param('height'),
		$c->param('radius'),
		$seed,
		$url,
		$step,
      );
  my $type = $c->param('type') // 'hex';
  if ($type eq 'hex') {
    return Game::TextMapper::Schroeder::Island
	->with_roles('Game::TextMapper::Schroeder::Hex')->new()
	->generate_map(@params);
  } else {
    return Game::TextMapper::Schroeder::Island
	->with_roles('Game::TextMapper::Schroeder::Square')->new()
	->generate_map(@params);
  }
}

get '/island' => sub {
  my $c = shift;
  my $map = island_map($c);
  if ($c->stash('format') || '' eq 'txt') {
    $c->render(text => $map);
  } else {
    $c->render(template => 'edit', map => $map);
  }
};

get '/island/random' => sub {
  my $c = shift;
  my $map = island_map($c);
  my $type = $c->param('type') // 'hex';
  my $mapper;
  if ($type eq 'hex') {
    $mapper = Game::TextMapper::Mapper::Hex->new(dist_dir => $dist_dir);
  } else {
    $mapper = Game::TextMapper::Mapper::Square->new(dist_dir => $dist_dir);
  }
  my $svg = $mapper->initialize($map)->svg;
  $c->render(text => $svg, format => 'svg');
};

sub archipelago_map {
  my $c = shift;
  # must be able to override this for the documentation
  my $step = shift // $c->param('step');
  # need to compute the seed here so that we can send along the URL
  my $seed = $c->param('seed') || int(rand(1000000000));
  my $url = $c->url_with('archipelagodocument')->query({seed => $seed})->to_abs;
  my @params = ($c->param('width'),
		$c->param('height'),
		$c->param('concentration'),
		$c->param('eruptions'),
		$c->param('top'),
		$c->param('bottom'),
		$seed,
		$url,
		$step,
      );
  my $type = $c->param('type') // 'hex';
  if ($type eq 'hex') {
    return Game::TextMapper::Schroeder::Archipelago
	->with_roles('Game::TextMapper::Schroeder::Hex')->new()
	->generate_map(@params);
  } else {
    return Game::TextMapper::Schroeder::Archipelago
	->with_roles('Game::TextMapper::Schroeder::Square')->new()
	->generate_map(@params);
  }
}

get '/archipelago' => sub {
  my $c = shift;
  my $map = archipelago_map($c);
  if ($c->stash('format') || '' eq 'txt') {
    $c->render(text => $map);
  } else {
    $c->render(template => 'edit', map => $map);
  }
};

get '/archipelago/random' => sub {
  my $c = shift;
  my $map = archipelago_map($c);
  my $type = $c->param('type') // 'hex';
  my $mapper;
  if ($type eq 'hex') {
    $mapper = Game::TextMapper::Mapper::Hex->new(dist_dir => $dist_dir);
  } else {
    $mapper = Game::TextMapper::Mapper::Square->new(dist_dir => $dist_dir);
  }
  my $svg = $mapper->initialize($map)->svg;
  $c->render(text => $svg, format => 'svg');
};

sub gridmapper_map {
  my $c = shift;
  my $seed = $c->param('seed') || int(rand(1000000000));
  my $pillars = $c->param('pillars') // 1;
  my $rooms = $c->param('rooms') // 5;
  my $caves = $c->param('caves') // 0;
  srand($seed);
  return Game::TextMapper::Gridmapper->new()
      ->generate_map($pillars, $rooms, $caves);
}

get '/gridmapper' => sub {
  my $c = shift;
  my $map = gridmapper_map($c);
  if ($c->stash('format') || '' eq 'txt') {
    $c->render(text => $map);
  } else {
    $c->render(template => 'edit', map => $map);
  }
};

get '/gridmapper/random' => sub {
  my $c = shift;
  my $map = gridmapper_map($c);
  my $mapper = Game::TextMapper::Mapper::Square->new(dist_dir => $dist_dir);
  my $svg = $mapper->initialize($map)->svg;
  $c->render(text => $svg, format => 'svg');
};

get '/gridmapper/random/text' => sub {
  my $c = shift;
  my $map = gridmapper_map($c);
  $c->render(text => $map, format => 'txt');
};

sub apocalypse_map {
  my $c = shift;
  my $seed = $c->param('seed') || int(rand(1000000000));
  srand($seed);
  my $hash = $c->req->params->to_hash;
  return Game::TextMapper::Apocalypse->new(%$hash)
      ->generate_map();
}

get '/apocalypse' => sub {
  my $c = shift;
  my $map = apocalypse_map($c);
  if ($c->stash('format') || '' eq 'txt') {
    $c->render(text => $map);
  } else {
    $c->render(template => 'edit', map => $map);
  }
};

get '/apocalypse/random' => sub {
  my $c = shift;
  my $map = apocalypse_map($c);
  my $mapper = Game::TextMapper::Mapper::Hex->new(dist_dir => $dist_dir);
  my $svg = $mapper->initialize($map)->svg;
  $c->render(text => $svg, format => 'svg');
};

get '/apocalypse/random/text' => sub {
  my $c = shift;
  my $map = apocalypse_map($c);
  $c->render(text => $map, format => 'txt');
};

sub star_map {
  my $c = shift;
  my $seed = $c->param('seed') || int(rand(1000000000));
  srand($seed);
  my $hash = $c->req->params->to_hash;
  return Game::TextMapper::Traveller->new(%$hash)->generate_map();
}

get '/traveller' => sub {
  my $c = shift;
  my $map = star_map($c);
  if ($c->stash('format') || '' eq 'txt') {
    $c->render(text => $map);
  } else {
    $c->render(template => 'edit', map => $map);
  }
};

get '/traveller/random' => sub {
  my $c = shift;
  my $map = star_map($c);
  my $mapper = Game::TextMapper::Mapper::Hex->new(dist_dir => $dist_dir);
  my $svg = $mapper->initialize($map)->svg;
  $c->render(text => $svg, format => 'svg');
};

get '/traveller/random/text' => sub {
  my $c = shift;
  my $map = star_map($c);
  $c->render(text => $map, format => 'txt');
};

get '/help' => sub {
  my $c = shift;

  seek(DATA,0,0);
  local $/ = undef;
  my $pod = <DATA>;
  $pod =~ s/=head1 NAME\n.*=head1 DESCRIPTION/=head1 Text Mapper/gs;
  my $parser = Pod::Simple::HTML->new;
  $parser->html_header_after_title('');
  $parser->html_header_before_title('');
  $parser->title_prefix('<!--');
  $parser->title_postfix('-->');
  my $html;
  $parser->output_string(\$html);
  $parser->parse_string_document($pod);

  my $dom = Mojo::DOM->new($html);
  for my $pre ($dom->find('pre')->each) {
    my $map = $pre->text;
    $map =~ s/^    //mg;
    next if $map =~ /^perl/; # how to call it
    my $url = $c->url_for('render')->query(map => $map);
    $pre->replace("<pre>" . xml_escape($map) . "</pre>\n"
		  . qq{<p class="example"><a href="$url">Render this example</a></p>});
  }

  $c->render(html => $dom);
};

app->start;

__DATA__

=encoding utf8

=head1 NAME

Game::TextMapper - a web app to generate maps based on text files

=head1 DESCRIPTION

The script parses a text description of a hex map and produces SVG output. Use
your browser to view SVG files and use Inkscape to edit them.

=head2 Tutorial

Note that if you look at the help page
L<online|https://campaignwiki.org/text-mapper/help> there are links to run all
these examples.

Here's a small example:

    grass attributes fill="green"
    0101 grass

We probably want lighter colors.

    grass attributes fill="#90ee90"
    0101 grass

First, we defined the SVG attributes of a hex B<type> and then we
listed the hexes using their coordinates and their type. Adding more
types and extending the map is easy:

    grass attributes fill="#90ee90"
    sea attributes fill="#afeeee"
    0101 grass
    0102 sea
    0201 grass
    0202 sea

You might want to define more SVG attributes such as a border around
each hex:

    grass attributes fill="#90ee90" stroke="black" stroke-width="1px"
    0101 grass

The attributes for the special type B<default> will be used for the
hex layer that is drawn on top of it all. This is where you define the
I<border>.

    default attributes fill="none" stroke="black" stroke-width="1px"
    grass attributes fill="#90ee90"
    sea attributes fill="#afeeee"
    0101 grass
    0102 sea
    0201 grass
    0202 sea

You can define the SVG attributes for the B<text> in coordinates as
well.

    text font-family="monospace" font-size="10pt"
    default attributes fill="none" stroke="black" stroke-width="1px"
    grass attributes fill="#90ee90"
    sea attributes fill="#afeeee"
    0101 grass
    0102 sea
    0201 grass
    0202 sea

You can provide a text B<label> to use for each hex:

    text font-family="monospace" font-size="10pt"
    default attributes fill="none" stroke="black" stroke-width="1px"
    grass attributes fill="#90ee90"
    sea attributes fill="#afeeee"
    0101 grass
    0102 sea
    0201 grass "promised land"
    0202 sea

To improve legibility, the SVG output gives you the ability to define an "outer
glow" for your labels by printing them twice and using the B<glow> attributes
for the one in the back. In addition to that, you can use B<label> to control
the text attributes used for these labels. If you append a number to the label,
it will be used as the new font-size.

    text font-family="monospace" font-size="10pt"
    label font-family="sans-serif" font-size="12pt"
    glow fill="none" stroke="white" stroke-width="3pt"
    default attributes fill="none" stroke="black" stroke-width="1px"
    grass attributes fill="#90ee90"
    sea attributes fill="#afeeee"
    0101 grass
    0102 sea
    0201 grass "promised land"
    0202 sea "deep blue sea" 20

If you append transformation instructions after the font size, those will be
applied, too. In order to make this easier, the text element is transformed
first, and translated to the correct position in the middle of the hex.

    text font-family="monospace" font-size="10pt"
    label font-family="sans-serif" font-size="12pt"
    glow fill="none" stroke="white" stroke-width="3pt"
    default attributes fill="none" stroke="black" stroke-width="1px"
    grass attributes fill="#90ee90"
    sea attributes fill="#afeeee"
    0101 grass
    0102 sea
    0201 grass "promised land"
    0202 sea "deep blue sea" 20 translate(-75,-43.3) rotate(30)

In the example above, remember that a hex is 2×100px wide and 173 (100×√3) high.
The mid point between two hexes would therefore be a translation of
(-¾×100,-½×100×√3).

You can define SVG B<path> elements to use for your map. These can be
independent of a type (such as an icon for a settlement) or they can
be part of a type (such as a bit of grass).

Here, we add a bit of grass to the appropriate hex type:

    text font-family="monospace" font-size="10pt"
    label font-family="sans-serif" font-size="12pt"
    glow fill="none" stroke="white" stroke-width="3pt"
    default attributes fill="none" stroke="black" stroke-width="1px"
    grass attributes fill="#90ee90"
    grass path attributes stroke="#458b00" stroke-width="5px"
    grass path M -20,-20 l 10,40 M 0,-20 v 40 M 20,-20 l -10,40
    sea attributes fill="#afeeee"
    0101 grass
    0102 sea
    0201 grass "promised land"
    0202 sea "deep blue sea" 20

If you want to read up on the SVG Path syntax, check out the official
L<specification|https://www.w3.org/TR/SVG11/paths.html>. You can use a tool like
L<Linja Lili|https://campaignwiki.org/linja-lili> to work on it: paste “M
-20,-20 l 10,40 M 0,-20 v 40 M 20,-20 l -10,40” in the the Path field, use the
default transform of “scale(2) translate(50,50)” and import it. Make some
changes, export it, and copy the result from the Path field back into your map.
Linja Lili was written just for this! 😁

Here, we add a settlement. The village doesn't have type attributes (it never
says C<village attributes>) and therefore it's not a hex type.

    text font-family="monospace" font-size="10pt"
    label font-family="sans-serif" font-size="12pt"
    glow fill="none" stroke="white" stroke-width="3pt"
    default attributes fill="none" stroke="black" stroke-width="1px"
    grass attributes fill="#90ee90"
    grass path attributes stroke="#458b00" stroke-width="5px"
    grass path M -20,-20 l 10,40 M 0,-20 v 40 M 20,-20 l -10,40
    village path attributes fill="none" stroke="black" stroke-width="5px"
    village path M -40,-40 v 80 h 80 v -80 z
    sea attributes fill="#afeeee"
    0101 grass
    0102 sea
    0201 grass village "Beachton"
    0202 sea "deep blue sea" 20

As you can see, you can have multiple types per coordinate, but
obviously only one of them should have the "fill" property (or they
must all be somewhat transparent).

As we said above, the village is an independent shape. As such, it also gets the
glow we defined for text. In our example, the glow has a stroke-width of 3pt and
the village path has a stroke-width of 5px which is why we can't see it. If had
used a thinner stroke, we would have seen a white outer glow. Here's the same
example with a 1pt stroke-width for the village.

    text font-family="monospace" font-size="10pt"
    label font-family="sans-serif" font-size="12pt"
    glow fill="none" stroke="white" stroke-width="3pt"
    default attributes fill="none" stroke="black" stroke-width="1px"
    grass attributes fill="#90ee90"
    grass path attributes stroke="#458b00" stroke-width="5px"
    grass path M -20,-20 l 10,40 M 0,-20 v 40 M 20,-20 l -10,40
    village path attributes fill="none" stroke="black" stroke-width="1pt"
    village path M -40,-40 v 80 h 80 v -80 z
    sea attributes fill="#afeeee"
    0101 grass
    0102 sea
    0201 grass village "Beachton"
    0202 sea "deep blue sea" 20

You can also have lines connecting hexes. In order to better control the flow of
these lines, you can provide multiple hexes through which these lines must pass.
You can append a label to these, too. These lines can be used for borders,
rivers or roads, for example.

    text font-family="monospace" font-size="10pt"
    label font-family="sans-serif" font-size="12pt"
    glow fill="none" stroke="white" stroke-width="3pt"
    default attributes fill="none" stroke="black" stroke-width="1px"
    grass attributes fill="#90ee90"
    grass path attributes stroke="#458b00" stroke-width="5px"
    grass path M -20,-20 l 10,40 M 0,-20 v 40 M 20,-20 l -10,40
    village path attributes fill="none" stroke="black" stroke-width="5px"
    village path M -40,-40 v 80 h 80 v -80 z
    sea attributes fill="#afeeee"
    0101 grass
    0102 sea
    0201 grass village "Beachton"
    0202 sea "deep blue sea" 20
    border path attributes stroke="red" stroke-width="15" stroke-opacity="0.5" fill-opacity="0"
    0102-0101-0200 border "The Wall"
    road path attributes stroke="black" stroke-width="3" fill-opacity="0" stroke-dasharray="10 10"
    0302-0201-0001 road "The Road"


As you can see the lines can lead off the map. Lines can have two extra pieces
of information attached after the label. The first is either C<left> or C<right>
in case the default assignment doesn't work. In the example above, the defaults
worked just fine. In the example below we'll reverse the direction. The second
piece of information is a I<percentage> to indicate where along the line the text
should display.

    text font-family="monospace" font-size="10pt"
    label font-family="sans-serif" font-size="12pt"
    glow fill="none" stroke="white" stroke-width="3pt"
    default attributes fill="none" stroke="black" stroke-width="1px"
    grass attributes fill="#90ee90"
    grass path attributes stroke="#458b00" stroke-width="5px"
    grass path M -20,-20 l 10,40 M 0,-20 v 40 M 20,-20 l -10,40
    village path attributes fill="none" stroke="black" stroke-width="5px"
    village path M -40,-40 v 80 h 80 v -80 z
    sea attributes fill="#afeeee"
    0101 grass
    0102 sea
    0201 grass village "Beachton"
    0202 sea "deep blue sea" 20
    border path attributes stroke="red" stroke-width="15" stroke-opacity="0.5" fill-opacity="0"
    0102-0101-0200 border "The Wall" right 10%
    road path attributes stroke="black" stroke-width="3" fill-opacity="0" stroke-dasharray="10 10"
    0302-0201-0001 road "The Road" left 50%

=head2 Colours and Transparency

Let me return for a moment to the issue of colours. We've used 24 bit colours in
the examples above, that is: red-green-blue (RGB) definitions of colours where
very colour gets a number between 0 and 255, but written as a hex using the
digites 0-9 and A-F: no red, no green, no blue is #000000; all red, all green,
all blue is #FFFFFF; just red is #FF0000.

    text font-family="monospace" font-size="20px"
    label font-family="monospace" font-size="20px"
    glow fill="none" stroke="white" stroke-width="4px"
    default attributes fill="none" stroke="black" stroke-width="1px"
    sea attributes fill="#000000"
    land attributes fill="#ffffff"
    fire attributes fill="#ff0000"
    0101 sea
    0102 sea
    0103 sea
    0201 sea
    0202 sea "black sea"
    0203 sea
    0301 land
    0302 land "lands of Dis"
    0303 sea
    0401 fire "gate of fire"
    0402 land
    0403 sea

But of course, we can write colours in all the ways L<allowed on the
web|https://en.wikipedia.org/wiki/Web_colors>: using just three digits (#F00 for
red), using the predefined SVG colour names (just "red"), RGB values
("rgb(255,0,0)" for red), RGB percentages ("rgb(100%,0%,0%)" for red).

What we haven't mentioned, however, is the alpha channel: you can always add a
fourth number that specifies how transparent the colour is. It's tricky, though:
if the colour is black (#000000) then it doesn't matter how transparent it is: a
value of zero doesn't change. But it's different when the colour is white!
Therefore, we can define an attribute that is simply a semi-transparent white
and use it to lighten things up. You can even use it multiple times!

    text font-family="monospace" font-size="20px"
    label font-family="monospace" font-size="20px"
    glow fill="none" stroke="white" stroke-width="4px"
    default attributes fill="none" stroke="black" stroke-width="1px"
    sea attributes fill="#000000"
    land attributes fill="#ffffff"
    fire attributes fill="#ff0000"
    lighter attributes fill="rgb(100%,100%,100%,40%)"
    0101 sea
    0102 sea
    0103 sea
    0201 sea lighter
    0202 sea lighter "black sea"
    0203 sea lighter
    0301 land
    0302 land "lands of Dis"
    0303 sea lighter lighter
    0401 fire "gate of fire"
    0402 land
    0403 sea lighter lighter lighter

Thanks to Eric Scheid for showing me this trick.

=head2 Include a Library

Since these definitions get unwieldy, require a lot of work (the path elements),
and to encourage reuse, you can use the B<include> statement with an URL or a
filename. If a filename, the file must be in the directory named by the
F<contrib> configuration key, which defaults to the applications F<share>
directory.

    include default.txt
    0102 sand
    0103 sand
    0201 sand
    0202 jungle "oasis"
    0203 sand
    0302 sand
    0303 sand

=head3 The default library

Source of the map:
L<http://themetalearth.blogspot.ch/2011/03/opd-entry.html>

Example data:
L<https://campaignwiki.org/contrib/forgotten-depths.txt>

Library:
L<https://campaignwiki.org/contrib/default.txt>

Result:
L<https://campaignwiki.org/text-mapper?map=include+forgotten-depths.txt>

=head3 Gnomeyland library

Example data:
L<https://campaignwiki.org/contrib/gnomeyland-example.txt>

Library:
L<https://campaignwiki.org/contrib/gnomeyland.txt>

Result:
L<https://campaignwiki.org/text-mapper?map=include+gnomeyland-example.txt>

=head3 Traveller library

Example:
L<https://campaignwiki.org/contrib/traveller-example.txt>

Library:
L<https://campaignwiki.org/contrib/traveller.txt>

Result:
L<https://campaignwiki.org/text-mapper?map=include+traveller-example.txt>

=head3 Dungeons library

Example:
L<https://campaignwiki.org/contrib/gridmapper-example.txt>

Library:
L<https://campaignwiki.org/contrib/gridmapper.txt>

Result:
L<https://campaignwiki.org/text-mapper?type=square&map=include+gridmapper-example.txt>

=head2 Large Areas

If you want to surround a piece of land with a round shore line, a
forest with a large green shadow, you can achieve this using a line
that connects to itself. These "closed" lines can have C<fill> in
their path attributes. In the following example, the oasis is
surrounded by a larger green area.

    include default.txt
    0102 sand
    0103 sand
    0201 sand
    0203 sand
    0302 sand
    0303 sand
    0102-0201-0302-0303-0203-0103-0102 green
    green path attributes fill="#9acd32"
    0202 jungle "oasis"

Confusingly, the "jungle path attributes" are used to draw the palm
tree, so we cannot use it do define the area around the oasis. We need
to define the green path attributes in order to do that.

I<Order is important>: First we draw the sand, then the green area,
then we drop a jungle on top of the green area.

=head2 SVG

You can define shapes using arbitrary SVG. Your SVG will end up in the
B<defs> section of the SVG output. You can then refer to the B<id>
attribute in your map definition. For the moment, all your SVG needs to
fit on a single line.

    <circle id="thorp" fill="#ffd700" stroke="black" stroke-width="7" cx="0" cy="0" r="15"/>
    0101 thorp

Shapes can include each other:

    <circle id="settlement" fill="#ffd700" stroke="black" stroke-width="7" cx="0" cy="0" r="15"/>
    <path id="house" stroke="black" stroke-width="7" d="M-15,0 v-50 m-15,0 h60 m-15,0 v50 M0,0 v-37"/>
    <use id="thorp" xlink:href="#settlement" transform="scale(0.6)"/>
    <g id="village" transform="scale(0.6), translate(0,40)"><use xlink:href="#house"/><use xlink:href="#settlement"/></g>
    0101 thorp
    0102 village

When creating new shapes, remember the dimensions of the hex. Your shapes must
be centered around (0,0). The width of the hex is 200px, the height of the hex
is 100 √3 = 173.2px. A good starting point would be to keep it within (-50,-50)
and (50,50).

=head2 Other

You can add even more arbitrary SVG using the B<other> keyword. This
keyword can be used multiple times.

    grass attributes fill="#90ee90"
    0101 grass
    0201 grass
    0302 grass
    other <circle cx="150" cy="90" r="30" fill="yellow" stroke="black" stroke-width="10"/>

The B<other> keyword causes the item to be added to the end of the document. It
can be used for all sorts of one-time symbols, frames, regions, and so on.
Sadly, it must all come on one line!

=head2 URL

You can make labels link to web pages using the B<url> keyword.

    grass attributes fill="#90ee90"
    0101 grass "Home"
    url https://campaignwiki.org/wiki/NameOfYourWiki/

This will make the label X link to
C<https://campaignwiki.org/wiki/NameOfYourWiki/X>. You can also use
C<%s> in the URL and then this placeholder will be replaced with the
(URL encoded) label.

=head2 License

This program is copyright (C) 2007-2019 Alex Schroeder <alex@gnu.org>.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
details.

You should have received a copy of the GNU Affero General Public License along
with this program. If not, see <http://www.gnu.org/licenses/>.

The maps produced by the program are obviously copyrighted by I<you>,
the author. If you're using SVG icons, these I<may> have a separate
license. Thus, if you produce a map using the I<Gnomeyland> icons by
Gregory B. MacKenzie, the map is automatically licensed under the
Creative Commons Attribution-ShareAlike 3.0 Unported License. To view
a copy of this license, visit
L<http://creativecommons.org/licenses/by-sa/3.0/>.

You can add arbitrary SVG using the B<license> keyword (without a
tile). This is what the Gnomeyland library does, for example.

    grass attributes fill="#90ee90"
    0101 grass
    license <text>Public Domain</text>

There can only be I<one> license keyword. If you use multiple
libraries or want to add your own name, you will have to write your
own.

There's a 50 pixel margin around the map, here's how you might
conceivably use it for your own map that uses the I<Gnomeyland> icons
by Gregory B. MacKenzie:

    grass attributes fill="#90ee90"
    0101 grass
    0201 grass
    0301 grass
    0401 grass
    0501 grass
    license <text x="50" y="-33" font-size="15pt" fill="#999999">Copyright Alex Schroeder 2013. <a style="fill:#8888ff" xlink:href="http://www.busygamemaster.com/art02.html">Gnomeyland Map Icons</a> Copyright Gregory B. MacKenzie 2012.</text><text x="50" y="-15" font-size="15pt" fill="#999999">This work is licensed under the <a style="fill:#8888ff" xlink:href="http://creativecommons.org/licenses/by-sa/3.0/">Creative Commons Attribution-ShareAlike 3.0 Unported License</a>.</text>

Unfortunately, it all has to go on a single line.

The viewport for the map is determined by the hexes of the map. You need to take
this into account when putting a license onto the map. Thus, if your map does
not include the hex 0101, you can't use coordinates for the license text around
the origin at (0,0) – you'll have to move it around.

=head3 Smale

The default algorithm was developed by Erin D. Smale. See L<Hex-based Campaign
Design (Part 1)|http://www.welshpiper.com/hex-based-campaign-design-part-1/> and
L<Hex-based Campaign Design (Part
2)|http://www.welshpiper.com/hex-based-campaign-design-part-2/> for more
information.

The output uses the I<Gnomeyland> icons by Gregory B. MacKenzie. These are
licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
To view a copy of this license, visit
L<http://creativecommons.org/licenses/by-sa/3.0/>. If you use these maps in your
works, you must take this into account.

See L<Game::TextMapper::Smale> for more information.

=head3 Alpine

The Alpine algorithm was developed by Alex Schroeder. See L<Alpine map generator
1|https://alexschroeder.ch/wiki/2016-08-06_Alpine_Map_Generator> and L<Alpine
map generator 2|https://alexschroeder.ch/wiki/2016-08-16_Alpine_Map_Generator>
for more information.

The output also uses the I<Gnomeyland> icons by Gregory B. MacKenzie. These are
licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
To view a copy of this license, visit
L<http://creativecommons.org/licenses/by-sa/3.0/>. If you use these maps in your
works, you must take this into account.

See L<Game::TextMapper::Schroeder::Alpine> for more information.

=head3 Apocalypse

The Alpine algorithm was developed by Alex Schroeder. See L<Hex describing the
post-apocalypse|https://alexschroeder.ch/wiki/2020-10-02_Hex_describing_the_post-apocalypse>
for more information.

The output uses the default library. This library is dedicated to the public.
domain.

See L<Game::TextMapper::Schroeder::Alpine> for more information.

=head3 Gridmapper

The Gridmapper algorithm was developed by Alex Schroeder and is based on
geomorph sketches by Robin Green. See L<The Nine Forms of the Five Room
Dungeon|https://gnomestew.com/the-nine-forms-of-the-five-room-dungeon/> by
Matthew J. Neagley for more information.

The output uses the Dungeons library. This library is dedicated to the public
domain.

See L<Game::TextMapper::Gridmapper> for more information.

=head3 Islands

The Island algorithm was developed by Alex Schroeder. See
L<https://alexschroeder.ch/wiki/2020-04-25_Island_generator_using_J> and
L<https://alexschroeder.ch/wiki/2020-05-01_Island_map_generator_and_Text_Mapper>
for more information.

The output also uses the I<Gnomeyland> icons by Gregory B. MacKenzie. These are
licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
To view a copy of this license, visit
L<http://creativecommons.org/licenses/by-sa/3.0/>. If you use these maps in your
works, you must take this into account.

See L<Game::TextMapper::Schroeder::Islands> for more information.

=head3 Traveller

The Traveller link generates a random landscape based on Classic Traveller with
additions by Vicky Radcliffe and Alex Schroeder.

See L<Game::TextMapper::Traveller> for more information.

=head2 Border Adjustments

The border adjustments can be a little unintuitive. Let's assume the default map
and think through some of the operations.

    0101 mountain "mountain"
    0102 swamp "swamp"
    0103 hill "hill"
    0104 forest "forest"
    0201 empty pyramid "pyramid"
    0202 tundra "tundra"
    0203 coast "coast"
    0204 empty house "house"
    0301 woodland "woodland"
    0302 wetland "wetland"
    0303 plain "plain"
    0304 sea "sea"
    0401 hill tower "tower"
    0402 sand house "house"
    0403 jungle "jungle"
    0501 mountain cave "cave"
    0502 sand "sand"
    0205-0103-0202-0303-0402 road
    0101-0203 river
    0401-0303-0403 border
    include https://campaignwiki.org/contrib/default.txt
    license <text>Public Domain</text>

Basically, we're adding and removing rows and columns using the left, top,
bottom, right parameters. Thus, “left +2” means adding two columns at the left.
The mountains at 0101 thus turn into mountains at 0301.

    0301 mountain "mountain"
    0302 swamp "swamp"
    0303 hill "hill"
    0304 forest "forest"
    0401 empty pyramid "pyramid"
    0402 tundra "tundra"
    0403 coast "coast"
    0404 empty house "house"
    0501 woodland "woodland"
    0502 wetland "wetland"
    0503 plain "plain"
    0504 sea "sea"
    0601 hill tower "tower"
    0602 sand house "house"
    0603 jungle "jungle"
    0701 mountain cave "cave"
    0702 sand "sand"
    0405-0303-0402-0503-0602 road
    0301-0403 river
    0601-0503-0603 border
    include https://campaignwiki.org/contrib/default.txt
    license <text>Public Domain</text>

Conversely, “left -2” means removing the two columns at the left. The mountains
at 0101 and the pyramid at 0201 would therefore disappear and the woodland at
0301 would turn into the woodland at 0101.

    0101 woodland "woodland"
    0102 wetland "wetland"
    0103 plain "plain"
    0104 sea "sea"
    0201 hill tower "tower"
    0202 sand house "house"
    0203 jungle "jungle"
    0301 mountain cave "cave"
    0302 sand "sand"
    0005--0103-0002-0103-0202 road
    0201-0103-0203 border
    include https://campaignwiki.org/contrib/default.txt
    license <text>Public Domain</text>

The tricky part is when “add empty” is not checked and you first add two columns
on the left, and then remove two columns on the left. If you do this, you’re not
undoing the addition of the two columns because the code just considers the
actual columns and thus removes the columns with the mountain which moved from
0101 to 0301 and the pyramid which moved from 0201 to 0401, leaving the woodland
in 0301.

    0301 woodland "woodland"
    0302 wetland "wetland"
    0303 plain "plain"
    0304 sea "sea"
    0401 hill tower "tower"
    0402 sand house "house"
    0403 jungle "jungle"
    0501 mountain cave "cave"
    0502 sand "sand"
    0205-0103-0202-0303-0402 road
    0401-0303-0403 border
    include https://campaignwiki.org/contrib/default.txt
    license <text>Public Domain</text>

This problem disappears if you check “add empty” as you add the two columns
at the left because now all the gaps are filled, starting at 0101. You’re
getting two empty columns on the left:

    0101 empty
    0102 empty
    0103 empty
    0104 empty
    0201 empty
    0202 empty
    0203 empty
    0204 empty
    0301 mountain "mountain"
    0302 swamp "swamp"
    0303 hill "hill"
    0304 forest "forest"
    0401 empty pyramid "pyramid"
    0402 tundra "tundra"
    0403 coast "coast"
    0404 empty house "house"
    0501 woodland "woodland"
    0502 wetland "wetland"
    0503 plain "plain"
    0504 sea "sea"
    0601 hill tower "tower"
    0602 sand house "house"
    0603 jungle "jungle"
    0604 empty
    0701 mountain cave "cave"
    0702 sand "sand"
    0703 empty
    0704 empty
    0301-0403 river
    0405-0303-0402-0503-0602 road
    0601-0503-0603 border
    include https://campaignwiki.org/contrib/default.txt
    license <text>Public Domain</text>

When you remove two columns in the second step, you’re removing the two empty
columns you just added. But “add empty” fills all the gaps, so in the example
map, it also adds all the missing hexes in columns 04 and 05, so you can only
use this option if you want those empty hexes added…

    0101 mountain "mountain"
    0102 swamp "swamp"
    0103 hill "hill"
    0104 forest "forest"
    0201 empty pyramid "pyramid"
    0202 tundra "tundra"
    0203 coast "coast"
    0204 empty house "house"
    0301 woodland "woodland"
    0302 wetland "wetland"
    0303 plain "plain"
    0304 sea "sea"
    0401 hill tower "tower"
    0402 sand house "house"
    0403 jungle "jungle"
    0404 empty
    0501 mountain cave "cave"
    0502 sand "sand"
    0503 empty
    0504 empty
    0101-0203 river
    0205-0103-0202-0303-0402 road
    0401-0303-0403 border
    include https://campaignwiki.org/contrib/default.txt
    license <text>Public Domain</text>

=head2 Configuration

The application will read a config file called F<text-mapper.conf> in the
current directory, if it exists. As the default log level is 'warn', one use of
the config file is to change the log level using the C<loglevel> key.

The libraries are loaded from the F<contrib> URL or directory. You can change
the default using the C<contrib> key. This is necessary when you want to develop
locally, for example. If you don't set it to the local F<share> directory, the
library will access the files installed with the entire distribution.

    {
      loglevel => 'debug',
      contrib => 'share',
    };

=head2 Command Line

You can call the script from the command line. The B<render> command reads a map
description from STDIN and prints it to STDOUT.

    text-mapper render < contrib/forgotten-depths.txt > forgotten-depths.svg

See L<Game::TextMapper::Command::render> for more.

The B<random> command prints a random map description to STDOUT.

    text-mapper random > map.txt

See L<Game::TextMapper::Command::random> for more.

Thus, you can pipe the random map in order to render it:

    text-mapper random | text-mapper render > map.svg

=cut


@@ help.html.ep
% layout 'default';
% title 'Text Mapper: Help';
<%== $html %>


@@ edit.html.ep
% layout 'default';
% title 'Text Mapper';
<h1>Text Mapper</h1>
<p>Submit your text description of the map.</p>
%= form_for render => (method => 'POST') => begin
%= text_area map => (cols => 60, rows => 15) => begin
<%= $map =%>
% end

<p>
%= radio_button type => 'hex', id => 'hex', checked => undef
%= label_for hex => 'Hex'
%= radio_button type => 'square', id => 'square'
%= label_for square => 'Square'
<p>
%= submit_button "Generate Map"

<p>
Add (or remove if negative) rows or columns:
%= label_for top => 'top'
%= number_field top => 0, class => 'small', id => 'top'
%= label_for left => 'left'
%= number_field left => 0, class => 'small', id => 'left'
%= label_for right => 'right'
%= number_field right => 0, class => 'small', id => 'right'
%= label_for bottom => 'bottom'
%= number_field bottom => 0, class => 'small', id => 'bottom'
%= label_for empty => 'add empty'
%= check_box empty => 1, id => 'empty'
<p>
%= submit_button "Modify Map Data", 'formaction' => $c->url_for('borders')
%= end
<p>
See the <%= link_to url_for('help')->fragment('Border_Adjustments') => begin %>documentation<% end %>
for an explanation of what these parameters do.

<hr>
<p>
<%= link_to smale => begin %>Random<% end %>
generates map data based on Erin D. Smale's <em>Hex-Based Campaign Design</em>
(<a href="http://www.welshpiper.com/hex-based-campaign-design-part-1/">Part 1</a>,
<a href="http://www.welshpiper.com/hex-based-campaign-design-part-2/">Part 2</a>).
You can also generate a random map
<%= link_to url_for('smale')->query(bw => 1) => begin %>with no background colors<% end %>.
Click the submit button to generate the map itself. Or just keep reloading
<%= link_to smalerandom => begin %>this link<% end %>.
You'll find the map description in a comment within the SVG file.
</p>
%= form_for smale => begin
<table>
<tr><td>Width:</td><td>
%= number_field width => 20, min => 5, max => 99
</td></tr><tr><td>Height:</td><td>
%= number_field height => 10, min => 5, max => 99
</td></tr></table>
<p>
%= submit_button "Generate Map Data"
% end

<hr>
<p>
<%= link_to alpine => begin %>Alpine<% end %> generates map data based on Alex
Schroeder's algorithm that's trying to recreate a medieval Swiss landscape, with
no info to back it up, whatsoever. See it
<%= link_to url_for('alpinedocument')->query(height => 5) => begin %>documented<% end %>.
Click the submit button to generate the map itself. Or just keep reloading
<%= link_to alpinerandom => begin %>this link<% end %>.
You'll find the map description in a comment within the SVG file.
</p>
%= form_for alpine => begin
<table>
<tr><td>Width:</td><td>
%= number_field width => 20, min => 5, max => 99
</td><td>Bottom:</td><td>
%= number_field bottom => 0, min => 0, max => 10
</td><td>Peaks:</td><td>
%= number_field peaks => 5, min => 0, max => 100
</td><td>Bumps:</td><td>
%= number_field bumps => 2, min => 0, max => 100
</td></tr><tr><td>Height:</td><td>
%= number_field height => 10, min => 5, max => 99
</td><td>Steepness:</td><td>
%= number_field steepness => 3, min => 1, max => 6
</td><td>Peak:</td><td>
%= number_field peak => 10, min => 7, max => 10
</td><td>Bump:</td><td>
%= number_field bump => 2, min => 1, max => 2
</td></tr><tr><td>Arid:</td><td>
%= number_field arid => 2, min => 0, max => 2
</td><td><td>
</td><td></td><td>
</td></tr></table>
<p>
See the <%= link_to alpineparameters => begin %>documentation<% end %> for an
explanation of what these parameters do.
<p>
%= radio_button type => 'hex', id => 'hex', checked => undef
%= label_for hex => 'Hex'
%= radio_button type => 'square', id => 'square'
%= label_for square => 'Square'
<p>
%= submit_button "Generate Map Data"
</p>
% end

<hr>
<p>
<%= link_to url_for('gridmapper')->query(type => 'square') => begin %>Gridmapper<% end %>
generates dungeon map data based on geomorph sketches by Robin Green. Or
just keep reloading one of these links:
<%= link_to url_for('gridmapperrandom')->query(rooms => 5) => begin %>5 rooms<% end %>,
<%= link_to url_for('gridmapperrandom')->query(rooms => 10) => begin %>10 rooms<% end %>,
<%= link_to url_for('gridmapperrandom')->query(rooms => 20) => begin %>20 rooms<% end %>.
Each map contains an “Edit in Gridmapper” link which will open the same map in the <a
href="https://campaignwiki.org/gridmapper.svg">Gridmapper web app</a> itself.
%= form_for gridmapper => begin
<p>
<label>
%= check_box pillars => 0
No rooms with pillars
</label>
<label>
%= check_box caves => 1
Just caves
</label>
%= hidden_field type => 'square'
<table>
<tr><td>Rooms:</td><td>
%= number_field rooms => 5, min => 1
</td></tr></table>
<p>
%= submit_button "Generate Map Data"
% end

<hr>

<p><%= link_to url_for('apocalypse') => begin %>Apocalypse<% end %> generates a post-apocalyptic map.
<%= link_to url_for('apocalypserandom') => begin %>Reload<% end %> for lots of post-apocalyptic maps.
You'll find the map description in a comment within the SVG file.
%= form_for apocalypse => begin
<p>
<table>
<tr><td>Width:</td><td>
%= number_field cols => 20, min => 1
</td><td>Height:</td><td>
%= number_field rows => 10, min => 1
</td></tr>
<tr><td>Region Size:</td><td>
%= number_field region_size => 5, min => 1
</td><td>Settlement Chance:</td><td>
%= number_field settlement_chance => 0.1, min => 0, max => 1, step => 0.1
</td></tr></table>
<p>
%= submit_button "Generate Map Data"
% end

<hr>

<p><%= link_to url_for('traveller') => begin %>Traveller<% end %> generates a star map.
<%= link_to url_for('travellerrandom') => begin %>Reload<% end %> for lots of random star maps.
You'll find the map description in a comment within the SVG file.
%= form_for traveller => begin
<p>
<table>
<tr><td>Width:</td><td>
%= number_field cols => 8, min => 1
</td></tr>
<tr><td>Height:</td><td>
%= number_field rows => 10, min => 1
</td></tr></table>
<p>
%= submit_button "Generate Map Data"
% end

<hr>

<p>Ideas and work in progress…

<p><%= link_to url_for('island') => begin %>Island<% end %> generates a hotspot-inspired island chain.
Reload <%= link_to url_for('islandrandom') => begin %>Hex Island<% end %>
or <%= link_to url_for('islandrandom')->query(type => 'square') => begin %>Square Island<% end %>
for lots of random islands.
You'll find the map description in a comment within the SVG file.

<p><%= link_to url_for('archipelago') => begin %>Archipelago<% end %> is an experimenting with alternative hex heights.
Reload <%= link_to url_for('archipelagorandom') => begin %>Hex Archipelago<% end %>
or <%= link_to url_for('archipelagorandom')->query(type => 'square') => begin %>Square Archipelago<% end %>
for lots of random archipelagos.
You'll find the map description in a comment within the SVG file.

@@ render.svg.ep


@@ alpine_parameters.html.ep
% layout 'default';
% title 'Alpine Parameters';
<h1>Alpine Parameters</h1>

<p>
This page explains what the parameters for the <em>Alpine</em> map generation
will do.
</p>
<p>
The parameters <strong>width</strong> and <strong>height</strong> determine how
big the map is.
</p>
<p>
Example:
<%= link_to url_for('alpinerandom')->query(height => 10, width => 15) => begin %>15×10 map<% end %>.
</p>
<p>
The number of peaks we start with is controlled by the <strong>peaks</strong>
parameter (default is 2½% of the hexes). Note that you need at least one peak in
order to get any land at all.
</p>
<p>
Examples:
<%= link_to url_for('alpinerandom')->query(height => 10, width => 15, peaks => 1) => begin %>lonely mountain<% end %>,
<%= link_to url_for('alpinerandom')->query(height => 10, width => 15, peaks => 2) => begin %>twin peaks<% end %>,
<%= link_to url_for('alpinerandom')->query(height => 10, width => 15, peaks => 15) => begin %>here be glaciers<% end %>
</p>
<p>
The number of bumps we start with is controlled by the <strong>bumps</strong>
parameter (default is 1% of the hexes). These are secondary hills and hollows.
</p>
<p>
Examples:
<%= link_to url_for('alpinerandom')->query(height => 10, width => 15, peaks => 1, bumps => 0) => begin %>lonely mountain, no bumps<% end %>,
<%= link_to url_for('alpinerandom')->query(height => 10, width => 15, peaks => 1, bumps => 4) => begin %>lonely mountain and four bumps<% end %>
</p>
<p>
When creating elevations, we surround each hex with a number of other hexes at
one altitude level lower. The number of these surrounding lower levels is
controlled by the <strong>steepness</strong> parameter (default 3). Lower means
steeper. Floating points are allowed. Please note that the maximum numbers of
neighbors considered is the 6 immediate neighbors and the 12 neighbors one step
away.
</p>
<p>
Examples:
<%= link_to url_for('alpinerandom')->query(height => 10, width => 15, steepness => 0) => begin %>ice needles map<% end %>,
<%= link_to url_for('alpinerandom')->query(height => 10, width => 15, steepness => 2) => begin %>steep mountains map<% end %>,
<%= link_to url_for('alpinerandom')->query(height => 10, width => 15, steepness => 4) => begin %>big mountains map<% end %>
</p>
<p>
The sea level is set to altitude 0. That's how you sometimes get a water hex at
the edge of the map. You can simulate global warming and set it to something
higher using the <strong>bottom</strong> parameter.
</p>
<p>
Example:
<%= link_to url_for('alpinerandom')->query(height => 10, width => 15, steepness => 2, bottom => 5) => begin %>steep mountains and higher water level map<% end %>
</p>
<p>
You can also control how high the highest peaks will be using the
<strong>peak</strong> parameter (default 10). Note that nothing special happens
to a hex with an altitude above 10. It's still mountain peaks. Thus, setting the
parameter to something higher than 10 just makes sure that there will be a lot
of mountain peaks.
</p>
<p>
Examples:
<%= link_to url_for('alpinerandom')->query(height => 10, width => 15, peak => 11) => begin %>big mountains<% end %>,
<%= link_to url_for('alpinerandom')->query(height => 10, width => 15, steepness => 3, bottom => 3, peak => 8) => begin %>old country<% end %>
</p>
<p>
You can also control how high the extra bumps will be using the
<strong>bump</strong> parameter (default 2).
</p>
<p>
Examples:
<%= link_to url_for('alpinerandom')->query(height => 10, width => 15, peaks => 1, bump => 1) => begin %>small bumps<% end %>,
<%= link_to url_for('alpinerandom')->query(height => 10, width => 15, peaks => 1, bump => 2) => begin %>bigger bumps<% end %>
</p>
<p>
You can also control forest growth (as opposed to grassland) by using the
<strong>arid</strong> parameter (default 2). That's how many hexes surrounding a
river hex will grow forests. Smaller means more arid and thus more grass.
Fractions are allowed. Thus, 0.5 means half the river hexes will have forests
grow to their neighbouring hexes.
</p>
<p>
Examples:
<%= link_to url_for('alpinerandom')->query(height => 10, width => 15, peaks => 2, stepness => 2, arid => 2) => begin %>fewer, steeper mountains<% end %>,
<%= link_to url_for('alpinerandom')->query(height => 10, width => 15, peaks => 2, stepness => 2, arid => 1) => begin %>less forest<% end %>,
<%= link_to url_for('alpinerandom')->query(height => 10, width => 15, peaks => 2, stepness => 2, arid => 0) => begin %>very arid<% end %>
</p>


@@ alpine_document.html.ep
% layout 'default';
% title 'Alpine Documentation';
<h1>Alpine Map: How does it get created?</h1>

<p>How do we get to the following map?
<%= link_to url_for('alpinedocument')->query(width => $width, height => $height, steepness => $steepness, peaks => $peaks, peak => $peak, bumps => $bumps, bump => $bump, bottom => $bottom, arid => $arid) => begin %>Reload<% end %>
to get a different one. If you like this particular map, bookmark
<%= link_to url_for('alpinerandom')->query(seed => $seed, width => $width, height => $height, steepness => $steepness, peaks => $peaks, peak => $peak, bumps => $bumps, bump => $bump, bottom => $bottom, arid => $arid) => begin %>this link<% end %>,
and edit it using
<%= link_to url_for('alpine')->query(seed => $seed, width => $width, height => $height, steepness => $steepness, peaks => $peaks, peak => $peak, bumps => $bumps, bump => $bump, bottom => $bottom, arid => $arid) => begin %>this link<% end %>,
</p>

%== $maps->[$#$maps]

<p>First, we pick <%= $peaks %> peaks and set their altitude to <%= $peak %>.
Then we loop down to 1 and for every hex we added in the previous run, we add
<%= $steepness %> neighbors at a lower altitude, if possible. We actually vary
steepness, so the steepness given is just an average. We'll also consider
neighbors one step away. If our random growth missed any hexes, we just copy the
height of a neighbor. If we can't find a suitable neighbor within a few tries,
just make a hole in the ground (altitude 0).</p>

<p>The number of peaks can be changed using the <em>peaks</em> parameter. Please
note that 0 <em>peaks</em> will result in no land mass.</p>

<p>The initial altitude of those peaks can be changed using the <em>peak</em>
parameter. Please note that a <em>peak</em> smaller than 7 will result in no
sources for rivers.</p>

<p>The number of adjacent hexes at a lower altitude can be changed using the
<em>steepness</em> parameter. Floating points are allowed. Please note that the
maximum numbers of neighbors considered is the 6 immediate neighbors and the 12
neighbors one step away.</p>

%== shift(@$maps)

<p>Next, we pick <%= $bumps %> bumps and shift their altitude by -<%= $bump %>,
and <%= $bumps %> bumps and shift their altitude by +<%= $bump %>. If the shift
is bigger than 1, then we shift the neighbours by one less.</p>

%== shift(@$maps)

<p>Mountains are the hexes at high altitudes: white mountains (altitude 10),
white mountain (altitude 9), light-grey mountain (altitude 8).</p>

%== shift(@$maps)

<p>Oceans are whatever lies at the bottom (<%= $bottom %>) and is surrounded by
regions at the same altitude.</p>

%== shift(@$maps)

<p>We determine the flow of water by having water flow to one of the lowest
neighbors if possible. Water doesn't flow upward, and if there is already water
coming our way, then it won't flow back. It has reached a dead end.</p>

%== shift(@$maps)

<p>Any of the dead ends we found in the previous step are marked as lakes.</p>

%== shift(@$maps)

<p>We still need to figure out how to drain lakes. In order to do that, we start
"flooding" lakes, looking for a way to the edge of the map. If we're lucky, our
search will soon hit upon a sequence of arrows that leads to ever lower
altitudes and to the edge of the map. An outlet! We start with all the hexes
that don't have an arrow. For each one of those, we look at its neighbors. These
are our initial candidates. We keep expanding our list of candidates as we add
at neighbors of neighbors. At every step we prefer the lowest of these
candidates. Once we have reached the edge of the map, we backtrack and change
any arrows pointing the wrong way.</p>

%== shift(@$maps)

<p>We add bogs (altitude 7) if the water flows into a hex at the same altitude.
It is insufficiently drained. We use grey swamps to indicate this.</p>

%== shift(@$maps)

<p>We determined the predominant wind direction (see purple arrow in 01.01) and
mark areas in the wind shadow of mountains as having no river sources,
presumably because of reduced rainfall. Specifically, a hex with altitude 7 or 8
next to a hex where the wind is coming from that is at the same altitude or
higher is marked as "dry". The only effect is that there can be no river sources
in these hexes (as these are all at altitudes 7 and 8)</p>

%== shift(@$maps)

<p>We add a river sources high up in the mountains (altitudes 7 and 8), merging
them as appropriate. These rivers flow as indicated by the arrows. If the river
source is not a mountain (altitude 8) or a bog (altitude 7), then we place a
forested hill at the source (thus, they're all at altitude 7).</p>

%== shift(@$maps)

<p>Remember how the arrows were changed at some points such that rivers don't
always flow downwards. We're going to assume that in these situations, the
rivers have cut canyons into the higher lying ground and we'll add a little
shadow.</p>

%== shift(@$maps)

<p>Any hex <em>with a river</em> that flows towards a neighbor at the same
altitude is insufficiently drained. These are marked as swamps. The background
color of the swamp depends on the altitude: grey if altitude 6 and higher,
otherwise dark-grey.</p>

%== shift(@$maps)

<p>Wherever there is water and no swamp, forests will form. The exact type again
depends on the altitude: light green fir-forest (altitude 7 and higher), green
fir-forest (altitude 6), green forest (altitude 4–5), dark-green forest
(altitude 3 and lower). Once a forest is placed, it expands up to <%= $arid %>
hexes away, even if those hexes have no water flowing through them. When
considering neighbouring hexes, they have to be at the same altitude or lower;
when considering hexes with an intermediary hex, the intermediary hex has to be
at the same altitude or lower, and the other he has to be at the same altitude
or lower as the intermediary hex.</p>

<p>You probably need fewer peaks on your map to verify this (a <%= link_to
url_with('alpinedocument')->query({peaks => 1}) => begin %>lonely mountain<% end
%> map, for example).</p>

%== shift(@$maps)

<p>Any remaining hexes have no water nearby and are considered to be little more
arid. At high altitudes, they get "light-grey grass"; at lower altitudes they
get "light-green bushes". For these lower altitude badlands, we add more variety
by simulating areas where conditions are bad. We pick a quarter of these hexes,
and deteriorate them, and their immediate neighbours. That is, we take little
"circles" of seven hexes each, and place them in these areas. Whenever they
overlap, conditions deteriorate even further: light-green bushes → light-green
grass → dust grass → dust hill → dust desert.</p>

<p>You probably need fewer peaks on your map to verify this (a <%= link_to
url_with('alpinedocument')->query({peaks => 1}) => begin %>lonely mountain<% end
%> map, for example).</p>

%== shift(@$maps)

<p>Cliffs form wherever the drop is more than just one level of altitude.</p>

%== shift(@$maps)

<p>Wherenver there is forest, settlements will be built. These reduce the
density of the forest. Of the settlements are big, trees disappear completely
and are replaced by soil. If the village or town is next to a water hex, it gets
a port and grows by one step. Note that currently it's impossibleto get a
city.</p>

<table>
<tr><th>Settlement</th><th>Conditions</th><th>Change to</th><th>Number</th>
    <th>Minimum Distance</th><th>Near water</th></tr>
<tr><td>thorp</td><td>fir-forest, or forest</td><td>firs, or trees</td><td class="numeric">10%</td>
    <td class="numeric">2</td><td>unchanged</td></tr>
<tr><td>village</td><td>forest &amp; river</td><td>trees</td><td class="numeric">5%</td>
    <td class="numeric">5</td><td>town &amp; port</td></tr>
<tr><td>town</td><td>forest or dark-forest &amp; river</td><td>soil</td><td class="numeric">2½%</td>
    <td class="numeric">10</td><td>large town &amp; port</td></tr>
<tr><td>large town</td><td>none</td><td>light soil</td><td class="numeric">0%</td>
    <td class="numeric">n/a</td><td>city &amp; port</td></tr>
<tr><td>city</td><td>none</td><td>light soil</td><td class="numeric">0%</td>
    <td class="numeric">n/a</td><td>unchanged</td></tr>
<tr><td>law</td><td>white mountain</td><td>unchanged</td><td class="numeric">2½%</td>
    <td class="numeric">10</td><td>unchanged</td></tr>
<tr><td>chaos</td><td>swamp</td><td>unchanged</td><td class="numeric">2½%</td>
    <td class="numeric">10</td><td>unchanged</td></tr>
</table>

%== shift(@$maps)

<p>Trails connect every settlement to any neighbor that is one or two hexes
away. If no such neighbor can be found, we try to find neighbors that are three
hexes away. If there are multiple options, we prefer the one at a lower
altitude.</p>

%== shift(@$maps)

<p>Finally, we take advantage of the fact that rivers continue into the ocean.
We identify river mouths where the altitude change is just 1 (i.e. no cliff) and
extend the land into the water using a blue-green swamp. These are coastal
marshes. We also check the next hex along the (invisible) river to check if this
an ocean hex. If it is, we change it to water.

%== shift(@$maps)

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
<head>
<title><%= title %></title>
%= stylesheet '/text-mapper.css'
%= stylesheet begin
body {
  padding: 1em;
  font-family: "Palatino Linotype", "Book Antiqua", Palatino, serif;
}
textarea {
  width: 100%;
}
td, th {
  padding-right: 0.5em;
}
.example {
  font-size: smaller;
}
.numeric {
  text-align: center;
}
.small {
  width: 3em;
}
% end
<meta name="viewport" content="width=device-width">
</head>
<body>
<%= content %>
<hr>
<p>
<a href="https://campaignwiki.org/text-mapper">Text Mapper</a>&#x2003;
<%= link_to 'Help' => 'help' %>&#x2003;
<a href="https://alexschroeder.ch/cgit/text-mapper/about/">Git</a>&#x2003;
<a href="https://alexschroeder.ch/wiki/Contact">Alex Schroeder</a>
</body>
</html>
