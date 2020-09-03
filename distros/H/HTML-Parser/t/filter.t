use strict;
use warnings;

use HTML::Filter;
use SelectSaver;

use Test::More tests => 3;

my $HTML = <<EOT;

<!DOCTYPE HTML>
<!-- comment
<h1>Foo</h1>
-->

<H1
>Bar</H1
>

<Table><tr><td>1<td>2<td>3
<tr>
</table>

<?process>

EOT


my $tmpfile = "test-$$.htm";
die "$tmpfile already exists" if -e $tmpfile;

{
    open(my $fh, '>', $tmpfile) or die "$!";
    my $save = SelectSaver->new($fh);
    HTML::Filter->new->parse($HTML)->eof;
    close($fh);
}
{
    open(my $fh, '<', $tmpfile) or die "$!";
    local $/;
    my $FILTERED = <$fh>;
    close($fh);

    #print $FILTERED;
    is($FILTERED, $HTML);
}

{

    package MyFilter;
    use strict;
    use warnings;
    require HTML::Filter;
    our @ISA = qw(HTML::Filter);
    sub comment       { }
    sub output        { push(@{$_[0]->{fhtml}}, $_[1]) }
    sub filtered_html { join("", @{$_[0]->{fhtml}}) }
    1;
}

my $f2 = MyFilter->new->parse_file($tmpfile)->filtered_html;
unlink($tmpfile) or warn "Can't unlink $tmpfile: $!";

#diag $f2;

unlike($f2, qr/Foo/);
like($f2, qr/Bar/);
