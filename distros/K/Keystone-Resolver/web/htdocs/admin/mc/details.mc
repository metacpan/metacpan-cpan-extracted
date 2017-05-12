%# $Id: details.mc,v 1.6 2008-01-29 14:48:59 mike Exp $
% my $user = $m->comp("/mc/utils/user.mc", require => 1) or return;
<%perl>
my $status = 0;
my $complete = 1;
foreach my $fieldname (qw(name email_address)) {
    $complete = 0 if !utf8param($r, $fieldname);
}

if (defined utf8param($r, "update") && $complete) {
    my %data;
    foreach my $key (grep { $_ ne "update" } utf8param($r)) {
	$data{$key} = utf8param($r, $key);
    }
    $user->update(%data);
    $status = 1;
}

# For fields not specified in CGI parameters, fill in from DB
foreach my $fieldname (qw(name email_address)) {
    if (!defined utf8param($r, $fieldname)) {
	utf8param($r, $fieldname, encode_utf8($user->field($fieldname)));
    }
}
</%perl>
     <form method="get" action="">
      <p>
% if ($status == 1) {
       <b>Your details have been updated.  Thank you.</b>
% } else {
       You can use this form to update your personal details.
% }
      </p>
      <table>
% my @params = (obj => $user, submitted => (defined utf8param($r, "update")));
<& /mc/form/textbox.mc, @params, name => "name" &>
<& /mc/form/textbox.mc, @params, name => "email_address" &>
       <tr>
        <td></td>
        <td align="right">
	 <input type="submit" name="update" value="Update"/>
        </td>
       </tr>
      </table>
     </form>
