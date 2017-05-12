%# $Id: result.mc,v 1.11 2008-04-02 12:49:30 mike Exp $
<%args>
$_class
$rs
$first
$last => undef
$pagesize => 10
$_sort
</%args>
<%perl>
my $site = $m->notes("site");
my $n = $rs->count();
if (!defined $last) {
    $last = $first + $pagesize-1;
    $last = $n if $last > $n;
}
my $fullclass = "Keystone::Resolver::DB::$_class";
my @df = $fullclass->display_fields();
my $baseURL = "./search.html?_class=$_class&amp;_query=" .
    uri_escape_utf8(encode_hash(%{ $rs->query() }));
my $sortArg = defined $_sort ? "&amp;_sort=$_sort" : "";
</%perl>
     <p></p>
<& nav, rs => $rs, first => $first, last => $last, pagesize => $pagesize,
	baseURL => $baseURL . $sortArg &>
     <p></p>
     <table class="center">
      <thead>
       <tr>
% my %fields = $fullclass->fields();
% while (@df) {
% my $field = shift @df;
% my $unused_type = shift @df;
% my $sort = utf8param($r, "_sort");
% $sort = defined $sort && $sort eq $field ? "$field desc" : $field;
        <th>
<%perl>
my $sortable = !ref $fields{$field};
print '<a href="' . "$baseURL&amp;_sort=" . uri_escape_utf8($sort) . '">' if $sortable;
print encode_entities($fullclass->label($field));
print '</a>' if $sortable;
</%perl>
        </th>
% }
% my $user = $m->comp("/mc/utils/user.mc", require => 0);
% if (defined $user && $user->admin() > 0) {
%     print qq[     <th>&nbsp;</th>\n];
% }
       </tr>
      </thead>
      <tbody>
% foreach my $i ($first..$last) {
%     my($record, $errmsg) = $rs->fetch($i);
%     if (defined $record) {
% 	$m->comp("shortrecord.mc", record => $record);
%     } else {
      <tr>
       <td colspan="2">
	<p class="error"><% $errmsg %></p>
       </td>
      </tr>
%     }
% }
      </tbody>
     </table>
     <p></p>
<& nav, rs => $rs, first => $first, last => $last, pagesize => $pagesize,
	baseURL => $baseURL . $sortArg &>
<%def nav>
<%args>
$rs
$first
$last
$pagesize
$baseURL
</%args>
<%perl>
my $fullclass = $rs->class();
(my $_class = $fullclass) =~ s/^Keystone::Resolver::DB:://;
my $n = $rs->count();
my $ptext = "&lt;&lt;&nbsp;Prev";
my $ntext = "Next&nbsp;&gt;&gt;";

my($prev, $next);
if ($first > 1) {
    my $newstart = $first-$pagesize;
    $newstart = 1 if $newstart < 1;
    $prev = qq[<a href="${baseURL}&amp;_first=$newstart">$ptext</a>];
} else {
    $prev = qq[<span class="disabled">$ptext</span>];
}
if ($last < $n) {
    my $newstart = $first+$pagesize;
    $newstart = 1 if $newstart < 1;
    $next = qq[<a href="${baseURL}&amp;_first=$newstart">$ntext</a>];
} else {
    $next = qq[<span class="disabled">$ntext</span>];
}
my $which = ($first == 1 && $last == $n) ? "All" : "$first to $last of";
</%perl>
     <table border="0" cellpadding="0" cellspacing="0">
      <tr>
       <td align="left" valign="top">
	<% $prev %>
       </td>
       <td>&nbsp;&nbsp;</td>
       <td align="center">
        <b><% $which %> <% $n %> matching <% $_class %> records</b>
       </td>
       <td>&nbsp;&nbsp;</td>
       <td align="right" valign="top">
	<% $next %>
       </td>
      </tr>
     </table>
</%def>
