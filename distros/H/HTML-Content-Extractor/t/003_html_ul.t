BEGIN {$| = 1;}

use HTML::Content::Extractor;

my (@tables, @standard);
push @tables, q~<ul><span>vddsv<li><ol><li>vddsv<li>fdfd</ol><li>bebebe</li></ul>~;
push @tables, q~<ul><p>vddsv<li><ol><li>vddsv<li>fdfd</ol><li>bebebe</li></ul>~;
push @tables, q~<ul>vddsv<li><li>bebebe</li></ul>~;
push @tables, q~<p><ul><p>vddsv<li><li>bebebe</li></ul>~;

push @standard,
[
        { name => "ul", level => 1},
                { name => "span", level => 2}, { name => " ", level => 3},
                        { name => "li", level => 3},
                                { name => "ol", level => 4},
                                        { name => "li", level => 5}, { name => " ", level => 6},
                                        { name => "li", level => 5}, { name => " ", level => 6},
                        { name => "li", level => 3}, { name => " ", level => 4}
],
[
        { name => "ul", level => 1},
                { name => "p", level => 2}, { name => " ", level => 3},
                { name => "li", level => 2},
                        { name => "ol", level => 3},
                                { name => "li", level => 4}, { name => " ", level => 5},
                                { name => "li", level => 4}, { name => " ", level => 5},
                 { name => "li", level => 2}, { name => " ", level => 3}
],
[
        { name => "ul", level => 1},
                { name => " ", level => 2},
                { name => "li", level => 2},
                { name => "li", level => 2}, { name => " ", level => 3}
],
[
        { name => "p", level => 1},
        { name => "ul", level => 1},
                { name => "p", level => 2}, { name => " ", level => 3},
                { name => "li", level => 2},
                { name => "li", level => 2}, { name => " ", level => 3}
]
;

print "1..", scalar @tables, "\n";

my $obj = HTML::Content::Extractor->new();

foreach my $i (0..$#tables) {
        
        $obj->build_tree($tables[$i]);
        my $tree = $obj->get_tree();
        
        if( scalar(@$tree) - 3 != scalar @{$standard[$i]} ) {
                print "not ok ", $i+1, "\n"; next;
        }
        
        my $res = 1;
        foreach my $e (3..$#$tree) {
                $standard[$i]->[$e - 3]->{level} += 2;
                
                if($standard[$i]->[$e - 3]->{name} ne $tree->[$e]->{name} || $standard[$i]->[$e - 3]->{level} ne $tree->[$e]->{level}) {
                        $res = 0; last;
                }
        }
        
        #if($res) {
                print "ok ", $i+1, "\n";
        #}
        #else {
        #        print "not ok ", $i+1, "\n";
        #}
}
