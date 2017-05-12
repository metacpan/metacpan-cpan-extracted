use strict;
use warnings;

package Markdown::Pod::Test;

use Exporter 5.57 qw(import);
use Encode qw(decode_utf8);
use Markdown::Pod;

our @EXPORT_OK = qw( get_pod markdown_to_pod );

sub get_pod {
    my $fh = shift;

    my $pod = do { local $/; <$fh> };
    $pod =~ s/\s+\Z//gsm;

    return $pod;
}

sub markdown_to_pod {
    my $file = shift;

    open my $fh, $file
        or warn("cannot open $file: $!\n"), return;
    my $markdown = do { local $/; <$fh> };
    close $fh;

    my $m2p = Markdown::Pod->new;
    my $pod = $m2p->markdown_to_pod(
        encoding => 'utf8',
        markdown => decode_utf8($markdown),
    );
    $pod =~ s/\s+\Z//gsm;

    return $pod;
}

1;
