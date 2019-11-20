package Locale::Object::Continent;

use strict;
use warnings;;
use Carp qw(croak);

use Locale::Object;
use base qw( Locale::Object );

use Locale::Object::Country;
use Locale::Object::DB;

our $VERSION = '0.78';

my $db = Locale::Object::DB->new();

# Initialize the hash where we'll keep our singleton continent objects.
my $existing = {};

# Yours is the hash, and everything that's in it.
my %continents = map { $_ => undef }
  ('Africa', 'Asia', 'Europe', 'North America', 'Oceania', 'South America');
  
# Initialize the object.
sub init
{
  my $self = shift;
  my %params = @_;
  return unless %params;
  
  # Two's a crowd.
  my $num_params = keys %params;
  
  croak "Error: No continent name specified for initialization." unless $params{name};
  croak "Error: You can only specify a single continent name for initialization."
      if $num_params > 1;
      
  # Check for pre-existing objects. Return it if there is one.  
  my $continent = $self->exists($params{name});
  return $continent if $continent;
  
  # Initialize with a continent name.
  my $name = $params{name};
  $self->{_name} = $name;

  # Register the new object.
  $self->register();
  
  # Return the object.
  $self;
}

# Check if objects exist in the singletons hash.
sub exists {
  my $self = shift;
  
  # Check existence of a object with the given parameter or with
  # the name of the current object.
  my $name = shift;
  
  # Return the singleton object, if it exists.
  $existing->{$name};
}

# Register the object as a singleton.
sub register {
  my $self = shift;
  
  # Do nothing unless the object has a name.  
  my $name = $self->name or return;
  
  # Put the current object into the singleton hash.
  $existing->{$name} = $self;
}

sub name
{
  my $self = shift;
  my $name = shift;
  
  # If no arguments were given, return the name attribute of the current object. 
  # Otherwise, carry on and set one on the current object.
  return $self->{_name} unless defined $name;
  
  # Check we didn't fall off the edge of the world.
  # http://www.maphist.nl/extra/herebedragons.html
  croak "Error: unknown continent name given for initialization: '$name'" unless exists $continents{$name};
  
  # Set the name.
  $self->{_name} = $name;
  
  # If a Continent object with that name exists, return it. 
  if (my $continent = $self->exists( $name ))
  {
    return $continent;
  }
  # Otherwise, register the current object as a singleton.
  else
  {
    $self->register();
  }
  
  # Return the current object.
  $self;
}

# Method for retrieving all countries in this continent.
sub countries
{
  my $self = shift;
   
  # No name, no countries.
  return unless $self->{_name};
    
  # Check for countries attribute. Set it if we don't have it.
  _set_countries($self) unless $self->{_countries};

  # Give an array if requested in array context, otherwise a reference.    
  return @{$self->{_countries}} if wantarray;
  return $self->{_countries};
}

# Private method to set an attribute with an array of objects for all countries in this continent.
sub _set_countries
{
    my $self = shift;

    my (%country_codes, @countries);
    
    # If it doesn't, find all countries in this continent.
    my $result = $db->lookup(
                                      table => 'continent', 
                                      result_column => 'country_code', 
                                      search_column => 'name', 
                                      value => $self->{'_name'}
                                     );

    # Create new country objects and put them into an array.
    foreach my $place (@{$result})
    {
      my $where = $place->{'country_code'};

      my $obj = Locale::Object::Country->new( code_alpha2 => $where );
      push @countries, $obj; 
    }
        
    # Set a reference to that array as an attribute.
    $self->{'_countries'} = \@countries;
}

1;

__END__

=head1 NAME

Locale::Object::Continent - continent information objects

=head1 DESCRIPTION

C<Locale::Object::Continent> allows you to create objects representing continents, that contain other objects representing the continent in question's countries.

=head1 SYNOPSIS

    my $asia      = Locale::Object::Continent->new( name => 'Asia' );

    my $name      = $asia->name;
    my @countries = $asia->countries;

=head1 METHODS

=head2 C<new()>

    my $asia = Locale::Object::Continent->new( name => 'Asia' );
    
The C<new> method creates an object. It takes a single-item hash as an argument - the only valid options to it is 'name', which must be one of 'Africa', 'Asia', 'Europe', 'North America', 'Oceania' or 'South America'. Support for Antarctic territories is not currently provided.

The objects created are singletons; if you try and create a continent object when one matching your specification already exists, C<new()> will return the original one.

=head2 C<name()>

    my $name = $asia->name;
    
Retrieves the value of the continent object's name.

=head2 C<countries()>

    my @countries = $asia->countries;

Returns an array of L<Locale::Object::Country> objects with their ISO 3166 alpha2 codes as keys in array context, or a reference in scalar context. The objects have their own attribute methods, so you can do things like this:

    foreach my $place (@countries)
    {
      print $place->name, "\n";
    }
    
Which will list you all the currencies used in that continent. See the documentation for L<Locale::Object::Country> for a listing of country attributes. Note that you can chain methods as well.

    foreach my $place (@countries)
    {
      print $place->currency->name, "\n";
    }

=head1 AUTHOR

Originally by Earle Martin

=head1 COPYRIGHT AND LICENSE

Originally by Earle Martin. To the extent possible under law, the author has dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty. You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

=cut
