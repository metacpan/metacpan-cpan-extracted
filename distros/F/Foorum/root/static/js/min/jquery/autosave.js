jQuery.fn.autoSave=function(fcn,settings){$daemach=(typeof $daemach!=="undefined")?$daemach:{};if(typeof $daemach.autoSave=="undefined"){$daemach.autoSave=new Object();$daemach.autoSave["timer"]=new Array();$daemach.autoSave["fn"]=new Array();}
var _as=$daemach.autoSave;settings=jQuery.extend({delay:500,doClassChange:true,beforeClass:"asBefore",afterClass:"asAfter",onChange:null,preSave:null,postSave:null,minLength:0},settings);if(settings.doClassChange){if(settings.beforeClass=="asBefore"){createCSSClass(".asBefore","background-color:#FFdddd");}
if(settings.afterClass=="asAfter"){createCSSClass(".asAfter","background-color:#ddFFdd");}}
return this.each(function(){var p=this.name;if(typeof _as["fn"][p]=="undefined"){_as["fn"][p]=new Array();_as["fn"][p][0]=null;}
var bindType;var initialState;switch(this.type){case"text":bindType="keyup";initialState=this.value;break;case"hidden":bindType="keyup";initialState=this.value;break;case"textarea":bindType="keyup";initialState=this.value;break;case"password":bindType="keyup";initialState=this.value;break;case"select-one":bindType="change";initialState=this.value;break;case"select-multiple":bindType="change";initialState=this.value;break;case"radio":bindType="click";initialState=this.value;break;case"checkbox":bindType="click";initialState=this.checked;break;default:bindType="keyup";initialState=this.value;break;}
if(bindType=="keyup"){_as["timer"][p]=null;}
if(this.type!=="radio"||(this.type=="radio"&&this.checked)){_as["fn"][p][0]=initialState;}
_as["fn"][p][1]=function(e){if(e&&e.type=='blur'&&_as["fn"][p][2]){if(_as["timer"][p])window.clearTimeout(_as["timer"][p]);}
if(_as["fn"][p][2]){if(_as["fn"][p][0]!==this.value||(this.type=="checkbox")){if(settings.preSave){_as["fn"][p][2]=false;var proceed=settings.preSave.apply(this);if(!(typeof proceed=="boolean"&&proceed==false)){_as["fn"][p][2]=true;}}
if(_as["fn"][p][2]){fcn.apply(this);_as["fn"][p][0]=this.value;}else{if(this.type=="checkbox"){this.checked=_as["fn"][p][0];}else{this.value=_as["fn"][p][0];}}
if(settings.postSave){settings.postSave.apply(this);}
if(settings.doClassChange){jQuery(this).removeClass(settings.beforeClass).addClass(settings.afterClass);}}}}
_as["fn"][p][2]=true;jQuery(this).bind(bindType,function(){if(_as["fn"][p][0]!==this.value||(this.type=="checkbox")){if(settings.onChange){_as["fn"][p][2]=false;var proceed=settings.onChange.apply(this);if(!(typeof proceed=="boolean"&&proceed==false)){_as["fn"][p][2]=true;}}
if(settings.doClassChange){var ele=jQuery(this);if(ele.is('.'+settings.afterClass))ele.removeClass(settings.afterClass);if(!ele.is('.'+settings.beforeClass))ele.addClass(settings.beforeClass);}
var me=this;if(bindType=="keyup"){if(this.value.length>=settings.minLength){_as["timer"][p]=window.setTimeout(function(){_as["fn"][p][1].apply(me);},settings.delay);}}
else{_as["fn"][p][1].apply(me);}}});if(bindType=="keyup"){jQuery(this).blur(function(){if(this.value.length>=settings.minLength){_as["fn"][p][1]}});}
if(bindType=="keyup"){jQuery(this).keydown(function(){if(_as["timer"][p]){window.clearTimeout(_as["timer"][p])};});}});};if(typeof createCSSClass=="undefined"){function createCSSClass(selector,style){if(!document.styleSheets)return;if(document.getElementsByTagName("head").length==0)return;var stylesheet;var mediaType;if(document.styleSheets.length>0){for(var i=0;i<document.styleSheets.length;i++){if(document.styleSheets[i].disabled)continue;var media=document.styleSheets[i].media;mediaType=typeof media;if(mediaType=="string"){if(media==""||media.indexOf("screen")!=-1){styleSheet=document.styleSheets[i];}}
else if(mediaType=="object"){if(media.mediaText==""||media.mediaText.indexOf("screen")!=-1){styleSheet=document.styleSheets[i];}}
if(typeof styleSheet!="undefined")break;}}
if(typeof styleSheet=="undefined"){var styleSheetElement=document.createElement("style");styleSheetElement.type="text/css";document.getElementsByTagName("head")[0].appendChild(styleSheetElement);for(var i=0;i<document.styleSheets.length;i++){if(document.styleSheets[i].disabled)continue;styleSheet=document.styleSheets[i];}
var media=styleSheet.media;mediaType=typeof media;}
if(mediaType=="string"){for(var i=0;i<styleSheet.rules.length;i++){if(styleSheet.rules[i].selectorText.toLowerCase()==selector.toLowerCase()){styleSheet.rules[i].style.cssText=style;return;}}
styleSheet.addRule(selector,style);}
else if(mediaType=="object"){for(i=0;i<styleSheet.cssRules.length;i++){if(styleSheet.cssRules[i].selectorText.toLowerCase()==selector.toLowerCase()){styleSheet.cssRules[i].style.cssText=style;return;}}
styleSheet.insertRule(selector+"{"+style+"}",styleSheet.cssRules.length);}}}