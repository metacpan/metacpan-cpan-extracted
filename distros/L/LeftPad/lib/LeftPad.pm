use 5.008001;
use strict;
use warnings;

package LeftPad;
# ABSTRACT: Why should Node.js have all the fun?

our $VERSION = '0.003';

use base 'Exporter';
our @EXPORT = qw/leftpad/;

#pod =func leftpad
#pod
#pod     $string = leftpad( $string, $min_length );
#pod     $string = leftpad( $string, $min_length, $pad_char );
#pod
#pod Returns a copy of the input string with left padding if the input string
#pod length is less than the minimum length.  It pads with spaces unless given a
#pod pad character as a third argument.
#pod
#pod Zero or negative minimum length returns the input string.  Only the first
#pod character in the pad-character string is used.  Undefined warnings are
#pod suppressed so an undefined input string is treated as an empty string.
#pod
#pod =cut

sub leftpad {
    no warnings 'uninitialized';
    return "" . $_[0] if $_[1] < 1;
    return sprintf( "%*s", $_[1], $_[0] ) unless defined $_[2] && length $_[2];
    return substr( $_[2], 0, 1 ) x ( $_[1] - length $_[0] ) . $_[0];
}

1;


# vim: ts=4 sts=4 sw=4 et tw=75:

__END__

=pod

=encoding UTF-8

=head1 NAME

LeftPad - Why should Node.js have all the fun?

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use LeftPad;

    $string = leftpad( $string, $min_length );
    $string = leftpad( $string, $min_length, $pad_char );

=head1 DESCRIPTION

This module provides left padding, just like you'd find for Node.js.

=head1 STABILITY

So that people may depend on this module for their production code,
the author commits to never delete it from CPAN.

=head1 FUNCTIONS

=head2 leftpad

    $string = leftpad( $string, $min_length );
    $string = leftpad( $string, $min_length, $pad_char );

Returns a copy of the input string with left padding if the input string
length is less than the minimum length.  It pads with spaces unless given a
pad character as a third argument.

Zero or negative minimum length returns the input string.  Only the first
character in the pad-character string is used.  Undefined warnings are
suppressed so an undefined input string is treated as an empty string.

=head1 SEE ALSO

=over 4

=item *

L<String::Pad>

=item *

L<Text::Padding>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/LeftPad/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/LeftPad>

  git clone https://github.com/dagolden/LeftPad.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
