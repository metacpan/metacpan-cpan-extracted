<!-- //if:jsminified
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/ssl.min.js?v=<TMPL_VAR CACHE_TAG>"></script>
//else -->
<script type="text/javascript" src="<TMPL_VAR NAME="STATIC_PREFIX">common/js/ssl.js?v=<TMPL_VAR CACHE_TAG>"></script>
<!-- //endif -->

<div class="form">
  <input type="hidden" name="nossl" value="1" />
  <div class="sslclick">
    <img src="<TMPL_VAR NAME="STATIC_PREFIX">common/modules/SSL.png" alt="<TMPL_VAR NAME="module">" class="img-thumbnail mb-3" />
  </div>

  <TMPL_INCLUDE NAME="impersonation.tpl">
  <TMPL_INCLUDE NAME="checklogins.tpl">

  <button type="submit" class="btn btn-success sslclick" >
    <span class="fa fa-sign-in"></span>
    <span trspan="connect">Connect</span>
  </button>
</div>

<TMPL_IF NAME="DISPLAY_FINDUSER">
  <div class="actions">
  <button type="button" class="btn btn-secondary" data-toggle="modal" data-target="#finduserModal">
    <span class="fa fa-search"></span>
    <span trspan="searchAccount">Search for an account</span>
  </button>
  </div>
</TMPL_IF>
