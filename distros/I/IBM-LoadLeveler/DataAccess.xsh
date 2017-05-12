
LL_element *
ll_query(queryType)
	int queryType
	PROTOTYPE: $

int
ll_reset_request(object)	
	LL_element *object

LL_element *
ll_next_obj(object)	
	LL_element *object

int
ll_free_objs(object)
	LL_element *object

void
ll_deallocate(object)
	LL_element *object
     
int
ll_set_request(object,QueryFlags,ObjectFilter,DataFilter)
	LL_element *object
	int	QueryFlags
	char 	**ObjectFilter
	int	DataFilter

LL_element *
ll_get_objs(object,query_daemon,hostname,number,err)
	LL_element *object
	int	    query_daemon
	char	   *hostname
	int         number
	int         err
	PROTOTYPE: $$$$$
	CODE:
	{
	    RETVAL=ll_get_objs(object,query_daemon,hostname,&number,&err);
	}
	OUTPUT:
		number
		err
		RETVAL

void *
ll_get_data(object,Specification)
	LL_element *object
	int Specification       
	PROTOTYPE: $$

	PPCODE:
	{
		RETVAL=(void *)targ; /* bogus but spresses any unused variable error messages */
	    /*fprintf(stderr,"\nSPECIFICATION = %d\n",Specification);*/
	    switch (defs[Specification])
	    {
	        case LL_NONE:
		    	XSRETURN_UNDEF;
	        break;
	        case LL_CHAR_STAR_STAR:
			{
		    	char *pointer=NULL;
		    	int   rc;

		    	rc=ll_get_data(object,Specification,(void *)&pointer);
		    	/* fprintf(stderr,"%d = %s\n",Specification,pointer); */
		    	if (rc >= 0 && pointer != NULL)
		    	{
		    	    XPUSHs(sv_2mortal(newSVpv(pointer, 0)));
					Safefree(pointer);
					XSRETURN(1);
			    }
			    else
		    	    XSRETURN_UNDEF;
			}
			break ;
	        case LL_BOOLEAN_STAR:
	        case LL_INT_STAR:
			{
		    	int integer;
		    	int rc;

		    	rc=ll_get_data(object,Specification,(void *)&integer);
			/*	fprintf(stderr,"LLXS INTERNAL: (LL_INT_STAR)    : %d = %d ( %d )\n",Specification,integer,rc); */
		    	if (rc >= 0)
		    	{
					XPUSHs(sv_2mortal(newSViv(integer)));
					XSRETURN(1);
		    	}
		    	else
		      		XSRETURN_UNDEF;
			}
			break;
	        case  LL_TIME_T_STAR:
			{
			    time_t time;
			    int   rc;
		    
		    	rc=ll_get_data(object,Specification,(void *)&time);
			/*	fprintf(stderr,"LLXS INTERNAL: (LL_TIME_T_STAR) : %d = %ld ( %d )\n",Specification,time,rc); */
		    	/*fprintf(stderr,"%d = %ld\n",Specification,time); */
		    	if (rc >= 0)
		    	{
		    	    XPUSHs(sv_2mortal(newSViv((long)time)));
					XSRETURN(1);
		    	}
		    	else
		    	    XSRETURN_UNDEF;
			}
			break ;
	        case LL_CHAR_STAR:
			{
		    	/* char * type ( A single Character ) */
		    	char value;
		    	int   rc;

		    	rc=ll_get_data(object,Specification,(void *)&value);
		    	/*fprintf(stderr,"\n%d = %c ( %d )\n",Specification,value,rc)*/;
		    	if (rc >= 0)
		    	{
		    	    XPUSHs(sv_2mortal(newSViv(value)));
					XSRETURN(1);
		    	}
		    	else
		    		XSRETURN_UNDEF;		    
			}
			break ;
	        case LL_UINT64_T_STAR:
	        case LL_INT64_T_STAR:
			{
		    	int64_t value;
		    	int     rc;
		
		    	rc=ll_get_data(object,Specification,&value);
		    	/*		    	printf("%d = %lld\n",Specification,value);*/
		    	if (rc >= 0)
		    	{
		    	    XPUSHs(sv_2mortal(newSViv(value)));
					XSRETURN(1);
		    	}
		    	else
		    	    XSRETURN_UNDEF;
			}
			break ;
	        case LL_DOUBLE_STAR:
			{ 
		    	double value;
		    	int rc;
		
		    	rc=ll_get_data(object,Specification,(void *)&value);
		    	/* printf("%d = %f\n",Specification,value); */
		    	if (rc >= 0)
		    	{
		        	XPUSHs(sv_2mortal(newSVnv(value)));
		        	XSRETURN(1);
		    	}
		    	else
		    	  XSRETURN_UNDEF;
			}
			break;
	        case LL_LL_ELEMENT_STAR:
			{
				void *pointer;
				int   rc;
		
				rc=ll_get_data(object,Specification,(void *)&pointer);
				/*fprintf(stderr,"LLXS INTERNAL: (LL_ELEMENT_STAR) : %d = %ld ( %d)\n",Specification,pointer,rc);*/
				if (rc >= 0)
				{
			    	XPUSHs(sv_2mortal(newSViv((long)pointer)));
			    	XSRETURN(1);
				}
				else
				    XSRETURN_UNDEF;
			}
	    	break ;
	    	case LL_CHAR_STAR_STAR_STAR:
	      	{
		  		switch(Specification)
		  		{
#if LLVER >= 3030100
		    		case LL_FairShareEntryNames:
		      		{
		          		/* char *** data type (array of strings) */
			  			char **array;
			  			int    i;
			  			int    rc;
			  			int    size;

			  			rc=ll_get_data(object,LL_FairShareNumberOfEntries,(void *)&size);
			  			if ( rc >= 0 )
			  			{
			    			rc=ll_get_data(object,Specification,(void *)&array);
			      			if ( rc >= 0 && array)
			      			{
				  				for(i=0; array[i];i++)
				  				{
				      				/* 	printf("%d = %d  %p -> %s\n",Specification,index,&array[i],array[i]); */
				      				/*   	printf("%d = %d -> %s\n",Specification,index,array[i]); */
				      				XPUSHs(sv_2mortal(newSVpv(array[i], 0)));
				  				}
				  				Safefree(array);
				  				XSRETURN(i);
			      			}
			      			else
								XSRETURN_UNDEF;
			  			}
			  			else
			    			XSRETURN_UNDEF;
		      		}
		      		break;
		      		case LL_BgPartitionBPList:
		      		case LL_BgPartitionNodeCardList:
		      		{
		          		/* char *** data type (array of strings) */
			  			char **array;
			  			int    i;
			  			int    rc;

			  			rc=ll_get_data(object,Specification,(void *)&array);
			  			if ( rc >= 0 && array)
			  			{
			      			for(i=0; array[i];i++)
			      			{
				  				/* 	printf("%d = %d  %p -> %s\n",Specification,index,&array[i],array[i]); */
				  				/* 	printf("%d = %d -> %s\n",Specification,index,array[i]); */
				  				XPUSHs(sv_2mortal(newSVpv(array[i], 0)));
			      			}
			      			Safefree(array);
			      			XSRETURN(i);
			  			}
			  			else
			    	  		XSRETURN_UNDEF;
		      		}
		      		break;
#endif
		      		default:
		      		{
			  			/* char *** data type (array of strings) */
			  			char **array;
			  			char  *pointer;
			  			int    i;
			  			int    rc;

			  			rc=ll_get_data(object,Specification,(void *)&array);
			  			if ( rc >= 0 )
			  			{
			    	  		pointer=*array;
			      			i=0;
			      			while (pointer != NULL)
			      			{
				  				/* printf("%d = %s\n",Specification,pointer); */
				  				/* printf("%d = %p %s\n",Specification,array+i,pointer); */
				  				XPUSHs(sv_2mortal(newSVpv(pointer, 0)));
				  				i++;
				  				Safefree(pointer);
				  				pointer=*(array+i);
			      			}
			      			Safefree(array);
			      			XSRETURN(i);
			  			}
			  			else
			      			XSRETURN_UNDEF;
		      		}
		      		break ;
		    	}
	      }
	      break;
#if LLVER >= 3050000
	      case LL_CRONTAB_TIME_STAR:
	      {
		      /* data type LL_crontab_time * (pointer to crontab structure) */
		      int 		rc;
		      LL_crontab_time	*time;
		      
		      rc=ll_get_data(object,Specification,(void *)&time);
		      if (rc >= 0)
		      {
			      HV *hash;
           
			      hash=unpack_ll_crontab_time((LL_crontab_time *)time);
			      	XPUSHs(sv_2mortal(newRV((SV *)hash)));
			      if (time->minutes != NULL) Safefree(time->minutes);
			      if (time->hours   != NULL) Safefree(time->hours);
			      if (time->dom     != NULL) Safefree(time->dom);
			      if (time->months  != NULL) Safefree(time->months);
			      if (time->dow     != NULL) Safefree(time->dow);
		      }
		      else
			      	XSRETURN_UNDEF;
	      }
	      break;
#endif
	      case LL_INT_STAR_STAR:
	      {
		  int     ArraySize=-1;
		  int     rc=-1;
		  int	 *array;
		  int	  i;

		  /*
		   * The int ** arrays all have a size, either fixed such as those for BG
		   * or returned in an int value from some other call
		   */
		  switch (Specification)
		  {
		      case LL_MachinePoolList:
			  rc=ll_get_data(object,LL_MachinePoolListSize,(void *)&ArraySize);
			  break;
#if LLVER >= 3020000
		      case LL_AdapterWindowList:
			  rc=ll_get_data(object,LL_AdapterTotalWindowCount,(void *)&ArraySize);			
			  break;
#endif 
#if LLVER >= 3040001
  		      case LL_BgPartitionShape:
		      case LL_ReservationBgShape:
#endif
#if LLVER >= 3030100
		      case LL_BgBPLocation:
		      case LL_BgMachineBPSize:
		      case LL_BgMachineSize:
		      case LL_StepBgShapeAllocated:
		      case LL_StepBgShapeRequested:
				{
					rc=0;
					ArraySize=3;
				}
				break;
#endif
#if LLVER >= 3040001
		      case LL_FairShareUsedBgShares:			
#endif
#if LLVER >= 3030100
		      case LL_FairShareEntryTypes:
		      case LL_FairShareAllocatedShares:
		      case LL_FairShareUsedShares:
			  rc=ll_get_data(object,LL_FairShareNumberOfEntries,(void *)&ArraySize);
			  break;
#endif
		      case LL_MachineCPUList:
			  	rc=ll_get_data(object,LL_MachineCPUs,(void *)&ArraySize);
			  break;
		      case LL_MCMCPUList:
			  	rc=ll_get_data(object,LL_MCMCPUs,(void *)&ArraySize);
			  break;
		      case LL_MachineUsedCPUList:
			  	rc=ll_get_data(object,LL_MachineUsedCPUs,(void *)&ArraySize);
		      break;
		  }
		  
		  /* Return if we don't have a valid value in ArraySize */
		  if (rc < 0  || ArraySize < 0)
		  {
		    XSRETURN_UNDEF;
		  } 
		  /*printf("MachinePoolListSize = %ld\n",PoolSize); */
		  rc=ll_get_data(object,Specification,(void *)&array);
		  if ( rc >= 0 )
		  {
		      /*fprintf(stderr,"Array Size = %d\n",ArraySize);*/
		      for(i=0;i != ArraySize;i++)
		      {
					/* fprintf(stderr,"Value %d = %d\n",i,array[i]); */
					XPUSHs(sv_2mortal(newSViv((long)array[i])));
		      }
		      free(array);
		      XSRETURN(ArraySize);
		  }
		  else
		    XSRETURN_UNDEF;
	      }
	      break;     	  
	    }
	}
	    
