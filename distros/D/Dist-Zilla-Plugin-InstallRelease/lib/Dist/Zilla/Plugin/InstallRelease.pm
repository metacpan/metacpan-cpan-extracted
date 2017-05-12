package Dist::Zilla::Plugin::InstallRelease;
use strict;
use warnings;
# ABSTRACT: installs your dist after releasing
our $VERSION = '0.008'; # VERSION

use Carp ();
use autodie;
use Moose;
with 'Dist::Zilla::Role::Plugin';
with 'Dist::Zilla::Role::AfterRelease';


has install_command => (
    is      => 'ro',
    isa     => 'Str',
    predicate => 'has_install_command',
);

sub after_release {
    my $self = shift;

    eval {
        require File::pushd;
        my $wd = File::pushd::pushd($self->zilla->built_in);
        if ($self->has_install_command) {
            system($self->install_command)
                && $self->log_fatal([ 'error running %s', [$self->install_command] ]);
        }
        else {
            my @cmd = ($^X, '-MCPAN',
                $^O eq 'MSWin32' ? q(-e"install '.'") : q(-einstall '.')
            );
            system(@cmd) && $self->log_fatal([ 'error running %s', \@cmd ]);
        }
    };

    if ($@) {
        $self->log($@);
        $self->log('Install failed.');
    }
    else {
        $self->log('Install OK');
    }

    return;
}


__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Dist::Zilla::Plugin::InstallRelease - installs your dist after releasing

=head1 VERSION

version 0.008

=head1 DESCRIPTION

After doing C<dzil release>, this plugin will install your dist so you
are always the first person to have the latest and greatest version. It's
like getting first post, only useful.

To use it, add the following in F<dist.ini>:

    [InstallRelease]

You can specify an alternate install command:

    [InstallRelease]
    install_command = cpanm .

This plugin must always come before L<Dist::Zilla::Plugin::Clean>.

=for Pod::Coverage after_release

=head1 AVAILABILITY

The project homepage is L<http://p3rl.org/Dist::Zilla::Plugin::InstallRelease>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::Plugin::InstallRelease/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Dist-Zilla-Plugin-InstallRelease>
and may be cloned from L<git://github.com/doherty/Dist-Zilla-Plugin-InstallRelease.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Dist-Zilla-Plugin-InstallRelease/issues>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2100 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

