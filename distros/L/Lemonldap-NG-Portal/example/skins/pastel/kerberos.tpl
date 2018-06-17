<TMPL_IF NAME="KRBAUTO">
<script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/js/kerberos.js"></script>
<div class="alert alert-info"><lang en="Authentication in progress, please wait" fr="Authentification en cours, merci de patienter" /></div>
</TMPL_IF>
<span id="purl" val="<TMPL_VAR NAME="PORTAL_URL">"></span>
<input type="hidden" name="kerberos" value="0" />
