#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Language::Befunge::lib::FOO;
# ABSTRACT: extension to print foo
$Language::Befunge::lib::FOO::VERSION = '5.000';
sub new { return bless {}, shift; }

sub P {
    print "foo";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::lib::FOO - extension to print foo

=head1 VERSION

version 5.000

=head1 SYNOPSIS

    P - print "foo"

=head1 DESCRIPTION

This extension is just an example of the Befunge extension mechanism
of the Language::Befunge interpreter.

=head1 FUNCTIONS

=head2 new

Create a FOO instance.

=head2 P

Output C<foo>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
