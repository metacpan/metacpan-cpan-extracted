package Enbld::Target::Symlink;

use strict;
use warnings;

use File::Spec;
use File::Path qw/make_path/;

require Enbld::Home;


# directory list for symbolic link
our $dir_list = {
    'bin' => {
        'dir'   => 'bin',
        'omit'  => undef,
    },

    'sbin' => {
        'dir'   => 'sbin',
        'omit'  => undef,
    },

    'lib' => {
        'dir'   => 'lib',
        'omit'  => [ 'pkgconfig', 'perl5' ],
    },
    
    'pkgconfig' => {
        'dir'   => File::Spec->catdir( 'lib', 'pkgconfig' ),
        'omit'  => undef,
    },
    
    'include'   => {
        'dir'   => 'include',
        'omit'  => undef,
    },

    'script'    => {
        'dir'   => 'script',
        'omit'  => undef,
    },

    'support-files' => {
        'dir'   => 'support-files',
        'omit'  => undef,
    },

    'man-man1'      => {
        'dir'   => File::Spec->catdir( 'man', 'man1' ),
        'omit'  => undef,
    },

    'man-man3'      => {
        'dir'   => File::Spec->catdir( 'man', 'man3' ),
        'omit'  => undef,
    },

    'share-man1'      => {
        'dir'   => File::Spec->catdir( 'share', 'man', 'man1' ),
        'omit'  => undef,
    },

    'share-man3'      => {
        'dir'   => File::Spec->catdir( 'share', 'man', 'man3' ),
        'omit'  => undef,
    },

    'share'     => {
        'dir'   => 'share',
        'omit'  => [ 'emacs', 'info', 'man', 'doc', 'aclocal' ],
    },

    'doc'       => {
        'dir'   => File::Spec->catdir( 'share', 'doc' ),
        'omit'  => undef,
    },

    'site-lisp' => {
        'dir'   => File::Spec->catdir( 'share', 'emacs', 'site-lisp' ),
        'omit'  => undef,
    },

    'aclocal' => {
        'dir'   => File::Spec->catdir( 'share', 'aclocal' ),
        'omit'  => undef,
    },
};

sub delete_symlink {
    my ( $pkg, $old_depository ) = @_;

    foreach my $dir ( sort keys %{ $dir_list } ) {
        my $installed = File::Spec->catdir(
                Enbld::Home->home,
                $dir_list->{$dir}{dir}
                );

        next unless ( -d $installed );
        
        opendir( my $dh, $installed );
        my @list = grep { !/^\.{1,2}$/ } readdir $dh;
        closedir $dh;

        chdir $installed;
        
        foreach my $file ( @list ) {
            next unless ( -l $file );

            my $link = readlink( $file );
            
            if ( index( $link, $old_depository ) == 0 ) {
                unlink $file;
            }
        }
    }
}

sub create_symlink {
    my ( $pkg, $new_depository ) = @_;

    foreach my $dir ( sort keys %{$dir_list} ) {
        my $link_from_path =
            File::Spec->catdir( $new_depository, $dir_list->{$dir}{dir} );

        next unless ( -d $link_from_path );
        
        opendir( my $dh, $link_from_path );
        my @list = grep { !/^\.{1,2}$/ } readdir $dh;
        closedir $dh;
        
        my $link_to_path = File::Spec->catdir(
                Enbld::Home->home,
                $dir_list->{$dir}{dir}
                );
        
        unless ( -d $link_to_path ) {
            make_path( $link_to_path );
        }

        foreach my $file ( @list ) {
            next if ( grep {/^$file$/ } @{$dir_list->{$dir}{omit}} );
            
            my $symlink = File::Spec->catfile( $link_to_path, $file );
            
            if ( -l $symlink ) {
                unlink $symlink;
            }
            
            unless ( -e $symlink ) {
                symlink File::Spec->catfile( $link_from_path, $file ), $symlink;
            }
        }
    }
}


1;
