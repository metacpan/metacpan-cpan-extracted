<h3 trspan="openidAp"></h3>
<table class="openidsreg">
 <tbody>
 <TMPL_LOOP NAME="required">
  <tr class="required">
   <td>
    <input type="checkbox" disabled="disabled" checked="checked"/>
   </td>
   <td>
    <TMPL_VAR NAME="k">
   </td>
   <td>
    <TMPL_VAR NAME="m">
   </td>
  </tr>
 </TMPL_LOOP>
 <TMPL_LOOP NAME="optional">
  <tr class="optional">
   <td>
    <input type="checkbox" value="OK" checked="<TMPL_VAR NAME="c">" name="sreg_<TMPL_VAR NAME="k">" />
   </td>
   <td>
    <TMPL_VAR NAME="k">
   </td>
   <td>
    <TMPL_VAR NAME="m">
   </td>
  </tr>
 </TMPL_LOOP>
 </tbody>
</table>
