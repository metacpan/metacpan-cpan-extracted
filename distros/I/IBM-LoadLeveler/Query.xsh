#if LLVER < 3050000
	
void *
ll_get_jobs()

	PPCODE:
	{
	    LL_get_jobs_info info;
	    int rc;
	    AV *jobs;
	    int i;

	    RETVAL=(void *)targ; /* bogus but spresses any unused variable error messages */
	    rc=ll_get_jobs(&info);
	    if (rc != 0 )
		XSRETURN_IV(rc);
	    else
	    {
		XPUSHs(sv_2mortal(newSViv((long)info.version_num)));
		XPUSHs(sv_2mortal(newSViv((long)info.numJobs)));
		jobs=(AV *)sv_2mortal((SV *)newAV());
		for(i=0;i!=info.numJobs;i++)
		{
		    AV *job;

		    job=unpack_ll_job(info.JobList[i]);
		    av_push(jobs,newRV((SV *)job));
		}	
		XPUSHs(sv_2mortal(newRV((SV *)jobs)));
		ll_free_jobs(&info);
	    }
	}	
	
void *
ll_get_nodes()

	PPCODE:
	{
	    LL_get_nodes_info info;
	    int rc;
	    AV *nodes;
	    int i;

	    RETVAL=(void *)targ; /* bogus but spresses any unused variable error messages */
	    rc=ll_get_nodes(&info);
	    if (rc != 0 )
		XSRETURN_IV(rc);
	    else
	    {
		XPUSHs(sv_2mortal(newSViv((long)info.version_num)));
		XPUSHs(sv_2mortal(newSViv((long)info.numNodes)));
		nodes=(AV *)sv_2mortal((SV *)newAV());
		for(i=0;i!=info.numNodes;i++)
		{
		    AV *node;

		    node=unpack_ll_node(info.NodeList[i]);
		    av_push(nodes,newRV((SV *)node));
		}	
		XPUSHs(sv_2mortal(newRV((SV *)nodes)));
		ll_free_nodes(&info);
	    }
	}
		
#endif
