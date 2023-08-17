#!perl

=head1 DESCRIPTION

Check POD spelling via Lingua::Ispell.

This requires installation of Lingua::Ispell, ispell itself,
and American English dictionary.

=cut

use strict;
use warnings;

use Test::More;
use File::Basename qw(dirname);
use Test::Pod 1.22;

BEGIN {
    eval { require Lingua::Ispell; 1 } or do {
        plan tests => 1;
        fail "Can't find Lingua::Ispell (or ispell itself), aborting";
        exit 1;
    };
};
BEGIN {
    local $SIG{__WARN__} = sub {};
    require Test::Pod::Spelling;
    Test::Pod::Spelling->import(
        spelling => {
            allow_words => [qw[
                Konstantin Uvarin Alexey Kuznetsov
                URI API JSON JSONP DSL CPAN
                github metacpan annocpan
                regex arrayref hostname unicode wildcard referer
                validator validators proxied stateful unblessed rethrow
                aka distro del param js css
            ]],
        }
    );
};

my $dir = dirname(__FILE__);
my $root = $dir eq '.' ? '..' : dirname($dir);

my @files = @ARGV ? @ARGV : ("$root/lib/MVC/Neaf.pm", "$root/lib/MVC/Neaf/Request.pm");
    # TODO all_pod_files("$root/lib");

foreach ( @files ) {
    pod_file_spelling_ok($_);
};

done_testing;
