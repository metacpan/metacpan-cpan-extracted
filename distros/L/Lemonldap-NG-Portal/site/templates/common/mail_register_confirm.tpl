<TMPL_INCLUDE NAME="mail_header.tpl">

<p>
<span trspan="hello">Hello</span> <TMPL_VAR NAME="firstname" ESCAPE=HTML> <TMPL_VAR NAME="lastname" ESCAPE=HTML>,<br />
<br />
<span><img src="cid:arrow:../common/bullet_go.png" alt="go"/></span>
<a href="<TMPL_VAR NAME="url" ESCAPE=HTML>" style="text-decoration:none;color:orange;">
<span trspan="click2Register">Click here to confirm your account registration</span>
</a>
</p>

<TMPL_INCLUDE NAME="mail_footer.tpl">
