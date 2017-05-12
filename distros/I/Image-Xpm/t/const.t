use strict;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip no Test::More module\n";
	exit;
    }
}

plan tests => 8;

use Image::Xpm;

my $TestImage = <<'EOT';
/* XPM */
static const char* noname[] = {
/* width height ncolors chars_per_pixel */
"4 10 4 1",
/* colors */
"` c #000000",
"a c #FA1340",
"b c #3BFA34",
"c c #FFFF00",
/* pixels */
"````",
"`aa`",
"`aa`",
"````",
"`cc`",
"`cc`",
"````",
"`bb`",
"`bb`",
"````"
};
EOT

(my $TestImage_negative_hotspot = $TestImage) =~ s{("4 10 4 1)(",)}{$1 -1 -1$2};
die if $TestImage eq $TestImage_negative_hotspot;

{ # new() and separate load() step
    my $xpm = Image::Xpm->new(-width => 0, -height => 0);
    $xpm->load(\$TestImage);
    is($xpm->get('-width'), 4, 'Image with static const char loaded');
    is($xpm->get('-height'), 10);
}

{ # new() with -file
    my $xpm = Image::Xpm->new(-width => 0, -height => 0, -file => \$TestImage);
    is($xpm->get('-width'), 4, 'Image with static const char loaded');
    is($xpm->get('-height'), 10);
}

{ # hotspot: -1, -1
    my $xpm = Image::Xpm->new(-width => 0, -height => 0, -file => \$TestImage_negative_hotspot);
    is($xpm->get('-width'), 4, 'Image with static const char loaded');
    is($xpm->get('-height'), 10);
    is($xpm->get('-hotx'), -1, 'Negative hotspot');
    is($xpm->get('-hoty'), -1);
}
