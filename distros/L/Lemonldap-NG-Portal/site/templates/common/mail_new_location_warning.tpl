<TMPL_INCLUDE NAME="mail_header.tpl">

<p>
<span trspan="hello">Hello</span> <TMPL_VAR NAME="session_cn" ESCAPE=HTML>,<br />
<br />
<h3><span trspan="newLocationWarningMailBody">Your account was signed in to from a new location</span></h3></br>
<span trspan="location">Location</span> <b><TMPL_VAR NAME="location"></b></br>
<span trspan="date">Date</span> <b><TMPL_VAR NAME="date"></b></br>
<span trspan="UA">UA</span> <b><TMPL_VAR NAME="ua"></b></br>
</p>

<TMPL_INCLUDE NAME="mail_footer.tpl">
