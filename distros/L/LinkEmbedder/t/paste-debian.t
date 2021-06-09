use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
    'https://paste.debian.net/?show=1186554' => {
        cache_age        => 0,
        class            => 'le-paste le-provider-debian le-rich',
        html             => paste_debian_html(),
        isa              => 'LinkEmbedder::Link::Basic',
        provider_name    => 'Debian',
        provider_url     => 'https://paste.debian.net/?show=1186554',
        title            => 'debian Pastezone',
        type             => 'rich',
        url              => 'https://paste.debian.net/?show=1186554',
        version          => '1.0'
    }
);

done_testing;

sub paste_debian_html {
  return <<'HERE';
<div class="le-paste le-provider-debian le-rich">
  <div class="le-meta">
    <span class="le-provider-link"><a href="https://paste.debian.net/?show=1186554">Debian</a></span>
    <span class="le-goto-link"><a href="https://paste.debian.net/?show=1186554" title="debian Pastezone">View</a></span>
  </div>
  <pre>#!/bin/bash
theIp=$(printf &quot;&lt;redacted IPv6 prefix&gt;$(echo -n $1 | sha1sum | head -c 16 | sed &#39;s/..../:&amp;/g&#39;)\n&quot;)
echo &quot;User: $1&quot;
echo &quot;\&quot;$theIp/64\&quot;&quot;

## Example output
$ bash genip.sh Batman
User: Batman
&quot;&lt;redacted IPv6 prefix&gt;:32b2:6a27:1530:f105/64&quot;

</pre>
</div>
HERE
}

