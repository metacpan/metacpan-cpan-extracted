package Dist::Zilla::Plugin::NoTabsTests;
# ABSTRACT: (DEPRECATED) Release tests making sure hard tabs aren't used

our $VERSION = '0.15';

use Moose;
extends 'Dist::Zilla::Plugin::Test::NoTabs';

use namespace::autoclean;

before register_component => sub {
    warnings::warnif('deprecated',
        "!!! [NoTabsTests] is deprecated and will be removed in a future release; replace it with [Test::NoTabs]\n",
    );
};

has '+filename' => (
    default => sub { return 'xt/release/no-tabs.t' },
);

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::NoTabsTests - (DEPRECATED) Release tests making sure hard tabs aren't used

=head1 VERSION

version 0.15

=head1 SYNOPSIS

In your F<dist.ini>:

    [NoTabsTests]
    module_finder = my_finder
    script_finder = other_finder

=head1 DESCRIPTION

This is a plugin that runs at the L<gather files|Dist::Zilla::Role::FileGatherer> stage,
providing the file F<xt/release/no-tabs.t>, a standard L<Test::NoTabs> test.

THIS MODULE IS DEPRECATED. Please use
L<Dist::Zilla::Plugin::Test::NoTabs> instead. it may be removed at a
later time (but not before October 2014).

In the meantime, it will continue working -- although with a warning.
Refer to the replacement for the actual documentation.

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
