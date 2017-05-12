package Locale::Object::Language;

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
    qw( code_alpha2 code_alpha3 name );
  
  # Go no further if the specified parameter wasn't one.
  croak "Error: You can only specify an alpha2 or alpha3 code or language name for initialization." unless exists $allowed_params{$parameter};

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
                                    table         => 'language',
                                    result_column => '*',
                                    search_column => $parameter,
                                    value         => $value
                                   );

  croak "Error: Unknown $parameter given for initialization: $value" unless $result;

  if (defined @{$result}[0])
  {  
    # Get values from our query.
    my $code_alpha2 = @{$result}[0]->{'code_alpha2'};
    my $code_alpha3 = @{$result}[0]->{'code_alpha3'};
    my $name        = @{$result}[0]->{'name'}; 
      
    # Check for pre-existing objects. Return it if there is one.
    my $enguage = $self->exists($code_alpha3);
    return $enguage if $enguage;
  
    # If not, make a new object.
    _make_language($self, $code_alpha2, $code_alpha3, $name);
    
    # Register the new object.
    $self->register();
  
    # Return the object.
    $self;
  }
  else
  {
    carp "Warning: No result found in language table for '$value' in $parameter.";
    return;
  }

}

# Check if objects exist.
sub exists {
  my $self = shift;
  
  # Check existence of a object with the given parameter or with
  # the code of the current object.
  my $code_alpha3 = shift || $self->code_alpha3;

  # Return the singleton object, if it exists.
  $existing->{$code_alpha3};
}

# Register the object in our hash of existing objects.
sub register {
  my $self = shift;

  # Do nothing unless the object exists.
  my $code_alpha3 = $self->code_alpha3 or return;
  
  # Put the current object into the singleton hash.
  $existing->{$code_alpha3} = $self;
}

sub _make_language
{
  my $self       = shift;
  my @attributes = @_;

  # The second attribute we get is the alpha3 language code.
  my $code = $attributes[1];
  
  # The attributes we want to set.
  my @attr_names = qw(code_alpha2 code_alpha3 name);
  
  # Initialize a loop counter.
  my $counter = 0;
  
  foreach my $current_attribute (@attr_names)
  {
    # Set the attributes of the entry for this currency code in the singleton hash.
    $self->$current_attribute( $attributes[$counter] );

    $counter++; 
  }

}

# Method for retrieving all countries using this language
sub countries
{
    my $self = shift;
    
    # Check for countries attribute. Set it if we don't have it.
    _set_countries($self) if $self->{_name};
    
    # Give an array if requested in array context, otherwise a reference.    
    return @{$self->{_countries}} if wantarray;    
    return $self->{_countries};
}

# Private method to set an attribute with a hash of objects for all countries using this currency.
sub _set_countries
{
    my $self = shift;
    my $code = $self->{_code_alpha3};

    # Do nothing if the list already exists.
    return if $existing->{$code}->{'_countries'};

    # If it doesn't, find all countries using this currency and put them in a hash.
    my @countries;

    my $result = $db->lookup(
                                      table         => 'language_mappings', 
                                      result_column => 'country', 
                                      search_column => 'language',
                                      value         => $code
                                     );
    
    # Create new country objects and put them into an array.
    foreach my $where (@{$result})
    {
      my $country_code = $where->{'country'};
      my $obj = Locale::Object::Country->new( code_alpha2 => $country_code );
      push @countries, $obj;
    }
    
    # Set a reference to that array as an attribute.
    $self->{'_countries'} = \@countries;       
}

# Get/set attributes.

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

sub official
{
  my $self      = shift;
  my $where     = shift;
  my $selected  = $self->code_alpha3;
    
  croak "Error: you can only pass official() a Locale::Object::Country object." unless $where->isa('Locale::Object::Country');

  my $country = $where->code_alpha2; 

  my $count = 0;

  # For each language used in the country...

  my @langs = ($where->languages);
  
  my %used_langs = map { $_->code_alpha3 => $_ } @langs;

  croak qq{ERROR: Language "$selected" is not used in } . $where->name . '.' unless exists $used_langs{$selected};

  my $result = $db->lookup_dual(
                              table      => 'language_mappings', 
                              result_col => 'official', 
                              col_1      => 'country', 
                              val_1      => $country,
                              col_2      => 'language',
                              val_2      => $selected
                             );

  return @{$result}[0]->{'official'};
}

1;

__END__

=head1 NAME

Locale::Object::Language - language information objects

=head1 DESCRIPTION

C<Locale::Object::Language> allows you to create objects containing information about languages such as their ISO codes, the countries they're used in and so on.

=head1 SYNOPSIS

    use Locale::Object::Language;

    my $eng = Locale::Object::Language->new( code_alpha3 => 'eng' );

    my $name        = $eng->name;
    my $code_alpha2 = $eng->code_alpha2;
    my $code_alpha3 = $eng->code_alpha3;
    
    my @countries = $eng->countries;

    my $gb  = Locale::Object::Country->new(  code_alpha2 => 'gb'  );

    print $eng->official($gb); 

=head1 METHODS

=head2 C<new()>

    my $eng = Locale::Object::Language->new( code_alpha3 => 'eng' );

The C<new> method creates an object. It takes a single-item hash as an argument - valid options to pass are ISO 3166 values - 'code_alpha2', 'code_alpha3' and 'name' (see L<Locale::Object::DB::Schemata> for details on these).

The objects created are singletons; if you try and create a currency object when one matching your specification already exists, C<new()> will return the original one.

=head2 C<name(), code_alpha2(), code_alpha3()>

    my $name = $country->name;
    
These methods retrieve the values of the attributes in the object whose name they share.

=head2 C<countries()>

    my @countries = $eng->countries;

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

=head2 C<official()>

    my $gb = Locale::Object::Country->new(  code_alpha2 => 'gb'  );

    print $eng->official($gb);  # prints 'true'

Give this method a L<Locale::Object::Country> object, and it will return a 'true' or 'false' value for whether the country the object represents has the language represented by your C<Locale::Object::Language> object as an official language. See L<database.pod> for a note about languages in the database.

=head1 OBSOLETE LANGUAGE CODES

ISO 639 is not immune from change, and there are three codes that changed in 1995: Hebrew (C<he>, was C<iw>), Indonesian (C<id>, was C<in>) and Yiddish (C<yi>, formerly C<ji>). Because the database maintains a one-to-one mapping, the old codes aren't included; if you need to support them for some reason (apparently Java versions previous to 1.4 use 'iw', for example), you'll have to alias them yourself. Thanks to Robin Szemeti (RSZEMETI) for bringing this to my attention.

=head1 KNOWN BUGS

The database of language information is not perfect by a long stretch. In particular, numerous comparatively obscure secondary or regional languages that don't have ISO codes, such as in several African countries and India, are missing. (See note in L<database.pod> about data sources.) Please send any corrections to the author.

=head1 AUTHOR

Originally by Earle Martin

=head1 COPYRIGHT AND LICENSE

Originally by Earle Martin. To the extent possible under law, the author has dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty. You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

=cut

