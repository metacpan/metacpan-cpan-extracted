%# $Id: submitted.mc,v 1.10 2008-04-01 20:20:20 mike Exp $
<%args>
$_class
$_query => undef
$_first => 1
$_sort => undef
</%args>
<%perl>
my $site = $m->notes("site");
my $session = $m->notes("session");

my %query;
if (defined $_query) {
    %query = decode_hash(decode_utf8(uri_unescape($_query)));
    $query{_sort} = $_sort;
} else {
    %query = map { $_ => utf8param($r, $_) } utf8param($r);
}
my($rs, $errmsg) = $site->search($_class, %query);
if (!defined $rs) {
    $m->comp("/debug/fatal.mc", errmsg => $errmsg);
    $m->comp("/mc/newlink.mc", _class => $_class);
    return;
}

my $n = $rs->count();
if ($n > 0) {
    $session->update(query => encode_hash(%query));
    $m->comp("result.mc", _class => $_class, rs => $rs, first => $_first, _sort => $_sort);
    $m->comp("/mc/newlink.mc", _class => $_class);
} else {
</%perl>
      <p>
       <b>Sorry, no <% $_class %> matches your criteria.</b>
      </p>
      <p>
       Please <a href="./search.html?_class=<% $_class %>">try again</a>.
      </p>
% $m->comp("/mc/newlink.mc", _class => $_class);
% }
