%# $Id: password.mc,v 1.3 2007-06-21 14:19:09 mike Exp $
<%perl>
my $user = $m->comp("/mc/utils/user.mc", require => 1) or return;
my $submitted = utf8param($r, "update");
my $match = ($user->password() eq utf8param($r, "current"));
my $new1 = utf8param($r, "new1");
my $new2 = utf8param($r, "new2");
my $same = ($new1 eq $new2);
if ($submitted && $match && $new1 && $new2 && $same) {
    $user->update(password => $new1);
    print "<p><b>Your password has been updated.</b></p>\n";
    return;
}
my @params = (obj => $user, submitted => $submitted);
</%perl>
     <form method="get" action="">
      <p>
       Please re-enter your current password, and choose a new one:
      </p>
      <table>
<& /mc/form/password.mc, @params, name => "current",
	label => "Current password" &>
<& /mc/form/error.mc, @params, cond => !$match,
	msg => "Incorrect password" &>
<& /mc/form/password.mc, @params, name => "new1", mandatory => 1,
	label => "New password" &>
<& /mc/form/password.mc, @params, name => "new2", mandatory => 1,
	label => "Re-enter new password" &>
<& /mc/form/error.mc, @params, cond => !$same,
	msg => "Entered passwords are not the same" &>
       <tr>
        <td></td>
        <td align="right">
	 <input type="submit" name="update" value="Update"/>
        </td>
       </tr>
      </table>
     </form>

