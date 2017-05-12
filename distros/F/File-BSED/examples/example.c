 #include <stdlib.h>
    #include <stdio.h>
    #include <libgbsed.h>
    
    extern int gbsed_errno;

    int main(int argc, char **argv) {

        int         gbsed_ret;
        int         sysret;
        const char *errmessage;
        GBSEDargs   *bargs; 

        sysret  = EXIT_SUCCESS;
        bargs   = (GBSEDargs *)malloc(sizeof(GBSEDargs));
        if (bargs == NULL) {
            fprintf(stderr, "Out of memory!\n");
            exit(1);
        } 

        bargs->search      = "0xff";
        bargs->replace     = "0x00";
        bargs->infilename  = "/bin/ls";
        bargs->outfilename = "bsed.out";
        bargs->minmatch    =  1;    // atleast one match.
        bargs->maxmatch    = -1;    // no limit.

        if (argc > 1)
            bargs->infilename  = argv[1]; 

        gbsed_ret = gbsed_binary_search_replace(bargs);

        switch (gbsed_ret) {
            
            case GBSED_ERROR:
                errmessage = gbsed_errtostr(gbsed_errno);
                fprintf(stderr, "ERROR: %s\n", errmessage);
                sysret = EXIT_FAILURE;
                break;
            case GBSED_NO_MATCH:
                fprintf(stderr, "No match for %s found in %s\n",
                    bargs->search, bargs->infilename
                );
                sysret = EXIT_FAILURE;
                break;
            
            default:
                printf("Search for '%s' in '%s' matched %d times.\n",
                    bargs->search, bargs->infilename, gbsed_ret
                );
                break;
        }
        
        free(bargs);
        return sysret;
    }
