<$RIF.' "<$RVAR.repository_query_engine>" eq "" '>
	<$RTRACE.' Default engine (setting repository_query_engine var ) is not supported anymore change your code !!! '>
	<$RSET.repository_query_engine=' "repository" '>
</$RIF>

<$RIF.' "<$RVAR.repository_template>" eq "" '>
	<$RSET.repository_template=' "<$RTEMPLATE>" '>
</$RIF>

<$REM - get all of the user realms >
<$RIF.'!"<$RVAR.user_realms>"'>
	<$RINCLUDE.'Repository/get_user_realms.inc'>
</$RIF>

<$R[<$RVAR.repository_query_engine>].DB='SYSTEM'>

<$R[<$RVAR.repository_query_engine>].Q="
	SELECT a.*,
		b.field_name parent_field_name,
		b.fldtyp_code parent_fldtyp_code,
		b.src parent_src,
		b.value parent_value,
		b.size parent_size,
		b.maxlength parent_maxlength,
		b.width parent_width,
		b.height parent_height,
		b.class parent_class,
		b.fldsts_code parent_fldsts_code,
		b.realm_id parent_realm_id,
		b.arrangement parent_arrangement,
		b.onBlur parent_onBlur,
		b.onClick parent_onClick,
		b.onDblClick parent_onDblClick,
		b.onChange parent_onChange,
		b.onMouseOver parent_onMouseOver,
		b.onMouseMove parent_onMouseMove,
		b.onMouseOut parent_onMouseOut,
		b.field_data parent_field_data,
		b.pos_x parent_pos_x,
		b.pos_y parent_pos_y,
		b.background parent_background,
		b.border parent_border,
		b.pos_delta parent_pos_delta,
		b.status_code parent_status_code,
		c.langug_code,
		c.caption,
		d.langug_code parent_langug_code,
		d.caption parent_caption,
		e.note fldstatus,
		f.note parent_fldstatus,
		g.note field_template,
		g.number isfield,
		g.name field_type,
		h.note parent_field_template,
		h.number parent_isfield,
		h.name parent_field_type
        FROM repository_t a
	LEFT JOIN repository_t b ON b.rid=a.field_parent_repository_id
					AND b.template_id='0'
	LEFT JOIN repository_language_matrix c ON c.repository_id=a.rid 
                                        AND c.langug_code='<$RVAR.langug_code>'
	LEFT JOIN repository_language_matrix d ON d.repository_id=b.rid 
                                        AND d.langug_code='<$RVAR.langug_code>'
	LEFT JOIN tbl e ON e.code=a.fldsts_code 
					AND e.tbl='FLDSTS'
                                        AND e.langug_code=''
	LEFT JOIN tbl f ON f.code=b.fldsts_code 
					AND f.tbl='FLDSTS'
                                        AND f.langug_code=''
	LEFT JOIN tbl g ON g.code=a.fldtyp_code 
					AND g.tbl='FLDTYP'
                                        AND g.langug_code=''
	LEFT JOIN tbl h ON h.code=b.fldtyp_code 
					AND h.tbl='FLDTYP'
                                        AND h.langug_code=''
	INNER JOIN templates_t i ON i.id=a.template_id
	INNER JOIN instances_t j ON j.id=i.instance_id
	WHERE i.templatename='<$RVAR.repository_template>' 
	AND j.instancename LIKE '<$RCFG.MERGE_ABSOLUTE_PATH>%'
	AND a.realm_id IN (<$RVAR.user_realms>) 
	AND a.status_code > 1
	ORDER BY a.arrangement
">
