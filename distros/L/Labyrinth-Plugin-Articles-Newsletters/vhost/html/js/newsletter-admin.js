function doSubmit(act,id) {
	document.EDIT.recordid.value = id;
	document.EDIT.doaction.value = act;
	document.EDIT.submit();
}

function togglecheckboxes(main) {
	for (i=0; i < document.forms[0].elements.length; i++) {
    if(document.forms[0].elements[i].style.display != 'none') {
  		document.forms[0].elements[i].checked = main.checked;
    }
	}
}

function showit(boxname) {
  var box = document.getElementById(boxname); 
  box.style.display = 'block';

  var but = document.getElementById('showbutton'); 
  but.style.display = 'none';
}

function hideit(boxname) {
  var box = document.getElementById(boxname); 
  box.style.display = 'none';

  var but = document.getElementById('showbutton'); 
  but.style.display = 'block';
}
