function break_point (line) {
   document.hiddenform.myaction.value = "break_point";
   document.hiddenform.line.value = line;
   document.hiddenform.submit();
}

function break_point_delete (line) {
   document.hiddenform.myaction.value = "break_point_delete";
   document.hiddenform.line.value = line;
   document.hiddenform.submit();
}
