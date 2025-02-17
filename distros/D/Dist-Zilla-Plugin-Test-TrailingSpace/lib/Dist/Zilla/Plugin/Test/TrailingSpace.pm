package Dist::Zilla::Plugin::Test::TrailingSpace;

use 5.012;

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with qw/Dist::Zilla::Role::TextTemplate Dist::Zilla::Role::PrereqSource/;

use namespace::autoclean;

has filename_regex => (
    is => 'ro',
    isa => 'Str',
    default => q/(?:\.(?:t|pm|pl|xs|c|h|txt|pod|PL)|README|Changes|TODO|LICENSE)\z/,
);

has abs_path_prune_re => (
    is => 'ro',
    isa => 'Str',
);

around add_file => sub {
    my ($orig, $self, $file) = @_;

    return $self->$orig(
        Dist::Zilla::File::InMemory->new(
            name => $file->name,
            content => $self->fill_in_string($file->content,
                {
                    dist => \($self->zilla),
                    filename_regex => $self->filename_regex,
                    abs_path_prune_re => $self->abs_path_prune_re,
                }
            )
        )
    );
};

# Register the release test prereq as a "develop requires"
# so it will be listed in "dzil listdeps --author"
sub register_prereqs {
    my ($self) = @_;

    $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        'Test::TrailingSpace'     => '0.0203',
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::TrailingSpace - test for trailing whitespace
in files.

=head1 VERSION

version 0.4.0

=head1 SYNOPSIS

1. In the dist.ini:

    [Test::TrailingSpace]

2. From the command line

    $ dzil test --release

=head1 DESCRIPTION

This module tests adds a test for trailing whitespace in the distribution. It
accepts the following parameters:

=head2 filename_regex

The regular expression for input to Test::TrailingSpace for matching the files
to look for trailing space.

Here is an example of how to override it:

    [Test::TrailingSpace]
    filename_regex = \.(?:pm|pod)\z

=head2 abs_path_prune_re

The regular expression for input to Test::TrailingSpace for specifying paths
to ignore.

=head1 SUBROUTINES/METHODS

=head2 register_prereqs()

Needed by L<Dist::Zilla> .

=head1 SEE ALSO

=over 4

=item * L<Dist::Zilla::Plugin::Test::EOL>

Can also check for trailing whitespace.

=item * L<Dist::Zilla::Plugin::EOLTests>

Older and seems less preferable.

=item * L<Test::TrailingSpace>

A standalone test module for trailing whitespace which this is a wrapper
for.

=back

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Dist-Zilla-Plugin-Test-TrailingSpace>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-TrailingSpace>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Dist-Zilla-Plugin-Test-TrailingSpace>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-Plugin-Test-TrailingSpace>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-Test-TrailingSpace>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::Plugin::Test::TrailingSpace>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dist-zilla-plugin-test-trailingspace at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Dist-Zilla-Plugin-Test-TrailingSpace>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/Dist-Zilla-Plugin-Test-TrailingSpace>

  git clone https://github.com/shlomif/Dist-Zilla-Plugin-Test-TrailingSpace.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-Test-TrailingSpace>
or by email to
L<bug-dist-zilla-plugin-test-trailingspace@rt.cpan.org|mailto:bug-dist-zilla-plugin-test-trailingspace@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut

__DATA__
___[ xt/release/trailing-space.t ]___
#!perl

use strict;
use warnings;

use Test::More;

eval "use Test::TrailingSpace";
if ($@)
{
   plan skip_all => "Test::TrailingSpace required for trailing space test.";
}
else
{
   plan tests => 1;
}

# TODO: add .pod, .PL, the README/Changes/TODO/etc. documents and possibly
# some other stuff.
my $finder = Test::TrailingSpace->new(
   {
       root => '.',
       filename_regex => qr#{{ $filename_regex }}#,
       abs_path_prune_re => {{ defined $abs_path_prune_re
                                 ?  qq{qr#$abs_path_prune_re#}
                                 : 'undef' }},
   },
);

# TEST
$finder->no_trailing_space(
   "No trailing space was found."
);
