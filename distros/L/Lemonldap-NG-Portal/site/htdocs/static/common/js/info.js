(function () {
  'use strict';

  // Timer for information page
  var _go, go, i, stop, _timer;
  i = 30;
  _go = 1;
  stop = function stop() {
    _go = 0;
    $('#divToHide').hide();
    return $('#wait').hide();
  };
  go = function go() {
    if (_go) {
      return $("#form").submit();
    }
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

  //$(document).ready ->
  $(window).on('load', function () {
    if (window.datas['activeTimer']) {
      window.setTimeout(go, 30000);
      window.setTimeout(_timer, 1000);
    }
    return $("#wait").on('click', function () {
      return stop();
    });
  });

})();
