package JavaScript::Writer::Block;

use strict;
use warnings;
use v5.8.0;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw[ body ]);

use overload '""' => \&as_string;

our $VERSION = '0.0.1';

use JavaScript::Writer;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub as_string {
    my $self = shift;
    my $sub = $self->body;
    my $body = sub {
        my ($js) = @_;
        $sub->($js);
        return $js;
    }->(JavaScript::Writer->new);
    return "{${body}}";
}

1;

__END__

=head1 NAME

JavaScript::Writer::Block - JavaScript code block generation from Perl.

=head1 SYNOPSIS

    my $js = JavaScript::Writer::Block->new();

    $js->body(sub {
        my $js = shift;
        $js->alert("Nihao");
    })

    print $js->as_string;

    # {alert("Foo");}

=head1 DESCRIPTION

This module is designed to be the object that outputs a block of
javascript code. A block in javascript is a region wrapped by C<{}>.
This module is used internally in various places. For example, to
generate function body, or to generate the code block for "if" and
"while" control structure.

The object overload the stringify operation to call its as_string()
method as its basic syntatic sugar.

=head1 INTERFACE

=over

=item new()

Constructor. Accepts nothing and gives you an object.

=item body( $code_ref )

The passed $code_ref is a callback to generate the function
body. It'll be passed in a JavaScript::Writer object so you can use it
to write more javascript statements.

=item as_string

Output current block of javascript code as a string. This string
will always be wrapped inside a pair of C<{}>.

=back


=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-javascript-writer@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Kang-min Liu C<< <gugod@gugod.org> >>.

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
