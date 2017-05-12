Digest::Adler32::XS

This is an XS-based implementation of the Adler32 digest, developed into a 
drop-in replacement for Digest::Adler32. 

If you have Digest::Adler32, the benchmark test will compare the performance.
On my system, the XS-based module runs more than 300 times faster than the
pure Perl Digest::Adler32.
