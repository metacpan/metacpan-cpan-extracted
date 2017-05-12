#!/usr/bin/perl -w

use strict;
use warnings;
{
    use Data::Dumper;
    use Lingua::Translate::Google;
    use English qw( -no_match_vars $PROGRAM_NAME );
}

my ( $key, $src, $dest, $q );

ARG:
while ( my $arg = shift @ARGV ) {

    if ( $arg eq '--key' ) {

        if ( @ARGV && $ARGV[0] !~ m{\A -- }xms ) {

            $key = shift @ARGV;
        }
        next ARG;
    }
    if ( $arg eq '--src' ) {

        if ( @ARGV && $ARGV[0] !~ m{\A -- }xms ) {

            $src = shift @ARGV;
        }
        next ARG;
    }
    if ( $arg eq '--dest' ) {

        if ( @ARGV && $ARGV[0] !~ m{\A -- }xms ) {

            $dest = shift @ARGV;
        }
        next ARG;
    }
    if ( $arg eq '--q' ) {

        $q = "";

        while ( @ARGV && $ARGV[0] !~ m{\A -- }xms ) {

            $q .= shift @ARGV;
            $q .= ' ';
        }

        chomp $q;

        next ARG;
    }
}

if ( !$q || !$src || !$dest || !$key ) {

    die <<"END_USAGE";
$PROGRAM_NAME --key <api key> --src <lang> --dest <lang> --q "Hello world"
END_USAGE
}

my $t = Lingua::Translate::Google->new(
    key  => $key,
    src  => $src,
    dest => $dest,
);

my %r = $t->translate($q);

print "\n", Dumper( \%r );

print "\nresult:\n", $r{result}, "\n";

__END__
