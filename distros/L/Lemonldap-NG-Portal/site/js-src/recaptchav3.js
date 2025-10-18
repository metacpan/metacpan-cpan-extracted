$(document).ready(function() {
  $('form').on('submit', function(e) {
    e.preventDefault();
    grecaptcha.ready(function() {
      grecaptcha.execute(datas['datasitekey'], {action: 'submit'}).then(function(token) {
        $('#grr').val(token);
        $(e.currentTarget).unbind('submit').submit();
      });
  })
 })
});
