package JavaScript::Code::Expression::Op::Term;

use strict;
use vars qw[ $VERSION ];
use base qw[ JavaScript::Code::Expression::Op ];

$VERSION = '0.03';

=head1 NAME

JavaScript::Code::Expression::Op::Term

=head1 METHODS

=head2 new

=cut

sub new {
    my $obj   = shift;
    my $class = ref $obj || $obj;

    die("'$class' takes excatly 1 operand.")
      unless @_ == 1;

    return bless [@_], $class;
}

=head2 $self->precedence( )

=cut

sub precedence { return 1000; }

=head2 $self->output( )

=cut

sub output     { return shift->[0]; }

=head1 SEE ALSO

L<JavaScript::Code>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
