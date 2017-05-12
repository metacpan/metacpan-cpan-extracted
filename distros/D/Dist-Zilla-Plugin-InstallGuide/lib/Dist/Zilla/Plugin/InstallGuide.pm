use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::InstallGuide;

# ABSTRACT: Build an INSTALL file
our $VERSION = '1.200007'; # VERSION
use Moose;
with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::TextTemplate';
with 'Dist::Zilla::Role::FileMunger';
use List::Util 'first';


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
## Documentation

{{ $dist->name }} documentation is available as POD.
You can run perldoc from a shell to read the documentation:

    % perldoc {{ $package }}
END_TEXT

has makemaker_manual_installation => (is => 'ro', isa => 'Str', default => <<'END_TEXT');
As a last resort, you can manually install it. Download the tarball, untar it,
then build it:

    % perl Makefile.PL
    % make && make test

Then install it:

    % make install

If your perl is system-managed, you can create a local::lib in your home
directory to install modules to. For details, see the local::lib documentation:
https://metacpan.org/pod/local::lib
END_TEXT

has module_build_manual_installation => (is => 'ro', isa => 'Str', default => <<'END_TEXT');
As a last resort, you can manually install it. Download the tarball, untar it,
then build it:

    % perl Build.PL
    % ./Build && ./Build test

Then install it:

    % ./Build install

If your perl is system-managed, you can create a local::lib in your home
directory to install modules to. For details, see the local::lib documentation:
https://metacpan.org/pod/local::lib
END_TEXT


sub gather_files {
    my $self = shift;

    require Dist::Zilla::File::InMemory;
    $self->add_file(Dist::Zilla::File::InMemory->new({
        name => 'INSTALL',
        content => $self->template,
    }));

    return;
}


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

    (my $main_package = $zilla->name) =~ s!-!::!g;

    my $file = first { $_->name eq 'INSTALL' } @{ $zilla->files };

    my $content = $self->fill_in_string(
        $file->content,
        {   dist                => \$zilla,
            package             => $main_package,
            manual_installation => $manual_installation
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

version 1.200007

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

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::Plugin::InstallGuide/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Dist-Zilla-Plugin-InstallGuide>
and may be cloned from L<git://github.com/doherty/Dist-Zilla-Plugin-InstallGuide.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Dist-Zilla-Plugin-InstallGuide/issues>.

=head1 AUTHORS

=over 4

=item *

Marcel Grünauer <marcel@cpan.org>

=item *

Mike Doherty <doherty@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Marcel Grünauer <marcel@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
