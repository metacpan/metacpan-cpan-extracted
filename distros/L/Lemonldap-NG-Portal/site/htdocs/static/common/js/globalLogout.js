(function () {
  'use strict';

  // Timer for globalLogout page
  var go, i, _timer;
  i = 30;
  go = function go() {
    return $("#globallogout").submit();
  };
  _timer = function timer() {
    var h;
    h = $('#timer').html();
    if (i > 0) {
      i--;
    }
    h = h.replace(/\d+/, i);
    $('#timer').html(h);
    return window.setTimeout(_timer, 1000);
  };
  $(document).ready(function () {
    $(".data-epoch").each(function () {
      var myDate;
      myDate = new Date($(this).text() * 1000);
      return $(this).text(myDate.toLocaleString());
    });
    window.setTimeout(go, 30000);
    return window.setTimeout(_timer, 1000);
  });

})();
