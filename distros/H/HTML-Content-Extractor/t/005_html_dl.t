BEGIN {$| = 1;}

use HTML::Content::Extractor;

my (@tables, @standard);
push @tables, q~<dl><p>ds<dl><dd><span>sddsd<dt>dssd</dl><dd><span>sddsd<dl><dd>sddsd<dt>dssd</dl><dt>dssd~;
push @tables, q~<dl><span>ds<dl><dd><span>sddsd<dt>dssd</dl><dd><span>sddsd<dl><dd>sddsd<dt>dssd</dl><dt>dssd~;
push @tables, q~<dl><div>ds<dl><dd><span>sddsd<dt>dssd</dl><dd><span>sddsd<dl><dd>sddsd<dt>dssd</dl><dt>dssd~;
push @tables, q~<p><dl><p>ds<dl><dd><span>sddsd<dt>dssd</dl><dd><span>sddsd<dl><dd>sddsd<dt>dssd</dl><dt>dssd~;

push @standard,
[
        { name => "dl", level => 1},
                { name => "p", level => 2}, { name => " ", level => 3},
                { name => "dl", level => 2},
                        { name => "dd", level => 3},
                                { name => "span", level => 4}, { name => " ", level => 5},
                        { name => "dt", level => 3}, { name => " ", level => 4},
                { name => "dd", level => 2},
                        { name => "span", level => 3}, { name => " ", level => 4},
                                { name => "dl", level => 4},
                                        { name => "dd", level => 5}, { name => " ", level => 6},
                                        { name => "dt", level => 5}, { name => " ", level => 6},
                { name => "dt", level => 2},
                        { name => " ", level => 3}
],
[
        { name => "dl", level => 1},
                { name => "span", level => 2}, { name => " ", level => 3},
                        { name => "dl", level => 3},
                                { name => "dd", level => 4},
                                        { name => "span", level => 5}, { name => " ", level => 6},
                                { name => "dt", level => 4}, { name => " ", level => 5},
                        { name => "dd", level => 3},
                                { name => "span", level => 4}, { name => " ", level => 5},
                                        { name => "dl", level => 5},
                                                { name => "dd", level => 6}, { name => " ", level => 7},
                                                { name => "dt", level => 6}, { name => " ", level => 7},
                        { name => "dt", level => 3},
                                { name => " ", level => 4}
],
[
        { name => "dl", level => 1},
                { name => "div", level => 2}, { name => " ", level => 3},
                        { name => "dl", level => 3},
                                { name => "dd", level => 4},
                                        { name => "span", level => 5}, { name => " ", level => 6},
                                { name => "dt", level => 4}, { name => " ", level => 5},
                        { name => "dd", level => 3},
                                { name => "span", level => 4}, { name => " ", level => 5},
                                        { name => "dl", level => 5},
                                                { name => "dd", level => 6}, { name => " ", level => 7},
                                                { name => "dt", level => 6}, { name => " ", level => 7},
                        { name => "dt", level => 3},
                                { name => " ", level => 4}
],
[
        { name => "p", level => 1},
        { name => "dl", level => 1},
                { name => "p", level => 2}, { name => " ", level => 3},
                { name => "dl", level => 2},
                        { name => "dd", level => 3},
                                { name => "span", level => 4}, { name => " ", level => 5},
                        { name => "dt", level => 3}, { name => " ", level => 4},
                { name => "dd", level => 2},
                        { name => "span", level => 3}, { name => " ", level => 4},
                                { name => "dl", level => 4},
                                        { name => "dd", level => 5}, { name => " ", level => 6},
                                        { name => "dt", level => 5}, { name => " ", level => 6},
                { name => "dt", level => 2},
                        { name => " ", level => 3}
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
