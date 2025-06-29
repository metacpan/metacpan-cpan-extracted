package Dist::Zilla::Plugin::HelpWanted;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: insert 'Help Wanted' information in the distribution's META
$Dist::Zilla::Plugin::HelpWanted::VERSION = '0.3.3';

use 5.34.0;
use warnings;

use Moose;
use List::MoreUtils qw(uniq);

use experimental qw/ signatures /;

with qw/
    Dist::Zilla::Role::Plugin
    Dist::Zilla::Role::InstallTool
/;

my @positions = qw/ 
    maintainer 
    co-maintainer 
    coder 
    translator 
    documentation
    tester 
    documenter
    developer
    helper
/;

my %legacy = (
    'co-maintainer'   => 'maintainer',
    'coder'           => 'developer',
    'documentation'   => 'documenter',
);

has [ @positions ] => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

has positions => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

sub setup_installer($self) {

    for my $p ( split ' ', $self->positions ) {
        eval { $self->$p(1); 1; }
            or die "position '$p' not recognized\n";
    }

    my @open_positions =
        uniq
        map { exists($legacy{$_}) ? $legacy{$_} : $_ }
        grep { $self->$_ } @positions;

    $self->zilla->distmeta->{x_help_wanted} = \@open_positions
        if @open_positions;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::HelpWanted - insert 'Help Wanted' information in the distribution's META

=head1 VERSION

version 0.3.3

=head1 SYNOPSIS

In dist.ini:

    [HelpWanted]
    positions = maintainer developer translator documenter tester helper

or

    [HelpWanted]
    maintainer    = 1
    developer     = 1
    translator    = 1
    documenter    = 1
    tester        = 1
    helper        = 1

=head1 DESCRIPTION

C<Dist::Zilla::Plugin::HelpWanted> adds an
C<x_help_wanted> field in the META information of the 
distribution.

=head1 CONFIGURATION OPTIONS

Position  are passed to the plugin either via the 
option C<positions>, or piecemeal (see example above).

The list of possible positions (inspired by
L<DOAP|https://github.com/edumbill/doap/wiki>) is:

=over

=item maintainer

=item developer

=item translator

=item documenter

=item tester

=item helper

=back

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
