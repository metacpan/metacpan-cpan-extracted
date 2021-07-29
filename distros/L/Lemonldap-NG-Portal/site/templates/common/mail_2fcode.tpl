<TMPL_INCLUDE NAME="mail_header.tpl">

<span>
<span trspan="hello">Hello</span> <TMPL_VAR NAME="session_cn" ESCAPE=HTML>,<br />
<br />
<span trspan="yourLoginCodeIs">Your login code is</span>
<b><TMPL_VAR NAME="code" ESCAPE=HTML></b><br/>
</span>

<TMPL_INCLUDE NAME="mail_footer.tpl">
