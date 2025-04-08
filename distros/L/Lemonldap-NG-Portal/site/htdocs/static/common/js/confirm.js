(function () {
  'use strict';

  // Timer for confirmation page
  var go, i, _timer, timerIsEnabled;
  i = 5;
  timerIsEnabled = 0;
  go = function go() {
    if (timerIsEnabled) {
      return $("#form").submit();
    }
  };
  _timer = function timer() {
    var h;
    h = $('#timer').html();
    if (h) {
      timerIsEnabled = 1;
      if (i > 0) {
        i--;
      }
      h = h.replace(/\d+/, i);
      $('#timer').html(h);
      return setTimeout(_timer, 1000);
    }
  };
  $(document).ready(function () {
    setTimeout(go, 30000);
    setTimeout(_timer, 1000);
    return $("#refuse").on('click', function () {
      return $("#confirm").attr("value", $(this).attr("val"));
    });
  });

})();
