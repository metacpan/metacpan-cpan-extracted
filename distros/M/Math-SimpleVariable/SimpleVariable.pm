package Math::SimpleVariable;

require 5.005_62;
use strict;
use warnings;
use Carp;

our $VERSION = '0.03';
use fields (
   'name',  # a string with the name of the variable
   'value', # the numerical value of the variable
);

sub new {
    # parse the arguments
    my $proto = shift;
    my $pkg = ref($proto) || $proto;
    my %arg = ();
    if(@_ == 1 && defined(ref $_[0])) {
	if(ref($_[0])->isa('Math::SimpleVariable')) {
	    # new() was invoked as a copy ctor
	    return $_[0]->clone();
	}
	elsif(ref($_[0]) eq 'HASH') {
	    # the arguments are passed in a ref to a hash
	    %arg = %{$_[0]};
	}
	else {
	    croak "Invalid argument passed to Math::SimpleVariable::new()";
	}
    }
    else {
	%arg = @_;
    }

    # build the object
    my Math::SimpleVariable $this = fields::new($pkg);
    while(my($k,$v) = each %arg) {
	$this->{$k} = $v;
    }

    # further initialize the object (e.g. apply default values were no value was given)
    $this->initialize();

    return $this;
}

sub initialize { # override this method in derived() classes
    my Math::SimpleVariable $this = shift;
    defined($this->{name}) or die "No name specified for variable";
    return 1;
}

sub clone { # makes a deep copy of the object
    # You need to override clone() in derived classes carrying additional data!
    my Math::SimpleVariable $this = shift;
    return Math::SimpleVariable->new(
       name  => $this->{name},
       value => $this->{value},
    );
}

### Accessors (including useful aliases)
sub name {
    my Math::SimpleVariable $this = shift;
    return $this->{name};
}

sub id {
    my Math::SimpleVariable $this = shift;
    return $this->name();
}

sub value {
    my Math::SimpleVariable $this = shift;
    return $this->{value};
}

sub evaluate {
    my Math::SimpleVariable $this = shift;
    return $this->value();
}

### I/O
sub stringify {
    my Math::SimpleVariable $this = shift;
    return $this->name();
}


1;

__END__

=head1 NAME

Math::SimpleVariable - simple representation of mathematical variables

=head1 SYNOPSIS

  use Math::SimpleVariable;

  # Make a variable
  my $foo = new Math::SimpleVariable(name => 'foo', value => 0.3);

  # Some of the available accessors
  # Note that many are identical, but you might want to change
  # their behaviour in derived variable classes...
  my $name = $foo->name();       # yields 'foo'
  print $foo->stringify(), "\n"; # prints 'foo'
  my $id = $foo->id();           # yields 'foo'
  my $value = $foo->value();     # yields 0.3
  print $foo->evaluate(), "\n";  # prints 0.3

  # Make a second variable
  my $bar = $foo->clone();
  $bar->{name} = 'bar';      # changes the name (and as a consequence the id())
  print $bar->value(), "\n"; # prints the same value, 0.3

=head1 DESCRIPTION

Math::SimpleVariable is a simple representation of mathematical variables,
with an obligatory name and an optional value. This class on itself might
not seem very useful at first sight, but you might want to derive different
types of variables for some application. That way, objects of the derived 
variable class can be accessed interchangeably with the here provided
protocols.

Math::SimpleVariable has two data fields - B<name> and B<value> - that
can be accessed and modified as if the variable object is a hash. E.g.

    $var->{name} = 'foo';

sets the name of the object $var to 'foo', and

    my $val = $var->{value};

reads the value of the $var object into $val.

In addition, the following accessor methods are available for 
Math::SimpleVariable objects:

=over 4

=item $var->name()

Returns $var->{name}

=item $var->id()

Returns $var->name() for Math::SimpleVariable objects. The purpose
of id() is to provide some unique identifier when using variables
in some higher level concept, e.g. a matrix representation of a set
of equations. Depending on your needs, you might want to change
the implementation of id() in derived classes.

=item stringify()

Returns a printable representation of the variable. For Math::SimpleVariable
objects, returns $var->name(). Again, you might want to override this
for derived classes.

=item value()

Returns $var->{value}

=item evaluate()

Returns a numerical evaluation of the variable. For Math::SimpleVariable
objects, returns $var->value(). You might want to override this behaviour
in derived classes, athough I cannot think of any place where this might
come in useful :-). evaluate() is still there for reasons of orthogonality.

=back

=head1 SEE ALSO

perl(1).

=head1 VERSION

This is CVS $Revision: 1.6 $ of Math::Simplevariable,
last edited at $Date: 2001/10/31 12:38:39 $.

=head1 AUTHOR

Wim Verhaegen E<lt>wimv@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2001 Wim Verhaegen. All rights reserved.
This program is free software; you may redistribute
and/or modify it under the same terms as Perl itself.

=cut
