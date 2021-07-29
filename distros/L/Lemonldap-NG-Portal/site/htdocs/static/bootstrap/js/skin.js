$(window).on("load", function() {

  // Adapt some class to fit Bootstrap theme
  $("div.message-positive").addClass("alert-success");
  $("div.message-warning").addClass("alert-warning");
  $("div.message-negative").addClass("alert-danger");

  $("table.info").addClass("table");

  $(".notifCheck").addClass("checkbox");

  // Collapse menu on click
  $('.collapse li[class!="dropdown"]').on('click', function() {
    if (!$('.navbar-toggler').hasClass('collapsed')) {
      $(".navbar-toggler").trigger("click");
    }
  });

  // Remember selected tab
  $('#authMenu .nav-link').on('click', function (e) {
      window.datas.choicetab = e.target.hash.substr(1)
  });

  // Transmit attributes to remove2f modal
  $('#remove2fModal').on('show.bs.modal', function (event) {
  var button = $(event.relatedTarget) // Button that triggered the modal
  var device = button.attr('device') // Extract device/epoch from button
  var epoch = button.attr('epoch')
  var modal = $(this)

  // Set device/epoch on modal remove2f button so that the portal JS code can find it
  modal.find('.remove2f').attr('device', device)
  modal.find('.remove2f').attr('epoch', epoch)
})

  // Set tab items (my applications, password, history, logout) tabbable
  // (ie accessible via tab key)
  // needed because of jquery-ui setting only active element tabbable
  // (see #2561)
  $('.nav-item').click(function() {
    $('.nav-item').attr( "tabIndex", 0 );
  });
  $('.nav-item').focusin(function() {
    $('.nav-item').attr( "tabIndex", 0 );
  });
  $('.nav-item').focusout(function() {
    $('.nav-item').attr( "tabIndex", 0 );
  });


});
