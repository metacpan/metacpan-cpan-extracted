use warnings;
use strict;
use Test::More tests => 4;
use_ok('HTML::Template::Compiled');
use lib 't';
use HTC_Utils qw($tdir &cdir &create_cache &remove_cache);
my $cache_dir = "cache20";
$cache_dir = create_cache($cache_dir);


HTML::Template::Compiled->clear_filecache($cache_dir);
{
    my $pre = 'precompiled1.tmpl';
    my $scalar = <<'EOM';
Precompiled scalarref!
EOM
    my $templates = HTML::Template::Compiled->precompile(
        path     => $tdir,
        file_cache_dir => $cache_dir,
        file_cache => 1,
        filenames => [$pre, \$scalar],
    );
    #warn Data::Dumper->Dump([\$templates], ['templates']);
    my $out = $templates->[0]->output;
    #print "out: '$out'\n";
    my $out2 = $templates->[1]->output;
    #print "out2: '$out2'\n";
    my $exp = do {
        open my $fh, '<', File::Spec->catfile($tdir, $pre) or die $!;
        local $/;
        <$fh>;
    };
    tr/\r\n//d for $exp, $out, $out2, $scalar;
    cmp_ok(scalar @$templates, "==", 2, "precompile count");
    cmp_ok($out, "eq", $exp, "precompiled output");
    cmp_ok($out2, "eq", $scalar, "precompiled scalarref");
    #print `ls t/cache/`;

}

HTML::Template::Compiled->clear_filecache($cache_dir);
remove_cache($cache_dir);
