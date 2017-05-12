BEGIN {$| = 1;}

use HTML::Content::Extractor;

my (@tables, @standard);
push @tables, q~<ruby><p>test<rt>test<ruby><p><rt>test<rp>test</ruby><rp>test~;
push @tables, q~<p><ruby><p>test<rt>test<ruby><p><rt>test<rp>test</ruby><rp>test~;
push @tables, q~<ruby><div>test<rt>test<ruby><p><rt>test<rp>test</ruby><rp>test~;

push @standard,
[
        { name => "ruby", level => 1},
                { name => "p", level => 2}, { name => " ", level => 3},
                { name => "rt", level => 2}, { name => " ", level => 3},
                        { name => "ruby", level => 3},
                                { name => "p", level => 4},
                                { name => "rt", level => 4}, { name => " ", level => 5},
                                { name => "rp", level => 4}, { name => " ", level => 5},
                { name => "rp", level => 2}, { name => " ", level => 3}
],
[
        { name => "p", level => 1},
                { name => "ruby", level => 2},
        { name => "p", level => 1}, { name => " ", level => 2},
                { name => "rt", level => 2},
                        { name => " ", level => 3},
                        { name => "ruby", level => 3},
        { name => "p", level => 1},
                { name => "rt", level => 2}, { name => " ", level => 3},
                        { name => "rp", level => 3}, { name => " ", level => 4},
                                { name => "rp", level => 4}, { name => " ", level => 5}
],
[
        { name => "ruby", level => 1},
                { name => "div", level => 2}, { name => " ", level => 3},
                        { name => "rt", level => 3}, { name => " ", level => 4},
                                { name => "ruby", level => 4},
                                        { name => "p", level => 5},
                                        { name => "rt", level => 5}, { name => " ", level => 6},
                                        { name => "rp", level => 5}, { name => " ", level => 6},
                        { name => "rp", level => 3}, { name => " ", level => 4}
],
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
        
        if($res) {
                print "ok ", $i+1, "\n";
        }
        else {
                print "not ok ", $i+1, "\n";
        }
}
