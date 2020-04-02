package main;

use strict;
use warnings;

use File::Spec;
use File::Symlink::Relative qw{ :all };
use File::Temp 0.19;	# For newdir()
use Test2::V0;

SYMLINK_SUPPORTED
    or plan skip_all => 'Symbolic links not supported on this system';

my $dir = File::Temp->newdir();

my $src_file = 'source.tmp';
my $source = File::Spec->catfile( $dir->dirname(), $src_file );

my $tgt_file = 'target.link';
my $target = File::Spec->catfile( $dir->dirname(), $tgt_file );

my $content = "Able was I ere I saw Elba.\n";

{
    open my $fh, '>', $source
	or die "Unable to open $source: $!";
    print { $fh } $content;
    close $fh;
}

if (
    ok symlink_r( $source, $target ), "Able to link $tgt_file to $src_file"
) {

    is readlink $target, $src_file, 'Link content is as expected';

    local $/ = undef;
    open my $fh, '<', $target;
    my $from_link = <$fh>;
    close $fh;

    is $from_link, $content, 'Read correct file content via link';
}

done_testing;

1;

# ex: set textwidth=72 :
