#include <stdio.h>
#include <stdlib.h>
#include "llapi.h"

/* 
 * This is a simple C representation of test t/05int_types
 * The Perl test will check the result of this with it's own for consistency
 */
 
main(int argc, char *argv[])
{
	LL_element	*query,*machines;
	int		rc,number,err;
	int		cpus,i;
	int		*cpulist;
	int		pools,*poollist;
	LL_element	*adapter;
	int		windows,*windowlist;
	
	query = ll_query(MACHINES);
	if (!query) {
		exit(1);
	}
	rc=ll_set_request(query,QUERY_ALL,NULL,ALL_DATA);
	if (rc) {
		exit(1);
	}
	
	machines=ll_get_objs(query,LL_CM,NULL,&number,&err);
	if (machines == NULL) {
		exit(1);
	}
	if (!rc){
  		printf("INT_TYPES:NUMBER=%d\n", number);
	}	
   	rc = ll_get_data(machines,LL_MachineCPUs,&cpus);
	if (!rc){
	   	printf("INT_TYPES:CPUS=%d\n",cpus);
	}
   	rc = ll_get_data(machines,LL_MachineCPUList,&cpulist);
	if (!rc){
		printf("INT_TYPES:CPU_LIST=");
		for(i=0;i != cpus;i++)
	   	{
        		printf("%d:",cpulist[i]);
   		}
		printf("\n");
	}
	rc = ll_get_data(machines, LL_MachinePoolListSize,&pools);
	if (!rc){
		printf("INT_TYPES:POOLS=%d\n",pools);
	}
	rc = ll_get_data(machines,LL_MachinePoolList,&poollist);
	if (!rc){
		printf("INT_TYPES:POOL_LIST=");
		for(i=0;i != pools;i++)
   		{
        		printf("%d:",poollist[i]);
   		}
		printf("\n");	
	}
	rc = ll_get_data(machines, LL_MachineGetFirstAdapter,&adapter);
	if ( adapter != NULL )
	{
		rc=ll_get_data(adapter, LL_AdapterTotalWindowCount,&windows);
		while (adapter != NULL && windows == 0 )
		{
		 	rc=ll_get_data(machines, LL_MachineGetNextAdapter,&adapter);
			rc=ll_get_data(adapter, LL_AdapterTotalWindowCount,&windows);
		}
		if ( windows != 0 )
		{
			printf("INT_TYPES:WINDOWS=%d\n",windows);
			printf("INT_TYPES:WINDOW_LIST=");
   			rc=ll_get_data(adapter, LL_AdapterWindowList,&windowlist);
			for(i=0;i != windows;i++)
   			{
     			   	printf("%d:",windowlist[i]);
   			}
			printf("\n");
		}
	}
}
