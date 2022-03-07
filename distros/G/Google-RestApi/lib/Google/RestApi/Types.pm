package Google::RestApi::Types;

# custom type constrants. see Type::Library.
# NOTE: can't use Google::RestApi::Setup here because that module imports this one.

use strict;
use warnings;

our $VERSION = '1.0.1';

use Types::Standard qw( Undef Str StrMatch Int ArrayRef HashRef Tuple HasMethods );

my @types = qw(
  ReadableDir ReadableFile
  EmptyArrayRef EmptyHashRef
  EmptyString Zero False
  HasApi
);

use Type::Library -base, -declare => @types;

use Exporter;
our %EXPORT_TAGS = (all => \@types);

my $meta = __PACKAGE__->meta;


$meta->add_type(
  name    => 'ReadableDir',
  parent  => Str->where( sub { -d -r; } ),
  message => sub { "Must point to a file system directory that's readable" },
);

$meta->add_type(
  name    => 'ReadableFile',
  parent  => Str->where( sub { -f -r; } ),
  message => sub { "Must point to a file that's readable" },
);



$meta->add_type(
  name    => 'EmptyArrayRef',
  parent  => ArrayRef->where( sub { scalar @$_ == 0; } ),
  message => sub { "Must be an empty array" },
);

$meta->add_type(
  name    => 'EmptyHashRef',
  parent  => HashRef->where( sub { scalar keys %$_ == 0; } ),
  message => sub { "Must be an empty hash" },
);

my $empty_string = $meta->add_type(
  name    => 'EmptyString',
  parent  => StrMatch[qr/^$/],
  message => sub { "Must be an empty string" },
);

my $zero = $meta->add_type(
  name    => 'Zero',
  parent  => Int->where( sub { $_ == 0; } ),
  message => sub { "Must be an int equal to 0" },
);

# TODO: perhaps add emptyarray and emptyhash to this?
my $false = $meta->add_type(
  name    => 'False',
  parent  => Undef | $zero | $empty_string,
  message => sub { "Must evaluate to false" },
);



$meta->add_type(
  name    => 'HasApi',
  parent  => HasMethods[qw(api)],
  message => sub { "Must be an api object"; }
);

__PACKAGE__->make_immutable;

1;
