# -*-perl-*-

use strict;
use MT::Template::Context;

MT::Template::Context->add_tag(PingedUrls => sub {
    my $ctx = shift;

    if (my $entry = $ctx->stash("entry")) {
	return $entry->pinged_urls() || "";
    }

    return "";
});

return 1;
