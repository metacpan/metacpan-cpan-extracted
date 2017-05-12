%# $Id: form.mc,v 1.4 2008-01-29 14:49:01 mike Exp $
<%args>
$submitted
</%args>
% my @params = (submitted => $submitted);
     <p>
      Please enter your <b>email address</b> and <b>password</b> to
      login:
     </p>
     <p>&nbsp;</p>
     <form method="get" action="./login.html">
      <table>
<& /mc/form/textbox.mc, @params,
	name => "email_address", label => "Email&nbsp;address" &>
<& /mc/form/error.mc, @params, cond => !(utf8param($r, "email_address")),
	msg => "Please enter your email address!" &>
<& /mc/form/password.mc, @params,
	name => "password", label => "Password" &>
<& /mc/form/error.mc, @params, cond => !(utf8param($r, "password")),
	msg => "Please enter your password!" &>
       <tr>
        <td></td>
        <td align="right">
	 <input type="submit" name="login" value="Login"/>
        </td>
       </tr>
<& /mc/form/separator.mc &>
       <tr>
	<td></td>
	<td>
	 If you have forgotten your password, enter your email address
	 above and click to request a ...
	 <div class="right">
	  <input type="submit" name="remind" value="Reminder"/>
	 </div>
	</td>
       </tr>
<& /mc/form/separator.mc &>
       <tr>
	<td></td>
	<td>
	 If you don't have an account yet, enter your email address
	 above and click to ...
	 <div class="right">
	  <input type="submit" name="register" value="Register"/>
	 </div>
	</td>
       </tr>
      </table>
     </form>
