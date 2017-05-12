window.onload = function() {
document.onkeypress = register;
}
keys_disabled = 0;
function register(e) {
    var key;
    var myaction;
    if (keys_disabled) {
      return true;
    }
    if (e == null) {
        // IE
        key = event.keyCode
    }
    else {
        // Mozilla
        if (e.altKey || e.ctrlKey) {
            return true
        }
        key = e.which
    }
    letter = String.fromCharCode(key).toLowerCase();
    switch (letter) {
        case "n": myaction = "next"; break
        case "r": myaction = "return"; break
        case "R": myaction = "run"; break
        case "s": myaction = "step"; break
        case "u": myaction = "undo"; break
    }
    if (myaction) {
      document.hiddenform.myaction.value = myaction;
      document.hiddenform.submit();
    }
}
