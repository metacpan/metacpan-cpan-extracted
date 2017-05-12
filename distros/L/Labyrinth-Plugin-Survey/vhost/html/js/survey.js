function check_submission() {
    var f = document.forms['SURVEY'];
    var check = 0;

    if(!confirm(f.confirmation.value)) {
      return false;
    }

    var e=document.getElementsByTagName("input");
    for(var i=0;i<e.length;i++){
        if(e[i].type == 'text') { if(e[i].value && e[i].value != '0') { check=1 } }
        if(e[i].type == 'radio') { if(e[i].checked) { check=1 } }
        if(e[i].type == 'checkbox') { if(e[i].checked) { check=1 } }
    }

    e=document.getElementsByTagName("select");
    for(var i=0;i<e.length;i++){
        if(e[i].selectedIndex > 0) { check=1 }
    }

    e=document.getElementsByTagName("textarea");
    for(var i=0;i<e.length;i++){
        if(e[i].value) { check=1 }
    }

    if(check) { return true }

    alert("Please complete form before submitting.");
    return false;
}

function suball() {
    f = document.usersearch;
    f.searchall.value = 1;
    f.submit();
}

function subletter(let) {
    f = document.usersearch;
    f.letter.value = let;
    f.submit();
}
