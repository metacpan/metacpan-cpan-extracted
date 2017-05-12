// ScrollBar Object
// widget that draws a 2 dimensional scrollbar
// 19990613

// Copyright (C) 1999 Dan Steinman
// Distributed under the terms of the GNU Library General Public License
// Available at http://www.dansteinman.com/dynapi/
var gx=0;
var gy=0;
function ScrollBar(x,y,width,height,boxW,boxH,name) {
	//this.name="ScrollBar"+(ScrollBar.count++)
	this.name="scrollbar_"+name;
	this.x=x
	this.y=y
	this.w=width
	this.h=height
	this.boxW=boxW
	this.boxH=boxH
	this.offsetHeight=this.h-this.boxH
	this.offsetWidth=this.w-this.boxW
	this.obj=this.name+"Object"
	eval(this.obj+"=this")
}
{var p=ScrollBar.prototype
p.bgColor=null
p.boxColor=null
p.inc=10
p.speed=20
p.active=false
p.boxvis=null
p.dragActive=false
p.build=ScrollBarBuild
p.activate=ScrollBarActivate
p.mousedown=ScrollBarMouseDown
p.mousemove=ScrollBarMouseMove
p.mouseup=ScrollBarMouseUp
p.finishSlide=ScrollBarFinishSlide
p.getXfactor=ScrollBarGetXfactor
p.getYfactor=ScrollBarGetYfactor
p.setImages=ScrollBarSetImages
p.onScroll=new Function()
}

function ScrollBarSetImages(bg,box,shade,dir) {
	if (!dir) dir=''
	this.bgImg=(bg!=null)?dir+bg:''
	this.boxImg=(box!=null)?dir+box:''
	this.shadeImg=(shade!=null)?dir+shade:''
}

function ScrollBarBuild() {
	var bg=this.bgImg? 'background-image:URL('+this.bgImg+'); layer-background-image:URL('+this.bgImg+'); repeat:yes; ':''
	var box=this.boxImg? '<img src="'+this.boxImg+'" width='+this.boxW+' height='+this.boxH+'>' : ''
	var shade=this.shadeImg? '<div id="'+this.name+'Shade"><img src="'+this.shadeImg+'"></div>\n' : ''
	this.css=css(this.name,this.x,this.y,this.w,this.h,this.bgColor,null,null,bg)+
	css(this.name+'Box',0,0,this.boxW,this.boxH,this.boxColor,this.boxvis)+
	css(this.name+'C',0,0,this.w,this.h)
	if (this.shadeImg) this.css+=css(this.name+'Shade',0,0)
	this.div='<div id="'+this.name+'">'+shade+'<div id="'+this.name+'Box">'+box+'</div><div id="'+this.name+'C"></div></div>\n'
}

function ScrollBarActivate() 
{
	this.lyr=new DynLayer(this.name)
	this.boxlyr=new DynLayer(this.name+'Box')
	this.boxlyr.slideInit()
	this.boxlyr.onSlide=new Function(this.obj+'.onScroll()')
	this.lyrc=new DynLayer(this.name+'C')
	this.lyrc.elm.scrollbar=this.obj
	if (is.ns) this.lyrc.elm.captureEvents(Event.MOUSEDOWN | Event.MOUSEMOVE | Event.MOUSEUP | Event.MOUSEOUT)
	this.lyrc.elm.onmousedown=ScrollBarMouseSDown
	this.lyrc.elm.onmousemove=ScrollBarMouseSMove
	this.lyrc.elm.onmouseup=ScrollBarMouseSUp
	this.lyrc.elm.onmouseout=ScrollBarMouseSUp
	//this.lyrc.elm.onmouseover=new Function(this.obj+'.active=true')
	//this.lyrc.elm.onmouseout=new Function(this.obj+'.active=false')
}

function ScrollBarMouseSDown(e) {eval(this.scrollbar+'.mousedown('+(is.ns?e.layerX:event.offsetX)+','+(is.ns?e.layerY:event.offsetY)+')');return false;}
function ScrollBarMouseSMove(e) {eval(this.scrollbar+'.mousemove('+(is.ns?e.layerX:event.offsetX)+','+(is.ns?e.layerY:event.offsetY)+')');return false;}
function ScrollBarMouseSUp(e) {eval(this.scrollbar+'.mouseup()');return false}
function ScrollBarMouseSOut(e) {eval(this.scrollbar+'.mouseout()');return false}

function ScrollBarMouseDown(x,y) 
{
	this.mouseIsDown=true
	if (x>this.boxlyr.x && x<=this.boxlyr.x+this.boxlyr.w && y>this.boxlyr.y && y<=this.boxlyr.y+this.boxlyr.h) 
	{
		this.dragX=x-this.boxlyr.x
		this.dragY=y-this.boxlyr.y
		this.dragActive=true
	}
	else if (!this.boxlyr.slideActive) 
	{
		var newx=x-this.boxW/2
		var newy=y-this.boxH/2
		if (newx<0) newx=0
		if (newx>=this.offsetWidth) newx=this.offsetWidth
		if (newy<0) newy=0
		if (newy>=this.offsetHeight) newy=this.offsetHeight
		this.boxlyr.slideTo(newx,newy,this.inc,this.speed,this.obj+'.finishSlide()')
	}
}
function ScrollBarFinishSlide() {
	if (this.mouseIsDown) {
	this.dragX=this.boxW/2
	this.dragY=this.boxH/2
	this.dragActive=true
	}
}
function ScrollBarMouseMove(x,y) 
{
	if (!this.dragActive || this.boxlyr.slideActive) return;

	var newx=x-this.dragX
	var newy=y-this.dragY
	
	if (x-this.dragX<0) newx=0
	if (x-this.dragX>=this.offsetWidth) newx=this.offsetWidth
	if (y-this.dragY<0) newy=0
	if (y-this.dragY>=this.offsetHeight) newy=this.offsetHeight
	this.boxlyr.moveTo(newx,newy)
	this.onScroll()
}

function ScrollBarMouseUp() {
	this.mouseIsDown=false
	this.dragActive=false
	this.boxlyr.slideActive=false
}

function ScrollBarGetXfactor() {
	return 1-(this.offsetWidth-this.boxlyr.x)/this.offsetWidth||0
}

function ScrollBarGetYfactor() {
	return 1-(this.offsetHeight-this.boxlyr.y)/this.offsetHeight||0
}

ScrollBar.count=0
