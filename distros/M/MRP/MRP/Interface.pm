package MRP::Interface;

use strict;
use Carp;

use MRP::Introspection;

use vars qw($AUTOLOAD %interfaces %implementers $VERSION);

$VERSION = 1.0;

sub AUTOLOAD {
  my ($name) = $AUTOLOAD =~ /([^:]+)$/;
  my $int = $interfaces{$name};
  $int or confess "Use of undefined interface: $name";
  return $int;
}

sub create {
  my $thingy = shift;
  my %interface = @_;

  my ($name, $definition);
  while (($name, $definition) = each %interface) {
    if(exists $interfaces{$name}) {
      confess "interface $name has already been defined\n";
    } else {
      my $description = $definition->{''}; delete $definition->{''};
      $interfaces{$name} = bless {name=>$name,
				  definition=>$definition,
				  implementors=>{},
				  description=>$description,
				 }, $thingy;
    }
  }
}

sub implementedBy {
  my ($interface,$thingy) = (shift,shift);
  if(my $package = ref($thingy)) {
    foreach (keys %{$interface->{implementors}}) {
      return 1 if $thingy->isa($_);
    }
    return;
  } else {
    return if(not $thingy);
    my @errors = map { $thingy->can($_)
			 ? () : "$_";
		     } keys %{$interface->{definition}};
    if(@errors) {
      confess
	"$thingy does not implement interface ",
	$interface->{name},
	". The following ", scalar(@errors), " functions must be defined:\n  ",
	  join("", map { $_."\n\t".$interface->{definition}->{$_}."\n" } @errors),
	"\n";
    }
    $interface->{implementors}->{$thingy} = 1;
  }
}

sub name {
  my $interface = shift;
  return $interface->{name};
}

sub functions {
  my $interface = shift;
  return keys %{$interface->{definition}};
}

sub DESTROY {}

$VERSION;

__END__

=head1 NAME

MRP::Interface - defines object interfaces

=head1 DESCRIPTION

Allows you to specify the interface that an object is expected to
implement without implying an inheritance hierachy.

=head1 SYNOPSIS

  MRP::Interface->create(Foo => {''=>'My realy usefull interface',  # interface description
				 action=>'performs an action',      # functions and their descriptions
				 reaction=>'responds to an action', # ...
				});

 MRP::Interface->Foo->implementedBy('Bar'); # register package Bar as implementing interface Foo
                                            # Package Bar must have functions 'action' and 'reaction'
                                            # or a fatal error is generated.
 $bar = new Bar;
 $hoot = new Hoot;

 MRP::Interface->Foo->implementedBy($bar);  # returns true as $bar does implement Foo
 MRP::Interface->Foo->implementedBy($hoot); # returns false as $hoot doen't implement Foo
 MRP::Interface->Gee->implementedBy($bar);  # fatal error if interface Gee is not defined


 $int = MRP::Interface->Foo;                # gets the interface object for 'Foo'
 print $int->name();                        # prints out 'Foo'
 %functions = %{$int->functions()};         # %functions now contains Foo's functions and descriptions

=head1 FUNCTIONS

=over

=item create

Creates a new interface. You can create any number of interfaces with
a single call. Treats the parameters as a hash, where each key is an
interface name, and each value is a hashref. The hasref key/value
pairs specify function names and descriptions for those functions. If
the function name is '' then this is used as the interface
description.

 MRP::Interface->create( interfaceName => { '' => $description_for_interfaceName,
                                            func1 => $description_for_func1,
                                            func2 => $description_for_func2,
                                            ...
                                            funcn => $description_for_funcn },
                         otherInterface => { ..... }
 );

=item functions

Returns the hash of function names and descriptions used to create the
interface.

=item name

Returns the name of the interface.

=item implementedBy

If the argument is a reference (presumably an object) then return true
or false depending on whether the object is of a class that implements
the interface.

If the argument is a package name (not a reference) then the package
is registered as implementing the interface. If the package does not
provide all of the required functions then an error is thrown.

=item anything else

Any other method is treated as if it where the name of an interface to
retrieve. Thus, MRP::Interface->Holly will retrieve the interface
named Holly. If Holly does not exist then a fatal error is thrown. So,
you can have code like:

 MRP::Interface->Holly->implementedBy($obj)
  || die "$obj does not implement interface Holly";

=back

=head1 AUTHOR

Matthew Pocock mrp@sanger.ac.uk
