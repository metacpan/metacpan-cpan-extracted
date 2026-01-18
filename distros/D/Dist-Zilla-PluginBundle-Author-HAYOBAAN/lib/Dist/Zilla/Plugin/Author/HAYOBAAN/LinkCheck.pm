package Dist::Zilla::Plugin::Author::HAYOBAAN::LinkCheck;
use strict;
use warnings;

# ABSTRACT: Adapted version of the Dist::Zilla::Plugin::Test::Pod::LinkCheck
# plugin to set the cpan backend to CPAN instead of the deprecated CPANPLUS.
our $VERSION = '0.016'; # VERSION

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::PrereqSource';

sub register_prereqs {
    my $self = shift;

    return $self->zilla->register_prereqs(
        { type  => 'requires',
          phase => 'develop', },
        'Test::Pod::LinkCheck' => '0',
    );
}

#pod =pod
#pod
#pod =encoding UTF-8
#pod
#pod =for :stopwords Randy Stauner ACKNOWLEDGEMENTS cpan testmatrix url annocpan anno bugtracker
#pod rt cpants kwalitee diff irc mailto metadata placeholders metacpan
#pod
#pod =head1 NAME
#pod
#pod Dist::Zilla::Plugin::Author::HAYOBAAN::LinkCheck - Add author tests for POD links
#pod
#pod =head1 USAGE
#pod
#pod Add the following to your F<dist.ini>:
#pod
#pod   [Author::HAYOBAAN::LinkCheck]
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod * The original L<Test::Pod::LinkCheck|Dist::Zilla::Plugin::Test::Pod::LinkCheck> plugin
#pod
#pod * The underlying test L<Test::Pod::LinkCheck>
#pod
#pod =cut

#pod =for Pod::Coverage register_prereqs
#pod
#pod =head1 AUTHOR
#pod
#pod Randy Stauner <rwstauner@cpan.org>, modifications by Hayo Baan.
#pod
#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod This software is copyright (c) 2011 by Randy Stauner.
#pod
#pod This is free software; you can redistribute it and/or modify it under
#pod the same terms as the Perl 5 programming language system itself.
#pod
#pod =cut

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::HAYOBAAN::LinkCheck - Adapted version of the Dist::Zilla::Plugin::Test::Pod::LinkCheck

=head1 VERSION

version 0.016

=head1 USAGE

Add the following to your F<dist.ini>:

  [Author::HAYOBAAN::LinkCheck]

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS cpan testmatrix url annocpan anno bugtracker
rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

Dist::Zilla::Plugin::Author::HAYOBAAN::LinkCheck - Add author tests for POD links

=for Pod::Coverage register_prereqs

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>, modifications by Hayo Baan.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker
L<website|https://github.com/HayoBaan/Dist-Zilla-PluginBundle-Author-HAYOBAAN/issues>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=over 4

=item *

The original L<Test::Pod::LinkCheck|Dist::Zilla::Plugin::Test::Pod::LinkCheck> plugin

=back

* The underlying test L<Test::Pod::LinkCheck>

=head1 AUTHOR

Hayo Baan <info@hayobaan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Hayo Baan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ xt/author/pod-linkcheck.t ]___
#!perl

use strict;
use warnings;
use Test::More;

foreach my $env_skip ( qw(SKIP_POD_LINKCHECK) ) {
    plan skip_all => "\$ENV{$env_skip} is set, skipping" if $ENV{$env_skip};
}

eval "use Test::Pod::LinkCheck";
if ( $@ ) {
    plan skip_all => 'Test::Pod::LinkCheck required for testing POD';
} else {
    my $linktest = Test::Pod::LinkCheck->new;
    $linktest->cpan_backend('CPAN');
    $linktest->all_pod_ok;
}
