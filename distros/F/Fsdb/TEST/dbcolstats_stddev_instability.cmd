#
# This input showed numeric instability in stddev,
# resulting in sqrt of a negative number.
#
# test case from hangguo
# fails with Can't take sqrt of -5.59822e-15 at /usr/share/perl5/vendor_perl/Fsdb/Filter/dbcolstats.pm line 620, <GEN0> line 106.
# under Fedora 31 with perl v5.30.1 on x86-64
#
prog='dbcolstats'
args='RCLoss_norm'
cmp='diff -c '
