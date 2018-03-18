package DracPerl::CollectionMappings;

use Readonly;

Readonly my %QUERIES => ( systemInformations =>
        'pwState,sysDesc,sysRev,hostName,osName,osVersion,svcTag,expSvcCode,biosVer,fwVersion,LCCfwVersion,kvmEnabled'
);

sub get_query {
    my $command = shift;
    return $QUERIES{$command} || '';
}

1;
