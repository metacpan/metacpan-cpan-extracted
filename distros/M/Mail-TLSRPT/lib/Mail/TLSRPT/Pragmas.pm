package Mail::TLSRPT::Pragmas;
# ABSTRACT: Setup system wide pragmas
our $VERSION = '1.20200305.1'; # VERSION
use 5.20.0;
use strict;
use warnings;
require feature;
use Import::Into;

use English;
use JSON;
use Types::Standard;
use Type::Utils;

use open ':std', ':encoding(UTF-8)';

sub import {
  strict->import;
  warnings->import;
  feature->import($_) for ( qw{ postderef signatures } );
  warnings->unimport($_) for ( qw{ experimental::postderef experimental::signatures } );

  Types::Standard->import::into(scalar caller, qw{ Str Int HashRef ArrayRef Enum } );
  Type::Utils->import::into(scalar caller, qw{ class_type } );
  English->import::into(scalar caller);
  JSON->import::into(scalar caller);
}

1;

