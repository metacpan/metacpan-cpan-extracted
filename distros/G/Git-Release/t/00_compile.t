use strict;
use Test::More;

BEGIN { 
    use_ok 'Git::Release';
    use_ok 'Git::Release::Config';
    use_ok 'Git::Release::Branch';
    use_ok 'Git::Release::BranchManager';
    use_ok 'Git::Release::RemoteManager';
}

done_testing;
