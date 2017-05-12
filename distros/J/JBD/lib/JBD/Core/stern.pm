package JBD::Core::stern;
# ABSTRACT: exports warnings and strict; also provides puke() and barf()
our $VERSION = '0.04'; # VERSION

#/ Warnings and strict.
#/ @author Joel Dalley
#/ @version 2013/Oct/26

use strict;
use warnings;
use Data::Dumper();

sub puke {
    my $chunks = @_ > 1 ? [@_] : shift;
    print Data::Dumper::Dumper $chunks;
}

sub barf { puke @_; exit }

sub import {
    shift if (ref $_[0] || $_[0] || '') eq __PACKAGE__;

    no strict 'refs';
    my $depth = shift || 0;
    *{(caller($depth))[0] ."::$_"} = *$_ for qw(puke barf);

    warnings->import;
    strict->import;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JBD::Core::stern - exports warnings and strict; also provides puke() and barf()

=head1 VERSION

version 0.04

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
