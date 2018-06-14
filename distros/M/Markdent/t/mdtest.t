use strict;
use warnings;

use Test2::V0;

use lib 't/lib';

use File::Basename qw( basename );
use File::Find qw( find );
use File::Slurp qw( read_file );
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
    't/mdtest-data'
);

for my $pair ( sort { $a->[0] cmp $b->[0] } @files ) {
    my ( $md_file, $html_file ) = @{$pair};

    my $markdown    = read_file($md_file);
    my $expect_html = read_file($html_file);

    my $desc = basename($md_file);
    $desc =~ s/\.text$//;

    html_fragment_ok( $markdown, $expect_html, $desc );
}

done_testing();
