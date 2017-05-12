package File::ConfigDir::Plack;

use 5.008;

use strict;
use warnings FATAL => 'all';
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use Carp qw(croak);
use Cwd             ();
use Exporter        ();
use File::Basename  ();
use File::Spec      ();
use File::ConfigDir ();

=head1 NAME

File::ConfigDir::Plack - Plack plugin for File::ConfigDir

=cut

$VERSION     = '0.002';
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = ( qw(plack_app_dir plack_env_dir), );
%EXPORT_TAGS = (
    ALL => [@EXPORT_OK],
);

my $plack_app;

BEGIN
{
    defined $ENV{PLACK_ENV} and $plack_app = $0;
}

=head1 SYNOPSIS

    use File::ConfigFir 'config_dirs';
    use File::ConfigDir::Plack;

    my @dirs = config_dirs();
    my @foos = config_dirs('foo');

Of course, in edge case you need to figure out the dedicated configuration
locations:

    use File::ConfigDir::Plack qw/plack_app_dir plack_env_dir/;

    # remember - directory source functions always return lists, even
    #            only one entry is in there
    my @plack_app_dir = plack_app_dir;
    my @plack_env_dir = plack_env_dir;
    my @plack_env_foo = plack_env_dir('foo');

=head1 DESCRIPTION

File::ConfigDir::Plack works as plugin for L<File::ConfigDir> to find
configurations directories for L<Plack> environments. This requires
the environment variable C<PLACK_ENV> being set and the directory
C<environments> must exists in the directory of the running process image
or up to 3 levels above.

=head1 EXPORT

This module doesn't export anything by default. You have to request any
desired explicitly.

=head1 SUBROUTINES

=head2 plack_app_dir

Returns the configuration directory of a L<Plack> application currently
executed. It doesn't work outside of a Plack application.

=cut

my @search_locations = (
    File::Spec->curdir, File::Spec->updir,
    File::Spec->catdir( File::Spec->updir, File::Spec->updir ),
    File::Spec->catdir( File::Spec->updir, File::Spec->updir, File::Spec->updir ),
);

my $plack_app_dir = sub {
    my @dirs;

    if ( defined $plack_app )
    {
        my $app_dir = File::Basename::dirname($plack_app);
        foreach my $srch (@search_locations)
        {
            if ( -d File::Spec->catdir( $app_dir, $srch, "environments" ) )
            {
                $app_dir = Cwd::abs_path( File::Spec->catdir( $app_dir, $srch ) );
                last;
            }
        }
        push( @dirs, $app_dir );
    }

    return @dirs;
};

sub plack_app_dir
{
    my @cfg_base = @_;
    0 == scalar(@cfg_base)
      or croak "plack_app_dir(), not plack_app_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    return $plack_app_dir->();
}

=head2 plack_env_dir

Returns the environment directory of a L<Plack> application.

=cut

my $plack_env_dir = sub {
    my @cfg_base = @_;
    my @dirs;

    defined $ENV{PLACK_ENV}
      and push( @dirs, map { File::Spec->catdir( $_, "environments", $ENV{PLACK_ENV}, @cfg_base ) } $plack_app_dir->() );

    return @dirs;
};

sub plack_env_dir
{
    my @cfg_base = @_;
    return $plack_env_dir->(@cfg_base);
}

my $registered;
File::ConfigDir::_plug_dir_source( $plack_app_dir, ++$registered )
  and File::ConfigDir::_plug_dir_source($plack_env_dir)
  unless $registered;

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-file-configdir-plack at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-ConfigDir-Plack>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::ConfigDir::Plack

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-ConfigDir-Plack>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-ConfigDir-Plack>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-ConfigDir-Plack>

=item * Search CPAN

L<http://search.cpan.org/dist/File-ConfigDir-Plack/>

=back

=head1 ACKNOWLEDGEMENTS

Celogeek San inspired that module by including L<MooX::ConfigFromFile>
into L<Jedi>.

=head1 LICENSE AND COPYRIGHT

Copyright 2013,2014 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;    # End of File::ConfigDir::Plack
