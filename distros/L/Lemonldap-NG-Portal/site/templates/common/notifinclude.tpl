<TMPL_LOOP NAME="notifications">
<input type="hidden" name="reference<TMPL_VAR NAME="id">" value="<TMPL_VAR NAME="reference">"/>
<TMPL_IF NAME="title">
<h2 class="notifText"><TMPL_VAR NAME="title"></h2>
</TMPL_IF>
<TMPL_IF NAME="subtitle">
<h3 class="notifText"><TMPL_VAR NAME="subtitle"></h3>
</TMPL_IF>
<TMPL_IF NAME="text">
<p class="notifText"><TMPL_VAR NAME="text"></p>
</TMPL_IF>
<TMPL_LOOP NAME="check">
<p class="notifCheck">
  <div class="form-group form-check">
    <input class="form-check-input" type="checkbox" name="check<TMPL_VAR NAME="id">" id="<TMPL_VAR NAME="id">" value="accepted"/>
    <label class="form-check-label" for="<TMPL_VAR NAME="id">"><TMPL_VAR NAME="value"></label>
  </div>
</p>
</TMPL_LOOP>
</TMPL_LOOP>
