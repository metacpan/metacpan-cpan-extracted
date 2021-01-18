<TMPL_INCLUDE NAME="mail_header.tpl">

<p>
<span trspan="hello">Hello</span> $cn,<br />
<br />
<TMPL_IF NAME="RESET">
<span trspan="newPwdIs">Your new password is</span> 
<span><img src="cid:key:../common/key.png" alt="key"/></span>
<b>$password</b>
<TMPL_ELSE>
<span trspan="pwdChanged">Your password has been successfully changed!</span> 
</TMPL_IF>
</p>

<TMPL_INCLUDE NAME="mail_footer.tpl">
