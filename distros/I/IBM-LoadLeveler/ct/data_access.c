#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "llapi.h"

/* 
 * This is a simple C representation of test t/04data_access
 * The Perl test will check the result of this with it's own for consistency
 */
 
main(int argc, char *argv[])
{
	LL_element	*query,*machines;
	int		rc,number,err;
	int		cpus;
	double		speed;
	char		*name;
	char		**classes, *pointer;
	int		i;
	time_t		time;
	LL_element	*adap;
	char            *aname;
	
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
	printf("DATA_ACCESS:NUMBER=%d\n",number);
		
	rc=ll_get_data(machines,LL_MachineCPUs,&cpus);
	if (!rc){
		printf("DATA_ACCESS:CPUS=%d\n",cpus);
		}
	
	rc=ll_get_data(machines,LL_MachineSpeed,&speed);
	if (!rc){
		printf("DATA_ACCESS:SPEED=%f\n",speed);
		}
		
	rc=ll_get_data(machines,LL_MachineName,&name);
	if (!rc){
	 	printf("DATA_ACCESS:NAME=%s\n",name);
		free(name);
		}
	
	rc=ll_get_data(machines,LL_MachineConfiguredClassList,&classes);
	if (!rc){
		pointer=*classes;
		i=0;
		printf("DATA_ACCESS:CLASSES=");
		while (pointer != NULL)
		{
		  printf("%s:",pointer);
		  i++;
		  free(pointer);
		  pointer=*(classes+i);
		}
		free(classes);
		printf("\n");
		}
		
	rc=ll_get_data(machines,LL_MachineTimeStamp,&time);
	if (!rc){
		printf("DATA_ACCESS:TIME=%ld\n",time);
		}	
	rc=ll_get_data(machines,LL_MachineGetFirstAdapter,&adap);
	if ( adap != NULL )
	{
  		rc=ll_get_data(adap,LL_AdapterName,&aname);
	if (!rc){
			printf("DATA_ACCESS:ADAPTER=%s\n",aname);
		}	
	}	
}
