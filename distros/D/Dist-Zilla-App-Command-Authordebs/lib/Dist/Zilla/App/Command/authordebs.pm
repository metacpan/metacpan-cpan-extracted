#
# This file is part of Dist-Zilla-App-Command-Authordebs
#
# This software is Copyright (c) 2016 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 2, June 1991
#
use strict;
use warnings;
use 5.010;
package Dist::Zilla::App::Command::authordebs;
$Dist::Zilla::App::Command::authordebs::VERSION = '0.003';
use Debian::AptContents;
use DhMakePerl::Utils qw(is_core_module);
use Dist::Zilla::Util::AuthorDeps;

use Dist::Zilla::App -command;

sub abstract { "list or install authordeps using Debian packages" }

sub opt_spec
{
    [ 'install'   , 'also run sudo apt-get install for missing packages' ],
}

sub execute
{
    my ($self, $opt) = @_; # $arg

    $self->app->chrome->logger->mute unless $self->app->global_options->verbose;

    my $apt_contents = Debian::AptContents->new( { homedir => $ENV{'HOME'}.'/.dh-make-perl' } );

    unless ($apt_contents) {
        die <<EOF;
Unable to locate module packages, because APT Contents files
are not available on the system.

Please install the 'apt-file' package, run 'sudo apt-file update' as root
and retry.
EOF
    }

    my $dep_list = Dist::Zilla::Util::AuthorDeps::extract_author_deps('.',1);

    if (not @$dep_list ) {
        warn "All dzil dependencies are already available\n";
        exit;
    }

    my @pkgs;
    foreach my $dep (@$dep_list) {
        my ($mod, $version) = %$dep;
        if ( my $pkg = $apt_contents->find_perl_module_package($mod) ) {
            warn "$mod is in $pkg package\n";
            push @pkgs , $pkg;
        }
        else {
            warn "$mod is not found in any Debian package\n";
        }
    }

    if ($opt->{install} and @pkgs) {
        warn "Installing required packages...\n";
        system(qw/sudo apt-get install/,@pkgs);
    }
    else {
        say join("\n",@pkgs);
    }
}


1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::authordebs - List or install Dist::Zilla authors dependencies as Debian packages

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 dzil authordebs --install

 apt install $( dzil authordebs )

=head1 DESCRIPTION

B<dzil authordebs> uses L<Dist::Zilla::Util::AuthorDeps> to scan
the Perl module required to build a Perl module using L<Dist::Zilla> and list the
corresponding Debian packages.

With C<--install> option, the required packages are installed with C<sudo apt-get install>, so you
must have sudo configured properly.

This command exits 1 if some required dependencies are not available as Debian packages.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2016 Dominique Dumont <dod@debian.org>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dominique Dumont.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

__END__

# ABSTRACT: List or install Dist::Zilla authors dependencies as Debian packages



1;
