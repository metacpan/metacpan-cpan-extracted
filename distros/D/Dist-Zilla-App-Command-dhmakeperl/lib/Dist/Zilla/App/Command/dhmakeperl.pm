use strict;
use warnings;

package Dist::Zilla::App::Command::dhmakeperl;

# PODNAME: Dist::Zilla::App::Command::dhmakeperl
# ABSTRACT: use dh-make-perl to generate .deb archives from your CPAN package
#
# This file is part of Dist-Zilla-App-Command-dhmakeperl
#
# This software is copyright (c) 2015 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '0.007'; # VERSION

# Dependencies
use DhMakePerl;
use Dist::Zilla::App -command;
use autodie qw(:all);


sub abstract {
    'build debian package using dh-make-perl from your dzil package.
    look for the deb file in ./debuild folder after running dzil dhmakeperl';
}


sub opt_spec { }


sub validate_args {
    my ( $self, $opt, $args ) = @_;
    die 'no args expected' if @$args;
}


sub execute {
    my ( $self, $opt, $args ) = @_;

    system('rm -rf debuild');
    mkdir('debuild');
    $self->zilla->build_in('debuild/source');
    system( 'dh-make-perl make --vcs none --build debuild/source --version '
          . $self->zilla->version );
}
1;

__END__

=pod

=head1 NAME

Dist::Zilla::App::Command::dhmakeperl - use dh-make-perl to generate .deb archives from your CPAN package

=head1 VERSION

version 0.007

=head1 SYNOPSIS

Once the package is installed and you have setup the prereqs, you can run the following command inside your package folder:

     dzil dhmakeperl

Once this is done your package will be tested and deb file will be generated in the debuild folder for you.

=head1 DESCRIPTION

This is a extension for the L<Dist::Zilla> App that adds a command dhmakeperl to your dzil package for compiling your perl modules into .deb packages. 

Before you install this package make sure that dh-make-perl is installed in your debianE<sol>ubuntu system. There are some additional app requirements that you might want to install for dh-make-perl to avoid annoying warnings from dh-make-perl.

     sudo apt-get install dh-make-perl
     sudo apt-get install apt-file
     sudo apt-file update

To make sure that your changelog and debian control file is included use plugins L<Dist::Zilla::Plugin::Control::Debian> and L<Dist::Zilla::Plugin::ChangelogFromGit::Debian> in your dist.ini

=head1 METHODS

=head2 abstract

=head2 opt_spec

=head2 validate_args

=head2 execute

=head1 NOTES

=over

=item *

L<http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=683533> If you have
accidentally upgraded Makemaker you may apply this patch to fix the
perllocal.pod error.

=back

     --- ./Debian/Debhelper/Buildsystem/makefile.pm  2012-05-19 17:26:26.000000000 +0200
     +++ ./Debian/Debhelper/Buildsystem/makefile.pm.new      2012-08-01 15:53:41.000000000 +0200
     @@ -100,9 +100,9 @@
 
      sub install {
             my $this=shift;
             my $destdir=shift;
     -       $this->make_first_existing_target(['install'],
     +       $this->make_first_existing_target(['pure_install', 'install'],
                     "DESTDIR=$destdir",
                     "AM_UPDATE_INFO_DIR=no", @_);
      }

=over

=item *

The .deb archive is created using code in your current repository. It does not
use cpan2deb to pull CPAN code to create the .deb archive.

=item *

You must have dh-make-perl installed on your system to use this command. 

=item *

use sudo apt-get install dh-make-perl to install it on debian and ubuntu.

=item *

The .deb file will be created in the debuild folder, This should be added to
your .gitignore file.

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through github at 
L<https://github.com/shantanubhadoria/perl-dist-zilla-app-command-dhmakeperl/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/shantanubhadoria/perl-dist-zilla-app-command-dhmakeperl>

  git clone git://github.com/shantanubhadoria/perl-dist-zilla-app-command-dhmakeperl.git

=head1 AUTHOR

Shantanu Bhadoria <shantanu@cpan.org> L<https://www.shantanubhadoria.com>

=head1 CONTRIBUTORS

=for stopwords Shantanu Bhadoria

=over 4

=item *

Shantanu <shantanu@cpan.org>

=item *

Shantanu Bhadoria <shantanu@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
