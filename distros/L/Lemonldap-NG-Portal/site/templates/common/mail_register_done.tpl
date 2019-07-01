<TMPL_INCLUDE NAME="mail_header.tpl">

<p>
<span trspan="hello">Hello</span> $firstname $lastname,<br />
<br />
<span trspan="accountCreated">Your account was successfully created.</span>
<br /> 
<br /> 
<span trspan="yourLoginIs">Your login is</span> 
<span><img src="cid:key:../common/bullet_go.png" /></span>
<b>$login</b>
<br /> 
<span trspan="pwdIs">Your password is</span> 
<span><img src="cid:key:../common/key.png" /></span>
<b>$password</b>
</p>
<p><a href="$url"><span trspan="goToPortal">Click here to access to portal</span></a></p>

<TMPL_INCLUDE NAME="mail_footer.tpl">
