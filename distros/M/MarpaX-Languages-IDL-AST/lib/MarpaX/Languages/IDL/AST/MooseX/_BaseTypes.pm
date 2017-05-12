use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::IDL::AST::MooseX::_BaseTypes;

# ABSTRACT: MooseX-IDL base types mapping

our $VERSION = '0.007'; # VERSION

use MooseX::Types -declare => [
                               qw/_floatingPtType
                                  _nativeFloatingPtType
                                  _signedShortInt
                                  _signedLongInt
                                  _signedLonglongInt
                                  _unsignedShortInt
                                  _unsignedLongInt
                                  _unsignedLonglongInt
                                  _charType
                                  _wideCharType
                                  _stringType
                                  _wideStringType
                                  _booleanType
                                  _octetType
                                  _objectType
                                  _valueBaseType
                                  _anyType/];
use MooseX::Types::Moose qw/Int Str Bool Object Any Num/;

class_type _floatingPtType,      { class => 'Math::BigFloat' };
subtype    _nativeFloatingPtType,as Num;
subtype    _signedShortInt,      as Int, where { ($_ >= -2**15) && ($_ <= (2**15 - 1))};
subtype    _signedLongInt,       as Int, where { ($_ >= -2**31) && ($_ <= (2**31 - 1))};
subtype    _signedLonglongInt,   as Int, where { ($_ >= -2**63) && ($_ <= (2**63 - 1))};
subtype    _unsignedShortInt,    as Int, where { ($_ >=      0) && ($_ <= (2**16 - 1))};
subtype    _unsignedLongInt,     as Int, where { ($_ >=      0) && ($_ <= (2**32 - 1))};
subtype    _unsignedLonglongInt, as Int, where { ($_ >=      0) && ($_ <= (2**64 - 1))};
subtype    _charType,            as Str, where { length($_) == 1 && ord(substr($_, 0, 1)) <= 255 };
subtype    _wideCharType,        as Str, where { length($_) == 1 };
subtype    _stringType,          as Str, where { my $str = $_; ! grep {ord(substr($str, $_, 1)) > 255} (0..length($_)) };
subtype    _wideStringType,      as Str;
subtype    _booleanType,         as Bool;
subtype    _octetType,           as Int, where { $_ >= 0 && $_ <= 255 };
subtype    _objectType,          as Object;
subtype    _valueBaseType,       as Object;
subtype    _anyType,             as Any;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::IDL::AST::MooseX::_BaseTypes - MooseX-IDL base types mapping

=head1 VERSION

version 0.007

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
