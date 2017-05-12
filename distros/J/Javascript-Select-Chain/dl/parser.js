// Chained Selects Parser

// Copyright Xin Yang 2004
// Web Site: www.yxScripts.com
// EMail: m_yangxin@hotmail.com
// Last Updated: 2004-08-07

var subCount=1, maxNest=1, nestCount=1;
var separator=",";

function parseOption(list, text, value, pick) {
  return 'addOption("'+list+'", "'+text+'", "'+value.replace(/\s+$/,"")+'"'+(pick?', 1':'')+");\n";
}

function parseList(list, text, value, sub, pick, sublist) {
  var content='addList("'+list+'", "'+text+'", "'+value.replace(/\s+$/,"")+'", "'+sub+'"'+(pick?', 1':'')+");\n";
  var i=sublist.firstChild, item=null;

  while (i) {
    if (i.nodeType==1) {
      j=i.firstChild;
      item=j.nodeValue.replace(/\s+$/,"").split(separator);

      if (i.childNodes.length>1) {
        nestCount++;
        maxNest=Math.max(maxNest, nestCount);
        content+=parseList(sub, item[0], item[1]||item[0], "cs-sub-"+(subCount++), item[2]||0, j.nextSibling)+"\n";
        nestCount--;
      }
      else {
        content+=parseOption(sub, item[0], item[1]||item[0], item[2]||0);
      }
    }
    i=i.nextSibling;
  }

  return content;
}

function parseTop(list) {
  var content="", i=list.firstChild, item=null;

  while (i) {
    if (i.nodeType==1) {
      j=i.firstChild;
      item=j.nodeValue.replace(/\s+$/,"").split(separator);

      if (i.childNodes.length>1) {
        nestCount++;
        maxNest=Math.max(maxNest, nestCount);
        content+=parseList("cs-top", item[0], item[1]||item[0], "cs-sub-"+(subCount++), item[2]||0, j.nextSibling)+"\n";
        nestCount--;
      }
      else {
        content+=parseOption("cs-top", item[0], item[1]||item[0], item[2]||0);
      }
    }
    i=i.nextSibling;
  }

  return content;
}

function parseGroup() {
  var content="", list=document.getElementById("CS"), listGroup=document.forms[0].listgroup.value;

  if (listGroup!="") {
    subCount=1;
    maxNest=1;
    nestCount=1;
    content='addListGroup("'+listGroup+'", "cs-top");'+"\n\n";
    content+=parseTop(list);

    document.forms[0].content.value=content;
  }
}

function showGroup() {
  if (document.forms[0].content.value!="") {
    demoWin=window.open();

    with (demoWin.document) {
      writeln('<script language="javascript" src="chainedselects.js"></script>');
      writeln('<script language="javascript">');
    }

    demoWin.document.writeln(document.forms[0].content.value);
    demoWin.document.writeln('</script>');
    demoWin.document.write('<body onload="initListGroup('+"'"+document.forms[0].listgroup.value+"'");

    with (demoWin.document) {
      for (var i=1; i<=maxNest; i++) {
        write(", document.forms[0].s"+i);
      }
      writeln(')">');
      writeln("<form>");
      for (var i=1; i<=maxNest; i++) {
        writeln("<p><select style='width:200px;' name=s"+i+"></select></p>");
      }
      writeln("</form>");
      writeln("</body>");
    }
    demoWin.document.close();
  }
}
