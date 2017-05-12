# this command demonstrates regular commands can operate on compressed input
prog='dbrow'
args='"_fullname =~ /John/"'
cmp='diff -c -b '
cmd_tail='| dbfilealter -Z none'
requires='IO::Compress::Xz'
