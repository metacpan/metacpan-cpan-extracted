use strict;
use warnings;

package Dist::Zilla::Plugin::Test::Portability; # git description: v2.001002-4-g5c51a04
# ABSTRACT: Author tests for portability

our $VERSION = '2.001003';

use Moose;
with qw/
    Dist::Zilla::Role::FileGatherer
    Dist::Zilla::Role::FileInjector
    Dist::Zilla::Role::PrereqSource
    Dist::Zilla::Role::TextTemplate
/;
use Dist::Zilla::File::InMemory;
use Sub::Exporter::ForMethods 'method_installer';
use Data::Section 0.004 { installer => method_installer }, '-setup';
use namespace::autoclean;

has options => (
  is      => 'ro',
  isa     => 'Str',
  default => '',
);

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        options => $self->options,
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };
    return $config;
};

sub register_prereqs {
    my ($self) = @_;

    $self->zilla->register_prereqs({
            phase => 'develop',
            type  => 'requires',
        },
        'Test::More' => 0,
        'Test::Portability::Files' => '0',
    );

    return;
}

sub gather_files {
    my $self = shift;

    # 'name => val, name=val'
    my %options = split(/\W+/, $self->options);

    my $opts = '';
    if (%options) {
        $opts = join ', ', map "$_ => $options{$_}", sort keys %options;
        $opts = "options($opts);";
    }

    my $filename = 'xt/author/portability.t';
    my $filled_content = $self->fill_in_string(
        ${ $self->section_data($filename) },
        { opts => $opts },
    );
    $self->add_file(
        Dist::Zilla::File::InMemory->new({
            name => $filename,
            content => $filled_content,
        })
    );

    return;
}

__PACKAGE__->meta->make_immutable;
1;

#pod =pod
#pod
#pod =begin :prelude
#pod
#pod =for test_synopsis BEGIN { die "SKIP: synopsis isn't perl code" }
#pod
#pod =end :prelude
#pod
#pod =head1 SYNOPSIS
#pod
#pod In your F<dist.ini>:
#pod
#pod     [Test::Portability]
#pod     ; you can optionally specify test options
#pod     options = test_dos_length = 1, use_file_find = 0
#pod
#pod =cut

#pod =head1 DESCRIPTION
#pod
#pod This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
#pod following file:
#pod
#pod   xt/author/portability.t - a standard Test::Portability::Files test
#pod
#pod You can set options for the tests in the 'options' attribute:
#pod Specify C<< name = value >> separated by commas.
#pod
#pod See L<Test::Portability::Files/options> for possible options.
#pod
#pod =cut

#pod =for Pod::Coverage register_prereqs
#pod
#pod =cut

#pod =head2 munge_file
#pod
#pod Inserts the given options into the generated test file.
#pod
#pod =for Pod::Coverage gather_files
#pod
#pod =cut

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::Portability - Author tests for portability

=head1 VERSION

version 2.001003

=for test_synopsis BEGIN { die "SKIP: synopsis isn't perl code" }

=head1 SYNOPSIS

In your F<dist.ini>:

    [Test::Portability]
    ; you can optionally specify test options
    options = test_dos_length = 1, use_file_find = 0

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following file:

  xt/author/portability.t - a standard Test::Portability::Files test

You can set options for the tests in the 'options' attribute:
Specify C<< name = value >> separated by commas.

See L<Test::Portability::Files/options> for possible options.

=for Pod::Coverage register_prereqs

=head2 munge_file

Inserts the given options into the generated test file.

=for Pod::Coverage gather_files

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-Portability>
(or L<bug-Dist-Zilla-Plugin-Test-Portability@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Test-Portability@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Randy Stauner <rwstauner@cpan.org>

=item *

Mike Doherty <doherty@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Marcel Gruenauer Mike Doherty Graham Knop Randy Stauner Dave Rolsky Kent Fredric Peter Vereshagin

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Marcel Gruenauer <hanekomu@gmail.com>

=item *

Mike Doherty <doherty@cs.dal.ca>

=item *

Mike Doherty <mike@mikedoherty.ca>

=item *

Graham Knop <haarg@haarg.org>

=item *

Randy Stauner <randy@magnificent-tears.com>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Karen Etheridge <github@froods.org>

=item *

Kent Fredric <kentfredric@gmail.com>

=item *

Peter Vereshagin <peter@vereshagin.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ xt/author/portability.t ]___
use strict;
use warnings;

use Test::More;

use Test::Portability::Files;
{{$opts}}
run_tests();
