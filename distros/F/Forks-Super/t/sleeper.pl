# trivial external command to wait and then exit
# see  t/24c-kill.t  and  t/24d-kill.t
$SIG{TERM} = $SIG{QUIT} = sub { 
    exit 255;
};
sleep 15;
