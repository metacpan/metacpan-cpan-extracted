package MRP::Introspection;

use strict;
use Exporter;

use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $VERSION);

$VERSION = 1.0;

@EXPORT_OK = qw (functions function functionsMatching
		 scalars   scalar
		 arrays    array
		 hashes    hash
		 recursiveFunction recursiveInheritance ISA);
%EXPORT_TAGS = ( ALL => [@EXPORT_OK] );

@ISA = qw (Exporter);

sub symTable ( $ ) {
  my ($package) = shift;
  $package = (ref $package || $package) . '::';
  no strict 'refs';
  return \%$package;
}
   
sub ISA ( $ ) {
  my $thingy = shift;
  my $isa = array($thingy, 'ISA', @_);
  return () unless defined $isa;
    (wantarray) ?
      (defined $isa) ? return @$isa : return () :
	return $isa;
}

sub functions( $ ) {
  my $thingy = shift;
  my %funcs;
  my ($name, $glob);

  while(($name, $glob) = each %{symTable $thingy}) {
    defined (*$glob{CODE}) && do { $funcs{$name} = \&$glob };
  }

  return %funcs;
}

sub functionsMatching( $$ ) {
  my ($thingy,$pattern)=@_;
  my %funcs;
  my ($name, $glob);

  while(($name, $glob) = each %{symTable $thingy}) {
    $name =~ /^$pattern$/ &&
      defined (*$glob{CODE}) && do { $funcs{$name} = \&$glob };
  }
  return %funcs;
}

sub scalars( $ ) {
  my $thingy = shift;
  my %scalars;
  my ($name, $glob);

  while(($name, $glob) = each %{symTable $thingy}) {
    defined ${*$glob{SCALAR}} && do { $scalars{$name} = \$$glob };
  }
  (wantarray) ? 
    return %scalars :
      return \%scalars;
}

sub arrays( $ ) {
  my $thingy = shift;
  my %arrays;
  my ($name, $glob);

  while(($name, $glob) = each %{symTable $thingy}) {
    defined (*$glob{ARRAY}) && do { $arrays{$name} = \@$glob };
  }
  (wantarray)
    ? return %arrays
      : return \%arrays;
}

sub hashes( $ ) {
  my $thingy = shift;
  my %hashes;
  my ($name, $glob);

  while(($name, $glob) = each %{symTable $thingy}) {
    $name =~ /::$/ && next; # don't return nested symbol tables
    defined (*$glob{HASH}) && do { $hashes{$name} = \%$glob };
  }
  (wantarray) ?
    return %hashes :
      return \%hashes;
}

no strict 'refs';

sub function($$;$) {
  my ($thingy,$sym,$val) = @_;
  my $fullName = join '::', ref $thingy || $thingy, $sym;
  *{$fullName} = $_[2] if(@_ == 3);
  return *{$fullName}{CODE};
}

sub scalar ( $$;$ ) {
  my ($thingy,$sym,$val) = @_;
  my $fullName = join '::', ref $thingy || $thingy, $sym;
  ${$fullName} = $_[2] if(@_ == 3);
  return *{$fullName}{SCALAR};
}

sub array ( $$;@ ) {
  my ($thingy,$sym) = (shift,shift);
  my $fullName = join '::', ref $thingy || $thingy, $sym;
  @{$fullName} = @_ if(@_ or not defined wantarray);
  my $ref = *{$fullName}{ARRAY};
  if($ref) {
    return (wantarray)
      ? @$ref
	: $ref;
  }
  return;
}

sub hash ( $$;@ ) {
  my ($thingy,$sym) = (shift,shift);
  my $fullName = join '::', ref $thingy || $thingy, $sym;
  %{$fullName} = @_ if(@_ or not defined wantarray);
  my $ref = *{$fullName}{HASH};
  return (wantarray)
    ? %$ref
      : $ref;
}

sub recursiveFunction ( $$;@ ) {
  my ($thingy,$function) = (shift,shift);
  my $package = ref $thingy || $thingy;
  my %functions = $thingy->$function(@_);
  my %return;
  my ($key,$val);
  my @ISA = $thingy->ISA;
  while(($key, $val) = each %functions) {
    $return{join '::',$package,$key} = $val;
  }
    
  %return = map { recursiveFunction $_, $function, @_ } @ISA;
  
  (wantarray) ?
    return %return :
      return \%return;
}

sub recursiveInheritance ( $$;@ ) {
  my ($thingy,$function) = (shift,shift);
  my $package = ref $thingy || $thingy;
  my %functions = $thingy->$function(@_);
  my %return;
  my ($key,$val);
  while(($key, $val) = each %functions) {
    $return{join '::',$package,$key} = $val;
  }

  foreach my $isa (ISA($thingy)) {
    my %parentFuncs = recursiveInheritance($isa, $function, @_);
    foreach my $name (keys %parentFuncs) {
      my ($fname) = $name =~ /([^:]+)$/;
      $return{$name} = $parentFuncs{$name} unless exists $functions{$fname};
    }
  }

  (wantarray) ?
    return %return :
      return \%return;
}

sub superAUTOLOAD ( $$@ ) {
  my ($thingy,$value) = (shift,shift);
  my ($func,$name);
  foreach(ISA($thingy)) {
    $func = _setAUTOLOAD($_,$value);
    return $func if $func;
  }
}

sub _setAUTOLOAD ( $$ ) {
  my ($thingy,$value) = (@_);
  my ($func);
  if($func = function($thingy,'AUTOLOAD')) {
    MRP::Introspection::scalar($thingy,'AUTOLOAD',$value);
    return $func;
  }

  foreach(ISA($thingy)) {
    $func = _setAUTOLOAD($_,$value) and last;
  }

  return $func;
}

$VERSION;

__END__

=head1 NAME

MRP::Introspection - powerful introspection

=head1 DESCRIPTION

Provides introspection support without you breaking strict.

=head1 SYNOPSIS

These functions perform introspection into a package to avoid you
having to tamper with the symbol table directly. They use MAJOR
wizardry to make sure that things behave just as you would expect. Use
with caution, particularly if you use them to alter variables.

=over

=item Package symbols

In a scalar context, these functions return a reference to a hash. In
a list context, they return a list of key/value pairs. The keys are
all of the items found in the symbol table of a given type. The values
are references to these items. Call using something like:

 $arrayHash = MRP::Interface->_arrays($obj);
 print "Got ISA ", $arrayHash->{ISA}, "\n";
 %arrayHash = MRP::Interface->_functions(MyPackage);
 print "Found ISA" if exists $arrayHash{'ISA'}

=over

=item _functions

=item _scalars

=item _arrays

=item _hashes

=back

=item Accessing individual symbol table elements

These functions all return either a reference to to the item within
the package or undef if it doesn't exist. For example,

 $func = MRP::Interface->_function($thingy, 'printme');

will put a reference to the function 'printme' in $func. If there is
no such function within the package that $thingy is blessed into (or
the package named by $thingy), then $func will be undef. These
functions do not deal with inheritance. They only look in a single
package.

=over

=item _function

=item _scalar

=item _array

=item _hash

=back

=item Other functions

=over

=item symTable

Returns a hash ref to the symbol table of a package (or the package
that an object is blessed into).

 $symTable = MRP::Introspection->symTable($obj);

=item ISA

Returns the @ISA array for a package or object. Returned as an array
or a reference to the actual ISA array depending on wantarray.

 $isaRef = MRP::Introspection->ISA($package);
 push @$isaRef, $newBaseClass;

=item functionsMatching

Returns all of the functions that match a given regex.

 $sets = MRP::Introspection($package, '^set.*$'); # all the functions in
                                     # package $package matching ^set.*$

=item recursiveFunction

MRP::Introspection->recursiveFunction($package, $funcRef);

Recursively applies a function throughout an objects inheritance
hierachy.  Returns a hash or hashref of all of the function return
values pre-catonated with the package name. You will have to just try
this one out.

=item recursiveInheritance

Same as recursiveFunction, but throws away results that could not be
reached because they are masked by inheritance. Again, just try it.

=item superAUTOLOAD

use:

  $autref = MRP::Interface->superAutoload($thisPackage, $AUTOLOAD);
  $autref->(@paramlist);

For those stickey moments when you have entered an AUTOLOAD method,
but it needs to allow some superclasses AUTOLOAD to do some
processing. The method sets $AUTOLOAD in the package that is first
reached by inheritance that has an AUTOLOAD method, and returns a
reference to that function. You just have to use the reference and
pass it the relevant arguments.

=back

=back

=head1 AUTHOR

Matthew Pocock mrp@sanger.ac.uk
