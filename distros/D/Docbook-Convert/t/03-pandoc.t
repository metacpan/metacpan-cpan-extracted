use strict;
use warnings;
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;
use Docbook::Convert::Pandoc;
plan skip_all => 'set PANDOC_TEST=1 to qualify external tools' unless $ENV{'PANDOC_TEST'};
my $converter_or=Docbook::Convert::Pandoc->new();
my $md=$converter_or->convert_file('examples/guide/guide.xml');
like($md, qr/!!! note/, 'admonition preserved');
like($md, qr/\{#start\}/, 'section ID preserved');
like($md, qr/\(#next\)/, 'internal link preserved');
$md=$converter_or->convert_file('examples/include/guide.xml');
like($md, qr/print "hello"/, 'external example text included');

my $temporary_dn=tempdir(CLEANUP => 1);
my $angle_fn=File::Spec->catfile($temporary_dn, 'angle.xml');
open(my $angle_fh, '>', $angle_fn) || die "unable to write $angle_fn: $!";
print {$angle_fh} <<'XML';
<article version="5.0" xmlns="http://docbook.org/ns/docbook">
  <title>Guide</title>
  <section xml:id="tag_perl">
    <title>&lt;perl&gt;</title>
    <para>Use &lt;perl&gt; when 4 &lt; 5.</para>
    <note><para>Note about &lt;perl&gt;.</para></note>
    <programlisting>&lt;perl&gt;</programlisting>
  </section>
</article>
XML
close($angle_fh) || die "unable to close $angle_fn: $!";
$md=$converter_or->convert_file($angle_fn);
like($md, qr/&lt;perl&gt;/, 'literal tags use portable HTML entities');
like($md, qr/4 &lt; 5/, 'literal comparison uses a portable HTML entity');
unlike($md, qr/\\[<>]/, 'prose does not use Pandoc-only angle escapes');
like($md, qr/^ {4}<perl>$/m, 'program listing remains literal');

eval { $converter_or->convert_file('missing.xml') };
like($@, qr/not found/, 'missing input is an error');
done_testing();
