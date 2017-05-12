#delete the linkcont user
if [ $1 = '0' ]
then 
    default-install --verbose --disable --linkcont-user
fi
