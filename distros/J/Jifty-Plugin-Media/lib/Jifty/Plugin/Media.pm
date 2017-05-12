use strict;
use warnings;
use utf8;

package Jifty::Plugin::Media;
use base qw/Jifty::Plugin Class::Accessor::Fast/;

our $VERSION = '0.01';

=head1 NAME

Jifty::Plugin::Media - Provides upload file and select url for Jifty

=head1 DESCRIPTION

Jifty::Plugin::Media is a Jifty plugin to allow managing static files, upload 
create directory, delete and select url for any media file for your application.

=head1 SYNOPSIS

In your B<Model> class schema description, add the following:

   column color1 => is Media;

In your jifty B<config.yml> under the framework section:

   Plugins:
       - Media:
          default_root: files

C<default_root> will be added to C<Your_app_root/share/web/static/> path 
Your web process need to have write rights in this directory.

In your B<Dispatcher> manage allowed uploaders :

  use strict;
  use warnings;
  package TestApp::Dispatcher;
  use Jifty::Dispatcher -base;
  before '*' => run {
    Jifty->api->allow('Jifty::Plugin::Media::Action::ManageFile')
        if Jifty->web-current_user->is_supersuser;
    };
  before '/media_*' => run {
    tangent '/access_denied'
        if ( ! Jifty->web-current_user->is_superuser );
  };
  1;

In your B<View> you can access to a manager page C<'/media_manage_page'> or
a fragment C<'/media_manage'> usable in a popout link:

  hyperlink (label => 'Manage files',
               onclick => { popout => '/media_manage' });

you can open a repository on load with C<mediadir> argument

   hyperlink (label => 'Manage files',
                 onclick => {
                     popout => '/media_manage',
                     args => { mediadir => '/images/'}
                     });

or you can change default_root to a sub directory with C<rootdir> argument

   hyperlink (label => 'Manage files',
                 onclick => {
                     popout => '/media_manage',
                     args => { rootdir => '/images/'}
                     });

=cut

__PACKAGE__->mk_accessors(qw(real_root default_root));

use File::Path;
use File::Basename;
use Text::Unaccent;

=head2 init

load config values, javascript and css

=cut

sub init {
   my $self = shift;
   my %opt  = @_;

    my $default_root = $opt{default_root} || 'files';
   $self->default_root( $default_root );
    my $root = Jifty::Util->app_root().'/share/web/static/'.$default_root.'/file';
    my $dir = File::Basename::dirname($root);

    if ( ! -d $dir) {
        eval { File::Path::mkpath($dir, 0, 0775); };
        die if $@;
    };
   $self->real_root( $dir );

   Jifty->web->add_javascript(qw( jqueryFileTree.js ) );
   Jifty->web->add_css('jqueryFileTree.css');
};


use Jifty::DBI::Schema;

sub _media {
            my ($column, $from) = @_;
            my $name = $column->name;
            $column->type('text');
}

Jifty::DBI::Schema->register_types(
    Media =>
      sub { _init_handler is \&_media, render_as 'Jifty::Plugin::Media::Widget' },
);

=head2 read_dir

=cut

sub read_dir {
    my $self = shift;
    my $dir = shift;

    # don't allow relative path
    $dir =~ s/\.\.//g;
    # don't allow cached path
    $dir =~ s/^\.//g;

    my ($plugin) = Jifty->find_plugin($self);

    my $root = $plugin->real_root();
    my $fullDir = $root . $dir;

    return if ! -e $fullDir;

    opendir(BIN, $fullDir) or die "Can't open $dir: $!";
    my (@folders, @files);
    my $total = 0;
    while( defined (my $file = readdir BIN) ) {
        next if $file eq '.' or $file eq '..';
        $total++;
        if (-d "$fullDir/$file") {
        push (@folders, $file);
        } else {
        push (@files, $file);
        }
    };
    closedir(BIN);

    return ({ Folders => \@folders, Files => \@files });
};

sub _get_filesize_str
{
    my $size = shift;

    if ($size > 1099511627776)  #   TiB: 1024 GiB
    {
        return sprintf("%.2f T", $size / 1099511627776);
    }
    elsif ($size > 1073741824)  #   GiB: 1024 MiB
    {
        return sprintf("%.2f G", $size / 1073741824);
    }
    elsif ($size > 1048576)     #   MiB: 1024 KiB
    {
        return sprintf("%.2f M", $size / 1048576);
    }
    elsif ($size > 1024)        #   KiB: 1024 B
    {
        return sprintf("%.2f K", $size / 1024);
    }
    else                        #   bytes
    {
        return sprintf("%.2f", $size);
    }
};


=head2 file_info

=cut

sub file_info {
    my $self = shift;
    my $file = shift;

    my $root = Jifty::Util->app_root().'/share/web';
    my $fullName = $root . $file;
    return if (! -e $fullName);

    my $size = _get_filesize_str((stat($fullName))[7]);
    DateTime->DefaultLocale(Jifty::I18N->get_current_language);
    my $dt = Jifty::DateTime->from_epoch(time_zone => 'local',epoch => (stat($fullName))[9]);
    my $date = $dt->strftime("%a %d %b %H:%M:%S");
    my $sname = File::Basename::basename($fullName);
    return ($sname,$size,$date);
};

=head2 conv2ascii

 convert accent character to ascii

=cut

sub conv2ascii {
 my ($self,$string) = @_;
 my $res = unac_string('utf8',$string); # if( !$res);
 return $res;
};


=head2 clean_dir_name

convert dir name in ascii

=cut

sub clean_dir_name {
    my $self = shift;
    my $string = shift;
    return if !$string;
    $string=~s/[ '"\.\/\\()%&~{}|`,;:!*\$]/-/g;
    $string=~s/#/Sharp/g;
    $string=~s/--/-/g; $string=~s/--/-/g; $string=~s/--/-/g;
    $string=$self->conv2ascii($string);
    return $string;
};

=head2 clean_file_name

convert file name in ascii

=cut


sub clean_file_name {
    my $self = shift;
    my $name = shift;
    my $string=''; my $ext='';
    ($string,$ext) = $name =~m/^(.*?)(\.\w+)?$/;
    $ext =~ s/^\.// if $ext;
    $string = $self->clean_dir_name($string);
    $ext = $self->clean_dir_name($ext);
    return ($ext)?$string.'.'.$ext:$string;
};


=head1 AUTHOR

Yves Agostini, <yvesago@cpan.org>

=head1 LICENSE

Copyright 2010, Yves Agostini.

This program is free software and may be modified and distributed under the same
terms as Perl itself.

Embeded C<jqueryFileTree.js> is based on B<jQuery File Tree>
from http://abeautifulsite.net/2008/03/jquery-file-tree/  

Which is dual-licensed under the GNU General Public License and the MIT License
and is copyright 2008 A Beautiful Site, LLC. 

=cut

1;
