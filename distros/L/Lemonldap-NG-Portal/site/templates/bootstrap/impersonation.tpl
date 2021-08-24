<TMPL_IF NAME="IMPERSONATION">
	<div class="input-group mb-3">
	  <div class="input-group-prepend">
	  <span class="input-group-text"><label for="spoofIdfield" class="mb-0"><i class="fa fa-user icon-blue"></i></label></span>
	  </div>
	  <input name="spoofId" type="text" class="form-control" value="<TMPL_VAR NAME="SPOOFID">" autocomplete="off" trplaceholder="spoofId" aria-required="false"/>
	</div>
</TMPL_IF>
