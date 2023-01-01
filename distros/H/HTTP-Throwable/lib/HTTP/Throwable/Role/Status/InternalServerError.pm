package HTTP::Throwable::Role::Status::InternalServerError 0.028;
our $AUTHORITY = 'cpan:STEVAN';

use Types::Standard qw(Bool);

use Moo::Role;

with(
    'HTTP::Throwable',
    'StackTrace::Auto',
);

sub default_status_code { 500 }
sub default_reason      { 'Internal Server Error' }

has 'show_stack_trace' => ( is => 'ro', isa => Bool, default => 1 );

sub text_body {
    my ($self) = @_;

    my $out = $self->status_line;
    $out .= "\n\n" . $self->stack_trace->as_string
        if $self->show_stack_trace;

    return $out;
}

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::InternalServerError - 500 Internal Server Error

=head1 VERSION

version 0.028

=head1 DESCRIPTION

The server encountered an unexpected condition which prevented it
from fulfilling the request.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 ATTRIBUTES

=head2 show_stack_trace

This is a boolean attribute which by default is true and indicates
to the C<text_body> method whether or not to show the stack trace
in the output.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Ricardo Signes <cpan@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: 500 Internal Server Error

#pod =head1 DESCRIPTION
#pod
#pod The server encountered an unexpected condition which prevented it
#pod from fulfilling the request.
#pod
#pod =attr show_stack_trace
#pod
#pod This is a boolean attribute which by default is true and indicates
#pod to the C<text_body> method whether or not to show the stack trace
#pod in the output.
#pod
