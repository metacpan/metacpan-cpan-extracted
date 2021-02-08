package File::Path::Tiny;

use strict;
use warnings;
use Cwd qw(cwd chdir);
use Carp ();

$File::Path::Tiny::VERSION = "1.0";

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
    my ( $path, $fast ) = @_;
    my ( $orig_dev, $orig_ino ) = ( lstat $path )[ 0, 1 ];
    if ( -e _ && !-d _ ) { $! = 20; return; }
    return 2 if !-d _;

    empty_dir( $path, $fast ) or return;
    _bail_if_changed( $path, $orig_dev, $orig_ino );
    rmdir($path) or !-e $path or return;
    return 1;
}

sub empty_dir {
    my ( $path, $fast ) = @_;
    my ( $orig_dev, $orig_ino ) = ( lstat $path )[ 0, 1 ];
    if ( -e _ && !-d _ ) { $! = 20; return; }

    my ( $starting_point, $starting_dev, $starting_ino );
    if ( !$fast ) {
        $starting_point = cwd();
        ( $starting_dev, $starting_ino ) = ( lstat $starting_point )[ 0, 1 ];
        chdir($path) or Carp::croak("Failed to change directory to “$path”: $!");
        $path = '.';
        _bail_if_changed( $path, $orig_dev, $orig_ino );
    }

    opendir( my $dh, $path ) or return;
    my @contents = grep { $_ ne '.' && $_ ne '..' } readdir($dh);
    closedir $dh;
    _bail_if_changed( $path, $orig_dev, $orig_ino );

    require File::Spec if @contents;
    for my $thing (@contents) {
        my $long = File::Spec->catdir( $path, $thing );
        if ( !-l $long && -d _ ) {
            _bail_if_changed( $path, $orig_dev, $orig_ino );
            rm( $long, $fast ) or !-e $long or return;
        }
        else {
            _bail_if_changed( $path, $orig_dev, $orig_ino );
            unlink $long or !-e $long or return;
        }
    }

    _bail_if_changed( $path, $orig_dev, $orig_ino );

    if ( !$fast ) {
        chdir($starting_point) or Carp::croak("Failed to change directory to “$starting_point”: $!");
        _bail_if_changed( ".", $starting_dev, $starting_ino );
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

sub _bail_if_changed {
    my ( $path, $orig_dev, $orig_ino ) = @_;

    my ( $cur_dev, $cur_ino ) = ( lstat $path )[ 0, 1 ];

    if ( !defined $cur_dev || !defined $cur_ino ) {
        $cur_dev ||= "undef(path went away?)";
        $cur_ino ||= "undef(path went away?)";
    }
    else {
        $path = Cwd::abs_path($path);
    }

    if ( $orig_dev ne $cur_dev || $orig_ino ne $cur_ino ) {
        local $Carp::CarpLevel += 1;
        Carp::croak("directory $path changed: expected dev=$orig_dev ino=$orig_ino, actual dev=$cur_dev ino=$cur_ino, aborting");
    }
}

1;
