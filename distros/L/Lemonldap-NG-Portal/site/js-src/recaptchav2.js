// Global callback for ReCaptcha v2 onload
window.__llng_recaptchaLoad = function() {
  window.__llng_recaptchaReady = true;
  if (window.__llng_recaptchaCallback) {
    window.__llng_recaptchaCallback();
  }
};

$(document).ready(function() {
  // Find all forms with ReCaptcha v2
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

  // 3. If ReCaptcha already loaded before DOM ready, unblock immediately
  if (window.__llng_recaptchaReady) {
    allowSubmit();
  }

  // 4. Register callback for when ReCaptcha loads after DOM ready
  window.__llng_recaptchaCallback = allowSubmit;

  // 5. Safety timeout (60 seconds for slow connections)
  setTimeout(function() {
    if (typeof grecaptcha === 'undefined') {
      // This may happen if a captive portal or proxy altered the ReCaptcha script
      alert('ReCaptcha failed to load. Please check your network connection.');
      return;
    }
    allowSubmit();
  }, 60000);
});
