#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use IP::China 'chinese_ip';
if (chinese_ip ('127.0.0.1')) {
    print '你好';
}
