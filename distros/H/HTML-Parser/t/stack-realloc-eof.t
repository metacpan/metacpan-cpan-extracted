use strict;
use warnings;

use HTML::Parser ();
use Test::More tests => 2;

# HTML-Parser core dumps on this because
# of missing SPAGAIN calls in parse() XS code.  It was not prepared for
# the stack to get realloced.

my $em = <<'EOF';
<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /></head><body style='font-size: 10pt; font-family: Verdana,Geneva,sans-serif'>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
<p><span style="font-size: 10.0pt; font-family: 'Verdana','sans-serif';">cat</span></p>
</body></html>
EOF

sub handle_doc_end {
    my ($self) = @_;

    # We need to construct a large list and then splice it in array context, this will
    # cause splice to regrow the stack and mess up the stack pointer in Parser.xs's eof
    my @list;

    for (1..150) {
       push @list, 1; # { $_ => 1 };
    }

    # ok(1, 'splicing');

    foreach my $i (splice(@list)) { }

    # ok(1, 'done splicing');
}

sub extract {
    my $markup = shift;

    my $parser = HTML::Parser->new(
        api_version => 3,
        handlers => {
            end_document => [\&handle_doc_end => 'self']
        },
    );
    $parser->empty_element_tags(1);
    $parser->parse($markup);
    $parser->eof();
    return 1;
}

ok(extract($em), 'first call okay');
ok(extract($em), 'second call okay');
