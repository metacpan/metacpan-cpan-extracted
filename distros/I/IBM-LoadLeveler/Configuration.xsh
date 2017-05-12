
#if LLVER >= 3040000

int 
ll_config_changed()

int
ll_read_config()

    CODE:
    {    
         LL_element *errObj=NULL;

	 RETVAL=ll_read_config(&errObj);
	 if (RETVAL != API_OK )
	 {
	   sv_setiv(get_sv("IBM::LoadLeveler::errObj",FALSE),(IV)errObj);	   
	 }
    }
     OUTPUT:
         RETVAL
	 
#endif
