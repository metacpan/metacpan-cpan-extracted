$(document).ready(function() {

  // Adapt some class to fit Bootstrap theme
  $("div.message-positive").addClass("alert-success");
  $("div.message-warning").addClass("alert-warning");
  $("div.message-negative").addClass("alert-danger");

  $("table.info").addClass("table");

  $(".notifCheck").addClass("checkbox");

  // Collapse menu on click
  $('.nav a').on('click', function() {
    if ($('.navbar-toggle').css('display') != 'none') {
      $(".navbar-toggle").trigger("click");
    }
  });

});