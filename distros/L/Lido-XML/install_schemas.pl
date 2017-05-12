#!/usr/bin/env perl

use File::Slurp::Tiny;
use File::Spec;

my $name   = shift;

die "usage: $0 name file [file...]" unless $name && @ARGV;

my $pkgdir = "lib/Lido/XML/$name";

my @packages;

for my $path (@ARGV) {
    my ($volume,$directories,$file) = File::Spec->splitpath( $path );
    my $content = File::Slurp::Tiny::read_file($path);
    my $package = $file;
    $package =~ s{\..*$}{};
   	$package =~ s{[^A-Za-z0-9_]}{_}g;
   	$package =~ s{_+}{_}g;

    print "$file -> $pkgdir/$package.pm\n"; 
    File::Slurp::Tiny::write_file("$pkgdir/$package.pm",<<EOF);
package Lido::XML::$name\::$package;

use Moo;

our \$VERSION = '0.01';

sub content {
	my \@lines = <DATA>;
	join '' , \@lines;
}

1;
__DATA__
$content
EOF
	push @packages , "Lido::XML::$name\::$package";
}

my $perl =<<EOF;
package Lido::XML::$name;

our \$VERSION = '0.01';

use Moo;
EOF

for my $pkg (@packages) {
	$perl .=<<EOF;
use $pkg;
EOF
}

$perl .=<<EOF;

sub content {
    my \@res;
    for my \$pkg (qw( 
EOF

for my $pkg (@packages) {
	$perl .=<<EOF;
          $pkg
EOF
}

$perl .=<<EOF;
    )) {
        push \@res , \$pkg->new->content;
    }

    \@res;
}

1;
EOF

File::Slurp::Tiny::write_file("$pkgdir.pm",$perl);