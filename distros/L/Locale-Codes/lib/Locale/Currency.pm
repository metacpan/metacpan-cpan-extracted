package Locale::Currency;
# Copyright (C) 2001      Canon Research Centre Europe (CRE).
# Copyright (C) 2002-2009 Neil Bowers
# Copyright (c) 2010-2025 Sullivan Beck
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# This file was automatically generated.  Any changes to this file will
# be lost the next time 'gen_mods' is run.
#    Generated on: Sun Jun  1 17:54:14 EDT 2025

use strict;
use warnings;
require 5.006;
use Exporter qw(import);

our($VERSION,@EXPORT);
$VERSION='3.84';

################################################################################
use if $] >= 5.027007, 'deprecate';
use Locale::Codes;
use Locale::Codes::Constants;

@EXPORT    = qw(
                code2currency
                code2currencys
                currency2code
                all_currency_codes
                all_currency_names
                currency_code2code
               );
push(@EXPORT,@Locale::Codes::Constants::CONSTANTS_CURRENCY);

our $obj = new Locale::Codes('currency');
$obj->show_errors(0);

sub show_errors {
   my($val) = @_;
   $obj->show_errors($val);
}

sub code2currency {
   return $obj->code2name(@_);
}

sub code2currencys {
   return $obj->code2names(@_);
}

sub currency2code {
   return $obj->name2code(@_);
}

sub currency_code2code {
   return $obj->code2code(@_);
}

sub all_currency_codes {
   return $obj->all_codes(@_);
}

sub all_currency_names {
   return $obj->all_names(@_);
}

sub rename_currency {
   return $obj->rename_code(@_);
}

sub add_currency {
   return $obj->add_code(@_);
}

sub delete_currency {
   return $obj->delete_code(@_);
}

sub add_currency_alias {
   return $obj->add_alias(@_);
}

sub delete_currency_alias {
   return $obj->delete_alias(@_);
}

sub rename_currency_code {
   return $obj->replace_code(@_);
}

sub add_currency_code_alias {
   return $obj->add_code_alias(@_);
}

sub delete_currency_code_alias {
   return $obj->delete_code_alias(@_);
}

1;
