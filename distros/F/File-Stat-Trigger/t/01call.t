
use strict;
use Test::More tests => 25;
use IO::File;

BEGIN { use_ok 'File::Stat::Trigger' }

my $file = 't/sample.txt';

my $fs = File::Stat::Trigger->new({
 file        => $file,
});

ok($fs->scan());

$fs = File::Stat::Trigger->new({
 file        => $file,
 check_atime => ['>=','2008/11/20 12:00:00'],
 check_ctime => ['>='],
# check_mtime => ['<=', '2008/11/20 12:00:00'],
 check_size  => ['==',1024],
 auto_stat   => 1,
});

ok($fs->size_trigger( sub {
        my $self = shift;
        my $i = $self->file_stat->size;    
        my $j = $self->_size;
    } ));

ok($fs->atime_trigger(\&sample));

my $result = $fs->scan();

is($result->{size_trigger},0,'Not Call size_trigger');
is($result->{atime_trigger},1,'Not Call atime_trigger');
is($result->{ctime_trigger},0,'Call ctime_trigger');
is($result->{mtime_trigger},0,'Call mtime_trigger');

# ---------- 
$fs = File::Stat::Trigger->new({
 file        => $file,
 check_atime => ['!='],
 check_ctime => ['=='],
 check_mtime => ['=='],
 check_size  => ['!='],
});
# check_size  => ['!=',1024],

ok($fs->ctime_trigger(\&sample));
ok($fs->atime_trigger(\&sample));
ok($fs->mtime_trigger(\&sample));
ok($fs->size_trigger(\&sample));

sleep(2);

# changed atime
my $fh = new IO::File "$file";
if (defined $fh) {
    while(my $l = <$fh>){}
    $fh->close;
}

$result = $fs->scan();
is($result->{atime_trigger},1,'Not Call atime_trigger');
is($result->{ctime_trigger},1,'Not Call ctime_trigger');
is($result->{mtime_trigger},1,'Not Call mtime_trigger');
is($result->{size_trigger},0,'Not Call mtime_trigger');

# This function execute 'scan()' in three interval. 
#$result = $fs->run(3);

$fs = File::Stat::Trigger->new({
 file        => $file,
});

ok($fs->scan());




$fs = File::Stat::Trigger->new({
 file        => $file,
});

ok($fs->ctime_trigger(\&sample,['>','2008/11/20 01:00:00']));
ok($fs->atime_trigger(\&sample,['!=','2008/11/20 01:00:00']));
ok($fs->mtime_trigger(\&sample,['>=','2008/11/20 01:00:00']));
ok($fs->size_trigger(\&sample,['>=',10]));
$result = $fs->scan();
is($result->{ctime_trigger},1,'Not Call ctime_trigger');
is($result->{atime_trigger},1,'Not Call atime_trigger');
is($result->{mtime_trigger},1,'Not Call mtime_trigger');
is($result->{size_trigger},1,'Not Call size_trigger');

# This function execute 'scan()' in three interval. 
#$result = $fs->run(3);

sub sample {
     my $fs = shift;
     print 'file.atime:'.$fs->file_stat->atime->ymd('-')."\n";
     return 1;
}

