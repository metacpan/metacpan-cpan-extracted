  </div>

  <TMPL_IF NAME="SCROLL_TOP">
    <button type="button" class="btn btn-danger btn-floating btn-lg" id="btn-back-to-top">
      <span trspan="backToTop" hidden></span>  <i class="fa fa-chevron-up"></i>
    </button>
  </TMPL_IF>

  <div class="col-3 d-none d-xl-block" id="floating-menu"></div>

  <div id="footer">
    <div class="row">
    <div class="col-md-2"></div>
    <div class="col-md-8 col-10">
      <TMPL_INCLUDE NAME="customfooter.tpl">
    </div>
    <TMPL_IF NAME="LANGS">
    <div class="col-md-2 col-2 text-right">
      <span id="languages"></span>
    </div>
    </TMPL_IF>
    </div>
  </div>

<!-- Constants -->
<script type="text/JavaScript" src="<TMPL_VAR NAME="SCRIPTNAME">psgi.js"></script>
</body>
</html>

