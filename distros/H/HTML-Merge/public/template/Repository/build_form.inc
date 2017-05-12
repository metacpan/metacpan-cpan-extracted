<$RSET.__pos_dir__='(uc("<$RVAR.dir>") eq "RTL")?"right":"left"'>

<$REM - Build the Macro hash>
<$RIF.'!"<$RVAR.__loaded__macros__>"'>
	<$R[__macro__].DB='SYSTEM'>
	<$R[__macro__].Q='SELECT name,note FROM tbl WHERE tbl="MACROS" '>
	<$R[__macro__].LOOP>
		<$RSET.__macro_<$R[__macro__].SQL.name>__=' "<$R[__macro__].SQL.note>" '>
	</$R[__macro__].LOOP>
	<$RASSIGN.__loaded__macros__='1'>
</$RIF>

<$REM - Do the page build>
<$RINCLUDE.'Repository/repush.inc'>

<$RINCLUDE.'Repository/repository_query.inc'>
<$R[<$RVAR.repository_query_engine>].LOOP>
	<$RPERL>
		my $buf;

		# written in merge internals for preformance reason
		foreach ($engines{$vars{"repository_query_engine"}}->Columns) 
		{
			next if /^parent/;

			$buf = getfield($_, getvar('repository_query_engine'));
			$vars{"__${_}__"}=($buf ne '')?$buf:getfield("parent_$_", getvar('repository_query_engine'));
		}

		$vars{__pos_x_fld__}=($vars{__isfield__} ne '')?($vars{__pos_x__}+$vars{__pos_delta__}):$vars{__pos_x__};
	</$RPERL>

	<$RASSIGN.__border__=' <$RDECIDE.'<$RPIC.N(.0)."<$RVAR.__DEBUG__>">'?'thin solid':'<$RVAR.__border__>'> '>
	<$RASSIGN.__visibility__=' <$RDECIDE.' "<$RVAR.__fldstatus__>" eq "hidden"  '?'hidden':''> '>
	<div id="<$RVAR.__field_name__>_fld" class="<$RVAR.__class__>" dir="<$RVAR.dir>" style="position: absolute;<$RVAR.__pos_dir__>: <$RVAR.__pos_x_fld__>px; top: <$RVAR.__pos_y__>px; width:<$RVAR.__width__>px; height:<$RVAR.__height__>px; border: <$RVAR.__border__>; visibility: <$RVAR.__visibility__>;">
	<$RPERL>
		my $__x__ = getvar('__field_template__');
                $__x__=~ s/\@(.*?)\@/getvar("__macro_$1__")/ge;
                $__x__=~ s/#(.*?)#/getvar("__${1}__")/ge;
                $__x__=~ s/``/\"/g;
                $__x__=~ s/`/\'/g;
                merge($__x__);
	</$RPERL>
	</div>
	<$RIF.' <$RPIC.N(.0)."<$RVAR.__isfield__>"> '>
		<$RSET.__pos_y_cap__='<$RVAR.__pos_y__> + 0'>
		<$RASSIGN.__border__=' <$RDECIDE.'<$RPIC.N(.0)."<$RVAR.__DEBUG__>">'?'thin solid':''> '>	
		<div id="<$RVAR.__field_name__>_cap" class="<$RVAR.__class__>" style="position: absolute;<$RVAR.__pos_dir__>: <$RVAR.__pos_x__>px; top: <$RVAR.__pos_y_cap__>px; border: <$RVAR.__border__>; visibility: <$RVAR.__visibility__>;">
			<$RVAR.__caption__>
		</div>
	</$RIF>
</$R[<$RVAR.repository_query_engine>].LOOP>

<$RINCLUDE.'Repository/repop.inc'>
