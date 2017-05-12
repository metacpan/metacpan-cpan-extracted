use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Test::UnusedVars;
# ABSTRACT: Release tests for unused variables
our $VERSION = '2.000007'; # VERSION
use Path::Tiny;
use Moose;
use Data::Section -setup;
with qw(
    Dist::Zilla::Role::FileGatherer
    Dist::Zilla::Role::TextTemplate
);

has files => (
    is  => 'ro',
    isa => 'Maybe[ArrayRef[Str]]',
    predicate => 'has_files',
);


sub mvp_multivalue_args { return qw/ files / }
sub mvp_aliases { return { file => 'files' } }

sub gather_files {
    my $self = shift;
    my $file = 'xt/release/unused-vars.t';

    require Dist::Zilla::File::InMemory;
    $self->add_file(
        Dist::Zilla::File::InMemory->new({
            name    => $file,
            content => $self->fill_in_string(
                ${ $self->section_data($file) },
                {
                    has_files => $self->has_files,
                    files => ($self->has_files
                        ? [ map { path($_)->relative('lib')->stringify } @{ $self->files } ]
                        : []
                    ),
                }
            ),
        })
    );
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::UnusedVars - Release tests for unused variables

=head1 VERSION

version 2.000007

=head1 SYNOPSIS

In C<dist.ini>:

    [Test::UnusedVars]

Or, give a list of files to test:

    [Test::UnusedVars]
    file = lib/My/Module.pm
    file = bin/verify-this

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following file:

    xt/release/unused-vars.t - a standard Test::Vars test

=for Pod::Coverage *EVERYTHING*

=for test_synopsis 1;
__END__

=head1 AVAILABILITY

The project homepage is L<http://metacpan.org/release/Dist-Zilla-Plugin-Test-UnusedVars/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::Plugin::Test::UnusedVars/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Dist-Zilla-Plugin-Test-UnusedVars>
and may be cloned from L<git://github.com/doherty/Dist-Zilla-Plugin-Test-UnusedVars.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Dist-Zilla-Plugin-Test-UnusedVars/issues>.

=head1 AUTHORS

=over 4

=item *

Marcel Grünauer <marcel@cpan.org>

=item *

Mike Doherty <doherty@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ xt/release/unused-vars.t ]___
#!perl

use Test::More 0.96 tests => 1;
eval { require Test::Vars };

SKIP: {
    skip 1 => 'Test::Vars required for testing for unused vars'
        if $@;
    Test::Vars->import;

    subtest 'unused vars' => sub {
{{
$has_files
    ? 'my @files = (' . "\n"
        . join(",\n", map { q{    '} . $_ . q{'} } map { s{'}{\\'}g; $_ } @files)
        . "\n" . ');' . "\n"
        . 'vars_ok($_) for @files;'
    : 'all_vars_ok();'
}}
    };
};
