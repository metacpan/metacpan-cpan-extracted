<TMPL_INCLUDE NAME="mail_header.tpl">

<p>
<lang en="Hello" fr="Bonjour" /> $firstname $lastname,<br />
<br />
<lang en="Your account was successfully created." fr="Votre compte a bien été créé." />
<br /> 
<br /> 
<lang en="Your login is" fr="Votre identifiant est" /> 
<span><img src="cid:key:skins/common/bullet_go.png" /></span>
<b>$login</b>
<br /> 
<lang en="Your password is" fr="Votre mot de passe est" /> 
<span><img src="cid:key:skins/common/key.png" /></span>
<b>$password</b>
</p>

<TMPL_INCLUDE NAME="mail_footer.tpl">
