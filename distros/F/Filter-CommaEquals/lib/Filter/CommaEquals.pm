package Filter::CommaEquals;
# ABSTRACT: Adds support for ,= to any package or script

use 5.008;
use strict;
use warnings;

use Filter::Simple;

our $VERSION = '1.02'; # VERSION

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

version 1.02

=for markdown [![test](https://github.com/gryphonshafer/Filter-CommaEquals/workflows/test/badge.svg)](https://github.com/gryphonshafer/Filter-CommaEquals/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Filter-CommaEquals/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Filter-CommaEquals)

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

L<MetaCPAN|https://metacpan.org/pod/Filter::CommaEquals>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Filter-CommaEquals/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Filter-CommaEquals>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Filter-CommaEquals>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/F/Filter-CommaEquals.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2021 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
