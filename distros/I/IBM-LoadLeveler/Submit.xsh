void *
llsubmit(job_cmd_file, monitor_program,monitor_arg)
	char *job_cmd_file
	char *monitor_program
	char *monitor_arg

	PPCODE:
	{
	    LL_job	job_info;
	    int		 rc;
	    int		i;
	    AV		*steps;

	    RETVAL=(void *)targ; /* bogus but supresses any unused variable error messages */
	    rc=llsubmit(job_cmd_file,monitor_program,monitor_arg,&job_info,LL_JOB_VERSION);
	    if ( rc != 0 )
		XSRETURN_UNDEF;
	    else
	    {
		XPUSHs(sv_2mortal(newSVpv(job_info.job_name, 0)));
		XPUSHs(sv_2mortal(newSVpv(job_info.owner, 0)));
		XPUSHs(sv_2mortal(newSVpv(job_info.groupname, 0)));
		XPUSHs(sv_2mortal(newSViv((long)job_info.uid)));
		XPUSHs(sv_2mortal(newSViv((long)job_info.gid)));
		XPUSHs(sv_2mortal(newSVpv(job_info.submit_host, 0)));
		XPUSHs(sv_2mortal(newSViv((long)job_info.steps)));
		steps=(AV *)sv_2mortal((SV *)newAV());
		for(i=0;i!=job_info.steps;i++)
		{
		    HV *step;

		    step=unpack_job_step(job_info.step_list[i]);
		    av_push(steps,newRV((SV *)step));
		}	
		XPUSHs(sv_2mortal(newRV((SV *)steps)));
		/* All Data now in Perl structures free the LoadLeveler construct */
		llfree_job_info(&job_info,LL_JOB_VERSION);
	    }	    
	}
