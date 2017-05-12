#!/bin/sh
#perl -MTestWorker -e 'TestWorker->start_worker()' 
perl -MTestWorker -e 'TestWorker->start_worker("localhost:9998")' 
