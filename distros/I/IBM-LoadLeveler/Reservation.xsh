
#if LLVER >= 3030000

int
ll_bind(jobsteplist,ID,unbind,binding_method)
	char **jobsteplist
	char  *ID
	int    unbind
	int    binding_method	

	CODE:
	{
	    LL_element    *errObj = NULL;
	    LL_bind_param  param;
	    LL_bind_param *p_param = &param;
		
	    param.jobsteplist=jobsteplist;
	    param.ID=ID;
	    param.unbind=unbind;
#if LLVER >= 3050000
	    param.binding_method=binding_method;
#endif	    	    
	    RETVAL=ll_bind(LL_API_VERSION,&errObj,&p_param);
	    if ( RETVAL != RESERVATION_OK)
	    {
		    sv_setiv(get_sv("IBM::LoadLeveler::errObj",FALSE),(IV)errObj);	   
	    }
	}
        OUTPUT:
	    RETVAL			
			
void *
ll_make_reservation(start_time,duration,data_type,data,options,users,groups,group,...)
	char  *start_time
	int    duration
	int    data_type
	SV	*data
	int    options
	char **users
	char **groups
	char  *group	

	PPCODE:
	{
	    LL_element           *errObj = NULL;
	    LL_reservation_param  param;
	    LL_reservation_param *p_param = &param;
	    
	    int rc;    
#if LLVER >= 3050000
	    /* Handle new parameters */	    
	    char  *expiration;
	    SV    *recurrence;
	    
	    expiration = (char *)SvPV_nolen(ST(8));
	    recurrence = (SV *)ST(9);
#endif       
	    /* First Initialize the structure */
	    RETVAL=(void *)targ; /* bogus but spresses any unused variable error messages */
	    rc = ll_init_reservation_param(LL_API_VERSION,&errObj,&p_param);
	    if ( rc != 0 )
	    {
		/* If the init_routine fails send the error code and object back */
		XPUSHs(sv_2mortal(&PL_sv_undef));	
		if (rc != API_OK )
		{
		    sv_setiv(get_sv("IBM::LoadLeveler::errObj",FALSE),(IV)errObj);	   
		}

	    }
	    else		       
	    {
		if ( errObj != NULL )
		{
		    Safefree(errObj);
		    errObj=NULL;
		}
		param.start_time=start_time;
		param.duration=duration;
		param.data_type=data_type;	      
		/*fprintf(stderr,"Reserving at %s for %d minutes\n",start_time,duration);*/
		switch (data_type)
		{
		    case RESERVATION_BY_NODE:
#if LLVER >= 3040101
		    case RESERVATION_BY_BG_CNODE:
#endif
		    {
			int value;

			value=SvIV(data);	
			/*fprintf(stderr,"Reserving by nodes = %d, %s\n",value,group);*/
			/* Interface Change from 3.3.0.0 */
#if LLVER == 3030000
			param.data=(void *)value;
#else
			param.data=&value;
#endif
		    }
		    break;
		    case RESERVATION_BY_HOSTLIST:
		    {
			param.data=XS_unpack_charPtrPtr(data);
		    }
		    break;
		    case RESERVATION_BY_JOBSTEP:
		    case RESERVATION_BY_JCF:
#if LLVER >= 3040101
		    case RESERVATION_BY_HOSTFILE:
#endif

		    {
			char *value;
			value=SvPV_nolen(data);
		    	param.data=value;
			/*fprintf(stderr,"Reserving by JOBSTEP/JCF (%d)= %s\n",data_type,value);*/
		    }
		    break;
		}
		param.mode=options;
		param.users=users;
		param.groups=groups;
		param.group=group;
#if LLVER >= 3050000
		param.expiration=expiration;
		param.recurrence=LL_crontab_encode(recurrence);
#endif
		rc = ll_make_reservation(LL_API_VERSION,&errObj,&p_param);
		if ( rc == RESERVATION_OK )
		{
		    XPUSHs(sv_2mortal(newSVpv(*param.ID, 0)));
		    Safefree(param.ID);
#if LLVER >= 3050000
		    if (param.recurrence != NULL)
		    {
    		    	if (param.recurrence->minutes != NULL) Safefree(param.recurrence->minutes);
    		    	if (param.recurrence->hours != NULL)   Safefree(param.recurrence->hours);
    		    	if (param.recurrence->dom != NULL)     Safefree(param.recurrence->dom);
		    	if (param.recurrence->months != NULL)  Safefree(param.recurrence->months);
		    	if (param.recurrence->dow != NULL)     Safefree(param.recurrence->dow);
		    	Safefree(param.recurrence);
		     }	
#endif
		}
		else
		{
		    XPUSHs(sv_2mortal(&PL_sv_undef));
		    sv_setiv(get_sv("IBM::LoadLeveler::errObj",FALSE),(IV)errObj);	   
	
		}
	   }
	}


						
int
ll_remove_reservation(IDs,user_list,host_list,group_list,base_partition_list)
	char **IDs
	char **user_list
	char **host_list
	char **group_list
	char **base_partition_list

	CODE:
	{
	    LL_element    *errObj = NULL;

	    RETVAL=0;
#if LLVER < 3040000	
	    RETVAL=ll_remove_reservation(LL_API_VERSION,&errObj,IDs,user_list,host_list,group_list);
#else
	    RETVAL=ll_remove_reservation(LL_API_VERSION,&errObj,IDs,user_list,host_list,group_list,base_partition_list);
#endif
	    if ( RETVAL != RESERVATION_OK)
	    {
		    sv_setiv(get_sv("IBM::LoadLeveler::errObj",FALSE),(IV)errObj);	   
	    }
	}
        OUTPUT:
	    RETVAL

int
ll_change_reservation(ID,param)
	char  *ID
	HV    *param

	CODE:
	{
	    I32	                          count,len,i;
	    char                         *key;
	    SV                           *ptr;
	    SV                          **value;
	    LL_reservation_change_param  *data;
	    LL_reservation_change_param **p_data;
	    LL_element                   *errObj = NULL;

	    count=hv_iterinit(param);
	    /*  fprintf(stderr,"HV_ITERINIT icount = %i\n",count);*/
	    /* Make space to store all of the arguments */
	    data=calloc(count,sizeof(LL_reservation_change_param));
	    p_data=calloc(count+1,sizeof(LL_reservation_change_param *));


	    for(i=0;i!=count;i++)
	    {
                p_data[i] = &data[i];
		ptr=hv_iternextsv(param,&key,&len);
		if (strncmp(key,"RESERVATION_START_TIME",len) == 0)     { data[i].type=RESERVATION_START_TIME; };
		if (strncmp(key,"RESERVATION_ADD_START_TIME",len) == 0) { data[i].type=RESERVATION_ADD_START_TIME; };
		if (strncmp(key,"RESERVATION_DURATION",len) == 0)       { data[i].type=RESERVATION_DURATION; };
		if (strncmp(key,"RESERVATION_ADD_DURATION",len) == 0)   { data[i].type=RESERVATION_ADD_DURATION; };
		if (strncmp(key,"RESERVATION_BY_NODE",len) == 0)        { data[i].type=RESERVATION_BY_NODE; };
		if (strncmp(key,"RESERVATION_ADD_NUM_NODE",len) == 0)   { data[i].type=RESERVATION_ADD_NUM_NODE; };
		if (strncmp(key,"RESERVATION_BY_HOSTLIST",len) == 0)    { data[i].type=RESERVATION_BY_HOSTLIST; };
#if LLVER >= 3040000
		if (strncmp(key,"RESERVATION_BY_BG_CNODE",len) == 0)    { data[i].type=RESERVATION_BY_BG_CNODE; };
#endif
#if LLVER >= 3040101
		if (strncmp(key,"RESERVATION_BY_HOSTFILE",len) == 0)    { data[i].type=RESERVATION_BY_HOSTFILE; };
#endif
#if LLVER >= 3050000
		if (strncmp(key,"RESERVATION_BINDING_METHOD",len) == 0) { data[i].type=RESERVATION_BINDING_METHOD; };
		if (strncmp(key,"RESERVATION_EXPIRATION",len) == 0)     { data[i].type=RESERVATION_EXPIRATION; };
		if (strncmp(key,"RESERVATION_OCCURRENCE",len) == 0)     { data[i].type=RESERVATION_OCCURRENCE; };
		if (strncmp(key,"RESERVATION_RECURRENCE",len) == 0)     { data[i].type=RESERVATION_RECURRENCE; };
#endif
		if (strncmp(key,"RESERVATION_ADD_HOSTS",len) == 0)      { data[i].type=RESERVATION_ADD_HOSTS; };
		if (strncmp(key,"RESERVATION_DEL_HOSTS",len) == 0)      { data[i].type=RESERVATION_DEL_HOSTS; };
		if (strncmp(key,"RESERVATION_BY_JOBSTEP",len) == 0)     { data[i].type=RESERVATION_BY_JOBSTEP; };
		if (strncmp(key,"RESERVATION_BY_JCF",len) == 0)         { data[i].type=RESERVATION_BY_JCF; };
		if (strncmp(key,"RESERVATION_USERLIST",len) == 0)       { data[i].type=RESERVATION_USERLIST; };
		if (strncmp(key,"RESERVATION_ADD_USERS",len) == 0)      { data[i].type=RESERVATION_ADD_USERS; };
		if (strncmp(key,"RESERVATION_DEL_USERS",len) == 0)      { data[i].type=RESERVATION_DEL_USERS; };
		if (strncmp(key,"RESERVATION_GROUPLIST",len) == 0)      { data[i].type=RESERVATION_GROUPLIST; };
		if (strncmp(key,"RESERVATION_ADD_GROUPS",len) == 0)     { data[i].type=RESERVATION_ADD_GROUPS; };
		if (strncmp(key,"RESERVATION_DEL_GROUPS",len) == 0)     { data[i].type=RESERVATION_DEL_GROUPS; };
		if (strncmp(key,"RESERVATION_MODE_SHARED",len) == 0)    { data[i].type=RESERVATION_MODE_SHARED; };
		if (strncmp(key,"RESERVATION_OWNER",len) == 0)          { data[i].type=RESERVATION_OWNER; };
		if (strncmp(key,"RESERVATION_GROUP",len) == 0)          { data[i].type=RESERVATION_GROUP; };
		if (strncmp(key,"RESERVATION_MODE_REMOVE_ON_IDLE",len) == 0) { data[i].type=RESERVATION_MODE_REMOVE_ON_IDLE; };
/*		fprintf(stderr,"%d = HV_ITERNEXTSV %i,%s,%i\n",i,ptr,key,len); */
		value=hv_fetch(param,key,len,0);
		switch(data[i].type)
		{
		    case RESERVATION_START_TIME:
		    case RESERVATION_BY_JOBSTEP:
		    case RESERVATION_BY_JCF:
		    case RESERVATION_GROUP:
		    case RESERVATION_OWNER:
#if LLVER >= 3040101
		    case RESERVATION_BY_HOSTFILE:
#endif
		    {
			data[i].data=SvPV_nolen(*value);
			/*  fprintf(stderr,"%d (char *)= %s,%s\n",i,key,data[i].data); */
		    }
		    break;
 		    case RESERVATION_BY_HOSTLIST:
		    case RESERVATION_ADD_HOSTS:
		    case RESERVATION_DEL_HOSTS:
		    case RESERVATION_ADD_USERS:
		    case RESERVATION_DEL_USERS:
		    case RESERVATION_GROUPLIST:
		    case RESERVATION_ADD_GROUPS:
		    case RESERVATION_DEL_GROUPS:
#if LLVER >= 3040000
		    case RESERVATION_BY_BG_CNODE:
#endif

		    {		    
			data[i].data=XS_unpack_charPtrPtr(*value);
		    }
		    break;
#if LLVER >= 3050000
		    case RESERVATION_RECURRENCE:
		    {
			        
			    data[i].data=LL_crontab_encode(value);
		    }
		    break;
#endif
		    default :
		    {
			int val;
		    
			val=SvIV(*value);
#if LLVER == 3030000
			data[i].data=(void *)val;
#else
			data[i].data=&val;
#endif
			/*  fprintf(stderr,"%d (int*)= %s,%d\n",i,key,val); */
		    }
		}
		
	    }
	    p_data[count]=NULL;
	    RETVAL=ll_change_reservation(LL_API_VERSION,&errObj,&ID,p_data);
	    if ( RETVAL != RESERVATION_OK)
	    {
		    sv_setiv(get_sv("IBM::LoadLeveler::errObj",FALSE),(IV)errObj);	   
	    }
	}
        OUTPUT:
            RETVAL
			
#endif			


#if LLVER > 3050000	

int
ll_remove_reservation_xtnd(IDs,user_list,group_list,host_list,base_partition_list,begin,end)
	char    **IDs
	char	**user_list
	char	**group_list
	char	**host_list
	char	**base_partition_list
	char	 *begin
	char	 *end

	CODE:
	{
		LL_remove_reservation_param	param;
	    	LL_element             *errObj = NULL;

		param.IDs=IDs;
		param.user_list=user_list;
		param.group_list=group_list;
		param.host_list=host_list;
		param.base_partition_list=base_partition_list;
		param.begin=begin;
		param.end=end;

		RETVAL=ll_remove_reservation_xtnd(LL_API_VERSION,&errObj,&param);
	        if ( RETVAL != RESERVATION_OK)
	        {
		    sv_setiv(get_sv("IBM::LoadLeveler::errObj",FALSE),(IV)errObj);	   
	        }
	}
        OUTPUT:
            RETVAL

#endif
