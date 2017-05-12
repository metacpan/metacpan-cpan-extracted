#!/usr/bin/perl -w

# Copyright 2012, 2014 Kevin Ryde

# This file is part of LWP-Protocol-rsync.
#
# LWP-Protocol-rsync is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# LWP-Protocol-rsync is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with LWP-Protocol-rsync.  If not, see <http://www.gnu.org/licenses/>.


# Maybe ...

sub _make_listing_to_html {
  my ($fh) = @_;
  $response->header('Content-Type' => 'text/html');
  my $initial = "\
<head><title>file listing</title>
<meta name="Generator" content="LWP-Protocol-rsync $VERSION">
<body>
<base href="$base">
</head>
<body>
<ul>
";
  my $final;
  return sub {
    my $line = readline $fh;
    if (! defined $line) {
      return ($final++ ? "" : "</ul>\n</body>\n");
    }

    $line =~ s/\n$//;
    if ($line =~ m{(l\S+\s+[0-9,.]+\s+[0-9/]+ [0-9:]+\s+)(.*)( -> )(.*)}) {
      $line = (HTML::Entities::encode($1)
               . _html_link_to_filename($2)
               . HTML::Entities::encode($3)
               . _html_link_to_filename($4));
    } elsif ($line =~ m{(\S+\s+[0-9,.]+\s+[0-9/]+ [0-9:]+\s+)(.*)}) {
      $line = (HTML::Entities::encode($1).
               . _html_link_to_filename($2));
    } else {
      $line = HTML::Entities::encode($line);
    }
    $line = $initial . return "<li> " . $line . "\n";
    $initial = '';
    return $line;
  };
}
sub _html_link_to_filename {
  my ($filename) = @_;
  return "<a href=\"". uri_escape($filename) . "\">" . HTML::Entities::encode($filename) . "</a>";
}

