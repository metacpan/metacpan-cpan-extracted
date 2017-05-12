#============================================================= -*-perl-*-
#
# Kite::Profile
#
# DESCRIPTION
#   Module defining an object class used to represent and manipulate
#   2D profiles.
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 2000 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# VERSION
#   $Id: Profile.pm,v 1.3 2000/10/18 08:37:49 abw Exp $
#
#========================================================================
 
package Kite::Profile;

require 5.004;

use strict;
use Kite::Base;
use base qw( Kite::Base );
use vars qw( $VERSION $ERROR $DEBUG );

$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';


#------------------------------------------------------------------------
# init(\%params)
#
# Initialisation method called by the Kite::Base base class
# constructor, new().  A reference to a hash array of configuration
# parameters is passed.  The method returns a true value ($self) if
# successful, or undef on error, with the internal ERROR value set.
#------------------------------------------------------------------------

sub init {
    my ($self, $params) = @_;
    
    # if a FILE parameter is defined then we call parse_file() to load and
    # parse the profile.  If TEXT is defined then we call _parse_text().
    # Otherwise we copy any NAME, X and Y parameters.

    # map all config parameters to upper case
    @$params{ map { uc $_ } keys %$params } = values %$params;

    if ($params->{ FILE }) {
	$self->parse_file($params->{ FILE }) || return undef;	## RETURN ##
    }
    elsif ($params->{ TEXT }) {
	$self->parse($params->{ TEXT }) || return undef;	## RETURN ##
    }
    else {
	my @keys = qw( NAME X Y );
	@$self{ @keys } = @$params{ @keys };
	return $self->error("profile NAME not specified")
	    unless $self->{ NAME };
	return $self->error("profile X values not specified")
	    unless $self->{ X };
	return $self->error("invalid profile X values (expects list ref)")
	    unless ref $self->{ X } eq 'ARRAY';
	return $self->error("profile Y values not specified")
	    unless $self->{ Y };
	return $self->error("invalid profile Y values (expects list ref)")
	    unless ref $self->{ Y } eq 'ARRAY';
    }

    return $self;
}


#------------------------------------------------------------------------
# parse_file($file)
#
# Method called by init() to load a file and parse the contents
# (via a call to parse_text()) when a FILE parameter is specified.
#------------------------------------------------------------------------

sub parse_file {
    my ($self, $filename) = @_;
    my $text;
    local *FIN;

    print STDERR "parse_file($filename)\n" if $DEBUG;

    $self->{ FILENAME } = $filename;
    
    # undefine Input Record Separator and read entire file in one go
    local $/ = undef;
    open(FIN, $filename) 
	|| return $self->error("$filename: $!");
    $text = <FIN>;
    close(FIN);

    $self->parse_text($text);
}


#------------------------------------------------------------------------
# parse_text($text)
#
# Method called by init() or parse_file() to parse the profile
# definition text into an internal form. 
#------------------------------------------------------------------------

sub parse_text {
    my ($self, $text) = @_;
    my @lines = split(/\n/, $text);
    my $source = $self->{ FILENAME } ||= 'input text';
    my ($line, $x, $y, @x, @y);

    print STDERR "parse_text(\"$text\")\n" if $DEBUG;

    $self->{ NAME } = shift(@lines) 
	|| return $self->error("Profile name not found in $source");

    while (defined($line = shift @lines)) {
	chomp $line;
	# ignore blank lines and comments, starting '#' or '%'
	next if $line =~ /^[#%]/ || $line =~ /^\s*$/;
	($x, $y) = $line =~ /([\d\-\.]+)\s*([\d\-\.]+)/;
	push(@x, $x);
	push(@y, $y);
    }
    $self->{ X } = \@x;
    $self->{ Y } = \@y;

    return 1;
}


#------------------------------------------------------------------------
# name($newname)
#
# Returns the existing NAME member if called without any arguments.  
# Updates the NAME if called with a new name parameter.
#------------------------------------------------------------------------

sub name {
    my $self = shift;
    if (@_) {
	$self->{ NAME } = shift;
    }
    else {
	return $self->{ NAME };
    }
}


#------------------------------------------------------------------------
# x()
# y()
# nodes()
#
# Return a pair of references to the X and Y value lists.
#------------------------------------------------------------------------

sub x {
    my $self = shift;
    return $self->{ X };
}

sub y {
    my $self = shift;
    return $self->{ Y };
}

sub nodes {
    my $self = shift;
    return ($self->{ X }, $self->{ Y });
}


#------------------------------------------------------------------------
# n_nodes()
#
# Return the number of nodes that constitute the profile.
#------------------------------------------------------------------------

sub n_nodes {
    my $self = shift;
    return $self->{ SIZE } ||= scalar @{ $self->{ X } };
}


#------------------------------------------------------------------------
# min(\@set)
# max(\@set)
#
# Respectively return the minimum and maximum values of the items in the 
# list passed by reference.
#------------------------------------------------------------------------

sub min {
    my ($self, $set) = @_;
    my $min;

    foreach (@$set) {
	$min = $_, next 
	    unless defined $min;
	$min = $_ 
	    if $_ < $min;
    }
    $min;
}

sub max {
    my ($self, $set) = @_;
    my $max;

    foreach (@$set) {
	$max = $_, next 
	    unless defined $max;
	$max = $_ 
	    if $_ > $max;
    }
    $max;
}

sub min_x {
    my $self = shift;
    $self->{ MINX } ||= $self->min($self->{ X });
}

sub min_y {
    my $self = shift;
    $self->{ MINY } ||= $self->min($self->{ Y });
}

sub max_x {
    my $self = shift;
    $self->{ MAXX } ||= $self->max($self->{ X });
}

sub max_y {
    my $self = shift;
    $self->{ MAXY } ||= $self->max($self->{ Y });
}


#------------------------------------------------------------------------
# length()
# height()
#
# Return the length and height of the profile as calculated by the 
# difference between maximum and minimum points in x and y respectively.
#------------------------------------------------------------------------

sub length {
    my $self = shift;
    $self->{ LENGTH } ||= $self->max_x() - $self->min_x();
}

sub height {
    my $self = shift;
    $self->{ HEIGHT } ||= $self->max_y() - $self->min_y();
}


#------------------------------------------------------------------------
# translate(\@set, $amount);
# translate_x($amount)
# translate_y($amount)
#
# Translate all the X/Y values by the specified amount.
#------------------------------------------------------------------------

sub translate {
    my ($self, $set, $amount) = @_;
    foreach my $i (@$set) {
	$i = $i + $amount;
    }
}

sub translate_x {
    my ($self, $amount) = @_;
    print STDERR "translate_x($amount)\n" if $DEBUG;
    $self->translate($self->{ X }, $amount);
    $self->_changed_size();   # clear memoised size values
}
    
sub translate_y {
    my ($self, $amount) = @_;
    print STDERR "translate_y($amount)\n" if $DEBUG;
    $self->translate($self->{ Y }, $amount);
    $self->_changed_size();   # clear memoised size values
}



#------------------------------------------------------------------------
# scale(\@set, $factor);
# scale_xy($factor)
# scale_x($factor)
# scale_y($factor)
#
# Scale all the X/Y values by the specified factor.
#------------------------------------------------------------------------

sub scale {
    my ($self, $set, $factor) = @_;
    foreach my $i (@$set) {
	$i = $i * $factor;
    }
}

sub scale_x {
    my ($self, $factor) = @_;
    print STDERR "scale_x($factor)\n" if $DEBUG;
    $self->scale($self->{ X }, $factor);
    $self->_changed_size();   # clear memoised size values
}
    
sub scale_y {
    my ($self, $factor) = @_;
    print STDERR "scale_y($factor)\n" if $DEBUG;
    $self->scale($self->{ Y }, $factor);
    $self->_changed_size();   # clear memoised size values
}
   
sub scale_xy {
    my ($self, $factor) = @_;
    print STDERR "scale_xy($factor)\n" if $DEBUG;
    $self->scale($self->{ X }, $factor);
    $self->scale($self->{ Y }, $factor);
    $self->_changed_size();   # clear memoised size values
}


#------------------------------------------------------------------------
# normalise()
# normalise_x()
# normalise_y()
#
# normalise_x() adjusts the profile so that the X values range from 0
# to 1.  It first translates the profile along the X axis so that min_x
# is 0 and then scales the X values by 1/length (i.e. 1/max_x) so that 
# they are normalised to the range 0 - 1.
#
# normalise_y() scales the profile to height 1 but does not perform any
# translation.  Airfoil profiles typically extend above and below Y=0
# and any such translation would change the centre line position, something
# we probably don't want to do.
#
# normalise() adjusts the X values as per normalise_x() and then scales
# the Y values by the *same* factor.  This normalises the profile length
# to 1, and scales the Y values in proportion.
#------------------------------------------------------------------------

sub normalise {
    my $self = shift;
    print STDERR "normalise()\n" if $DEBUG;
    $self->translate_x(-$self->min_x);   # translate so that min_x == 0
    $self->scale_xy(1 / $self->max_x);   # scale so that max_x == 1
}

sub normalise_x {
    my $self = shift;
    print STDERR "normalise_x()\n" if $DEBUG;
    $self->translate_x(-$self->min_x);   # translate so that min_x == 0
    $self->scale_xy(1 / $self->max_x);   # scale so that max_x == 1
    $self->scale_x(1 / $self->max_x);
}

sub normalise_y {
    my $self = shift;
    print STDERR "normalise_y()\n" if $DEBUG;
    $self->scale_y(1 / $self->height);
}


#------------------------------------------------------------------------
# origin()
# origin_x()
# origin_y()
# 
# Translate X/Y, X or Y values so that min_x/min_y lies at the origin 0.
#------------------------------------------------------------------------

sub origin {
    my $self = shift;
    print STDERR "origin()\n" if $DEBUG;
    $self->translate_x(-$self->min_x);
    $self->translate_y(-$self->min_y);
}
    
sub origin_x {
    my $self = shift;
    print STDERR "origin_x()\n" if $DEBUG;
    $self->translate_x(-$self->min_x);
}
    
sub origin_y {
    my $self = shift;
    print STDERR "origin_y()\n" if $DEBUG;
    $self->translate_y(-$self->min_y);
}

    
#------------------------------------------------------------------------
# insert($n, $x, $y)
#
# Insert a new node at position $n with the values $x and $y.  The 
# existing node $n and remainder of the list are moved down by 1 to 
# make room for the new node.
#------------------------------------------------------------------------

sub insert {
    my ($self, $n, $x, $y) = @_;
    my $size = $self->n_nodes();
    
    return $self->error("specific node is out of range ($n)")
	if $n < 0 || $n > $size;

    print STDERR "insert($n, $x, $y)\n" if $DEBUG;
    
    splice(@{ $self->{ X } }, $n, 0, $x);
    splice(@{ $self->{ Y } }, $n, 0, $y);

    $self->_changed_size();

    return 1;
}


#------------------------------------------------------------------------
# delete($n)
#
# Delete node $n and shift the remainder of the list up by one to fill
# the gap.
#------------------------------------------------------------------------

sub delete {
    my ($self, $n) = @_;
    my $size = $self->n_nodes();
    
    return $self->error("specific node is out of range ($n)")
	if $n < 0 || $n >= $size;

    print STDERR "delete($n)\n" if $DEBUG;
    
    splice(@{ $self->{ X } }, $n, 1);
    splice(@{ $self->{ Y } }, $n, 1);

    $self->_changed_size();

    return 1;
}


#------------------------------------------------------------------------
# keep($from, $to)
#
# Splits the profile into two parts, keeping the section of nodes from 
# $from to $to and discarding the rest.  The section $from - $to becomes 
# the new profile.
#------------------------------------------------------------------------

sub keep {
    my ($self, $from, $to) = @_;

    if ($from > $to) {
	my $tmp = $from;
	$from = $to;
	$to = $tmp;
    }

    return $self->error("lower limit is out of range ($from)")
	if $from < 0;
    return $self->error("upper limit is out of range ($to)")
	if $to >= scalar @{ $self->{ X } };

    print STDERR "keep($from, $to)\n" if $DEBUG;
    
    # perl's splice() expects ARRAY, OFFSET, LENGTH
    $to = ++$to - $from;
    $self->{ X } = [ splice(@{ $self->{ X } }, $from, $to) ];
    $self->{ Y } = [ splice(@{ $self->{ Y } }, $from, $to) ];

    return 1;
}


#------------------------------------------------------------------------
# closed()
# close()
#
# closed() returns true if the profile is closed.  That is, if the last 
# node has the same X, Y values as the first.  close() duplicates the 
# first node at the end of the list, if necessary, to ensure that the 
# profile is closed.
#------------------------------------------------------------------------

sub closed {
    my $self = shift;
    my $last = $self->n_nodes - 1;
    return (   $self->{ X }->[ $last ] == $self->{ X }->[0]
            && $self->{ Y }->[ $last ] == $self->{ Y }->[0] );
}

sub close {
    my $self = shift;

    print STDERR "close()\n" if $DEBUG;

    unless ($self->closed()) {
	push(@{ $self->{ X } }, $self->{ X }->[0]);
	push(@{ $self->{ Y } }, $self->{ Y }->[0]);
	$self->_changed_size();   # clear memoised size values
    }
}


#------------------------------------------------------------------------
# a_at_b(\@a, \@b, $b)
# y_at_x($x)
# x_at_y($y)
#
# Returns a reference to an ordered list of Y/X values where the profile 
# crosses the specified point on the X/Y axis.  The profile must be closed 
# to ensure that an even number of crossing points are returned.  
#------------------------------------------------------------------------

sub a_at_b {
    my ($self, $aval, $bval, $b) = @_;
    my ($a, $a1, $a2, $da, $b1, $b2, $db, $ratio, $tmp);
    my $last = $#$aval;
    my @aset = ();

    return $self->error("profile must be closed")
	unless $self->closed();

    for (my $i = 0; $i < $last; $i++) {
	($a1, $a2) = @$aval[ $i, $i+1 ];
	($b1, $b2) = @$bval[ $i, $i+1 ];

	# swap values if necessary to ensure $b1 < $b2
	if ($b1 > $b2) {
	    $tmp = $a1; $a1 = $a2; $a2 = $tmp;
	    $tmp = $b1; $b1 = $b2; $b2 = $tmp;
	}

	if ($b >= $b1 && $b < $b2) {
	    $da = $a2 - $a1;
	    $db = $b2 - $b1;
	    $ratio = ($b - $b1) / $db;
	    $a     = $a1 + $da * $ratio;
	    print STDERR "$b in range [ $b1 -> $b2 ], [ $a1 -> $a2 ] => $a\n"
		if $DEBUG;
	    push(@aset, $a);
	}
    }
    return \@aset;
}

sub y_at_x {
    my ($self, $x) = @_;
    print STDERR "y_at_x($x)\n" if $DEBUG;
    $self->a_at_b($self->{ Y }, $self->{ X }, $x);
}

sub x_at_y {
    my ($self, $y) = @_;
    print STDERR "x_at_y($y)\n" if $DEBUG;
    $self->a_at_b($self->{ X }, $self->{ Y }, $y);
}

	
    

#------------------------------------------------------------------------
# about()
# 
# Returns a string containing information about the profile.
#------------------------------------------------------------------------

sub about {
    my $self  = shift;
    my $debug = $self->{ DEBUG };
    local $"  = ', ';

    my $output = "Profile $self->{ NAME } ($self->{ FILENAME })\n";
    $output   .= sprintf("length: %8.3f   height: %8.3f\n", 
			 $self->length(), $self->height());

    my $n = scalar @{ $self->{ X } };

    $output .= "$n co-ordinate pairs:\n"
 	    .  "    n                X              Y\n"
            .  '-' x 38 . "\n";

    foreach (my $i = 0; $i < $n; $i++) {
	$output .= sprintf("  %3d:  %14.8f  %14.8f\n", $i, 
			   $self->{ X }->[ $i ], 
			   $self->{ Y }->[ $i ]);
    }

    return $output;
}


#------------------------------------------------------------------------
# output()
#
# Returns a text string representing the profile definition in the form:
#
#     Profile Name
#     x1  y1
#     x2  y2
#     ... 
#     xn  yn
#
#------------------------------------------------------------------------

sub output {
    my $self = shift;
    my $text = $self->{ NAME } . "\n";
    my ($x, $y) = @$self{ qw( X Y ) };
    my $n = scalar @$x;

    for(my $i = 0; $i < $n; $i++) {
	$text .= sprintf("%9.7f  %9.7f\n", $x->[$i], $y->[$i]);
    }
    return $text;
}

sub postscript {
    my $self = shift;
    my $vars = shift || { };
    
    require Kite::PScript::Defs;
    require Template;

    my $doc = $self->ps_template();
    my $template = Template->new( POST_CHOMP => 1);
    $vars->{ defs } = Kite::PScript::Defs->new();
    $vars->{ self } = $self;
    $vars->{ border } = 5 unless defined $vars->{ border };
    $vars->{ rotate } ||= 0;
    $vars->{ translate } ||= [0,0];

    my $out = '';
    $template->process(\$doc, $vars, \$out)
	|| return $self->error($template->error());
    return $out;
}

#------------------------------------------------------------------------
# _changed_size()
#
# Private method called when the profile size changes.  Clears any 
# memoised values for LENGTH HEIGHT MINX MAXX MINY and MAXY
#------------------------------------------------------------------------

sub _changed_size {
    my $self = shift;
    @$self{ qw( SIZE LENGTH HEIGHT MINX MAXX MINY MAXY ) } = (undef) x 7;
}
 

#------------------------------------------------------------------------

sub ps_template {
    return <<'EOF';
[% USE fix = format('%.2f') -%]
%!PS-Adobe-3.0
[% IF name %]
%%Title: [% name %]
[% END %]
%%EndComments

[% defs.mm %]
[% defs.lines %]
[% defs.cross %]
[% defs.dot %]
[% defs.circle %]
[% defs.crop %]
[% defs.outline %]

/border [% border %] mm def
[% defs.clip +%]
[% regmarks ? defs.reg : defs.noreg +%]
[% defs.tiles +%]
[% defs.tilemap +%]

/Times-Roman findfont dup dup
  24 scalefont /big-text exch def
  14 scalefont /mid-text exch def
  10 scalefont /min-text exch def

% define profile
/tileimage {
  gsave
[% IF outline %]
  tilepath [% outline %] mm outline
[% END %]

  [% rotate %] rotate
  [% translate.0 %] mm [% translate.1 %] mm translate

  newpath linedashed
  [% self.min_x - 5 %] mm 0 mm moveto
  [% self.max_x + 5 %] mm 0 lineto
  [% self.min_x %] mm -5 mm moveto [% self.min_x %] mm 5 mm lineto
  [% self.max_x %] mm -5 mm moveto [% self.max_x %] mm 5 mm lineto
  stroke

  [% x = self.x
     y = self.y 
  %]
  newpath linenormal
  [% FOREACH i = [0 .. x.max ] %]
     [% fix(x.$i) %] mm [% fix(y.$i) %] mm 
        [%- loop.first ? ' moveto' : ' lineto' +%]
  [% END %]
  stroke
  grestore
} def

/tilepath {
  0 0 translate
  [% rotate %] rotate
  [% translate.0 %] mm [% translate.1 %] mm translate
  newpath
  [% x = self.x
     y = self.y 
  %]
  [% FOREACH i = [0 .. x.max ] %]
     [% fix(x.$i) %] mm [% fix(y.$i) %] mm 
        [%- loop.first ? ' moveto' : ' lineto' +%]
  [% END %]
  [% translate.0 %] neg mm [% translate.1 %] mm neg translate
  [% rotate %] neg rotate
} def


/tilepage {
  regmarks
  /x border 3 mm add def
  /y border 3 mm add def
[% IF map %]
  tilemap
[% END %]
} def    

tilepath tiles
[% defs.dotiles %]

EOF
}



1; 

__END__

=head1 NAME

Kite::Profile - represent and manipulate a 2d profile

=head1 SYNOPSIS

    use Kite::Profile;

    # create new profile 
    my $profile = Kite::Profile->new({
	NAME => "Profile Name",
        X    => [ $x1, $x2, $x3 ... $xn ],
        Y    => [ $y1, $y2, $y3 ... $yn ]
    });

    # load profile from file (plotfoil format)
    my $profile = Kite::Profile->new({
	FILE => 'profiles/S2091'
    }) || die Kite::Profile->error(), "\n";

    # create profile from text string (plotfoil format)
    my $profile = Kite::Profile->new({
	TEXT => "Profile Name\n x1 y1\n x2 y2\n ...\n"
    }) || die Kite::Profile->error(), "\n";

    # get/set the profile name
    print $profile->name();
    $profile->name("New name for this profile");

    # methods for general information and data output
    print $profile->about();
    print $profile->output();

    # methods to return specific profile characteristics
    print $profile->height();
    print $profile->length();
    print $profile->max_x();
    print $profile->min_x();
    print $profile->max_y();
    print $profile->min_y();

    # move (translate) the x or y values by a given amount
    $profile->translate_x($amount);
    $profile->translate_y($amount);

    # move the profile to zero it at the origin (minx = miny = 0)
    $profile->origin();
    $profile->origin_x();
    $profile->origin_y();

    # scale the profile by a given factor
    $profile->scale_xy($factor);
    $profile->scale_x($factor);
    $profile->scale_y($factor);

    # scale the profile to a length (x) or height (y) of 1
    $profile->normalise();
    $profile->normalise_x();
    $profile->normalise_y();

    # insert a node $n with values $x and $y
    $profile->insert($n, $x, $y)
        || warn $profile->error(), "\n";

    # delete node $n
    $profile->delete($n)
        || warn $profile->error(), "\n";

    # discard all but a sub-section of nodes
    $profile->keep($from, $to)
        || warn $profile->error(), "\n";

    # test if profile is closed (first node == last node)
    print "profile is closed\n"
        if $profile->closed();
    
    # add final node if necessary to ensure a closed profile
    $profile->close();

    # find set of X/Y values where profile crosses point on Y/X axis
    my $xpoints = $profile->x_at_y($y);
    print "profile crosses X at Y=$y at [ @$xpoints ]\n";

    my $ypoints = $profile->y_at_x($x);
    print "profile crosses Y at X=$x at [ @$ypoints ]\n";

    # retrieve number of nodes and lists of node values
    my $no_of_nodes = $profile->n_nodes();
    my ($x, $y) = $profile->nodes();
    for (my $i = 0; $i < $no_of_nodes; $i++) {
	print "$i  x: $x->[$i]  y: $y->[$i]\n";
    }

=head1 DESCRIPTION

This module defines an object class which can be used to represent and
manipulate 2D profiles.  In this context, a profile is a set of X,Y
co-ordinates (nodes) that define the outline of a shape.  

For the original intended use in kite construction, these profiles
ultimately represent cutting patterns for pieces of fabric which are
sewn together to form the kite.  However, this module is not specific
to kite design and can be applied to any situation where you wish to
represent a 2-dimensional shapes  by a set of co-ordinates and
perform simple manipulations on it (e.g. scale, translate, sub-section, etc.)

The profile data can be output in a simple format which can be 
subsequently processed (e.g. convert to Postscript) by other tools
(e.g. plotfoil).

=head1 METHODS

=head2 new(\%params) 

Class constructor method to create a new profile object based on data
provided as configuration items, read from a file or provided as a
text string.  The method should be passed a reference to a hash array
containing one of the following items or sets of items.

=over 4 

=item NAME, X, Y

Specify the profile name, and X and Y values for each of the points that
constitute the profile.  The X and Y values should be specified as 
references to lists.

    my $profile = Kite::Profile->new({
	NAME => 'Peter Lynn "Pilot" 4m^2 - Flare'
        X    => [ 2250, 985, 110, 0, 2250 ],
	Y    => [ 0, 480, 280, 0, 0 ],
    });

=item FILE

Specify a filename from which the profile data should be read. 

    my $profile = Kite::Profile->new({ 
	FILE => '/home/abw/kites/pilot/rib'
    });

The constructor returns undef if the file cannot be opened.  The
error() class method can be called to retrieve the specific error
message.

    my $profile = Kite::Profile->new({ 
	FILE => '/home/abw/kites/pilot/rib'
    }) || die Kite::Profile->error();

The expected file format is as per Plotfoil:

     Name of the profile
     x1  y1
     x2  y2
     .   .
     .   .
     xn  yn

Comments (lines starting with # or %) are ignored, as are blank lines.

Example:

     Peter Lynn "Pilot" 4m^2 - Rib 
     # either:
     #   cut 5 of these
     # or:
     #   cut 2 of these and cut the other 3 with the flares (30mm overlap)
     2330    0
     2330   20
      350  270
      300  277
        .    .
        .    .
     2330    0

=item TEXT

This option allows you to specify the profile data as a text string.  The 
format should be as above.

    my $text = 

    my $profile = Kite::Profile->new({ 
	TEXT => "Peter Lynn \"Pilot\" 4m^2 - Rib\n2330 0\n2330 20\n..."; 
    });

=back

=head2 name()

Returns the profile name.  Can also be called with an argument to set a 
new name.

    $profile->name("New name for the profile");

=head2 length()

Returns the profile length (max_x - min_x).

=head2 height()

Returns the profile height (max_y - min_y).

=head2 min_x()

Returns the smallest X value.

=head2 max_x()

Returns the largest X value.

=head2 min_y()

Returns the smallest Y value.

=head2 max_y()

Returns the largest Y value.

=head2 translate_x($amount)

Add a given amount to all the X values, effectively moving the profile
in the X direction.

=head2 translate_y($amount)

Add a given amount to all the Y values, effectively moving the profile
in the Y direction.

=head2 origin()

Translates the profile to the origin so that both minx and max are 0.

=head2 origin_x()

Translates the profile X values so that minx is 0.

=head2 origin_y()

Translates the profile Y values so that miny is 0.

=head2 scale_x($factor)

Multiply all the X values by a given amount, effectively scaling the 
profile in the X direction.

=head2 scale_y($factor)

Multiply all the Y values by a given amount, effectively scaling the 
profile in the Y direction.

=head2 scale_xy($factor)

Multiply all the X and Y values by a given amount, effectively scaling the 
profile in both X and Y directions.

=head2 normalise_x()

Scales the X values (by 1/length) to achieve a profile length of 1.
The profile is moved along the X axis to ensure that min_x is 0.  The
max_x value is then 1 and all other values lie proportionately between
0 and 1.

=head2 normalise_y()

Scales the Y values (by 1/height) to acheive a profile height of 1.
The profile is *NOT* translated to min_x = 0 to ensure that the original
centre line position of the profile is preserved.
range 0 - 1.

=head2 normalise()

Normalises the profile to a length of 1 (see normalise_x()) and then 
scales the Y values by the same factor (1/length).  The end result is 
a proportionately scaled profile of length 1.

=head2 insert($node, $x, $y)

Inserts a new node at the position specified by $node with the $x and $y
values.  The value for $node should be in the range 0 - $nnodes.  The 
existing node $n and any elements following will be shifted futher down
the list by one to make room for the new element.  An element inserted 
at $node position 0 is added to the front of the list.  An element inserted
at a $node position one greater than the last current node will be added to
the end of the list.

Returns 1 if the new node was successfully inserted or undef on error.

=head2 delete($node)

Deletes the node at the position specified by $node and moves the remaining
items in the list up by one to close the gap.

Returns 1 if the node was sucessfully inserted or undef on error. 

=head2 keep($from, $to)

Reduces the profile to a sub-section of nodes identified by $from and
$to.  These should be specified as node numbers from 0 to n_nodes-1.
The nodes in this range (inclusively) are kept to form the new profile 
and the others are discarded.

=head2 closed()

Returns a true/false value to indicate if the profile is closed.  That is, 
if the first and last nodes contain identical X and Y values.

=head2 close()

Duplicates the first node at the end of the list to ensure that the profile
is closed.  Has no effect if the profile is already closed.

=head2 x_at_y($y)

Returns a reference to a list of X values where the profile crosses point
$y on the Y axis.  The profile must be closed.  The list returned will be 
empty if the profile does not cross the specified point or will contain an
even number of items if it does.  Each pair of items thus represents an 
entry/exit transition into/out of the enclosed profile area for increasing
values of X at a fixed Y.

Returns undef on error (e.g. profile not closed).

=head2 y_at_x($x)

Returns a reference to a list of Y values where the profile crosses point
$y on the X axis.  Otherwise similar to x_at_y() above.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 VERSION

$Revision: 1.3 $

=head1 COPYRIGHT

Copyright (C) 2000 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<okprof|okprof>, L<Kite|Kite>, L<Kite::Base|Kite::Base>

=cut


