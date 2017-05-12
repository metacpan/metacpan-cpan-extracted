#include <stdio.h>
#include <unistd.h>
#include <ljackul.h>

int main (int argc, char *argv[])
{
	float vout = 0;
	long id = -1;

	//
	// Test Analog Outs (Using EAnalogOut)
	//
	printf("%s: Testing analog outs ...\n", argv[0]);
	for (vout = 0; vout < 5.1; vout += 0.5) {
    
		printf("\tSetting voltage to %f ...\n", vout);
        
		if (EAnalogOut(&id, 0, vout, vout) != 0) {
			printf("%s: Error setting analog outs!\n", argv[0]);
			break;
		}   
		sleep(2);
	}

	if (EAnalogOut(&id, 0, 0, 0) != 0) {
		printf("%s: Error setting analog outs!\n", argv[0]);
	}

    return 0;
}
