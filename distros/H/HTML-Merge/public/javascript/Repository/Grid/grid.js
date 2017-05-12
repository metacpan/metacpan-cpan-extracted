//////////////////////////////////
// Grid js class		//
// Written by: Roi Illouz	//
// Date: 10/03/2002		//
// Raz Information Systems	//
//////////////////////////////////
function Grid(grid_init)
{
	// gui vars
	this.background = grid_init.background?grid_init.background:'silver';
	this.width = grid_init.width;
	this.width_str = this.width?'width='+this.width:'';
	this.height = grid_init.height;
	this.title_header = '<table border="0" cellspacing="0" cellpadding="1" '+this.width_str+' class="gridRepText__" style="border: 1px outset; border-bottom: 2px outset" id="oTtl_'+ grid_init.name +'" name="oTtl_'+ grid_init.name +'" onselectstart="return false">';
	this.title_header_row = '<tr bgcolor="'+this.background+'">'; 
	this.tbl_header = '<table border="0" cellspacing="0" cellpadding="1" bgcolor="white" '+this.width_str+' class="gridRepText__" id="oTbl_'+ grid_init.name +'" style="border: none;" name="oTbl_'+ grid_init.name +'" onselectstart="return false">';
	this.len = grid_init.size?grid_init.size:5;
	this.td_height = 15;
	this.js_class = grid_init.js_class?grid_init.js_class:'gridCntrlText__';
	this.sort_item = new Object();
	
	// init vars
	this.name = grid_init.name;
	this.bnd_src = grid_init.bnd_src;
	this.mode = grid_init.mode;
	this.note = grid_init.note;
	this.div = grid_init.div;
	this.dir = grid_init.dir?grid_init.dir:'ltr';
	this.charset = grid_init.charset?grid_init.charset:'ISO-8859-1';
	this.step = grid_init.step?grid_init.step:20;
	this.start = grid_init.start?grid_init.start:1;
	this.uid = grid_init.uid?grid_init.uid:'rid';
	this.langug_code = grid_init.langug_code;
	this.merge = grid_init.merge;
	this.image_path = grid_init.image_path;
	this.table;
	this.quote_data = (grid_init.quote_data)?true:false;
	
	// event func
	this.dbl_click_func = grid_init.dbl_click_func;
	this.click_func = grid_init.click_func;
	this.change_func = grid_init.change_func;

	// cursor defines
	this.clr_cursor="#cccccc";
	this.clr_cursor_zoom="#00007f";
	this.clr_cursor_mark="#aaaaaa";
	this.clr_cursor_base="#ffffff";
	this.clr_title_cursor_over="#000000";
	
	// cursor data structs
	this.zoomed_row = '';
	this.marked = new Array();
	
	// data vars
	this.obj = new Object();
	this.str_obj = new Object;
	this.grid_arr = new Array();
	this.grid_width = new Object();
	this.order_by='';
	this.order_by_dir='';
	this.dir_gif='';
	
	// scroolbar handlers
	this.vbar;
	this.current_step = this.step;
	
	// grid captions
	this.cap_record = grid_init.cap_record;
	this.cap_end_record = grid_init.cap_end_record;
	this.cap_sort = grid_init.cap_sort;
}
{var p=Grid.prototype
	p.Draw = GridDraw
	p.DrawCell = GridDrawCell
	p.DoEvents = GridDoEvents
	p.DoTitleEvents = GridDoTitleEvents
	p.DoUp = GridDoUp
	p.DoDown = GridDoDown
	p.DoDelMark = GridDoDelMark
	p.DoMark = GridDoMark
	p.DoLineChk = GridDoLineChk
	p.DoTitleClick = GridDoTitleClick
	p.DoTitleMouseOver = GridDoTitleMouseOver 
	p.DoTitleMouseOut = GridDoTitleMouseOut 
	p.DoDblClick = GridDoDblClick
	p.DoChange = GridDoChange
	p.DoOnContextMenu = GridDoOnContextMenu
	p.DoMouseOver = GridDoMouseOver 
	p.DoMouseOut = GridDoMouseOut 
	p.Refresh = GridRefresh
	p.Rebuild = GridRebuild
	p.SetData = GridSetData
	p.SetHeight = GridSetHeight
	p.SetWidth = GridSetWidth
	p.OrderTable = GridOrderTable
	p.DoSortArrow = GridDoSortArrow
	p.ClearImg = GridClearImg
	p.GetMarkedUid = GridGetMarkedUid
	p.GetMarkedUidAsStr = GridGetMarkedUidAsStr
	p.GetMarkedRowid = GridGetMarkedRowid
	p.GetMarkedRowidAsStr = GridGetMarkedRowidAsStr
	p.GetZoomUid = GridGetZoomUid
	p.GetZoomRowid = GridGetZoomRowid
	p.SetHeaderCaptionByID = GridSetHeaderCaptionByID
	p.SetHeaderCaptionByFieldName = GridSetHeaderCaptionByID
	p.GetHeaderCaptionByID = GridGetHeaderCaptionByID
	p.GetHeaderCaptionByFieldName = GridGetHeaderCaptionByID
	p.GetFieldByRowAndCol = GridGetFieldByRowAndCol
	p.GetTable = GridGetTable
	p.GetTitle = GridGetTitle
	p.UnMarkRow = GridUnMarkRow
	p.DelColumnByID = GridDelColumnByID
	p.DelColumnByFieldName = GridDelColumnByID
	p.GetZoomColor = GridGetZoomColor
	p.SetZoomColor = GridSetZoomColor
	p.GetCursorColor = GridGetCursorColor
	p.SetCursorColor = GridSetCursorColor
	p.CalcWidth = GridCalcWidth
	p.GetRowFromSrcEevent = GridGetRowFromSrcEevent
	p.GetCellFromSrcEevent = GridGetCellFromSrcEevent
	p.PaintRow = GridPaintRow
	p.GetRowidFromRow = GridGetRowidFromRow
	p.GetUidFromRow = GridGetUidFromRow
	p.GetInstanceFromRow = GridGetInstanceFromRow
	p.GetIsMarkedFromRow = GridGetIsMarkedFromRow
	p.SetIsMarkedByRow = GridSetIsMarkedByRow
	p.InitNavStr = GridInitNavStr
	p.CreateUrlStrFromObj = GridCreateUrlStrFromObj
	p.BuildFormHiddenFieldsFromObj = GridBuildFormHiddenFieldsFromObj
	p.AddRecord = GridAddRecord
	p.RemoveRecord = GridRemoveRecord
	p.Scroll = GridScroll
	p.GetLength = GridGetLength
	p.GetCellIDbyID = GridGetCellIDbyID
}
/////////////////////////////
function GridDoUp()
{
	var obj = new Object();
	
	if(this.grid_arr.length-1 < this.step)
		return;

	this.start += this.step;

	this.Rebuild('',obj,true);
}
/////////////////////////////
function GridDoDown()
{
	var obj = new Object();
	
	if(this.start <= 1)
		return;

	this.start-=this.step;

	this.Rebuild('',obj,true);
}
/////////////////////////////
function GridDoTitleEvents(obj)
{
	obj.onclick = this.DoTitleClick;
	obj.onmouseover = this.DoTitleMouseOver;
	obj.onmouseout = this.DoTitleMouseOut;
	obj.oncontextmenu = new Function("return false");
}
/////////////////////////////
function GridDoEvents(obj)
{
	obj.onmouseover = this.DoMouseOver;
	obj.onmouseout = this.DoMouseOut;
	obj.ondblclick = this.DoDblClick;
	obj.onclick = this.DoChange;
	obj.oncontextmenu = this.DoOnContextMenu;
	obj.onselectstart =  new Function("return false");
}
/////////////////////////////
function GridDoTitleMouseOver() 
{ 
	var row = GridGetRowFromSrcEevent(event.srcElement); if(!row) return;
	var cell = GridGetCellFromSrcEevent(event.srcElement); if(!cell) return;
	var instance = GridGetInstanceFromRow(row);
	var grid_element = cell.grid_element;

	if(grid_element == 'grid_mark')
		return;

	cell.childNodes[0].childNodes[3].style.textDecoration='underline';
	//cell.childNodes[0].style.textDecoration='underline';
}
/////////////////////////////
function GridDoTitleMouseOut() 
{ 
	var row = GridGetRowFromSrcEevent(event.srcElement); if(!row) return;
	var cell = GridGetCellFromSrcEevent(event.srcElement); if(!cell) return;
	var instance = GridGetInstanceFromRow(row);
	var grid_element = cell.grid_element;

	if(grid_element == 'grid_mark')
		return;

	cell.childNodes[0].childNodes[3].style.textDecoration='none';
}
/////////////////////////////
function GridDoTitleClick() 
{
	var row = GridGetRowFromSrcEevent(event.srcElement); if(!row) return;
	var cell = GridGetCellFromSrcEevent(event.srcElement); if(!cell) return;
	var instance = GridGetInstanceFromRow(row);
	var grid_element = cell.grid_element;
	var param = new Object;
	var is_marked = instance.GetIsMarkedFromRow(row);
			
	if(grid_element != 'grid_mark')
	{
		instance.OrderTable(grid_element);
		return;
	}

	// if in zoom mod return 
	if(instance.zoomed_row)
		return false;
	
	if(!is_marked)
	{
		instance.SetIsMarkedByRow(row,true);
		instance.DoLineChk(true);
	}
	else
	{
		instance.SetIsMarkedByRow(row,false);
		instance.DoLineChk(false);
	}
	
	// handle the user event
	if(this.on_click_func)
	{
		// create the param line for the func obj
		param.uid = instance.GetMarkedUidAsStr(instance.quote_data);
		param.rowid = instance.GetMarkedRowidAsStr(instance.quote_data);
		param.flag = is_marked;
	
		eval(this.on_click_func+'(param)');
	}
}
/////////////////////////////
function GridDoMouseOver() 
{ 
	var row = GridGetRowFromSrcEevent(event.srcElement);
	var instance = GridGetInstanceFromRow(row);

	if(row.childNodes[1].style.backgroundColor == instance.clr_cursor_base)
		instance.PaintRow(row,instance.clr_cursor);
}
/////////////////////////////
function GridDoMouseOut() 
{ 
	var row = GridGetRowFromSrcEevent(event.srcElement);
	var instance = GridGetInstanceFromRow(row);
	
	if(row.childNodes[1].style.backgroundColor == instance.clr_cursor)
		instance.PaintRow(row,instance.clr_cursor_base);
}
/////////////////////////////
function GridDoChange() 
{
	var row = GridGetRowFromSrcEevent(event.srcElement); if(!row) return;
	var cell = GridGetCellFromSrcEevent(event.srcElement); if(!cell) return;
	var instance = GridGetInstanceFromRow(row);
	var grid_element = cell.grid_element;
	var query_index = instance.GetUidFromRow(row);
	var index = instance.GetRowidFromRow(row);
	var param = new Object;
	var is_marked;

	if(grid_element != 'grid_mark')
		return;

	// if in zoom mod return 
	if(instance.zoomed_row)
		return;
	
	// mark the checked chekboxes
	if(row.childNodes[1].style.backgroundColor == instance.clr_cursor_mark)
	{
		instance.DoDelMark(row);
		is_marked = false;
	}
	else
	{
		instance.DoMark(row,query_index);
		is_marked = true;
	}
	
	// handle the user event
	if(instance.change_func)
	{
		// create the param line for the func obj
		param.uid = query_index;
		param.rowid = index;
		param.flag = is_marked;
	
		eval(instance.change_func+'(param)');
	}

}
/////////////////////////////
function GridDoDblClick(selected_row,selected_cell) 
{ 
	var row = selected_row ? selected_row : GridGetRowFromSrcEevent(event.srcElement);
	var cell = selected_cell ? selected_cell : GridGetCellFromSrcEevent(event.srcElement);
	var instance = GridGetInstanceFromRow(row);
	var grid_element = cell.grid_element;
	var index = instance.GetRowidFromRow(row);
	var param = new Object(); // all param to be send to user func

	if(grid_element == 'grid_mark')
		return;

	if(instance.zoomed_row == row)
	{	
		instance.PaintRow(row,instance.clr_cursor_base,'#000000');
		instance.zoomed_row = '';
	}
	else
	{
		// clear all Marked
		instance.DoLineChk(false);
		
		// clear all zoom
		if(instance.zoomed_row)
			instance.PaintRow(instance.zoomed_row,instance.clr_cursor_base,'#000000');
		
			
		instance.PaintRow(row,instance.clr_cursor_zoom,'#ffffff');
		
		instance.zoomed_row = row;
	}
	
	// handle the user event
	if(instance.dbl_click_func)
	{
		// create the param line for the func obj
		param.uid = instance.grid_arr[index] ? instance.grid_arr[index][instance.uid] : '';
		param.rowid = index;
		param.flag = (instance.zoomed_row)?true:false;

		eval(instance.dbl_click_func+'(param)');
	}
}
/////////////////////////////
function GridDoOnContextMenu()
{
	var row = GridGetRowFromSrcEevent(event.srcElement);
	var cell = GridGetCellFromSrcEevent(event.srcElement);
	var instance = GridGetInstanceFromRow(row);
	var grid_element = cell.grid_element;
	var row_id = instance.GetRowidFromRow(row);

	if(grid_element == 'grid_mark')
		return false;

	alert(instance.grid_arr[row_id][grid_element]);

	return false;
}
/////////////////////////////
function GridGetRowFromSrcEevent(element)
{
	var row;

	switch(element.nodeName) 
	{
		case 'SPAN':
			row = element.parentNode.parentNode.parentNode;
			break;
                case 'DIV':
			row = element.parentNode.parentNode;
			break;
                case 'TD':
			row = element.parentNode;
			break;
			
	}
	
	return row;
}
/////////////////////////////
function GridGetCellFromSrcEevent(element)
{
	var cell;

	switch (element.nodeName) 
	{
		case 'SPAN':
			cell = element.parentNode.parentNode;
			break;
                case 'DIV':
			cell = element.parentNode;
			break;
                case 'TD':
			cell = element;
			break;
			
	}
	
	return cell;
}
/////////////////////////////
// run over the line checkboxes and change their values
function GridDoLineChk(flag)
{
	var i = 1;
	var table = this.GetTable();
	
	if(!table)
		return;
		
	// init all marked objects
	this.marked = new Array();
	this.marked[0] = '';
	
	if(flag)
	{
		// run the length of the grid
		while(this.grid_arr[i])
		{	
			if(!table.rows[i-1])
				break;

			// mark the checked elements
			this.DoMark(table.rows[i-1],this.grid_arr[i][this.uid]);

			i++;
		}
	}
	else
	{
		while(this.grid_arr[i])
		{	
			if(!table.rows[i-1])
				break;

			this.DoDelMark(table.rows[i-1]);
			i++;
		}
	}
}
/////////////////////////////
function GridOrderTable(element)
{
	var img_name = 'c_'+this.name+'_'+element;
	var src = document.images[img_name].src;
	var path = this.image_path;
	var form = document.forms[0] ? document.forms[0] : '';

	if(this.zoomed_row)
		return;
	
	src=src.substring(src.lastIndexOf('/')+1);
	
	// change the image source
	switch (src) 
	{			
		case 'space.gif':
			src = 'up.gif';
			this.order_by_dir='ASC';
		
			break;
			
		case 'up.gif':
			src = 'down.gif';
			this.order_by_dir='DESC';
			break;
			
		case 'down.gif':
			this.order_by_dir='';
			src = 'space.gif';
			break;
	}

	if(this.order_by_dir)	
		this.order_by = element;
		
	this.dir_gif=path+'/'+src;

	// init the start vars 
	this.start = 1;
	this.current_step = this.step;
	
	// allways try to trasport by form as the safest way
	this.Rebuild('','',true,this.start,form);
}
/////////////////////////////
function GridDoSortArrow(image,element)
{
	var grid_img = document.images[element];
	
	this.ClearImg();

	if(!image || !element || !grid_img)
		return;

	grid_img.src = image;
	
	if(grid_img.src.indexOf('space.gif') >= 0)
	{
		grid_img.width = 0;
		grid_img.height = 0;
	}
	else
	{
		grid_img.width = 12;
		grid_img.height = 11;
	}
	
	// mark the sort itemes
	this.sort_item.element = element;
	this.sort_item.image = image;
}
/////////////////////////////
function GridClearImg()
{
	var img_name;
	var element;
	
	for(element in this.grid_arr[0])
        {

		img_name = 'c_'+this.name+'_'+element;
		
		if(document.images[img_name])
		{
			document.images[img_name].src = this.image_path+'/space.gif';
			document.images[img_name].width = 0;
			document.images[img_name].height = 0;
		}
	}
}
/////////////////////////////
function GridDraw()
{
	var i;
	var element;
	var first = true;
	var table;
	var str_maxlength;
	var tmp;
	var css_class;
	var background;
	var width;
	var grid_length = this.GetLength();
	var height = this.height ? this.height : (this.td_height*1+3)*this.len;
	var cell_id;

	// do the title line
	document.writeln(this.title_header);
	document.writeln('<tbody>');
	document.writeln(this.title_header_row);

	table = this.GetTitle();

	for(element in this.grid_arr[0])
	{
		cell_id = this.GetCellIDbyID(element);

		// first line
		if(first)
		{
			css_class = 'td_title_side__'; 
			first = false;
		}
		else
		{
			css_class = 'td_title_'+this.dir+'__'; 
		}

		// build the str_obj element
		tmp = this.DrawCell(0,element);

		document.writeln("<td id='" + cell_id + "' grid_element='"+element+"' height='"+this.td_height+"' align='baseline' style='width:"+this.grid_width[element]+";height:"+this.td_height+";cursor: hand' nowrap><div class='"+css_class+"' style='overflow: hidden; width:"+this.grid_width[element]+"'>"+tmp+"</div></td>");

		// build the coll maxlength
		str_maxlength = table.rows[0].cells[cell_id].childNodes[0].col_maxlength;
		if(str_maxlength)
			this.str_obj[element] = str_maxlength;
			
		// add title default events
		this.DoTitleEvents(table.rows[0].cells[cell_id]);
	}
	document.writeln('</tr></tbody></table>');

	// calc the table width
	this.CalcWidth();

	// do the default grid body
	document.writeln("<div dir='"+this.dir+"' style='overflow-y: auto; overflow-x: hidden; height: "+height+"; width: "+this.width+"px;'>");
	document.writeln(this.tbl_header);
	document.writeln('<tbody>');
	document.writeln("</tbody></table></div>\n");
	
	table = this.GetTable();

	for(i=1;i <= grid_length;i++)
	{  
		this.AddRecord('last',i);
		
	}

	document.writeln('<div dir="'+this.dir+'">');
	document.writeln('<input type="button" name="'+this.name+'_up" class="grid_btn_navi__" style="background-color:'+this.background+'" value="<" onClick="c_'+this.name+'.DoDown()">');
	document.writeln('<input type="button" name="'+this.name+'_down" class="grid_btn_navi__" style="background-color:'+this.background+'" value=">" onClick="c_'+this.name+'.DoUp()">');
	document.writeln('<span class="gridCntrlText__" id="nav_str_'+this.name+'"></span>');
	document.writeln('</div>');

	// Init the nav string
        this.InitNavStr();
}
/////////////////////////////
function GridAddRecord(pos,query_index)
{
        var table = this.GetTable();
        var row = document.createElement("TR");
        var td = new Array();
        var element;
        var i = 0;
        var tmp;
	var first = true;

	// init first flag
	first = true;

	tmp = this.DrawCell(query_index,element);

        for(element in this.grid_arr[0])
        {
        	td[i] = document.createElement("TD");

		if(first)
		{
			td[i].className = 'td_tbl_side__'; 
			td[i].style.backgroundColor = this.background;
			td[i].style.width = this.grid_width[element];

			first = false;
		}
		else
		{
			td[i].className = 'td_tbl_'+this.dir+'__'; 
			td[i].style.backgroundColor = '#ffffff';
			td[i].style.width = this.grid_width[element] - 1;
		}

                td[i].height = this.td_height;
                td[i].grid_element = element;
                td[i].id = this.name +'_' + element;
		
		tmp = this.DrawCell(query_index,element);

		// add the data div
                td[i].innerHTML = "<div style='overflow: hidden; width:"+td[i].style.width+"'>"+tmp+"</div>";

        	row.appendChild(td[i]);

		// advance the counter
		i++;
	}

	this.DoEvents(row);
		
        if(pos == 'last')
        {
                table.appendChild(row);
        }
        else
        {
                table.insertBefore(row,table.rows[0]);
        }
}
/////////////////////////////
function GridRemoveRecord(pos)
{
	var table = this.GetTable();
	var row_num = pos == 'last' ? table.rows.length - 1 : 0;
	
	if(table.rows[row_num])
        	table.removeChild(table.rows[row_num]);
	else
		alert("can't remove row "+row_num+" out of range!");
}
/////////////////////////////
function GridInitNavStr()
{
	var grid_length = this.GetLength();
	var to = this.start + grid_length - 1;
	var txt;
	
	if(to < this.start)
	{
		txt = this.cap_end_record;
	}
	else
	{
		txt = this.cap_record+' ['+this.start+' - '+to+']';
	}

        window['nav_str_'+this.name].innerText = txt;
}
///////////////////////////
function GridGetTable()
{
	return document.getElementById('oTbl_'+this.name).getElementsByTagName("TBODY")[0];
}
/////////////////////////////
function GridGetTitle()
{
	return document.getElementById('oTtl_'+this.name).getElementsByTagName("TBODY")[0];
}
/////////////////////////////
function GridDoMark(row,query_index)
{
	this.marked[this.GetRowidFromRow(row)] = query_index;
	this.PaintRow(row,this.clr_cursor_mark);
}
/////////////////////////////
function GridDoDelMark(row)
{
	this.marked[this.GetRowidFromRow(row)] = '';
	this.PaintRow(row,this.clr_cursor_base);
}
//////////////////////////// 
// refresh the grid data content 
function GridRefresh(line_offset)
{
	var table = this.GetTable();
	var i = 1;
	var buf;
	var grid_length = this.GetLength();
	
	// give default value
	line_offset = line_offset?line_offset:0;
	
	// init all check boxes and marked objects
	this.DoLineChk(false);

	if(this.zoomed_row)
	{
		this.DoDblClick(this.zoomed_row,this.zoomed_row.childNodes[1]);
	}

	for(i = line_offset;i < this.step;i++)
	{
		if(i < grid_length)
		{
			if(!table.rows[i])
				this.AddRecord('last',i+1);

			for(element in this.grid_arr[0])
			{	
				table.rows[i].cells[this.GetCellIDbyID(element)].childNodes[0].innerHTML = this.DrawCell(i+1,element);
			}
		}
		else
		{
			if(table.rows[grid_length] && table.rows[table.rows.length-1])
				this.RemoveRecord('last');
		}
	}	

	// create the sort arrow
	if(this.sort_item.element)
		this.DoSortArrow(this.sort_item.image,this.sort_item.element);
	else
		this.ClearImg();
	
	// init the grid gui vars:
	this.zoomed_row = '';
	this.marked = new Array();

	// init the nav str
	this.InitNavStr();
}
//////////////////////////// 
// rebuild the grid from the db
function GridRebuild(extra,obj,suppress_header_rebuild,line_offset,form)
{
	var buf = '';
	var form_save = new Object();

	// save the header 
	if(suppress_header_rebuild)
		buf = this.grid_arr[0];
		
	// clear the sort_item indicator
	this.sort_item = new Object();
	
	// init the grid array
	this.grid_arr = new Array();

	// save only the header if suppress_header_rebuild 
	this.grid_arr[0] = buf;
	
	if(line_offset)
		this.start = line_offset;

	if(!obj)
		var obj = new Object();
	
	obj.bnd_src = this.bnd_src;
	obj.uid = this.uid;
	obj.__grid_name__ = this.name;
	obj.langug_code = this.langug_code;
	obj.step = obj.step?obj.step:this.step;
	obj.extra = extra?extra:'';
	obj.suppress_header_rebuild = suppress_header_rebuild?1:0;
	obj.start = this.start;
	obj.order_by_dir = this.order_by_dir;
	obj.order_by = this.order_by;
	obj.dir_gif = this.dir_gif;
	obj.charset = this.charset;
	obj.template = 'Repository/Grid/grid_refresh.html';
	obj.__image_path__ = this.image_path;

	if(form)
	{
		// save the original settings
		form_save.action = form.action;
		form_save.method = form.method;
		form_save.target = form.target;

		if(form.template)
			form_save.template = form.template.value;

		this.BuildFormHiddenFieldsFromObj(form,obj);

		form.action = this.merge;
		form.method = 'post';
		form.target = 'build_form_data_proc';

		form.submit();

		// restore form settings
		form.action = form_save.action;
                form.method = form_save.method;
                form.target = form_save.target;

		if(form_save.template)
			form.template.value = form_save.template;
	}
	else
	{
		// create the var buffer 
		buf = this.CreateUrlStrFromObj(form,obj);
		
		// do the http request
		build_form_data_proc.location.href = this.merge+"?template="+obj.template+buf;	
	}
}
////////////////////////////
function GridCreateUrlStrFromObj(form,obj)
{
	var buf = '';

        for(element in obj)
        {
        	buf+='&'+element+'='+obj[element];
        }

	return buf;
}
////////////////////////////
function GridBuildFormHiddenFieldsFromObj(form,obj)
{
	var input
;
	for(element in obj)
        {
		input = document.getElementById(element);
		
		if(input)
		{
			input.value = obj[element];

			continue;
		}
		
		input = document.createElement("INPUT");
		input.type = 'hidden';
		input.name = element;
		input.id = element;
		input.value = obj[element];
		
		form.appendChild(input);
	}
}
////////////////////////////
function GridSetData(obj,rownum)
{
	this.grid_arr[rownum] = obj;
}
////////////////////////////
function GridSetWidth(obj)
{
	this.grid_width = obj;	
}
////////////////////////////
function GridSetHeight(height)
{
	if(height)
		this.td_height = height;	
}
////////////////////////////
function DeepCopy(src,dest)
{
	alert('using deep copy');

	for(element in src)
	{
		dest[element]=src[element];
	}
}
////////////////////////////
function GridGetMarkedUid(){ return this.marked; }
////////////////////////////
function GridGetMarkedUidAsStr(quoted)
{
	var i;

	var buf = '';
	var sep = (quoted)?"','":",";
		
	for(i in this.marked)
	{
		if(this.marked[i])
		{
			buf += this.marked[i]+sep;
		}
	}

	// cut the last seperator 
	buf = buf.substr(0,(buf.length-sep.length));
	
	if(!buf)
		return '';

	return (quoted)?"'"+buf+"'":buf;
}
////////////////////////////
function GridGetMarkedRowid()
{
	var i;
	var arr = new Array();
	
	for(i in this.marked)
	{
		if(this.marked[i])
			arr[arr.length] = i;
	}

	return arr; 
}
////////////////////////////
function GridGetMarkedRowidAsStr(quoted)
{
	var arr = this.GetMarkedRowid();
	var buf = '';
	var sep = (quoted)?"','":",";
	
	for(i in arr)
	{
		if(arr[i])
		{
			buf+=arr[i]+sep;
		}
	}
	
	// cut the last seperator 
	buf = buf.substr(0,(buf.length-sep.length));
	
	if(!buf)
		return;

	return (quoted)?"'"+buf+"'":buf;
}
////////////////////////////
function GridGetZoomUid() { return this.zoomed_row ? this.grid_arr[this.GetZoomRowid()*1][this.uid] : '' ; }
////////////////////////////
function GridGetZoomRowid() { return this.zoomed_row ? this.GetRowidFromRow(this.zoomed_row) : '' }
////////////////////////////
function GridSetHeaderCaptionByID(id,str) 
{ 
	if(!id)
		return;

	var table = this.GetTitle(); 
	var cell_id = this.GetCellIDbyID(id);
	var obj = table.rows[0].cells[cell_id].childNodes[0];

	// if number
	if(id*1 == id)
		id = table.rows[0].cells[cell_id].grid_element;

	var buf = this.grid_arr[0][id];
	var pre_str_idx = buf.indexOf('>',buf.indexOf('<span')) + 1;
	var post_str_idx = buf.lastIndexOf('<');

	buf = buf.substring(0,pre_str_idx) + str + buf.substring(post_str_idx);
	this.grid_arr[0][id] = buf;

	buf = this.DrawCell(0,id);
	obj.innerHTML = buf;
}
////////////////////////////
function GridGetHeaderCaptionByID(id){var table = this.GetTitle(); return table.rows[0].cells[this.GetCellIDbyID(id)].innerText;}
////////////////////////////
function GridGetFieldByRowAndCol(row,col){return (!this.grid_arr[row])?'':this.grid_arr[row][col];}
////////////////////////////
function GridUnMarkRow(row)
{
	var table = this.GetTable();
	var obj = table.rows[row*1+1].cells[1].childNodes[0];
	
	obj.checked = false;
	this.DoChk(obj,row*1+1);
}
////////////////////////////
function GridDelColumnByID(id)
{
	var row;
	var table = this.GetTable();
	var title = this.GetTitle();
	var i;
	var cell_id = this.GetCellIDbyID(id);

	// let's delete the specific col from the grid_arr
	for(row in this.grid_arr)
	{
		delete(this.grid_arr[row][id]);
	}
	
	// now let's physicaly delete the column
	title.rows[0].removeChild(title.rows[0].cells[cell_id]);
	
	for(i=0;i<table.rows.length;i++)
	{
		if(table.rows[i].cells[cell_id])
		{
			table.rows[i].removeChild(table.rows[i].cells[cell_id]);
		}
	}
}
////////////////////////////
function GridCalcWidth()
{
	var table = this.GetTitle();

	if(!this.width)
		this.width = table.offsetWidth + 2;
	
	return this.width;
}
////////////////////////////
function GridGetZoomColor(){return this.clr_cursor_zoom;}
////////////////////////////
function GridSetZoomColor(val){this.clr_cursor_zoom = val;}
////////////////////////////
function GridGetCursorColor(){return this.clr_cursor;}
////////////////////////////
function GridSetCursorColor(val){this.clr_cursor = val;}
////////////////////////////
function GridPaintRow(row,back_clr,clr)
{
	for(i=1;row.childNodes[i];i++)
        {
        	row.childNodes[i].style.backgroundColor = back_clr;

		if(clr)
			row.childNodes[i].style.color = clr;
	
        }
}
////////////////////////////
function GridGetRowidFromRow(row)
{
	var child_str = row.childNodes[0].childNodes[0].childNodes[0].id;

	return child_str.substring(11);
}
////////////////////////////
function GridGetUidFromRow(row)
{
	return row.childNodes[0].childNodes[0].childNodes[0].uid;
}
////////////////////////////
function GridGetIsMarkedFromRow(row)
{
	return row.childNodes[0].childNodes[0].childNodes[0].marked ? true : false;
}
////////////////////////////
function GridSetIsMarkedByRow(row,flag)
{
	var val = (flag == true) ? 1 : 0; 

	row.childNodes[0].childNodes[0].childNodes[0].marked = val;

	return;
}
////////////////////////////
function GridGetInstanceFromRow(row)
{
	return eval('c'+row.parentNode.parentNode.name.substring(4));
}
////////////////////////////
function GridDrawCell(index,element)
{
	var buf = this.grid_arr[index][element];

 	if(this.str_obj[element]*1)
        	buf  = buf.substr(0,this.str_obj[element]);

	if(index == 0)
	{
		if(element != 'grid_mark')
			buf = '&nbsp;'+buf;
	}
	else
	{
		if(element == 'grid_mark')
			buf += '&nbsp';
		else		
			buf = '&nbsp;'+buf+'&nbsp;';
	}

	return buf;
}
////////////////////////////
function GridScroll(x,y)
{
	table = this.GetTable();

	// need to put scrolling code here	
}
////////////////////////////
function GridGetLength()
{
	var data_length = this.grid_arr.length*1 - 1;

	if(!this.grid_arr.length)
		return 0;

 	return data_length < this.step ? data_length : this.step;
}
////////////////////////////
function GridGetCellIDbyID(id){ return (id*1 == id) ? id : this.name+'_'+id; }
////////////////////////////
