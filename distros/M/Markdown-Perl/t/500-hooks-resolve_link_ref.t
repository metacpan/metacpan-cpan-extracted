use strict;
use warnings;
use utf8;

use Markdown::Perl 'convert', 'set_hooks';
use Test2::V0;

sub hook {
  my ($ref) = @_;
  if ($ref eq 'foo') {
    return { target => 'http://foo' };
  } elsif ($ref eq 'bar') {
    return { target => 'http://bar', title => 'BAR' };
  }
  return;
}

set_hooks(resolve_link_ref => \&hook);
is(convert("[text][foo]"), "<p><a href=\"http://foo\">text</a></p>\n", 'resolved in full link reference');
is(convert("[foo][]"), "<p><a href=\"http://foo\">foo</a></p>\n", 'resolved in collapsed link reference');
is(convert("[foo]"), "<p><a href=\"http://foo\">foo</a></p>\n", 'resolved in shortcut link reference');

is(convert("[bar]"), "<p><a href=\"http://bar\" title=\"BAR\">bar</a></p>\n", 'resolved with title');
is(convert("[none]"), "<p>[none]</p>\n", 'not resolved');

is(convert("[foo]\n\n[foo]: http://other"), "<p><a href=\"http://other\">foo</a></p>\n", 'source has precedence');

{
  my $p = Markdown::Perl->new();
  is($p->convert("[foo]"), "<p>[foo]</p>\n", 'no default hook');
  $p->set_hooks(resolve_link_ref => \&hook); 
  is($p->convert("[foo]"), "<p><a href=\"http://foo\">foo</a></p>\n", 'set_hooks object-oriented');
}

set_hooks(resolve_link_ref => undef);
is(convert("[foo]"), "<p>[foo]</p>\n", 'hook can be removed');

done_testing;
