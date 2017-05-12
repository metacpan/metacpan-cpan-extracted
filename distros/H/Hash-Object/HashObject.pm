package Tie::HashObject;

sub new {
        my $class = shift;
        my %args  = @_;

        my %tied;
        #tie %tied, Tie::HashMethods, {keys=> $args{keys}};
        tie %tied, Tie::HashMethods;

        my $self = bless \%tied, $class;
	$tied{keys}   = $args{keys} if exists $args{keys};
        $tied{object} = $self;
        return $self;
}
1;

package Tie::HashMethods;

use strict;

our $VERSION = '0.01';

sub defined_public_keys {
	my $self = shift;
	my $keys = [];
	foreach my $key (@{$self->method_keys}) {
		push @$keys, $key if defined $self->{storage}->{$key};
	}
	return $keys;
}


sub DESTROY {
	my $self = shift;
	# Note: I don't know if this is neccessary.
	# but it gets rid of the self reference...
	$self->{object} = {};
	# I worried about having a reference inside a reference... but I'm not sure whether this is a problem.
}

sub object {
	my $self = shift;
	$self->{object} = shift if defined $_[0];
	return $self->{object};
}

sub method_keys {
	my $self = shift;
	$self->{keys} = shift if defined $_[0];
	return $self->{keys};
}

sub TIEHASH  { 
	my $class = shift;
	my $args  = shift;

	my $self = bless {}, $class;

	if (exists $args->{keys}) {
		$self->method_keys($args->{keys});
	}

	return $self;
}

sub STORE { 
	my $self  = shift;
	my $key   = shift;
	my $value = shift;

	if (!defined $self->object && $key eq 'object') {
		if (ref $value) {
			$self->object($value);
		} else {
			warn sprintf('First call to %s->{object} must be a reference to an object', __PACKAGE__);
		}
	}
	elsif (!defined $self->method_keys && $key eq 'keys') {
		$self->method_keys($value);
	}
        elsif ( $self->object->isa( (caller)[0] ) ) { 
		return $self->{storage}->{$key} = $value;
	}
	elsif (grep /^$key$/, @{$self->method_keys}) {
		$self->object->$key($value);
	}
	else {
		warn "Invalid key: " . $key;
	}
}

sub FETCH { 
	my $self = shift;
	my $key  = shift;
        if ( $self->object->isa((caller)[0]) ) { 
		return $self->{storage}->{$key};
	}
	elsif (grep /^$key$/, @{$self->method_keys}) {
		return $self->object->$key;
	}
	else {
		warn "Invalid key: " . $key;
	}
}

sub FIRSTKEY {
	my $self = shift;
        if ( $self->object->isa((caller)[0]) ) { 
		return (keys %{$self->{storage}})[0];
	}
	else {
		# we have to do this for data dumps...
		return (@{$self->defined_public_keys})[0];
	}
}

sub NEXTKEY { 
	my $self        = shift;
	my $last_method = shift;

	my @keys;

        if ( $self->object->isa((caller)[0]) ) { 
		@keys = keys %{$self->{storage}};
	}
	else {
		@keys = @{$self->defined_public_keys};
	}
	my $next_index  = 0;
	foreach my $key (@keys) {
		$next_index++;
		last if $last_method eq $key;
	}
	return $next_index > scalar @keys ? undef : $keys[$next_index];
}


sub EXISTS { 
	my $self = shift;
	my $key  = shift;

        if ( $self->object->isa((caller)[0]) ) { 
		return exists $self->{storage}->{$key};
	}
	else {
		return (grep /^$key$/, @{$self->defined_public_keys});
	}
}

sub DELETE { 
	my $self = shift;
	my $key  = shift;

        if ( $self->object->isa((caller)[0]) ) { 
		return delete $self->{storage}->{$key};
	}
	else {
		warn "Cannot delete methods. Please set the values instead.";
	}
}

# override this method if you have some default for clearing the method hash values...
sub CLEAR  { 
	my $self = shift;
        if ( $self->object->isa((caller)[0]) ) { 
		$self->{storage} = {};
	}
	else {
		warn "Cannot clear tied method calls"; 
	}
}

sub SCALAR { 
	my $self = shift;
        if ( $self->object->isa((caller)[0]) ) { 
		return scalar keys %{$self->{storage}};
	}
	else {
		return scalar @{$self->defined_public_keys};
	}
}

1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Tie::HashObject - Perl extension for changing object methods into a limited set of allowed hash keys. Returns a tied hash with keyed access to the defined methods. The original object is accessed through a specially named key.

=head1 SYNOPSIS

  #.. example ..

  use Tie::HashObject;

  my $some_object = Bla::Bla->new;
  my %tied_hash;
  tie %tied_hash, 'Tie::HashMethods', { object => $some_object, keys => [qw(method1 method2 etc)] };

  #...or...

  $tied = Tie::HashObject->new(
	object => $someobject,
	keys => [qw(method1 method2 etc)],
  );

  #...generally, you will want to inherit from Tie::HashObject and call it's new...

  package TieThisObject;
  use vars qw(Tie::HashObject);

  sub method1 {$_[0]->{method1} = $_[1]}
  sub method2 {$_[0]->{method2} = $_[1]}

  #...then in the main program you would...
  my $outside = TieThisObject->new(keys => [qw(method1 method2)]);
  
  # Now, from the 'main' program, you will only have access to...
  my $outside = TieThis::Object->new;
  $outside->{method1};
  $outside->{method2};

  # Also, calling these keys from outside the object will actually call the related method, so...
  $outside->{method1} = 5;
  # ...will actually call...
  $self->method1(5);
  # ...from inside the TieThis::Object object.

  # try this for fun...
  @{$outside}{method1 method2} = qw(jelly booba);

  # don't try this...
  $outside->{random_key};
  # ...since you didn't declare this as valid it will return an error warning and not store anything.

  # However, within the class, you will have direct access to the full range of the hash...
  $self->{cgi} = CGI->new; 
  # This would work inside TieThis::Object for example.. (as well as any super class)

=head1 DESCRIPTION

This method allows you to quickly create protection for an Object by using a tied hash instead of the standard hash ref. 
Simply, provide a list of allowed keys and a reference to the original object type.

Note: All calls to the set/retrieve keys from the tied hash object will actually call the internal methods of the same name. So consider this for mostly get/set methods or methods that do a small amount of work. This generally isn't a problem since it is bad practice to call/set blessed reference internals directly.

Reason: I like using hashes and wanted to be able to use object data as a hash without violating direct calls to the object internals. I also wanted to be able to access the object methods.

Pros: It will probably make your module much more safe and convenient to use.
Cons: This is will slow things down and use more memory.

I hope this module makes it easy enough for others to begin tying up their module references.

Best luck.

=head1 Tie::HashObject

=head2 METHODS

new()
  Can be called as a class or object method.
  Allows for the following parameters:

  keys
    An arrayref of method names which list the accessible method names. 
    Defaults to the keys already available within the object (but don't do that).
    I may update this to allow a hashref where key names are mapped to methods of 
    a different name.

=head1 Tie::HashMethods

=head2 TIEHASH()

  keys 
    An arrayref of method names which list the accessible method names. 
    Defaults to the keys already available within the object (but don't do that). 
    I may update this to allow a hashref where key names are mapped to methods of 
    a different name.

=head2 object()

    sets the internally stored object. Call this first! Or inherit Tie::HashObject 
    and call it's new() method to do this automatically.

=head1 AUTHOR

Jeffrey B Anderson jeff@pvrcanada.com

=head1 SEE ALSO

perltie(1).
Tie::Hash

=cut
