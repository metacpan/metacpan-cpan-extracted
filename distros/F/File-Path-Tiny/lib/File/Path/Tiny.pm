package File::Path::Tiny;

use strict;
use warnings;

$File::Path::Tiny::VERSION = 0.8;

sub mk {
    my ( $path, $mask ) = @_;
    return 2 if -d $path;
    if ( -e $path ) { $! = 20; return; }
    $mask ||= '0777';    # Perl::Critic == Integer with leading zeros at ...
    $mask = oct($mask) if substr( $mask, 0, 1 ) eq '0';
    require File::Spec;
    my ( $vol, $directories ) = File::Spec->splitpath( $path, 1 );
    my @dirs = File::Spec->splitdir($directories);
    my @list;

    while ( my ($_dir) = shift @dirs ) {
        last if not defined $_dir;
        push @list, $_dir;
        next if ( $_dir eq '' );
        my $progressive = File::Spec->catpath( $vol, File::Spec->catdir(@list), '' );
        if ( !-d $progressive ) {
            mkdir( $progressive, $mask ) or -d $progressive or return;
        }
    }
    return 1 if -d $path;
    return;
}

sub rm {
    my ($path) = @_;
    if ( -e $path && !-d $path ) { $! = 20; return; }
    return 2 if !-d $path;
    empty_dir($path) or return;
    rmdir($path) or !-e $path or return;
    return 1;
}

sub empty_dir {
    my ($path) = @_;
    if ( -e $path && !-d $path ) { $! = 20; return; }
    opendir( DIR, $path ) or return;
    my @contents = grep { $_ ne '.' && $_ ne '..' } readdir(DIR);
    closedir DIR;
    require File::Spec if @contents;
    for my $thing (@contents) {
        my $long = File::Spec->catdir( $path, $thing );
        if ( !-l $long && -d $long ) {
            rm($long) or !-e $long or return;
        }
        else {
            unlink $long or !-e $long or return;
        }
    }
    return 1;
}

sub mk_parent {
    my ( $path, $mode ) = @_;
    $path =~ s{/+$}{};

    require File::Spec;
    my ( $v, $d, $f ) = File::Spec->splitpath( $path, 1 );
    my @p = File::Spec->splitdir($d);

    # pop() is probably cheaper here, benchmark? $d = File::Spec->catdir(@p[0--$#p-1]);
    pop @p;
    $d = File::Spec->catdir(@p);

    my $parent = File::Spec->catpath( $v, $d, $f );
    return mk( $parent, $mode );
}

1;
