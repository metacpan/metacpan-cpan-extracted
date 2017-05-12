#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use Test::Differences qw(eq_or_diff);

package MyLink;

sub new
{
    my $class = shift;
    my $self = shift;
    bless $self, $class;
    return $self;
}

sub direct_url
{
    my $self = shift;

    return $self->{direct_url};
}

package main;

use HTML::Latemp::NavLinks::GenHtml::ArrowImages;

{
    my $obj =  HTML::Latemp::NavLinks::GenHtml::ArrowImages->new(
        root => "../../",
        nav_links_obj => {
            'up' => MyLink->new({direct_url => "my-up-url.html" }),
            'next' => MyLink->new({direct_url => "the-NExT-URL.xhtml" }),
            'prev' => MyLink->new({direct_url => "../A-Better-pREVIOUS-URL/" }),
        }
    );

    # TEST
    ok ($obj, "Testing that \$obj is ok.");

    my $expected = <<'EOF';
<ul class="nav_links">
<li>
<a href="../A-Better-pREVIOUS-URL/" title="Previous Page (Alt+P)"
><img src="../..//images/arrow-left.png"
alt="Previous Page" class="bless" /></a>
</li>
<li>
<a href="my-up-url.html" title="Up in the Site (Alt+U)"
><img src="../..//images/arrow-up.png"
alt="Up in the Site" class="bless" /></a>
</li>
<li>
<a href="the-NExT-URL.xhtml" title="Next Page (Alt+N)"
><img src="../..//images/arrow-right.png"
alt="Next Page" class="bless" /></a>
</li>

</ul>
EOF
    chomp($expected);
    # TEST
    eq_or_diff ($obj->get_total_html(), $expected,
        "Testing that the output is OK."
    );
}

{
    my $obj =  HTML::Latemp::NavLinks::GenHtml::ArrowImages->new(
        root => "../../",
        ext => '.svg',
        nav_links_obj => {
            'up' => MyLink->new({direct_url => "my-up-url.html" }),
            'next' => MyLink->new({direct_url => "the-NExT-URL.xhtml" }),
            'prev' => MyLink->new({direct_url => "../A-Better-pREVIOUS-URL/" }),
        }
    );

    # TEST
    ok ($obj, "Testing that \$obj is ok.");

    my $expected = <<'EOF';
<ul class="nav_links">
<li>
<a href="../A-Better-pREVIOUS-URL/" title="Previous Page (Alt+P)"
><img src="../..//images/arrow-left.svg"
alt="Previous Page" class="bless" /></a>
</li>
<li>
<a href="my-up-url.html" title="Up in the Site (Alt+U)"
><img src="../..//images/arrow-up.svg"
alt="Up in the Site" class="bless" /></a>
</li>
<li>
<a href="the-NExT-URL.xhtml" title="Next Page (Alt+N)"
><img src="../..//images/arrow-right.svg"
alt="Next Page" class="bless" /></a>
</li>

</ul>
EOF
    chomp($expected);

    # TEST
    eq_or_diff ($obj->get_total_html(), $expected,
        "Testing that the output is OK."
    );
}
