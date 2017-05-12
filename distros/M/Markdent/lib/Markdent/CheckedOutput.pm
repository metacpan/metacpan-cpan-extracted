package Markdent::CheckedOutput;

use strict;
use warnings;

our $VERSION = '0.26';

sub new {
    my $class  = shift;
    my $output = shift;

    return bless \$output, $class;
}

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub print {
    my $self = shift;

    # We don't need warnings from IO::* about printing to closed handles when
    # we'll die in that case anyway.
    #
    ## no critic (TestingAndDebugging::ProhibitNoWarnings)
    no warnings 'io';
    ## use critic
    print { ${$self} } @_ or die "Cannot write to handle: $!";
}
## use critic

1;

# ABSTRACT: This class has no user-facing parts

__END__

=pod

=head1 NAME

Markdent::CheckedOutput - This class has no user-facing parts

=head1 VERSION

version 0.26

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
