<div class="oidc_consent_message">
 <TMPL_IF NAME="imgUrl">
  <img src="<TMPL_VAR NAME="imgUrl">" />
 </TMPL_IF>
 <h3 trspan="oidcConsent,<TMPL_VAR NAME="displayName">"></h3>
 <ul>
  <TMPL_LOOP NAME="list">
   <li>
    <span trspan="<TMPL_VAR NAME="m">"><TMPL_VAR NAME="m"></span>
    <TMPL_IF NAME="n">
     <i>(<TMPL_VAR NAME="n" ESCAPE=HTML>)</i>
    </TMPL_IF>
   </li>
  </TMPL_LOOP>
 </ul>
</div>
