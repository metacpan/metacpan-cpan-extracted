function doSubmit(act,id) {
	document.forms[0].recordid.value = id;
	document.forms[0].doaction.value = act;
	document.forms[0].submit();
}

function doOnlyOne(act) {
	var checkBoxArr = getSelectedCheckbox(document.forms[0].LISTED);
	if (checkBoxArr.length == 1) { 
		doSubmit(act);
		return;
	}

	if (checkBoxArr.length == 0)  { alert("No check boxes selected"); }
	else						              { alert("Only one check box can be selected"); }
}


function getSelectedCheckbox(buttonGroup) {
   // Go through all the check boxes. return an array of all the ones
   // that are selected (their position numbers). if no boxes were checked,
   // returned array will be empty (length will be zero)
   var retArr = new Array();
   var lastElement = 0;
   if (buttonGroup[0]) { // if the button group is an array (one check box is not an array)
      for (var i=0; i<buttonGroup.length; i++) {
         if (buttonGroup[i].checked) {
            retArr.length = lastElement;
            retArr[lastElement] = i;
            lastElement++;
         }
      }
   } else { // There is only one check box (it's not an array)
      if (buttonGroup.checked) { // if the one check box is checked
         retArr.length = lastElement;
         retArr[lastElement] = 0; // return zero as the only array value
      }
   }
   return retArr;
} // Ends the "getSelectedCheckbox" function


function DoPopup(callback) {
	document.forms[0].display.value = callback;
	window.open(cgipath+"/pages.cgi?act=album-pick", "popup", "width=370,height=450,scrollbars=no,menubar=no,resizable=no,status=no,toolbar=no,location=no");
}

function SetImage(id,href) {
	f = document.forms[1];
	f.elements[f.display.value].value=id;
	disp = document.getElementById(f.display.value);
	disp.src=webpath+href
}

function PhotoGallery(callback) {
	document.forms[1].display.value = callback;
	window.open(cgipath+"pages.cgi?act=album-pick", "popup", "width=370,height=450,scrollbars=no,menubar=no,resizable=no,status=no,toolbar=no,location=no");
}

function ImageGallery(callback) {
	document.forms[1].display.value = callback;
	window.open(cgipath+"pages.cgi?act=imgs-gallery&amp;imagetype=0,1,2,4,9", "popup", "width=340,height=390,scrollbars=no,menubar=no,resizable=no,status=no,toolbar=no,location=no");
}

function AddTag(tag) {
	var meta = document.getElementById('metadata');
	var val = meta.value;
	if(val) { val = val + ' ' }
	val = val + tag
    meta.value = val;
}
	