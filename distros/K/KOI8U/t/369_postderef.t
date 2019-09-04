# encoding: KOI8U
# This file is encoded in KOI8-U.
die "This file is not encoded in KOI8-U.\n" if q{‚ } ne "\x82\xa0";

use KOI8U;

BEGIN {
    print "1..6\n";
    if ($] >= 5.020) {
        require feature;
        feature::->import('postderef');
        require warnings;
        warnings::->unimport('experimental::postderef');
    }
    else{
        for my $tno (1..6) {
            print qq{ok - $tno SKIP $^X @{[__FILE__]}\n};
        }
        exit;
    }
}

# same as ${$sref}
$scalar = 'a scalar value';
$sref = \$scalar;
if ($sref->$* eq ${$sref}) {
    print qq{ok - 1 \$sref->\$* eq \${\$sref} $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 \$sref->\$* eq \${\$sref} $^X @{[__FILE__]}\n};
}

# same as @{$aref}
@array = (5,20,0);
$aref = \@array;
if (join('.',$aref->@*) eq join('.',@{$aref})) {
    print qq{ok - 2 join('.',\$aref->\@*) eq join('.',\@{\$aref}) $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 join('.',\$aref->\@*) eq join('.',\@{\$aref}) $^X @{[__FILE__]}\n};
}

# same as %{$href}
%hash = (qw(‚ ‚© 1 ‚ ‚¨ 2 ‚« 3 ‚Þ‚ç‚³‚«‚¢‚ë 4));
$href = \%hash;
if (join(',',$href->%*) eq join(',',%{$href})) {
    print qq{ok - 3 join(',',\$href->%*) eq join(',',%{\$href}) $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 join(',',\$href->%*) eq join(',',%{\$href}) $^X @{[__FILE__]}\n};
}

# same as &{$cref}
$cref = sub { '‚Í‚ñ‚È‚è' };
if ($cref->&* eq &{$cref}) {
    print qq{ok - 4 \$cref->&* eq &{\$cref} $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 \$cref->&* eq &{\$cref} $^X @{[__FILE__]}\n};
}

# same as *{$gref}
$gref = \*scalar;
if ($gref->** eq *{$gref}) {
    print qq{ok - 5 \$gref->** eq *{\$gref} $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 \$gref->** eq *{\$gref} $^X @{[__FILE__]}\n};
}

# same as $#{$aref}
@array = (5,20,0);
$aref = \@array;
if ($aref->$#* eq $#{$aref}) {
    print qq{ok - 6 \$aref->\$#* eq \$#{\$aref} $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 \$aref->\$#* eq \$#{\$aref} $^X @{[__FILE__]}\n};
}

__END__
