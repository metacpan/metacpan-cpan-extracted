<TMPL_INCLUDE NAME="mail_header.tpl">

<p>
<span trspan="hello">Hello</span> <TMPL_VAR NAME="firstname" ESCAPE=HTML> <TMPL_VAR NAME="lastname" ESCAPE=HTML>,<br />
<br />
<span trspan="accountCreated">Your account was successfully created.</span>
<br /> 
<br /> 
<span trspan="yourLoginIs">Your login is</span> 
<span><img src="cid:arrow:../common/bullet_go.png" alt="go"/></span>
<b><TMPL_VAR NAME="login" ESCAPE=HTML></b>
<br /> 
<span trspan="pwdIs">Your password is</span> 
<span><img src="cid:key:../common/key.png" alt="key"/></span>
<b><TMPL_VAR NAME="password" ESCAPE=HTML></b>
</p>
<p><a href="<TMPL_VAR NAME="url" ESCAPE=HTML>"><span trspan="goToPortal">Click here to access to portal</span></a></p>

<TMPL_INCLUDE NAME="mail_footer.tpl">
