<TMPL_INCLUDE NAME="mail_header.tpl">

<p>
<lang en="Hello" fr="Bonjour" /> $cn,<br />
<br />
<TMPL_IF NAME="RESET">
<lang en="Your new password is" fr="Votre nouveau mot de passe est" /> 
<span><img src="cid:key:skins/common/key.png" /></span>
<b>$password</b>
<TMPL_ELSE>
<lang en="Your password was changed." fr="Votre mot de passe a été changé." /> 
</TMPL_IF>
</p>

<TMPL_INCLUDE NAME="mail_footer.tpl">
