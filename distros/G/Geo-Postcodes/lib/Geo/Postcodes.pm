package Geo::Postcodes;

#################################################################################
#                                                                               #
#           This file is written by Arne Sommer - perl@bbop.org                 #
#                                                                               #
#################################################################################

use strict;
use warnings;

our $VERSION = '0.32';

## Which methods are available ##################################################

my @valid_fields = qw(postcode location borough county type type_verbose owner
                       address);  # Used by the 'get_fields' procedure.

my %valid_fields;

foreach (@valid_fields)
{
  $valid_fields{$_} = 1; # Used by 'is_field' for easy lookup.
}

## Type Description #############################################################

my %typedesc;

$typedesc{BX}   = "Post Office box";
$typedesc{ST}   = "Street address";
$typedesc{SX}   = "Service box";
$typedesc{IO}   = "Individual owner";
$typedesc{STBX} = "Street Address and Post Office box";
$typedesc{MU}   = "Multiple usage";
$typedesc{PP}   = "Porto Paye receiver";

$typedesc{PN}   = "Place name";

## OO Methods ###################################################################

our %postcode_of;
our %location_of;
our %borough_of;
our %county_of;
our %type_of;
our %owner_of;
our %address_of;

sub new
{
  my $class      = shift;
  my $postcode   = shift;
  my $self       = shift; # Allow for subclassing.

  return unless valid($postcode);

  unless ($self)
  {
    $self = bless \(my $dummy), $class;
  }

  $postcode_of {$self} =              $postcode;
  $location_of {$self} = location_of ($postcode);
  $borough_of  {$self} = borough_of  ($postcode);
  $county_of   {$self} = county_of   ($postcode);
  $type_of     {$self} = type_of     ($postcode);
  $owner_of    {$self} = owner_of    ($postcode);
  $address_of  {$self} = address_of  ($postcode);
  return $self;
}

sub DESTROY
{
  my $object_id = $_[0];

  delete $postcode_of {$object_id};
  delete $location_of {$object_id};
  delete $borough_of  {$object_id};
  delete $county_of   {$object_id};
  delete $type_of     {$object_id};
  delete $owner_of    {$object_id};
  delete $address_of  {$object_id};
}

sub postcode
{
  my $self = shift;
  return unless defined $self;
  return $postcode_of{$self} if exists $postcode_of{$self};
  return;
}

sub location
{
  my $self = shift;
  return unless defined $self;
  return $location_of{$self} if exists $location_of{$self};
  return;
}

sub borough
{
  my $self = shift;
  return unless defined $self;
  return $borough_of{$self} if exists $borough_of{$self};
  return;
}

sub county
{
  my $self = shift;
  return unless defined $self;
  return $county_of{$self} if exists $county_of{$self};
  return;
}

sub type
{
  my $self = shift;
  return unless defined $self;
  return $type_of{$self} if exists $type_of{$self};
  return;
}

sub type_verbose
{
  my $self = shift;
  return unless defined $self;
  return unless exists $type_of{$self};
  return unless exists $typedesc{$type_of{$self}};
  return $typedesc{$type_of{$self}};
}

sub owner
{
  my $self = shift;
  return unless defined $self;
  return $owner_of{$self} if exists $owner_of{$self};
  return;
}

sub address
{
  my $self = shift;
  return unless defined $self;
  return $address_of{$self} if exists $address_of{$self};
  return;
}

#################################################################################

sub get_postcodes      ## Return all the postcodes, unsorted.
{
  return;
}

sub get_fields         ## Get a list of legal fields for the class/object.
{
  return @valid_fields;
}

sub is_field           ## Is the specified field legal? Can be called as
{                      ## a procedure, or as a method.
  my $field = shift;
  $field    = shift if $field =~ /Geo::Postcodes/; # Called on an object.

  return 1 if $valid_fields{$field};
  return 0;
}

## Global Procedures  - Stub Version, Override in your subclass #################

sub legal # Is it a legal code, i.e. something that follows the syntax rule.
{
  return 0;
}

sub valid # Is the code in actual use.
{
  return 0;
}

sub postcode_of
{
  return;
}

sub location_of
{
  return;
}

sub borough_of
{
  return;
}

sub county_of
{
  return;
}

sub type_of
{
  return;
}

sub type_verbose_of
{
  return;
}

sub owner_of
{
  return;
}

sub address_of
{
  return;
}

sub get_types
{
  return keys %typedesc;
}

sub type2verbose
{
  my $type = shift;
  return unless $type;
  return unless exists $typedesc{$type};
  return $typedesc{$type};
}

my %legal_mode;
   $legal_mode{'and'}  = $legal_mode{'and not'}  = 1;
   $legal_mode{'nand'} = $legal_mode{'nand not'} = 1;
   $legal_mode{'nor'}  = $legal_mode{'nor not'}  = 1;
   $legal_mode{'or'}   = $legal_mode{'or not'}   = 1;
   $legal_mode{'xnor'} = $legal_mode{'xnor not'} = 1;
   $legal_mode{'xor'}  = $legal_mode{'xor not'}  = 1;

my %legal_initial_mode;
   $legal_initial_mode{'all'} = $legal_initial_mode{'none'} = 1;
   $legal_initial_mode{'not'} = $legal_initial_mode{'one'}  = 1;

sub is_legal_selectionmode
{
  my $mode = shift;
  return 1 if $legal_mode{$mode};
  return 0;
}

sub is_legal_initial_selectionmode
{
  my $mode = shift;
  return 1 if $legal_initial_mode{$mode} or $legal_mode{$mode};
  return 0;
}

sub get_selectionmodes
{
  return sort keys %legal_mode;
}

sub get_initial_selectionmodes
{
  return sort (keys %legal_mode, keys %legal_initial_mode);
}

sub verify_selectionlist
{
  return Geo::Postcodes::_verify_selectionlist('Geo::Postcodes', @_);
    # Black magic.
}

sub _verify_selectionlist
{
  my $caller_class = shift;
  my @args         = @_;    # A list of selection arguments to verify

  my $status       = 1;     # Return value
  my @out          = ();
  my @verbose      = ();

  return (0, "No arguments") unless @args;

  if (is_legal_initial_selectionmode($args[0]))
  {
    my $mode = shift @args;

    if (@args and $args[0] eq "not" and is_legal_initial_selectionmode("$mode $args[0]"))
    {
      $mode = "$mode $args[0]";
      shift @args;
    }

    push @out, $mode;
    push @verbose, "Mode: '$mode' - ok";

    return (1, @out) if $mode eq "all" or $mode eq "none";
    return (1, @out) if $mode eq "one" and @args == 0;
      # This one can both be used alone, or followed by more.

    return (0, @verbose, "Missing method/value pair - not ok") unless @args >= 2;
        # Missing method/value pair.
  }

  ## Done with the first one

  while (@args)
  {
    my $argument = shift(@args);

    if ($caller_class->is_field($argument))
    {
      push @out, $argument;
      push @verbose, "Field: '$argument' - ok";

      if (@args)
      {
        $argument = shift(@args);
        push @out, $argument;
        push @verbose, "String: '$argument' - ok";
      }
      else
      {
        push @verbose, "Missing string - not ok"; # The last element was a method.
        $status = 0;
        @args = (); # Terminate the loop
      }          
    }
    elsif (is_legal_selectionmode($argument))
    {
      if (@args and $args[0] eq "not" and is_legal_selectionmode("$argument $args[0]"))
      {
        $argument = "$argument $args[0]";
        shift @args;
      }
      push @out, $argument;
      push @verbose, "Mode: '$argument' - ok";

      unless (@args >= 2) # Missing method/value pair
      {
        push @verbose, "Missing method/value pair - not ok";
        $status = 0;
        @args = (); # Terminate the loop
      }
    }
    elsif ($argument eq 'procedure')
    {
      push @out, $argument;
      push @verbose, "Field: 'procedure' - ok";

      my $procedure = shift(@args);
      if (ref $procedure eq "CODE")
      {
        if (_valid_procedure_pointer($procedure))
        {
          push @out, $procedure;
          push @verbose, "Procedure pointer: '$procedure' - ok";
        }
        else
        {
          push @verbose, "No such procedure: '$procedure' - not ok";
          $status = 0;
          @args   = (); # Terminate the loop
        }
      }
      else
      {
        push @verbose, "Not a procedure pointer: '$procedure' - not ok";
        $status = 0;
        @args   = (); # Terminate the loop
      }
    }
    else
    {
      push @verbose, "Illegal argument: '$argument' - not ok";
      $status = 0;
      @args   = (); # Terminate the loop
    }
  }

  return (1, @out) if $status; # Return a modified argument list on success.

  return (0, @verbose);        # Return a list of diagnostic meddages on failure.
}

sub selection_loop
{
  return Geo::Postcodes::_selection_loop('Geo::Postcodes', @_);
    # Black magic.
}

sub _selection_loop
{
  my $caller_class      = shift;

  my $objects_requested = 0; # Not object oriented.

  if ($_[0] eq $caller_class)
  {
    $objects_requested  = 1;
    shift;
  }

  my $procedure_pointer = shift;

  return 0 unless $procedure_pointer;

  my @selection_clauses = @_;
  my @postcodes         = _selection($caller_class, @selection_clauses);

  return 0 unless @postcodes;

  foreach (@postcodes)
  {
    &$procedure_pointer($objects_requested ? $caller_class->new($_) : $_);
  } 
  return 1;
}


#################################################################################
#                                                                               #
#  Returns a list of postcodes if called as a procedure;                        #
#    Geo::Postcodes::XX::selection(...)                                         #
#  Returns a list of objects if called as a method;                             #
#    Geo::Postcodes::XX->selection(...)                                         #
#                                                                               #
# Note that 'or' and 'not' are not written efficient, as they recompile the     #
# regular expression(s) for every postcode.                                     #
#                                                                               #
#################################################################################

sub selection
{
  return Geo::Postcodes::_selection('Geo::Postcodes', @_);
    # Black magic.
}

sub _selection
{
  my $caller_class      = shift;

  my $objects_requested = 0; # Not object oriented.

  if ($_[0] eq $caller_class)
  {
    $objects_requested  = 1;
    shift;
  }

  if ($_[0] eq 'all')
  {
    my @all = sort &{&_proc_pointer($caller_class . '::get_postcodes')}();
      # Get all the postcodes.

    return @all unless $objects_requested;

    my @out_objects;

    foreach my $postcode (@all)
    {
      push(@out_objects, $caller_class->new($postcode));
    }

    return @out_objects;    
  }

  elsif ($_[0] eq 'none')
  {
    return; # Absolutely nothing.
  }

  my $limit = 0; # Set to one if we have requested only one postcode.
  if ($_[0] eq "one")
  {
    $limit = 1;
    shift; # Get rid of the mode.
  } 

  my $mode = "and"; 
    # The mode defaults to 'and' unless specified.

  my %out = ();

  ## The first set of method/value ##############################################

  my @all = &{&_proc_pointer($caller_class . '::get_postcodes')}();
    # Get all the postcodes.

  my($field, $current_field, $value, $current_value);

  if (@_) # As 'one' can be without additional arguments.
  {
    if (is_legal_initial_selectionmode($_[0]))
    {
      if ($_[1] eq "not" and is_legal_initial_selectionmode("$_[0] $_[1]"))
      {
        $mode = shift; $mode .= " "; $mode .= shift;
      }
      else
      {
        $mode = shift if is_legal_initial_selectionmode($_[0]);
      }
    }

    $field = shift;

    if ($field eq 'procedure')
    {
      my $procedure = shift; 
      return unless _valid_procedure_pointer($procedure);

      my $match;

      foreach my $postcode (@all)
      {
        eval { $match = $procedure->($_); };
        return if $@; # Return if the procedure was uncallable.

        if ($mode =~ /not/) { $out{$postcode}++ unless $match; }
        else                { $out{$postcode}++ if     $match; }
      }
    }
    else
    {
      return unless &{&_proc_pointer($caller_class . '::is_field')}($field);
        # Return if the specified method is undefined for the class.
        # As and 'and' with a list with one undefined item gives an empty list.

      my $current_field = &_proc_pointer($caller_class . '::' . $field .'_of');

      $value  = shift; $value =~ s/%/\.\*/g;
      return unless $value;
        # A validity check is impossible, so this is the next best thing.

      foreach my $postcode (@all)
      {
        $current_value = $current_field->($postcode);
          # Call the procedure with the current postcode as argument

        next unless $current_value;
          # Skip postcodes without this field.

        my $match = $current_value =~ m{^$value$}i; ## Case insensitive

        if ($mode =~ /not/) { $out{$postcode}++ unless $match; }
        else                { $out{$postcode}++ if     $match; }
      }
    }

    $mode = 'and' if $mode eq 'not';
  }

  elsif ($limit) # just one argument; 'one'.
  {
    map { $out{$_} = 1 } @all
  }

  while (@_)
  {
    if (is_legal_selectionmode($_[0]))
    {
      if ($_[1] eq "not" and is_legal_selectionmode("$_[0] $_[1]"))
      {
        $mode = shift; $mode .= " "; $mode .= shift;
      }
      else
      {
        $mode = shift if is_legal_selectionmode($_[0]);
      }
    }

    # Use the one already on hand, if none is given.

    my $is_procedure = 0;
    my $procedure;

    $field = shift;

    if ($field eq 'procedure')
    {
      $is_procedure = 1;
      $procedure = shift; 
      return unless _valid_procedure_pointer($procedure);
    }
    else
    {
      return unless &{&_proc_pointer($caller_class . '::is_field')}($field);
        # Return if the specified method is undefined for the class.
        # As an 'and' with a list with one undefined item gives an empty list.

      $current_field = &_proc_pointer($caller_class . '::' . $field .'_of');

      $value = shift; 
      $value =~ s/%/\.\*/g;
      return unless $value;
        # A validity check is impossible, so this is the next best thing.
    }

    foreach my $postcode ($mode =~ /and/ ? (keys %out) : @all)
    {
      # We start with the result from the previous iteration if the mode
      # is one of the 'and'-family. Otherwise it is one of the 'or'-family,
      # and we have to start from scratch (@all).

      my $match;

      if ($procedure)
      {
        eval { $match = $procedure->($postcode); };
        return if $@; # Return if the procedure was uncallable.
      }
      else
      {
        $current_value = $current_field->($postcode);
          # Call the procedure with the current postcode as argument

        next unless $current_value;
          # Skip postcodes without this field.

        $match = $current_value =~ m{^$value$}i; ## Case insensitive
      }

      if    ($mode eq "and")
      {
        delete $out{$postcode} unless $match;
      }
      elsif ($mode eq "and not")
      {
        delete $out{$postcode} if     $match;
      }

      elsif ($mode eq "nand")
      {
        if ($match and $out{$postcode})   { delete $out{$postcode} if $out{$postcode}; }
        else                              { $out{$postcode}++;                         }
      }
      elsif ($mode eq "nand not")
      {
        if (!$match and $out{$postcode})  { delete $out{$postcode} if $out{$postcode}; }
        else                              { $out{$postcode}++;                         }
      }

      elsif ($mode eq "or")
      {
        $out{$postcode}++      if     $match;
      }
      elsif ($mode eq "or not")
      { 
        $out{$postcode}++      unless $match;
      }
      elsif ($mode eq "nor")
      {
        if (!$match and !$out{$postcode}) { $out{$postcode}++;                         }
        else                              { delete $out{$postcode} if $out{$postcode}; }
      }
      elsif ($mode eq "nor not")
      {
        if ($match and !$out{$postcode})  { $out{$postcode}++;                         }
        else                              { delete $out{$postcode} if $out{$postcode}; }
      }
      elsif ($mode eq "xor")
      {
        if ($match)
        {
          if ($out{$postcode}) { delete $out{$postcode}; }
          else                 { $out{$postcode}++;      }
        }
      }
      elsif ($mode eq "xor not")
      {
        unless ($match)
        {
           if ($out{$postcode}) { delete $out{$postcode}; }
           else                 { $out{$postcode}++;      }
        }
      }

      elsif ($mode eq "xnor")
      {
        my $boolean = $out{$postcode} ? 1 : 0;
        if ($match == $boolean)
        {
          $out{$postcode}++;
        }
        else
        {
          delete $out{$postcode} if $out{$postcode};
        }
      }
      elsif ($mode eq "xnor not")
      {
        my $boolean = $out{$postcode} ? 1 : 0;
        if ($match != $boolean)
        {
          $out{$postcode}++;
        }
        else
        {
          delete $out{$postcode} if $out{$postcode};
        }
      }
    }
  }

  ###############################################################################

  return unless %out;
    # Return nothing if we have an empty list (or rather, hash).

  my @out;

  if ($limit)                   # The caller has requested just one postcode,   #
  {                             #  and will get exactly that if any matches     #
    my @list = keys %out;       #  were found. The returned postcode is chosen  #
    @out = $list[rand(@list)];  #  by random.                                   #
  }
  else
  {
    @out = sort keys %out;
      # This will give an ordered list, as opposed to a semi random order. This #
      # is essential when comparing lists of postcodes, as the test scripts do. #
  }

  ###############################################################################

  return @out unless $objects_requested;

  my @out_objects;

  foreach my $postcode (@out)
  {
    push(@out_objects, $caller_class->new($postcode));
  }

  return @out_objects;
}


sub _proc_pointer
{
  my $procedure_name = shift;
  return \&{$procedure_name};
}

sub _valid_procedure_pointer
{
  my $ptr = shift;
  return 0 if ref $ptr ne "CODE";
  return 1 if defined(&$ptr);
  return 0;
}

1;
__END__

=head1 NAME

Geo::Postcodes - Base class for the Geo::Postcodes::* modules

=head1 SYNOPSIS

This module should not be used directly from application programs, but from a
country subclass; e.g.:

 package Geo::Postcodes::U2;

 use Geo::Postcodes 0.30;
 use base qw(Geo::Postcodes);

 use strict;
 use warnings;

 our $VERSION = '0.30';
 
And so on. See the documentation for making country subclasses for the gory
details; I<perldoc Geo::Postcodes::Subclass> or I<man Geo::Postcodes::Subclass>.

=head1 ABSTRACT

Geo::Postcodes - Base class for the Geo::Postcodes::* modules. It is
useless on its own.

=head1 PROCEDURES AND METHODS

These procedures and methods should, with a few exceptions, not be used directly,
but from a country module. See the documentation for the indiviual country modules
for usage details.

=head2 address, borough, county, location, owner, postcode, type, type_verbose

Methods for accessing the fields of a postcode object. The individual country
modules can support as many of them as needed, and add new ones.

=head2 address_of, borough_of, county_of, location_of, owner_of, postcode_of,
       type_of, type_verbose_of

Procedures that returns the value of the corresponding field for the given postcode.
They will return I<undef> if the postcode does not exist, or the field is without
value for the given postcode.

=head2 get_fields, is_field

I<get_fields()> will return a list of all the fields supported by the module, and
I<is_field($field)> will return true (1) if the specified field is supported by 
the module.

=head2 legal, valid

Procedures that return I<true> if the postcode is legal (syntactically), or valid
(in actual use).

=head2 new

This will create a new postcode object.

=head2 selection, selection_loop

Procedures/methods for selecting several postcodes at once.

See the selection manual (I<perldoc Geo::Postcodes::Selection> or
I<man Geo::Postcodes::Selection>) for usage details, and the tutorial
(I<perldoc Geo::Postcodes::Tutorial> or I<man Geo::Postcodes::Tutorial>) 
for sample code.

=head2 verify_selectionlist, is_legal_selectionmode, is_legal_initial_selectionmode
       get_selectionmodes, get_initial_selectionmodes

Supporting procedures when using I<selection> or I<selection_loop>.

See the selection manual; I<perldoc Geo::Postcodes::Selection> or
I<man Geo::Postcodes::Selection> for usage details.

=head2 get_postcodes

This will return an unsorted list of all the postcodes.

=head2 get_types

This will return a list of types.  See the next section.

=head2 type2verbose

  my $type_as_english_text  = $Geo::Postcodes::type2verbose($type);
  my $type_as_national_text = $Geo::Postcodes::U2:type2verbose($type);

This procedure gives an english description of the type. Use the child class
directly for a description in the native language.

=head1 TYPE

This class defines the following types for the postal locations:

=over

=item BX

Post Office box

=item ST

Street address

=item SX

Service box (as a Post Office box, but the mail is delivered to
the customer).

=item IO

Individual owner (a company with its own postcode).

=item STBX

Either a Street address (ST) or a Post Office box (BX)

=item MU

Multiple usage (a mix of the other types)

=item PP

Porto Paye receiver (mail where the reicever will pay the postage).

=item PN

Place name

=back

The child classes can use them all, or only a subset, but must not define
their own additions. The child classes are responsible for adding descriptions
in the native language, if appropriate.

=head1 DESCRIPTION

This is the base class for the Geo::Postcodes::* modules.

=head1 CAVEAT

This module uses I<inside out objects>, see for instance
L<http://www.stonehenge.com/merlyn/UnixReview/col63.html> for a discussion of
the concept.

=head1 SEE ALSO

See also the selection manual (I<perldoc Geo::Postcodes::Selection> or
I<man Geo::Postcodes::Selection>) for usage details, the tutorial
(I<perldoc Geo::Postcodes::Tutorial> or I<man Geo::Postcodes::Tutorial>) 
for sample code, and the ajax tutorial (I<perldoc Geo::Postcodes::Ajax> or
I<man Geo::Postcodes::Ajax>) for information on using the modules in
combination with ajax code in a html form to get the location updated
automatically.

The latest version of this library should always be available on CPAN, but see
also the library home page; F<http://bbop.org/perl/GeoPostcodes> for additional
information and sample usage. The child classes that can be found there have
some sample programs.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2006 by Arne Sommer - perl@bbop.org

This library is free software; you can redistribute them and/or modify
it under the same terms as Perl itself.

=cut
