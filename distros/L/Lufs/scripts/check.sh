#!/bin/sh

sum=$(tar cP ${*:-*} | md5sum)
procs=20

echo testing read on ${*:-*} with $procs concurrent processes
while true
	do for in in $(seq 1 $procs)
		do if [[ "$sum" != "$(tar cP ${*:-*} | md5sum)" ]]
			then echo error
		fi & \
	done
	sleep 1
done


