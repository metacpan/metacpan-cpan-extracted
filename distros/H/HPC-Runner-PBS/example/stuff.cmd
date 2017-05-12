echo "new commands job 1" && \
    echo "hello from job 1"

echo "hello from job 1"

wait

#HPC mem=24GB
#HPC module=module1

echo "new commands job 2"
echo "hello from job 3"
echo "new commands job 4"
echo "hello from job 5"
echo "new commands job 6" && \
    echo "hello from job 6"
