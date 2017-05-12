// Created  : 18/12/2000
// Updated  : 
// Module   : razglobal.js
// Remarks  : general functions for raz projects on the web
// work with explorer netscape opera
// 	(C) Raz Information Systems.
// *******************************************
////////////////////////////////////////
function GetParameter(location,parameter)
{
	var pre,post,paramLength;
	var answer;
	
	pre = location.indexOf(parameter+'=');
	if(pre < 0) return null; // the paramter wasn't found in the location
	paramLength = parameter.length + 1;
	post = location.indexOf('&', pre);
	pre = pre + paramLength;
	if(post < 0) // it means it is the last parameter in the location
	{
		 post = location.length;
	}
	else // normal parameter
	{	
		post = post - pre;
	}
		 
	answer = location.substr(pre, post);
	return answer;
}
////////////////////////////////////////
function RemoveParameter(str,param)
{
	var pre,post;
	
	pre=str.indexOf('&'+param+'=');
	
	if(pre < 0)
		return str;
		
	post=str.indexOf('&',pre+1);
	
	return str.substr(0,pre)+str.substr(post);
}
////////////////////////////////////////
function CreateUrlVarString(oForm)
{
	var i;	
	var buf='';
	var dt = new Date() -1;	
	
	for (i=0; oForm.elements[i]!=null; i++)
	{
		buf = buf + oForm.elements[i].name + '=' + oForm.elements[i].value + '&';
	}

	buf = buf + 'dt='+dt; // to prevent the browser takes the page from cache
	
	return buf;
}
////////////////////////////////////////
function ReplaceBlank(str)
{
	var f_str;
	var reg = / /g;

	f_str = str.replace(reg,"+");

	return f_str;
}
//////////////////////////////////////////////////
function WrapperPopulateCbo(fatherCbo,sonCbo,selected,name)
{	// the function is the wrapper of the PopulateCbo function

	var i;
	var len;	
	var multiSelect = new Array();
	
	// cleaning	the populated field (from the end - it'a a recursive system)
	for (i=sonCbo.options.length - 1; i > 0 ; i--)
	{
		sonCbo.options[i] = null;
	}

	if(selected == '0.0' || selected == '0.00' || selected == '')
	{
		PopulateCbo(sonCbo,'',name);
		sonCbo.selectedIndex = 0; // the son is initialized
/*
		// that means that the father ComboBox was changed
		// to nothing, so the list in the populate field
		// should be of all the possible items
		len = fatherCbo.options.length - 1;	
		for(i=len; i>=1 ; i--) // in a recursia method
		{
			PopulateCbo(sonCbo,fatherCbo.options[i].value,name);
		}
		//SortD(sonCbo); // sort the combo
		sonCbo.selectedIndex = 0; // the son is also initialized
*/
	}

	else
	{	
		if((i=selected.indexOf('|')) != -1)
		{
			// cuts the first part(that's what we need)
			selected = selected.substr(0,i);
		}	
			
		// split the string to an array
		multiSelect = selected.split(",");
		
		len = multiSelect.length - 1;
		for(i=len; i>=0 ; i--) // in a recursia method
		{
			PopulateCbo(sonCbo,multiSelect[i],name);
		}
		sonCbo.selectedIndex = 0; // the son is initialized
	}						  
}
//////////////////////////////////////////////////
function PopulateCbo(sonCbo,selected,name)
{
	// the function populates the son Combo Box according
	// to the father Combo Box

	var i;
	var opt;
	var selectedArray_value = eval("qt_" + name + "_value" + selected);
	var selectedArray_text = eval("qt_" + name + "_text" + selected);
	
	// populating to the field the new options (from the end - it'a a recursive system)
	for (i=selectedArray_value.length -1 ; i >= 0; i--)
	{
		opt = new Option(selectedArray_text[i],selectedArray_value[i]);
		sonCbo.add(opt,1);
	}
	
	// we want to clean the first field in the Combo Box
	// in  of an old value
	sonCbo.options[0].value = '';
	sonCbo.options[0].text = '';		
}
//////////////////////////////////////////////////
function SortD(box)  
{
 	var temp_opts = new Array();
 	var temp = new Object();
 
 	for(var i=0; i<box.options.length; i++)  
	{
  		temp_opts[i] = box.options[i];
 	}

 	for(var x=0; x<temp_opts.length-1; x++)  
	{
  		for(var y=(x+1); y<temp_opts.length; y++)  
		{
   			if(temp_opts[x].text > temp_opts[y].text)  
			{
    			temp = temp_opts[x].text;
    			temp_opts[x].text = temp_opts[y].text;
    			temp_opts[y].text = temp;
    			temp = temp_opts[x].value;
    			temp_opts[x].value = temp_opts[y].value;
    			temp_opts[y].value = temp;
   			}
  		}
 	}

 	for(var i=0; i<box.options.length; i++)  
	{
  		box.options[i].value = temp_opts[i].value;
 	 	box.options[i].text = temp_opts[i].text;
 	}
}
//////////////////////////////////////////////////
function TrimDecimal(num,precision)
{
	var base=Math.floor(num);
	var exponent='';
	var str=num.toString();
	var tmp=str.indexOf('.');
	var i=0;
	
	if(tmp >=0)
	{
		exponent=str.substr(str.indexOf('.')+1,precision);
	}
	else
	{
		while(i++<precision)
		{
			exponent+='0';
		}
	}
	
	return base.toString()+'.'+exponent;
}
//////////////////////////////////////////////////
function GetXY(aTag)
{
 	var oTmp = aTag;
  	var pt = new Point(0,0);

  	do {
  		pt.x += oTmp.offsetLeft;
  		pt.y += oTmp.offsetTop;
  		oTmp = oTmp.offsetParent;
  	} while(oTmp.tagName!="BODY");
  
  	return pt;
}
//////////////////////////////////////////////////
function Point(iX, iY)
{
	this.x = iX;
	this.y = iY;
}
//////////////////////////////////////////////////
function GetCenterXY(width,height)
{
  	var pt = new Point(0,0);

  	pt.x=(screen.availWidth-10)/2-width/2;
	pt.y=(screen.availHeight-50)/2-height/2;

  	return pt;
}
//////////////////////////////////////////////////
function SetCBX(box,str)
//Set combo box according to string text
{
    for(var i=0; i<box.options.length; i++)  
    {
           if (box.options[i].text == str)
           {
         box.selectedIndex = i;
         return;
           }
    }
}
//////////////////////////////////////////////////