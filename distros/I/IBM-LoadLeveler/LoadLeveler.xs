
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <llapi.h>
#include <errno.h>

#include "defs.h"

#if LLVER >= 3050000

/*
 * Decode an array of integers or possibly a single value into an integer array
 */
 	
int *
int_array(in)
	SV	*in;
	
{
	int 	i,avlen;
	int	    *out;	
	AV	    *av;
	
	/* If not defined return NULL */
	if ( ! SvOK( in ) )
		return( (int*)NULL );

	/* Expect it to be an AV (array) or a single value. */
	if (SvIOK(in) || SvPOK(in))
	{
		if (SvPOK(in))
		{
			/* If the input was a string assume it was a "*" and return NULL */
			return( (int *)NULL);	
		}
		else
		{
			/* Else it was a single value */
			out=calloc(2,sizeof(int));
			out[0]=SvIV(in);
			out[1]=-1;
		}	
	}
	else
	{
		av = (AV*)SvRV(in);
		
		avlen = av_len(av);
		/*fprintf(stderr,"int_array length = %d\n",avlen);*/
		out=(int *)calloc(avlen+2,sizeof(int));
		for( i = 0; i <= avlen; i++ )
		{
			/* walk the array, getting each value */
				
			out[i] =  (int)SvIV(*av_fetch( av, i, 0 ));
			/*fprintf(stderr,"int_array Element = %d === %d\n",i,out[i]);*/
		}
		out[avlen+1]=-1;
		/*fprintf(stderr,"int_array Element = %d === %d\n",avlen+1,out[avlen+1]);*/
	}
	return(out);
}

LL_crontab_time *
LL_crontab_encode(in)
	SV		*in;
{
	I32	count,i,len;
    char   *key;
	SV     *ptr;
	SV    **value;
	LL_crontab_time	*out=NULL;
	
	/*fprintf(stderr,"entering LL_crontab_encode\n");*/
	/* return if not a hash */ 
/*	if ( ! SvOK(in) || SvTYPE(SvRV(in)) != SVt_PVHV )
		fprintf(stderr,"NOT a hash returning NULL\n");*/
	if ( ! SvOK(in) || SvTYPE(SvRV(in)) != SVt_PVHV )
		return((LL_crontab_time *)NULL);    
	out=malloc(sizeof(LL_crontab_time));
	count=hv_iterinit((HV *)SvRV(in));
/*	fprintf(stderr,"LL_crontab_encode hash size = %i\n",count);*/
	for(i=0;i!=count;i++)
	{
		/* Walk the hash, stufing values in to slots */
		ptr=hv_iternextsv((HV *)SvRV(in),&key,&len);
		value=hv_fetch((HV *)SvRV(in),key,len,0);
/*		fprintf(stderr, "HASH KEY %d = %s\n",i,key);*/
	    	if (strncmp(key,"minutes",len) == 0) { out->minutes = int_array(*value); };
		if (strncmp(key,"hours",len) == 0)   { out->hours   = int_array(*value); };
		if (strncmp(key,"dom",len) == 0)     { out->dom     = int_array(*value); };
		if (strncmp(key,"months",len) == 0)  { out->months  = int_array(*value); };
	   	if (strncmp(key,"dow",len) == 0)     { out->dow     = int_array(*value); };
	}
	return(out);
}		

AV *
array_int(in)
	int	*in;
{
	AV *array;
	int	i;
		
	array=(AV *)sv_2mortal((SV *)newAV());
	for(i=0;in[i]!=-1;i++)
	{
		/*fprintf(stderr,"in[%d] = %d\n",i,in[i]);*/
		av_push(array,newSViv(in[i]));
	}
	return(array);
}	
				
HV *
unpack_ll_crontab_time(time)
    LL_crontab_time	*time;
{
	HV *hash;
	
	hash=(HV *)sv_2mortal((SV *)newHV());

	if ( time->minutes != NULL )
	{
		AV *array;
		
		array=array_int(time->minutes);
		(void)hv_store(hash,"minutes",strlen("minutes"),(newRV((SV*)array)),0);	
	}
	else
		(void)hv_store(hash,"minutes",strlen("minutes"),newSV(0),0);
	if ( time->hours != NULL )
	{
		AV *array;
		
		array=array_int(time->hours);
		(void)hv_store(hash,"hours",strlen("hours"),(newRV((SV*)array)),0);	
	}
	else
		(void)hv_store(hash,"hours",strlen("hours"),newSV(0),0);
	if ( time->dom != NULL )
	{
		AV *array;
		
		array=array_int(time->dom);
		(void)hv_store(hash,"dom",strlen("dom"),(newRV((SV*)array)),0);	
	}
	else
		(void)hv_store(hash,"dom",strlen("dom"),newSV(0),0);
	if ( time->months != NULL )
	{
		AV *array;
		
		array=array_int(time->months);
		(void)hv_store(hash,"months",strlen("months"),(newRV((SV*)array)),0);	
	}
	else
		(void)hv_store(hash,"months",strlen("months"),newSV(0),0);
	if ( time->dow != NULL )
	{
		AV *array;
		
		array=array_int(time->dow);
		(void)hv_store(hash,"dow",strlen("dow"),(newRV((SV*)array)),0);	
	}
	else
		(void)hv_store(hash,"dow",strlen("dow"),newSV(0),0);		
	
	return(hash);	
}

#endif


AV * 
unpack_ll_step_id(id)
    LL_STEP_ID *id;
{
    AV *array;

    array=(AV *)sv_2mortal((SV *)newAV());
    av_push(array,newSViv((long)id->cluster));
    av_push(array,newSViv((long)id->proc));
    av_push(array,newSVpv(id->from_host,0));
    return(array);
}

HV *
unpack_ll_adapter_usage(adapter_usage)
    LL_ADAPTER_USAGE *adapter_usage;
{
    HV *hash;
    hash=(HV *)sv_2mortal((SV *)newHV());

    (void)hv_store(hash,"dev_name",strlen("dev_name"),(newSVpv(adapter_usage->dev_name,0)),0);
    (void)hv_store(hash,"protocol",strlen("protocol"),(newSVpv(adapter_usage->protocol,0)),0);
    (void)hv_store(hash,"subsystem",strlen("subsystem"),(newSVpv(adapter_usage->subsystem,0)),0);
    (void)hv_store(hash,"wid",strlen("wid"),(newSViv((long)adapter_usage->wid)),0);
    (void)hv_store(hash,"mem",strlen("mem"),(newSViv(adapter_usage->mem)),0);

    return(hash);
}

/*
 * Convert an rusage struct into a hash
 *
 */

HV *
unpack_rusage(usage)
    struct rusage *usage;
{
    HV *hash;
    AV *timet;

    hash=(HV *)sv_2mortal((SV *)newHV());

    timet=(AV *)sv_2mortal((SV *)newAV());
    av_push(timet,newSViv((long)usage->ru_utime.tv_sec));
    av_push(timet,newSViv((long)usage->ru_utime.tv_usec));
    (void)hv_store(hash,"ru_utime",strlen("ru_utime"),(newRV((SV*)timet)),0);

    timet=(AV *)sv_2mortal((SV *)newAV());
    av_push(timet,newSViv((long)usage->ru_stime.tv_sec));
    av_push(timet,newSViv((long)usage->ru_stime.tv_usec));
    (void)hv_store(hash,"ru_stime",strlen("ru_stime"),(newRV((SV*)timet)),0);

    (void)hv_store(hash,"ru_maxrss",strlen("ru_maxrss"),(newSViv((long)usage->ru_maxrss)),0);
    (void)hv_store(hash,"ru_ixrss",strlen("ru_ixrss"),(newSViv((long)usage->ru_ixrss)),0);
    (void)hv_store(hash,"ru_idrss",strlen("ru_idrss"),(newSViv((long)usage->ru_idrss)),0);
    (void)hv_store(hash,"ru_isrss",strlen("ru_isrss"),(newSViv((long)usage->ru_isrss)),0);
    (void)hv_store(hash,"ru_majflt",strlen("ru_majflt"),(newSViv((long)usage->ru_majflt)),0);
    (void)hv_store(hash,"ru_nswap",strlen("ru_nswap"),(newSViv((long)usage->ru_nswap)),0);
    (void)hv_store(hash,"ru_inblock",strlen("ru_inblock"),(newSViv((long)usage->ru_inblock)),0);
    (void)hv_store(hash,"ru_oublock",strlen("ru_oublock"),(newSViv((long)usage->ru_oublock)),0);
    (void)hv_store(hash,"ru_msgsnd",strlen("ru_msgsnd"),(newSViv((long)usage->ru_msgsnd)),0);
    (void)hv_store(hash,"ru_msgrcv",strlen("ru_msgrcv"),(newSViv((long)usage->ru_msgrcv)),0);
    (void)hv_store(hash,"ru_nsignals",strlen("ru_nsignals"),(newSViv((long)usage->ru_nsignals)),0);
    (void)hv_store(hash,"ru_nvcsw",strlen("ru_nvcsw"),(newSViv((long)usage->ru_nvcsw)),0);
    (void)hv_store(hash,"ru_nivcsw",strlen("ru_nvicsw"),(newSViv((long)usage->ru_nivcsw)),0);

    return(hash);
}

HV *
unpack_event_usage(event)
    LL_EVENT_USAGE *event;
{
    HV *hash;
    hash=(HV *)sv_2mortal((SV *)newHV());

    (void)hv_store(hash,"event",strlen("event"),(newSViv((long)event->event)),0);
    (void)hv_store(hash,"name",strlen("name"),(newSVpv(event->name,0)),0);
    (void)hv_store(hash,"time",strlen("time"),(newSViv((long)event->time)),0);
    (void)hv_store(hash,"starter_rusage",strlen("starter_rusage"),(newRV((SV *)unpack_rusage(&event->starter_rusage))),0);
    (void)hv_store(hash,"step_rusage",strlen("step_rusage"),(newRV((SV *)unpack_rusage(&event->step_rusage))),0);
    return(hash);
}


HV *
unpack_dispatch_usage(dispatch)
    LL_DISPATCH_USAGE *dispatch;
{
    HV *hash;
    AV *array;
    int i;
    LL_EVENT_USAGE	*ptr;

    hash=(HV *)sv_2mortal((SV *)newHV());

    (void)hv_store(hash,"dispatch_num",strlen("dispatch_num"),(newSViv((long)dispatch->dispatch_num)),0);
    (void)hv_store(hash,"starter_rusage",strlen("starter_rusage"),(newRV((SV *)unpack_rusage(&dispatch->starter_rusage))),0);
    (void)hv_store(hash,"step_rusage",strlen("step_rusage"),(newRV((SV *)unpack_rusage(&dispatch->step_rusage))),0);
    array=(AV *)sv_2mortal((SV *)newAV());
    i=0;
    ptr=dispatch->event_usage;
    while (ptr != NULL)
    {     
	av_push( array,newRV((SV *)unpack_event_usage(ptr)));
	ptr=ptr->next;
    }
    (void)hv_store(hash,"event_usage",strlen("event_usage"),newRV((SV *)array),0);

    return(hash);

}

HV *
unpack_mach_usage(mach)
    LL_MACH_USAGE *mach;
{
    HV *hash;
    AV *array;
    int i;
    LL_DISPATCH_USAGE	*ptr;

    hash=(HV *)sv_2mortal((SV *)newHV());

    (void)hv_store(hash,"name",strlen("name"),(newSVpv(mach->name,0)),0);
    (void)hv_store(hash,"machine_speed",strlen("machine_speed"),(newSVnv((long)mach->machine_speed)),0);
    (void)hv_store(hash,"dispatch_num",strlen("dispatch_num"),(newSViv((long)mach->dispatch_num)),0);
    array=(AV *)sv_2mortal((SV *)newAV());
    i=0;
    ptr=mach->dispatch_usage;
    while (ptr != NULL)
    {     
	av_push( array,newRV((SV *)unpack_dispatch_usage(ptr)));
	ptr=ptr->next;
    }
    (void)hv_store(hash,"dispatch_usage",strlen("dispatch_usage"),newRV((SV *)array),0);
    return(hash);

}

HV *
unpack_ll_usage(usage)
    LL_USAGE *usage;
{
    HV *hash;
    AV *array;
    LL_MACH_USAGE	*ptr;

    hash=(HV *)sv_2mortal((SV *)newHV());

    (void)hv_store(hash,"starter_rusage",strlen("starter_rusage"),(newRV((SV *)unpack_rusage(&usage->starter_rusage))),0);
    (void)hv_store(hash,"step_rusage",strlen("step_rusage"),(newRV((SV *)unpack_rusage(&usage->step_rusage))),0);
    array=(AV *)sv_2mortal((SV *)newAV());
    ptr=usage->mach_usage;
    while (ptr != NULL)
    {     
	av_push( array,newRV((SV *)unpack_mach_usage(ptr)));
	ptr=ptr->next;
    }
    (void)hv_store(hash,"mach_usage",strlen("mach_usage"),newRV((SV *)array),0);

    return(hash);

}

/*
 * Convert an LL_job_step structure into a perl hash.
 */

HV *
unpack_job_step( job_info )
LL_job_step	*job_info;

{
    HV *step;
    AV *nqs_info,*limits,*processor_list,*limits64;
    int t;

    step=(HV *)sv_2mortal((SV *)newHV());
    (void)hv_store(step,"step_name",strlen("step_name"),(newSVpv(job_info->step_name,0)),0);
    (void)hv_store(step,"requirements",strlen("requirements"),(newSVpv(job_info->requirements,0)),0);
    (void)hv_store(step,"preferences",strlen("preferences"),(newSVpv(job_info->preferences,0)),0);
    (void)hv_store(step,"prio",strlen("prio"),(newSViv((long)job_info->prio)),0);
    (void)hv_store(step,"dependency",strlen("dependency"),(newSVpv(job_info->dependency,0)),0);
    (void)hv_store(step,"group_name",strlen("group_name"),(newSVpv(job_info->group_name,0)),0);
    (void)hv_store(step,"stepclass",strlen("stepclass"),(newSVpv(job_info->stepclass,0)),0);
    (void)hv_store(step,"start_date",strlen("start_date"),(newSViv((long)job_info->start_date)),0);
    (void)hv_store(step,"flags",strlen("flags"),(newSViv((long)job_info->flags)),0);
    (void)hv_store(step,"min_processors",strlen("min_processors"),(newSViv((long)job_info->min_processors)),0);
    (void)hv_store(step,"max_processors",strlen("max_processors"),(newSViv((long)job_info->max_processors)),0);
    (void)hv_store(step,"account_no",strlen("account_no"),(newSVpv(job_info->account_no,0)),0);
    (void)hv_store(step,"comment",strlen("comment"),(newSVpv(job_info->comment,0)),0);
    
    (void)hv_store(step,"id",strlen("id"),newRV((SV *)unpack_ll_step_id(&job_info->id)),0);
    
    (void)hv_store(step,"q_date",strlen("q_date"),(newSViv((long)job_info->q_date)),0);
    (void)hv_store(step,"status",strlen("status"),(newSViv((long)job_info->status)),0);
    (void)hv_store(step,"num_processors",strlen("num_processors"),(newSViv((long)job_info->num_processors)),0);
    processor_list=(AV *)sv_2mortal((SV *)newAV());
    for(t=0;t!=job_info->num_processors;t++)
	{     
	    av_push( processor_list, newSVpv( job_info->processor_list[t], 0 ) );
	}
    (void)hv_store(step,"processor_list",strlen("processor_list"),newRV((SV *)processor_list),0);
    
    (void)hv_store(step,"cmd",strlen("cmd"),(newSVpv(job_info->cmd,0)),0);
    (void)hv_store(step,"args",strlen("args"),(newSVpv(job_info->args,0)),0);
    (void)hv_store(step,"env",strlen("env"),(newSVpv(job_info->env,0)),0);
    (void)hv_store(step,"in",strlen("in"),(newSVpv(job_info->in,0)),0);
    (void)hv_store(step,"out",strlen("out"),(newSVpv(job_info->out,0)),0);
    (void)hv_store(step,"err",strlen("err"),(newSVpv(job_info->err,0)),0);
    (void)hv_store(step,"iwd",strlen("iwd"),(newSVpv(job_info->iwd,0)),0);
    (void)hv_store(step,"notify_user",strlen("notify_user"),(newSVpv(job_info->notify_user,0)),0);
    (void)hv_store(step,"shell",strlen("shell"),(newSVpv(job_info->shell,0)),0);
    (void)hv_store(step,"tracker",strlen("tracker"),(newSVpv(job_info->tracker,0)),0);
    (void)hv_store(step,"tracker_arg",strlen("tracker_arg"),(newSVpv(job_info->tracker_arg,0)),0);
    (void)hv_store(step,"notification",strlen("notification"),(newSViv((long)job_info->notification)),0);
    (void)hv_store(step,"image_size",strlen("image_size"),(newSViv((long)job_info->image_size)),0);
    (void)hv_store(step,"exec_size",strlen("exec_size"),(newSViv((long)job_info->exec_size)),0);
    limits=(AV *)sv_2mortal((SV *)newAV());
    av_push(limits,newSViv((long)job_info->limits.cpu_hard_limit));
    av_push(limits,newSViv((long)job_info->limits.cpu_soft_limit));
    av_push(limits,newSViv((long)job_info->limits.data_hard_limit));
    av_push(limits,newSViv((long)job_info->limits.data_soft_limit));
    av_push(limits,newSViv((long)job_info->limits.core_hard_limit));
    av_push(limits,newSViv((long)job_info->limits.core_soft_limit));
    av_push(limits,newSViv((long)job_info->limits.file_hard_limit));
    av_push(limits,newSViv((long)job_info->limits.file_soft_limit));
    av_push(limits,newSViv((long)job_info->limits.rss_hard_limit));
    av_push(limits,newSViv((long)job_info->limits.rss_soft_limit));
    av_push(limits,newSViv((long)job_info->limits.stack_hard_limit));
    av_push(limits,newSViv((long)job_info->limits.stack_soft_limit));
    av_push(limits,newSViv((long)job_info->limits.hard_cpu_step_limit));
    av_push(limits,newSViv((long)job_info->limits.soft_cpu_step_limit));
    av_push(limits,newSViv((long)job_info->limits.hard_wall_clock_limit));
    av_push(limits,newSViv((long)job_info->limits.soft_wall_clock_limit));
    av_push(limits,newSViv((long)job_info->limits.ckpt_time_hard_limit));
    av_push(limits,newSViv((long)job_info->limits.ckpt_time_soft_limit));
    (void)hv_store(step,"limits",strlen("limits"),newRV((SV *)limits),0);

    /* strlen on linux causes a segfault on undefined values, which the following 
     * typically are. newSVpvn differs from newSVpv in that it can take a NULL value
     */ 
    nqs_info=(AV *)sv_2mortal((SV *)newAV());
    av_push(nqs_info,newSViv((long)job_info->nqs_info.nqs_flags));
    if (job_info->nqs_info.nqs_submit == NULL)
    {
      av_push(nqs_info,newSVpvn(NULL,0));
    }
    else
    {
      av_push(nqs_info,newSVpv(job_info->nqs_info.nqs_submit,0));
    }

    if (job_info->nqs_info.nqs_query == NULL)
    {
        av_push(nqs_info,newSVpvn(NULL,0));
    }
    else
    {
      av_push(nqs_info,newSVpv(job_info->nqs_info.nqs_query,0));
    }
    if (job_info->nqs_info.umask == NULL)
    {
      av_push(nqs_info,newSVpvn(NULL,0));
    }
    else
    {
      av_push(nqs_info,newSVpv(job_info->nqs_info.umask,0));
    }
    (void)hv_store(step,"nqs_info",strlen("nqs_info"),newRV((SV *)nqs_info),0);
    
    (void)hv_store(step,"dispatch_time",strlen("dispatch_time"),(newSViv((long)job_info->dispatch_time)),0);

    (void)hv_store(step,"start_time",strlen("start_time"),(newSViv((long)job_info->start_time)),0);
    (void)hv_store(step,"completion_code",strlen("completion_code"),(newSViv((long)job_info->completion_code)),0);
    (void)hv_store(step,"completion_date",strlen("completion_date"),(newSViv((long)job_info->completion_date)),0);
    (void)hv_store(step,"start_count",strlen("start_count"),(newSViv((long)job_info->start_count)),0);
    (void)hv_store(step,"usage_info",strlen("usage_info"),(newRV((SV *)unpack_ll_usage(&job_info->usage_info))),0);
    (void)hv_store(step,"user_sysprio",strlen("user_sysprio"),(newSViv((long)job_info->user_sysprio)),0);
    (void)hv_store(step,"group_sysprio",strlen("group_sysprio"),(newSViv((long)job_info->group_sysprio)),0);
    (void)hv_store(step,"class_sysprio",strlen("class_sysprio"),(newSViv((long)job_info->class_sysprio)),0);
    (void)hv_store(step,"number",strlen("number"),(newSViv((long)job_info->number)),0);
    (void)hv_store(step,"cpus_requested",strlen("cpus_requested"),(newSViv((long)job_info->cpus_requested)),0);
    (void)hv_store(step,"virtual_memory_requested",strlen("virtual_memory_requested"),(newSViv((long)job_info->virtual_memory_requested)),0);
    (void)hv_store(step,"memory_requested",strlen("memory_requested"),(newSViv((long)job_info->memory_requested)),0);
    (void)hv_store(step,"adapter_used_memory",strlen("adapter_used_memory"),(newSViv((long)job_info->adapter_used_memory)),0);
    (void)hv_store(step,"adapter_req_count",strlen("adapter_req_count"),(newSViv((long)job_info->adapter_req_count)),0);
/*  void  **adapter_req;  adapter requirements - step->getFirstAdapterReq() ...  */
 
    (void)hv_store(step,"image_size64",strlen("image_size64"),(newSViv(job_info->image_size64)),0);
    (void)hv_store(step,"exec_size64",strlen("exec_size64"),(newSViv(job_info->exec_size64)),0);
    (void)hv_store(step,"virtual_memory_requested64",strlen("virtual_memory_requested64"),(newSViv(job_info->virtual_memory_requested64)),0);
    (void)hv_store(step,"memory_requested64",strlen("memory_requested64"),(newSViv(job_info->memory_requested64)),0);
    limits64=(AV *)sv_2mortal((SV *)newAV());
    av_push(limits64,newSViv(job_info->limits64.cpu_hard_limit));
    av_push(limits64,newSViv(job_info->limits64.cpu_soft_limit));
    av_push(limits64,newSViv(job_info->limits64.data_hard_limit));
    av_push(limits64,newSViv(job_info->limits64.data_soft_limit));
    av_push(limits64,newSViv(job_info->limits64.core_hard_limit));
    av_push(limits64,newSViv(job_info->limits64.core_soft_limit));
    av_push(limits64,newSViv(job_info->limits64.file_hard_limit));
    av_push(limits64,newSViv(job_info->limits64.file_soft_limit));
    av_push(limits64,newSViv(job_info->limits64.rss_hard_limit));
    av_push(limits64,newSViv(job_info->limits64.rss_soft_limit));
    av_push(limits64,newSViv(job_info->limits64.stack_hard_limit));
    av_push(limits64,newSViv(job_info->limits64.stack_soft_limit));
    av_push(limits64,newSViv(job_info->limits64.hard_cpu_step_limit));
    av_push(limits64,newSViv(job_info->limits64.soft_cpu_step_limit));
    av_push(limits64,newSViv(job_info->limits64.hard_wall_clock_limit));
    av_push(limits64,newSViv(job_info->limits64.soft_wall_clock_limit));
    av_push(limits64,newSViv(job_info->limits64.ckpt_time_hard_limit));
    av_push(limits64,newSViv(job_info->limits64.ckpt_time_soft_limit));
    (void)hv_store(step,"limits64",strlen("limits64"),newRV((SV *)limits64),0);
    
    (void)hv_store(step,"good_ckpt_start_time",strlen("good_ckpt_start_time"),(newSViv((long)job_info->good_ckpt_start_time)),0);
    (void)hv_store(step,"accum_ckpt_time",strlen("accum_ckpt_time"),(newSViv((long)job_info->accum_ckpt_time)),0);
    (void)hv_store(step,"ckpt_dir",strlen("ckpt_dir"),(newSVpv(job_info->ckpt_dir,0)),0);
    (void)hv_store(step,"ckpt_file",strlen("ckpt_file"),(newSVpv(job_info->ckpt_file,0)),0);
    (void)hv_store(step,"large_page",strlen("large_page"),(newSVpv(job_info->large_page,0)),0);
    return(step);
}


AV *
unpack_ll_job(job)
LL_job    *job;
{
    AV *array,*steps;
    int i;

    array=(AV *)sv_2mortal((SV *)newAV());


    av_push(array,newSVpv(job->job_name, 0));
    av_push(array,newSVpv(job->owner, 0));
    av_push(array,newSVpv(job->groupname, 0));
    av_push(array,newSViv((long)job->uid));
    av_push(array,newSViv((long)job->gid));
    av_push(array,newSVpv(job->submit_host, 0));
    av_push(array,newSViv((long)job->steps));
    steps=(AV *)sv_2mortal((SV *)newAV());
    for(i=0;i!=job->steps;i++)
	{
	    HV *step;
	    
	    step=unpack_job_step(job->step_list[i]);
	    av_push(steps,newRV((SV *)step));
	}	
    av_push(array,newRV((SV *)steps));
    return(array);
}


AV *
unpack_ll_node(node)
LL_node    *node;
{
    AV *array,*list;
    int i;
    char *ptr;
    LL_STEP_ID *idptr;

    array=(AV *)sv_2mortal((SV *)newAV());

    av_push(array,newSVpv(node->nodename, 0));
    av_push(array,newSViv((long)node->version_num));
    av_push(array,newSViv((long)node->configtimestamp));
    av_push(array,newSViv((long)node->time_stamp));
    av_push(array,newSViv((long)node->virtual_memory));
    av_push(array,newSViv((long)node->memory));
    av_push(array,newSViv((long)node->disk));
    av_push(array,newSVnv(node->loadavg));
    av_push(array,newSViv(node->speed));
    av_push(array,newSViv((long)node->max_starters));
    av_push(array,newSViv((long)node->pool));
    av_push(array,newSViv((long)node->cpus));
    av_push(array,newSVpv(node->state, 0));
    av_push(array,newSViv((long)node->keywordidle));
    av_push(array,newSViv((long)node->totaljobs));
    av_push(array,newSVpv(node->arch, 0));
    av_push(array,newSVpv(node->opsys, 0));

    list=(AV *)sv_2mortal((SV *)newAV());
    ptr=node->adapter[0];
    i=0;
    while(ptr!=NULL)
    {     
	av_push( list, newSVpv( ptr, 0 ) );
	i++;
	ptr=node->adapter[i];
    }
    av_push(array,newRV((SV *)list));

    list=(AV *)sv_2mortal((SV *)newAV());
    ptr=node->feature[0];
    i=0;
    while(ptr!=NULL)
    {     
	av_push( list, newSVpv( ptr, 0 ) );
	i++;
	ptr=node->feature[i];
    }
    av_push(array,newRV((SV *)list));

    list=(AV *)sv_2mortal((SV *)newAV());
    ptr=node->job_class[0];
    i=0;
    while(ptr!=NULL)
    {     
	av_push( list, newSVpv( ptr, 0 ) );
	i++;
	ptr=node->job_class[i];

    }
    av_push(array,newRV((SV *)list));

    list=(AV *)sv_2mortal((SV *)newAV());
    ptr=node->initiators[0];
    i=0;
    while(ptr!=NULL)
    {     
	av_push( list, newSVpv( ptr, 0 ) );
	i++;
	ptr=node->initiators[i];
    }
    av_push(array,newRV((SV *)list));

/* LL_STEP_ID */
    list=(AV *)sv_2mortal((SV *)newAV());
    idptr=node->steplist;
    while (idptr->from_host != NULL )
    {
	av_push(list,newRV((SV *)unpack_ll_step_id(idptr)));
	idptr++;
    }
    av_push(array,newRV((SV *)list));

    av_push(array,newSViv(node->virtual_memory64));
    av_push(array,newSViv(node->memory64));
    av_push(array,newSViv(node->disk64));
    return(array);
}

/* 
 * Convert a perl array ( assumed to be of strings ) into a C char ** array.
 * To do this we iterate over the array, malloc storage for the data and copy it into the C array
 * This Code is from the XS Cookbooks by Dead Roehrich ( CPAN authors/DEAN_Roehrich).
 */

char **
XS_unpack_charPtrPtr( rv )
SV *rv;
{
	AV *av;
	SV **ssv;
	char **s;
	int avlen;
	int x;
	/*	unsigned long na; */   /* MH check this */

	if ( ! SvOK( rv ) )
		return( (char**)NULL );

	if( SvROK( rv ) && (SvTYPE(SvRV(rv)) == SVt_PVAV) )
		av = (AV*)SvRV(rv);
	else {
		warn("XS_unpack_charPtrPtr: rv was not an AV ref");
		return( (char**)NULL );
	}

	/* is it empty? */
	avlen = av_len(av);
	if( avlen < 0 ){
		return( (char**)NULL );
	}

	/* av_len+2 == number of strings, plus 1 for an end-of-array sentinel.
	 */
	s = (char **)safemalloc( sizeof(char*) * (avlen + 2) );
	if( s == NULL ){
		warn("XS_unpack_charPtrPtr: unable to malloc char**");
		return( (char**)NULL );
	}
	for( x = 0; x <= avlen; ++x ){
		ssv = av_fetch( av, x, 0 );
		if( ssv != NULL ){
			if( SvPOK( *ssv ) ){
				s[x] = (char *)safemalloc( SvCUR(*ssv) + 1 );
				if( s[x] == NULL )
					warn("XS_unpack_charPtrPtr: unable to malloc char*");
				else
					strcpy( s[x], SvPV_nolen( *ssv) );
			}
			else
				warn("XS_unpack_charPtrPtr: array elem %d was not a string.", x );
		}
		else
			s[x] = (char*)NULL;
	}
	s[x] = (char*)NULL; /* sentinel */
	return( s );
}

/* This call back function is called by the ll_move_spool API after each
 * job is processed. This allows the caller to receive status for each job 
 * This routine was copied from llmovespool in the sample directory.
 */

int _ll_print_job_status(char *jobid,int rc, LL_element **messageObj) 
{

        char *msg = NULL;

        if (rc == API_OK) {
                msg = ll_error(messageObj,1);
        } else {
                msg = ll_error(messageObj,2);
        }
        if (msg != NULL) free(msg);
	return(rc);
}


MODULE = IBM::LoadLeveler		PACKAGE = IBM::LoadLeveler

const char *
ll_version()


INCLUDE: Workload.xsh		     	     
INCLUDE: Reservation.xsh
INCLUDE: Configuration.xsh
INCLUDE: Error.xsh
INCLUDE: FairShare.xsh
INCLUDE: Query.xsh
INCLUDE: Submit.xsh
INCLUDE: DataAccess.xsh
		
