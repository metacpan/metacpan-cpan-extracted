<div class="card p-3 mb-3 border-danger ppolicy">
  <span trspan="passwordPolicy">Please respect the following password policy:</span>
  <ul class="fa-ul text-left">
    <TMPL_IF NAME="PPOLICY_MINSIZE">
    <li>
        <i id="ppolicy-minsize-feedback" class="fa fa-li"> </i>
        <span trspan="passwordPolicyMinSize">Minimal size:</span> <TMPL_VAR NAME="PPOLICY_MINSIZE">
    </li>
    </TMPL_IF>
    <TMPL_IF NAME="PPOLICY_MINLOWER">
    <li>
        <i id="ppolicy-minlower-feedback" class="fa fa-li"> </i>
        <span trspan="passwordPolicyMinLower">Minimal lower characters:</span> <TMPL_VAR NAME="PPOLICY_MINLOWER">
    </li>
    </TMPL_IF>
    <TMPL_IF NAME="PPOLICY_MINUPPER">
    <li>
        <i id="ppolicy-minupper-feedback" class="fa fa-li"> </i>
        <span trspan="passwordPolicyMinUpper">Minimal upper characters:</span> <TMPL_VAR NAME="PPOLICY_MINUPPER">
    </li>
    </TMPL_IF>
    <TMPL_IF NAME="PPOLICY_MINDIGIT">
    <li>
        <i id="ppolicy-mindigit-feedback" class="fa fa-li"> </i>
        <span trspan="passwordPolicyMinDigit">Minimal digit characters:</span> <TMPL_VAR NAME="PPOLICY_MINDIGIT">
    </li>
    </TMPL_IF>
    <TMPL_IF NAME="PPOLICY_MINSPECHAR">
    <li>
        <i id="ppolicy-minspechar-feedback" class="fa fa-li"> </i>
        <span trspan="passwordPolicyMinSpeChar">Minimal special characters:</span> <TMPL_VAR NAME="PPOLICY_MINSPECHAR">
    </li>
    </TMPL_IF>
    <TMPL_IF NAME="PPOLICY_ALLOWEDSPECHAR">
    <li>
        <i id="ppolicy-allowedspechar-feedback" class="fa fa-li"> </i>
        <span trspan="passwordPolicySpecialChar">Allowed special characters:</span> <TMPL_VAR NAME="PPOLICY_ALLOWEDSPECHAR">
    </li>
    </TMPL_IF>
    <TMPL_IF NAME="ENABLE_CHECKHIBP">
    <li>
        <i id="ppolicy-checkhibp-feedback" class="fa fa-li"> </i>
        <span trspan="passwordCompromised">Password compromised</span>
    </li>
    </TMPL_IF>
  </ul>
  <TMPL_IF NAME="PPOLICY_NOPOLICY">
    <span trspan="passwordPolicyNone">You are free to choose your password! ;-)</span>
  </TMPL_IF>
</div>
