%# $Id: delete.mc,v 1.3 2008-02-08 13:31:13 mike Exp $
<%args>
$_class
$id
$really => 0
</%args>
<%perl>
my $site = $m->notes("site");
my $record = $site->db()->find1($_class, id => $id);
if (!defined $record) {
    print "<p>There is no $_class $id -- has it been deleted?</p>";
    print "<p>(That was a rhetorical question.)</p>";
    return;
}
my @reasons = $record->undeletable();
if (@reasons) {
    print("<p>You can not delete this record because:</p>\n",
	  "<ul>\n",
	  join("", map { " <li>" . encode_entities($_) . "</li>\n" } @reasons),
	  "</ul>\n");
    return;
}
</%perl>
% if (!$really) {
     <h2>Warning</h2>
     <p class="error">
      Are you sure you want to delete
      <% $_class %> "<% encode_entities($record->render_name()) %>"?
     </p>
     <p>
      <a href="?really=1&amp;_class=<% $_class %>&amp;amp;id=<% encode_entities($id) %>">Yes</a><br/>
      <a href="record.html?_class=<% $_class %>&amp;id=<% encode_entities($id) %>">No</a><br/>
     </p>
% } else {
<%perl>
### We should refuse to do this if other records depend on it
$record->delete();
</%perl>
     <p>
      Deleted
      <% $_class %> "<% encode_entities($record->render_name()) %>".
     </p>
     <p>
      I hope you meant it.
     </p>
% }
