%# $Id: record.mc,v 1.12 2008-02-08 12:37:07 mike Exp $
<%args>
$_class
$id
</%args>
<%perl>
my $site = $m->notes("site");
my $record = $site->db()->find1($_class, id => $id);
if (!defined $record) {
    print "<p>There is no $_class $id -- has it been deleted?</p>";
    print "<p>(That was a rhetorical question.)</p>";
    return;
}
</%perl>
   <h2><% encode_entities($_class . ": " . $record->render_name()) %></h2>
   <table class="center">
% my @df = $record->fulldisplay_fields();
% while (@df) {
%   my $field = shift @df;
%   my $fulltype = shift @df;
    <tr>
     <th><% encode_entities($record->label($field)) %></th>
<& /mc/displayfield.mc, context => "l", record => $record,
		 field => $field, fulltype => $fulltype &>
    </tr>
% }
   </table>
% my $user = $m->comp("/mc/utils/user.mc", require => 0);
% if (defined $user && $user->admin() > 0) {
     <p>
      <a href="./edit.html?_class=<% $_class %>&amp;id=<% $id %>">[Edit]</a>
      <a href="./edit.html?_class=<% $_class %>">[New]</a>
      <a href="./delete.html?_class=<% $_class %>&amp;id=<% $id %>">[Delete]</a>
     </p>
% }
