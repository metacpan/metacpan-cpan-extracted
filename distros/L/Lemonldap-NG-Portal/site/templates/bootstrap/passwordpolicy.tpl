<div id="ppolicy" class="card p-3 mb-3 border-danger ppolicy">
  <span trspan="passwordPolicy">Please respect the following password policy:</span>
  <ul class="fa-ul text-left">
    <TMPL_LOOP NAME="PPOLICY_RULES">
        <TMPL_IF NAME="condition">
        <TMPL_IF NAME="customHtml"><TMPL_VAR NAME="customHtml"></TMPL_IF>
        <li>
            <i id="<TMPL_VAR NAME="id">-feedback" class="fa fa-li"> </i>
            <span trspan="<TMPL_VAR NAME="label">"<TMPL_LOOP NAME="data"> data-<TMPL_VAR key>="<TMPL_VAR value ESCAPE="html">"</TMPL_LOOP>></span> <TMPL_IF NAME="value"><TMPL_VAR NAME="value" ESCAPE="html"></TMPL_IF>
            <TMPL_IF NAME="customHtmlAfter"><TMPL_VAR NAME="customHtmlAfter"></TMPL_IF>
        </li>
        </TMPL_IF>
    </TMPL_LOOP>
    <li>
        <i id="samepassword-feedback" class="fa fa-li"> </i>
        <span trspan="passwordPolicySamePwd"></span>
    </li>
  </ul>
</div>
