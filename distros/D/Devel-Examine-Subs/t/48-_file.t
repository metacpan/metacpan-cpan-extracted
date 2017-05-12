#!perl 
use warnings;
use strict;

use Test::More;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

{
    my $des = Devel::Examine::Subs->new(file => 't/sample.data');

    $des->_file({file => 'Pod::Usage'});

    use Data::Dumper;

    ok (! exists $INC{'Pod::Usage'}, "module unloaded if not previously loaded in _file()");
    ok (! $Pod::Usage::VERSION, "_file() also unloads an unloaded module");
}
{
    my $des = Devel::Examine::Subs->new;

    my $file = '/c:';

    $des->{params}{backup} = 1;
    eval { $des->_read_file({ file => $file }); };
    like (
        $@,
        qr/DES::_read_file\(\) can't create backup/,
        "_read_file() croaks if it can't create backup file and backup is set"
    );
}
{
    my $des = Devel::Examine::Subs->new;

    my $file = '/c:';

    eval { $des->_read_file({ file => $file }); };
    like (
        $@,
        qr/Can't call method "serialize" on an undefined/, # PPI error
        "_read_file() croaks via PPI if a file is invalid or doesn't exist"
    );
}
{
    my $des = Devel::Examine::Subs->new;

    my $file = 't/sample.data';

    $des->{params}{backup} = 1;
    $des->_read_file({ file => $file });

    is (-e 'sample.data.bak', 1, "with backup enabled, a bak file is created");

    eval { unlink 'sample.data.bak' or die "can't unlink file!"; };
    is ($@, '', "removed bak file ok");
}
{
    my $des = Devel::Examine::Subs->new;

    my $file = 't/sample.data';

    $des->_read_file({ file => $file });
    is (-e 'sample.data.bak', undef, "backup is disabled by default");

    $des->backup(1);
    $des->_read_file({ file => $file });
    is (-e 'sample.data.bak', 1, "with backup(1), a bak is created");
    eval { unlink 'sample.data.bak' or die "can't unlink file!"; };
    is ($@, '', "removed bak file ok");

    $des->backup(0);
    is ($des->{params}{backup}, 0, "backup is disabled after backup(0) call");
    $des->_read_file({ file => $file });

    is (-e 'sample.data.bak', undef, "with backup disabled, a bak file isn't created");
}

done_testing();
