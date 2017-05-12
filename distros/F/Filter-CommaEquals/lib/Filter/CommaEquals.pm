package Filter::CommaEquals;
# ABSTRACT: Adds support for ,= to any package or script

use strict;
use warnings;

use Filter::Simple;

our $VERSION = '1.01'; # VERSION

FILTER_ONLY
    code => sub {
        s/(\@[^',=']+)\s*,=\s*([^;]+);/push $1, $2;/msg
    };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Filter::CommaEquals - Adds support for ,= to any package or script

=head1 VERSION

version 1.01

=for markdown [![Build Status](https://travis-ci.org/gryphonshafer/Filter-CommaEquals.svg)](https://travis-ci.org/gryphonshafer/Filter-CommaEquals)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/Filter-CommaEquals/badge.png)](https://coveralls.io/r/gryphonshafer/Filter-CommaEquals)

=for test_synopsis BEGIN { die "SKIP: skip Test::Synopsis because content is post-filter\n"; }

=head1 SYNOPSIS

    use Filter::CommaEquals;
    my @array = ( 42, 1138, 96 );

    @array ,= 433;
    # exactly the same as writing: push( @array, 433 );

    print join(', ', @array), "\n";
    # prints: 42, 1138, 96, 433

=head1 DESCRIPTION

Adds support for ,= to any package or script. Perl has +=, -=, /=, *=, .=, and
so forth to operate on scalars, but it doesn't have ,= to operate on arrays.
This module effectively lets you rewrite push statements with ,= instead.

For example...

    push @array, $element;
    push( @array, $element_1, $element_2, $element_3 );
    push @array, [ 42, 1138, 96, 433 ];

...can now be rewritten as...

    use Filter::CommaEquals;
    @array ,= $element;
    @array ,= $element_1, $element_2, $element_3;
    @array ,= [ 42, 1138, 96, 433 ];

Cool, huh? Admit it. You want to write ,= instead of push, don't you.
You can save typing 3 whole characters!

Filter::CommaEquals is scoped to the package or script that it's used in,
but nothing more, and it requires Perl version 5.7.1 or higher.

=head1 MOTIVATION

A coworker complained about ,= not being in core Perl. After some thought,
I realized writing ,= is faster (by 3 key presses) than push. Also, I'm lazy.

=head1 SEE ALSO

You can also look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Filter-CommaEquals>

=item *

L<CPAN|http://search.cpan.org/dist/Filter-CommaEquals>

=item *

L<MetaCPAN|https://metacpan.org/pod/Filter::CommaEquals>

=item *

L<AnnoCPAN|http://annocpan.org/dist/Filter-CommaEquals>

=item *

L<Travis CI|https://travis-ci.org/gryphonshafer/Filter-CommaEquals>

=item *

L<Coveralls|https://coveralls.io/r/gryphonshafer/Filter-CommaEquals>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
