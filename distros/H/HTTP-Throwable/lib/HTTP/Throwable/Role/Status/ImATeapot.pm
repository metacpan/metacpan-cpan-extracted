package HTTP::Throwable::Role::Status::ImATeapot;
our $AUTHORITY = 'cpan:STEVAN';
$HTTP::Throwable::Role::Status::ImATeapot::VERSION = '0.026';
use Types::Standard qw(Bool);

use Moo::Role;

with(
    'HTTP::Throwable',
);

has 'short' => (is => 'ro', isa => Bool, default => 0);
has 'stout' => (is => 'ro', isa => Bool, default => 0);

sub default_status_code { 418 }
sub default_reason      { q{I'm a teapot} }

my $TEAPOT = <<'END';
                       (
            _           ) )
         _,(_)._        ((     I'M A LITTLE TEAPOT__X__
    ___,(_______).        )
  ,'__.   /       \    /\_
 /,' /  |""|       \  /  /
| | |   |__|       |,'  /
 \`.|                  /
  `. :           :    /
    `.            :.,'
      `-.________,-'
END

sub text_body {
    my $self = shift;
    my $base = $TEAPOT;
    my $msg  = $self->short && $self->stout ? " SHORT AND STOUT"
             : $self->short                 ? " SHORT NOT STOUT"
             : $self->stout                 ? " MERELY STOUT"
             :                                " WITH A SPOUT";

    $base =~ s/__X__/$msg/;

    return $base;
}

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::ImATeapot - 418 I'm a teapot

=head1 VERSION

version 0.026

=head1 DESCRIPTION

This exception provides RFC2324 support, in accordance with section 2.3.3:

   Any attempt to brew coffee with a teapot should result in the error code
   "418 I'm a teapot".  The resulting entity body MAY be short and stout.

Boolean attributes C<short> and C<stout> are provided, and default to false.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: 418 I'm a teapot

#pod =head1 DESCRIPTION
#pod
#pod This exception provides RFC2324 support, in accordance with section 2.3.3:
#pod
#pod    Any attempt to brew coffee with a teapot should result in the error code
#pod    "418 I'm a teapot".  The resulting entity body MAY be short and stout.
#pod
#pod Boolean attributes C<short> and C<stout> are provided, and default to false.
#pod
