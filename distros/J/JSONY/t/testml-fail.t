#!inc/bin/testml-cpan

# Make sure these strings do not parse as JSONY.
*jsony.jsony-load.Catch.Type == 'error'

=== Comma in bareword
--- jsony: { url: http://foo.com,2012 }

=== Unmatched [
--- jsony: foo[bar
