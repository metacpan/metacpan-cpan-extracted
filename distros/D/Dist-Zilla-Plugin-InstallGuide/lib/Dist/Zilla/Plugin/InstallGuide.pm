use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::InstallGuide; # git description: v1.200012-7-g19b74b1
# ABSTRACT: Build an INSTALL file

our $VERSION = '1.200013';

use Moose;
with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::TextTemplate';
with 'Dist::Zilla::Role::FileMunger';
with 'Dist::Zilla::Role::ModuleMetadata';
use List::Util 1.33 qw(first any);
use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod In C<dist.ini>:
#pod
#pod     [InstallGuide]
#pod
#pod =begin :prelude
#pod
#pod =for test_synopsis BEGIN { die "SKIP: synopsis isn't perl code" }
#pod
#pod =end :prelude
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin adds a very simple F<INSTALL> file to the distribution, telling
#pod the user how to install this distribution.
#pod
#pod You should use this plugin in your L<Dist::Zilla> configuration after
#pod C<[MakeMaker]> or C<[ModuleBuild]> so that it can determine what kind of
#pod distribution you are building and which installation instructions are
#pod appropriate.
#pod
#pod =head1 METHODS
#pod
#pod =cut

has template => (is => 'ro', isa => 'Str', default => <<'END_TEXT');
This is the Perl distribution {{ $dist->name }}.

Installing {{ $dist->name }} is straightforward.

## Installation with cpanm

If you have cpanm, you only need one line:

    % cpanm {{ $package }}

If it does not have permission to install modules to the current perl, cpanm
will automatically set up and install to a local::lib in your home directory.
See the local::lib documentation (https://metacpan.org/pod/local::lib) for
details on enabling it in your environment.

## Installing with the CPAN shell

Alternatively, if your CPAN shell is set up, you should just be able to do:

    % cpan {{ $package }}

## Manual installation

{{ $manual_installation }}
The prerequisites of this distribution will also have to be installed manually. The
prerequisites are listed in one of the files: `MYMETA.yml` or `MYMETA.json` generated
by running the manual build process described above.

## Configure Prerequisites

This distribution requires other modules to be installed before this
distribution's installer can be run.  They can be found under the
{{ join(" or the\n",
    $has_meta_yml ? '"configure_requires" key of META.yml' : '',
    $has_meta_json ? '"{prereqs}{configure}{requires}" key of META.json' : '',
)}}.

## Other Prerequisites

This distribution may require additional modules to be installed after running
{{ join(' or ', grep { $installer{$_} } qw(Build.PL Makefile.PL)) }}.
Look for prerequisites in the following phases:

* to run {{ join(' or ',
    ($installer{'Build.PL'} ? './Build' : ()),
    ($installer{'Makefile.PL'} ? 'make' : ())) }}, PHASE = build
* to use the module code itself, PHASE = runtime
* to run tests, PHASE = test

They can all be found in the {{ join(" or the\n",
    $has_meta_yml ? '"PHASE_requires" key of MYMETA.yml' : '',
    $has_meta_json ? '"{prereqs}{PHASE}{requires}" key of MYMETA.json' : '',
)}}.

## Documentation

{{ $dist->name }} documentation is available as POD.
You can run `perldoc` from a shell to read the documentation:

    % perldoc {{ $package }}

For more information on installing Perl modules via CPAN, please see:
https://www.cpan.org/modules/INSTALL.html
END_TEXT

our $common_instructions = <<'END_TEXT';
As a last resort, you can manually install it. Download the tarball, untar it,
install configure prerequisites (see below), then build it:

END_TEXT

has makemaker_manual_installation => (
    is => 'ro', isa => 'Str',
    default => $common_instructions . <<'END_TEXT',
    % perl Makefile.PL
    % make && make test

Then install it:

    % make install

On Windows platforms, you should use `dmake` or `nmake`, instead of `make`.

If your perl is system-managed, you can create a local::lib in your home
directory to install modules to. For details, see the local::lib documentation:
https://metacpan.org/pod/local::lib
END_TEXT
);

has module_build_manual_installation => (
    is => 'ro', isa => 'Str',
    default => $common_instructions . <<'END_TEXT',
    % perl Build.PL
    % ./Build && ./Build test

Then install it:

    % ./Build install

Or the more portable variation:

    % perl Build.PL
    % perl Build
    % perl Build test
    % perl Build install

If your perl is system-managed, you can create a local::lib in your home
directory to install modules to. For details, see the local::lib documentation:
https://metacpan.org/pod/local::lib
END_TEXT
);

#pod =head2 gather_files
#pod
#pod Creates the F<INSTALL> file.
#pod
#pod =cut

sub gather_files {
    my $self = shift;

    require Dist::Zilla::File::InMemory;
    $self->add_file(Dist::Zilla::File::InMemory->new({
        name => 'INSTALL',
        content => $self->template,
    }));

    return;
}

#pod =head2 munge_files
#pod
#pod Inserts the appropriate installation instructions into F<INSTALL>.
#pod
#pod =cut

sub munge_files {
    my $self = shift;

    my $zilla = $self->zilla;

    my $manual_installation = '';

    my %installer = (
        map {
            $_->isa('Dist::Zilla::Plugin::MakeMaker') ? ( 'Makefile.PL' => 1 ) : (),
            $_->does('Dist::Zilla::Role::BuildPL') ? ( 'Build.PL' => 1 ) : (),
        } @{ $zilla->plugins }
    );

    if ($installer{'Build.PL'}) {
        $manual_installation .= $self->module_build_manual_installation;
    }
    elsif ($installer{'Makefile.PL'}) {
        $manual_installation .= $self->makemaker_manual_installation;
    }
    unless ($manual_installation) {
        $self->log_fatal('neither Makefile.PL nor Build.PL is present, aborting');
    }

    my $main_package = $self->module_metadata_for_file($zilla->main_module, collect_pod => 0)->name;

    my $file = first { $_->name eq 'INSTALL' } @{ $zilla->files };

    my $content = $self->fill_in_string(
        $file->content,
        {   dist                => \$zilla,
            package             => $main_package,
            manual_installation => $manual_installation,
            has_meta_yml        => (any { $_->name eq 'META.yml' } @{ $zilla->files }),
            has_meta_json       => (any { $_->name eq 'META.json' } @{ $zilla->files }),
            installer           => \%installer,
        }
    );

    $file->content($content);
    return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::InstallGuide - Build an INSTALL file

=head1 VERSION

version 1.200013

=for test_synopsis BEGIN { die "SKIP: synopsis isn't perl code" }

=head1 SYNOPSIS

In C<dist.ini>:

    [InstallGuide]

=head1 DESCRIPTION

This plugin adds a very simple F<INSTALL> file to the distribution, telling
the user how to install this distribution.

You should use this plugin in your L<Dist::Zilla> configuration after
C<[MakeMaker]> or C<[ModuleBuild]> so that it can determine what kind of
distribution you are building and which installation instructions are
appropriate.

=head1 METHODS

=head2 gather_files

Creates the F<INSTALL> file.

=head2 munge_files

Inserts the appropriate installation instructions into F<INSTALL>.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-InstallGuide>
(or L<bug-Dist-Zilla-Plugin-InstallGuide@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-InstallGuide@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

=head1 AUTHORS

=over 4

=item *

Marcel Grünauer <marcel@cpan.org>

=item *

Mike Doherty <doherty@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Mike Doherty Marcel Gruenauer jonasbn Dan Book Dave Rolsky Apocalypse

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Mike Doherty <mike@mikedoherty.ca>

=item *

Marcel Gruenauer <hanekomu@gmail.com>

=item *

jonasbn <jonasbn@gmail.com>

=item *

Mike Doherty <doherty@cs.dal.ca>

=item *

Dan Book <grinnz@gmail.com>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Apocalypse <APOCAL@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Marcel Grünauer <marcel@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
