package File::ConfigDir;

use warnings;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use Carp qw(croak);
use Config;
use Cwd            ();
use Exporter       ();
use FindBin        ();
use File::Basename ();
use File::Spec     ();

=head1 NAME

File::ConfigDir - Get directories of configuration files

=cut

$VERSION   = '0.017';
@ISA       = qw(Exporter);
@EXPORT    = ();
@EXPORT_OK = (
    qw(config_dirs system_cfg_dir desktop_cfg_dir),
    qw(xdg_config_dirs machine_cfg_dir),
    qw(core_cfg_dir site_cfg_dir vendor_cfg_dir),
    qw(locallib_cfg_dir local_cfg_dir),
    qw(here_cfg_dir singleapp_cfg_dir),
    qw(xdg_config_home user_cfg_dir)
);
%EXPORT_TAGS = (
    ALL => [@EXPORT_OK],
);

my $haveFileHomeDir = 0;
eval {
    require File::HomeDir;
    $haveFileHomeDir = 1;
};

eval "use List::MoreUtils qw/uniq/;";
__PACKAGE__->can("uniq") or eval <<'EOP';
    # from PP part of List::MoreUtils
sub uniq(&@) {
    my %h;
    map { $h{$_}++ == 0 ? $_ : () } @_;
}
EOP

=head1 SYNOPSIS

    use File::ConfigDir ':ALL';

    my @cfgdirs = config_dirs();
    my @appcfgdirs = config_dirs('app');

    # install support
    my $site_cfg_dir = (site_cfg_dir())[0];
    my $vendor_cfg_dir = (site_cfg_dir()))[0];

=head1 DESCRIPTION

This module is a helper for installing, reading and finding configuration
file locations. It's intended to work in every supported Perl5 environment
and will always try to Do The Right Thing(tm).

C<File::ConfigDir> is a module to help out when perl modules (especially
applications) need to read and store configuration files from more than
one location. Writing user configuration is easy thanks to
L<File::HomeDir>, but what when the system administrator needs to place
some global configuration or there will be system related configuration
(in C</etc> on UNIX(tm) or C<$ENV{windir}> on Windows(tm)) and some
network configuration in nfs mapped C</etc/p5-app> or
C<$ENV{ALLUSERSPROFILE} . "\\Application Data\\p5-app">, respectively.

C<File::ConfigDir> has no "do what I mean" mode - it's entirely up to the
user to pick the right directory for each particular application.

=head1 EXPORT

Every function listed below can be exported, either by name or using the
tag C<:ALL>.

=head1 SUBROUTINES/METHODS

All functions can take one optional argument as application specific
configuration directory. If given, it will be embedded at the right (tm)
place of the resulting path.

=cut

sub _find_common_base_dir
{
    my ( $dira, $dirb ) = @_;
    my ( $va, $da, undef ) = File::Spec->splitpath($dira);
    my ( $vb, $db, undef ) = File::Spec->splitpath($dirb);
    my @dirsa = File::Spec->splitdir($da);
    my @dirsb = File::Spec->splitdir($db);
    my @commondir;
    my $max = $#dirsa < $#dirsb ? $#dirsa : $#dirsb;
    for my $i ( 0 .. $max )
    {
        $dirsa[$i] eq $dirsb[$i] or last;
        push( @commondir, $dirsa[$i] );
    }

    File::Spec->catdir( $va, @commondir );
}

=head2 system_cfg_dir

Returns the configuration directory where configuration files of the
operating system resides. For Unices this is C</etc>, for MSWin32 it's
the value of the environment variable C<%windir%>.

=cut

my $system_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs = File::Spec->catdir( $^O eq "MSWin32" ? $ENV{windir} : "/etc", @cfg_base );
    @dirs;
};

sub system_cfg_dir
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "system_cfg_dir(;\$), not system_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    $system_cfg_dir->(@cfg_base);
}

=head2 machine_cfg_dir

Alias for desktop_cfg_dir - deprecated.

=head2 xdg_config_dirs

Alias for desktop_cfg_dir

=head2 desktop_cfg_dir

Returns the configuration directory where configuration files of the
desktop applications resides. For Unices this is C</etc/xdg>, for MSWin32
it's the value of the environment variable C<%ALLUSERSPROFILE%>
concatenated with the basename of the environment variable C<%APPDATA%>.

=cut

my $desktop_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;
    if ( $^O eq "MSWin32" )
    {
        my $alluserprof = $ENV{ALLUSERSPROFILE};
        my $appdatabase = File::Basename::basename( $ENV{APPDATA} );
        @dirs = ( File::Spec->catdir( $alluserprof, $appdatabase, @cfg_base ) );
    }
    else
    {
        if ( $ENV{XDG_CONFIG_DIRS} )
        {
            @dirs = split( ":", $ENV{XDG_CONFIG_DIRS} );
            @dirs = map { File::Spec->catdir( $_, @cfg_base ) } @dirs;
        }
        else
        {
            @dirs = ( File::Spec->catdir( "/etc", "xdg", @cfg_base ) );
        }
    }
    @dirs;
};

sub desktop_cfg_dir
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "desktop_cfg_dir(;\$), not desktop_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    $desktop_cfg_dir->(@cfg_base);
}

no warnings 'once';
*machine_cfg_dir = \&desktop_cfg_dir;
*xdg_config_dirs = \&desktop_cfg_dir;
use warnings;

=head2 core_cfg_dir

Returns the C<etc> directory below C<$Config{prefix}>.

=cut

my $core_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs = ( File::Spec->catdir( $Config{prefix}, "etc", @cfg_base ) );
    @dirs;
};

sub core_cfg_dir
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "core_cfg_dir(;\$), not core_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    $core_cfg_dir->(@cfg_base);
}

=head2 site_cfg_dir

Returns the C<etc> directory below C<$Config{sitelib_stem}> or the common
base directory of C<$Config{sitelib}> and C<$Config{sitebin}>.

=cut

my $site_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;

    if ( $Config{sitelib_stem} )
    {
        push( @dirs, File::Spec->catdir( $Config{sitelib_stem}, "etc", @cfg_base ) );
    }
    else
    {
        my $sitelib_stem = _find_common_base_dir( $Config{sitelib}, $Config{sitebin} );
        push( @dirs, File::Spec->catdir( $sitelib_stem, "etc", @cfg_base ) );
    }

    @dirs;
};

sub site_cfg_dir
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "site_cfg_dir(;\$), not site_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    $site_cfg_dir->(@cfg_base);
}

=head2 vendor_cfg_dir

Returns the C<etc> directory below C<$Config{vendorlib_stem}> or the common
base directory of C<$Config{vendorlib}> and C<$Config{vendorbin}>.

=cut

my $vendor_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;

    if ( $Config{vendorlib_stem} )
    {
        push( @dirs, File::Spec->catdir( $Config{vendorlib_stem}, "etc", @cfg_base ) );
    }
    else
    {
        my $vendorlib_stem = _find_common_base_dir( $Config{vendorlib}, $Config{vendorbin} );
        push( @dirs, File::Spec->catdir( $vendorlib_stem, "etc", @cfg_base ) );
    }

    @dirs;
};

sub vendor_cfg_dir
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "vendor_cfg_dir(;\$), not vendor_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    $vendor_cfg_dir->(@cfg_base);
}

=head2 singleapp_cfg_dir

Returns the configuration file for standalone installed applications. In
Unix speak, installing JRE to C<< /usr/local/jre-<version> >> means there is
a C<< /usr/local/jre-<version>/bin/java >> and going from it's directory
name one above and into C<etc> there is the I<singleapp_cfg_dir>. For a
Perl module it means, we're assuming that C<$FindBin::Bin> is installed as
a standalone package somewhere, eg. into C</usr/pkg> - as recommended for
pkgsrc ;)

=cut

my $singleapp_cfg_dir = sub {
    my @dirs = (
        map
        {
            eval { Cwd::abs_path($_) } or File::Spec->canonpath($_)
        } File::Spec->catdir( $FindBin::RealDir, "..", "etc" )
    );
    @dirs;
};

sub singleapp_cfg_dir
{
    my @cfg_base = @_;
    0 == scalar(@cfg_base)
      or croak "singleapp_cfg_dir(), not singleapp_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    $singleapp_cfg_dir->();
}

=head2 local_cfg_dir

Returns the configuration directory for distribution independent, 3rd
party applications. While this directory doesn't exists for MSWin32,
there will be only the path C</usr/local/etc> for Unices.

=cut

my $local_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;

    unless ( $^O eq "MSWin32" )
    {
        push( @dirs, File::Spec->catdir( "/usr", "local", "etc", @cfg_base ) );
    }

    @dirs;
};

sub local_cfg_dir
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "local_cfg_dir(;\$), not local_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    $local_cfg_dir->(@cfg_base);
}

=head2 locallib_cfg_dir

Extracts the C<INSTALL_BASE> from C<$ENV{PERL_MM_OPT}> and returns the
C<etc> directory below it.

=cut

my $locallib_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;

    if (   $INC{'local/lib.pm'}
        && $ENV{PERL_MM_OPT}
        && $ENV{PERL_MM_OPT} =~ m/.*INSTALL_BASE=([^"']*)['"]?$/ )
    {
        ( my $cfgdir = $ENV{PERL_MM_OPT} ) =~ s/.*INSTALL_BASE=([^"']*)['"]?$/$1/;
        push( @dirs, File::Spec->catdir( $cfgdir, "etc", @cfg_base ) );
    }

    @dirs;
};

sub locallib_cfg_dir
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "locallib_cfg_dir(;\$), not locallib_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    $locallib_cfg_dir->(@cfg_base);
}

=head2 here_cfg_dir

Returns the path for the C<etc> directory below the current working directory.

=cut

my $here_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs = ( File::Spec->catdir( File::Spec->rel2abs( File::Spec->curdir() ), @cfg_base, "etc" ) );
    @dirs;
};

sub here_cfg_dir
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "here_cfg_dir(;\$), not here_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    $here_cfg_dir->(@cfg_base);
}

=head2 user_cfg_dir

Returns the users home folder using L<File::HomeDir>. Without
File::HomeDir, nothing is returned.

=cut

my $user_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;

    $haveFileHomeDir and @dirs = ( File::Spec->catdir( File::HomeDir->my_home(), map { "." . $_ } @cfg_base ) );

    @dirs;
};

sub user_cfg_dir
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "user_cfg_dir(;\$), not user_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    $user_cfg_dir->(@cfg_base);
}

=head2 xdg_config_home

Returns the user configuration directory for desktop applications.
If C<< $ENV{XDG_CONFIG_HOME} >> is not set, for MSWin32 the value
of C<< $ENV{APPDATA} >> is return and on Unices the C<.config> directory
in the users home folder. Without L<File::HomeDir>, on Unices the returned
list might be empty.

=cut

my $xdg_config_home = sub {
    my @cfg_base = @_;
    my @dirs;

    if ( $ENV{XDG_CONFIG_HOME} )
    {
        @dirs = split( ":", $ENV{XDG_CONFIG_HOME} );
        @dirs = map { File::Spec->catdir( $_, @cfg_base ) } @dirs;
    }
    elsif ( $^O eq "MSWin32" )
    {
        @dirs = ( File::Spec->catdir( $ENV{APPDATA}, @cfg_base ) );
    }
    else
    {
        $haveFileHomeDir and @dirs = ( File::Spec->catdir( File::HomeDir->my_home(), ".config", @cfg_base ) );
    }

    @dirs;
};

sub xdg_config_home
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "xdg_config_home(;\$), not xdg_config_home(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    $xdg_config_home->(@cfg_base);
}

my ( @extensible_bases, @pure_bases );
push( @extensible_bases,
    $system_cfg_dir, $desktop_cfg_dir, $local_cfg_dir, $singleapp_cfg_dir, $core_cfg_dir,
    $site_cfg_dir,   $vendor_cfg_dir,  $here_cfg_dir,  $user_cfg_dir,      $xdg_config_home );
push( @pure_bases, 3 );

=head2 config_dirs

    @cfgdirs = config_dirs();
    @cfgdirs = config_dirs( 'appname' );

Tries to get all available configuration directories as described above.
Returns those who exists and are readable.

=cut

sub config_dirs
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "config_dirs(;\$), not config_dirs(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    my @dirs = ();

    my $pure_idx = 0;
    foreach my $idx ( 0 .. $#extensible_bases )
    {
        my $pure;
        $pure_idx <= $#pure_bases and $idx == $pure_bases[$pure_idx] and $pure = ++$pure_idx;
        push( @dirs, $extensible_bases[$idx]->( ( $pure ? () : @cfg_base ) ) );
    }

    @dirs = grep { -d $_ && -r $_ } uniq(@dirs);

    @dirs;
}

=head2 _plug_dir_source

    my $dir_src = sub { return _better_config_dir(@_); }
    File::ConfigDir::_plug_dir_source($dir_src);

    my $pure_src = sub { return _better_config_plain_dir(@_); }
    File::ConfigDir::_plug_dir_source($pure_src, 1); # see 2nd arg is true

Registers more sources to ask for suitable directories to check or search
for config files. Each L</config_dirs> will traverse them in subsequent
invocations, too.

Returns the number of directory sources in case of succes. Returns nothing
when C<$dir_src> is not a code ref.

=cut

sub _plug_dir_source
{
    my ( $dir_source, $pure ) = @_;

    $dir_source or return;
    "CODE" eq ref $dir_source or return;

    push( @extensible_bases, $dir_source );
    $pure and push( @pure_bases, $#extensible_bases );
    1;
}

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-File-ConfigDir at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-ConfigDir>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::ConfigDir

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-ConfigDir>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-ConfigDir>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-ConfigDir>

=item * Search CPAN

L<http://search.cpan.org/dist/File-ConfigDir/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks are sent out to Lars Dieckow (daxim) for his suggestion to add
support for the Base Directory Specification of the Free Desktop Group.
Matthew S. Trout (mst) earns the credit to suggest C<singleapp_cfg_dir>
and remind about C</usr/local/etc>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2015 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<File::HomeDir>, L<File::ShareDir>, L<File::BaseDir> (Unices only)

=cut

1;    # End of File::ConfigDir
