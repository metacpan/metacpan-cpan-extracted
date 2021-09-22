#!/usr/bin/env perl

# Copyright (C) 2015-2018 Alex Schroeder <alex@gnu.org>

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

=encoding utf8

=head1 NAME

Game::FaceGenerator - a web app to combina random images into faces

=head1 DESCRIPTION

Face Generator is a web application which uses random images to create faces.

On a technical level, Face Generator is a web app based on the Mojolicious
framework. This class in particular uses L<Mojolicious::Lite>.

See L<Mojolicious::Guides> for more information.

=cut

package Game::FaceGenerator;

our $VERSION = 1.00;

use Modern::Perl;
use Mojolicious::Lite;
use File::ShareDir 'dist_dir';
use Cwd;
use GD;

=head2 Configuration

As a Mojolicious application, it will read a config file called
F<face-generator.conf> in the same directory, if it exists. As the default log
level is 'debug', one use of the config file is to change the log level using
the C<loglevel> key, and if you're not running the server in a terminal, using
the C<logfile> key to set a file.

The random elements for faces are stored in the F<contrib> directory. You can
change this directory using the C<contrib> key. By default, the directory
included with the distribution is used. Thus, if you're a developer, you
probably want to use something like the following to use the files from the
source directory.

    {
      loglevel => 'debug',
      logfile => undef,
      contrib => 'share',
    };

=cut

plugin 'Config' => {
  default => {
    users => {},
    empty => {},
    loglevel => 'debug',
    logfile => undef,
    contrib => dist_dir('Game-FaceGenerator'),
  },
  file => getcwd() . '/face-generator.conf',
  empty => {
    tuiren => {
      gnome => 'dwarf.png' },
    alex => {
      dragon => 'dragon.png',
      elf => 'elf.png',
      dwarf => 'dwarf.png',
      gnome => 'dwarf.png',
      demon => 'demon.png', }},
  no_flip => { alex => ['dragon', 'demon'] },
};

# This log is to find bugs...
app->log->level(app->config('loglevel'));
app->log->path(app->config('logfile'));

plugin 'authentication', {
    autoload_user => 1,
    load_user => sub {
        my ($self, $username) = @_;
        return {
	  'username' => $username,
	} if app->config('users')->{$username};
        return undef;
    },
    validate_user => sub {
        my ($self, $username, $password) = @_;
	if (app->config('users')->{$username}
	    && $password eq app->config('users')->{$username}) {
	  return $username;
	}
        return undef;
    },
};

get '/' => sub {
  my $self = shift;
  $self->render(template => 'index',
		artists => all_artists());
} => 'main';

get '/view' => sub {
  my $self = shift;
  $self->redirect_to(view => {artist => 'alex', type => 'woman'});
};

get '/view/:artist/:type' => sub {
  my $self = shift;
  my $artist = $self->param('artist');
  my $type = $self->param('type');
  $self->render(template => 'view',
		type => $type,
		artists => all_artists(),
		components => [random_components($type, $artist)]);
} => 'view';

get '/gallery' => sub {
  my $self = shift;
  $self->redirect_to(gallery => {artist => 'alex', type => 'man'});
};

get '/gallery/:type' => sub {
  my $self = shift;
  my $type = $self->param('type');
  $self->redirect_to(gallery => {artist => 'alex', type => $type});
};

get '/gallery/:artist/:type' => sub {
  my $self = shift;
  my $artist = $self->param('artist');
  my $type = $self->param('type');
  my $num = $self->param('number') || 20;
  $self->render(template => 'gallery',
		artists => all_artists(),
		type => $type,
		components => [map {
		  [random_components($type, $artist, $self->param('debug'))];
			       } 1..$num]);
} => 'gallery';

get '/random' => sub {
  my $self = shift;
  $self->redirect_to(random => {artist => 'alex', type => 'woman'});
};

get '/random/:type' => sub {
  my $self = shift;
  my $type = $self->param('type');
  $self->redirect_to(random => {artist => 'alex', type => $type});
};

get '/random/:artist/:type' => sub {
  my $self = shift;
  my $artist = $self->param('artist');
  my $type = $self->param('type');
  $self->render(format => 'png',
		data => render_components(
		  $self, $artist,
		  random_components(
		    $type, $artist)));
} => 'random';

get '/redirect/:artist/:type' => sub {
  my $self = shift;
  my $artist = $self->param('artist');
  my $type = $self->param('type');
  srand($self->param('seed')) if $self->param('seed');
  $self->redirect_to(render => {
    artist => $artist,
    files  => join(',', random_components($type, $artist)), });
} => 'redirect';

get '/render/#files' => sub {
  my $self = shift;
  my $files = $self->param('files');
  $self->redirect_to(face => {
    artist => 'alex',
    files => $files}, );
};

get '/render/:artist/#files' => sub {
  my $self = shift;
  my $artist = $self->param('artist');
  my $files = $self->param('files');
  $self->render(format => 'png',
		data => render_components(
		  $self, $artist,
		  split(',', $files)));
} => 'render';

get '/debug' => sub {
  my $self = shift;
  $self->render(template => 'debug',
		artist => '',
		elements => [all_elements()],
		types => []);
} => 'debug';

get '/debug/:artist' => sub {
  my $self = shift;
  my $artist = $self->param('artist');
  $self->render(template => 'debug',
		artist => $artist,
		elements => [all_elements()],
		types => all_artists()->{$artist}->{types});
} => 'debug_artist';

get '/debug/:artist/#element' => sub {
  my $self = shift;
  my $artist = $self->param('artist');
  my $element = $self->param('element');
  my $empty = $self->param('empty');
  if (not $empty and app->config('empty')->{$artist}) {
    $empty = app->config('empty')->{$artist}->{$element};
  }
  my $days = $self->param('days');
  $self->render(template => 'debugelement',
		artist => $artist,
		element => $element,
		empty => $empty,
		components => [all_components($artist,
					      $element,
					      $empty,
					      $days)]);
} => 'debug_element';

get '/edit/:artist/#component' => sub {
  my $self = shift;
  my $component = $self->param('component');
  my $empty = $self->param('empty');
  $self->render(template => 'edit',
		empty => $empty,
		components => [$empty||'empty.png', 'edit.png', $component]);
} => 'edit';

get '/move/:artist/#component/:dir' => sub {
  my $self = shift;
  if (not $self->is_user_authenticated()) {
    return $self->redirect_to('login');
  }
  my $artist = $self->param('artist');
  my $component = $self->param('component');
  my $dir = $self->param('dir');
  my $step = $self->param('step') || 10;
  my $empty = $self->param('empty');
  move($artist, $component, $dir, $step);
  $self->render(template => 'edit',
		empty => $empty,
		components => [$empty||'empty.png', 'edit.png', $component]);
} => 'move';

any "/login" => sub {
  my $self = shift;
  my $username = $self->param('username');
  my $password = $self->param('password');
  if ($username) {
    $self->authenticate($username, $password);
    if ($self->is_user_authenticated()) {
      return $self->redirect_to('main');
    } else {
      $self->stash(login => 'wrong');
    }
  }
  $self->stash(home => app->config('home'));
} => 'login';

get "/logout" => sub {
  my $self = shift;
  $self->logout();
  $self->redirect_to('main');
} => 'logout';

sub member {
  my $element = shift;
  foreach (@_) {
    return 1 if $element eq $_;
  }
}

sub one {
  my $i = int(rand(scalar @_));
  return $_[$i];
}

my %artists;

sub all_artists {
  return \%artists if %artists;
  my $dir = app->config('contrib');
  opendir(my $dh, $dir) || die "Can't open $dir: $!";
  my @dirs = grep {
    !/\.png$/ # ignore images
	&& substr($_, 0, 1) ne '.' # ignore "." and ".." and other "hidden files"
	&& -d "$dir/$_"
	&& -f "$dir/$_/README.md"
  } readdir($dh);
  closedir $dh;
  for my $artist (@dirs) {
    # Determine name and url from the README file.
    $artists{$artist}{name} = $artist; # default
    open(my $fh, '<:utf8', "$dir/$artist/README.md") or next;
    local $/ = undef;
    my $text = <$fh>;
    if ($text =~ /\[([^]]*)\]\((https?:.*)\)/) {
      $artists{$artist} = {};
      $artists{$artist}{name} = $1;
      $artists{$artist}{url}  = $2;
    }
    if ($text =~ /\*([^* ][^*]*)\*/) {
      $artists{$artist}{title}  = $1;
    }
    close($fh);
    # Find available types from the filenames.
    my %types;
    opendir(my $dh, "$dir/$artist") || die "Can't open $dir/$artist: $!";
    while(readdir $dh) {
      $types{$1} = 1 if /_([a-z]+)/;
    }
    closedir $dh;
    delete $types{all} if $types{all} and keys %types > 1;
    $artists{$artist}{types}  = [sort keys %types];
  }
  return \%artists;
}

sub all_components {
  my ($artist, $element, $empty, $days) = @_;
  my $dir = app->config('contrib');
  $empty ||= 'empty.png';
  opendir(my $dh, "$dir/$artist")
      || die "Can't open $dir/$artist: $!";
  my @files = grep { /$element.*\.png$/
		     and (not $days
			  or (stat("$dir/$artist/$_"))[9]
			      >= (time - $days*24*60*60)) } readdir($dh);
  closedir $dh;
  my @components = map { [$empty, $_] } @files;
  return @components;
}

sub all_elements {
  # face is the background, if any (mostly to support photos)
  # chin after mouth (mustache hides mouth)
  # nose after chin (mustache!)
  # hair after ears
  # ears after chin (if you're fat)
  # chin after ears (for your beard) – damn!
  return qw(face eyes brows mouth chin ears nose extra horns bangs hair hat);
}

sub random_components {
  my ($type, $artist, $debug) = @_;
  $type = one(@{$artists{$artist}->{types}}) if $type eq 'random';
  my @elements = all_elements();
  @elements = grep(!/^extra/, @elements) if rand(1) >= 0.1; # 10% chance
  @elements = grep(!/^hat/, @elements) if rand(1) >= 0.1; # 10% chance
  my $dir = app->config('contrib');
  opendir(my $dh, "$dir/$artist") || die "Can't open $dir/$artist: $!";
  my @files = grep { /\.png$/ } readdir($dh);
  closedir $dh;
  my @components;
  for my $element (@elements) {
    my @candidates1 = grep(/^${element}_/, @files);
    my @candidates2 = grep(/_$type/, @candidates1);
    @candidates2 = grep(/_all/, @candidates1) unless @candidates2;
    my $candidate = one(@candidates2) || '';
    unless (app->config('no_flip')
	    and app->config('no_flip')->{$artist}
	    and grep { $type eq $_ } @{app->config('no_flip')->{$artist}}) {
      $candidate .= '_' if $candidate and rand >= 0.5; # invert it!
    }
    push(@components, $candidate) if $candidate;
  }
  unshift(@components, 'empty.png') if $debug;
  return @components;
}

sub render_components {
  my ($self, $artist, @components) = @_;
  my $image;
  my $dir = app->config('contrib');
  for my $component (@components) {
    next unless $component;
    my $layer;
    if (-f "$dir/$component") {
      $layer = GD::Image->newFromPng("$dir/$component", 1);
    } elsif (substr($component, -1) eq '_') {
      $component = substr($component, 0, -1);
      $layer = GD::Image->newFromPng("$dir/$artist/$component", 1);
      $layer->flipHorizontal();
    } else {
      $layer = GD::Image->newFromPng("$dir/$artist/$component", 1);
    }
    # scanned images with a white background: make white transparent unless this
    # is the first image
    if ($layer->isTrueColor == 0 and $layer->transparent == -1 and $image) {
      my $white = $layer->colorClosest(255,255,255);
      $layer->transparent($white);
    }
    # if we already have an image, combine them
    if ($image) {
      $image->copy($layer, 0, 0, 0, 0, $layer->getBounds());
    } else {
      $image = $layer;
      $image->alphaBlending(1);
      $image->saveAlpha(1);
    }
  }
  my $height = $self->param('height');
  my $width = $self->param('width');
  if ($height and $image->height > $height) {
    my $small = GD::Image->new($image->width * $height / $image->height, $height);
    $small->copyResized($image, 0, 0, 0, 0,
			$small->width, $small->height,
			$image->width, $image->height);
    $image = $small;
  }
  if ($width and $image->width > $width) {
    my $small = GD::Image->new($width, $image->height * $width / $image->width);
    $small->copyResized($image, 0, 0, 0, 0,
			$small->width, $small->height,
			$image->width, $image->height);
    $image = $small;
  }
  return $image->png();
}

sub move {
  my ($artist, $element, $direction, $step) = @_;
  my $dir = app->config('contrib');
  my $file = "$dir/$artist/$element";
  my $original = GD::Image->new($file);
  my $image = GD::Image->new(450, 600);
  my $white = $image->colorAllocate(255,255,255); # find white
  $image->rectangle(0, 0, $image->getBounds(), $white);
  if ($direction eq 'up') {
    $image->copy($original, 0, 0, 0, $step, $image->width, $image->height - $step);
  } elsif ($direction eq 'down') {
    $image->copy($original, 0, $step, 0, 0, $image->width, $image->height - $step);
  } elsif ($direction eq 'left') {
    $image->copy($original, 0, 0, $step, 0, $image->width - $step, $image->height);
  } elsif ($direction eq 'right') {
    $image->copy($original, $step, 0, 0, 0, $image->width - $step, $image->height);
  } elsif ($direction eq 'appart') {
    $image->copy($original, $image->width/2 + $step/2, 0, $image->width/2, 0, $image->width/2 - $step/2, $image->height);
    $image->copy($original, 0, 0, $step/2, 0, $image->width/2 - $step/2, $image->height);
  } elsif ($direction eq 'closer') {
    $image->copy($original, $step/2, 0, 0, 0, $image->width/2 - $step/2, $image->height);
    $image->copy($original, $image->width/2, 0, $image->width/2 + $step/2, 0, $image->width/2 - $step/2, $image->height);
  } else {
    die "Unknown direction: $direction\n";
  }
  open(my $fh, '>:raw', $file) or die "Cannot write $file: $!";
  print $fh $image->png();
  close($fh);
}

app->secrets([app->config('secret')]) if app->config('secret');

app->start;

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Faces';
<h1>Faces for your RPG Characters</h1>
<p>This random face generator takes face elements drawn by an artist and
uses them to create a new face.
<p>Pick an artist:
<ul>
<% for my $artist (sort keys %$artists) { %>\
<li><%= link_to url_for(view => {artist => $artist, type => $artists->{$artist}->{types}->[-1]}) => begin %>\
<%= $artists->{$artist}{name} %>\
<% end %>\
<% if ($artists->{$artist}{title}) { %>\
 (<%= $artists->{$artist}{title} %>)\
<% } %>\
<% } %>\
</ul>
<% if ($self->is_user_authenticated()) { %>
<p>
Debugging:
<ul>
<li><%= link_to url_for(debug_artist => {artist => $self->current_user()->{username}}) => begin %>\
<%= $artists->{$self->current_user()->{username}}{name} %>\
<% end %>
</ul>
<% } %>
<p>
Would you like to see your name on this list? Check out our
<a href="https://alexschroeder.ch/cgit/face-generator/about/#how-to-contribute">tutorial</a>.

@@ view.html.ep
% layout 'default';
% title 'Random Face';
<h1>Random Face</h1>
<p>
<%= link_to url_for(view => {type => "$type"}) => begin %>Reload<% end %> the page to get a different face.<br>
Or take a look at the <%= link_to url_for(gallery => {artist => $artist, type => $type}) => begin %>Gallery<% end %>.
<% if (@{$artists->{$artist}->{types}} > 1) { =%>
<br>Or switch type:
<% for my $t (@{$artists->{$artist}->{types}}) {
     $self->stash('t', $t);
     if ($type eq $t) { %>\
<b><%= $t %></b>
<%   } else { %>
<%= link_to url_for(view => {artist => "$artist", type => "$t"})   => begin %><%= $t %><% end %>
<%   }
   } %>
<% } =%>
<p>
<% my $url = $self->url_for(render => { artist=> $artist, files => join(',', @$components)}); %>\
<a href="<%= $url %>" download="random.png">
<img class="face" src="<%= $url %>">
</a>
<p>
Images by <a href="<%= $artists->{$artist}{url} %>"><%= $artists->{$artist}{name} %></a>.
<p class="text">
For demonstration purposes, you can also use this link to a
<%= link_to url_for(random => {artist => $artist, type => $type}) => begin %>random face<% end %>.
You'll get a new random face every time you reload.
If you're writing an application that needs the <i>URL</i> to a random face, you're better using this
<%= link_to url_for(redirect => {artist => $artist, type => $type}) => begin %>redirecting<% end %>
link which gives you a URL to use.

@@ gallery.html.ep
% layout 'default';
% title 'Face Gallery';
<h1>Face Gallery</h1>
<p class="text">
<%= link_to url_for(gallery => {type => "$type"}) => begin %>Reload<% end %> the page to get a different gallery.
<% if (@{$artists->{$artist}->{types}} > 1) {
     my @list = (@{$artists->{$artist}->{types}}, 'random'); =%>
<br>Or switch type:
<% for my $t (@list) {
     $self->stash('t', $t);
     if ($type eq $t) { =%>\
<b><%= $t %></b>
<%   } else { =%>
<%= link_to url_for(gallery => {artist => "$artist", type => "$t"})   => begin %><%= $t %><% end %>
<%   }
   } %>
<% } =%>
<p>
<% for my $files (@$components) {
   my $url = $self->url_for(render => { files => join(',', @$files)}); =%>
<a href="<%= $url %>" class="download" download="random.png">\
<img class="face" src="<%= $url %>">\
</a>\
<% } %>
<p class="text">
Images by <a href="<%= $artists->{$artist}{url} %>"><%= $artists->{$artist}{name} %></a>.

@@ debug.html.ep
% layout 'default';
% title 'Face Debugging';
<h1>Face Debugging (<%= $artist %>)</h1>
<p>
Pick an element:
<ul>
<% for my $element (@$elements) {
   my $url  = $self->url_for(debug_element => { artist => $artist, element => $element }); %>
<li><a href="<%= $url %>"><%= $element %></a></li>
<% } %>
</ul>
<p>
Or pick a type:
<ul>
<% for my $type (@$types) {
   my $url  = $self->url_for(debug_element => { artist => $artist, element => $type }); %>
<li><a href="<%= $url %>"><%= $type %></a></li>
<% } %>
</ul>

@@ debugelement.html.ep
% layout 'default';
% title 'Face Debugging';
<h1>Face Debugging (<%= $artist %>/<%= $element %>)</h1>
<p>
<% for my $files (@$components) {
   my $url  = $self->url_for(render => { artist => $artist, files => join(',', @$files) });
   my $edit = $self->url_for(edit => { artist => $artist, component => $files->[-1] });
   $edit = $edit->query(empty => $empty) if $empty; %>
<a href="<%= $edit %>" class="edit">
<img class="face" src="<%= $url %>">
</a>
<% } %>

@@ edit.html.ep
% layout 'default';
% title 'Element Edit';
<h1>Element Edit</h1>
<p class="text">
Here's where you can make small edits to an element. The image below has eight
zones. Clicking the zone moves the element in its respective direction. The
outer zones move the element by ten pixels, the inner zones move the element by
five pixels.
<p>
<% my $i = 0;
   my $url        = $self->url_for(render => { files => join(',', @$components) });
   my $up         = $self->url_for(move => { component => $components->[-1], dir => 'up'});
   my $down       = $self->url_for(move => { component => $components->[-1], dir => 'down'});
   my $left       = $self->url_for(move => { component => $components->[-1], dir => 'left'});
   my $right      = $self->url_for(move => { component => $components->[-1], dir => 'right'});
   my $half_up    = $self->url_for(move => { component => $components->[-1], dir => 'up'})->query(step => 5);
   my $half_down  = $self->url_for(move => { component => $components->[-1], dir => 'down'})->query(step => 5);
   my $half_left  = $self->url_for(move => { component => $components->[-1], dir => 'left'})->query(step => 5);
   my $half_right = $self->url_for(move => { component => $components->[-1], dir => 'right'})->query(step => 5);
   my $appart     = $self->url_for(move => { component => $components->[-1], dir => 'appart'});
   my $closer     = $self->url_for(move => { component => $components->[-1], dir => 'closer'});
   if ($empty) {
     for my $var (\$up, \$down, \$left, \$right, \$half_up, \$half_down, \$half_left, \$half_right, \$appart, \$closer) {
       $$var = $$var->query({empty => $empty});
     }
   }
   $i++; %>

<img class="debug face" usemap="#map" src="<%= $url %>">
<map name="map">
  <area shape=poly coords="0,0,56,56,168,56,224,0" href="<%= $up %>" alt="Move up">
  <area shape=poly coords="0,299,56,243,168,243,224,299" href="<%= $down %>" alt="Move down">
  <area shape=poly coords="0,0,56,56,56,243,0,299" href="<%= $left %>" alt="Move left">
  <area shape=poly coords="224,0,168,56,168,243,224,299" href="<%= $right %>" alt="Move right">
  <area shape=poly coords="56,56,103,103,122,103,168,56" href="<%= $half_up %>" alt="Move half up">
  <area shape=poly coords="56,243,103,197,122,197,168,243" href="<%= $half_down %>" alt="Move half down">
  <area shape=poly coords="56,56,103,103,103,197,56,243" href="<%= $half_left %>" alt="Move half left">
  <area shape=poly coords="168,56,122,103,122,197,168,243" href="<%= $half_right %>" alt="Move half right">
  <area shape=rect coords="104,104,112,196" href="<%= $appart %>" alt="Move appart">
  <area shape=rect coords="113,104,121,196" href="<%= $closer %>" alt="Move together">
</map>

@@ login.html.ep
% layout 'default';
% title 'Login';
<h1>Login</h1>
<% if ($self->stash('login') eq 'wrong') { %>
<p>
<span class="alert">Login failed. Username unknown or password wrong.</span>
<% } %>
%= form_for login => (enctype => 'multipart/form-data') => (method => 'POST') => begin
%= label_for username => 'Username'
%= text_field 'username'
<p>
%= label_for password => 'Password'
%= password_field 'password'
<p>
%= submit_button 'Login'
<hr>
<p>Home: <%= $home %>
% end

@@ logout.html.ep
% layout 'default';
% title 'Logout';
<h1>Logout</h1>
<p>
You have been logged out.
<p>
Go back to the <%= link_to 'main menu' => 'main' %>.

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
<head>
<title><%= title %></title>
%= stylesheet '/face.css'
%= stylesheet begin
body { padding: 1em; font-family: "Palatino Linotype", "Book Antiqua", Palatino, serif }
a.download, a.edit { text-decoration: none }
.face { height: 300px }
.text { width: 80ex }
.alert { padding: 1ex; background: #ffc0cb; color: #d02090; border: 2px solid #d02090 }
.author { font-size: 80% }
label { display: inline-block; width: 10ex }
@media print {
  .face { height: 1.8in }
  h1, .text, .footer { display: none }
}
% end
<meta name="viewport" content="width=device-width">
</head>
<body>
<%= content %>
<div class="footer">
<hr>
<p>
All the images generated are <a href="http://creativecommons.org/publicdomain/zero/1.0/">dedicated to the public domain</a>.<br>
<%= link_to 'Faces' => 'main' %> &nbsp;
<a href="https://alexschroeder.ch/wiki/Contact">Alex Schroeder</a> &nbsp; <a href="https://alexschroeder.ch/cgit/face-generator/about/">Source</a> &nbsp;
<% if ($self->is_user_authenticated()) { %>
<%= link_to 'Logout' => 'logout' %>
<% } else { %>
<%= link_to 'Login' => 'login' %>
<% } %>
</div>
</body>
</html>
