package JS::Test::Base;

use 5.008;

our $VERSION = '0.16';

1;

=encoding utf8

=head1 NAME

Test.Base - Data Driven Testing Base Class

=head1 SYNOPSIS

    var t = new Test.Base();

    var filters = {
        input: 'upper_case'
    };

    t.plan(1);
    t.filters(filters);
    t.run_is('input', 'output');

    function upper_case(string) {
        return string.toUpperCase();
    }

    /* Test
    === Test Multiline Upper Case
    --- input
    foo
    bar
    baz
    --- output
    FOO
    BAR
    BAZ

    */

=head1 DESCRIPTION

Test.Base is a Javascript port of Perl's Test::Base.

For a feel of how Test.Base works, see Perl's Test::Base documenation
(for now).

To use Test.Base in a project, follow the instructions in sample/README.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006, 2008. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
