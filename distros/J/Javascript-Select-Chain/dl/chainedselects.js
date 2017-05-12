// Chained Selects

// Copyright Xin Yang 2004
// Web Site: www.yxScripts.com
// EMail: m_yangxin@hotmail.com
// Last Updated: 2004-10-14

// This script is free as long as the copyright notice remains intact.

var _disable_empty_list=false;
var _hide_empty_list=false;

// ------
if (typeof(disable_empty_list)=="undefined") { disable_empty_list=_disable_empty_list; }
if (typeof(hide_empty_list)=="undefined") { hide_empty_list=_hide_empty_list; }

var cs_goodContent=true, cs_M="M", cs_L="L", cs_curTop=null, cs_curSub=null;

function cs_findOBJ(obj,n) {
  for (var i=0; i<obj.length; i++) {
    if (obj[i].name==n) { return obj[i]; }
  }
  return null;
}
function cs_findContent(n) { return cs_findOBJ(cs_content,n); }

function cs_findM(m,n) {
  if (m.name==n) { return m; }

  var sm=null;
  for (var i=0; i<m.items.length; i++) {
    if (m.items[i].type==cs_M) {
      sm=cs_findM(m.items[i],n);
      if (sm!=null) { break; }
    }
  }
  return sm;
}
function cs_findMenu(n) { return (cs_curSub!=null && cs_curSub.name==n)?cs_curSub:cs_findM(cs_curTop,n); }

function cs_contentOBJ(n,obj){
  this.name=n;
  this.menu=obj;
  this.lists=new Array();
  this.cookie="";
  this.callback=null;
  this.count=1;
}; cs_content=new Array();

function cs_topmenuOBJ(tm) {
  this.name=tm;
  this.items=new Array();
  this.df=",";

  this.addM=cs_addM; this.addL=cs_addL;
}
function cs_submenuOBJ(dis,link,sub) {
  this.name=sub;
  this.type=cs_M;
  this.dis=dis;
  this.link=link;
  this.df=",";

  var x=cs_findMenu(sub);
  this.items=x==null?new Array():x.items;

  this.addM=cs_addM; this.addL=cs_addL;
}
function cs_linkOBJ(dis,link) {
  this.type=cs_L;
  this.dis=dis;
  this.link=link;
}

function cs_addM(dis,link,sub) { this.items[this.items.length]=new cs_submenuOBJ(dis,link,sub); }
function cs_addL(dis,link) { this.items[this.items.length]=new cs_linkOBJ(dis,link); }

function cs_showMsg(msg) { window.status=msg; }
function cs_badContent(n) { cs_goodContent=false; cs_showMsg("["+n+"] Not Found."); }

function _setCookie(name, value) {
  document.cookie=name+"="+value;
}
function cs_setCookie(name, value) {
  setTimeout("_setCookie('"+name+"','"+value+"')",0);
}

function cs_getCookie(name) {
  var cookieRE=new RegExp(name+"=([^;]+)");
  if (document.cookie.search(cookieRE)!=-1) {
    return RegExp.$1;
  }
  else {
    return "";
  }
}

function cs_optionOBJ(text,value) { this.text=text; this.value=value; }
function cs_getOptions(menu) {
  var opt=new Array();
  for (var i=0; i<menu.items.length; i++) {
    opt[i]=new cs_optionOBJ(menu.items[i].dis, menu.items[i].link);
  }
  return opt;
}
function cs_emptyList(list) {
  for (var i=list.options.length-1; i>=0; i--) {
    list.options[i]=null;
  }
}
function cs_refreshList(list,opt,df,key) {
  var l=list.options.length;
  for (var i=0; i<opt.length; i++) {
    list.options[l+i]=new Option(opt[i].text, opt[i].value, df.indexOf(","+i+",")!=-1, df.indexOf(","+i+",")!=-1);
    list.options[l+i].idx=i;
    list.options[l+i].key=key;
  }
}
function cs_getList(content,key) {
  var menu=content.menu;

  if (key!="[]") {
    var paths=key.substring(1,key.length-1).split(",");
    for (var i=0; i<paths.length; i++) {
      menu=menu.items[parseInt(paths[i],10)];
    }
  }

  return menu;
}
function cs_getKey(key,idx) {
  return "["+(key=="[]"?"":(key.substring(1,key.length-1)+","))+idx+"]";
}
function cs_getSelected(mode,name,idx,key,df) {
  if (mode) {
    var cookies=cs_getCookie(name+"_"+idx);
    if (cookies!="") {
      var mc=cookies.split("-");
      for (var i=0; i<mc.length; i++) {
        if (mc[i].indexOf(key)!=-1) {
          df=mc[i].substring(key.length);
          break;
        }
      }
    }
  }
  return df;
}

function cs_updateListGroup(content,idx,mode) {
  var menu=null, options=content.lists[idx].options, has_sublist=false;
  var key="", option=",", cookies="";

  if (options.selectedIndex<0) {
    options.selectedIndex=0;
  }

  for (var i=0; i<options.length; i++) {
    if (options[i].selected) {
      if (key!=options[i].key) {
        cookies+=key==""?"":((cookies==""?"":"-")+key+option);

        key=options[i].key;
        option=",";
        menu=cs_getList(content,key);
      }

      option+=options[i].idx+",";

      if (idx+1<content.lists.length) {
        if (menu.items[options[i].idx].type==cs_M) {
          if (!has_sublist) {
            has_sublist=true;
            cs_emptyList(content.lists[idx+1]);
          }
          var subkey=cs_getKey(key,options[i].idx), df=cs_getSelected(mode,content.cookie,idx+1,subkey,menu.items[options[i].idx].df);
          cs_refreshList(content.lists[idx+1],cs_getOptions(menu.items[options[i].idx]),df,subkey);
        }
      }
    }
  }

  if (key!="") {
    cookies+=(cookies==""?"":"-")+key+option;
  }

  if (content.cookie) {
    cs_setCookie(content.cookie+"_"+idx,cookies);
  }

  if (has_sublist && idx+1<content.lists.length) {
    if (disable_empty_list) {
      content.lists[idx+1].disabled=false;
    }
    if (hide_empty_list) {
      content.lists[idx+1].style.display="";
    }
    cs_updateListGroup(content,idx+1,mode);
  }
  else {
    for (var s=idx+1; s<content.lists.length; s++) {
      cs_emptyList(content.lists[s]);

      if (disable_empty_list) {
        content.lists[s].disabled=true;
      }
      if (hide_empty_list) {
        content.lists[s].style.display="none";
      }

      if (content.cookie) {
        cs_setCookie(content.cookie+"_"+s,"");
      }
    }
  }
}

function cs_initListGroup(content,mode) {
  var key="[]", df=cs_getSelected(mode,content.cookie,0,key,content.menu.df);

  cs_emptyList(content.lists[0]);
  cs_refreshList(content.lists[0],cs_getOptions(content.menu),df,key);
  cs_updateListGroup(content,0,mode);
}

function cs_updateList() {
  var content=this.content;
  for (var i=0; i<content.lists.length; i++) {
    if (content.lists[i]==this) {
      cs_updateListGroup(content,i,content.cookie);

      if (content.callback) {
        content.callback(this,i+1,content.count);
      }

      break;
    }
  }
}

// ----
function addListGroup(n,tm) {
  if (cs_goodContent) {
    cs_curTop=new cs_topmenuOBJ(tm); cs_curSub=null;

    var c=cs_findContent(n);
    if (c==null) {
      cs_content[cs_content.length]=new cs_contentOBJ(n,cs_curTop);
    }
    else {
      delete(c.menu); c.menu=cs_curTop;
    }
  }
}

function addList(n,dis,link,sub,df) {
  if (cs_goodContent) {
    cs_curSub=cs_findMenu(n);

    if (cs_curSub!=null) {
      cs_curSub.addM(dis,link||"",sub);
      if (typeof(df)!="undefined") { cs_curSub.df+=(cs_curSub.items.length-1)+","; }
    }
    else {
      cs_badContent(n);
    }
  }
}

function addOption(n,dis,link,df) {
  if (cs_goodContent) {
    cs_curSub=cs_findMenu(n);

    if (cs_curSub!=null) {
      cs_curSub.addL(dis,link||"");
      if (typeof(df)!="undefined") { cs_curSub.df+=(cs_curSub.items.length-1)+","; }
    }
    else {
      cs_badContent(n);
    }
  }
}

function initListGroup(n) {
  var _content=cs_findContent(n), count=0;
  if (_content!=null) {
    content=new cs_contentOBJ("cs_"+_content.count+"_"+n,_content.menu);
    content.count=_content.count++;
    cs_content[cs_content.length]=content;

    for (var i=1; i<initListGroup.arguments.length; i++) {
      if (typeof(arguments[i])=="object" && arguments[i].tagName && arguments[i].tagName=="SELECT") {
        content.lists[count]=arguments[i];

        arguments[i].onchange=cs_updateList;
        arguments[i].content=content; arguments[i].idx=count++;
      }
      else if (typeof(arguments[i])=="string" && /^[a-zA-Z_]\w*$/.test(arguments[i])) {
        content.cookie=arguments[i];
      }
      else if (typeof(arguments[i])=="function") {
        content.callback=arguments[i];
      }
      else {
        cs_showMsg("Warning: Unexpected argument in initListGroup() for ["+n+"]");
      }
    }

    if (content.lists.length>0) {
      cs_initListGroup(content,content.cookie);
    }
  }
}

function resetListGroup(n,count) {
  var content=cs_findContent("cs_"+(count||1)+"_"+n);
  if (content!=null && content.lists.length>0) {
    cs_initListGroup(content,"");
  }
}
// ------
