function doSubmit(act,id) {
	document.forms['EDIT'].recordid.value = id;
	document.forms['EDIT'].doaction.value = act;
	document.forms['EDIT'].submit();
}

function doOnlyOne(act) {
	var checkBoxArr = getSelectedCheckbox(document.forms[0].LISTED);
	if (checkBoxArr.length == 1) { 
		doSubmit(act);
		return;
	}

	if (checkBoxArr.length == 0) { alert("No check boxes selected"); }
	else						 { alert("Only one check box can be selected"); }
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

function markcomment(act,id,mark) {
  f = document.forms.SEARCH;
  f.act.value       = act;
  f.commentid.value = id;
  f.mark.value      = mark;
  f.submit();
}

function newpage(page) {
  f = document.forms.SEARCH;
  f.start.value = page;
  f.submit();
}

var index = 1;
function addformat() {
    var row = document.createElement('tr'); 
    var td1 = document.createElement('td'); 
    var td2 = document.createElement('td'); 
    var td3 = document.createElement('td'); 
    var td4 = document.createElement('td'); 

    var opts = '';
    for(var i = 0 ; i < optf.length ; i++) {
        opts = opts + '<option value="'+optf[i].index+'">'+optf[i].value+'</option>';
    }

    row.id = 'frow_x' + index;
    td1.innerHTML = '<select name="frm_x'+index+'">' + opts + '</select>';
    td2.innerHTML = '<input type="text" name="cat_x'+index+'" value="" />';
    td3.innerHTML = '<input type="text" name="lab_x'+index+'" value="" />';
    td4.innerHTML = '<button onclick="delfrm('+index+')">X</button>';

    row.appendChild(td1);
    row.appendChild(td2);
    row.appendChild(td3);
    row.appendChild(td4);

    document.getElementById('formats').appendChild(row); 

    index = index + 1;
}

function delfrm(inx) {
    var t = document.getElementById('formats');
    var r = document.getElementById('frow_x'+inx);
    t.removeChild(r);
    return false;
}

function delformat() {
    document.forms.EDIT.submit();
}

function addtrack() {
    var l = document.getElementById('add-lyric');
    l.style.display = 'block';
}

function Xaddtrack() {
    var row = document.createElement('tr'); 
    var td1 = document.createElement('td'); 
    var td2 = document.createElement('td'); 
    var td3 = document.createElement('td'); 

    var opts = '';
    for(var i = 0 ; i < optt.length ; i++) {
        opts = opts + '<option value="'+optt[i].index+'">'+optt[i].value+'</option>';
    }

    row.id = 'trow_x' + index;
    td1.innerHTML = '<input type="text" name="ord_x'+index+'" value="" size="2" />';
    td2.innerHTML = '<select name="trk_x'+index+'">' + opts + '</select>';
    td3.innerHTML = '<button onclick="deltrk('+index+')">X</button>';

    row.appendChild(td1);
    row.appendChild(td2);
    row.appendChild(td3);

    document.getElementById('lyrics').appendChild(row); 

    index = index + 1;
}

function deltrk(inx) {
    var t = document.getElementById('lyrics');
    var r = document.getElementById('trow_x'+inx);
    t.removeChild(r);
    return false;
}

function deltrack() {
    document.forms.EDIT.submit();
}

function addprofile() {
    var l = document.getElementById('add-profile');
    l.style.display = 'block';
}

function deltrk(inx) {
    var t = document.getElementById('profiles');
    var r = document.getElementById('prow_x'+inx);
    t.removeChild(r);
    return false;
}

function delprofile() {
    document.forms.EDIT.submit();
}
