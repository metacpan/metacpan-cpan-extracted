package HTML::Acid::Buffer;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.3');

# Module implementation here

sub new {
    my $class = shift;
    my $self = {};
    $self->{tagname} = shift || '';
    $self->{text} = "";
    $self->{attr} = {};
    bless $self, $class;
    return $self;
}

sub get_attr {
    my $self = shift;
    return $self->{attr};
}

sub set_attr {
    my $self = shift;
    my $attr = shift;
    $self->{attr} = $attr;
}

sub state {
    my $self = shift;
    return $self->{text};
}

sub add {
    my $self = shift;
    $self->{text} .= shift;
    return;
}

sub stop {
    my $self = shift;
    my $tagname = $self->{tagname};
    my $results = $tagname ? "<$tagname" : '';
    my $text = $self->{text};
    foreach my $key (sort keys %{$self->{attr}}) {
        $results .= " $key=\"$self->{attr}->{$key}\"";
    }
    $results .= ($tagname ? ">$text</$tagname>" : $text);
    delete $self->{text};
    delete $self->{attr};
    return $results;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

HTML::Acid::Buffer - Temporary buffer for certain elements


=head1 VERSION

This document describes HTML::Acid::Buffer version 0.0.3

=head1 DESCRIPTION

This class is not used directly. See L<HTML::Acid>.

=head1 INTERFACE 

=head2 new

This takes a tag name as an argument. Without a tag name
it will behave as the top level buffer.

=head2 add

This takes new text content and adds it to the buffer.

=head2 stop

This returns the current state of the content and clears the
buffer.

=head2 state

This returns the current buffer.

=head2 get_attr

This gets the attribute hash.

=head2 set_attr

This sets the attribute hash.

=head1 AUTHOR

Nicholas Bamber  C<< <nicholas@periapt.co.uk> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Nicholas Bamber C<< <nicholas@periapt.co.uk> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
