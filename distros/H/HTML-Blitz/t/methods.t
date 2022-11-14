use strict;
use warnings;
use Test::More;
use Test::Builder ();
use Test::Fatal qw(exception);
use File::Temp qw(tempfile);
use Fcntl qw(SEEK_SET);
use FindBin qw($Bin);
use HTML::Blitz ();

my $tmpl_file = "$Bin/template/doc.html";

sub fails_dummy {
    my ($blitz, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    like exception { $blitz->apply_to_file($tmpl_file); }, qr/\berror: .* contains forbidden dummy marker\b/, "throws $name";
}

{
    my $blitz = HTML::Blitz->new;
    $blitz->set_dummy_marker_re(qr/\bXXX\b/);
    fails_dummy $blitz, 'with set_dummy_marker_re';
}
{
    my $blitz = HTML::Blitz->new({ dummy_marker_re => qr/\bXXX\b/});
    fails_dummy $blitz, 'with dummy_marker_re (constructor)';
}
{
    my $blitz = HTML::Blitz->new(
        { dummy_marker_re => qr/\bXXX\b/},
        [ 'script.dummy' => ['replace_inner_text' => ''] ],
    );
    fails_dummy $blitz, 'with attribute value';
}
{
    my $blitz = HTML::Blitz->new(
        { dummy_marker_re => qr/\bXXX\b/},
        [ 'script.dummy' => ['replace_inner_text' => ''] ],
    );
    $blitz->add_rules(
        [ 'input.dummy' => ['set_attribute_text', value => 'nice'] ],
    );
    fails_dummy $blitz, 'with encoded text';
}

my $hjonk = "hj\N{LATIN SMALL LETTER O WITH DOUBLE ACUTE}nk";

{
    my $get_comments = sub { $_[0] =~ m{ <!--(.*?)--> }xsg };

    {
        my $html = HTML::Blitz->new->apply_to_file($tmpl_file)->process;
        is_deeply [$get_comments->($html)], [' lorem ipsum ', '# honk ', ' dolor sit #amet ', "# $hjonk "], 'all comments retained by default';
    }
    {
        my $html = HTML::Blitz->new({ keep_comments_re => qr/\A#/ })->apply_to_file($tmpl_file)->process;
        is_deeply [$get_comments->($html)], ['# honk ', "# $hjonk "], 'keep_comments_re works';
    }
    {
        my $blitz = HTML::Blitz->new;
        $blitz->set_keep_comments_re(qr/\A(?!#)/);
        my $html = $blitz->apply_to_file($tmpl_file)->process;
        is_deeply [$get_comments->($html)], [' lorem ipsum ', ' dolor sit #amet '], 'set_keep_comments_re works';
    }
}

{
    my $blitz = HTML::Blitz->new;
    my $template = $blitz->apply_to_file($tmpl_file);

    like $template->compile_to_string, qr/(?:\A|;)\s*sub \{/, '$template->compile_to_string produces Perl code';

    my $expected = <<"_EOF_";

<html>
    <head>
        <meta charset=utf-8>
        <!-- lorem ipsum -->
        <title>Asdf &lt;b> (not a tag)</title>
        <script class=dummy>//XXX</script>
    </head>
    <!--# honk -->
    <body>
        <!-- dolor sit #amet -->
        <h1>\N{INVERTED EXCLAMATION MARK}Document title with \N{EURO SIGN} \N{LATIN SMALL LETTER A WITH ACUTE}!</h1>
        <!--# $hjonk -->
        <label>Input: <input class=dummy value="XXX sample"></label>
        <p class=dummy>XXX weird</p>
    </body>
</html>
_EOF_

    {
        my $fn = $template->compile_to_sub;
        isa_ok $fn, 'CODE', '$template->compile_to_sub';
        
        $blitz->set_keep_doctype(0);
        my $fn2 = $blitz->apply_to_file($tmpl_file)->compile_to_sub;

        is $fn->(), "<!DOCTYPE html>$expected", '$template->compile_to_sub->() works (keep_doctype => 1)';
        is $fn2->(), $expected, '$template->compile_to_sub->() works (keep_doctype => 0)';
    }

    {
        open my $fh, '>', \my $buf or die $!;
        $template->compile_to_fh($fh);
        like $buf, qr/(?:\A|;)\s*sub \{/, '$template->compile_to_fh produces Perl code';
    }

    {
        my ($fh, $filename) = tempfile 'html-blitz-XXXXXX', TMPDIR => 1, UNLINK => 1;
        binmode $fh, ':encoding(UTF-8)';
        print $fh ") stuff\n";
        $fh->flush;

        $template->compile_to_file($filename);

        seek $fh, 0, SEEK_SET or die $!;
        my $code = do { local $/; readline $fh };
        like $code, qr/(?:\A|;)\s*sub \{/, '$template->compile_to_file produces Perl code';

        my $fn = do $filename;
        my $errno = $!;
        is $@, '', '$template->compile_to_file can be parsed by perl';
        ok defined($fn), '$template->compile_to_file can be read by perl'
            or diag "system error: $errno";

        is $fn->(), "<!DOCTYPE html>$expected", 'do($template->compile_to_file)->() generates expected HTML';
    }
}

done_testing;
