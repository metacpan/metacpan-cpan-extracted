# Comparison before the first release

Reviewed 6 October 2026. This is a scoped comparison of documented interfaces, not proof that no other CPAN module can perform these checks.

| Tool | Documented purpose | Relationship to this module |
| --- | --- | --- |
| [HTML::SimpleLinkExtor](https://metacpan.org/pod/HTML::SimpleLinkExtor) | Extract links from HTML | Good extraction API; does not document this report contract for target resolution and Unicode source positions. |
| [WWW::LinkRot](https://metacpan.org/pod/WWW::LinkRot) | Validate remote link status | Use for remote URLs; this module deliberately performs no requests. |
| [HTML::Lint](https://metacpan.org/pod/HTML::Lint) | Check general HTML errors | Use for broader linting; this library specializes in section-link reports. |
| [W3C Link Checker](https://metacpan.org/dist/W3C-LinkChecker/view/bin/checklink.pod) | Check dereferenceable links, fragments and duplicate anchors; includes crawling | Substantial functional overlap. Prefer it for crawling. This library offers a smaller in-memory offline interface returning source-located Perl data and NFC hints. |

HTML::Parser is reused for tokenization rather than implementing an HTML tokenizer. Fragment matching follows the relevant parts of the [HTML Standard](https://html.spec.whatwg.org/multipage/browsing-the-web.html#scroll-to-fragid), within the documented source-only limits. This module is not an HTML5 DOM reconstruction library.

The MetaCPAN API returned 404 for the proposed namespace HTML::Anchor::Audit on 6 October 2026. This is only a point-in-time check; PAUSE will make the authoritative indexing/permissions decision after upload.
