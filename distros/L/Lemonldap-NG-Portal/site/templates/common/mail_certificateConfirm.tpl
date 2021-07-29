<TMPL_INCLUDE NAME="mail_header.tpl">

<p>
<span trspan="hello">Hello</span> <TMPL_VAR NAME="session_cn" ESCAPE=HTML>,<br />
<br />
<span><img src="cid:arrow:../common/bullet_go.png" alt="go"/></span>
<a href="<TMPL_VAR NAME="url" ESCAPE=HTML>" style="text-decoration:none;color:orange;">
<span trspan="click2ResetCertificate">Click here to reset your certificate</span>
</a>
</p>

<TMPL_INCLUDE NAME="mail_footer.tpl">
