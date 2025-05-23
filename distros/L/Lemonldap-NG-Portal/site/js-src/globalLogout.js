// Timer for globalLogout page
var go, i, timer;

i = 30;

go = function() {
  return $("#globallogout").submit();
};

timer = function() {
  var h;
  h = $('#timer').html();
  if (i > 0) {
    i--;
  }
  h = h.replace(/\d+/, i);
  $('#timer').html(h);
  return window.setTimeout(timer, 1000);
};

$(document).ready(function() {
  $(".data-epoch").each(function() {
    var myDate;
    myDate = new Date($(this).text() * 1000);
    return $(this).text(myDate.toLocaleString());
  });
  window.setTimeout(go, 30000);
  return window.setTimeout(timer, 1000);
});
