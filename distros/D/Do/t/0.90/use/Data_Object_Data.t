use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Data

=abstract

Data-Object Data Extraction Class

=synopsis

  package Command;

  use Data::Object::Data;

  =help

  fetches results from the api

  =cut

  my $data = Data::Object::Data->new;

  my $help = $data->content('help');
  # fetches results ...

  my $token = $data->content('token');
  # token: the access token ...

  my $secret = $data->content('secret');
  # secret: the secret for ...

  my $flag = $data->contents('flag');
  # [,...]

  __DATA__

  =flag secret

  secret: the secret for the account

  =flag token

  token: the access token for the account

  =cut

=inherits

Data::Object::Base

=description

This package provides methods for parsing and extracting pod-like data sections
from any file or package. The pod-like syntax allows for using these sections
anywhere in the source code and Perl properly ignoring them.

=cut

use_ok "Data::Object::Data";

ok 1 and done_testing;
