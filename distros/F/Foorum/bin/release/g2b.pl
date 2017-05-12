#!/usr/bin/perl -w

use strict;
use Encode::HanConvert;
use File::Spec;
use FindBin qw/$Bin/;
use Cwd qw/abs_path/;

my $home
    = abs_path( File::Spec->catdir( $Bin, '..', '..' ) );    # Foorum home dir

local $/ = undef;

# for lib/Foorum/I18N/cn.po
open( my $fh, '<',
    File::Spec->catfile( $home, 'lib', 'Foorum', 'I18N', 'cn.po' ) );
flock( $fh, 1 );
binmode( $fh, ':encoding(simp-trad)' );
my $simp = <$fh>;
close($fh);

my $trad = simp_to_trad($simp);

open( $fh, '>',
    File::Spec->catfile( $home, 'lib', 'Foorum', 'I18N', 'tw.po' ) );
flock( $fh, 2 );
binmode( $fh, ':utf8' );
print $fh $trad;
close($fh);

print "lib/Foorum/I18N/tw.po OK\n";

# for root/js/jquery/validate/messages_cn.js
open(
    $fh, '<',
    File::Spec->catfile(
        $home,    'root',     'static', 'js',
        'jquery', 'validate', 'messages_cn.js'
    )
);
flock( $fh, 1 );
binmode( $fh, ':encoding(simp-trad)' );
$simp = <$fh>;
close($fh);

$trad = simp_to_trad($simp);

open(
    $fh, '>',
    File::Spec->catfile(
        $home,    'root',     'static', 'js',
        'jquery', 'validate', 'messages_tw.js'
    )
);
flock( $fh, 2 );
binmode( $fh, ':utf8' );
print $fh $trad;
close($fh);

print "root/static/js/jquery/validate/messages_cn.js OK\n";

# for root/js/site/formatter/ubbhelp-cn.js
open(
    $fh, '<',
    File::Spec->catfile(
        $home,  'root',      'static', 'js',
        'site', 'formatter', 'ubbhelp-cn.js'
    )
);
flock( $fh, 1 );
binmode( $fh, ':encoding(simp-trad)' );
$simp = <$fh>;
close($fh);

$trad = simp_to_trad($simp);

open(
    $fh, '>',
    File::Spec->catfile(
        $home,  'root',      'static', 'js',
        'site', 'formatter', 'ubbhelp-tw.js'
    )
);
flock( $fh, 2 );
binmode( $fh, ':utf8' );
print $fh $trad;
close($fh);

print "root/js/static/site/formatter/ubbhelp-cn.js OK\n";

1;
