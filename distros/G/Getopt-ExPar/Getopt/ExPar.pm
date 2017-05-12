package Getopt::ExPar;

$VERSION = "1.01";

# See the bottom of this file for the POD documentation.  Search for the string '=head'.

use English;
use strict;
use warnings;
use Carp;

use vars qw(@ISA $VERSION);

@ISA = qw();
use AutoLoader ();
*AUTOLOAD = \&AutoLoader::AUTOLOAD;

# ExPar.pm - Extended Parameters
#
# Harlin L. Hamilton Jr. <mailto:harlinh@cadence.com>
#
# This package is free, and can be modified or redistributed under # the same terms as Perl itself.

#### Method: new
#######################################################################
# Contructor routine.
#######################################################################
sub _new {
  my($class, $prefs) = @_;

  #Initilize $self
  my($self) = {};
  $self->{'prefs'} = {
    'ooRoutines' => 1,
    'development_check' => 0,
    'abbreviations' => 0,
    'filelistpref' => -1,
    'ignorecase' => 0,
    'switchglomming' => 0,
    'intermingledFiles' => 0,
  };
  $self->{'parameter'} = {};
  $self->{'aliasnamehash'} = {};

  #Overwrite elements in $self as specified by $prefs hash
  &__parse_prefs($self, $prefs) if ((defined $prefs) and (ref($prefs) eq 'HASH'));

  #Grab predefined types: integer, real, key, etc.
  &__assert_predefined_types($self);

  #Bless object into class and return
  bless $self, $class;
}

#Preference methods
sub _ooRoutines {
  my($self) = shift;
  my($value) = shift;
  if (defined $value) {
    $self->{'prefs'}->{'ooRoutines'} = $value;
  } else {
    return $self->{'prefs'}->{'ooRoutines'};
  }
}
sub _development_check {
  my($self) = shift;
  my($value) = shift;
  if (defined $value) {
    $self->{'prefs'}->{'development_check'} = $value;
  } else {
    return $self->{'prefs'}->{'development_check'};
  }
}
sub _abbreviations {
  my($self) = shift;
  my($value) = shift;
  if (defined $value) {
    $self->{'prefs'}->{'abbreviations'} = $value;
  } else {
    return $self->{'prefs'}->{'abbreviations'};
  }
}
sub _filelistpref {
  my($self) = shift;
  my($value) = shift;
  if (defined $value) {
    $self->{'prefs'}->{'filelistpref'} = $value;
  } else {
    return $self->{'prefs'}->{'filelistpref'};
  }
}
sub _ignorecase {
  my($self) = shift;
  my($value) = shift;
  if (defined $value) {
    $self->{'prefs'}->{'ignorecase'} = $value;
  } else {
    return $self->{'prefs'}->{'ignorecase'};
  }
}
sub _switchglomming {
  my($self) = shift;
  my($value) = shift;
  if (defined $value) {
    $self->{'prefs'}->{'switchglomming'} = $value;
  } else {
    return $self->{'prefs'}->{'switchglomming'};
  }
}
sub _intermingledFiles {
  my($self) = shift;
  my($value) = shift;
  if (defined $value) {
    $self->{'prefs'}->{'intermingledFiles'} = $value;
  } else {
    return $self->{'prefs'}->{'intermingledFiles'};
  }
}

#### Method: argl
############################################################################
#Routine to return the value (or the next value) of the specified parameter
############################################################################
sub _argl {
  my($self) = shift;
  my($parameter) = shift;
  return undef unless (exists $self->{'OPT'}->{$parameter});
  my($pKind) = (exists $self->{'special'}->{$parameter})? 'special' : 'parameter';
  if (ref($self->{'OPT'}->{$parameter}) eq 'SCALAR') {
    return $self->{'OPT'}->{$parameter};
  } elsif (ref($self->{'OPT'}->{$parameter}) eq 'ARRAY') {
    $self->{$pKind}->{$parameter}->{'cnt'} = 0
      unless (exists $self->{$pKind}->{$parameter}->{'cnt'});
    if ($self->{$pKind}->{$parameter}->{'cnt'} > $#{$self->{'OPT'}->{$parameter}}) {
      return undef;
    } elsif (@{$self->{'OPT'}->{$parameter}->[$self->{$pKind}->{$parameter}->{'cnt'}]} > 1) {
      return $self->{'OPT'}->{$parameter}->[$self->{$pKind}->{$parameter}->{'cnt'}++];
    } else {
      return $self->{'OPT'}->{$parameter}->[$self->{$pKind}->{$parameter}->{'cnt'}++]->[0];
    }
  }
}

#### Method: arglprepare
############################################################################
#Routine to prepare for calling _argl
############################################################################
sub _arglprepare {
  my($self) = shift;
  my($parameter) = shift;
  my($pKind) = (exists $self->{'special'}->{$parameter})? 'special' : 'parameter';
  delete $self->{$pKind}->{$parameter}->{'cnt'};
}

#### Method: arg
############################################################################
#Routine to return the *first* value for specified parameter unless the
# parameter is a 'switch' then return the scalar value.
############################################################################
sub _arg {
  my($self) = shift;
  my($parameter) = shift;
  return undef unless (exists $self->{'OPT'}->{$parameter});
  if (ref($self->{'OPT'}->{$parameter}) ne 'ARRAY') {
    return $self->{'OPT'}->{$parameter};
  } else {
    my($pKind) = (exists $self->{'special'}->{$parameter})? 'special' : 'parameter';
    my($r) = [];
    if ($pKind eq 'parameter') {
      if (@{$self->{'OPT'}->{$parameter}->[0]} == 1) {
	return $self->{'OPT'}->{$parameter}->[0]->[0];
      } else {
	return $self->{'OPT'}->{$parameter}->[0];
      }
    } else {
      return $self->{'OPT'}->{$parameter}->[0];
    }
    return undef;
  }
}

#### Method: argv/args
############################################################################
#Routine to return all values as an ARRAY ref for specified parameter.
# Or array of array refs if multiple arguments for specified parameter.
############################################################################
sub _argv { return &_args(@_); }
sub _args {
  my($self) = shift;
  my($parameter) = shift;
  return [] unless (exists $self->{'OPT'}->{$parameter});
  if (ref($self->{'OPT'}->{$parameter}) ne 'ARRAY') {
    return [ $self->{'OPT'}->{$parameter} ];
  } else {
    my($r) = [];
    my($pKind) = (exists $self->{'special'}->{$parameter})? 'special' : 'parameter';
    if ($pKind eq 'parameter') {
      foreach my $a ( @{$self->{'OPT'}->{$parameter}} ) {
        if ($#{$a} > 0) {
          my(@a) = @{$a};
          push(@{$r}, \@a); #array of arrays
        } else {
          push(@{$r}, $a->[0]); #array of scalars
        }
      }
    } else {
      foreach my $s ( @{$self->{'OPT'}->{$parameter}} ) {
	if ($#{$s} > 1) {
	  push(@{$r}, @{$s}[1..$#{$s}]); #array of arrays
	} else {
	  push(@{$r}, $s->[1]); #array of scalars
	}
      }
    }
    return $r;
  }
}

#### Method: argh
############################################################################
#Routine to return all values as a HASH ref for specified parameter.
# Hash keys are numeric preserving order of parameters.
#If multi_parameter, returns all args as hash of hashes where subhashes are
# name/value pairs.
############################################################################
sub _argh {
  my($self) = shift;
  my($parameter) = shift;
  return {} unless (exists $self->{'OPT'}->{$parameter});
  if (ref($self->{'OPT'}->{$parameter}) eq 'SCALAR') {
    return { $self->{'OPT'}->{$parameter} => 1 };
  } elsif (ref($self->{'OPT'}->{$parameter}) eq 'ARRAY') {
    my($pKind) = (exists $self->{'special'}->{$parameter})? 'special' : 'parameter';
    #If multi_parameter
    if (exists $self->{'parameter'}->{$parameter}) {
      if (exists $self->{'parameter'}->{$parameter}->{'name'}) {
	my($r) = {};
	foreach my $i ( 0 .. $#{$self->{'OPT'}->{$parameter}} ) {
	  $r->{$i} = { map { $self->{'parameter'}->{$parameter}->{'name'}->[$_],
			     $self->{'OPT'}->{$parameter}->[$i]->[$_] }
		       0 .. $#{$self->{'parameter'}->{$parameter}->{'name'}} };
	}
	return $r;
      } else {
	my($i) = 0;
	return { map { $i++, $_->[0] } @{$self->{'OPT'}->{$parameter}} };
      }
    } else { # special parameter
      if (@{$self->{'OPT'}->{$parameter}->[0]} == 1) {
	return { 0 => { $parameter => $self->{'OPT'}->{$parameter}->[0]->[0], }, };
      } elsif (@{$self->{'OPT'}->{$parameter}->[0]} == 2) {
	return { 0 => { $parameter => $self->{'OPT'}->{$parameter}->[0]->[0], 'opt' => $self->{'OPT'}->{$parameter}->[0]->[1], }, };
      } else {
	my($r) = {};
	foreach my $i ( 0 .. $#{$self->{'OPT'}->{$parameter}} ) {
	  $r->{$i} = { map { ($_ == 0)? $parameter : $self->{'special'}->{$parameter}->{'name'}->[$_-1],
			     $self->{'OPT'}->{$parameter}->[$i]->[$_] }
		       0 .. $#{$self->{'OPT'}->{$parameter}->[0]} };
	}
	return $r;
      }
    }
  } else {
    return undef;
  }
}

#### Method: argc
############################################################################
#Routine to return number of arguments for specified parameter
############################################################################
sub _argc {
  my($self) = shift;
  my($parameter) = shift;
  if (exists $self->{'OPT'}->{$parameter}) {
    if (ref($self->{'OPT'}->{$parameter}) eq 'ARRAY') {
      return $#{$self->{'OPT'}->{$parameter}}+1;
    } else {
      return $self->{'OPT'}->{$parameter};
    }
  } else {
    return 0;
  }
}

#### Method: arge/argt
############################################################################
#Routine to return 0/1 depending on existance of specified parameter.
# Or for special parameters, can check existance of a specific arg.
############################################################################
sub _arge { return &_argt(@_); }
sub _argt {
  my($self) = shift;
  my($parameter) = shift;
  return 0 unless (exists $self->{'OPT'}->{$parameter});
  my($pKind) = (exists $self->{'special'}->{$parameter})? 'special' : 'parameter';
  if ($pKind eq 'parameter') {
    return (exists $self->{'stats'}->{$parameter})? 1 : 0;
  } else {
    my($arg) = shift;
    return (exists $self->{'OPT'}->{$parameter}) unless (defined $arg);
    foreach my $a ( @{$self->{'OPT'}->{$parameter}} ) {
      return 1 if ($a->[0] =~ /$arg/);
    }
  }
  return 0;
}

#### Method: filelist/files
############################################################################
#Routine to return filelist if one exists
############################################################################
sub _files { return &_filelist(@_); }
sub _filelist {
  my($self) = shift;
  return undef unless (exists $self->{'OPT'}->{'filelist'});
  return ($self->{'OPT'}->{'filelist'});
}

#### Method: parse
#######################################################################
#Routine to parse the command line options
#######################################################################
sub _parse {
  my($self) = shift;
  my($argv) = shift;

  #Init some hashes
  $self->{'OPT'} = {};
  $self->{'stats'} = {};
  $self->{'actions'}->{'help'} = 0;

  #Parse @ARGV unless an array reference is passed in as second argument
  $argv = \@ARGV unless ((defined $argv) and (ref($argv) eq 'ARRAY'));

  #Do some development checking here
  if ($self->{'prefs'}->{'development_check'}) {
    #Check to make sure that a help_option value exists for all special parameters
    my($str) = [];
    foreach my $par ( keys %{$self->{'parameter'}} ) {
      push(@{$str}, $par) unless (exists $self->{'parameter'}->{$par}->{'help'});
    }
    foreach my $spec ( keys %{$self->{'special'}} ) {
      push(@{$str}, $spec) unless (exists $self->{'special'}->{$spec}->{'help'});
    }
    carp "Missing help text for these options: ", join(', ', sort @{$str}) if (@{$str} > 0);
    $str = [];
    foreach my $spec ( keys %{$self->{'special'}} ) {
      push(@{$str}, $spec) unless (exists $self->{'special'}->{$spec}->{'help_option'});
    }
    carp "Missing help_option string for these special parameters: ", join(', ', sort @{$str}) if (@{$str} > 0);
  }

  #Very first thing is to check for '-help' options.
  if (@{$argv} and ($argv->[0] eq '--help')) {
    $self->{'actions'}->{'help'} = 1;
    shift(@{$argv});
  } elsif (@{$argv} and ($argv->[0] eq '--full_help')) {
    $self->{'actions'}->{'help'} = 2;
    shift(@{$argv});

  #Check for first element of $argv for 'switchglomming'.  To meet this criteria,
  # the option must not match a defined parameter or alias, and it must not
  # match an abbreviated option if 'abbreviations' is enabled.
  #This 'if' statement also checks to make sure that the next command line argument
  # starts with a '-', OR that trailing file names are permitted.
  } elsif (($self->{'prefs'}->{'switchglomming'}) and
	   @{$argv} and ($argv->[0] =~ /^-([a-zA-Z0-9]+)$/) and
	   (($self->{'prefs'}->{'ignorecase'} and (not exists $self->{'parameter'}->{lc($1)})) or
	    (not exists $self->{'parameter'}->{$1})) and
	   (($self->{'prefs'}->{'ignorecase'} and (not exists $self->{'aliasnamehash'}->{lc($1)})) or
	    (not exists $self->{'aliasnamehash'}->{$1}))) {
    #Now that we've checked to see if it's a defined parameter or an alias, we need to
    # check to see if it's a match on a parameter abbreviation.
    my(@abb);
    if ($self->{'prefs'}->{'ignorecase'}) {
      @abb = grep { /(?i)^$argv->[0]/ } keys %{$self->{'parameter'}};
    } else {
      @abb = grep { /^$argv->[0]/ } keys %{$self->{'parameter'}};
    }
    #Ok, now check to see if it's a valid 'switchglomming' parameter.
    unless (($self->{'prefs'}->{'abbreviations'}) and @abb) {
      $argv->[0] =~ /^-([a-zA-Z0-9]+)$/;
      my($arg) = ($self->{'prefs'}->{'ignorecase'})? lc($1) : $1;
      #This bit of code makes sure that each letter of the potential switchglom is
      # a defined switch or alias for a swich.  Actually, any user-defined type that has
      # 0 arguments can be enabled through this switchglom mechanism.
      my($sg) = {};
      foreach ( split(//, $arg) ) {
        if (exists $self->{'aliasnamehash'}->{$_}) {
	  $sg->{$_} = 1
            if ($self->{'types'}->
                {$self->{'parameter'}->{$self->{'aliasnamehash'}->{$_}}->{'type'}->[0]}->
                {'number_of_arguments'} == 0);
        } elsif (exists $self->{'parameter'}->{$_}) {
	  $sg->{$_} = 1
            if ($self->{'types'}->
                {$self->{'parameter'}->{$_}->{'type'}->[0]}->
                {'number_of_arguments'} == 0);
        }
      }
      if ((scalar keys %{$sg}) == length($arg)) {
        foreach ( keys %{$sg} ) {
	  if ((exists $self->{'aliasnamehash'}->{$_}) or (exists $self->{'parameter'}->{$_})) {
	    delete $sg->{$_};
	  }
        }
        #If no keys left in %sg, then switchglomming found a successful match
        if ((scalar keys %{$sg}) == 0) {
          foreach my $switch ( split(//, $arg) ) {
            if (exists $self->{'parameter'}->{$switch}) {
              $self->{'OPT'}->{$switch} =
                $self->{'types'}->{$self->{'parameter'}->{$switch}->{'type'}->[0]}->{'specifiedvalue'};
              ++$self->{'stats'}->{$switch};
            } else {
              $self->{'OPT'}->{$self->{'aliasnamehash'}->{$switch}} =
                $self->{'types'}->{$self->{'parameter'}->{$self->{'aliasnamehash'}->{$switch}}->{'type'}->[0]}->{'specifiedvalue'};
              ++$self->{'stats'}->{$self->{'aliasnamehash'}->{$switch}};
            }
          }
          shift(@{$argv}); #remove switchglom from command line argument list
        }
      }
    }
  }

  #Loop through options and parse according to $self
  my($i) = 0;
  while ($i < @{$argv}) {

    #Check for 'ignorecase'
    my($cur_argv) = ($self->{'prefs'}->{'ignorecase'})? lc($argv->[$i]) : $argv->[$i];

    #Parse option
    my($origParameter) = $argv->[$i];
    my($parameter) = $origParameter;
    $parameter =~ s/^-//;
 
    #At this point, determine the correctly capitalized parameter if ignorecase
    if ($self->{'prefs'}->{'ignorecase'}) {
      my($a) = [ grep { lc($parameter) eq lc($_) } keys %{$self->{'parameter'}} ];
      if (@{$a} > 0) {
	$parameter = $a->[0];
      }
    }

    #Call help routine if $parameter is now '-help'
    if ($parameter =~ /(?i)^\-?h(e(l(p)?)?)?$/) {
      $self->{'actions'}->{'help'} = 1;
      $i++;
      next;
    #Call full_help routine if $parameter is now '-help'
    } elsif ($parameter =~ /(?i)^\-?full_h(e(l(p)?)?)?$/) {
      $self->{'actions'}->{'help'} = 2;
      $i++;
      next;
    }

    #Store croak message
    my($croak) = '';

    #Make sure this option exists.  First see if it's a defined parameter,
    # then see if it's an alias, then see if it's an abbreviation.
    if (not exists $self->{'parameter'}->{$parameter}) {
      if (exists $self->{'aliasnamehash'}->{$parameter}) {
        $parameter = $self->{'aliasnamehash'}->{$parameter};
      } elsif ($self->{'prefs'}->{'abbreviations'}) {
        my(@args) = grep { ($parameter =~ /^\W/)? /^\\$parameter/ : /^$parameter/ } keys %{$self->{'parameter'}};
        if (@args == 1) {
          if (exists $self->{'parameter'}->{$args[0]}) {
            $parameter = $args[0];
          } else {
            $croak = "Unknown option (-$parameter)";
          }
        } elsif (@args == 0) {
          $croak = "Unknown option (-$parameter)";
        } elsif (@args > 1) {
          $croak = "Ambiguous option (-$parameter) matches @args";
        }
      } else {
        $croak = "Unknown option (-$parameter)";
      }
    }

    if ( length($croak) ) {
      undef $parameter;
      #If $croak is not empty, then no match was found on parameters,
      # so check special parameters.
      if (exists $self->{'special'}) {
        foreach my $sp ( keys %{$self->{'special'}} ) {
          if (($cur_argv =~ /$self->{'special'}->{$sp}->{'special_pattern'}/) or
	      (($cur_argv =~ /(?i)$self->{'special'}->{$sp}->{'special_pattern'}/) and ($self->{'prefs'}->{'ignorecase'}))) {
            $parameter = $sp;
	    last;
          }
        }
      }

      #When at this point, assume argument is a file
      if (not defined $parameter) {
        if ($argv->[$i] !~ /^-/) {
          croak "File list not permitted (starting at '$argv->[$i]')"
            unless (($self->{'prefs'}->{'filelist'} > -1) or ($self->{'prefs'}->{'intermingledFiles'} == 1));
	  if ($self->{'prefs'}->{'intermingledFiles'} == 1) {
	    push(@{$self->{'OPT'}->{'filelist'}}, $argv->[$i]);
	    ++$i;
	    next;
	  } else {
	    push(@{$self->{'OPT'}->{'filelist'}}, @{$argv}[$i..$#{$argv}]);
	    last;
	  }
        }
        #Croak if $croak
        croak $croak if length($croak);
      }
    }

    #Determine parameter or special parameter
    my($pKind) = (grep { exists $self->{$_}->{$parameter} } ('parameter', 'special',))[0];

    #Handle argumentFile types here
    if ($self->{$pKind}->{$parameter}->{'type'}->[0] eq 'argumentFile') {
      my($file) = $argv->[$i+1];
      my($pat) = (exists $self->{$pKind}->{$parameter}->{'argumentFileComment'})?
	'(' . join('|', @{$self->{$pKind}->{$parameter}->{'argumentFileComment'}}) . ')' : '';
      open(AF, "< $file") or croak "Unable to open file $file for reading.\n\n";
      my($argStrArr) = [ 0 ];
      while (<AF>) {
	chomp;
	s/$pat.*$// if length($pat);
	next if /^\s*$/;
	push(@{$argStrArr}, $_);
      }
      close AF;
      my(@args) = `perl -e 'print join(\"\\n\", \@ARGV), \"\\n\";' @{$argStrArr}`;
      chomp(@args);
      splice(@{$argv}, $i, 2, @args);
      splice(@{$argv}, $i, 1);
      $i -= 2;
    }

    #Count parameter instances
    ++$self->{'stats'}->{$parameter};

    #Assign value into $self->{'OPT'}:
    #Handle special case of type that has no arguments (like type 'switch')
    if ($self->{'types'}->{$self->{$pKind}->{$parameter}->{'type'}->[0]}->{'number_of_arguments'} == 0) {
      if ($pKind eq 'parameter') {
        $self->{'OPT'}->{$parameter} =
          $self->{'types'}->{$self->{$pKind}->{$parameter}->{'type'}->[0]}->{'specifiedvalue'};
      } else {
	#since this is a 'special', check pattern and store $1 if it exists
	$argv->[$i] =~ /$self->{'special'}->{$parameter}->{'special_pattern'}/;
	if (defined $1) {
	  push(@{$self->{'OPT'}->{$parameter}}, [ $1 ]);
	} else {
	  push(@{$self->{'OPT'}->{$parameter}}, [ $argv->[$i] ]);
	}
      }
    } else {
      my($args) = [];
      foreach my $typeIndex ( 0 .. $#{$self->{$pKind}->{$parameter}->{'type'}} ) {
	my($type) = $self->{$pKind}->{$parameter}->{'type'}->[$typeIndex];
        croak "Not enough arguments for '$parameter'" unless ($i < $#{$argv});
        my($arg) = $argv->[++$i];
        #Check type specifications first
        if (exists $self->{'types'}->{$type}->{'arguments'}->[0]->{'pattern'}) {
          foreach my $p ( @{$self->{'types'}->{$type}->{'arguments'}->[0]->{'pattern'}} ) {
            croak join('', "Bad $type value ($arg) for parameter '$parameter'",
		       (($pKind eq 'special')? '('.$argv->[$i-@{$args}-1].')' : ''))
              if ($arg !~ /$p/);
          }
        }
        #Now check parameter specifications
        if ((exists $self->{$pKind}->{$parameter}) and
            (exists $self->{$pKind}->{$parameter}->{'pattern'})) {
          foreach my $pat ( @{$self->{$pKind}->{$parameter}->{'pattern'}->[$#{$args}+1]} ) {
            croak join('', "Bad $type value ($arg) for parameter '$parameter'",
		       (($pKind eq 'special')? '('.$argv->[$i-@{$args}-1].')' : ''))
              if ($arg !~ /$pat/);
          }
        }
        #Now check for key match if keys defined
        if ((exists $self->{$pKind}->{$parameter}) and
            (exists $self->{$pKind}->{$parameter}->{'keys'}) and
	    (defined $self->{$pKind}->{$parameter}->{'keys'}->[$typeIndex])) {
	  croak join('', "Bad value ($arg) for parameter '$parameter'",
		     (exists $self->{$pKind}->{$parameter}->{'name'})?
		     ", subParameter '$self->{$pKind}->{$parameter}->{'name'}->[$typeIndex]'" : '',
		     ". Valid values are (", 
                     join(', ', @{$self->{$pKind}->{$parameter}->{'keys'}->[$typeIndex]}), ")")
            unless (exists { map { $_, 1 } @{$self->{$pKind}->{$parameter}->{'keys'}->[$typeIndex]} }->{$arg});
        }

        push(@{$args}, $arg);
	$self->{$pKind}->{$parameter}->{'values'}->{$arg} = 1;
      }

      my($vals) = {};
      if ((exists $self->{'OPT'}->{$parameter}) and (ref($self->{'OPT'}->{$parameter}) eq 'ARRAY')) {
	foreach ( @{$self->{'OPT'}->{$parameter}} ) {
	  $vals->{"@{$_}"} = 1;
	}
      }

      if ($pKind eq 'parameter') {
        push(@{$self->{'OPT'}->{$parameter}}, $args);
      } else {
        push(@{$self->{'OPT'}->{$parameter}}, [ $argv->[$i-@{$args}], @{$args} ]);
      }

      #Do unique check here
      croak "Duplicate arguments '@{$self->{'OPT'}->{$parameter}->[$#{$self->{'OPT'}->{$parameter}}]}' found for option '$parameter' which requries unique arguments"
	if (($self->{$pKind}->{$parameter}->{'unique'}) and (exists $vals->{"@{$self->{'OPT'}->{$parameter}->[$#{$self->{'OPT'}->{$parameter}}]}"}));

    }
    ++$i;
  }

  #Do all argument checking here (prior to default bindings) unless help is requested
  if ($self->{'actions'}->{'help'} == 0) {
    #Check for mutual exclusion
    if (exists $self->{'checks'}->{'mutex'}) {
      foreach my $mutex ( @{$self->{'checks'}->{'mutex'}} ) {
	my($set) = [ grep { exists $self->{'stats'}->{$_} } @{$mutex} ];
	croak "Invalid argument set.  The following options are mutually exclusive: " .
	  join(', ', @{$set}) if (@{$set} > 1);
      }
    }
    #Check for required arguments
    foreach my $p ( keys %{$self->{'parameter'}} ) {
      croak "Required parameter '$p' not specified"
	if ($self->{'parameter'}->{$p}->{'required'} and (not exists $self->{'OPT'}->{$p}));
    }
    #Check for req_grps
    if (exists $self->{'checks'}->{'req_grp'}) {
      foreach my $req_grp ( @{$self->{'checks'}->{'req_grp'}} ) {
	my($set) = [ grep { exists $self->{'stats'}->{$_} } @{$req_grp} ];
	croak "Invalid argument set.  The following options must be used together: " .
	  join(', ', @{$req_grp}) if ((@{$set} != 0) and (@{$set} != @{$req_grp}));
      }
    }
  }

  #Loop through all parameters to see if they've been defined, and if not,
  # assign default values if they exist.
  foreach my $p ( keys %{$self->{'parameter'}} ) {
    next if (exists $self->{'OPT'}->{$p});
    #Assign 'unspecified' values to any parameters w/ zero arguments that weren't specified
    if ($self->{'types'}->{$self->{'parameter'}->{$p}->{'type'}->[0]}->{'number_of_arguments'} == 0) {
      $self->{'OPT'}->{$p} = $self->{'types'}->{$self->{'parameter'}->{$p}->{'type'}->[0]}->{'unspecifiedvalue'};
    } elsif ($self->{'types'}->{$self->{'parameter'}->{$p}->{'type'}->[0]}->{'number_of_arguments'} == 1) {
      @{$self->{'OPT'}->{$p}} = @{$self->{'parameter'}->{$p}->{'default'}}
        if (exists $self->{'parameter'}->{$p}->{'default'});
    }
  }

  #If -help was specified, print help and quit
  &__print_help($self, $argv, $self->{'actions'}->{'help'})
    if ((exists $self->{'actions'}->{'help'}) and ($self->{'actions'}->{'help'} > 0));

}

#### Method: parameter
#######################################################################
# Routine to define a parameter
#######################################################################
sub _parameter {
  my($self) = shift;
  if (@_ == 1) {
    if (ref($_[0]) eq 'HASH') {
      foreach my $p ( keys %{$_[0]} ) {
        &__assign_parameter($self, $p, $_[0]->{$p});
      }
    } else {
      &__assign_parameter($self, $_[0], 'switch');
    }
  } elsif ($_[1] eq 'switches') {
    foreach my $p ( split(//, $_[0]) ) {
      &__assign_parameter($self, $p, 'switch');
    }
  #parameter properties passed in as a hash: { 'type' => 'integer', }
  } elsif (ref($_[1]) eq 'HASH') {
    #make sure type is specified in HASH
    if ($self->{'prefs'}->{'development_check'}) {
      croak "'type' must be specified in HASH passed to _parameter method"
	unless ($_[1]->{'type'});
    }
    #do 'type' first, then do other properties ('default', 'alias', etc.)
    &_type($self, $_[0], $_[1]->{'type'});
    foreach my $prop ( grep { !/^type$/ } keys %{$_[1]} ) {
      no strict 'refs';
      &{"_$prop"}($self, $_[0], $_[1]->{$prop});
    }
  } else {
    my($p) = shift;
    my($t) = shift;
    &__assign_parameter($self, $p, $t);
    &_alias($self, $p, @_) if @_;
  }
}
sub _p { &_parameter(@_); }

#### Method: required_parameter
#######################################################################
# Routine to define a required parameter
#######################################################################
sub _requiredParameter { &_required_parameter(@_); }
sub _required_parameter {
  &_parameter(@_);
  &_required(@_);
}
sub _reqp { &_required_parameter(@_); }
sub _rp { &_required_parameter(@_); }

#######################################################################
# Routine to define a type for a specified parameter
#######################################################################
sub _type { &__assign_parameter(@_); }
sub _t { &_type(@_); }

#######################################################################
# Routine to create hash for specified parameter
#######################################################################
sub __assign_parameter {
  my($self, $parameter, $type) = @_;
  if ($self->{'prefs'}->{'development_check'}) {
    #Check to make sure that parameter is a scalar
    croak "Inappropriate parameter identifier '$parameter'" if ref($parameter);
    #Check to make sure that parameter of that same name doesn't already exit
    croak "Multiply defined parameter '$parameter'"
      if (exists $self->{'parameter'}->{$parameter});
    #Check to make sure that the specified type exists
    croak "Unknown type '$type' cannot be used by option '$parameter'"
      unless (exists $self->{'types'}->{$type});
    #Make sure parameter is not defined as an alias for an existing parameter
    foreach my $a ( %{$self->{'aliasnamehash'}} ) {
      croak "Invalid parameter '$parameter': already defined as an alias for '$self->{'aliasnamehash'}->{$parameter}'"
        if (exists $self->{'aliasnamehash'}->{$parameter});
    }
  }
  $self->{'parameter'}->{$parameter} = { 'type' => [$type], 'unique' => [0], };
  $self->{'parameter'}->{$parameter}->{'required'} = 0;
  $self->{'parameter'}->{$parameter}->{'unique'} = 0;
  $self->{'parameter'}->{$parameter}->{'_ptype'} = 'single';

  &__ooRoutines($self, $parameter);
}

#### Method: multi_parameter
#######################################################################
# Routine to define a parameter w/ multiple arguments
#######################################################################
sub _mp { &_multi_parameter(@_); }
sub _multiParameter { &_multi_parameter(@_); }
sub _multi_parameter {
  my($self) = shift;
  my($parameter) = shift;
  if ($self->{'prefs'}->{'development_check'}) {
    carp "Calling multi_parameter w/ only one named subparameter" if (@_ == 1);
  }
  $self->{'parameter'}->{$parameter}->{'required'} = 0;
  $self->{'parameter'}->{$parameter}->{'unique'} = 0;
  $self->{'parameter'}->{$parameter}->{'_ptype'} = 'multi';
  foreach my $mp ( @_ ) {
    croak "Call to multi_parameter must have HASH references as arguments"
      unless (ref($mp) eq 'HASH');
    croak "Call to multi_parameter must have HASH references w/ only one key"
      unless ((scalar keys %{$mp}) == 1);
    my($name) = (keys %{$mp})[0];
    my($type) = $mp->{$name};
    if ($self->{'prefs'}->{'development_check'}) {
      croak "Multiply defined subparameter '$name' in declaration of '$parameter'"
        if (exists $self->{'parameter'}->{$parameter}->{'nameOrder'}->{$name});
      croak "Unknown type '$type' cannot be used by option '$parameter:$name'"
        unless (exists $self->{'types'}->{$type});
    }
    push(@{$self->{'parameter'}->{$parameter}->{'type'}}, $type);
    push(@{$self->{'parameter'}->{$parameter}->{'name'}}, $name);
    $self->{'parameter'}->{$parameter}->{'nameOrder'}->{$name} =
      $#{$self->{'parameter'}->{$parameter}->{'name'}};
  }
  &__ooRoutines($self, $parameter);
}

#### Method: required_multi_parameter
#######################################################################
# Routine to define a required multi parameter
#######################################################################
sub _requiredMultiParameter { &_required_multi_parameter(@_); }
sub _required_multi_parameter {
  &_multi_parameter(@_);
  &_required(@_);
}
sub _rmp { &_required_multi_parameter(@_); }

#### Method: multi_special
#######################################################################
# Routine to define a special w/ multiple arguments
#######################################################################
sub _multiSpecial { &_multi_special(@_); }
sub _multiSpecialParameter { &_multi_special_parameter(@_); }
sub _multi_special { &_multi_special_parameter(@_); }
sub _multi_special_parameter {
  my($self) = shift;
  my($special) = shift;
  my($special_pattern) = shift;
  if ($self->{'prefs'}->{'development_check'}) {
    carp "Calling multi_special w/ only one named subparameter" if (@_ == 1);
  }
  $self->{'special'}->{$special}->{'required'} = 0;
  foreach my $mp ( @_ ) {
    croak "Call to multi_special must have HASH references as arguments"
      unless (ref($mp) eq 'HASH');
    croak "Call to multi_special must have HASH references w/ only one key"
      unless ((scalar keys %{$mp}) == 1);
    my($name) = (keys %{$mp})[0];
    my($type) = $mp->{$name};
    if ($self->{'prefs'}->{'development_check'}) {
      croak "Multiply defined subparameter '$name' in declaration of '$special'"
        if (exists $self->{'special'}->{$special}->{'nameOrder'}->{$name});
      croak "Unknown type '$type' cannot be used by option '$special:$name'"
        unless (exists $self->{'types'}->{$type});
    }
    push(@{$self->{'special'}->{$special}->{'type'}}, $type);
    push(@{$self->{'special'}->{$special}->{'name'}}, $name);
    $self->{'special'}->{$special}->{'nameOrder'}->{$name} =
      $#{$self->{'special'}->{$special}->{'name'}};
  }
  $self->{'special'}->{$special}->{'special_pattern'} = $special_pattern;
  &__ooRoutines($self, $special);
}
sub _ms { &_multi_special(@_); }
sub _msp { &_multi_special(@_); }

#### Method: special_parameter
#######################################################################
# Routine to define a special parameter
#  sp(<name>, <pattern>)
#  sp(<name>, <pattern>, <type>)
#######################################################################
sub _specialParameter { &_special_parameter(@_); }
sub _s { &_special_parameter(@_); }
sub _special { &_special_parameter(@_); }
sub _special_parameter {
  my($self) = shift;
  croak "Wrong number of arguments in method call" if ((@_ < 2) or (@_ > 3));
  if (@_ == 2) {
    &__assign_special_parameter($self, @_, 'switch');
  } else {
    &__assign_special_parameter($self, @_);
  }
}

#######################################################################
# Routine to create hash for specified special parameter
#######################################################################
sub __assign_special_parameter {
  my($self, $special, $pattern, $type) = @_;
  if ($self->{'prefs'}->{'development_check'}) {
    #Check to make sure that parameter of that same name doesn't already exit
    croak "Multiply defined parameter '$special'"
      if ((exists $self->{'special'}->{$special}) or
          (exists $self->{'parameter'}->{$special}));
    #Check to make sure that the specified type exists
    croak "Unknown type '$type' cannot be used by option '$special'"
      unless (exists $self->{'types'}->{$type});
  }
  $self->{'special'}->{$special}->{'required'} = 0;
  $self->{'special'}->{$special}->{'unique'} = 0;
  $self->{'special'}->{$special} = { 'special_pattern' => $pattern, 'type' => [ $type, ], };
  &__ooRoutines($self, $special);
}

#### Method: alias
#######################################################################
#Routine to associate an alias of set of aliases w/ a parameter
#######################################################################
sub __ooRoutines {
  my($self, $parameter) = @_;
  if ($self->{'prefs'}->{'ooRoutines'}) {
    my($code) = '';
    $code = join('',
		 'sub ', (($parameter =~ /^\d/)? '_' : ''), $parameter,
		 ' { my($self)=shift; return($self->_arg( \'', $parameter, '\', @_)); }', "\n",
		 map { join('',
			    'sub ', (($parameter =~ /^\d/)? '_' : ''), "${parameter}_$_",
			    ' { my($self)=shift; return($self->_', $_, '( \'', $parameter, '\', @_)); }', "\n",) }
		 qw/arge argt args argv argl argc arglprepare argh/);
#    print "$code\n\n";
    eval "$code";
  }
}

#### Method: alias
#######################################################################
#Routine to associate an alias of set of aliases w/ a parameter
#######################################################################
sub _a { &_alias(@_); }
sub _alias {
  my($self) = shift;
  my($parameter) = shift;
  my(%a) = map { $_, 1 } @_;
  if ($self->{'prefs'}->{'development_check'}) {
    foreach my $a ( @_ ) {
      croak "Alias '$a' specified for '$parameter' is already defined for '$self->{'aliasnamehash'}->{$a}'.\n"
        if (exists $self->{'aliasnamehash'}->{$a});
    }
  }
  foreach my $a ( @_ ) {
    $self->{'parameter'}->{$parameter}->{'alias'}->{$a} = 1;
    $self->{'aliasnamehash'}->{$a} = $parameter;
  }
}

#### Method: keys
#######################################################################
#Routine to associate user-specified values w/ specified parameters
# keys( param, 0, 1, 2, 3 )
# keys( param, [ 0, 1, 2, 3 ] )
# keys( multiparam, [ 0, 1, 2 ], [ 4, 5, 6 ], [ 7, 8, 9 ] )
# keys( multiparam, { 'sub1' => [ 0, 1, 2 ], 'sub2' => [ 4, 5, 6 ], 'sub3' => [ 7, 8, 9 ] } )
#######################################################################
sub _key { &_keys(@_); }
sub _k { &_keys(@_); }
sub _keys {
  my($self) = shift;
  my($parameter) = shift;
  my($pKind) = (exists $self->{'special'}->{$parameter})? 'special' : 'parameter';
  if (@{$self->{$pKind}->{$parameter}->{'type'}} > 1) {
    if (@_ > 1) {
      $self->{$pKind}->{$parameter}->{'keys'} = \@_;
    } elsif (ref($_[0]) eq 'HASH') {
      if ($self->{'prefs'}->{'development_check'}) {
	foreach ( keys %{$_[0]} ) {
	  croak "Subparameter $_ does not exist for $parameter"
	    unless (exists $self->{$pKind}->{$parameter}->{'nameOrder'}->{$_});
	}
      }
      foreach ( keys %{$_[0]} ) {
	$self->{$pKind}->{$parameter}->{'keys'}->[$self->{$pKind}->{$parameter}->{'nameOrder'}->{$_}] = $_[0]->{$_};
      }
    } else {
      croak "Format of argument for _keys call is not valid.";
    }
  } else {
    if (ref($_[0]) eq 'ARRAY') {
      $self->{$pKind}->{$parameter}->{'keys'} = [ $_[0] ];
    } else {
      $self->{$pKind}->{$parameter}->{'keys'} = [ \@_ ];
    }
  }
}

#### Method: unique
#######################################################################
#Routine to mark parameters as unique
#######################################################################
sub _u { &_unique(@_); }
sub _unique {
  my($self) = shift;
  foreach my $p ( @_ ) {
    my($pKind) = (exists $self->{'special'}->{$p})? 'special' : 'parameter';
    $self->{$pKind}->{$p}->{'unique'} = 1;
  }
}

#### Method: default
#######################################################################
#Routine to associate default values w/ specified parameters
# For  p: $opt->d('p', 0, 1, 2, 3);
# For mp: $opt->d('p', [0, 1], [2, 3]); 
#######################################################################
sub _d { &_default(@_); }
sub _default {
  my($self) = shift;
  my($parameter) = shift;
  my($pKind) = (exists $self->{'special'}->{$parameter})? 'special' : 'parameter';
  #Quick check for switch or switch-like type
  croak "Default assignment of type '$self->{$pKind}->{$parameter}->{'type'}->[0]' makes no sense"
    if ($self->{'types'}->{$self->{$pKind}->{$parameter}->{'type'}->[0]}->{'number_of_arguments'} == 0);
  #Store default values
  @{$self->{$pKind}->{$parameter}->{'default'}} = map { [ $_ ] } @_;
  #Bulletproofing....do later (check default values for type matching, etc.
  if ($self->{'prefs'}->{'development_check'}) {
  }
}

#### Method: description
#######################################################################
#Routine to store a description of the script
#######################################################################
sub _description {
  use strict 'refs';
  my($self) = shift;
  $self->{'description'} = shift;
}

#### Method: pattern
#######################################################################
#Routine to specify pattern(s) for a particular argument
#######################################################################
sub _pattern {
  my($self) = shift;
  my($parameter) = shift;
  my($pKind) = (exists $self->{'special'}->{$parameter})? 'special' : 'parameter';
  my($i) = 0;
  if (exists $self->{$pKind}->{$parameter}->{'nameOrder'}) {
    my($name) = shift;
    croak "Subparameter ($name) not found for '$parameter'"
      unless (exists $self->{$pKind}->{$parameter}->{'nameOrder'}->{$name});
    $i = $self->{$pKind}->{$parameter}->{'nameOrder'}->{$name};
  }
  push(@{$self->{$pKind}->{$parameter}->{'pattern'}->[$i]}, @_); }

#### Method: help
#######################################################################
#Routine to specify the help string of a parameter
#######################################################################
sub _h { &_help(@_); }
sub _help {
  use strict 'refs';
  my($self) = shift;
  #If only one argument, take as description string for entire script, not for a specific parameter
  if (@_ == 1) {
    $self->{'description'} = $_[0];
    chomp($self->{'description'});
  } elsif (@_ == 2) {
    my($pKind) = (exists $self->{'special'}->{$_[0]})? 'special' : 'parameter';
    $self->{$pKind}->{$_[0]}->{'help'} = $_[1];
    chomp($self->{$pKind}->{$_[0]}->{'help'});
  } else {
    croak "Incorrect number of arguments to 'help' method.";
  }
}

#### Method: help_option
#######################################################################
#Routine to specify the help option for special parameters
#######################################################################
sub _h_opt { &_help_option(@_); }
sub _help_option {
  my($self) = shift;
  if (@_ == 2) {
    $self->{'special'}->{$_[0]}->{'help_option'} = $_[1];
  } else {
    croak "Incorrect number of arguments to 'help_option' method.";
  }
}

#### Method: required
#######################################################################
#Routine to specify that certain parameters are required
#######################################################################
sub _r { &_required(@_); }
sub _required {
  my($self) = shift;
  foreach my $p ( @_ ) {
    my($pKind) = (exists $self->{'special'}->{$p})? 'special' : 'parameter';
    $self->{$pKind}->{$p}->{'required'} = 1;
  }
}

#### Method: mutex
#######################################################################
#Routine to define sets of mutually exclusive parameters.
# This checking takes place after argument parsing and prior to default
# bindings.
#######################################################################
sub _mutually_exclusive { &_mutex(@_); }
sub _mutex {
  my($self) = shift;
  push(@{$self->{'checks'}->{'mutex'}}, \@_);
}

#### Method: req_grp
#######################################################################
#Routine to define sets of options such that if any option in a group
# is used, all others in that group must also be used.
#######################################################################
sub _rg { &_req_grp(@_); }
sub _group { &_req_grp(@_); }
sub _required_group { &_req_grp(@_); }
sub _req_grp {
  my($self) = shift;
  push(@{$self->{'checks'}->{'req_grp'}}, \@_);
}

#### Method: argumentFileComment
#######################################################################
#Routine to add a string for designating comment lines in an
# arguementFile.
#######################################################################
sub _argumentFileComment { &_argument_file_comment(@_); }
sub _argument_file_comment {
  my($self) = shift;
  my($p) = shift;
  my($pKind) = (exists $self->{'special'}->{$p})? 'special' : 'parameter';
  foreach my $c ( @_ ) {
    push(@{$self->{$pKind}->{$p}->{'argumentFileComment'}}, $c);
  }
}

#### Method: _assert_predefined_types
#######################################################################
#Routine to assert predefined types:
# Define the number of arguments.
# Each argument gets an entry in the 'arguments' array defining all 
#  the argument attributes: range, pattern, translation, etc.
##NOTE: I added '. "\$"' on the end of some of these strings to make 
# my emacs highlighting mode happy since it always thinks that $' is a
# perl variable (even at the end of a single-quoted string, and I'm not
# much of a lisp hacker).
#######################################################################
sub __assert_predefined_types {
  my($self) = @_;

  #Switch
  $self->{'types'}->{'switch'} =
    { 'number_of_arguments' => 0,
      #Special keys for types w/ zero arguments
      'specifiedvalue' => 1,
      'unspecifiedvalue' => 0,
    };

  #Integer
  $self->{'types'}->{'integer'} =
    { 'number_of_arguments' => 1,
      'arguments' => [
                      { 'range' => [],
                        'pattern' => [ '^[+-]?\d+' . "\$", ],
                        'translation' => {},
                        'range_translation' => {},
                        'pattern_translation' => {},
                      },
                      ],
      };

  #Natural
  $self->{'types'}->{'natural'} =
    { 'number_of_arguments' => 1,
      'arguments' => [
                      { 'range' => [],
                        'pattern' => [ '^\+?\d+' . "\$", ],
                        'translation' => {},
                        'range_translation' => {},
                        'pattern_translation' => {},
                      },
                      ],
      };

  #Real
  $self->{'types'}->{'real'} =
    { 'number_of_arguments' => 1,
      'arguments' => [
                      { 'range' => [],
                        'pattern' => [ '^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?' . "\$", ],
                        'translation' => {},
                        'range_translation' => {},
                        'pattern_translation' => {},
                      },
                      ],
      };

  #File
  $self->{'types'}->{'file'} =
    { 'number_of_arguments' => 1,
      'arguments' => [
                      { 'range' => [],
                        'pattern' => [],
                        'translation' => {},
                        'range_translation' => {},
                        'pattern_translation' => {},
                      },
                      ],
      };

  #String
  $self->{'types'}->{'string'} =
    { 'number_of_arguments' => 1,
      'arguments' => [
                      { 'range' => [],
                        'pattern' => [],
                        'translation' => {},
                        'range_translation' => {},
                        'pattern_translation' => {},
                      },
                      ],
      };

  #######################################################################
  #ArgumentFile: a file containing more command line arguments to parse
  #######################################################################
  $self->{'types'}->{'argumentFile'} =
    { 'number_of_arguments' => 1,
      'arguments' => [
                      { 'range' => [],
                        'pattern' => [],
                        'translation' => {},
                        'range_translation' => {},
                        'pattern_translation' => {},
                      },
                      ],
      };

}

#### Method: _parse_prefs
#######################################################################
#Routine to parse prefs hash
#######################################################################
sub __parse_prefs {
  my($self, $prefs) = @_;
  #Overwrite elements in $self as specified by $prefs hash
  foreach my $prefKey (keys %{$prefs}) {
    croak "Unknown preference '$prefKey' specified" unless (exists $self->{'prefs'}->{$prefKey});
    if (ref($self->{'prefs'}->{$prefKey}) eq 'HASH') {
      foreach my $key ( @{$prefs->{$prefKey}} ) {
        $self->{'prefs'}->{$prefKey}->{$key} = 1;
      }
    } else {
      $self->{'prefs'}->{$prefKey} = $prefs->{$prefKey};
    }
  }
}

#########################################################################
#Auxiliary routine to return number of arguments for specified parameter
# according to type definition.
#########################################################################
sub __number_of_arguments {
  my($self) = @_;
}

#######################################################################
#Auxiliary routine to print out help text
#######################################################################
sub __print_help {
  my($self, $argv, $lvl) = @_;
  $lvl = 0 unless (defined $lvl);
  #Build up a help string:
  print "\nDESCRIPTION:\n", $self->{'description'}, "\n" if (exists $self->{'description'});
  #$0 <required options> [optional options]
  my($help) = [ "\nUSAGE:\n$0", ];
  foreach my $opt ( grep { (exists $self->{'parameter'}->{$_}->{'required'}) and ($self->{'parameter'}->{$_}->{'required'} == 1) }
		    sort keys %{$self->{'parameter'}} ) {
    push(@{$help}, "-$opt");
    push(@{$help}, join(' ', map { "<$_>" } @{$self->{'parameter'}->{$opt}->{'type'}}))
      unless ($self->{'types'}->{$self->{'parameter'}->{$opt}->{'type'}->[0]}->{'number_of_arguments'} == 0);
  }
  foreach my $opt ( grep { (exists $self->{'special'}->{$_}->{'required'}) and ($self->{'special'}->{$_}->{'required'} == 1) }
		    sort keys %{$self->{'special'}} ) {
    push(@{$help}, (exists $self->{'special'}->{$_}->{'help_option'})? $self->{'special'}->{$_}->{'help_option'} : $self->{'special'}->{$_}->{'pattern'});
  }
  foreach my $opt ( grep { (not exists $self->{'parameter'}->{$_}->{'required'}) or ($self->{'parameter'}->{$_}->{'required'} == 0) }
		    sort keys %{$self->{'parameter'}} ) {
    push(@{$help}, "[-$opt");
    push(@{$help}, join(' ', map { "<$_>" } @{$self->{'parameter'}->{$opt}->{'type'}}))
      unless ($self->{'types'}->{$self->{'parameter'}->{$opt}->{'type'}->[0]}->{'number_of_arguments'} == 0);
    $help->[$#{$help}] .= "]";
  }
  foreach my $opt ( grep { (not exists $self->{'special'}->{$_}->{'required'}) or ($self->{'special'}->{$_}->{'required'} == 0) }
		    sort keys %{$self->{'special'}} ) {
    push(@{$help}, '[' . ((exists $self->{'special'}->{$opt}->{'help_option'})? $self->{'special'}->{$opt}->{'help_option'} : $self->{'special'}->{$opt}->{'special_pattern'}));
    push(@{$help}, join(' ', map { "<$_>" } @{$self->{'special'}->{$opt}->{'type'}}))
      unless ($self->{'types'}->{$self->{'special'}->{$opt}->{'type'}->[0]}->{'number_of_arguments'} == 0);
    $help->[$#{$help}] .= ']';
  }
  print join(' ', @{$help}), "\n\n";
  #Print extended help messages if full_help
  if ($lvl > 1) {
    $help = {};
    foreach my $opt ( sort keys %{$self->{'parameter'}} ) {
      my($key) = "-$opt";
      $key .= join(' ', '', map { "<$_>" } @{$self->{'parameter'}->{$opt}->{'type'}})
	unless ($self->{'types'}->{$self->{'parameter'}->{$opt}->{'type'}->[0]}->{'number_of_arguments'} == 0);
      $help->{$key} = (exists $self->{'parameter'}->{$opt}->{'help'})? $self->{'parameter'}->{$opt}->{'help'} : '__no help text__';
    }
    foreach my $opt ( sort keys %{$self->{'special'}} ) {
      my($key) = (exists $self->{'special'}->{$opt}->{'help_option'})? $self->{'special'}->{$opt}->{'help_option'} : $self->{'special'}->{$opt}->{'special_pattern'};
      $key .= join(' ', '', map { "<$_>" } @{$self->{'special'}->{$opt}->{'type'}})
	unless ($self->{'types'}->{$self->{'special'}->{$opt}->{'type'}->[0]}->{'number_of_arguments'} == 0);
      $help->{$key} = (exists $self->{'special'}->{$opt}->{'help'})? $self->{'special'}->{$opt}->{'help'} : '__no help text__';
    }
    #Get longest key length of $help
    my($len) = (reverse sort {$a<=>$b;} map { length($_) } keys %{$help})[0];
    print "FULL HELP LISTING:\n";
    foreach ( sort keys %{$help} ) {
      print "  ", $_, (' ' x ($len-length($_)+2)), $help->{$_}, "\n";
    }
    print "\n";

    if (exists $self->{'checks'}->{'req_grp'}) {
      foreach my $req_grp ( @{$self->{'checks'}->{'req_grp'}} ) {
	print "These options must be specified together: ", join(', ', @{$req_grp}), ".\n";
      }
      print "\n";
    }
    if (exists $self->{'checks'}->{'mutex'}) {
      foreach my $mutex ( @{$self->{'checks'}->{'mutex'}} ) {
	print "These options are mutually exclusive: ", join(', ', @{$mutex}), ".\n";
      }
      print "\n";
    }
  }

  exit;
}

1;

__END__

=head1 NAME

Getopt::ExPar - Extended Parameters command line parser.

=head1 SYNOPSIS

  use Getopt::ExPar;

  my($opt) = new Getopt::ExPar();

=head1 ABSTRACT

  Method-based command line argument parser.

=head1 DESCRIPTION

This is a method-based command line argument handling package.  ExPar was originally based on EvaP
but was eventually rewritten from scratch.  I have tested it and refined it over the course of around
6 years.  I have been using it for internal projects for several years and now it is time to release it.

=head2 Introduction

Because of the near-infinite combinations of command line arguments, this package may seem burdensome to use.
I hope that is not the case.  In fact, I hope that its feature set will prove invaluable.

A quick list of features:
 - Perl OO interface
 - allows multiple arguments per option: -starship Federation Constitution "USS Enterprise" NCC-1701
 - allows options to be specified as patterns so plusargs can be handled: +plusarg+x=y asdf
 - has some convenience functions like specifying parameter groups and mutually exclusive parameters

A few things to note.  Since this package can create routines on the fly based on the option names, all the internal
routines of ExPar begin with '_'.  So, the 'new' method is really '_new'.

=head2 Preferences

There are several preferences that can be specified when invoking the _new() method.  These can also be set through their
own methods.  Values are set to 0 or 1 unless specified otherwise.

  my($opt) = Getopt::ExPar::_new({ 'ooRoutines' => 1,
				   'development_check' => 1,});

=head3 ooRoutines (method _ooRoutines)
Very useful and possibly dangerous option.  This creates OO methods named after your command line options.  If you use
more than one ExPar object in the same script, this could get tricky.  Also, there are some Perl calls that you cannot duplicate: BEGIN, END, BLOCK, others?
Also, if you happen to name one of your options the same as an internally-used routine, this could cause issues, but all the internal
routines start with '_' so this can be easily avoided.

=head3 development_check (method _development_check)
Set this to a 1 while you are developing your script.  This does some checking to make sure there are no duplicate names used, etc.

=head3 abbreviations (method _abbreviations)
Simply put, this allows the user to use an option only by specifying beginning of the option with enough characters to make it identifiable.
For instance, if you have -xyz and -xvii options, the user could specify -xy or -xv but -x would give an error.

=head3 filelistpref (method _filelistpref)
This determines how extra arguments are handled.  Possible values are -1, 1, 0.  -1 is default and means no files are expected.  0 means that
files may be present.  1 means files must be present.  By default, if 0 or 1 is used, any argument not found to be a match for a known option
is considered the start of the filelist and all other options are considered files.  So, it is possible for a user to give a bad option and the
script to take it as the start of the fileilst.

=head3 intermingledFiles (method _intermingledFiles)
This gives the option to allow files to be anywhere in the arguments.  Any argument that does not match a specified option is added to the filelist.
This overrides the aforementioned behavior of filelistpref and does not take the first non-matching parameter as the start of the file list.

=head3 switchglomming (method _switchglomming)
This allows a group of switches to be specified as the first argument.  For instance, if you have -x -y -z -p -d & -q switches, then the user can
specify them in a single argument but it b<must> be the first argument: UNIX> script.pl -xyzpdq
There is an exception.  If the particular combinations of switches actually spells out another option or abbreviation or alias thereof,
the switchglom will take precedence.  This may or may not be what the user is expecting.  Using the development_check preference can help alleviate this.

=head2 Methods

The 3 types of methods that deal with parameters are those that define, parse and access the command line data.

=head3 Defining Methods

=head4 _parameter (_p)

The main method for defining parameters.  It can be called in several ways, but the primary way is:

  $opt->_parameter( <name>, <type>, <alias> );
  $opt->_parameter( <name>, <type> );
  $opt->_parameter( <name>, );

Currently suppoted types are integer, natural, real, string, file, switch & argumentFile.  If type is not specified, then
'switch' is assumed.

  $opt->_parameter( 'affiliation', 'string', 'aff' );

=head4 _multi_parameter (_mp)

For declaring a parameter that has multiple arguments: -starship Constitution "USS Enterprise" NCC-1701
The declaration syntax for this is a bit tedious and will be expanded in the future:

  $opt->_multi_parameter( <name>, { <arg1_name> => <type>, }, { <arg2_name> => <type>, }, { <arg3_name> => <type>, }, );

Example with 4 arguments where the names of the different arguments are affiliation, class, name, desgination:

  $opt->_multi_parameter( 'starship',
			  { 'affiliation' => 'string' }, { 'class' => 'string' },
			  { 'name' => 'string' }, { 'designation' => 'string' } );

=head4 _special_parameter (_sp)

For declaring a parameter in terms of a perl regular expression.  Was originally created to handle 'plusargs'.

  $opt->_special_parameter( <name>, <pattern>, <type> );
  $opt->_special_parameter( <name>, <pattern>, );

=head4 _multi_special_parameter (_msp)

Finally, for declaring a parameter as a regular expression that has multiple arguments.

  $opt->_multi_special_parameter( <name>, <pattern>, { <arg1_name> => <type>, }, { <arg2_name> => <type>, }, { <arg3_name> => <type>, }, );

=head4 _help (_h)

For declaring some help text for the specified argument.

  $opt->_help( <name>, <help_text> );

=head4 _help_option (_ho)

Since regular expressions do not make for good descriptions unless you understand them, _help_option b<must> be
specified for every _special and _multi_special parameters declared.

_help_option( <name>, <help_option> );

Example:
  $opt->_special( 'mySpecialOption', '\+xyz\+\d+=\S+' );
  $opt->_help_option( 'mySpecialOption', '+xyz+<count>=<description>' );

Basically, _help_option is shown when the help is output for this option.  Where '\+xyz\+\d+=\S+' does not really tell
the user anything, '+xyz+<count>=<description>' is a human-readable description.

=head4 _alias (_a)

  $opt->_alias( <name>, <alias>, <alias2>, <alias3>, ... );

More than one alias can be specified.

=head4 _default (_d)

  $opt->_default( <name>, <default> );

For normal parameters, <default> is a list of scalars:

  $opt->_default( 'affiliation', 'Federation', 'Klingon', );

For multi_parameters, <default> is a list of array references.

  $opt->_default( 'starship', [ 'Federation', 'Constitution', 'USS Enterprise', 'NCC-1701', ], );

=head4 _required (_r)

Used to designate that a parameter must be specified by the user.

  $opt->_required( <name>, <help_text> );

=head4 _keys (_k)

A way to give a list of possible values for an argument.

  $opt->_keys( <name>,  );

=head4 _mutually_exclusive (_mutex)

A list of options that are mutually exclusive.  If one is used, then none of the others may be used.
If this happens, the user is given an appropriate message.

  $opt->_mutually_exclusiev( <opt1>, <opt2>, <opt3>, );

=head4 _required_group (_rg)

A list of options that must be specified together.  If any are used, all must be used.  If not, the
user is given an appropriate error message.

  $opt->_required_group( <opt1>, <opt2>, <opt3>, );

=head4 _unique (_u)

This simply checks to make sure that no arguments are duplicated for the specified parameter.

  $opt->_unique( 'starship' );

This works for any type of parameter and for multi-parameters it will check all arguments.  If an argument
is duplicated, the user is given an appropriate error message.

=head3 Parsing Methods

=head4 _parse

This runs the parser on @ARGV once all the parameters have been defined.

=head3 Accessing Methods

=head4 _arg

Routine to return the *first* value for specified parameter, unless the parameter is a 'switch', then return the scalar value.

=head4 _arge

Routine to return 0/1 depending on existance of specified parameter.  Or for special parameters, can check existance of a specific arg.

=head4 _argc

Routine to return number of arguments for specified parameter.

=head4 _args

Routine to return all values as an ARRAY ref for specified parameter.  Or array of array refs if multiple arguments for specified parameter.

=head4 _argl

Routine to return the value (or the next value) of the specified parameter.

=head4 _arglprepare

Routine to prepare for calling _argl (it resets the internal counter).

=head4 _argh

Routine to return all values as a HASH ref for specified parameter.  Hash keys are numeric preserving order of parameters.
If multi_parameter, returns all args as hash of hashes where subhashes are name/value pairs.

=head4 _filelist

Routine to return filelist if one exists.

=head1 EXAMPLE

=head1 PLANNED FEATURES

Here are a few ideas for future enhancements.  Currently, there is no support
for platforms other than UNIX and no support for languages other than Perl.
(What else could there be...:)

=head2 Command Parameter Completion

Some shells in UNIX allow for command completion where the first few letters of a
command is typed in and a completion-key, usually ESC or TAB, is pressed and the
shell determines if enough letters have been typed to distinguish from any other
command. Some shells allow a refinement of this by completing command parameters.
In I<tcsh>, this is done with the I<complete> command.  For programs with a complex
option set, the I<complete> command can become unmanagable.

Perhaps by calling the perl script with a -complete (--complete) option only, a
I<complete> definition would be printed to STDOUT.

=head1 POSSIBLE FEATURES

=head2 User Requests

I will entertain any [sane] ideas that users may have...:)

=head1 NOTES

This is currently I<Release 1.00>.  There are undoubtedly bugs and shortcomings.
Please email me at B<harlinh@cadence.com> with questions, comments, feature
requests and bug reports.

=head1 VERSION HISTORY

=head2 1.00

Full initial release.

=head2 1.01

Repackaging of tar file.

=head1 AUTHOR

Harlin L. Hamilton Jr., E<lt>harlinh@cadence.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 1998-2008 Harlin L. Hamilton Jr.  All rights reserved. This package is
free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
