package Devel::Carnivore;
use strict;
use 5.6.0;
use warnings;
use Carp;
use Attribute::Handlers;
no  warnings "redefine";

use vars qw/$OUT @EXPORT @ISA $NAME $VERSION/;

use base "Exporter";
@EXPORT = qw(watch unwatch);

$VERSION = 0.09;

# By default print to STDERR
$OUT = \*STDERR;

# test whether the first para is NOT a hashref
sub test_no_hashref($) {
	my($hashref) = @_;
	
	return if ref $hashref eq "HASH";                # normal hash ref: good
	
	if(ref $hashref) {
		local $@;
		eval '%{ $hashref }';
		return unless $@;                        # blessed hash: good
	}
	
	return 1;
}

# tie $hashref to Devel::Carnivore::Tie::Hash
# optionally specify a name
# for internal use: a custom carp level may be specified. look at Carp.pm for documentation
sub watch($;$) {
	my($hashref,$name) = @_;
	
	# this module only works with hashrefs
	croak "variable is not a hash reference" if test_no_hashref $hashref;
	
	my %copy = %$hashref; # make a copy of the actual hash in hashref
	
	my $calling_pkg = caller;
	
	croak "can't watch a variable which is already tied" if tied %$hashref;
	
	# print a comment that we start watching
	print $Devel::Carnivore::OUT "# variable is now under observation\n";
                
	tie %$hashref, 'Devel::Carnivore::Tie::Hash', $name;
	# %$hashref is now empty
	
	while(my($key,$value) = each %copy) { # but we restore the copy 
		$hashref->{$key} = $value	
	}
}

# untie $hashref
sub unwatch($) {
	my($hashref) = @_;
	
	if(test_no_hashref $hashref) { # of course this only works if $hashref is actually a hash reference
		carp "variable is not a hash reference"
	}
	elsif((tied %$hashref)->isa("Devel::Carnivore::Tie::Hash")) {
		no warnings; # silence "untie attempted while 1 inner references still exist" warning
		             # is there a better way to do this.
		             # as far as I can see this call is perfectly safe.
		untie %$hashref;
		print $Devel::Carnivore::OUT "# mission completed\n";
	} else {
		carp "Apparently this variable is not currently under observation."	
	}
}

# install Watch as a universal attribute for hashes
# a name may be given as the single parameter to the attribute
# we then call our watch with the hashref and the name
sub UNIVERSAL::Watch : ATTR(HASH) {
	my ($package, $symbol, $hashref, $attr, $name, $phase) = @_;  
        
	watch $hashref, $name
}
 
# install Watch as a universal attribute for scalars
# this scalar is then tied to the special class Devel::Carnivore::Tie::Scalar
# ....why the f*ck? ... oh, yeah, so we can automatically tie any hashref to
# Devel::Carnivore::Tie::Hash as soon as it is assigned to this scalar :)
sub UNIVERSAL::Watch : ATTR(SCALAR) {
	my ($package, $symbol, $scalar_ref, $attr, $name, $phase) = @_;  
        
	tie $$scalar_ref, 'Devel::Carnivore::Tie::Scalar', $name
}

# utility class used by the Watch scalar attribute
package Devel::Carnivore::Tie::Scalar;
use Carp;
use Devel::Carnivore;

# save a scalar and a name with the tied scalar
sub TIESCALAR {
	my($class,$name) = @_;
	
	my $scalar = undef;
	
	my $self = {
		scalar => \$scalar,
		name   => $name,
	};
	
	bless $self, $class;
}

# only hashrefs or object based on hashrefs may be assigned to scalars based on this class
# these hashrefs are then immediately tied to Devel::Carnivore::Tie::Hash
sub STORE {
	my($self,$value) = @_;
	
	croak "You may only store hashrefs within a scalar under observation by Devel::Carnivore."
		if Devel::Carnivore::test_no_hashref($value);
	
	Devel::Carnivore::watch $value, $self->{name};
	
	${$self->{scalar}} = $value
}

sub FETCH   { ${$_[0]->{scalar}} }
sub DESTROY { undef ${$_[0]->{scalar}} }

package Devel::Carnivore::Tie::Hash;

# this is where the actual output is generated
sub STORE {
	my($self,$key,$value)     = @_;
	my($package,$filename,$line) = caller;
	
	my $hashref   = $self->{hash};
	my $name      = $self->{name};
	
	my $old_value = $hashref->{$key};

	$key       = defined $key       ? $key       : ""; # some stuff to limit warnings
	$value     = defined $value     ? $value     : "";
	$old_value = defined $old_value ? $old_value : "";
	
	my $message = "> "; # this is what will eventually get printed out
	
	$message .= qq{$name: } if defined $name; # we start out with a name if we have one
	
	# "myHashKey" changed from "someValue" to "someOtherValue"
	$message .= qq{"$key" changed from "$old_value" to "$value" };
	
	
	# $Carp::CarpLevel may be set to influence the output.
	# This sucks bad!!!. First, CarpLevel is deprecated but setting CarpInternal to our 
	# caller does not seem to work, second, setting CarpLevel to 1 seems to be the right
	# thing but Perl 5.6.1 (and below???) doesnt like it.
	
	local $Carp::CarpLevel;
	if($] >= 5.008) {
		$Carp::CarpLevel = 1;
	}
	
	# we print this using a function available via the Carp module
	# it automatically adds information about where this method was called
	
	print $Devel::Carnivore::OUT Carp::shortmess($message);
	
	# ahh, and finally we behave like a normal hash.
	return $hashref->{$key} = $value;
}

# make an object with a hash and a name
sub TIEHASH  {
	my($class,$name) = @_; 
	
	bless {
		hash => {},
		name => $name,	
	}, $class 
}

# copied from Tie::Hash, adapted to my object scheme
sub FETCH    { $_[0]->{hash}{$_[1]} }
sub FIRSTKEY { my $a = scalar keys %{$_[0]->{hash}}; each %{$_[0]->{hash}} }
sub NEXTKEY  { each %{$_[0]->{hash}} }
sub EXISTS   { exists $_[0]->{hash}{$_[1]} }
sub DELETE   { delete $_[0]->{hash}{$_[1]} }
sub CLEAR    { %{$_[0]->{hash}} = () }

q<big brother is watching you>

__END__

=head1 NAME

Devel::Carnivore - Spy on your hashes (and objects)

=head1 SYNOPSIS

  use Devel::Carnivore;
  
  sub new_attribute {
    my %self : Watch("myName") = ();		

    bless \%self, shift;
  }

  sub new_functional {
    my $self  = {};		
    watch $self, "myName";
    bless $self
  }

  sub new_blessed {
    my $self  = {};	
    bless $self;
    watch $self, "myName";
    return $self;
  }

  sub new_scalar_attribute {
    my $self : Watch("myName") = {};		
    bless $self
  }

=head1 DESCRIPTION

This module allows you to debug your hashes and, in particular, your objects 
based on hashes without using the perl debugger. There are several good reasons
to do this. Among them:

1) You're too stupid to use the perl debugger (This is true for me)

2) You're building web applications and the perl debugger doesn't work very
well in that environment

Obviously, this module does not provide you with a complete debugger. All it does
is helping you keep track of the state changes which occur to your objects. 

=head2 Output

By default all output is written to STDERR. You may change this behavior by assigning
a valid output filehandle to C<$Devel::Carnivore::OUT>.

Everytime the hash which is being watched by this module is assigned to, a message
like this is created:
> ProgLang: "cool" changed from "Java" to "Perl"  at devel.pl line 30

So what does this tell you?

You have a Perl file named devel.pl. On line 30 your code changed the value of the 
key "cool" from "Java" to "Perl". In order, to identify this hash you optionally
named it "ProgLang".

=head1 USAGE

There are several ways to declare a hash as being watched. "aName" is always
optional. You can use it to identify a certain hash in the output.

The following text will assume "place under observation" means "tie to Devel::Carnivore"

=item functional

  The function C<watch> (which is exported by default) will place it's first
  para under observation.

  C<watch $hashref, "aName">
  C<watch \%hash, "aName">

=item scalar attribute

  The attribute Watch may be placed on any scalar which is immediately
  assigned an hash reference. It will put this hash reference under observation.

  C<my $scalar : Watch("aName") = {};>
  
=item hash attribute

  The attribute Watch may be placed on any hash to put it under observation.

  C<my %hash : Watch("aName") = ();>

=item stop tracing

  This function (which is exported by default) will END the observation of it's
  first para.

  C<unwatch $hashref>
  C<unwatch \%hash>   

=head1 WARNING

Please do NOT use this module on any hashes which are tied to any other
class during their livetime. That won't work.

=head1 BUGS

It seems to work alright, but this module is in very early state.

It would be nice to have a complete stack trace for each state change
and some tool to format that output nicely.

The module could easily extended to work on arrays. Currently I don't
feel the need.

=head1 AUTHOR

Malte Ubl, E<lt>malteubl@gmx.deE<gt>

=head1 COPYRIGHT

Copyright 2002 by Malte Ubl E<lt>malteubl@gmx.deE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut
