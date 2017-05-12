function markcomment(act,id,mark) {
  f = document.forms.SEARCH;
  f.act.value       = act;
  f.commentid.value = id;
  f.mark.value      = mark;
  f.submit();
}
