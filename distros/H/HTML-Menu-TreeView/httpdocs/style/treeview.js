
function displayTree(id){
  var e = document.getElementById(id);
  if(!e)return;
  var display = e.style.display;
  if(display == "none"){
	e.style.display = "";
  }else if(display == ""){
	e.style.display = "none";
  }
}
var m_bOver = true;
function ocNode(id,size){

	var node = document.getElementById(id).className;
        var mnode = 'minusNode'+size;
        var cmnode = 'clasicMinusNode'+size;
        var pnode = 'plusNode'+size;
        var cpnode = 'clasicPlusNode'+size;
        if(node  ==  mnode){
            document.getElementById(id).className = pnode;
        }else if(node  ==  pnode){
            document.getElementById(id).className = mnode;
        }else if(node  ==  cpnode){
            document.getElementById(id).className = cmnode
        }else if(node  ==  cmnode){
            document.getElementById(id).className = cpnode;
        }
}
function ocpNode(id,size){
	var node = document.getElementById(id).className;
        var mnode = 'lastMinusNode'+size;
        var cmnode = 'clasicLastMinusNode'+size;
        var pnode = 'lastPlusNode'+size;
        var cpnode = 'clasicLastPlusNode'+size;
        if(node  ==  mnode){
            document.getElementById(id).className = pnode;
        }else if(node  ==  pnode){
            document.getElementById(id).className = mnode;
        }else if(node  ==  cpnode){
            document.getElementById(id).className = cmnode;
        }else if(node  ==  cmnode){
            document.getElementById(id).className = cpnode;
        }
}
function ocFolder(id){
    var fid = id+'.folder';
    var folder = document.getElementById(fid).className;
    var mclass = /(folder.*)Closed(\d+)/;
    var isclosed = mclass.test(folder);
    if(isclosed  ==  true){
        document.getElementById(fid).className = folder.replace(/(folder.*)Closed(\d+)/,'\$1\$2');
    }else{
        document.getElementById(fid).className = folder.replace(/(folder[^\d]*)(\d+)/,'\$1Closed\$2');
    }
}
function hideArray(i){
    var first = 1;
    var display = '';
    if(window.folders &&  window.folders[i]){
      
        for (var j  =0;j < window.folders[i].length; j++){
            var node =document.getElementById('tr'+window.folders[i][j]);
            if(first){
                display  = node.style.display == 'none' ? '':'none'
                        first = 0;
            }
            var subfolder = document.getElementById(window.folders[i][j]);
            if(subfolder){
                if(subfolder.style.display != display && display == ''){
                    ocFolder(window.folders[i][j]);
                    ocNode(window.folders[i][j]+'.node');
                    displayTree(window.folders[i][j]);
                }
            }
            node.style.display = display;
        }
    }
}

function trOver(id){
     var node =document.getElementById('tr'+id);
     var node2 =document.getElementById('tree'+id);
     if(m_bOver){
          if(node)
          node.className = 'trOver';
          if(node2)
          node2.className = 'trOver';
     }
}
function trUnder(id){
     var node =document.getElementById('tr'+id);
     var node2 =document.getElementById('tree'+id);
     if(m_bOver){
          if(node)
          node.className = '';
          if(node2)
          node2.className = '';
     }
}