$(document).ready(function() {
  return $(".idploop").on('click', function() {
    return $("#idp").val($(this).attr("val"));
  });
});
