use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Data

=abstract

Data-Object Data Extraction Class

=synopsis

  use Data::Object::Data;

  my $data = Data::Object::Data->new;

This example is extracting from the main package.

  use Data::Object::Data;

  my $data = Data::Object::Data->new(from => 'Example::Package');

This example is extracting from a class.

  use Data::Object::Data;

  my $data = Data::Object::Data->new(file => 'lib/Example/Package.pm');

This example is extracting from a file.

  use Data::Object::Data;

  my $data = Data::Object::Data->new(data => [,"..."]);

This example is extracting from existing data.

  package Command;

  use Data::Object::Data;

  =pod help

  fetches results from the api

  =cut

  my $data = Data::Object::Data->new(
    from => 'Command'
  );

  my $help = $data->content('help');
  # fetches results ...

  my $token = $data->content('token');
  # token: the access token ...

  my $secret = $data->content('secret');
  # secret: the secret for ...

  my $flags = $data->contents('flag');
  # [,...]

  __DATA__

  =flag secret

  secret: the secret for the account

  =flag token

  token: the access token for the account

  =cut

=inherits

Data::Object::Base

=libraries

Data::Object::Library

=description

This package provides methods for parsing and extracting pod-like data sections
from any file or package. The pod-like syntax allows for using these sections
anywhere in the source code and Perl properly ignoring them.

=cut

use_ok "Data::Object::Data";

ok 1 and done_testing;
