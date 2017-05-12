#!/bin/bash


echo " running"
echo -n " Hostname="
hostname
echo -n " uname="
uname -a
echo -n " user="
id
echo
sleep $1
echo
echo "-------start env ---"
env
echo "-------end env ---"
env | wc
echo "done seeya later"
