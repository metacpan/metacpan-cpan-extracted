package File::ConfigDir::Install;

use warnings;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use Carp qw(confess);
use Config;
use Cwd;
use Exporter ();
require File::Basename;
require File::Spec;
use IO::Dir ();

=head1 NAME

File::ConfigDir::Install - Install (into) configuration directories

=cut

$VERSION     = '0.001';
@ISA         = qw(Exporter);
@EXPORT      = qw(install_config);
@EXPORT_OK   = qw(install_config postamble constants install);
%EXPORT_TAGS = (
    ALL => [@EXPORT_OK],
    CONFIG => [qw(install_config)],
    MY => [qw(postamble constants install)],
);

our @DIRS;
our %ALREADY;
our $INCLUDE_DOTFILES = 0;
our $INCLUDE_DOTDIRS  = 0;

sub install_config
{
    my $dir  = @_ ? pop   : 'etc';

    # confess "Illegal or invalid config dir type '$type'" unless defined $type and $type =~ /^(system|core|local|...)$/;

    # if( $type eq 'dist' and @_ ) {
    #     confess "Too many parameters to install_share";
    # }

    my $def = _mk_def();
    _add_dir( $def, $dir );
}

#
# Build a task definition
sub _mk_def { { dotfiles => $INCLUDE_DOTFILES, dotdirs => $INCLUDE_DOTDIRS } }

#
#
# Add directories to a task definition
# Save the definition
sub _add_dir
{
    my ( $def, $dir ) = @_;

    $dir = [$dir] unless ref $dir;

    foreach my $d (@$dir)
    {
	defined $d or confess "Missing directory";
	-d $d or confess "Illegal directory specification: '$d'";
        $ALREADY{$d}++ and confess "Directory '$d' is already being installed";
        push @DIRS, {%$def, dir => $d};
    }
}

my $Curdir = File::Spec->curdir;

sub constants
{
    my $self = shift;
    my $m = $self->ExtUtils::MY::constants(@_);

    my $installetc = File::Spec->catdir($Config{installprefix}, "etc");
    $self->{INST_ETC} ||= File::Spec->catdir($Curdir, qw(blib etc));
    $self->{INSTALLETC} ||= $installetc;
    $self->{INSTALLSITEETC} ||= '$(INSTALLETC)';
    $self->{INSTALLVENDORETC} ||= $Config{usevendorprefix} ? '$(INSTALLETC)' : '';

    my @m = map { "$_ = $self->{$_}" } qw(INST_ETC);
    push @m, map { "$_ = $self->{$_}\nDEST$_ = \$(DESTDIR)\$($_)" } qw(INSTALLETC INSTALLSITEETC INSTALLVENDORETC);

    join("\n", $m, @m);
}

sub _unix_install_wrapper
{
    my($self, %attribs) = @_;
    my $m = $self->ExtUtils::MY::install(@_);

    my ($ppi, $psi, $pvi);
    $m =~ m/(pure_perl_install :: all.*?^$)/ms and $ppi = $1;
    $m =~ m/(pure_site_install :: all.*?^$)/ms and $psi = $1;
    $m =~ m/(pure_vendor_install :: all.*?^$)/ms and $pvi = $1;

    $ppi =~ s/"\$\(INST_BIN\)" "\$\(DESTINSTALLBIN\)" \\/"\$\(INST_BIN\)" "\$\(DESTINSTALLBIN\)" \\\n\t\t"\$\(INST_ETC\)" "\$\(DESTINSTALLETC\)" \\/ms;
    $psi =~ s/"\$\(INST_BIN\)" "\$\(DESTINSTALLSITEBIN\)" \\/"\$\(INST_BIN\)" "\$\(DESTINSTALLSITEBIN\)" \\\n\t\t"\$\(INST_ETC\)" "\$\(DESTINSTALLSITEETC\)" \\/ms;
    $pvi =~ s/"\$\(INST_BIN\)" "\$\(DESTINSTALLVENDORBIN\)" \\/"\$\(INST_BIN\)" "\$\(DESTINSTALLVENDORBIN\)" \\\n\t\t"\$\(INST_ETC\)" "\$\(DESTINSTALLVENDORETC\)" \\/ms;

    $m =~ s/(pure_perl_install :: all.*?^$)/$ppi/ms and $ppi = $1;
    $m =~ s/(pure_site_install :: all.*?^$)/$psi/ms and $psi = $1;
    $m =~ s/(pure_vendor_install :: all.*?^$)/$pvi/ms and $pvi = $1;

    $m;
}

sub _inject_eu_mm_vms_install_wrapper
{
    my($self, %attribs) = @_;
    my $m = $self->ExtUtils::MY::install(@_);

    my ($ppi, $psi, $pvi);
    $m =~ m/(pure_perl_install :: all.*?^$)/ms and $ppi = $1;
    $m =~ m/(pure_site_install :: all.*?^$)/ms and $psi = $1;
    $m =~ m/(pure_vendor_install :: all.*?^$)/ms and $pvi = $1;

    $ppi =~ s/"\$\(INST_BIN\)" "\$\(DESTINSTALLBIN\)" \\/"\$\(INST_BIN\)" "\$\(DESTINSTALLBIN\)" \\\n\t\t"\$\(INST_ETC\)" "\$\(DESTINSTALLETC\)" \\/ms;
    $psi =~ s/"\$\(INST_BIN\)" "\$\(DESTINSTALLSITEBIN\)" \\/"\$\(INST_BIN\)" "\$\(DESTINSTALLSITEBIN\)" \\\n\t\t"\$\(INST_ETC\)" "\$\(DESTINSTALLSITEETC\)" \\/ms;
    $pvi =~ s/"\$\(INST_BIN\)" "\$\(DESTINSTALLVENDORBIN\)" \\/"\$\(INST_BIN\)" "\$\(DESTINSTALLVENDORBIN\)" \\\n\t\t"\$\(INST_ETC\)" "\$\(DESTINSTALLVENDORETC\)" \\/ms;

    $m =~ s/(pure_perl_install :: all.*?^$)/$ppi/ms and $ppi = $1;
    $m =~ s/(pure_site_install :: all.*?^$)/$psi/ms and $psi = $1;
    $m =~ s/(pure_vendor_install :: all.*?^$)/$pvi/ms and $pvi = $1;

    $m;
}

sub install
{
    defined $INC{'ExtUtils/MM_VMS.pm'} and return _vms_install_wrapper(@_);
    defined $INC{'ExtUtils/MM_Unix.pm'} and _unix_install_wrapper(@_);
}

#####################################################################
# Build the postamble section
sub postamble
{
    my $self = shift;
    join "\n", map { __postamble_etc_dir( $self, $_ ) } @DIRS;
}

#####################################################################
sub __postamble_etc_dir
{
    my ( $self, $def ) = @_;

    my $dir = $def->{dir};
    my $idir = File::Spec->catdir( '$(INST_ETC)' );

    my @cmds;
    my $autodir = '$(INST_ETC)';
    my $perl_cfg_to_blib = $self->oneliner( <<CODE, ['-MExtUtils::Install'] );
pm_to_blib({\@ARGV}, '$autodir')
CODE

    my $files = {};
    _scan_etc_dir( $files, $idir, $dir, $def );
    @cmds = $self->split_command( $perl_cfg_to_blib, %$files );

    my $r = join '', map { "\t\$(NOECHO) $_\n" } @cmds;

    return "config::\n$r";
}

# Get the per-dist install directory.
# We depend on the Makefile for most of the info
sub _dist_dir
{
    return ;
}

sub _scan_etc_dir
{
    my( $files, $idir, $dir, $def ) = @_;
    my $dh = IO::Dir->new( $dir ) or die "Unable to read $dir: $!";
    my $entry;
    # XXX use FFR, if available
    while( defined( $entry = $dh->read ) ) {
        next if $entry =~ /(~|,v|#)$/;
        my $full = File::Spec->catfile( $dir, $entry );
        if( -f $full ) {
            next if not $def->{dotfiles} and $entry =~ /^\./;
            $files->{ $full } = File::Spec->catfile( $idir, $entry );
        }
        elsif( -d $full ) {
            if( $def->{dotdirs} ) {
                next if $entry eq '.' or $entry eq '..' or 
                        $entry =~ /^\.(svn|git|cvs)$/;
            }
            else {
                next if $entry =~ /^\./;
            }
            _scan_etc_dir( $files, File::Spec->catdir( $idir, $entry ), $full );
        }
    }
}

1;
=head1 SYNOPSIS

    use ExtUtils::MakeMaker;
    use File::ConfigDir::Install;

    install_config 'etc';

    WriteMakefile( ... );       # As you normaly would

    package MY;
    use File::ConfigDir::Install qw(:MY);

=head1 DESCRIPTION

File::ConfigDir::Install allows you to install configuration files from a
distribution.

=head1 EXPORT

=head2 :CONFIG

This tag contains the functions for configration stage of Makefile.PL

=head3 install_config

This function allows adding directories to be scanned for (config-)files
which will be installed in a later stage.

=head2 :MY

=head3 postamble

Wrapper around ExtUtils::MY::postamble to inject a "config::" target into
Makefile

=head3 install

Wrapper around ExtUtils::MY::install to inject install rules for config
files. Injected rules are

=over 4

=item perl

add C<< "$(INST_ETC)" "$(DESTINSTALLETC)" >> to C<pure_perl_install>
target,

=item site

add C<< "$(INST_ETC)" "$(DESTINSTALLSITEETC)" >> to C<pure_site_install>
target,

=item vendor

and add C<< "$(INST_ETC)" "$(DESTINSTALLVENDORETC)" >> to C<pure_vendor_install>
target.

=back

=head3 constants

Wrapper around ExtUtils::MY::constants to inject install constants for config
files.

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 LIMITATIONS

This early stage version has some limitations

=over 4

=item *

It is not trivially possible to mix this with other MakeMaker extensions
overloading C<constants>, C<install> or C<postamble>, respectively.

A reasonable solution (I<around>, L<Exporter::Tiny> ?) is required ...

=item *

Target directory is limited to static guess from one of
L<File::ConfigDir/core_cfg_dir>, L<File::ConfigDir/site_cfg_dir> or
L<File::ConfigDir/vendor_cfg_dir>, respectively.

A reasonable way to override might be more packager- and user-friendly.

=item *

No VMS support

Needs to be hacked ...

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-file-configdir-install at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-ConfigDir-Install>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::ConfigDir::Install

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-ConfigDir-Install>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-ConfigDir-Install>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-ConfigDir-Install>

=item * Search CPAN

L<http://search.cpan.org/dist/File-ConfigDir-Install/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
