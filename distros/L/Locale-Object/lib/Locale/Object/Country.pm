package Locale::Object::Country;

use strict;
use warnings;;
use Carp;

use Locale::Object;
use base qw( Locale::Object );

use Locale::Object::DB;
use Locale::Object::Currency;
use Locale::Object::Continent;
use Locale::Object::Language;

use DateTime::TimeZone;

our $VERSION = '0.78';

my $db = Locale::Object::DB->new();

# Initialize the hash where we'll keep our continent objects.
my $existing = {};


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
    qw(code_alpha2 code_alpha3 code_numeric name);
  
  # Go no further if the specified parameter wasn't one.
  croak "Error: You can only specify a country name, alpha2 code, alpha3 code or numeric code for initialization." unless exists $allowed_params{$parameter};

  # Get the value given for the parameter.
  my $value = $params{$parameter};

  # Make sure input matches style of values in the db.
  if ($parameter eq 'name')
  {
    $value = ucfirst($value);
  }
  elsif ($parameter eq 'code_alpha2' or $parameter eq 'code_alpha3')
  {
    $value = lc($value);
  }

  # Look in the database for a match.
  my $result = $db->lookup(
                           table         => 'country',
                           result_column => '*',
                           search_column => $parameter,
                           value         => $value
                          );
  
  croak "Error: Unknown $parameter given for initialization: $value" unless $result;

  if (defined @{$result}[0])
  {
    # Get the values from the result of our database query.
    my $code_alpha2           = $result->[0]->{'code_alpha2'}; 
    my $code_alpha3           = $result->[0]->{'code_alpha3'}; 
    my $code_numeric          = $result->[0]->{'code_numeric'}; 
    my $name                  = $result->[0]->{'name'};
    my $dialing_code          = $result->[0]->{'dialing_code'};

    $result = $db->lookup_dual(
                               table      => 'timezone',
                               result_col => 'timezone',
                               col_1      => 'country_code',
                               val_1      => $code_alpha2,
                               col_2      => 'is_default',
                               val_2      => 'true'
                              );
  
    my $timezone = $result->[0]->{timezone};

    # Check for pre-existing objects. Return it if there is one.
    my $country = $self->exists($code_alpha2);
    return $country if $country;
  
    # If not, make a new object.
    _make_country($self, $code_alpha2, $code_alpha3, $code_numeric, $name, $dialing_code, $timezone);
    
    # Register the new object.
    $self->register();
  
    # Return the object.
    $self;
  }
  else
  {
    carp "Warning: No result found in country table for '$value' in $parameter.";
    return;
  }
}

# Check if objects exist.
sub exists {
  my $self = shift;
  
  # Check existence of a object with the given parameter or with
  # the alpha2 code of the current object.
  my $code = shift;

  # Return the singleton object, if it exists.
  $existing->{$code};
}

# Register the object in our hash of existing objects.
sub register {
  my $self = shift;
  
  # Do nothing unless the object exists.
  my $code = $self->code_alpha2 or return;
  
  # Put the current object into the singleton hash.
  $existing->{$code} = $self;
}

sub _make_country
{
  my $self       = shift;
  my @attributes = @_;

  # The first attribute we get is the alpha2 country code.
  my $code = $attributes[0];

  # The attributes we want to set.
  my @attr_names = qw(code_alpha2 code_alpha3 code_numeric name dialing_code timezone);
  
  # Initialize a loop counter.
  my $counter = 0;
  
  # For each of those attributes,
  foreach my $current_attribute (@attr_names)
  {      
    # set it on the object.
    $self->$current_attribute( $attributes[$counter] );
    $counter++; 
  }

  # Check there's a continent row matching our current country.
  my $result = $db->lookup(
                                    table         => 'continent',
                                    result_column => '*',
                                    search_column => 'country_code',
                                    value         => $code
                                   );
  
  croak "Error: no continent found in the database for country code $code." unless @{$result}[0];
  
  my $continent = @{$result}[0]->{'name'};
  
  # Make new continent and currency objects as attributes.
  $self->{_continent} = Locale::Object::Continent->new(        name => $continent );
  $self->{_currency}  = Locale::Object::Currency->new( country_code => $code      );
  
}

# Method for retrieving all languages spoken in this country.
sub languages
{
  my $self = shift;

  # No name, no languages.
  return unless $self->{_name};
  
  # Check for languages attribute. Set it if we don't have it.
  _set_languages($self) unless $self->{_languages};

  # Give an array if requested in array context, otherwise a reference.    
  return @{$self->{_languages}} if wantarray;
  return $self->{_languages};
}

# Method for retrieving the official language(s) of this country.
sub languages_official
{
  my $self = shift;

  # No name, no languages.
  return unless $self->{_name};
  
  # Check for languages attribute. Set it if we don't have it.
  _set_languages($self) unless $self->{_languages};
  
  my @official_languages;

  foreach ($self->languages)
  {
    push (@official_languages, $_) if $_->official($self) eq 'true';
  }
  
  # Give an array if requested in array context, otherwise a reference.      
  return @official_languages if wantarray;
  return \@official_languages;
}

# Private method to set an attribute with an array of objects for all languages spoken in this country.
sub _set_languages
{
    my $self = shift;

    my @languages;
    
    # If it doesn't, find all countries in this continent and put them in a hash.
    my $result = $db->lookup(
                                      table => 'language_mappings', 
                                      result_column => 'language', 
                                      search_column => 'country', 
                                      value => $self->{'_code_alpha2'}
                                     );

    # Create new country objects and put them into an array.
    foreach my $lang (@{$result})
    {
      my $lang_code = $lang->{'language'};
      
      my $obj = Locale::Object::Language->new( code_alpha3 => $lang_code );
      push @languages, $obj; 
    }
    
    # Set a reference to that array as an attribute.
    $self->{'_languages'} = \@languages;
}

# Small methods that return object attributes.
# Will refactor these into an AUTOLOAD later.

sub code_alpha2
{
  my $self = shift;

  if (@_)
  {
    $self->{_code_alpha2} = shift;
    return $self;
  }
  
  $self->{_code_alpha2};
}

sub code_alpha3
{
  my $self = shift;  
  
  if (@_)
  {
    $self->{_code_alpha3} = shift;
    return $self;
  }

  $self->{_code_alpha3};
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

sub continent
{
  my $self = shift;  

  if (@_)
  {
    $self->{_continent} = shift;
    return $self;
  }

  $self->{_continent};
}

sub currency
{
  my $self = shift;  
  
  if (@_)
  {
    $self->{_currency} = shift;
    return $self;
  }

  $self->{_currency};
}

sub dialing_code
{
  my $self = shift;  
  
  if (@_)
  {
    $self->{_dialing_code} = shift;
    return $self;
  }

  $self->{_dialing_code};
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

sub timezone
{
  my $self = shift;  
  
  if (@_)
  {
    my $timezone = shift;
    return $self unless $timezone;
    $self->{_timezone} = DateTime::TimeZone->new( name => $timezone );

    return $self;
  }

  $self->{_timezone};
}  

sub all_timezones
{
  my $self = shift;  

  # Get the country alpha2 code.
  my $code = $self->code_alpha2;

  # If the all_timezones attribute exists, return it.
  if ($self->{_all_timezones})
  {
    return @{$self->{_all_timezones}} if wantarray;
    return $self->{_all_timezones};
  }
  # Otherwise, set it.
  else
  {
    # Get all time zones for the country code.
    my $results = $db->lookup(
                              table         => 'timezone',
                              search_column => 'country_code',
                              result_column => '*',
                              value         => $code
                             );
    my @timezones;
 
    foreach my $search_result (@{$results})
    {
      # Get the timezone from each result.
      my $zone = $search_result->{timezone};
    
      # Make a new object.
      my $tz_object = DateTime::TimeZone->new( name => $zone );
      
      # Stick it in an array.
      push @timezones, $tz_object;
    }

    $self->{_all_timezones} = \@timezones;

    return @{$self->{_all_timezones}} if wantarray;
    return $self->{_all_timezones};
  }
}

1;

__END__

=head1 NAME

Locale::Object::Country - country information objects

=head1 DESCRIPTION

C<Locale::Object::Country> allows you to create objects containing information about countries such as their ISO codes, currencies and so on.

=head1 SYNOPSIS

    use Locale::Object::Country;
    
    my $country = Locale::Object::Country->new( code_alpha2 => 'af' );
    
    my $name         = $country->name;         # 'Afghanistan'
    my $code_alpha3  = $country->code_alpha3;  # 'afg'
    my $dialing_code = $country->dialing_code; # '93'
    
    my $currency     = $country->currency;
    my $continent    = $country->continent;

    my @languages    = $country->languages;
    my @official     = $country->languages_official;
    
    my $timezone     = $country->timezone;
    my @allzones     = @{$country->all_timezones};
    
=head1 METHODS

=head2 C<new()>

    my $country = Locale::Object::Country->new( code => 'af' );
    
The C<new> method creates an object. It takes a single-item hash as an argument - valid options to pass are ISO 3166 values - 'code_alpha2', 'code_alpha3', 'code_numeric' and 'name'. See L<Locale::Object::DB::Schemata> for details on these.

The objects created are singletons; if you try and create a country object when one matching your specification already exists, C<new()> will return the original one.

=head2 C<code_alpha2(), code_alpha3(), code_numeric(), name(), dialing_code()>

    my $name = $country->name;
    
These methods retrieve the values of the attributes whose name they share in the object.

=head2 C<currency(), continent()>

These methods return L<Locale::Object::Currency> and L<Locale::Object::Continent> objects respectively. Both of those have their own attribute methods, so you can do things like this:

    my $currency      = $country->currency;
    my $currency_name = $currency->name;

See the documentation for those two modules for a listing of currency and continent attributes.

Note: More attributes will be added in a future release; see L<Locale::Object::DB::Schemata> for a full listing of the contents of the database.
    
=head2 C<languages(), languages_official()>

    my @languages = $country->languages;

C<languages()> returns an array of L<Locale::Object::Language> objects in array context, or a reference in scalar context. The objects have their own attribute methods, so you can do things like this:

    foreach my $lang (@languages)
    {
      print $lang->name, "\n";
    }

C<languages_official()> does much the same thing, but only gives languages that are official in that country. Note: you can also use the C<official()> method of a L<Locale::Object::Language> object on a country object; this will return a boolean value describing whether the language is official in that country.

=head2 C<timezone()>

    my $timezone = $country->timezone;
    
This method will return you a L<DateTime::TimeZone> object corresponding with the time zone in the capital of the country your object represents. See the documentation for that module to see what methods it provides; as a simple example:

    my $timezone_name = $timezone->name;

=head2 C<all_timezones()>

    my @allzones     = @{$country->all_timezones};

This method will return an array or array reference, depending on context, of L<DateTime::TimeZone> objects for all time zones that occur in the country your object represents. In most cases this will be only one, and in some cases it will be quite a few (for example, the US, Canada, and Russian Federation).

=head1 AUTHOR

Originally by Earle Martin

=head1 COPYRIGHT AND LICENSE

Originally by Earle Martin. To the extent possible under law, the author has dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty. You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

=cut
