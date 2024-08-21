package Dist::Zilla::Plugin::Test::CPAN::Changes; # git description: v0.012-5-g02db9b7
use strict;
use warnings;
# ABSTRACT: release tests for your changelog

our $VERSION = '0.013';

use Moose;
use Sub::Exporter::ForMethods;
use Data::Section 0.200002 { installer => Sub::Exporter::ForMethods::method_installer }, '-setup';

with
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::PrereqSource',
    'Dist::Zilla::Role::TextTemplate';

#pod =head1 SYNOPSIS
#pod
#pod In C<dist.ini>:
#pod
#pod     [Test::CPAN::Changes]
#pod
#pod =begin :prelude
#pod
#pod =for test_synopsis BEGIN { die "SKIP: synopsis isn't perl code" }
#pod
#pod =end :prelude
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
#pod following file:
#pod
#pod     xt/release/cpan-changes.t - a standard Test::CPAN::Changes test
#pod
#pod See L<Test::CPAN::Changes> for what this test does.
#pod
#pod =head1 CONFIGURATION OPTIONS
#pod
#pod =head2 changelog
#pod
#pod The file name of the change log file to test. Defaults to F<Changes>.
#pod
#pod If you want to use a different filename for whatever reason, do:
#pod
#pod     [Test::CPAN::Changes]
#pod     changelog = CHANGES
#pod
#pod and that file will be tested instead.
#pod
#pod =head2 filename
#pod
#pod The name of the test file to be generated. Defaults to
#pod F<xt/release/cpan-changes.t>.
#pod
#pod =cut

has changelog => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Changes',
);

has filename => (
    is      => 'ro',
    isa     => 'Str',
    default => 'xt/release/cpan-changes.t',
);

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        changelog => $self->changelog,
        filename  => $self->filename,
        blessed($self) ne __PACKAGE__
            ? ( version => (defined __PACKAGE__->VERSION ? __PACKAGE__->VERSION : 'dev') )
            : (),
    };
    return $config;
};

#pod =for Pod::Coverage gather_files register_prereqs
#pod
#pod =cut

sub gather_files {
    my $self = shift;

    require Dist::Zilla::File::InMemory;

    my $content = ${$self->section_data('__TEST__')};

    my $final_content = $self->fill_in_string(
        $content,
        {
            changes_filename => \($self->changelog),
            plugin           => \$self,
        },
    );

    $self->add_file( Dist::Zilla::File::InMemory->new(
        name => $self->filename,
        content => $final_content,
    ));

    return;
}

# Register the release test prereq as a "develop requires"
# so it will be listed in "dzil listdeps --author"
sub register_prereqs {
  my ($self) = @_;

  $self->zilla->register_prereqs(
    {
      type  => 'requires',
      phase => 'develop',
    },
    # Latest known release of Test::CPAN::Changes
    # because CPAN authors must use the latest if we want
    # this check to be relevant
    'Test::CPAN::Changes'     => '0.19',
  );
}





__PACKAGE__->meta->make_immutable;
no Moose;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::CPAN::Changes - release tests for your changelog

=head1 VERSION

version 0.013

=for test_synopsis BEGIN { die "SKIP: synopsis isn't perl code" }

=head1 SYNOPSIS

In C<dist.ini>:

    [Test::CPAN::Changes]

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following file:

    xt/release/cpan-changes.t - a standard Test::CPAN::Changes test

See L<Test::CPAN::Changes> for what this test does.

=head1 CONFIGURATION OPTIONS

=head2 changelog

The file name of the change log file to test. Defaults to F<Changes>.

If you want to use a different filename for whatever reason, do:

    [Test::CPAN::Changes]
    changelog = CHANGES

and that file will be tested instead.

=head2 filename

The name of the test file to be generated. Defaults to
F<xt/release/cpan-changes.t>.

=for Pod::Coverage gather_files register_prereqs

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/doherty/Dist-Zilla-Plugin-Test-CPAN-Changes/issues>.

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.libera.chat>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Mike Doherty Karen Etheridge Olivier Mengué Graham Knop Kent Fredric Mark Gardner Nelo Onyiah

=over 4

=item *

Mike Doherty <mike@mikedoherty.ca>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Olivier Mengué <dolmen@cpan.org>

=item *

Graham Knop <haarg@haarg.org>

=item *

Kent Fredric <kentfredric@gmail.com>

=item *

Mark Gardner <mgardner@ariasystems.com>

=item *

Nelo Onyiah <nelo.onyiah@gmail.com>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__[ __TEST__ ]__
use strict;
use warnings;

# this test was generated with {{ ref($plugin) . ' ' . $plugin->VERSION }}

use Test::More 0.96 tests => 1;
use Test::CPAN::Changes;
subtest 'changes_ok' => sub {
    changes_file_ok('{{ $changes_filename }}');
};
