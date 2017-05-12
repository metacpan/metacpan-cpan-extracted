<script language="javascript">
<!--
var __grid_obj__ = new Object;
var __grid_width__ = new Object;
var __i = 1; //because 1 is the row num of the data

<$RPERL.C>
	# order the table by order by	
	my $sql=getvar('grid_query');
	my $sql_part='ORDER\s+BY';
	my @sql_parts_post=qw(LIMIT PROCEDURE FOR\s+UPDATE $);
	my $sql_parts_post=join('|',@sql_parts_post);
	my $res=1 if $sql =~ m/$sql_part/si;
	
	return if(!$sql);
	
	# if there is an order by clause replace it
	
	if(getvar("order_by"))
	{
		if($res)
		{
			$sql=~ s/$sql_part.*?(?=$sql_parts_post)/ ORDER BY <$RVAR.order_by> <$RVAR.order_by_dir> /si;
		}
		else
		{
			$sql=~ s/(?=$sql_parts_post)/ ORDER BY <$RVAR.order_by> <$RVAR.order_by_dir> /si;
		}
	}
	return "<\$R[grid].Q='$sql'>";
</$RPERL>

<$RINCLUDE.'Repository/repush.inc'>
<$RINCLUDE.'Repository/repository_query.inc'>

<$REM ----- the header section ----- >
<$RIF.'!<$RPIC.N(.0).'<$RVAR.suppress_header_rebuild>'>'>
<$RASSIGN.__def_height='15'>
<$RASSIGN.__def_side_width='15'>
<$RASSIGN.__def_width='100'>

__grid_obj__.grid_mark='<div id="grid_mark_all" uid="all" marked=""></div>';
__grid_width__.grid_mark='<$RVAR.__def_side_width>';
</$RIF>

<$R[<$RVAR.repository_query_engine>].LOOP>
	<$RIF.'!<$RPIC.N(.0).'<$RVAR.suppress_header_rebuild>'>'>
<$RASSIGN.__def_height=' <$RDECIDE.' "<$RPIC.N(.0).'<$R[<$RVAR.repository_query_engine>].SQL.height>'>" > <$RVAR.__def_height> '?' <$R[<$RVAR.repository_query_engine>].SQL.height> ':'<$RVAR.__def_height>'> '>
<$RASSIGN.__width=' <$RDECIDE.' "<$RPIC.N(.0).'<$R[<$RVAR.repository_query_engine>].SQL.width>'>" '?'<$R[<$RVAR.repository_query_engine>].SQL.width>':'<$RVAR.__def_width> '> '>
<$RINC.__width-20>
__grid_obj__.<$R[<$RVAR.repository_query_engine>].SQL.field_name>='<img border="0" src="<$RVAR.__image_path__>/space.gif" name="<$RVAR.grid_class>_<$R[<$RVAR.repository_query_engine>].SQL.field_name>" alt="<$RVAR.cap_sort>" border=0 width=0 height=0>&nbsp;<span class="<$RDECIDE.' "<$R[<$RVAR.repository_query_engine>].SQL.class>" '?'<$R[<$RVAR.repository_query_engine>].SQL.class>':'gridsText__'>" col_maxlength="<$R[<$RVAR.repository_query_engine>].SQL.maxlength>" style="width:<$RVAR.__width>" title="<$RVAR.cap_sort>"><$R[<$RVAR.repository_query_engine>].SQL.caption></span>';
__grid_width__.<$R[<$RVAR.repository_query_engine>].SQL.field_name>='<$RVAR.__width>'*1 + 20;
	</$RIF>

<$RSET.__PIC_<$R[<$RVAR.repository_query_engine>].SQL.field_name>=' "<$R[<$RVAR.repository_query_engine>].SQL.value>" '>
</$R[<$RVAR.repository_query_engine>].LOOP>

<$RIF.'!<$RPIC.N(.0).'<$RVAR.suppress_header_rebuild>'>'>
	<$RVAR.grid_ref><$RVAR.grid_class>.SetData(__grid_obj__,0);
	<$RVAR.grid_ref><$RVAR.grid_class>.SetWidth(__grid_width__);
	<$RVAR.grid_ref><$RVAR.grid_class>.SetHeight('<$RVAR.__def_height>');
</$RIF>
<$REM ----- end the header section ----- >

__grid_obj__ = new Object();

<$REM ----- the body section ----- >						  
<$REM - run till start>
<$R[grid].LOOP.LIMIT=<$RPIC.N(.0).'<$RVAR.start>'>>
</$R[grid].LOOP>

<$RIF.' <$R[grid].INDEX> == <$RPIC.N(.0).'<$RVAR.start>'> '>
<$R[grid].LOOP.LIMIT=<$RPIC.N(.0).'<$RVAR.step>'>>
	<$RINC.i>
	
	__grid_obj__.grid_mark='<div id="mark_check_<$RVAR.i>" uid="<$R[grid].SQL.<$RVAR.uid>>"></div>';
		
	<$R[grid].ENUMQUERY.var=val>
		<$RIF.' "<$RVAR.__PIC_<$RVAR.var>>" '>
			<$RPERL.B>
				print "\n__grid_obj__.<$RVAR.var> = '";
				merge("<\$RPIC.<$RVAR.__PIC_<$RVAR.var>>.'<$RVAR.val>'>");
				print "';";
			</$RPERL>
		<$RELSE>
__grid_obj__.<$RVAR.var> = '<$RVAR.val>'; 
		</$RIF>
	</$R[grid].ENUMQUERY>
	
	<$RVAR.grid_ref><$RVAR.grid_class>.SetData(__grid_obj__,__i++);
	
	__grid_obj__ = new Object();
</$R[grid].LOOP>
</$RIF>

<$REM ----- end the body section ----- >
<$REM - kill the grid query var >
<$RSET.grid_query=''>
<$R[grid].DISCONNECT>

<$RINCLUDE.'Repository/repop.inc'>
//-->
</script>
