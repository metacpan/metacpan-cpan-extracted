<$RINC.engine_enum>
<$RPERL>
	if(!getvar('__rep_start_stack__'))
	{
		setvar('__rep_start_stack__',1);
    	@__stack__ = undef;
	}
	push(@__stack__, getvar('repository_query_engine'));
	setvar('repository_query_engine', 'rep' . getvar('engine_enum'));
</$RPERL>