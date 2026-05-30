$(document).ready(function() {
  // Find all forms with ReCaptcha v3
  var $form = $('form').has('.g-recaptcha[data-sitekey]');
  if ($form.length === 0) return;

  // Create a hidden input for validation blocking
  var $validationInput = $('<input type="text" required style="display:none">');
  $form.prepend($validationInput);

  var recaptchaLoaded = false;

  // 1. Block form submission via setCustomValidity
  $validationInput[0].setCustomValidity('Waiting for security check to load...');

  // 2. Function to allow form submission
  function allowSubmit() {
    if (recaptchaLoaded) return;
    recaptchaLoaded = true;
    $validationInput.remove();
  }

  // 3. Wait for grecaptcha to be ready
  if (typeof grecaptcha !== 'undefined' && typeof grecaptcha.ready === 'function') {
    grecaptcha.ready(allowSubmit);
  }

  // 4. Safety timeout (60 seconds for slow connections)
  setTimeout(function() {
    if (typeof grecaptcha === 'undefined') {
      // This may happen if a captive portal or proxy altered the ReCaptcha script
      alert('ReCaptcha failed to load. Please check your network connection.');
      return;
    }
    allowSubmit();
  }, 60000);

  // 5. Handle form submission
  $form.on('submit', function(e) {
    e.preventDefault();
    if (typeof grecaptcha !== 'undefined' && grecaptcha.execute) {
      grecaptcha.execute(datas['datasitekey'], {action: 'submit'}).then(function(token) {
        $('#grr').val(token);
        $(e.currentTarget).unbind('submit').submit();
      });
    } else {
      // This may happen if a captive portal or proxy altered the ReCaptcha script
      alert('ReCaptcha failed to load. Please check your network connection.');
    }
  });
});
