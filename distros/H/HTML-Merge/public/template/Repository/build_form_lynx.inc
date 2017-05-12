<$RSET.__pos_dir__='(uc("<$RVAR.dir>") eq "RTL")?"right":"left"'>

<$REM - Build the Macro hash>
<$RIF.'!"<$RVAR.__loaded__macros__>"'>
	<$R[__macro__].Q='SELECT name,note FROM tbl WHERE tbl="MACROS" '>
	<$R[__macro__].LOOP>
		<$RSET.__macro_<$R[__macro__].SQL.name>__=' "<$R[__macro__].SQL.note>" '>
	</$R[__macro__].LOOP>
	<$RSET.__loaded__macros__='1'>
</$RIF>

<$REM - Do the page build>

<$RINCLUDE.'Repository/repush.inc'>

<$RINCLUDE.'Repository/repository_query.inc'>

<$RPERL>
	@page=undef;
	@page=[];
</$RPERL>

<$R[<$RVAR.repository_query_engine>].LOOP>
	<$RIF.' <$RPIC.N(.0)."<$R[<$RVAR.repository_query_engine>].SQL.isfield>"> '>
		<$RPERL.B>
			push(@{ $page[$#page] },qq!<$R[<$RVAR.repository_query_engine>].SQL.caption>!);
		</$RPERL>
	</$RIF>
	<$RPERL.A>
		# my $__x__='<$R[<$RVAR.repository_query_engine>].SQL.field_template>';
		my $__x__ = getfield('field_template', getvar('repository_query_engine'));

		$__x__=~ s/\@(.*?)\@/getvar("__macro_$1__")/ge;
		$__x__=~ s/#(.*?)#/getfield($1, getvar('repository_query_engine'))/ge;
		$__x__=~ s/``/\"/g;
		$__x__=~ s/`/\'/g;
		
		if (getfield('fldtyp_code', getvar('repository_query_engine')) eq "17")
		{
			push(@{ $page[$#page+1] },$__x__."\n");
			push(@page,[]);
		}
		else
		{
			push(@{ $page[$#page] },$__x__."\n");
		}
	</$RPERL>
</$R[<$RVAR.repository_query_engine>].LOOP>

<div align='<$RVAR.__pos_dir__>'>
<$RIF.' "<$RVAR.__pos_dir__>" eq "left" '>
	<$RPERL>
		my $row;
		
		foreach $row (@page)
		{ 
			foreach (@$row)
			{
				merge($_); 
			}
		}
	</$RPERL>
<$RELSE>
	<$RPERL>
		my $row;
		
		foreach $row (@page)
		{ 
			@$row=reverse(@$row);
			foreach (@$row)
			{
				merge($_); 
			}
		}
	</$RPERL>
<$REND_IF>
</div>

<$RINCLUDE.'Repository/repop.inc'>
