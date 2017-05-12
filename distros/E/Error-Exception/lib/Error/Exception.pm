# Copyright (C) 2008 Stephen Vance
# 
# This library is free software; you can redistribute it and/or
# modify it under the terms of the Perl Artistic License.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the Perl
# Artistic License for more details.
# 
# You should have received a copy of the Perl Artistic License along
# with this library; if not, see:
#
#       http://www.perl.com/language/misc/Artistic.html
# 
# Designed and written by Stephen Vance (steve@vance.com) on behalf
# of The MathWorks, Inc.

package Error::Exception;

use strict;
use warnings;

use Exception::Class;
use base qw( Error Exception::Class::Base );

our $VERSION = '1.1';

# This "no critic" is open because I couldn't find the policy name
sub new { ## no critic
    my $class = shift;

    local $Error::Depth = $Error::Depth + 1; ## no critic 'Dynamic::ValidateAgainstSymbolTable'

    my $self = $class->SUPER::new(@_);

    $self->{'-text'} = $self->_stringify();
    return $self;
}

sub _stringify {     
    my $self = shift;
    
    my $text = ref( $self ) . ' thrown in ' . $self->file
                . ' at line ' .  $self->line . "\n";
    my $msg = $self->{'-text'};
    if( defined( $msg ) && length( $msg ) > 0 ) {
        $text .= "with message <<" . $msg . ">>\n";
    }

    my @fields = $self->Fields();
    if( scalar @fields > 0 ) {
        $text .= "with fields:\n";
        for my $field ( @fields ) {
            my $value = $self->$field();
            if( ! defined( $value ) ) {
                $value = 'undef';
            }
            elsif( ref( $value ) eq 'ARRAY' ) {
                $value = '[ ' . join( "\n", @{$value} ) . ' ]';
            }
            # Don't expect hashes or objects
            $text .= "\t" . $field . " = '" . $value . "'\n";
        }
    }

    return $text;
}

1;
__END__

=head1 NAME

Error::Exception - Combines Error and Exception::Class with correct stringication

=head1 SYNOPSIS

A base exception class that combines the functionality of
the Error and Exception::Class packages and stringifies properly when uncaught
even in Test::Unit context.

=head1 FUNCTIONS

=head2 new

Instantiates the object and handles the initialization of the base classes
properly.

=head2 stringify

Converts a derived exception into a usable string for debugging.

=head3 Throws

Nothing

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-error-exception at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Error-Exception>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Error::Exception

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Error-Exception>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Error-Exception>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Error-Exception>

=item * Search CPAN

L<http://search.cpan.org/dist/Error-Exception>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT

Copyright 2008 Stephen Vance, all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
