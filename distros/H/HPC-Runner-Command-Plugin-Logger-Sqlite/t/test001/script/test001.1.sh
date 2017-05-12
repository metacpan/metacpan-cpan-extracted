#HPC jobname=job01
echo "hello world from job 1-1" && sleep 5

echo "hello again from job 1-2" && sleep 5

echo "goodbye from job 1-3"

#TASK tags=hello,world
echo "hello again from job 1-3" && sleep 5

#HPC jobname=job02
echo "hello world from job 2-1" && sleep 5

echo "hello again from job 2-2" && sleep 5

echo "goodbye from job 2-3"

#TASK tags=hello,world
echo "hello again from job 2-3" && sleep 5

