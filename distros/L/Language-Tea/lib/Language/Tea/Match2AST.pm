package Language::Tea::Match2AST;

use strict;
use warnings;

sub match2ast {
    my $root = shift;
    my ( $filename, $source_lines ) = @_;

    my $visitor_ast;
    $visitor_ast = sub {
        my ($root) = shift;
        if ( ref($root) eq 'Pugs::Runtime::Match' ) {

            #print "visit ",ref($root), "\n";

            my $h    = {};
            my @keys = sort keys %$root;
            return "" . $root unless @keys;
            for my $key (@keys) {
                my $res =
                  Language::Tea::Traverse::visit_prefix( $root->{$key},
                    $visitor_ast, @_ );
                if ( defined $res ) {
                    $h->{$key} = $res;
                }
                else {
                    $h->{$key} = $root->{$key};
                }
            }

            $h->{info} = {
                from => $root->from,
                to   => $root->to,
                file => $filename,
                resolve_line( $root->from, $source_lines ),
            };

            return $h;
        }
    };

    return Language::Tea::Traverse::visit_prefix( $root, $visitor_ast );

}

sub resolve_line {
    my $from         = shift;
    my $source_lines = shift;
    my $cnt_lines    = 0;
    my $cnt_chars    = 0;
    my $col          = 0;
    while ( $cnt_chars <= $from ) {
       $col = 1 + $from - $cnt_chars;
       $cnt_chars += length( $source_lines->[ $cnt_lines++ ] );
       last unless exists $source_lines->[$cnt_lines];
    }
    return ( line => $cnt_lines, col => $col );
}

1;
