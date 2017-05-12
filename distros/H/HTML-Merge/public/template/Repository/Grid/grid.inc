
<SCRIPT language=JavaScript src="<$RCFG.MERGE_PATH>/public/javascript/razglobal.js"></SCRIPT>
<SCRIPT language=JavaScript src="<$RCFG.MERGE_PATH>/public/javascript/Repository/Grid/grid.js"></SCRIPT>

<style>
	.td_title_LTR__ {
	overflow : hidden;
	border : 2px groove;
	border-top : none;
	border-bottom : none;
	border-right : none;
	}
	.td_title_RTL__ {
	overflow : hidden;
	border : 2px groove;
	border-top : none;
	border-bottom : none;
	border-left : none;
	}
	.td_title_side___ {
	border : none;
	width : 15px;
	cursor : hand;
	}
	.td_tbl_LTR__ {
	border : silver 1px solid;
	border-top : none;
	border-left : none;
	}
	.td_tbl_RTL__ {
	border : silver 1px solid;
	border-top : none;
	border-right : none;
	}
	.td_tbl_side__ {
	border : 1px outset;
	border-top : none;
	border-bottom : 2px groove;
	cursor : hand;
	width : 15px;
	}
	.td_tbl_empty__ {
	border : none;
	width : 15px;
	}
	.grid_btn_navi__ {
	height : 15px;
	width : 15px;
	font-family : Arial (Hebrew),Arial, David (Hebrew), Courier New (Hebrew);
	font-size : 8px;
	font-weight : bold;
	line-height : normal;
	color : #000000;
	background-color: transparent;
	border: 2px groove;
	cursor: hand;
	}
	.gridsText__ {
	font-size : 11px;
	font-weight : normal;
	color : #000000;
	font-family : Arial (Hebrew),Arial, David (Hebrew), Courier New (Hebrew);
	text-decotation : none;
	}
	
	.gridRepText__ {
	font-size : 11px;
	font-weight : normal;
	color : #000000;
	font-family : Arial (Hebrew),Arial, David (Hebrew), Courier New (Hebrew);
	text-decotation : none;
	}
	
	.gridCntrlText__ {
	font-size : 11px;
	font-weight : normal;
	color : #000000;
	font-family : Arial (Hebrew),Arial, David (Hebrew), Courier New (Hebrew);
	text-decotation : none;
	}
</style>

<script language="javascript">
<!--
if(!window.build_form_data_proc)
	document.writeln("<iframe src='<$RMERGE>?template=blank.html' id='build_form_data_proc' name='build_form_data_proc' width='0' height='0'></iframe>");

// create the class init struct 
var grid_init = new Object;

<$RPERL.B>
my $str='<$RVAR.__field_data__>';
my (@val,@tmp);

return if !$str;

@val=split(/;\s*/,$str);

foreach (@val)
{
        @tmp=split(/\s*=\s*/);
		print qq!grid_init.$tmp[0]='$tmp[1]';\n!;
		setvar($tmp[0],$tmp[1]);
}              
</$RPERL>

<$REM - map all captions to class and VARS - >
<$R[grid_captions].DB='SYSTEM'>
<$R[grid_captions].Q='SELECT name,note
		      FROM tbl 
		      WHERE tbl='FRMSTR' 
		      AND langug_code='<$RVAR.langug_code>' 
		      AND note IN ('cap_sort','cap_record','cap_end_record') '>
<$R[grid_captions].LOOP>
<$RSET.<$R[grid_captions].SQL.note>=' "<$R[grid_captions].SQL.name>" '>
grid_init.<$R[grid_captions].SQL.note>='<$R[grid_captions].SQL.name>';
</$R[grid_captions].LOOP>

<$REM - lets give default values>
<$RSET.step=' <$RDECIDE.' "<$RVAR.__maxlength__>" '?'<$RVAR.__maxlength__>':'50'> '>
<$RSET.langug_code=' <$RDECIDE.' "<$RVAR.langug_code>" '?' "<$RVAR.langug_code>" ':'en'> '>
<$RSET.uid=' <$RDECIDE.' "<$RVAR.uid>" '?'<$RVAR.uid>':'rid'> '>
<$RSET.__image_path__=' "public/gif" '>

grid_init.name = '<$RVAR.__field_name__>';
grid_init.size = <$RPIC.N(.0).'<$RVAR.__size__>'>;
grid_init.width = <$RPIC.N(.0).'<$RVAR.__width__>'>;
grid_init.height = <$RPIC.N(.0).'<$RVAR.__height__>'>;
grid_init.background = '<$RVAR.__background__>'
grid_init.mode = '<$RVAR.mode>';
grid_init.note = '<$RVAR.note>';
grid_init.div = '<$RVAR.__field_name__>_fld';
grid_init.dir = '<$RVAR.dir>';
grid_init.charset = '<$RVAR.charset>';
grid_init.step = <$RVAR.step>;
grid_init.start = 1;
grid_init.bnd_src = '<$RVAR.__src__>';
grid_init.langug_code = '<$RVAR.langug_code>';
grid_init.dbl_click_func='<$RVAR.__onDblClick__>';
grid_init.click_func='<$RVAR.__onClick__>';
grid_init.change_func='<$RVAR.__onChange__>';
grid_init.merge='<$RMERGE>';
grid_init.image_path='<$RVAR.__image_path__>';
grid_init.js_class='<$RVAR.__class__>';

<$REM - create the grid class>
<$RSET.grid_class=' "c_<$RVAR.__field_name__>" '>

// init the grid class
var <$RVAR.grid_class>=new Grid(grid_init);
//-->
</script>

<$RSET.repository_template=' "<$RVAR.__src__>" '>
<$RINCLUDE.'Repository/Grid/grid_build_data.inc'>

<script language="javascript">
<!--
	<$REM - create the grid>
	<$RIF.'"<$R[<$RVAR.repository_query_engine>].SQL.src>"'>
		<$RVAR.grid_class>.Draw();
	</$RIF>
//-->
</script>
</div>
