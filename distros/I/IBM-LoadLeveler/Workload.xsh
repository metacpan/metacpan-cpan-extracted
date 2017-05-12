
#if LLVER < 3050000
						
int
ll_start_job(cluster,proc,from_host,node_list)
        int    cluster
	int    proc
	char  *from_host
	char **node_list

	CODE:
	{
	    LL_start_job_info	job_info;

	    job_info.version_num=LL_PROC_VERSION;
	    job_info.nodeList=node_list;
	    job_info.StepId.cluster=cluster;
	    job_info.StepId.proc=proc;
	    job_info.StepId.from_host=from_host;
	    RETVAL=ll_start_job(&job_info);
	}		
	OUTPUT:
		RETVAL
			
#endif			

int
ll_terminate_job(cluster,proc,from_host,msg)
        int    cluster
	int    proc
	char  *from_host
	char  *msg

	CODE:
	{
	    LL_terminate_job_info	job_info;

	    job_info.version_num=LL_PROC_VERSION;
	    job_info.msg=msg;
	    job_info.StepId.cluster=cluster;
	    job_info.StepId.proc=proc;
	    job_info.StepId.from_host=from_host;
	    RETVAL=ll_terminate_job(&job_info);
	}		
	OUTPUT:
		RETVAL

#if  ! defined(__linux__) || LLVER >=3030000
int
ll_preempt(job_step,type)
	char *job_step
        int    type


	CODE:
	{
	    LL_element *errObj = NULL;

	    RETVAL=ll_preempt(LL_API_VERSION,&errObj,job_step,type);
	    if (RETVAL != API_OK )
	    {
		sv_setiv(get_sv("IBM::LoadLeveler::errObj",FALSE),(IV)errObj);	   
	    }
	}
        OUTPUT:
	       RETVAL

#endif

#if LLVER >= 3030000

int
ll_run_scheduler(Obj)
   	 LL_element *Obj 

	CODE:
	{
	    RETVAL=ll_run_scheduler(LL_API_VERSION,&Obj);
	}
	OUTPUT:
		RETVAL
			
int
ll_preempt_jobs(param)
        SV   *param

	CODE:
	{
	    LL_element        *errObj = NULL;
	    LL_preempt_param  *data;
	    LL_preempt_param **p_data = NULL;
	    int                avlen,i,p,count;
	    I32                len;
	    HV		      *hash;
	    SV		      **value;
	    char               *key;
	    SV		       *ptr;
	    AV		       *array;
	           
	    /* 
	     * Input is an array of hashes. unpack them and use to
	     * build the reqiured array of structures.
	     */

	    /* Is it an array */
	    if ((!SvROK(param)) || (SvTYPE(SvRV(param)) != SVt_PVAV ))
	    {
	        RETVAL=-5;
	    }
	    else
	    {
	        array=(AV *)SvRV(param);

		/* is it empty? */	    
		avlen = av_len(array);
		/* printf("AV Length = %d\n",avlen); */
		if( avlen < 0 )
		{
		    RETVAL=-5;
		}
		else
		{
		    /* Not empty, so alloc some space */
		  data=calloc(avlen+1,sizeof(LL_preempt_param));
		  p_data=calloc(avlen+1,sizeof(LL_preempt_param *));
		  for( i = 0; i <= avlen; i++ )
		  {
		      /* printf("AV Element = %d\n",i); */
		      /* walk the array, getting each hash */
		      p_data[i] = &data[i];
		    
		      hash =  (HV *)(SvRV(*av_fetch( array, i, 0 )));
		      count=hv_iterinit(hash);
		      /* printf("HASH Size = %d\n",count); */
		      p_data[i]->user_list=NULL;
		      p_data[i]->host_list=NULL;
		      p_data[i]->job_list=NULL;	
		      for(p=0;p!=count;p++)
		      {
			  /* Walk the hash, stufing values in to slots */
		          ptr=hv_iternextsv(hash,&key,&len);
			  value=hv_fetch(hash,key,len,0);
			  /* fprintf(stderr, "HASH KEY %d = %s\n",p,key); */
			  if (strncmp(key,"type",len) == 0)      { p_data[i]->type=SvIV(*value); };
			  if (strncmp(key,"method",len) == 0)    { p_data[i]->method=SvIV(*value); };
			  if (strncmp(key,"user_list",len) == 0) { p_data[i]->user_list=XS_unpack_charPtrPtr(*value);};
			  if (strncmp(key,"host_list",len) == 0) { p_data[i]->host_list=XS_unpack_charPtrPtr(*value); };
			  if (strncmp(key,"job_list",len) == 0)  { p_data[i]->job_list=XS_unpack_charPtrPtr(*value); };
		      }
		  }
		}
		/* Now make the call */
		RETVAL=ll_preempt_jobs(LL_API_VERSION,&errObj,p_data);
		if (RETVAL != API_OK) 
		{
	            sv_setiv(get_sv("IBM::LoadLeveler::errObj",FALSE),(IV)errObj);
		}
	    }
	}
        OUTPUT:
	    RETVAL

#endif

int
ll_start_job_ext(info)
        HV   *info

	CODE:
	{
	    LL_start_job_info_ext	job;
	    int count,i;
	    I32 len;
	    SV *ptr;
	    SV **value;
	    char *key;
	    
	    
	    /* Iterate over all hash elements */
	    count=hv_iterinit(info);
	    for(i=0;i!=count;i++)
	    {
 		ptr=hv_iternextsv(info,&key,&len);
		value=hv_fetch(info,key,len,0);
		if (strncmp(key,"StepId.cluster",len) == 0) { job.StepId.cluster =SvIV(*value); };
		if (strncmp(key,"StepId.proc",len) == 0) { job.StepId.proc =SvIV(*value); };
		if (strncmp(key,"StepId.from_host",len) == 0) { job.StepId.from_host=SvPV_nolen(*value); };
		if (strncmp(key,"adapterUsageCount",len) == 0) { job.adapterUsageCount = SvIV(*value); };
		if (strncmp(key,"adapterUsage",len) == 0) 
		{
		    int i,avlen,p;
		    AV *array;
		    LL_ADAPTER_USAGE *data;
		    LL_ADAPTER_USAGE **p_data = NULL;
		    HV		      *hash;


		    /* LL_ADAPTER_USAGE is an array of structures */
		    array=(AV *)SvRV(*value);
		    avlen = av_len(array);
		    data=calloc(avlen+1,sizeof(LL_ADAPTER_USAGE));
		    for( i = 0; i <= avlen; i++ )
		    {
			/* printf("AV Element = %d\n",i); */
			/* walk the array, getting each hash */
			
			hash =  (HV *)(SvRV(*av_fetch( array, i, 0 )));
			count=hv_iterinit(hash);
			/* printf("HASH Size = %d\n",count); */
			for(p=0;p!=count;p++)
			{
			    /* Walk the hash, stufing values in to slots */
			    ptr=hv_iternextsv(hash,&key,&len);
			    value=hv_fetch(hash,key,len,0);
			    /* fprintf(stderr, "HASH KEY %d = %s\n",p,key); */
			    if (strncmp(key,"dev_name",len) == 0)  { data[i].dev_name=SvPV_nolen(*value); };
			    if (strncmp(key,"protocol",len) == 0)  { data[i].protocol=SvPV_nolen(*value); };
			    if (strncmp(key,"subsystem",len) == 0) { data[i].subsystem=SvPV_nolen(*value); };
			    if (strncmp(key,"wid",len) == 0)       { data[i].wid=SvIV(*value); };
			    if (strncmp(key,"mem",len) == 0)       { data[i].mem=SvIV(*value); };
			    if (strncmp(key,"api_rcxtblocks",len) == 0)  { p_data[i]->api_rcxtblocks=SvIV(*value);};
			}
		    }
		    job.adapterUsage = data;
		}
	    }

	    RETVAL=ll_start_job_ext(&job);	    
	}
	OUTPUT:
		RETVAL

int
ll_cluster(action,cluster_list)
	int action
	char **cluster_list

	CODE:
	{
	    LL_element        *errObj = NULL;
	    LL_cluster_param   param;


	    param.action=action;
            param.cluster_list=cluster_list;

	    RETVAL=ll_cluster(LL_API_VERSION,&errObj,&param);

            if (RETVAL != CLUSTER_SUCCESS )
            {
	      sv_setiv(get_sv("IBM::LoadLeveler::errObj",FALSE),(IV)errObj);
	    }
	}
	OUTPUT:
		RETVAL

int
ll_cluster_auth()

	CODE:
	{
	    	LL_element        *errObj = NULL;
	 	LL_cluster_auth_param auth_param;
 		LL_cluster_auth_param *param_list[2];

		/* Set type to generate keys */
		auth_param.type = CLUSTER_AUTH_GENKEY;
		
		param_list[0] = &auth_param;
		param_list[1] = NULL;

		RETVAL = ll_cluster_auth(LL_API_VERSION, &errObj, param_list);

		if (RETVAL != API_OK) 
		{
		  sv_setiv(get_sv("IBM::LoadLeveler::errObj",FALSE),(IV)errObj);
		}
	}
	OUTPUT:
		RETVAL

#if LLVER >= 3040000

int
ll_move_job(cluster_name,job_id)
     char *cluster_name
     char *job_id

     CODE:
     {    
	    LL_element        *errObj = NULL;
	    LL_move_job_param param;
	    LL_move_job_param *param_list[2];

            param.cluster_name=cluster_name; 
            param.job_id=job_id; 
	    
	    param_list[0]=&param;
	    param_list[1]=NULL;

	    RETVAL=ll_move_job(LL_API_VERSION,&errObj,param_list);
	    if (RETVAL != API_OK) 
	    {
		sv_setiv(get_sv("IBM::LoadLeveler::errObj",FALSE),(IV)errObj);
	    }
     }
     OUTPUT:
         RETVAL

int
ll_move_spool(host,directory)
     char *host
     char *directory

     CODE:
     {    
	    LL_element          *errObj = NULL;
	    LL_move_spool_param  param;
	    LL_move_spool_param *param_list[2];
	    int (*func)(char *, int, LL_element **) = _ll_print_job_status;

	    param.data = LL_MOVE_SPOOL_JOBS;
            param.spool_directory=directory; 
	    /* schedd_host is a list !!! */
	    param.schedd_host = ( char **)calloc(2,sizeof(char *));
	    param.schedd_host[0] = host;
	    param.schedd_host[1] = NULL;
            
	    
	    param_list[0]=&param;
	    param_list[1]=NULL;

	    RETVAL=ll_move_spool(LL_API_VERSION,param_list,func,&errObj);
	    free(param.schedd_host);

	    if (RETVAL != API_OK) 
	    {
		sv_setiv(get_sv("IBM::LoadLeveler::errObj",FALSE),(IV)errObj);
	    }
     }
     OUTPUT:
         RETVAL

#endif

	
int
ll_control(control_op,host_list,user_list,job_list, class_list,priority)
	int    control_op
	char **host_list
	char **user_list 
	char **job_list
	char **class_list
	int    priority

	CODE:
	{
	    RETVAL=ll_control(LL_CONTROL_VERSION,control_op,host_list,user_list,job_list, class_list,priority);
	}
	OUTPUT:

		RETVAL

int
ll_modify(modify_op,value_ref,job_id)
	int   modify_op
	SV   *value_ref
	char *job_id

	CODE:
	{
	    LL_element		*errObj = NULL;
	    LL_modify_param	mycmd, *cmdp[2];
	    char *job_list[2];

            job_list[0] = job_id;
	    job_list[1] = NULL;

            mycmd.type=modify_op;
	    switch (modify_op)
            {
#if LLVER >= 3030000
	        case STEP_PREEMPTABLE:
		case SYSPRIO:
#endif
#if LLVER >= 3030100
		case BG_SIZE:
		case BG_CONNECTION:
		case BG_ROTATE:		
#endif
#if LLVER < 3040000
                case EXECUTION_FACTOR:
#endif
                case CONSUMABLE_CPUS:
#if LLVER >= 3020000
                case WCLIMIT_ADD_MIN:
#endif
#if LLVER >= 3050000
		case BG_PARTITION_TYPE:	
#endif			
                {
		   int value;
		   
		   value=SvIV(SvRV(value_ref));
                   mycmd.data=&value;
                }
                break;

                case CONSUMABLE_MEMORY:
                {
                   int64_t value;

		   value=SvIV(SvRV(value_ref));
                   mycmd.data=&value;
                }
                break;
#if LLVER >= 3030100
		case BG_SHAPE:
		case BG_PARTITION:
#endif
#if LLVER >= 3040000
		case BG_REQUIREMENTS:
		case RESOURCES:
		case NODE_RESOURCES:
#endif
#if LLVER >= 3020000
                case JOB_CLASS:
                case ACCOUNT_NO:
#if LLVER >= 3050000
		case CLUSTER_OPTION:		
		case DSTG_RESOURCES:
		case BG_USER_LIST:
#endif
                {
		    STRLEN l;

		    mycmd.data=SvPV(SvRV(value_ref),l);
                }
                break;
#endif

            }
            cmdp[0]=&mycmd;
	    cmdp[1]=NULL;

	    RETVAL=ll_modify(LL_API_VERSION,&errObj,cmdp,job_list);

	    if (RETVAL != MODIFY_SUCCESS )
	    {
	        sv_setiv(get_sv("IBM::LoadLeveler::errObj",FALSE),(IV)errObj);	   
	    }
	}
        OUTPUT:
	      RETVAL
	      
	      
