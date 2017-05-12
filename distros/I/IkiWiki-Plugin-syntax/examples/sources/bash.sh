# Long term variables, which may be set in the cvsdeb config file or the
# environment:
# rootdir workdir (if all original sources are kept in one dir)

TEMPDIR=/tmp/$$
mkdir $TEMPDIR || exit 1
TEMPFILE=$TEMPDIR/cl-tmp
trap "rm -f $TEMPFILE; rmdir $TEMPDIR" 0 1 2 3 7 10 13 15

TAGOPT=

# Command line; will bomb out if unrecognised options
TEMP=$(getopt -a -s bash \
       -o hC:EH:G:M:P:R:T:U:V:W:Ff:dcnr:x:Bp:Dk:a:Sv:m:e:i:I:t: \
       --long help,version,ctp,tC,sgpg,spgp,us,uc,op \
       --long si,sa,sd,ap,sp,su,sk,sr,sA,sP,sU,sK,sR,ss,sn \
       -n "$PROGNAME" -- "$@")
eval set -- $TEMP
