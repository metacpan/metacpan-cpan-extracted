<h3 trspan="redirectionToIdp">Redirection to your Identity Provider</h3>
<h4><TMPL_VAR NAME="name"></h4>
<p><i><TMPL_VAR NAME="idp"></i></p>
<TMPL_IF NAME="url">
  <input type="hidden" name="url" value="<TMPL_VAR NAME="url">" />
</TMPL_IF>
<input type="hidden" name="idp" value="<TMPL_VAR NAME="idp">" />
