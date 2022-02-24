<TMPL_IF NAME="AUTH_ERROR">
  <div class="message message-<TMPL_VAR NAME="AUTH_ERROR_TYPE"> alert" role="<TMPL_VAR NAME="AUTH_ERROR_ROLE">"><span trmsg="<TMPL_VAR NAME="AUTH_ERROR">"></span>
    <TMPL_IF LOCKTIME>
      <TMPL_VAR NAME="LOCKTIME"> <span trspan="seconds">seconds</span>.
    </TMPL_IF>
  </div>
</TMPL_IF>
