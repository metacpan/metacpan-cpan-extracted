## -*- Mode: CPerl -*-
##
## File: DiaColloDB::Compat.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DiaColloDB utilities: compatibility modules: top-level wrappers

package DiaColloDB::Compat;
#use DiaColloDB::Compat::v0_08;
#use DiaColloDB::Compat::v0_09;
use DiaColloDB::Logger;
use Carp;
use strict;

##==============================================================================
## Globals

our @ISA = qw(DiaColloDB::Logger);

##==============================================================================
## Utilities

## $bool = $that->usecompat($pkg)
##  + attempts to "use DiaColloDB::Compat::$pkg", throwing an error on failure
sub usecompat {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $pkg  = shift;
  (my $file = $pkg) =~ s{::}{/}g;
  $file   .= ".pm" if ($file !~ /\.pm$/);
  $file    = "DiaColloDB/Compat/$file" if ($file !~ m{^DiaColloDB/Compat/});
  my ($rc);
  eval { $rc = require $file };
  $that->logconfess("failed to load compatibility package $pkg".($@ ? ": $@" : '')) if ($@ || !$rc);
  return $rc;
}

## \&dummyMethodCode = $that->nocompat($methodName)
##   + wrapper for subclasses which do not implement some API methods
sub nocompat {
  my $that   = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : undef;
  my $method = shift;
  return sub {
    $_[0]->logconfess("method $method() not supported by compatibility wrapper");
  };
}

##==============================================================================
## Footer
1; ##-- be happy
