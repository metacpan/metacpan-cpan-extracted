
document.onkeypress = function (event) {
  var keycode;
  var keychar;

  if(window.event) keycode = window.event.keyCode;
  else if(event) keycode = event.which;
  else return false;

  keychar = String.fromCharCode(keycode);

  if(keychar == " ") {
    var next_link = document.getElementById('nav-next');
    if(next_link) {
      location.href = next_link.href;
    }
    return false;
  }

  return true;
}

