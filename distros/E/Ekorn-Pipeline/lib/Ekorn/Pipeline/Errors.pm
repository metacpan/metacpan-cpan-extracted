use v5.36;

package Ekorn::Pipeline::Errors;

use Carp     qw();
use Exporter qw(import);

use namespace::clean -except => 'import';

our @EXPORT_OK = qw(croakf);

# The packages Carp looks past, to croak at the line that called
# Ekorn::Pipeline. Each of them that croaks takes this list as its
# @CARP_NOT.
our @INTERNAL = qw(
    Ekorn::Pipeline         Ekorn::Pipeline::Errors
    Ekorn::Pipeline::Gather Ekorn::Pipeline::Pipes
    Ekorn::Pipeline::Stop
    Ekorn::Pipeline::Stages::Batch Ekorn::Pipeline::Stages::Flow
    Ekorn::Pipeline::Stages::Taps
);
our @CARP_NOT = @INTERNAL;

# Croak with a message made by sprintf from a format and its arguments,
# as croak itself would, at the same line: goto leaves no frame of its
# own for Carp to see. It's a sub without a signature, as goto passes @_.
sub croakf {    ## no critic (Subroutines::RequireArgUnpacking)
    my $format = shift;
    @_ = (sprintf $format, @_);
    goto &Carp::croak;
}

1;
__END__

=encoding utf8

=for stopwords croakf

=head1 NAME

Ekorn::Pipeline::Errors - report Ekorn::Pipeline's errors at the caller's line

=head1 SYNOPSIS

    use Ekorn::Pipeline::Errors qw(croakf);

    our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

    croakf 'Expected a count of 0 or more' unless $count =~ m( \A \d+ \z )xa;

=head1 DESCRIPTION

Ekorn::Pipeline reports its errors at the first line outside it, so
its user sees the line of their own code that caused them. Nothing is
exported by default.

C<croakf> is for modules of stages outside Ekorn::Pipeline too, such
as C<DBIx::Squirrel::Stages::Rows>. Called from a function that makes
a stage, it reports a mistake at the line that called the function,
with nothing more to set up. A C<%> in the message is written C<%%>.

A module of functions that take stages from their callers can put
C<@INTERNAL> in its own C<@CARP_NOT>, as in the synopsis. Then a stage
that dies is reported at the caller's line, where the stage was
written, not at the line in the module that ran the pipeline.

=head1 FUNCTIONS

=head2 croakf

    croakf 'Expected stage #%d to be a code reference or a pipeline', $n;

Croaks with a message made by C<sprintf> from a format and its
arguments, at the same line L<Carp/croak> would report.

Write the format as a literal in the code. Values go in as arguments,
through C<%s> and the like, never in the format. A format made from
data does whatever its C<%> directives say: C<%999999999s> makes a
string of a gigabyte.

=head1 VARIABLES

=head2 @INTERNAL

The packages of Ekorn::Pipeline. Each of its modules that croaks uses
this list as its C<@CARP_NOT>, so Carp looks past all of them to the
caller's line.

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Carp>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
