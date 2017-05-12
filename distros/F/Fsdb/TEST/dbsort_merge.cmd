prog='dbsort'
# We do this sort as STRINGS, not NUMERICS (with -n, as we used to)
# because -n is very sensitive to platform-specific floating-point IO
# and we get test failures on seemingly normal-platforms because of that.
args='-M 1024 rand'
cmp='diff -c -b '
