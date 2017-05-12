BEGIN {$| = 1;}

use HTML::Content::Extractor;

my (@tables, @standard);
push @tables, q~<datalist>0<option><div>1<option>2</datalist><select><p>0<option><select><p>0<option>1<option>2<option>2~;

push @standard,
[
        { name => "datalist", level => 1}, { name => " ", level => 2},
                { name => "option", level => 2},
                        { name => "div", level => 3}, { name => " ", level => 4},
                                { name => "option", level => 4},  { name => " ", level => 5},
                                { name => "select", level => 4}, { name => " ", level => 5},
                                        { name => "option", level => 5},
                                { name => "p", level => 4}, { name => " ", level => 5},
                                        { name => "option", level => 5},  { name => " ", level => 6},
                                        { name => "option", level => 5},  { name => " ", level => 6},
                                        { name => "option", level => 5},  { name => " ", level => 6},
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
        
        if($res) {
                print "ok ", $i+1, "\n";
        }
        else {
                print "not ok ", $i+1, "\n";
        }
}
