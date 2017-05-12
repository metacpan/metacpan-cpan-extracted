package FormValidator::Simple::Struct::CharTypes;
use 5.008_001;
use strict;
use warnings;
use utf8;

our $VERSION = '0.18';

use base 'Exporter';
our @EXPORT= qw/CHARTYPE::HIRAGANA CHARTYPE::KATAKANA CHARTYPE::KANJI CHARTYPE::GREEK CHARTYPE::ASCII CHARTYPE::CYRILLIC CHARTYPE::MATH CHARTYPE::NUMBER CHARTYPE::ALPHABET CHARTYPE::PUNCTUATION/;

sub CHARTYPE::HIRAGANA{
    '^\x{3040}-\x{309F}';
}

sub CHARTYPE::KATAKANA{
    '^\x{30A0}-\x{30FF}\x{FF00}-\x{FFEF}';
}

sub CHARTYPE::KANJI{
    '^\x{4E00}-\x{9FFF}';
}

sub CHARTYPE::ASCII{
    '^\x{0000}-\x{007F}';
}

sub CHARTYPE::GREEK{
    '^\x{0370}-\x{03FF}';
}

sub CHARTYPE::NUMBER{
    '^\x{2150}-\x{218F}\x{0030}-\x{0039}';
}

sub CHARTYPE::ALPHABET{
    '^\x{0041}-\x{005A}^\x{0061}-\x{007A}';
}

sub CHARTYPE::CYRILLIC{
    '^\x{0400}-\x{04FF}';
}

sub CHARTYPE::MATH{
    '^\x{2200}-\x{22FF}';
}

sub CHARTYPE::PUNCTUATION{
    '^\x{2000}-\x{206F}';
}

1;

__END__

=head1 NAME

FormValidator::Simple::Struct::AllowChars - Plugin for FormValidator::Simple::Struct

=head1 VERSION

This document describes FormValidator::Simple::Struct::AllowChars version 0.18.

=head1 SYNOPSIS

 use FormValidator::Simple::Struct;
 $class = FormValidator::Simple::Struct->new;
 $class->load_plugin('FormValidator::Simple::Struct::AllowChars');

=head1 DESCRIPTION

This module provides some validate methods based on utf8 characters
 
 use Test::More;
 ok $class->NUMBER('100');
 ng $class->NUMBER('value');

=head1 INTERFACE

=head2 Functions

=head3 HIRAGANA 

=head3 KATAKANA 

=head3 KANJI 

=head3 GREEK 

=head3 ASCII 

=head3 CYRILLIC 

=head3 MATH 

=head3 NUMBER 

=head3 PUNCTUATION

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

S2 E<lt>s2otsa59@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, S2. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
