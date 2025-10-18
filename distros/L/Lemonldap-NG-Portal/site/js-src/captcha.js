// Launch renew captcha request
var renewCaptcha;

renewCaptcha = function() {
  console.debug('Call URL -> ', `${portal}renewcaptcha`);
  // Request to get new token and image
  return $.ajax({
    type: "GET",
    url: `${scriptname}renewcaptcha`,
    dataType: 'json',
    error: function(j, status, err) {
      var res;
      if (err) {
        console.error('Error', err);
      }
      if (j) {
        res = JSON.parse(j.responseText);
      }
      if (res && res.error) {
        console.error('Returned error', res);
      }
    },
    // On success, values are set
    success: function(data) {
      var newimage, newtoken;
      newtoken = data.newtoken;
      console.debug('GET new token -> ', newtoken);
      newimage = data.newimage;
      console.debug('GET new image -> ', newimage);
      $('#token').attr('value', newtoken);
      $('#captcha').attr('src', newimage);
      return $('#captchafield').get(0).value = '';
    }
  });
};

$(document).ready(function() {
  $('#logout').attr('href', portal);
  return $('.renewcaptchaclick').on('click', renewCaptcha);
});