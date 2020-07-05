use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/../t/lib";

use File::Basename qw( basename );
use File::Find qw( find );
use File::Slurper qw( read_text );
use Test2::V0;
use Test::Markdent;

my @files;
find(
    {
        wanted => sub {
            return unless $File::Find::name =~ /\.text$/;

            ( my $html_file = $File::Find::name ) =~ s/\.text$/.xhtml/;

            unless ( -f $html_file ) {
                ( $html_file = $File::Find::name ) =~ s/\.text$/.html/;
            }

            return unless -f $html_file;

            push @files, [ $File::Find::name, $html_file ];
        },
        no_chdir => 1,
    },
    "$Bin/../t/mdtest-data",
);

for my $pair ( sort { $a->[0] cmp $b->[0] } @files ) {
    my ( $md_file, $html_file ) = @{$pair};

    my $markdown    = read_text($md_file);
    my $expect_html = read_text($html_file);

    my $desc = basename($md_file);
    $desc =~ s/\.text$//;

    html_fragment_ok( $markdown, $expect_html, $desc );
}

done_testing();
