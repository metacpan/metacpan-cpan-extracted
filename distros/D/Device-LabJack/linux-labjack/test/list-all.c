#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <ljackul.h>

int main() { 
    int size = 127;
    long productIDList[size]; 
    long serialnumList[size];
    long localIDList[size];
    long powerList[size];
    long calMatrix[size][20];
    long numberFound = 0;
    long fcddMaxSize = 0;
    long hvcMaxSize = 0;
    long result;
    int k, l, m, n;

    for (k = 0; k<size; k++) {
        productIDList[k] = 0;
        serialnumList[k] = 0;
        localIDList[k] = 0;
        powerList[k] = 0;
        
        for(l = 0; l<20; l++) 
            calMatrix[k][l] = 0;
    }

    numberFound = 0;
    fcddMaxSize = 0;
    hvcMaxSize = 0;
    result = ListAll(productIDList, serialnumList, localIDList, powerList, calMatrix, &numberFound, &fcddMaxSize, &hvcMaxSize);
            
    if( result != 0) {
        printf("ListAll error, # %ld\n", result);
        return result;
    }
            
    printf("\nFound %ld LabJacks!\n ", numberFound);
    printf("\nInfo: \n\n");
    printf("productID, serialNum, localID, powerList, calMatrix\n");
            
    for(m = 0; m < numberFound; m++) {
        printf("\n%ld, %ld, %ld, %ld, \n", productIDList[m], serialnumList[m], localIDList[m], powerList[m]);
        printf(" (");
        
        for(n = 0; n < 20; n++)
            printf("%ld ", calMatrix[m][n]);
            printf(")\n");
       	}

    return 0;
}
