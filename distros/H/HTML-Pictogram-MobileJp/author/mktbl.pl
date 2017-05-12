use strict;
use warnings;
use autodie;
use JSON;
use Data::Dumper;
use LWP::Simple;
use File::Basename;
use File::Spec;

my $c_docomo = slurp_json('http://svn.openpear.org/Text_Pictogram_Mobile/trunk/data/docomo_convert.json')->{docomo};
my $e_docomo = slurp_json('http://svn.openpear.org/Text_Pictogram_Mobile/trunk/data/docomo_emoji.json')->{docomo};
my $e_softbank = slurp_json('http://svn.openpear.org/Text_Pictogram_Mobile/trunk/data/softbank_emoji.json')->{softbank};

&main;exit;

sub main {
    make_unicode_number_map();
    make_emoji_number_map();

    exit;
}

sub make_unicode_number_map {
    my $ezweb;     # "docomo unicode" to "ez emoji number"
    my $softbank;  # "docomo unicode" to "softbank unicode"

    while (my ($docomo_id, $val) = each %$c_docomo) {
        if ($val->{ezweb} =~ /^\d+$/) {
            $ezweb->{$e_docomo->{$docomo_id}->{unicode}}  = $val->{ezweb};
        }
        if ($val->{softbank} =~ /^\d+$/) {
            $softbank->{$e_docomo->{$docomo_id}->{unicode}} = $e_softbank->{$val->{softbank}}->{unicode};
        }
    }

    my $ofname = File::Spec->catfile(dirname(__FILE__), '..', "lib/HTML/Pictogram/MobileJp/Unicode/Map.pm");
    open my $fh, ">:utf8", $ofname;
    select $fh;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse    = 1;
    print "package HTML::Pictogram::MobileJp::Unicode::Map;\n";
    print "use strict;\n";
    print "use warnings;\n";
    print "# This file was generated automatically.\n";
    print "use base qw/Exporter/;\n";
    print "our \@EXPORT = qw/\$EZWEB \$SOFTBANK/;\n";
    print "our \$EZWEB = ";
    print Dumper($ezweb);
    print ";\n";
    print "our \$SOFTBANK = ";
    print Dumper($softbank);
    print ";\n";
    print "1;\n";
    close $fh;
}

sub make_emoji_number_map {
    my $docomo;
    my $ezweb;
    my $softbank;

    while (my ($docomo_id, $val) = each %$c_docomo) {
        $ezweb->{$docomo_id}  = $val->{ezweb};
        $docomo->{$docomo_id} = $e_docomo->{$docomo_id}->{unicode};
        if ($val->{softbank} =~ /^\d+$/) {
            $softbank->{$docomo_id} = $e_softbank->{$val->{softbank}}->{unicode};
        } else {
            $softbank->{$docomo_id} = $val->{softbank};
        }
    }

    my $ofname = File::Spec->catfile(dirname(__FILE__), '..', "lib/HTML/Pictogram/MobileJp/EmojiNumber/Map.pm");
    open my $fh, ">:utf8", $ofname;
    select $fh;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse    = 1;
    print "package HTML::Pictogram::MobileJp::EmojiNumber::Map;\n";
    print "use strict;\n";
    print "use warnings;\n";
    print "# This file was generated automatically.\n";
    print "use base qw/Exporter/;\n";
    print "our \@EXPORT = qw/\$DOCOMO \$EZWEB \$SOFTBANK/;\n";
    print "our \$DOCOMO = ";
    print Dumper($docomo);
    print ";\n\n";
    print "our \$EZWEB = ";
    print Dumper($ezweb);
    print ";\n";
    print "our \$SOFTBANK = ";
    print Dumper($softbank);
    print ";\n";
    print "1;\n";
    close $fh;
}

sub slurp_json {
    my $content = get($_[0]) // die;
    decode_json($content);
}

