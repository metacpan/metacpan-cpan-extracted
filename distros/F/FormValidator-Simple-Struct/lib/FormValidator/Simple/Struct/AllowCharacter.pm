package FormValidator::Simple::Struct::AllowCharacter;
use 5.008_001;
use strict;
use warnings;
use utf8;

our $VERSION = '0.18';

use base 'Exporter';
our @EXPORT= qw/ALLOWCHARACTER::SPACE/;

sub ALLOWCHARACTER::SPACE{
    '\s';
}

1;

__END__

=head1 NAME

FormValidator::Simple::Struct::AllowCharacter

=head1 VERSION

This document describes FormValidator::Simple::Struct::AllowCharacters version 0.18.

=head1 SYNOPSIS

 use FormValidator::Simple::Struct;
 $class = FormValidator::Simple::Struct->new;
 $class->load_plugin('FormValidator::Simple::Struct::AllowChars');

=head1 DESCRIPTION

This module provides some validate methods based on utf8 characters
 

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

Copyright (c) 2013, S2. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
