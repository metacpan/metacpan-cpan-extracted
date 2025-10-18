<!-- //if:jsminified
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/ssl.min.js?v=<TMPL_VAR CACHE_TAG>"></script>
//else -->
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/ssl.js?v=<TMPL_VAR CACHE_TAG>"></script>
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
</div>

<TMPL_IF NAME="DISPLAY_FINDUSER">
  <div class="actions">
  <button type="button" class="btn btn-secondary" data-toggle="modal" data-target="#finduserModal">
    <span class="fa fa-search"></span>
    <span trspan="searchAccount">Search for an account</span>
  </button>
  </div>
</TMPL_IF>
