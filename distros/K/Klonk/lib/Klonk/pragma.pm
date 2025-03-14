package Klonk::pragma 0.01;
use strict;
use warnings;
use warnings FATAL => qw(uninitialized);
use constant MIN_PERL_VERSION => '5.36';
no feature ':all';
use feature ':' . MIN_PERL_VERSION;
no feature qw(bareword_filehandles);
use Function::Parameters 2;

use Carp ();

method import($class: @items) {
    for my $item (@items) {
        Carp::croak qq("$item" is not exported by the $class module);
    }

    strict->import;
    warnings->import;
    warnings->import(FATAL => 'uninitialized');
    feature->unimport(':all');
    feature->import(':' . MIN_PERL_VERSION);
    feature->unimport('bareword_filehandles');
    Function::Parameters->import;
}

1
__END__

=head1 NAME

Klonk::pragma - enable/disable common perl features

=head1 SYNOPSIS

    use Klonk::pragma;
    ## equivalent to:
    # use v5.36;
    # use warnings 'all', FATAL => 'uninitialized';
    # no feature 'bareword_filehandles';
    # use Function::Parameters 2;

=head1 DESCRIPTION

Loading this module automatically enables L<strict>, L<warnings> (while making
C<uninitialized> warnings a fatal error), the C<:5.36> L<feature> bundle (but
disables C<bareword_filehandles>), and L<Function::Parameters> in the current
lexical scope.
