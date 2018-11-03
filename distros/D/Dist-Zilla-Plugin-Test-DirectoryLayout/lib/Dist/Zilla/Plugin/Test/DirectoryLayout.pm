package Dist::Zilla::Plugin::Test::DirectoryLayout;
$Dist::Zilla::Plugin::Test::DirectoryLayout::VERSION = '0.002';
use strict;
use warnings;

# ABSTRACT: Test directory layout for standard compliance

use Moose;
use Test::DirectoryLayout;
use Test::More;

with 'Dist::Zilla::Role::TestRunner';

has add_dir => ( is => 'ro', isa => 'ArrayRef[Str]', default => sub { [] } );

sub mvp_multivalue_args { return qw(add_dir) }

sub test {
    my ($self) = @_;
    _add_dirs( $self->add_dir ) if @{ $self->add_dir };

    directory_layout_ok;

    done_testing;
}

sub _add_dirs {
    my ($add_dir) = @_;

    my $allowed_dirs = get_allowed_dirs();
    push @$allowed_dirs, @$add_dir;
    set_allowed_dirs($allowed_dirs);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::DirectoryLayout - Test directory layout for standard compliance

=head1 VERSION

version 0.002

=head1 METHODS

=head2 mvp_multivalue_args

Currently we have only one multi-value option: add_dir.

=head2 test

If additional directories are configured these are added to the list
of allowed directories.

Then we test the directory layout.

=head1 METHODS

=head1 AUTHOR

Goldbach <grg@perlservices.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gregor Goldbach.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
