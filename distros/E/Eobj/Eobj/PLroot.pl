#
# This file is part of the Eobj project.
#
# Copyright (C) 2003, Eli Billauer
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# A copy of the license can be found in a file named "licence.txt", at the
# root directory of this project.
#

# Eobj's basic root class
${__PACKAGE__.'::errorcrawl'}='system';
#our $errorcrawl='system';
sub new {
  my $this = shift;
  my $self = $this->SUPER::new(@_);
  my $class = ref($this) || $this;
  $self = {} unless ref($self); 
  bless $self, $class;
  $self->store_hash([], @_);

  my $name = $self->get('name');

  if (defined $name) {
    puke("New \'$class\' object created with illegal name: ".$self->prettyval($name)."\n")
      unless ($name=~/^[a-zA-Z_]\w*$/);

    blow("New \'$class\' object created with an already occupied name: \'$name\'\n")
      if (exists $Eobj::objects{$name});
    my $lc = lc($name);
    foreach (keys %Eobj::objects) {
      blow("New \'$class\' object created with a name \'$name\' when \'$_\' is already in the system (only case difference)\n")
	if (lc($_) eq $lc);
    }
  } else {
    # No name given? Let's be forgiving, and give one of our own...
    $name = $self->suggestname('DefaultName');
    $self->const('name', $name);
  }
  $Eobj::objects{$name}=$self;

  $self -> const('eobj-object-count', $Eobj::objectcounter++);
  return $self;
}  

sub destroy {
  my $self = shift;
  my $name = $self->get('name');

  delete $Eobj::objects{$name};
  bless $self, 'PL_destroyed';
  undef %{$self};

  return undef;
}

sub survivor { } # So method is recognized

sub who {
  my $self = shift;
  return "object \'".$self->get('name')."\'";
}

sub safewho {
  my ($self, $who) = @_;
  return "(non-object item)" unless ($self->isobject($who));
  return $who->who;
}

sub isobject {
  my ($self, $other) = @_;
  my $r = ref $other;
  return 1 if (Eobj::definedclass($r) == 2);
  return undef;
}

sub objbyname {
  my ($junk, $name) = @_;
  return $Eobj::objects{$name};
}

sub suggestname {
  my ($self, $name) = @_;
  my $sug = $name;
  my ($bulk, $num) = ($name =~ /^(.*)_(\d+)$/);
  my %v;

  foreach (keys %Eobj::objects) { $v{lc($_)}=1; } # Store lowercased names
  unless (defined $bulk) {
    $bulk = $name;
    $num = 0;
  }
  
  while ($v{lc($sug)}) {
    $num++;
    $sug = $bulk.'_'.$num;
  }
  return $sug;
}

sub get {
  my $self = shift;
  my $prop = shift;
  my $final;

  my @path = (ref($prop) eq 'ARRAY') ? @{$prop} : ($prop);

  $final = $self->{join("\n", 'plPROP', @path)};

  # Now try to return it the right way. If we have a reference, then
  # the property is set. So if the calling context wants an array, why
  # hassle? Let's just give an array.
  # But if a scalar is expected, and we happen to have only one
  # member in the list -- let's be kind and give the first value
  # as a scalar.

  if (ref($final)) {
    return @{$final} if (wantarray);
    return ${$final}[0];
  }

  # We got here, so the property wasn't defined. Now, if
  # we return an undef in an array context, it's no good, because it
  # will be considered as a list with lenght 1. If the property
  # wasn't defined we want to say "nothing" -- and that's an empty list.

  return () if (wantarray);

  # Wanted a scalar? Undef is all we can offer now.

  return undef;
}

sub getraw {
  my $self = shift;
 
  return $self->{join("\n", 'plPROP', @_)};
}

sub store_hash {
  my $self = shift;
  my $rpath = shift;
  my @path = @{$rpath};
  my %h = @_;

  foreach (keys %h) {
    my $val = $h{$_};

    if (ref($val) eq 'HASH') {
      $self->store_hash([@path, $_], %{$val});
    } elsif (ref($val) eq 'ARRAY') {
      $self->const([@path, $_], @{$val});
    } else {
      $self->const([@path, $_], $val);
    }
  }
}

sub const {
  my $self = shift;
  my $prop = shift;

  my @path = (ref($prop) eq 'ARRAY') ? @{$prop} : ($prop);

  my @newval = @_;

  my $pre = $self->getraw(@path);

  if (defined($pre)) {
    puke("Attempt to change a settable property into constant\n")
      unless (ref($pre) eq 'PL_const');

    my @pre = @{$pre};

    my $areeq = ($#pre == $#newval);
    my $i;
    my $eq = $self->get(['plEQ',@path]);

    if (ref($eq) eq 'CODE') {
      for ($i=0; $i<=$#pre; $i++) {
	$areeq = 0 unless (&{$eq}($pre[$i], $newval[$i]));
      }
    } else { 
      for ($i=0; $i<=$#pre; $i++) {
	$areeq = 0 unless ($pre[$i] eq $newval[$i]); 
      }
    }

    unless ($areeq) {
      if (($#path==2) && ($path[0] eq 'vars') && ($path[2] eq 'dim')) {
	# This is dimension inconsintency. Will happen a lot to novices,
	# and deserves a special error message.
	wrong("Conflict in setting the size of variable \'$path[1]\' in ".
	      $self->who.". The conflicting values are ".
	      $self->prettyval(@pre)." and ".$self->prettyval(@newval).
	      ". (This usually happens as a result of connecting variables of".
	      " different sizes, possibly indirectly)\n");
	
	
      } else {
	{ local $@; require Eobj::PLerrsys; }  # XXX fix require to not clear $@?
	my ($at, $hint) = &Eobj::PLerror::constdump();
	
	wrong("Attempt to change constant value of \'".
	      join(",",@path)."\' to another unequal value ".
	      "on ".$self->who." $at\n".
	      "Previous value was ".$self->prettyval(@pre).
	      " and the new value is ".$self->prettyval(@newval)."\n$hint\n");
      }
    }
  } else {
    if ($Eobj::callbacksdepth) {
      my $prop = join ",",@path;
      my $who = $self->who;
      hint("On $who: \'$prop\' = ".$self->prettyval(@newval)." due to magic property setting\n");
    }
    $self->domutate((bless \@newval, 'PL_const'), @path);

    my $cbref = $self->getraw('plMAGICS', @path);
    return unless (ref($cbref) eq 'PL_settable');
    my $subref;

    $Eobj::callbacksdepth++;
    while (ref($subref=shift @{$cbref}) eq 'CODE') {
      &{$subref}($self, @path);
    }
     $Eobj::callbacksdepth--;
  }
}

sub set {
  my $self = shift;
  my $prop = shift;

  my @path;
  @path = (ref($prop) eq 'ARRAY') ? @{$prop} : ($prop);

  my @newval = @_;

  my $pre = $self->getraw(@path);
  my $ppp = ref($pre);
  puke ("Attempted to set a constant property\n")
    if ((defined $pre) && ($ppp ne 'PL_settable'));
  $self->domutate((bless \@newval, 'PL_settable'), @path);
  return 1;
}

sub domutate {
  my $self = shift;
  my $newval = shift;
  my $def = 0;
  $def=1 if ((defined ${$newval}[0]) || ($#{$newval}>0));
 
  if ($def) {
    $self->{join("\n", 'plPROP', @_)} = $newval;
  } else { delete $self->{join("\n", 'plPROP', @_)}; }
  return 1;
}

sub seteq {
  my $self = shift;
  my $prop = shift;
  my @path = (ref($prop) eq 'ARRAY') ? @{$prop} : ($prop);
  my $eq = shift;
  puke("Callbacks should be references to subroutines\n")
    unless (ref($eq) eq 'CODE');
  $self->set(['plEQ', @path], $eq);
}

sub addmagic {
  my $self = shift;
  my $prop = shift;
  my @path = (ref($prop) eq 'ARRAY') ? @{$prop} : ($prop);
  my $callback = shift;

  unless (defined($self->get([@path]))) {   
    $self->punshift(['plMAGICS', @path], $callback);
  } else {
    $Eobj::callbacksdepth++;
    &{$callback}($self, @path);
    $Eobj::callbacksdepth--;
  }
}

sub pshift {
  my $self = shift;
  my $prop = shift;
  my @path = (ref($prop) eq 'ARRAY') ? @{$prop} : ($prop);
  my $pre = $self->getraw(@path);
  if (ref($pre) eq 'PL_settable') {
    return shift @{$pre}; 
  } else {
    return $self->set($prop, undef) # We're changing a constant property here. Will puke.
      if (defined $pre);
    return undef; # There was nothing there.
  }
}

sub ppop {
  my $self = shift;
  my $prop = shift;
  my @path = (ref($prop) eq 'ARRAY') ? @{$prop} : ($prop);
  my $pre = $self->getraw(@path);
  if (ref($pre) eq 'PL_settable') {
    return pop @{$pre}; 
  } else {
    return $self->set($prop, undef) # We're changing a constant property here. Will puke.
      if (defined $pre);
    return undef; # There was nothing there.
  }
}

sub punshift {
  my $self = shift;
  my $prop = shift;
  my @path = (ref($prop) eq 'ARRAY') ? @{$prop} : ($prop);
  
  my @val = @_;

  my $pre = $self->getraw(@path);
  if (ref($pre) eq 'PL_settable') {
    unshift @{$pre}, @val; 
  } else {
    $self->set(\@path, (defined($pre))? ($pre, @val) : @val);
  }
}

sub ppush {
  my $self = shift;
  my $prop = shift;
  my @path = (ref($prop) eq 'ARRAY') ? @{$prop} : ($prop);
  
  my @val = @_;

  my $pre = $self->getraw(@path);
  if (ref($pre) eq 'PL_settable') {
    push @{$pre}, @val; 
  } else {
    $self->set(\@path, (defined($pre))? (@val, $pre) : @val);
  }
}

sub globalobj {
  return &Eobj::globalobj();
}

sub linebreak {
  my $self = shift;
  return &Eobj::linebreak(@_);
}

sub objdump {
  my $self = shift;
  my @todump;

  unless (@_) {
    @todump = sort {$Eobj::objects{$a}->get('eobj-object-count') <=> 
		      $Eobj::objects{$b}->get('eobj-object-count')} 
    keys %Eobj::objects;
    @todump = map {$Eobj::objects{$_}} @todump; 
  } else {
    @todump = (@_);
  }

  foreach my $obj (@todump) {
    unless ($self->isobject($obj)) {
      my $r = $Eobj::objects{$obj};
      if (defined $r) {
	$obj = $r;
      } else {
	print "Unknown object specifier ".$self->prettyval($obj)."\n\n";
	next;
      }
    }
    
    my @prefix = ();
    print $self->linebreak($self->safewho($obj).", class=\'".ref($obj)."\':")."\n";
    my $indent = '    ';
    foreach my $prop (sort keys %$obj) {
      my @path = split("\n", $prop);
      shift @path if ($path[0] eq 'plPROP');
      my $propname = pop @path;

      # Now we make sure that the @path will be exactly like @prefix
      # First, we shorten @prefix if it's longer than @path, or if it
      # has items that are unequal to @path.

      CHOP: while (1) {
	# If @prefix is longer, no need to check -- we need chopping
	# anyhow
	unless ($#path < $#prefix) {
	  my $i;
	  my $last = 1;
	  for ($i=0; $i<=$#prefix; $i++) {
	    if ($prefix[$i] ne $path[$i]) {
	      $last = 0; last;
	    }
	  }
	  last CHOP if $last;
	}
	my $tokill = pop @prefix;
	$indent = substr($indent, 0, -((length($tokill) + 3)));
      }

      my $out = $indent;

      # And now we fill in the missing @path to @prefix
      while ($#path > $#prefix) {
	my $toadd = $path[$#prefix + 1];
	push @prefix, $toadd;
	$out .= "$toadd > ";
	$toadd =~ s/./ /g; # Substitute any character with white space...
	$indent .= "$toadd   ";
      }
      $out .= "$propname=";

      # Now we pretty-print the value.
      my $valref = $obj->{$prop};
      my @val = (ref($valref)) ? @$valref : (undef);
 
      my $extraindent = $out;
      $extraindent =~ s/./ /g;

      $out .= $self->prettyval(@val);

      # Finally, we do some linebreaking, so that the output will be neat
      print $self->linebreak($out, $extraindent)."\n";
    }
    print "\n";
  }
}

sub prettyval {
  my $self = shift;
  my $MaxListToPrint = 4;
  my $MaxStrLen = 40;

  my @a = @_; # @a will be manipulated. Get a local copy

  if (@a > $MaxListToPrint) {
    # cap the length of $#a and set the last element to '...'
    $#a = $MaxListToPrint;
    $a[$#a] = "...";
  }
  for (@a) {
    # set args to the string "undef" if undefined
    $_ = "undef", next unless defined $_;
    if (ref $_) {
      if ($Eobj::classes{ref($_)}) { # Is this a known object?
	$_='{'.$_->who.'}';    # Get the object's pretty ID
	next;
      }
      # force reference to string representation
      $_ .= '';
      s/'/\\'/g;
    }
    else {
      s/'/\\'/g;
      # terminate the string early with '...' if too long
      substr($_,$MaxStrLen) = '...'
	if $MaxStrLen and $MaxStrLen < length;
    }
    # 'quote' arg unless it looks like a number
    $_ = "'$_'" unless /^-?[\d.]+$/;
    # print high-end chars as 'M-<char>'
    s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;
    # print remaining control chars as ^<char>
    s/([\0-\37\177])/sprintf("^%c",ord($1)^64)/eg;
  }
  
  # append 'all', 'the', 'data' to the $sub string
  return ($#a != 0) ? '(' . join(', ', @a) . ')' : $a[0];
}
