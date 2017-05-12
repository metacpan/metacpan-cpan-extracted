package MRP::BaseClass;

use Exporter;
use Carp;
use strict;

use MRP::Introspection;
use MRP::Text;
use MRP::Interface;

use vars qw($AUTOLOAD %cache $VERSION);

$VERSION = 1.0;

# print nice diagnostics when functions are incorrectly called
#
sub AUTOLOAD {
    my ($package,$name) = $AUTOLOAD =~ /^(.+?)::([^:]+)$/;
    return if $name eq 'DESTROY';
    #print "Called with @_ and autoload $AUTOLOAD\n";
    my $self = shift || die $package."->".$name." called for nothing!";
    my $ref = ref $self || $self;
    my $message = ($ref eq $self) ? "Can't access '$name' in class $ref:\n" :
	                            "Can't access '$name' in object $self:\n";
    my ($member,$func);
    if($^W) {
	if(ref $self) {
	    foreach $member (sort keys %$self) {
		if( $member =~ /$name/i || $name =~ /$member/i ) {
		    $message .= "Did you mean member\t'$member'?\n";
		}
	    }
	}
	my %funcs = MRP::Introspection::recursiveInheritance($self,'MRP::Introspection::functions');
	foreach $func (sort keys %funcs) {
	  my ($funcn) = $func =~ /([^:]+)$/;
	  if( $funcn =~ /$name/i || $name =~ /$funcn/i ) {
	    $message .= "Did you mean function\t'$func'?\n";
	  }
	}
	my ($package, $filename, $line) = caller;
	$message .= "in $filename at line $line\n";
	$message .= "\n".$self->_printMembers()."\n";
    }
    confess $message;
}

# returns a MRP::MyBase object
# use this for all derived classes
#
sub new {
    my $ref = shift;
    my $class = ref($ref) || $ref;
    my $self = {};
    
    rebless($self,$class);

#    print "Created $self\n";
    return $self;
}

sub DESTROY {
#  my $self = shift;
#  print "Destroying $self\n";
}

sub clone {
  my $self = shift;
  my $depth = shift;
  my $clone = {};
  my ($name, $value);
  my $ref;

  $depth = defined($depth)
    ? ($depth =~ /'shallow'/) ? '' : 1
      : '';

  while (($name, $value) = each %$self) {
    if($depth) {                                      # if we are doing a deep copy
      if($ref = ref($value)) {                        # and we have a reference
	for($ref) {                                   # what type of reference?
	  /^HASH$/ && do { %{$self->{$name}} = %$value; next; };
	  /^ARRAY$/ && do { @{$self->{$name}} = @$value; next; };
	  /^SCALAR$/ && do { my $tmp = $$value; $self->{$name} = \$tmp; next; };
	  $clone->{$name} = $value->can('clone')          # and clone this object
	    ? $value->clone()                         # by hook
	      : $value->MRP::BaseClass::clone($depth); # or by crook
	}
      } else {
	$clone->{$name} = $value;
      }
    } else {                                          # if wee are doing a shallow copy
      $clone->{$name} = $value;                       # add each filed itself.
    }
  }
  
  bless $clone, ref $self;
  return $clone;
}

# reblesses a reference to a base class object into your class
# adds the apropreate members with their default values as
# defined in the %fields hash, and modified by initialize
# If the default value for any of the fields is a hash or
# array ref, puts in a new ref for the object.
#

sub rebless {
  my ($self,$class,%fields);
  if(ref $_[0]) {
    $self = shift || confess "You must give an object to rebless";
    $class = shift || confess "You must give a package to rebless $self into";
  } else {
    $class = shift;
    $self = {};
    my @parents = @_;
    %$self = map { ref $_
		     ? %$_
		       : confess "You tried to treat scalar $_ as an object for rebless"
		     } @parents; # add all the parental fileds to this object
    #print "Multiple inheritance. $self is created from ", MRP::Text->pretyArray(@parents), "\n";
  }

  # add this classes fields to the object
  %fields = _fields($class);
  foreach my $field (sort keys %fields) {
    my $val = $fields{$field};
    for (ref $val) {
      /^ARRAY$/ && do {
	$fields{$field} = [];
	last;
      };
      /^HASH$/ && do {
	$fields{$field} = {};
	last;
      };
    }
  }
  %{$self} = (%{$self}, %fields);
  #print "Reblessing $self into $class\n";
  bless $self, $class;
  my $initialize = MRP::Introspection::function($self,'initialize');
  &$initialize($self) if defined $initialize;

  return $self;
}

# prints a list of all members out - nice but not necisary. Will be lost
#
sub _printMembers {
    my $self = shift;
    my ($key, $val);
    my ($func, $scalar, $hash, $array, $ref);
    my $text;
    local $^W = undef;
    if(ref $self) {
	$text  = "Dumping model for $self\n";
	$text .= "Members\n";
	$text .= MRP::Text->pretyHash("\t", $self);
    }
    $text .= "Methods\n";
    my %funcs = MRP::Introspection::recursiveInheritance($self,'MRP::Introspection::functions');
    foreach $func (sort keys %funcs) {
      $ref = $funcs{$func};
      $func =~ /:_/ && next;
      $func =~ /:memberAccess::.*?_/ && next;
      $func =~ /(croak)|(confess)|(carp)/ && next;
      $text .= "\t$func\t= $ref\n";
    }
    $text .= "Variables\n";
    my %scalars = MRP::Introspection::scalars($self);
    while (($scalar, $ref) = each %scalars) {
	$text .= "\t\$$scalar\t= $$ref\n";
    }
    my %hashes = MRP::Introspection::hashes($self);
    while (($hash, $ref) = each %hashes) {
	$text .= "\t\%$hash\t= $ref=\n".MRP::Text->pretyHash("\t\t", $ref)."\n";
    }
    my %arrays = MRP::Introspection::arrays($self);
    while (($array, $ref) = each %arrays) {
	$text .= "\t\@$array\t= $ref=".MRP::Text->pretyArray($ref)."\n";
    }
    return $text;
}

sub _fields ($) {
  my $thingy = shift;
  my $fields = MRP::Introspection::hash($thingy,'fields');
  return () unless defined $fields;
  return (wantarray)
    ? %$fields
      : $fields;
}

# checks for name clashes between a class and all of it's base classes and delegates.
# Supports multiple inheritance, and multi-level inheritance
#
# also makes sure that $package::memberAccess is at the beginning of @$package::INC
sub check4Clashes {
  my $class = shift;
  my %debug = @_;
  my $memberPackage = $class."::memberAccess";
#  print "Checking $class\n";
  # open the debug streams
  my ($VARIABLES, $DELEGATES);
  if(exists $debug{'variables'}) {
    unless(defined(my $fh = $debug{'variables'})) {
      $VARIABLES = \*STDERR;
    } elsif (ref($fh) eq 'GLOB') {
      $VARIABLES = $fh;
      $debug{'variables'} = undef;
    } else {
      open(VARIABLES, ">>$fh") || die "Could not open $fh for appending: $!";
      $VARIABLES = \*VARIABLES;
      $debug{'variables'} = 'close';
    }
  } else { $VARIABLES = undef; }
  if(exists $debug{'delegates'}) {
    unless(defined(my $fh = $debug{'delegates'})) {
      $DELEGATES = \*STDERR;
    } elsif (ref($fh) eq 'GLOB') {
      $DELEGATES = $fh;
      $debug{'delegates'} = undef;
    } else {
      open(DELEGATES, ">>$fh") || die "Could not open $fh for output: $!";
      $DELEGATES = \*DELEGATES;
      $debug{'delegates'} = 'close';
    }
  } else { $DELEGATES = undef; }
  
  # get the fields has for $class
  my $fields = $class->MRP::BaseClass::_fields() || {};
  my $delegates = MRP::Introspection::hash($class,'delegates') || {};
  my $variables = MRP::Introspection::array($class,'public_vars') || [];
  my %variables = map {
    /^([\@\$\%])(.*)$/;
    ($2,($1 eq '@')
     ? []
     : ($1 eq '%')
     ? {} : undef
    )
  } @$variables;
  my $default = MRP::Introspection::array($class,'defaults') || [];
  my %default = map {
    /^([\@\$\%])(.*)$/;
    ($2,($1 eq '@')
     ? []
     : ($1 eq '%')
     ? {} : undef
    )
  } @$default;
  my %all = map { ($_,1) } keys %$fields, keys %variables, keys %default;
  my $isaref = MRP::Introspection::ISA($class) || [];
  my $override;
  my @found = ();
  
  # check for ambiguous functions
  my $isaCache;
  my @lISA = @$isaref;

  if(@lISA) {
    my $firstParent = shift @lISA;
    $isaCache = $cache{$firstParent};
    unless($isaCache) {
      $firstParent->MRP::BaseClass::check4Clashes();
      $isaCache = $cache{$firstParent};
    }
#    print "$class: Adding $firstParent\n";
  }

  my @clashes;
  my %allfunctions = %{scalar($isaCache->{'functions'}) || {}};
  my %allfields = %{scalar($isaCache->{'fields'}) || {}};
  my $classCache = {functions=>{},fields=>{}};
  my %classFunctions = MRP::Introspection::functions($class);
  my %classFields = MRP::BaseClass->_fields($class);
  foreach (keys %classFunctions) { $classFunctions{$_} = [$class, $classFunctions{$_}] }
  foreach (keys %classFields) { $classFields{$_} = $class }

  foreach my $isa (@lISA) {
#   print "$class: Checking $isa for clashes\n";
    my $isaCache = $cache{$isa} || do {$isa->MRP::BaseClass::check4Clashes, $cache{$isa}};
    my %functions = %{scalar($isaCache->{'functions'}) || {}};
    my %fields = %{scalar($isaCache->{'fields'}) || {}};
    foreach my $function (keys %functions) {
      my ($package,$ref) = @{$functions{$function}};
      if(my $clash = $allfunctions{$function}) {
	if($clash->[1] ne $ref) {
	  unless($classFunctions{$function}) {
	    push @clashes, "$package->$function\t <----->\t$clash->[0]"."->$function";
	  }
	}
      }
      $allfunctions{$function} = $functions{$function};
    }
    foreach my $field (keys %fields) {
      if(my $clash = $allfields{$field}) {
	push @clashes, "method:   $isa->$field\t <----->\t$clash->$field";
      }
      $allfields{$field} = $fields{$field};
    }
  }

  foreach my $delegate (keys %$delegates) {
    my $list = $delegates->{$delegate};
    ref $list || next;
    my @list;
    foreach my $func (@$list) {
      (ref($func)) and
	push @list, $func->functions() or
	  push @list, $func;
    }
    foreach my $func (@list) {
      if(my $clash = $allfunctions{$func}) {
	unless($classFunctions{$func}) {
	  push @clashes, "delegate: $delegate->$func\t <-----> " . $clash->[0] . "->$func";
	}
      }
    }
  }

  %allfunctions = (%allfunctions, %classFunctions);
  %allfields = (%allfields, %classFields);

  # check that delegate functions do not clash with fields or inherited functions
  foreach my $field (keys %$fields) {
    foreach my $delegate (keys %$delegates) {
      push @clashes,
		  map { ($field eq $_ and
		       not MRP::Introspection::function($class,$field))
			  ? "field $field clashes with $delegate->$_"
			    : ();
		      } @{$delegates->{$delegate}}
    }
  }

  # check that default variables don't clash with package/field or inherited field variables
  foreach my $default (keys %default) {
    if(exists $fields->{$default}) {
      push @clashes, "default $default clashes with field";
    } elsif (exists $allfields{$default}) {
      push @clashes, "default $default clashes with inherited field";
    } elsif (exists $variables{$default}) {
      push @clashes, "default $default clashes with variable";
    }
  }
  %$fields = (%$fields, map { ($_,undef) } keys %default);

  if(@clashes) {
    die "The following parts of $class are ambiguous:\n",
    join "\n",@clashes,"\n";
  }

  my $func;
  # add the member access functions
  foreach my $item (keys %all) {
    my $item_ref = $item.'_ref';
    my $item_field = $item.'_field';
    my $item_global = $item.'_global';
    MRP::Introspection::function($memberPackage,$item)
      && confess "$item already exists in $memberPackage\n";
    # generate the @default member access functions
    if(exists $default{$item}) {
      #print "Generating defualt function for '$item'\n";
      for (ref $default{$item}) {
	if(/^ARRAY$/) {	# this is an array member
	  $func = $class->_fieldArrayFunc($memberPackage,$item_field,$item);
	  $func.= $class->_packageArrayFunc($memberPackage,$item_global,$item);
	} elsif (/^HASH$/) {	# this is a hash member
	  $func = $class->_fieldHashFunc($memberPackage,$item_field,$item);
	  $func.= $class->_packageHashFunc($memberPackage,$item_global,$item);
	} else {
	  $func = $class->_fieldScalarFunc($memberPackage,$item_field,$item,$fields->{$item});
	  $func.= $class->_packageScalarFunc($memberPackage,$item_global,$item);
	}
      }
      $func .= $class->_defaultField($memberPackage, $item,
				     $item_field, $item_global)
    } elsif(exists $fields->{$item}) {
      if(exists $variables{$item}) {
	# Generate access functions for duel field/package items
	#print "generating dual acces for '$item'\n";
	for (ref $fields->{$item}) {
	  if(/^ARRAY$/) {
	    $func = $class->_fieldArrayFunc($memberPackage,$item_field,$item);
	  } elsif (/^HASH$/) {
	    $func = $class->_fieldHashFunc($memberPackage,$item_field,$item);
	  } else {
	    $func = $class->_fieldScalarFunc($memberPackage,$item_field,$item,$fields->{$item});
	  }
	}
	for (ref $variables{$item}) {
	  if(/^ARRAY$/) {
	    $func .= $class->_packageArrayFunc($memberPackage,$item_global,$item);
	  } elsif (/^HASH$/) {
	    $func .= $class->_packageHashFunc($memberPackage,$item_global,$item);
	  } else {
	    $func .= $class->_packageScalarFunc($memberPackage,$item_global,$item);
	  }
	}
	$func .= $class->_packageAndField($memberPackage, $item,
					  $item_field, $item_global)
      } else {
	# generate field member functions
	#print "generating field '$item'\n";
	for (ref $fields->{$item}) {
	  if(/^ARRAY$/) {
	    $func = $class->_fieldArrayFunc($memberPackage,$item);
	  } elsif (/^HASH$/) {
	    $func = $class->_fieldHashFunc($memberPackage,$item);
	  } else {
	    $func = $class->_fieldScalarFunc($memberPackage,$item,$fields->{$item});
	  }
	}
      }
    } else {
      # generate package member functions
      #print "Generating package member function '$item'";
      for (ref $variables{$item}) {
	if(/^ARRAY$/) {
	  $func = $class->_packageArrayFunc($memberPackage,$item);
	} elsif (/^HASH$/) {
	  $func = $class->_packageHashFunc($memberPackage,$item);
	} else {
	  $func = $class->_packageScalarFunc($memberPackage,$item);
	}
      }
    }
   $VARIABLES && print $VARIABLES $func;
#    print "Compiling member access:\n$func\n";
    eval $func; $@ && die "Error compiling code: $@";
  }
  # add the delegation functions
  foreach my $delegate (keys %$delegates) {
#    print "Processing delegate $delegate\n";
    exists $fields->{$delegate} and
      die "You have specified $class->$delegate as a delegate but there is a field by that name";
    my @interfaces = ();
    my $func = "";
    foreach my $item (@{$delegates->{$delegate}}) {
#      print "Generating delegate for '$delegate->$item'\n";
      if(ref($item)) {
	$func .= join '', map { $class->_delegateFunc($memberPackage,$delegate,$_) } ($item->functions());
	push @interfaces, $item;
      } else {
	$func .= $class->_delegateFunc($memberPackage,$delegate,$item); # make a function for it
      }
      $DELEGATES && print $DELEGATES $func;
    }
    $func .= $class->_delegateAccess($memberPackage,$delegate,@interfaces);
#    print "Compiling delegates:\n$func\n";
    eval $func; $@ && die "Error compiling code:\n$func";
  }
  # now add that entry to @ISA
  my %ISA = map { ($_,1) } @$isaref;
  if(((%all or %$delegates) and not exists $ISA{$class."::memberAccess"})) {
    $memberPackage->MRP::BaseClass::check4Clashes();
    unshift(@$isaref, $class."::memberAccess");
    %allfunctions = (%allfunctions,%{$cache{$memberPackage}->{functions}});
  }

  $classCache->{functions} = {%allfunctions};
  $classCache->{fields} = {%allfields};
#  print "$class has interface\n", MRP::Text->pretyHash('  ', %allfunctions), "\n";
  
  $cache{$class} = $classCache;
  close $VARIABLES if $debug{'variables'};
  close $DELEGATES if $debug{'delegates'};
#  print "Checked  $class\n";
}

sub _delegateFunc {
  my ($thingy, $memberPackage, $delegate, $function) = @_;

  return qq(
	    package $memberPackage;
	    sub $function {
			   my \$self = shift;
			   return \$self->$delegate->$function(\@_);
			  }
	   );
}

sub _delegateAccess {
  my ($thingy, $memberPackage, $item) = (shift,shift,shift);

  my $performChecks = join ";\n", map {qq(MRP::Interface->$_->implementedBy(\$value) or
					  Carp::confess "Delegate \$value must implement interface $_")
				     } map { $_->name() } @_;

  return qq(
	    package $memberPackage;
	    sub $item {
		       my \$self = shift;
		       if(\@_) {
			 my \$value = shift;
			 $performChecks;
			 return \$self->{'$item'} = \$value;
		       } else {
			 return \$self->{'$item'};
		       }
		      }
	   );
}

sub _fieldScalarFunc {
    my ($thingy, $memberPackage, $name, $interface, $item) = @_;
    $item ||= $name;

    my $interfaceText = "";
    if(ref($interface)) {
      $interface = $interface->name;
      $interfaceText = qq(MRP::Interface->$interface->implementedBy(\$_[0]) or
			  Carp::confess "field \$_[0] must implement interface $interface";);

    }

    return qq(
	      package $memberPackage;
	      sub $name {
			 my \$self = shift;
			 (\@_)
			 ? do { $interfaceText
				\$self->{'$item'} = \$_[0];
			      }
			 : \$self->{'$item'};
			}
	     );
}

sub _packageScalarFunc {
    my ($thingy, $memberPackage, $name, $item) = @_;
    $item ||= $name;
    my $packagevar = $thingy.'::'.$item;

    return qq(
	      package $memberPackage;
	      sub $name {
			 my \$class = shift;
			 scalar(\@_)
			 ? \$$packagevar = \$_[0]
			 : \$$packagevar;
			}
              );
}

sub _fieldArrayFunc {
    my ($thingy, $memberPackage, $name, $item) = @_;
    $item ||= $name;
    my $name_ref = $name.'_ref';

    return qq(
	      package $memberPackage;
	      sub $name {
			 my \$self = shift;
			 if (\@_ or not defined wantarray) {
			   \$self->{'$item'} = [] if not defined \$self->{'$item'};
			   \@{\$self->{'$item'}} = \@_;
			 }
			 my \$ret = \$self->{'$item'};
			 return ref(\$ret)
			 ? (wantarray)
			   ? \@{\$self->{'$item'}}
			   : \$self->{'$item'}
                         : (not defined \$ret)
                           ? undef
			   : &Carp::confess("Ilegal value for $item in \$self\n".\$self->_printMembers);
			}
	  ) . $thingy->_fieldScalarFunc($memberPackage, $name_ref, undef, $item);
}

sub _packageArrayFunc {
    my ($thingy, $memberPackage, $name, $item) = @_;
    $item ||= $name;
    my $packagevar = $thingy.'::'.$item;

    return qq(
	      package $memberPackage;
	      sub $name {
			 my \$class = shift;
			 \@$packagevar = \@_ if (\@_) or not defined wantarray;
			 wantarray
			 ? \@$packagevar
			 : \\\@$packagevar;
			}
              );
}

sub _fieldHashFunc {
    my ($thingy, $memberPackage, $name, $item) = @_;
    $item ||= $name;
    my $name_ref = $item.'_ref';

    return qq(
	      package $memberPackage;
	      sub $name {
			 my \$self = shift;
			 if(\@_ or not defined wantarray) {
			   if(\@_==1) {
			     my \$val = shift;
			     if(ref \$val eq 'HASH') {
			       %{\$self->{'$item'}} = %\$val;
			     } elsif (ref \$_[0] eq 'ARRAY') {
			       %{\$self->{'$item'}} = \@\$val;
			     } else {
			       Carp::confess "Can not set the hash member variable '$item' to \$val";
			     }
			   } else {
			     %{\$self->{'$item'}} = \@_;
			   }
			 }
			 my \$ret = \$self->{'$item'};
			 return (ref \$ret)
			   ? (wantarray)
			     ? (%{\$self->{'$item'}})
			     : (\$self->{'$item'})
			   : not defined(\$ret)
                             ? undef
			     : Carp::confess "Member $item of \$self has gained the ilegal value '\$ret'" . \$self->_printMembers;
			}
	      ) . $thingy->_fieldScalarFunc($memberPackage, $name_ref, undef, $item);
}

sub _packageHashFunc {
    my ($thingy, $memberPackage, $name, $item) = @_;
    $item ||= $name;
    my $packagevar = $thingy.'::'.$item;

    return qq(
	      package $memberPackage;
	      sub $name {
			 my \$class = shift;
			 \%$packagevar = \@_ if (\@_ or not defined wantarray);
			 wantarray
			 ?\%$packagevar
			 : \\%$packagevar;
			}
              );
}

sub _packageAndField {
    my ($thingy,$memberPackage,$item,$fieldFunc,$packageFunc) = @_;

    return qq(
	      package $memberPackage;
	      sub $item {
			 my \$thingy = shift;
			 ref(\$thingy)
			 ? \$thingy->$fieldFunc(\@_)
			 : \$thingy->$packageFunc(\@_);
			}
              );
}

sub _defaultField {
    my ($thingy,$memberPackage,$item,$fieldFunc,$packageFunc) = @_;

    return qq(
	      package $memberPackage;
	      sub $item {
			 my \$thingy = shift;
			 my \@return;
			 ref(\$thingy)
			 ? do {
			   \@return = (\$thingy->$fieldFunc(\@_));
			   (\@return &&
			    not (\@return == 1 && not defined(\$return[0])))
			     ? \@return
			       : \$thingy->$packageFunc(\@_)
			 }
			 : \$thingy->$packageFunc(\@_);
			}
              );
}

use vars qw(%builtInRefs);
%builtInRefs = map { ($_,1) } qw(REF SCALAR ARRAY HASH CODE GLOB);

sub isObject {
  my $self = shift;
  my $ref = shift;
  $ref = ref($ref) || return undef;
  exists $builtInRefs{$ref} && return undef;
  return $ref;
}

BEGIN {
  use vars qw(@ISA);
  @ISA = qw(Exporter);
  MRP::BaseClass->check4Clashes();
}

$VERSION;  # says use was ok
__END__

=head1 NAME

MRP::BaseClass - My base class object

=head1 DESCRIPTION

Base class for my perl objects that generates the class interface from
a definition.

=head1 SYNOPSIS

The aim of this package is to allow you to define a classes interface,
and have perl generate all of the standard functions for
you. Currently, you can define:

=over

=item fields

Member access functions are auto-generated so that nowhere in your
code do you ever directly access member variables.

=item package variables

Class functions are auto-generated to make package variables work like
static class members.

=item default variables

The package variable an be made to act as the default value for a
field of the same name.

=item delegation support

Simply specify which field is a delegate and which funcitons to
delegate to it, and the glue code is auto-generated.

=back

The other realy usefull thing it does is provide dramaticaly better
error messages when methods or static functions canot be found. Try
invoking the <C -w> flag. It even lists possible correct spellings of
misspelled function names!

As a matter of course, I include the class definition in a BEGIN block
at the end of the package. This allows the interface to be checked,
and the code to be generated at compile time. This has the additional
benefit that these checks are performed during a <C -c> compilation.

=head1 SEE ALSO

This module relies upon these modules:

=over

=item MRP::Interface

=item MRP::Text

=item MRP::Introspection

=back

=head1 A skeletal derived class

 package myDerived;

 use strict;                   # I'm paranoid about this...
 use vars qw ( @ISA %fields );

 use MRP::BaseClass;

 BEGIN {                       # Putting this code in BEGIN makes
                               # errors show up at compile time.
    # our parent class - in this case only MRP::BaseClass.
    @ISA = ('MRP::BaseClass');
    # the object model - member names and initial values
    %fields = (
	       'number' => 1,
	       'hash' => undef,
               'array' => undef,
	       );
    # check4Clashes ensures that you are not overriding base class
    # member variables and creates the member access functions.
    myDerived->check4Clashes();
 }

 # Our constructor - this one is very simple.
 sub new {
    my $class = shift;              # we need to know what type we are.
    my $self = new MRP::BaseClass;  # get an object from the emediate parent
    
    $self->rebless ($class);        # re-bless the object into this package
                                    # this is when MRP::BaseClass sets up
                                    # member variables
    return $self;                   # return the object.
 }

 # This function is called during re-blessing. Here we are just going
 # to set the member 'hash' to a new hash reference.
 # At this point $self is blessed into this package, and contains
 # all of its members. You could call member funcitons from here if
 # you realy wanted to.
 sub initialize {
    my $self = shift;
    $self->hash({});
    $self->array([]);
 }

You can now use this class as follows:

 $thing = new myDerived();          # get a new myDerived object
 $thing->hash->{'red'} = 1;         # set the key red in hash to 1
 $thing->number(5);                 # set the value of number to 5
 $thing->array->[0] = "goo";        # set the first element of array to 'goo'
 $thing->array->('a','b');          # this is not what you meant. The
                                    # array ref will be replaced with 'a' and
                                    # the rest of the parameters will be lost.
 @{$thing->array} = ('a','b');      # this is better.
 $thing->array([('a','b')]);        # replace the refrerence with a new one
                                    # containing the array ('a','b')

 print "I have the number ", $thing->number, " in me\n";

A class derived from myDerived would just substitute the name
myDerived for MRP::BaseClass.  Hey presto - all sorted!

The return value of the member access functons is the value of the
member. If a value is given to the member access function then the
member is set to that value, and it's new value is returned. Thus:

 $val = $thing->hash;     # puts the same reference in $val that was in hash
 $thing->hash(\%myHash);  # sets the hash reference used to\%myHash

=head1 Using clever fields

MRP::BaseClass is clever enough to create hash and array members and
specialised access functions, as well as methods that check the
interface of methods. Include a fields like this...

    %fields = (
	       myHashMember => {},
	       myArrayMember => [],
               myDelegate => MRP::Interface->ActionDelegate,
	       );

and MRP::BaseClass will do the following:

=over

=item *

During rebless, a new hash or array ref will be put into these
members.  You do not need to add these parts in initialize()

=item *

During member access generation, member access functions will be
generated that understand that these members are hashes or arrays.

=item *

A member access function named B<field_ref> gives you access to the
actual member variable.

=item *

When you set $obj->myDelegate, it checks that the new object
implements the interface ActionDelegate.

=back

So, reworking the original example,

    %fields = (
	       'number' => 1,
	       'hash' => {},   # put an empty hash here
               'array' => [],  # and an empty array here
	       );

The initialize subroutine can be discarded - you don't need to set
anything up now. The rest of the code is unchanged. You can access the
members as follows:

 $thing = new myDerived;          # get an object as before
 $thing->number(50);              # access to scalars doesn't change
 $thing->hash('foo'=>1,'bar'=>2); # sets hash to the value passed.
 $ref = $thing->hash;             # returns the reference used
 $val = $thing->hash->{'foo'};    # return 1
 %hash = $thing->hash;            # sets the contence of %hash equal to hash
 $thing->array(@list);            # sets the value of array to @list
 @list = $thing->array();         # sets the value of @list to array
 $array = $thing->array;          # sets $array to the same reference as array
 $val = $thing->array->[3];       # sets $val equal to the 3rd element of array
 $thing->array(\@array);          # sets array to a one member list containing
                                  # \@array. array and @array still point to
                                  # different objects
 $thing->array_ref(\@anarray);    # set array to the reference of @anarray. They
                                  # now refer to the same object.
 $thing->hash_ref(\%ahash);       # likewise, hash now refers to ahash.

=head1 Package variables

MRP::BaseClass will also generate access functions for package
variables. You must list the ones that you want to expose in the
@public_vars array. When check4Clashes is invoked, it will generate
access functions for each of the values in this array. For example,

 package myDerived;
 use strict;
 use vars qw(@ISA @public_vars $scalar %hash @array);
 use MRP::BaseClass;

 @ISA = qw(MRP::BaseClass);
 @public_vars = qw($scalar %hash @array);
 myDerived->check4Clashes();

 ...

 $s = myDerived->scalar;      # set $s to $myDerived::scalar
 myDerived->hash(%newValue);  # set %myDerived::hash to %newValue
 @list = myDerived->array;    # set @list to @myDerived::array

The benefit of this is that in any package derived from myDerived, you
can still access these variables. This makes package variable access
follow all the same rules as member variables do for inheritance. One
freebie is that you can access these package variables via an
object. So, if $error is a global scalar then $obj->error would access
the global value of error for you. In this way, global variables are
made to work like static class members.

=head1 Package variables and fields with the same name

There will be cases when the same variable is used for a package
variable and field name. If you include the variable both in fields
and in public_vars, then the access function will decide which value
to return based upon whether it was invoked as a class or objet
method.

 package myDerived;
 use strict;
 use vars qw(@ISA @public_vars %fields $error $linewidth);
 use MRP::BaseClass;

 @ISA = qw(MRP::BaseClass);
 %fields = { $error=>undef, };
 @public_vars = qw($error);
 myDerived->check4Clashes();

 ...

 $t = new myDerived;   # get a new object
 $t->error;            # returns the error field of object $t
 myDerived->error;     # returns the error associated with the package

=head1 Default variables

These are specified in the @defaults array. They do not need to be
listed in either fields or public_vars. A field and a package variable
will be generate, with the field providing the object-specific value
and the package variable provides the default value. This is returned
when you query an object for it, and the object value is undef. So -
to illustrate with the linewidth field:

 package myDerived;
 use strict;
 use vars qw(@ISA @defaults $linewidth);
 use MRP::BaseClass;

 @ISA = qw(MRP::BaseClass);
 @defaults = qw($linewidth);
 myDerived->check4Clashes();
 
 ...

 $t = new myDerived;        # make a new myDerived object
 $t->linewidth(72);         # set linewidth to 72 for this object
 myDerived->linewidth(70);  # set the defuault value to 70
 print $t->linewidth, "\n"; # will print '72'
 $t->linewidth(undef);      # make sure that linewidth is undef
 print $t->linewidth, "\n"; # will now print '70' - the default value

=head1 Delegation support

Very often, an object will contain a reference to another object that
it uses to implement part of its public interface. Usualy this is
achieved by just forwarding the function calls
directly. MRP::BaseClass will generate these functions automaticaly
from the %delegates hash.

  package myComposite;
  use strict;
  use MRP::BaseClass;

  use vars qw(%fields %delegates @ISA);

  BEGIN {
    @ISA = qw(MRP::BaseClass);
    %delegates = (
                  stringMaker => [qw(toString toText)],
                 );
    myComopsite->check4Clashes();
  }

... insert new function and the rest of the functionality here...

The delegates hash contains field names as keys followed by an arrray
reference containing function names. Thus, code will be generated to
wire myComoposite->toString to myComposite>stringMaker->toString. The
arguments are forwarded, so that myComposite objects share a subset of
the interface of the stringMaker delegate.

I have invented a hypothetical class called StringMaker that can write
out text in different languages. I wish that I had one during school!
It can expand messages into a string with C<toText> and to formatted
text with C<toString>. It can also have its target set with
C<language>. I do not wish myComposite to have a language method, but
I do wish it to be able to write out text.

 $mc1 = new myComposite(); # get a composite object
 $mc2 = new myComposite(); # and another
 $mc1->stringMaker($sm1); # set stringMaker to $sm1
 $sm1->language('English UK'); # and set the stringMaker language to british.
 $mc2->stringMaker($sm2); # set this stringmaker as well
 $sm2->language(french); # and set the language to french

 print $mc1->toText('Apologise'); # an eloquant british apology
 print $mc2->toText('Apologise'); # a beautifull french apology

If you try to use a field as a delegate that appears in the
fields hash, then a fatal error message will be printed.

=head1 Delegation support with type checking

It is not possible to check that the methods are legal for the
delegate, as the type of the delegate is not known at compile
time. However, by giving an interface object rather than a function
name, the object can be validated when the delegate is set.

  %delegates = (stringMaker => [MRP::Interface->StringMaker];);

Now, any object put into the stringMaker field of this class must
implement the interfave StringMaker, or an exception will be thrown.

=head1 Enhanced <C -w> diagnostics

If you run your script with <C -w> invoked, then MRP::BaseClass gives you
some extra diagnostics that I have found to be very usefull. The first
line is of the form:

Can't access 'funcName' in [object/package] [objectName/packageName]:

This clearly describes which function could not be located, whether it
was invoked as an object or package function, and the object or
package.

There may follow a section where the program lists potential
corrections. Thus, a common mistake I make is to type check4clashes -
incorrect case. In response to this, it would sudgest that I use the
function MRP::BaseClass::check4Clashes. It lists both similar filed
and function names.

The next line says where the error occured, in the form C<in
temp/testMutipleInheritance.pl at line 40>.

It then dumps the model for the object. This consists of its fields
and their values, all methods that can be directly accessed via
inheritance, and all package variables. The function list does not
include functions in baseclasses that are overridden in derived
classes, and it doesn't include functions starting with a leading
underscore.

Following this, a complete stack trace is displayed.

=head1 Functions

=over

=item new

Returns a new MRP::BaseClass object. This can then be reblessed into
your package.

=item rebless

Converts a base class into your class!  Call as $self->rebless($class)
where $self is a base class object.  It returns $self, blessed, with
the correct member variables. It is at this time that initialize, if
present, is invoked. This functon should be used in every constructor
that has to bless an object from a base class that is derived from
MRP::BaseClass into the current package. If you employ multiple
inheritance of field members, then use $class->rebless($parent1,
$parent2...). This is clever enough to combine the data members from
multiple parents. Therefore, it implements multiple inheritance by
combining all fields within a single namespace, rather than the c++
approach of each class having its own namespace within the
object. This should work fine for most things.

=item initialize

Override this in each derived class to provide class specific
initialization. For example, initialize may put arrays into member
variables that need them. MRP::BaseClass will not complain if you do
not provied an initialize function. It will assume that it is not
needed.

=item clone

Returns a new object that is a clone of this one. Currently it copies
scalars and references and then blesses the new object into the same
class as the cloned object.  This is a shallow copy by default. Invoke
it will a true argument and it will do a deep copy, calling C<clone>
for all objects it can. If you invoke clone with C<shallow> then you
force a shallow copy. Override this in a base class if this is not the
behavure you want. For example, my MRP::Document objects return
themselves when you call clone, so that only one object exists for
each directory being documented.

=item _PrintMembers

This function is provided for debugging.  It returns a string
representaion of your object model, including members, methods and
package variables.

=item check4Clashes

Call this function after you have defined your classes interface. It
does the following:

=over

=item *

Checks the C<%fields> of all classes in @ISA to ensure that you
are not redefining members

=item *

Checks the interface of all classes in @ISA to ensure that you have no
ambiguously inherited function calls that are not disambiguated in the
current class.

=item *

Generates code to support member variables and static variables via
access functions.

=item *

Generates code to support simple delegation models where function
arguments are forwarded unchanged.

=back

The template for the automaticaly generated code can be over-ridden in
any subclass to give more precise functionality. For example, in
MRP::Matrix, the delegation funciton is replaced with one that
systematicaly modifies the argumet list. This is a painless operation
under this system.

=back

=head1 package::memberAccess

When the class is created, MRP::BaseClass creates a package called
class::memberAccess. This package contains the member access
functions. MRP::BaseClass then makes class::memberAccess the first
parent in @class::ISA. Thus, you can do things like this:

    package myPath;
    ...
    %fields = (path => []);
    myPath->check4Clashes();
    ...
    sub path {
	my $self = shift;
	my @path = $self->SUPER::path;
	return join "/", @path;
    }

Because the member access functions are in a seperate package, you can
still create functions of the same name in your package without
'loosing' the member access. Cool!

=head1 Other usefull functions

These functons are very usefull, but are more aprpreate to packages
than members. They all work regardless of whether invoked as a class
or object method.

=over

=item Class variables

=over

=item _ISA

In a scalar context, this function returns a reference to the ISA
array for the package. In an array context it returns the contence of
ISA for the package.

=item _fields

In a scalar context, this function returns a reference to the fields
hash for the package. In an array context it returns the contence of
fields for the package as a list of key/value pairs.

=back

=item Text Formatting

=over

=item _pretyArray

This function takes either an array or a reference to an array. It
returns a string representation of the array.

=item _pretyHash

This function takes a leader string followed by either a hash or a
reference to a hash. The leader sequene is prepended to each line of
text. The function returns a single string representing the hash
contence.

=back

=back

=head1 Inheriting from an MRP::BaseClass-derived object

This is as simple as extending MRP::BaseClass. Optionaly define
%fields, @public_vars and @defaults, write an initialize function, and
then call check4Clashes. Then in the new function, get an object for
the imediate base class and call rebless for it.

 package myBox;

 use strict;
 use vars qw(@INC, %fields, @defaults);
 use myGraphable;

 BEGIN {
   @ISA = qw(myGraphable);
   %fields = (
     'x'=>undef, 'y'=>undef, 'w'=>undef, 'h'=>undef
   );
   @defaults = qw($color);
   myBox->check4clashes();
 }

 sub new {
   my $class = shift;
   my $self = new myGraphable;
   $self->rebless($class);
   return $self;
 }

 ... everything else goes here ...

=head1 Multiple inheritance

Much of the strife of multiple inheritance is taken care of for
you. Simply use the multi-argument form of rebless to create the new
object.

 package multiple;
 use myGlyph;
 use myPersistant;

 @ISA = qw(myGlyph myPersistant);

 sub new {
   my $class = shift;
   my $glyph = new myGlyph;
   my $persistant = new myPersistant;
   my $self = multiple->rebless($glyph,$persistant);
   return $self;
 }

... everything else here ...

Of course, you could include %fields, @public_vars and @defaults to
give this package extra behaviour, and you may wish to define
initialize.

=head1 Multiple inheritance involving non-MRP::BaseClass parents

check4Clashes stops searching a root of an inheritance hierachy when
it can find no baseclasses that support _containsFields. This section
describes how to implement _containsFields so that you can add your
classes into this framework if you wish to. The premice is that you
will only allow people to access member variables outside of the
package through access functions, and that your stoorage method
doesn't clash with mine.

_containsFields is responsible for comparing a classes fields with the
set in the calling package. The MRP::BaseClass implimentation will
work for cases where all of the classes that contribute fields are
derived from MRP::BaseClass, and relies on my use of the %fields hash.

_containsFields assumes that the first argument is the package that it
is being called in.  The following arguments are taken to be a list of
fields which to check are not found in members of the current package.

It should return either C<undef> or a reference to an array of name
clashes in the format C<package::variable>. These clashes should be
the combination of classes with this package and with all of the base
classes.

So it would look something like
  _containsFields {
    my $class = shift;
    my @toCheck = @_;

    foreach @toCheck {
	check that they are not in me. 
	  If they are, add them to the list of clashes to return.
    }

    add all base class clashes to your list of clashes

    if there were name clashes return a reference to them

    otherwise return undef
  }

It is as simple as that. Currently, member variables are contained as
keys within the $self hash reference. I provide access functions for
all of the keys mentioned by name in %package::fields when
check4Clashes is called. If anybody adds keys afterwards, member
access functions are not generated for them. I can not be bothered to
create a public:protected:private system. In the pod I just don't
document private stuff.

=head1 Modifying the code generated for variable access and delegation support

Here are the parameters that are passed into the code-generating functions.

=over

=item thingy

The class (possibly an object?) that the function is being generated
for. You can use this to access other functions.

=item memberPackage

The package that the function must be compiled into. Normaly you would
include C<package $memberPacage> as the first line of the text.

=item delegate

The name of the field that is acting as a delegate

=item interface

An MRP::Interface object - the generated code must ensure that objects
implement the correct interface before setting the field.

=item functions

The name of the function that the delegate is providing

=over

=item name

The name that you must give the function

=item item

The name of the field that this function must provide access to.

=back

Here are the funcitons themselves.

=over

=item _delegateFunc($thingy, $memberPackage, $delegate, $function)

=item _delegateAccess($thingy, $memberPackage, $item, $interface, $interface.....)

=item _fieldScalarFunc($thingy, $memberPackage, $name, $interface, $item)

=item _packageScalarFunc($thingy, $memberPackage, $name, $item)

=item _fieldArrayFunc($thingy, $memberPackage, $name, $item)

=item _packageArrayFunc($thingy, $memberPackage, $name, $item)

=item _fieldHashFunc($thingy, $memberPackage, $name, $item)

=item _packageHashFunc($thingy, $memberPackage, $name, $item)

=item _packageAndField($thingy,$memberPackage,$item,$fieldFunc,$packageFunc)

Handles the case when you have a static variable and a field of the
same name

=item _defaultField($thingy,$memberPackage,$item,$fieldFunc,$packageFunc)

Handles the case when you have a static variable that provides the
default value for a field

=back

=head1 AUTHOR

Matthew Pocock mrp@sanger.ac.uk
