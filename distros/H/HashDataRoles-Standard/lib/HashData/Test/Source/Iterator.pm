package HashData::Test::Source::Iterator;

use strict;
use 5.010001;
use strict;
use warnings;
use Role::Tiny::With;
with 'HashDataRole::Source::Iterator';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-11-04'; # DATE
our $DIST = 'HashDataRoles-Standard'; # DIST
our $VERSION = '0.005'; # VERSION

sub new {
    my ($class, %args) = @_;
    $args{num_pairs} //= 10;
    $args{random}    //= 0;

    $class->_new(
        gen_iterator => sub {
            my $i = 0;
            sub {
                $i++;
                return () if $i > $args{num_pairs}; ## no critic: Subroutines::ProhibitExplicitReturnUndef
                return $args{random} ? ($i, int(rand()*$args{num_pairs} + 1)) : ($i, $i);
            };
        },
    );
}

1;
# ABSTRACT: A test HashData module

__END__

=pod

=encoding UTF-8

=head1 NAME

HashData::Test::Source::Iterator - A test HashData module

=head1 VERSION

This document describes version 0.005 of HashData::Test::Source::Iterator (from Perl distribution HashDataRoles-Standard), released on 2024-11-04.

=head1 SYNOPSIS

 use HashData::Test::Source::Iterator;

 my $hash = HashData::Test::Soure::Iterator->new(
     # num_pairs => 100,   # default is 10
     # random => 1,        # if set to true, will return pairs in a random order
 );

=head1 DESCRIPTION

=head2 new

Create object.

Usage:

 my $hash = HashData::Test::Source::Iterator->new(%args);

Known arguments:

=over

=item * num_pairs

Positive int. Default is 10.

=item * random

Bool. Default is 0.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HashDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HashDataRoles-Standard>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HashDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
