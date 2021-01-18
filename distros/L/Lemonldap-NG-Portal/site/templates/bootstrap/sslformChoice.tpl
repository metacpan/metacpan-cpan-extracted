<!-- //if:jsminified
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/sslChoice.min.js"></script>
//else -->
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/sslChoice.js"></script>
<!-- //endif -->

<div class="form">
  <input type="hidden" name="nossl" value="1" />
  <div class="sslclick">
  <TMPL_IF NAME="logoFile">
    <img src="<TMPL_VAR NAME="STATIC_PREFIX">common/modules/<TMPL_VAR NAME="logoFile">" alt="<TMPL_VAR NAME="module">" class="img-thumbnail mb-3" />
  <TMPL_ELSE>
    <img src="<TMPL_VAR NAME="STATIC_PREFIX">common/modules/SSL.png" alt="<TMPL_VAR NAME="module">" class="img-thumbnail mb-3" />
  </TMPL_IF>

  </div>

  <TMPL_INCLUDE NAME="impersonation.tpl">
  <TMPL_INCLUDE NAME="checklogins.tpl">

  <button type="submit" class="btn btn-success sslclick" >
    <span class="fa fa-sign-in"></span>
    <span trspan="connect">Connect</span>
  </button>
</div>
