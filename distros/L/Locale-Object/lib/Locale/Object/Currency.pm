package Locale::Object::Currency;

use strict;
use warnings;;
use Carp;

use Locale::Object;
use base qw( Locale::Object );

use Locale::Object::Country;
use Locale::Object::DB;

our $VERSION = '0.78';

my $db = Locale::Object::DB->new();

# Initialize the hash where we'll keep our singleton currency objects.
my $existing = {};

my $class;

# Initialize the object.
sub init
{
  my $self   = shift;
  my %params = @_;

  # One parameter is allowed.
  croak "Error: You must specify a single parameter for initialization."
    unless scalar(keys %params) == 1;

  # It's the only key in %params.    
  my $parameter = (keys %params)[0];
  
  # Make a hash of valid parameters.
  my %allowed_params = map { $_ => undef }
    qw(country_code code code_numeric);
  
  # Go no further if the specified parameter wasn't one.
  croak "Error: You can only specify a country code, currency code or numeric code for initialization." unless exists $allowed_params{$parameter};

  # Get the value given for the parameter.
  my $value = $params{$parameter};

  # Make sure input matches style of values in the db.
  if ($parameter eq 'country_code')
  {
    $value = lc($value);
  }
  elsif ($parameter eq 'code')
  {
    $value = uc($value);
  }
  
  # Look in the database for a match.
  my $result = $db->lookup(
                           table         => 'currency',
                           result_column => '*',
                           search_column => $parameter,
                           value         => $value
                          );

  croak "Error: Unknown $parameter given for initialization: $value" unless $result;

  if (defined @{$result}[0])
  {
    # Set values from the results of our query.
    my $name           = @{$result}[0]->{'name'}; 
    my $code           = @{$result}[0]->{'code'}; 
    my $code_numeric   = @{$result}[0]->{'code_numeric'}; 
    my $symbol         = @{$result}[0]->{'symbol'}; 
    my $subunit        = @{$result}[0]->{'subunit'}; 
    my $subunit_amount = @{$result}[0]->{'subunit_amount'}; 
    
    # Check for pre-existing objects. Return it if there is one.
    my $currency = $self->exists($code);
    return $currency if $currency;
  
    # If not, make a new object.
    _make_currency($self, $name, $code, $code_numeric, $symbol, $subunit, $subunit_amount);
    
    # Register the new object.
    $self->register();
  
    # Return the object.
    $self;
  }
  else
  {
    carp "Warning: No result found in currency table for '$value' in $parameter.";
    return;
  }
}

# Check if objects exist.
sub exists {
  my $self = shift;
  
  # Check existence of a object with the given parameter or with
  # the code of the current object.
  my $code = shift || $self->code;
  
  # Return the singleton object, if it exists.
  $existing->{$code};
}

# Register the object in our hash of existing objects.
sub register {
  my $self = shift;
  
  # Do nothing unless the object exists.
  my $code = $self->code or return;
  
  # Put the current object into the singleton hash.
  $existing->{$code} = $self;
}

sub _make_currency
{
  my $self       = shift;
  my @attributes = @_;

  # The third attribute we get is the currency code.
  my $currency_code = $attributes[0];
  
  # The attributes we want to set.
  my @attr_names = qw(name code code_numeric symbol subunit subunit_amount);
  
  # Initialize a loop counter.
  my $counter = 0;
  
  foreach my $current_attribute (@attr_names)
  {
    # Set the attributes of the entry for this currency code in the singleton hash.
    $self->$current_attribute( $attributes[$counter] );
   
    $counter++; 
  }

}

# Method for retrieving all countries using this currency.
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

# Private method to set an attribute with a hash of objects for all countries using this currency.
sub _set_countries
{
    my $self = shift;

    my $code = $self->{_code};
        
    # If it doesn't, find all countries using this currency and put them in a hash.
    my (%country_codes, @countries);
    
    my $result = $db->lookup(
                                      table => "currency", 
                                      result_column => "country_code", 
                                      search_column => "code", 
                                      value => $existing->{$code}->{'_code'}
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

# Get/set attributes.

sub code
{
  my $self = shift;  

  if (@_)
  {
    $self->{_code} = shift;
    return $self;
  }

  $self->{_code};
}

sub name
{
  my $self = shift;

  if (@_)
  {
    $self->{_name} = shift;
    return $self;
  }
  
  $self->{_name};
}

sub code_numeric
{
  my $self = shift;

  if (@_)
  {
    $self->{_code_numeric} = shift;
    return $self;
  }

  $self->{_code_numeric};
}  

sub symbol
{
  my $self = shift;

  if (@_)
  {
    $self->{_symbol} = shift;
    return $self;
  }
  
  $self->{_symbol};
}

sub subunit
{
  my $self = shift;  

  if (@_)
  {
    $self->{_subunit} = shift;
    return $self;
  }

  $self->{_subunit};
}

sub subunit_amount
{
  my $self = shift;  

  if (@_)
  {
    $self->{_subunit_amount} = shift;
    return $self;
  }

  $self->{_subunit_amount};
}

1;

__END__

=head1 NAME

Locale::Object::Currency - currency information objects

=head1 DESCRIPTION

C<Locale::Object::Country> allows you to create objects containing information about countries such as their ISO codes, currencies and so on.

=head1 SYNOPSIS

    use Locale::Object::Currency;

    my $usd = Locale::Object::Currency->new( country_code => 'us' );

    my $name           = $usd->name;
    my $code           = $usd->code;
    my $code_numeric   = $usd->code_numeric;
    my $symbol         = $usd->symbol;
    my $subunit        = $usd->subunit;
    my $subunit_amount = $usd->subunit_amount;
    
    my @countries      = $usd->countries;

=head1 METHODS

=head2 C<new()>

    my $usd = Locale::Object::Currency->new( country_code => 'us' );

The C<new> method creates an object. It takes a single-item hash as an argument - valid options to pass are ISO 3166 values - 'code' and 'code_numeric'; also 'country_code', which is an alpha2 country code (see L<Locale::Object::DB::Schemata> for details on these). If you give a country code, a currency object will be created representing the currency of the country you specified.

The objects created are singletons; if you try and create a currency object when one matching your specification already exists, C<new()> will return the original one.

=head2 C<name(), code(), code_numeric(), symbol(), subunit(), subunit_amount()>

    my $name = $country->name;
    
These methods retrieve the values of the attributes in the object whose name they share.

=head2 C<countries()>

    my @countries = $usd->countries;

Returns an array (in array context, otherwise a reference) of L<Locale::Object::Country> objects with their ISO 3166 alpha2 codes as keys (see L<Locale::Object::DB::Schemata> for more details on those) for all countries using this currency in array context, or a reference in scalar context. The objects have their own attribute methods, so you can do things like this for example:

    foreach my $place (@countries)
    {
      print $place->name, "\n";
    }
    
Which will list you all the countries that use in that currency. See the documentation for L<Locale::Object::Country> for a listing of country attributes. Note that you can chain methods as well.

    foreach my $place (@countries)
    {
      print $place->continent->name, "\n";
    }

=head1 KNOWN BUGS

The database of currency information is not perfect by a long stretch. If you find mistakes or missing information, please send them to the author.

=head1 AUTHOR

Originally by Earle Martin

=head1 COPYRIGHT AND LICENSE

Originally by Earle Martin. To the extent possible under law, the author has dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty. You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

=cut

