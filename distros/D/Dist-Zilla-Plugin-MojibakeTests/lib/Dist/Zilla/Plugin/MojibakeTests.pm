package Dist::Zilla::Plugin::MojibakeTests;
# ABSTRACT: Author tests for source encoding

use strict;
use warnings qw(all);

our $VERSION = '0.8'; # VERSION

use Moose;
extends q(Dist::Zilla::Plugin::InlineFiles);
with 'Dist::Zilla::Role::PrereqSource';


sub register_prereqs {
    my $self = shift;
    return $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        'Test::Mojibake' => 0,
    );
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MojibakeTests - Author tests for source encoding

=head1 VERSION

version 0.8

=head1 SYNOPSIS

In F<dist.ini>:

    [MojibakeTests]

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the following file:

    xt/author/mojibake.t - a standard Test::Mojibake test

=for Pod::Coverage register_prereqs

=for test_synopsis 1;
__END__

=head1 AUTHOR

Stanislaw Pusep <stas@sysd.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Stanislaw Pusep.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ xt/author/mojibake.t ]___
#!perl

use strict;
use warnings qw(all);

use Test::More;
use Test::Mojibake;

all_files_encoding_ok();
