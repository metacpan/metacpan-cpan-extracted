<div class="alert alert-info text-left mb-3 ppolicy">
  <span trspan="passwordPolicy">Please respect the following password policy:</span>
  <ul>
    <TMPL_IF NAME="PPOLICY_MINSIZE">
    <li><span trspan="passwordPolicyMinSize">Minimal size:</span> <TMPL_VAR NAME="PPOLICY_MINSIZE"></li>
    </TMPL_IF>
    <TMPL_IF NAME="PPOLICY_MINLOWER">
    <li><span trspan="passwordPolicyMinLower">Minimal lower characters:</span> <TMPL_VAR NAME="PPOLICY_MINLOWER"></li>
    </TMPL_IF>
    <TMPL_IF NAME="PPOLICY_MINUPPER">
    <li><span trspan="passwordPolicyMinUpper">Minimal upper characters:</span> <TMPL_VAR NAME="PPOLICY_MINUPPER"></li>
    </TMPL_IF>
    <TMPL_IF NAME="PPOLICY_MINDIGIT">
    <li><span trspan="passwordPolicyMinDigit">Minimal digit characters:</span> <TMPL_VAR NAME="PPOLICY_MINDIGIT"></li>
    </TMPL_IF>
    <TMPL_IF NAME="PPOLICY_MINSPECHAR">
    <li><span trspan="passwordPolicyMinSpeChar">Minimal special characters:</span> <TMPL_VAR NAME="PPOLICY_MINSPECHAR"></li>
    </TMPL_IF>
    <TMPL_IF NAME="PPOLICY_ALLOWEDSPECHAR">
    <li><span trspan="passwordPolicySpecialChar">Allowed special characters:</span> <TMPL_VAR NAME="PPOLICY_ALLOWEDSPECHAR"></li>
    </TMPL_IF>
  </ul>
  <TMPL_IF NAME="PPOLICY_NOPOLICY">
    <span trspan="passwordPolicyNone">You are free to choose your password! ;-)</span>
  </TMPL_IF>
</div>
