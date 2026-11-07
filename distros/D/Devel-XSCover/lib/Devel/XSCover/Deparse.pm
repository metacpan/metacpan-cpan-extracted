package Devel::XSCover::Deparse;

use 5.020;
use strict;
use warnings;

use B ();
use B::Deparse ();

our $VERSION = '0.09';

our ($ORIGINAL, $CUSTOM);

BEGIN {
    $CUSTOM = B::opnumber('custom');
    $ORIGINAL = \&B::Deparse::AUTOLOAD;
    package
        B::Deparse;
    no warnings 'redefine';
    *B::Deparse::AUTOLOAD = sub {
        our $AUTOLOAD;
        if ($AUTOLOAD =~ /::pp_/ && @_ > 1 && ref $_[1] && $_[1]->can('type') && $_[1]->type == $Devel::XSCover::Deparse::CUSTOM) {
            return Devel::XSCover::Deparse::custom(@_);
        }
        goto &$Devel::XSCover::Deparse::ORIGINAL;
    };
}

sub custom {
    my ($self, $op, $cx) = @_;
    my @kids;
    if ($op->can('first') && ($op->flags & B::OPf_KIDS())) {
        for (my $kid = $op->first; ref $kid && !$kid->isa('B::NULL'); $kid = $kid->sibling) {
            next if $kid->name eq 'pushmark';
            push @kids, $self->deparse($kid, 6);
        }
    }
    return $op->name . '(' . join(', ', @kids) . ')';
}

1;

__END__

=head1 NAME

Devel::XSCover::Deparse - a deparse for custom ops that have none

=head1 SYNOPSIS

    perl -MDevel::XSCover::Deparse -MDevel::Cover ...

=head1 DESCRIPTION

Devel::Cover writes the text of every branch and condition it finds through
B::Deparse, which deparses each op by a method named after the op. A custom op
of a module that ships no such method falls to B::Deparse's own fallback, a
warning of an unexpected custom op and C<XXX> as the text, once for every line
the op sits on. Loaded before the run, this module takes that fallback: a custom
op without a method of its own deparses as its name with its deparsed kids in
parentheses, C<frob($x, 1)>, and nothing else changes. The replacement is compiled in
B::Deparse's own package, since perl sets C<$AUTOLOAD> in the package of the
sub it calls, and that package statement is split over two lines so the CPAN
indexer does not read it as a claim on B::Deparse. A module that ships
C<B::Deparse::pp_frob> for its op is still the one asked first. L<xs_cover> loads
this into every covered process.

=head1 FUNCTIONS

=head2 custom

    my $text = Devel::XSCover::Deparse::custom($deparser, $op, $cx);

The deparse of a custom op by its name and kids.

=head1 SEE ALSO

L<Devel::XSCover>, L<B::Deparse>

=cut
