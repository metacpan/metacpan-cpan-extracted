(function () {
  'use strict';

  // Launch renew captcha request
  var renewCaptcha;
  renewCaptcha = function renewCaptcha() {
    console.log('Call URL -> ', "".concat(portal, "renewcaptcha"));
    // Request to get new token and image
    return $.ajax({
      type: "GET",
      url: "".concat(scriptname, "renewcaptcha"),
      dataType: 'json',
      error: function error(j, status, err) {
        var res;
        if (err) {
          console.log('Error', err);
        }
        if (j) {
          res = JSON.parse(j.responseText);
        }
        if (res && res.error) {
          return console.log('Returned error', res);
        }
      },
      // On success, values are set
      success: function success(data) {
        var newimage, newtoken;
        newtoken = data.newtoken;
        console.log('GET new token -> ', newtoken);
        newimage = data.newimage;
        console.log('GET new image -> ', newimage);
        $('#token').attr('value', newtoken);
        $('#captcha').attr('src', newimage);
        return $('#captchafield').get(0).value = '';
      }
    });
  };
  $(document).ready(function () {
    $('#logout').attr('href', portal);
    return $('.renewcaptchaclick').on('click', renewCaptcha);
  });

})();
