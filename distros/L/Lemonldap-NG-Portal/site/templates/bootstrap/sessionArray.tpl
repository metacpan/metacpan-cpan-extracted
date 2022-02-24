<TMPL_IF NAME="title">
<h3 trspan="<TMPL_VAR NAME="title">"></h3>
</TMPL_IF>
<table class="info">
 <TMPL_IF NAME="displayError">
   <caption trspan="lastFailedLoginsCaptionLabel">Last failed logins</caption>
 <TMPL_ELSE>
   <caption trspan="lastLoginsCaptionLabel">Last logins</caption>
 </TMPL_IF>
 <thead>
  <tr>
   <TMPL_IF NAME="displayUser">
    <th trspan="user">User</th>
   </TMPL_IF>
   <th trspan="date">Date</th>
   <th trspan="ipAddr">IP address</th>
   <TMPL_LOOP NAME="fields">
    <th trspan="<TMPL_VAR NAME="name">"><TMPL_VAR NAME="name"></th>
   </TMPL_LOOP>
   <TMPL_IF NAME="displayError">
    <th trspan="errorMsg">Error message</th>
   </TMPL_IF>
  </tr>
 </thead>
 <tbody>
  <TMPL_LOOP NAME="sessions">
   <tr>
    <TMPL_IF NAME="displayUser">
     <td><TMPL_VAR NAME="user"></td>
    </TMPL_IF>
    <td class="localeDate" val="<TMPL_VAR NAME="utime">"></td>
    <td><TMPL_VAR NAME="ip"></td>
    <TMPL_LOOP NAME="values">
     <td><TMPL_VAR NAME="v"></td>
    </TMPL_LOOP>
    <TMPL_IF NAME="displayError">
     <td trspan="PE<TMPL_VAR NAME="error">">PE<TMPL_VAR NAME="error"></td>
    </TMPL_IF>
   </tr>
  </TMPL_LOOP>
 </tbody>
</table>
