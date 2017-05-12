package Test::Lingua::EO::Orthography::PurePerl;


# ****************************************************************
# pragma(s)
# ****************************************************************

use strict;
use warnings;
use utf8;


# ****************************************************************
# superclass(es)
# ****************************************************************

use base qw(
    Test::Class
    Test::Lingua::EO::Orthography::Base
);


# ****************************************************************
# test method(s)
# ****************************************************************

sub test_any : Tests {
    my $self = shift;

    $self->test_basic;

    $self->test_orthographize;
    $self->test_substitutize;
    $self->test_plurally_orthographize;

    $self->test_exception_on_sources;
    $self->test_exception_on_target;
    $self->test_exception_on_convert;

    $self->test_flughaveno;

    return;
}


# ****************************************************************
# return true
# ****************************************************************

1;
__END__


# ****************************************************************
# POD
# ****************************************************************

=head1 NAME

Test::Lingua::EO::Orthography::PurePerl -

=head1 SYNOPSIS

    use Test::Lingua::EO::Orthography::PurePerl;
    Test::Class->runtests;

=head1 DESCRIPTION

This class runs several test cases for
L<Lingua::EO::Orthography|Lingua::EO::Orthography>.

=head1 AUTHOR

=over 4

=item MORIYA Masaki, alias Gardejo

C<< <moriya at cpan dot org> >>,
L<http://gardejo.org/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 MORIYA Masaki, alias Gardejo

This module is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
See L<perlgpl|perlgpl> and L<perlartistic|perlartistic>.

The full text of the license can be found in the F<LICENSE> file
included with this distribution.

=cut
