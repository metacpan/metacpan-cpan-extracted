use strict;
use warnings;
use Test::More;
use HTML::TreeBuilder::LibXML;

plan skip_all => "this test requires Web::Query" unless eval "use Web::Query; 1";
plan tests => 6;

can_ok 'HTML::TreeBuilder::LibXML', 'parse_content';
can_ok 'HTML::TreeBuilder::LibXML', 'elementify';

my $html = <<'...';
<html>
    <body>
        <div id="userbox">
            <div id="user">
                <a href="https://github.com/olegwtf"><img height="20" src="gravatar-140.png" width="20" /></a>
                <a href="https://github.com/olegwtf" class="name">olegwtf</a>
            </div>

            <ul id="user-links">
                <li>
                    <a href="/inbox/notifications" id="notifications" class="tooltipped downwards">
                        <span class="notifications"></span>
                    </a>
                </li>
                <li>
                    <a href="/settings/profile" id="settings" class="tooltipped downwards" title="Account Settings">
                        <span class="account-settings"></span>
                    </a>
                </li>
                <li>
                    <a href="/logout" data-method="post" id="logout" class="tooltipped downwards" title="Log Out">
                        <span class="logout">Log Out</span>
                    </a>
                </li>
            </ul>
        </div>
    </body>
</html>
...

sub run {
    my @classes;
    
    my $text = wq($html)->find("ul#user-links li")->each(sub {
        push @classes, $_->find("a span")->attr("class");
    })->end->find(".logout")->text;
    
    return (\@classes, $text);
}

isa_ok(HTML::TreeBuilder::XPath->new, 'HTML::TreeBuilder::XPath');
my ($their_classes, $their_text) = &run;

HTML::TreeBuilder::LibXML->replace_original();

isa_ok(HTML::TreeBuilder::XPath->new, 'HTML::TreeBuilder::LibXML');
my ($our_classes, $our_text) = &run;

is($our_text, $their_text);
is_deeply($our_classes, $their_classes);
