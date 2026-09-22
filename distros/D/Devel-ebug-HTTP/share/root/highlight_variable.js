function highlight_variable (variable) {
  var anchors = document.getElementsByTagName('a');
  for (var i = 0; i < anchors.length; i++) {
    if (anchors[i].parentNode.className == 'symbol' && anchors[i].innerHTML == variable) {
      anchors[i].parentNode.className = 'symbol highlight';
    }
  }
  return false;
}

function unhighlight_variable (variable) {
  var anchors = document.getElementsByTagName('a');
  for (var i = 0; i < anchors.length; i++) {
    if (anchors[i].parentNode.className == 'symbol highlight' && anchors[i].innerHTML == variable) {
      anchors[i].parentNode.className = 'symbol';
    }
  }
  return false;
}
