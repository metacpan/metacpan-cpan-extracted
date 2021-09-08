package Locale::Object;

use strict;
use warnings;
use Carp;

use Locale::Object::Continent;
use Locale::Object::Country;
use Locale::Object::Currency;
use Locale::Object::Language;

our $VERSION = '0.82';

sub new
{
  my $class = shift;
  my %params = @_;

  my $self = bless {}, $class;
  
  # Initialize the new object or return an existing one.
  $self->init(%params);
}

sub init
{
  my $self   = shift;
  my %params = @_;

  # Make a hash of valid parameters.
  my %allowed_params = map { $_ => undef }
    qw( country_code_alpha2 country_code_alpha3 country_code_numeric 
        currency_code currency_code_numeric currency_name
        language_code_alpha2 language_code_alpha3 language_name );

  foreach my $parameter (keys %params)
  {
    # Go no further if the specified parameter wasn't one.
    croak "Error: Initialization parameter $parameter unrecognized." unless exists $allowed_params{$parameter};
    
    $self->$parameter( $params{$parameter} );
  }
  
  $self;
}  

# Check 'sanity' of object - that is, whether attributes correspond with each other
# (no mixing of, say, currency from one country with language from another).

sub sane
{
  my $self = shift;
  my $what = shift;

  # Default attribute is country.
  $what = 'country' unless $what;
  
  # Make a hash of allowed attributes.
  my %attributes = map { $_ => undef } qw( country currency language );

  croak "ERROR: attribute to check sanity against ($what) unrecognized, must be one of 'country', 'currency', 'language'." unless exists $attributes{$what};
   
  # We want to compare our selected attribute against the remaining attributes,
  # which will be whatever's left after deleting it from our attributes list.
  delete $attributes{$what};

  my $sanity_level = 0;

  # Compare each of the other attributes.
  foreach (keys %attributes)
  {
    $sanity_level++ if $self->_compare( from => $_, to => $what ) == 1;
  }
    
  # It's only sane if both the other attributes matched.
  return 1 if $sanity_level == 2;
  
  0;
}

# Compare object attributes against each other.
# Horrible, horrible code.

sub _compare
{
  my $self   = shift;
  my %params = @_;

  my $from = '_' . $params{from};
  my $to   = '_' . $params{to};
  
  # Pointless but we won't forbid it.
  return 1 if $params{from} eq $params{to};
  
  # An empty attribute is a sane attribute.
  return 1 unless $self->{$from};

  if ($params{to} eq 'country')
  {    
    foreach my $place ($self->{$from}->countries)
    {
      # If any of the countries we're checking match the code
      # of $self->{_country}, it's sane.
      return 1 if $place->code_alpha2 eq $self->{_country}->code_alpha2;
    }
  }
  
  elsif ($params{to} eq 'language')
  {
    if ($params{from} eq 'country')
    {
      foreach ($self->{_country}->languages)
      {
        # If $self->{_language} is one of those, it's sane.
        return 1 if $_->code_alpha2 eq $self->{_language}->code_alpha2;
      } 
    }
    
    elsif ($params{from} eq 'currency')
    {
      my %languages;
      
      # Check the alpha2 codes of all the languages used
      # in all the countries that use that currency.
      foreach ($self->{_currency}->countries)
      {
        foreach ($_->languages)
        {
          # If $self->{_language}'s alpha2 code is one of those, it's sane.
          return 1 if $_->code_alpha2 eq $self->{_language}->code_alpha2;
        }
      }
    }
  }
  
  elsif ($params{to} eq 'currency')
  {
    if ($params{from} eq 'country')
    {
      foreach ($self->{_currency}->countries)
      {
        # If any of the countries we're checking match the code
        # of $self->{_country}, it's sane.
        return 1 if $_->code_alpha2 eq $self->{_country}->code_alpha2;
      }
    }
    
    elsif ($params{from} eq 'language')
    {
      # Check the codes of all the currencies used
      # in all the countries that use that language.
      foreach ($self->{_language}->countries)
      {
        foreach ($_->currency)
        {
          # If $self->{_currency}'s code is one of those, it's sane.
          return 1 if $_->code eq $self->{_currency}->code;
        }
      }
    }
  }
  
  0;
}

# Make all the attributes kinsmen.

sub make_sane
{
  my $self   = shift;
  my %params = @_;

  my $what     = $params{attribute};
  my $populate = $params{populate} || 0;

  # Make a hash of allowed attributes.
  my %attributes = map { $_ => undef } qw( country currency language );

  # Default attribute is country.
  $what = 'country' unless $what;
  
  croak qq{ERROR: attribute to make sane with ("$what") unrecognized; must be one of "country", "currency", "language".} unless exists $attributes{$what};
  
  # Internal attributes start with underscores.
  my $internal_attribute = '_' . $what;
        
  croak "ERROR: can not make sane against $what, none has been set." unless $self->{$internal_attribute};
      
  delete $attributes{$what};

  if ($what eq 'country')
  {
    # Set the currency attribute with the currency used by the country attribute.
    $self->currency_code($self->{_country}->currency->code) if $self->{_currency} or $populate == 1;

    # Find the first language belonging to the country attribute that's
    # listed as official, and set it as the language attribute.
    if ($self->{_language} or $populate == 1)
    {
      $self->language_code_alpha2(
                                  @{$self->{_country}->languages_official}[0]->code_alpha2
                                 );
    }
  }
  elsif ($what eq 'language')
  {
    my $country;

    # If the country attribute exists, check if it uses the language. If so, pick it.
    if ($self->{_country})
    {
      foreach ($self->{_language}->countries)
      {
        $country = $_ if $self->{_country}->code_alpha2 eq $_->code_alpha2;
      }
    }
    
    unless (defined $country) 
    {
      # If no country attribute exists, pick the first country that uses
      # the language officially.
      foreach ($self->{_language}->countries)
      {
        if ($self->{_language}->official($_) eq 'true')
        {
          $country = $_;
          last;
        }
      }
    }     
    
    $self->country_code_alpha2($country->code_alpha2) if $self->{_country}  or $populate == 1;
    $self->currency_code($country->currency->code)    if $self->{_currency} or $populate == 1;
  }
  elsif ($what eq 'currency')
  {
    my ($country, $language);

    # Try and cross-reference against language.
    if ($self->{_language})
    {
      foreach ($self->{_language}->countries)
      {
        # If the currency of a country using our language
        # matches our currency attribute, pick that country.
        $country = $_ if ($_->currency->code eq $self->{_currency}->code)
      }
    }

    # If the preceding didn't find a country, get the first one to use the currency.    
    $country = @{$self->{_currency}->countries}[0] unless defined $country;

    # Get the first official language of that country.
    $language = @{$country->languages_official}[0];

    $self->country_code_alpha2($country->code_alpha2)   if $self->{_country}  or $populate == 1;
    $self->language_code_alpha2($language->code_alpha2) if $self->{_language} or $populate == 1;
  }
      
  $self;
}

# Remove attributes.
sub empty
{
  my $self      = shift;
  my $attribute = shift;

  $attribute = '_' . $attribute;
  
  # Make a hash of allowed attributes.
  my %valid = map { $_ => undef } qw( _country _currency _language );

  croak "ERROR: No attribute specified to empty." unless $attribute;
  croak qq{ERROR: Invalid attribute ("$attribute") specified to be emptied.} unless exists $valid{$attribute};

  delete $self->{$attribute};
  
  $self;
}

# Small methods that set or get object attributes.
# Could do with being refactored into an AUTOLOAD.

sub country_code_alpha2
{
  my $self = shift;  

  croak "No value given for country_code_alpha2" unless @_;

  $self->{_country} = Locale::Object::Country->new( code_alpha2 => shift );
}

sub country_code_alpha3
{
  my $self = shift;  
  
  croak "No value given for country_code_alpha3" unless @_;

  $self->{_country} = Locale::Object::Country->new( code_alpha3 => shift );
}

sub country_code_numeric
{
  my $self = shift;  
  
  croak "No value given for country_code_numeric" unless @_;

  $self->{_country} = Locale::Object::Country->new( code_numeric => shift );
}

sub country_name
{
  my $self = shift;  

  croak "No value given for country_name" unless @_;
  
  $self->{_country} = Locale::Object::Country->new( name => shift );
}

sub currency_code
{
  my $self = shift;  
  
  croak 'No value given for currency_code' unless @_;

  $self->{_currency} = Locale::Object::Currency->new( code => shift );
}

sub currency_code_numeric
{
  my $self = shift;  
  
  croak 'No value given for currency_code_numeric' unless @_;

  $self->{_currency} = Locale::Object::Currency->new( code_numeric => shift );
}

sub language_code_alpha2
{
  my $self = shift;  
  
  croak 'No value given for language_code' unless @_;

  $self->{_language} = Locale::Object::Language->new( code_alpha2 => shift );
}

sub language_code_alpha3
{
  my $self = shift;  
  
  croak 'No value given for language_code_alpha3' unless @_;

  $self->{_language} = Locale::Object::Language->new( code_alpha3 => shift );
}

sub language_name
{
  my $self = shift;  
  
  croak 'No value given for language_name' unless @_;

  $self->{_language} = Locale::Object::Language->new( name => shift );
}

sub language
{
  my $self = shift;
  
  return $self->{_language};
}

sub country
{
  my $self = shift;
  
  return $self->{_country};
}

sub currency
{
  my $self = shift;
  
  return $self->{_currency};
}

1;

__END__

=head1 NAME

Locale::Object - An object-oriented representation of locale information.

=head1 DESCRIPTION

The C<Locale::Object> group of modules attempts to provide locale-related information in an object-oriented fashion. The information is collated from several sources and provided in an accompanying L<DBD::SQLite> database.

At present, the modules are:

=over 4

=item * L<Locale::Object> - make compound objects containing country, currency and language objects

=item * L<Locale::Object::Country> - objects representing countries

=item * L<Locale::Object::Continent> - objects representing continents

=item * L<Locale::Object::Currency> - objects representing currencies

=item * L<Locale::Object::Currency::Converter>  - convert between currencies

=item * L<Locale::Object::DB> - does lookups for the modules in the database

=item * L<Locale::Object::Language> - objects representing languages

=back

For more information, see the documentation for those modules. The database is documented in L<Locale::Object::Database>. Locale::Object itself can be used to create compound objects containing country, currency and language objects.

=head1 SYNOPSIS

    use Locale::Object;
    
    my $obj = Locale::Object->new(
                                  country_code_alpha2  => 'gb',
                                  currency_code        => 'GBP',
                                  language_code_alpha2 => 'en'
                                 );

    $obj->country_code_alpha2('af');
    $obj->country_code_alpha3('afg');

    $obj->currency_code('AFA');
    $obj->currency_code_numeric('004');
    
    $obj->language_code_alpha2('ps');
    $obj->language_code_alpha3('pus');
    $obj->language_name('Pushto');
    
    my $country  = $obj->country;
    my $currency = $obj->currency;
    my $language = $obj->language;
    
    $obj->empty('language');
    
    print $obj->sane('country');

    $obj->make_sane(
                    attribute => 'country'
                    populate  => 1
                   );
    
=head1 METHODS

=head2 C<new()>

    my $obj = Locale::Object->new(
                                  country_code_alpha2  => 'gb',
                                  currency_code        => 'GBP',
                                  language_code_alpha2 => 'en'
                                 );

Creates a new object. With no parameters, the object will be blank. Valid parameters match the method names that follow.

=head2 C<country_code_alpha2(), country_code_alpha3()>

    $obj->country_code_alpha2('af');
    $obj->country_code_alpha3('afg');

Sets the country attribute in the object by alpha2 and alpha3 codes. Will create a new L<Locale::Object::Country> object and set that as the attribute. Because Locale::Object::Country objects all have single instances, if one has already been created by that code, it will be reused when you do this.
 
=head2 C<country_code(), currency_code_numeric()>

    $obj->currency_code('AFA');
    $obj->currency_code_numeric('004');

Serves the same purpose as the previous methods, only for the currency attribute, a L<Locale::Object::Currency> object.

=head2 C<language_code_alpha2(), language_code_alpha3(), language_name()>

    $obj->language_code_alpha2('ps');
    $obj->language_code_alpha3('pus');
    $obj->language_name('Pushto');

Serves the same purpose as the previous methods, only for the language attribute, a L<Locale::Object::Language> object.

=head1 Retrieving and Removing Attributes

=head2 C<country(), language(), currency()>

While the foregoing methods can be used to set attribute objects, to retrieve those objects' own attributes you will have to use their own methods. The C<country()>, C<language()> and C<currency()> methods return the objects stored as those attributes, if they exist.

    my $country_tzone = $country->timezone->name;
    my $language_name = $obj->language->name;
    my $currency_code = $obj->currency->code;
    
See L<Locale::Object::Country>, L<Locale::Object::Language> and L<Locale::Object::Currency> for more details on the subordinate methods.

=head2 C<empty()>

    $obj->empty('language');

Remove an attribute from the object. Can be one of C<country>, C<currency>, C<language>.

=head1 Object Sanity

=head2 C<sane()>

There will be occasions you want to know whether all the attributes in your object make sense with each other - questions such as "is the currency of the object used in the country?" or "Do they speak the language of the object in that country?" For that, use C<sane()>.

    print $obj->sane('country');
    
Returns 1 if the two remaining attributes in the object make sense compared against the attribute name you specify (if not specified, country is the default); otherwise, 0. The following table explains what's needed for a result of 1. Note: if an attribute doesn't exist, it's not *not* sane, so checking sanity against an attribute in an object with no other attributes will give a result of 1.

  If sane against | country must          | language must          | currency must
  -----------------------------------------------------------------------------------------
  country         | n/a                   | be used in the country | be used in the country
  -----------------------------------------------------------------------------------------
  language        | be using the language | n/a                    | be used in a country
                  |                       |                        | speaking the language
  -----------------------------------------------------------------------------------------
  currency        | use the currency      | be spoken in a country | n/a
                  |                       | using the currency     |
                  
=head2 C<make_sane()>

    $obj->make_sane(
                    attribute => 'country'
                    populate  => 1
                   );
    
This method will do its best to make the attributes of the object correspond with each other. The attribute you specify as a parameter will be taken to align against (default is country if none specified). If you specify C<populate> as 1, any empty attributes in the object will be filled. Provisos:

=over 4 

=item 1) Languages can be used in multiple countries. If you C<make_sane> against language, to pick a country the module will choose the first country it finds that uses the language officially.

=item 2) A similar situation exists for currencies. If a language attribute already exists, the module will pick the first country it finds that speaks the language and uses the currency. Otherwise, it will select the first country in its list of countries using the currency.

=back

=head1 AUTHOR

Originally by Earle Martin

=head1 COPYRIGHT AND LICENSE

Originally by Earle Martin. To the extent possible under law, the author has dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty. You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

=head1 SEE ALSO

L<Locale::Codes>, for simple conversions between names and ISO codes.

=cut
