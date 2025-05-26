#!perl
use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings;

use Encode;
use Encode::IMAPUTF7;

use File::Spec;
use File::Basename;

my $dir = dirname(__FILE__);
opendir my $dh, $dir or die "$dir:$!";
my @file = sort grep {/\.utf$/o} readdir $dh;
closedir $dh;
for my $file (@file){
    my $path = File::Spec->catfile($dir, $file);
    open my $fh, '<', $path or die "$path:$!";
    my $content;
    if (PerlIO::Layer->find('perlio')){
        binmode $fh => ':utf8';
        $content = join('' => <$fh>);
    } else { # ugh!
        binmode $fh;
        $content = join('' => <$fh>);
        Encode::_utf8_on($content)
    }
    close $fh;
    is(Encode::decode("IMAP-UTF-7", Encode::encode("IMAP-UTF-7", $content)), $content,
       "IMAP-UTF-7 RT:$file");
}
