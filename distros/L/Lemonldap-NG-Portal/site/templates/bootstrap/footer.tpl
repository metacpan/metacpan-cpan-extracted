  </div>

<TMPL_IF NAME="SCROLL_TOP">
  <button type="button" class="btn btn-danger btn-floating btn-lg" id="btn-back-to-top">
    <i class="fa fa-arrow-circle-up"></i>
  </button>
</TMPL_IF>

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

