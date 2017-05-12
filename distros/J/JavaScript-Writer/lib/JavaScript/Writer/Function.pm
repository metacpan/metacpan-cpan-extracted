package JavaScript::Writer::Function;

use strict;
use warnings;
use 5.008;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw[ name body ]);

use overload '""' => \&as_string;

our $VERSION = '0.0.2';

use JavaScript::Writer::Block;

sub new {
    my $class = shift;

    my $self = bless {}, $class;
    if (ref($_[0]) eq 'CODE') {
        $self->body($_[0]);
    }
    else {
        my %args = @_;
        while ( my ($k, $v) = each %args) {
            $self->$k($v);
        }
    }

    return $self;
}

sub arguments {
    my ($self, @args) = @_;
    if (@args) {
        $self->{arguments} = \@args;
        return $self;
    }
    return @{$self->{arguments}||[]}
}

sub as_string {
    my $self = shift;
    my $sub = $self->body;
    my $function_body = JavaScript::Writer::Block->new;
    $function_body->body($self->body);
    my $name = $self->name ? " $self->{name}" : "";
    my $args = join(",", $self->arguments);
    return "function${name}($args)${function_body}";
}

1;
__END__

=head1 NAME

JavaScript::Writer::Function - JavaScript function definition generation from Perl.

=head1 SYNOPSIS

    my $js = JavaScript::Writer::Function->new();

    $js->name("salut");

    $js->body(sub {
        my $js = shift;
        $js->alert("Nihao");
    })

    print $js->as_string;

    # function salut(){alert("Foo");}

=head1 DESCRIPTION

This module is designed to be the object that outputs a function
declarition. The object overload the stringify operation to call its
as_string() method as its basic syntatic sugar.

=head1 INTERFACE

=over

=item new()

Constructor. Accepts nothing and gives you an object.

=item name($str)

Specify the function name.

=item arguments( $arg1, $arg2, ... )

Spicify the arguments of current function definition. Each argument is
a string of variable name in javascript.

=item body( $code_ref )

The passed $code_ref is a callback to generate the function
body. It'll be passed in a JavaScript::Writer object so you can use it
to write more javascript statements. This function is the one that
generates the function body when you call
C<JavaScript::Writer::function()>

=item as_string

Output current function definition as a string.

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
