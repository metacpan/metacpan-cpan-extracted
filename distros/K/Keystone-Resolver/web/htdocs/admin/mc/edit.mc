%# $Id: edit.mc,v 1.19 2008-01-29 14:48:59 mike Exp $
<%args>
$_class
$id => undef
$_update => undef
</%args>
<%perl>
my $user = $m->comp("/mc/utils/user.mc", require => 1) or return;
if ($user->admin() == 0) {
    return $m->comp("/mc/error.mc", msg => "Normal users may not edit");
}

### Should require $record->mandatory_fields()
my %data = map { $_ => utf8param($r, $_) } grep { !/^_/ } utf8param($r);
delete $data{id};
my $db = $m->notes("site")->db();
my $record;

if (defined $id && $id ne "") {
    $record = $db->find1($_class, id => $id);
    return $m->comp("error.mc", msg => "no $_class with id=$id")
	if !defined $record;
    if (defined $_update) {
	my $nchanges = $record->update(%data);
	if ($nchanges == 0) {
	    print "<p>No changes!</p>\n";
	} else {
	    print("<p>Updated with $nchanges change",
		  ($nchanges == 1 ? "" : "s"), ".</p>\n");
	}
    }
} else {
    my $fullclass = "Keystone::Resolver::DB::$_class";
    if (defined $_update) {
	$record = $fullclass->create($db, %data);
	$id = $record->id();
    } else {
	$record = $fullclass->new($db)
    }
}

</%perl>
   <h2><% encode_entities($_class . ": " . $record->render_name()) %></h2>
   <form method="get" action="">
   <table class="center">
<%perl>
my @df = $record->editable_fields();
my $idField = 0;
while (@df) {
    my $field = shift @df;
    my $fulltype = shift @df;
    $idField++ if $field eq "id";
</%perl>
    <tr>
     <th><% encode_entities($record->label($field)) %></th>
<& /mc/editfield.mc, record => $record,
	field => $field, fulltype => $fulltype,
	newrecord => !defined $id &>
    </tr>
% }
    <tr>
     <td colspan="2" style="text-align: right">
      <input type="hidden" name="_class" value="<% $_class %>"/>
% if ($idField == 0) {
      <input type="hidden" name="id" value="<% $id %>"/>
% }
      <input type="submit" name="_update" value="Update"/>
     </td>
    </tr>
   </table>
   </form>
