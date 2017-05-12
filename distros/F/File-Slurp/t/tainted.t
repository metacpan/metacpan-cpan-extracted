#!perl -T

use strict;
use Test::More;
use File::Slurp;

plan 'skip_all', "Scalar::Util not available" unless
	eval 'use Scalar::Util qw(tainted) ; tainted($0) ; 1';

plan 'tests', 5;

my $path = "data.txt";
my $data = "random junk\nline2";

SKIP: {
    # write something to that file
    open(FILE, ">$path") or skip 4, "can't write to '$path': $!";
    print FILE $data;
    close(FILE);

    # read the file using File::Slurp in scalar context
    my $content = eval { read_file($path) };
    is( $@, '', "read_file() in scalar context" );
    ok( tainted($content), "  => returned content should be tainted" );


#         # reconstruct the full lines by merging items by pairs
#         for my $k (0..int($#lines/2)) {
#             my $i = $k * 2;
#             $lines[$k] = (defined $lines[$i]   ? $lines[$i]   : '') 
#                        . (defined $lines[$i+1] ? $lines[$i+1] : '');
#         }

#         # remove the rest of the items
#         splice(@lines, int($#lines/2)+1);
#         pop @lines unless $lines[-1];

#	$_ .= $/ for @lines ;

#         my @lines = split m{$/}, $content, -1;
# 	my @parts = split m{($/)}, $content, -1;

# #         my @parts = $content =~ m{.+?(?:$/)?}g ;

# my @lines ;
# 	while( @parts > 2 ) {

# 		my( $line, $sep ) = splice( @parts, 0, 2 ) ;
# 		push @lines, "$line$sep" ;
# 	}

# 	push @lines, shift @parts if @parts ;

# #    ok( tainted($lines[0]), "  text => returned content should be tainted" );

    # read the file using File::Slurp in list context
   my @content = eval { read_file($path) };
   is( $@, '', "read_file() in list context" );
   ok( tainted($content[0]), "  => returned content should be tainted" );

	my $text = join( '', @content ) ;

	is( $text, $content, "list eq scalar" );


#    ok( tainted($lines[0]), "  => returned content should be tainted" );
}

unlink $path;
