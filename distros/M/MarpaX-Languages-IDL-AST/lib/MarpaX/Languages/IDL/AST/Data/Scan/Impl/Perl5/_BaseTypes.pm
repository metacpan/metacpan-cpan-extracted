use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::IDL::AST::Data::Scan::Impl::Perl5::_BaseTypes;

# ABSTRACT: IDL Base Types library

our $VERSION = '0.007'; # VERSION

# AUTHORITY

use Type::Library
  -base,
  -declare => qw/IDL_floatingPtType
                 IDL_nativeFloatingPtType
                 IDL_signedShortIntType
                 IDL_signedLongIntType
                 IDL_signedLonglongIntType
                 IDL_unsignedShortIntType
                 IDL_unsignedLongIntType
                 IDL_unsignedLonglongIntType
                 IDL_charType
                 IDL_wideCharType
                 IDL_stringType
                 IDL_wideStringType
                 IDL_booleanType
                 IDL_octetType
                 IDL_objectType
                 IDL_valueBaseType
                 IDL_anyType/;
use Type::Utils -all;
use Types::Standard -types;

my %INT_RANGES = (
              IDL_signedShortIntType      => [ -2**15, 2**15 - 1 ],
              IDL_signedLongIntType       => [ -2**31, 2**31 - 1 ],
              IDL_signedLonglongIntType   => [ -2**63, 2**63 - 1 ],
              IDL_unsignedShortIntType    => [      0, 2**16 - 1 ],
              IDL_unsignedLongIntType     => [      0, 2**32 - 1 ],
              IDL_unsignedLonglongIntType => [      0, 2**64 - 1 ],
              IDL_octetType               => [      0,       255 ]
             );

sub _rangeMessage {
  my ($thisType, $baseType, $value) = @_;

  my ($min, $max) = @{$INT_RANGES{$thisType}};
  return $baseType->get_message($value) if ! $baseType->check($value);
  return "$value < $min ($thisType minimum)" if $value < $min;
  return "$value > $max ($thisType maximum)" if $value > $max;
  return 'Unknown reason (!?)'
}

sub _rangeCheckInlined {
  my ($thisType, $constraint, $varname) = @_;

  my ($min, $max) = @{$INT_RANGES{$thisType}};
  return $constraint->parent->inline_check($varname) . " && ($varname >= $min) && ($varname <= $max)"
}

sub _rangeCheck {
  my ($thisType, $value) = @_;

  my ($min, $max) = @{$INT_RANGES{$thisType}};
  return ($value >= $min) && ($value <= $max)
}

class_type IDL_floatingPtType,        { class => 'Math::BigFloat' };
declare    IDL_nativeFloatingPtType,  as Num;
#
# Ranges all share the same declaration syntax
#
foreach my $type (keys %INT_RANGES) {
  declare $type, as Int,
    where     { return _rangeCheck       ($type, $_)      },
    inline_as { return _rangeCheckInlined($type, @_)      },
    message   { return _rangeMessage     ($type, Int, $_) }
}
declare IDL_charType,
  as Str,
  where {
    return (length($_) == 1) && (ord($_) <= 255)
  },
  inline_as {
    my ($constraint, $varname) = @_;
    return $constraint->parent->inline_check($varname) . " && (length($varname) == 1) && (ord($varname) <= 255)"
  },
  message {
    return Str->get_message($_) if ! Str->check($_);
    my $oups;
    return "length must be 1 instead of $oups" if (($oups = length($_)) != 1);
    return "ordinal must be <= 255 instead of ".  sprintf('0x%x', $oups) if (($oups = ord($_)) > 255);
    return 'Unknown reason (!?)'
  };

declare IDL_wideCharType,
  as Str,
  where {
    return length($_) == 1
  },
  inline_as {
    my ($constraint, $varname) = @_;
    return $constraint->parent->inline_check($varname) . " && (length($varname) == 1)"
  },
  message {
    return Str->get_message($_) if ! Str->check($_);
    my $oups;
    return "length must be 1 instead of $oups" if ($oups = length($_)) != 1;
    return 'Unknown reason (!?)'
  };
declare IDL_stringType,
  as Str,
  where {
    my $rc = 1;
    foreach (split('', $_)) {
      if (ord($_) > 255) {
        $rc = undef;
        last
      }
    }
    return $rc
  },
  inline_as {
    my ($constraint, $varname) = @_;
    return $constraint->parent->inline_check($varname) . " && do {my \$rc = 1; foreach (split('', $varname)) { if (ord(\$_) > 255) { \$rc = undef; last } } \$rc }"
  },
  message {
    return Str->get_message($_) if ! Str->check($_);
    my ($pos, $oups) = (0, undef);
    foreach (split('', $_)) {
      last if (($oups = ord($_)) > 255);
      ++$pos
    }
    return "must not contain any ordinal > 255, but has ordinal " . sprintf('0x%x', $oups) . " at position $pos" if ($oups);
    return 'Unknown reason (!?)';
  };
declare    IDL_wideStringType,      as Str;
declare    IDL_booleanType,         as Bool;
declare    IDL_objectType,          as Object;
declare    IDL_valueBaseType,       as Object;
declare    IDL_anyType,             as Any;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::IDL::AST::Data::Scan::Impl::Perl5::_BaseTypes - IDL Base Types library

=head1 VERSION

version 0.007

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
