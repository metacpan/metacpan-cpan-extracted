package MYDan::AntDen::Cli;
use strict;
use warnings;

use Cwd;
use Carp;
use MYDan;
use MYDan::Util::OptConf;
use MYDan::Agent::Client;
use Digest::MD5;

sub new
{
    my ( $class, %self ) = splice @_;
    bless +{ %self, mt => "$MYDan::PATH/dan/tools" }, ref $class || $class;
}

sub _api
{
    my $this = shift @_;

    my %api = MYDan::Util::OptConf->load()->set()->get()->dump( 'api' );
    die "api.addr undef" unless my $api = $api{addr};
    $api =~ s/^http[s]*:\/\///;
    $api =~ s/:.*$//;
    $api =~ s/\/.*$//;
    die "api.addr error" unless $api && $api =~ /^[a-zA-Z0-9\.]+$/;

    return $api;
}

sub _rcall
{
    my ( $this, $host, %argv ) = splice @_;

    my $option = MYDan::Util::OptConf->load();
    my %o = $option->set( timeout => 60 )->get()->dump( 'agent' );

    $o{user} = `id -un` and chop $o{user} unless $o{user};
    $o{sudo} = 'root';

    my $api = $host || $this->_api();
    my %query = ( %argv, map{ $_ => $o{$_} }qw( user sudo ) );

    my %result = MYDan::Agent::Client->new( 
        $api
    )->run( %o, query => \%query ); 

    my $res = $result{$api} || '';
    die "call fail: $res" unless $res =~ s/--- 0$//;
    return $res;
}

sub run
{
    my ( $this, %run ) = splice @_;

    my $codeaddr = '';
    my $r = $this->resources( %run );
    die "[ERROR]Get resources fail.\n" unless $r && ref $r eq 'HASH';
    die "[ERROR]You don't have any resources to use.\n" unless $r->{machine} && ref $r->{machine} eq 'ARRAY' && @{$r->{machine}};

    unless( $run{group} )
    {
        my %group;
        grep{ $group{$_->{group}} ++ if 'slave' eq $_->{role} && $_->{mon} =~ /health=1/ }@{$r->{machine}};
        ( $run{group} ) = sort{ $group{$b} <=> $group{$a} } keys %group;
        die "[ERROR]You don't have any resources to use.\n" unless $run{group};
    }

    if( $run{hostip} )
    {
        map{
           if( $_->{mon} =~ /health=1/ )
           {
                $codeaddr = $_->{ip};
                $run{group} = $_->{group};
           }
        }grep{ $run{hostip} eq $_->{ip} }@{$r->{machine}};
    }
    else
    {
        map{
            $codeaddr = $_->{ip} if $_->{mon} =~ /health=1/;
        }grep{ $run{group} eq $_->{group} }@{$r->{machine}};
    }

    my @ingress = map{ $_->{ip} }grep{ $run{group} eq $_->{group} && $_->{role} eq 'ingress' }@{$r->{machine}};

    die "[ERROR]No machines or clusters available.\n" unless $codeaddr;
    map{ die "$_ undef" unless defined $run{$_} }qw( nice group count resources );
    my $api = $this->_api();

    my $uuid = time . '.'. sprintf "%012d", int rand 1000000000000;

    my $user = $ENV{MYDan_username};
    $user = `id -un` and chop $user unless $user;

    my ( $temp, $repofile, $runpath ) = ( "/tmp/antden.pkg.$uuid.tar.gz", "/data/AntDen_repo/$user.$uuid.tar.gz", "/tmp/AntDen.run.$uuid" );

    unless( $run{run} eq '_null_' )
    {
        print "[INFO]Compress local path...\n";
        die "tar fail: $!" if system "tar -zcf $temp `ls -a|grep -v '^\\.\$'|grep -v '^\\.\\.\$'`";
        print "[INFO]Upload data...\n";
        die "dump fail: $!" if system "$this->{mt}/rcall -r $codeaddr dump $temp --path '$repofile' --sudo root >/dev/null";
        die "remove temp file $temp fail:$!" if system "rm -f $temp";
    }
    print "[INFO]Submit job...\n";

    my @resources;
    map{
        if( my @x = $_ =~ /^([A-Z]+):(\d+)$/ )
        {
            if( $x[0] eq 'GPU' )
            {
                map{ push( @resources, [ $x[0], '.', 1 ] ) } 1 .. $x[1];
            }
            else { push( @resources, [ $x[0], '.', $x[1] ] ) }
        }
    } split /,/, $run{resources};

    die "resources err" unless @resources;

    my $ingress;
    my $domain = $run{domain} || sprintf "tmp.%s.antden.cn", Digest::MD5->new->add( time. rand( 10*10 ). YAML::XS::Dump \%run )->hexdigest;

    if( $run{port} )
    {
        push( @resources, [ 'PORT', '.', 1 ] );
        $ingress = +{ domain => $domain, location => '/' };
        
        if( @ingress )
        {
            if( $run{domain} )
            {
                printf "[INFO]Confirm that domain name $domain is bound to %s\n", join ',', @ingress;
            }
            else
            {
                print "[INFO]Domain $domain => $ingress[0]\n";
                die "write domain into hosts fail:$!\n" if system "echo '$ingress[0] $domain' >> /etc/hosts";
            }
            print "[INFO]Please open in browser http://$domain Access to services\n";
        }
        else
        {
            print "[WARN] no ingress in group $run{group}\n";
        }
    }

    my @datasets; @datasets = map{ "/mnt/$_:/mnt/$_" }split /,/, $run{datasets} if $run{datasets};
    my @volume; @volume = split /,/, $run{volume} if $run{volume};

    my $executer;
    if( $run{image} )
    {
        my $pwd = getcwd;
        $executer = +{
            name => 'docker',
            param => +{
                cmd => "$run{run}",
                image => $run{image},
                volumes => [ "/data/AntDen_repo/$user.$uuid:$pwd", @datasets, @volume ],
                antden_repo => $run{run} eq '_null_' ? undef : [ $codeaddr, "/data/AntDen_repo/$user.$uuid" ],
                workdir => $run{run} =~ /\.\// ? $pwd : undef,
                port => $run{port},
            }
        },
    }
    else
    {
        $executer = +{
            name => 'exec',
            param => +{
                exec => "MYDan_Agent_Load_Code=free.load_antden $this->{mt}/load --host $codeaddr  --sp '$repofile' --dp $runpath.tar.gz && mkdir -p $runpath && tar -zxvf $runpath.tar.gz -C '$runpath' &&cd '$runpath' && $run{run}"
            }
        },
    }

    my %argv = (
        ctrl => 'submitjob',
        conf => +{
            config => [+{
                executer => $executer,
                scheduler => +{
                    ip => $run{hostip},
                    envhard => 'arch=x86_64,os=Linux',
                    envsoft => 'app1=1.0',
                    count => $run{count},
                    resources => \@resources
                },
                ingress => $ingress,
            }],
            map{ $_ => $run{$_} }qw( nice name group )
        }
    );

    my $res = $this->_rcall( undef, code => 'antdencli', argv => \%argv );
    my $jobid = eval{ YAML::XS::Load $res };
    die "call fail: $res $@" if $@;
    die "call fail: $res\n" unless $jobid =~ /^J\.\d{8}\.\d{6}.\d{6}\.\d{3}$/;
    return $jobid;
}

sub list
{
    my ( $this, %run ) = splice @_;
    my $res = $this->_rcall( undef, code => 'antdencli', argv => +{ ctrl => 'listjob' } );
    my $job = eval{ YAML::XS::Load $res };
    die "call fail: $res $@" if $@;
    return $job;
}

sub resources
{
    my ( $this, %run ) = splice @_;
    my $res = $this->_rcall( undef, code => 'antdencli', argv => +{ ctrl => 'resources' } );
    my $r = eval{ YAML::XS::Load $res };
    die "call fail: $res $@" if $@;
    return $r;
}

sub info
{
    my ( $this, %run ) = splice @_;

    die "jobid undef" unless $run{jobid};

    my $res = $this->_rcall( undef,
        code =>'antdencli',
        argv => +{
            ctrl => 'info',
            conf => +{
                jobid => $run{jobid}
            }
        }
    );
    my $job = eval{ YAML::XS::Load $res };
    die "call fail: $res $@" if $@;
    return $job;
}

sub stop
{
    my ( $this, %run ) = splice @_;
    die "jobid undef" unless $run{jobid};

    my $res = $this->_rcall( undef,
        code =>'antdencli',
        argv => +{
            ctrl => 'stop',
            conf => +{
                jobid => $run{jobid}
            }
        }
    );

    my $job = eval{ YAML::XS::Load $res };
    die "call fail: $res $@" if $@;
    return $job;
}

sub tail
{
    my ( $this, %run ) = splice @_;
    $this->_taskcall( %run, name => 'tail' );
}

sub top
{
    my ( $this, %run ) = splice @_;
    $this->_taskcall( %run, name => 'top' );
}

sub shell
{
    my ( $this, %run ) = splice @_;
    $this->_taskcall( %run, name => 'shell' );
}

sub nvidiasmi
{
    my ( $this, %run ) = splice @_;
    $this->_taskcall( %run, name => 'nvidia-smi' );
}

sub listoutput
{
    my ( $this, %run ) = splice @_;
    $this->_taskcall( %run, name => 'listoutput' );
}

sub download
{
    my ( $this, %run ) = splice @_;
    $this->_taskcall( %run, name => 'download' );
}

sub _gethost
{
    my ( $this, $taskid, $type ) = @_;
    die "[ERROR]TaskID error.\n" unless $taskid =~ /^T\.\d{8}\.\d{6}\.\d{6}\.\d{3}\.\d{3}$/;
    my $res = $this->_rcall( undef,
        code => 'antdencli',
        argv => +{
            ctrl => 'taskinfo',
            conf => +{
                taskid => $taskid
            }
        }
    );

    my $task = eval{ YAML::XS::Load $res };
    die "call fail: $res $@\n" if $@;
    die "task no Hash" unless $task && ref $task eq 'HASH';
    return ( $task, 'scheduling' ) unless my $host = $task->{hostip};
    return ( $task, 'nofind ip' ) unless $host =~ /^\d+\.\d+\.\d+\.\d+$/;
    return ( $task, 'nofind status' ) unless $task->{status};
    my $x = "task status $task->{status}";
    if( grep{ $type eq $_ }qw( tail listoutput download ) )
    {
        return ( grep{ $task->{status} eq $_ } qw( running stoped ) ) ? ( $task, $x, $host ) : ( $task, $x );
    }
    die "task stoped.\n" if $task->{status} eq 'stoped';
    return ( $task->{status} eq 'running' ) ? ( $task, $x, $host ) : ( $task, $x );
}

sub _taskcall
{
    my ( $this, %run, $task, $mesg, $host, $omesg, $p, $i ) = splice @_;

    die "jobid undef" unless my $taskid = $run{jobid};
    $taskid .= '.001' if $taskid =~ s/^J/T/;

    for( 1 .. 900 )
    {
        last if $i++ > 60;
        ( $task, $mesg, $host ) = $this->_gethost( $taskid, $run{name} );
        last if $host;
        $omesg ||= $mesg;
        unless( $omesg eq $mesg )
        {
            $i = 1;$p = 0;
            print "\n";
        }
        print "\r[INFO]Pending... $i [$mesg]";
        $p ++;
        $omesg = $mesg;
        sleep 1;
    }
    print "\n" if $p;

    die "[INFO]Your task has been submitted, but it hasn't been run yet. Please check the log later.\n" unless $host;

    if ( $run{name} eq 'tail' )
    {
        print "[INFO]Go ...\n";
        exec $task->{executer} eq 'docker'
            ? "$this->{mt}/shellv2 -h '$host' --sudo root --cmd 'docker logs -f $taskid'"
            : "$this->{mt}/shellv2 -h '$host' --sudo root --cmd 'tail -F /opt/AntDen/logs/task/$taskid.log'";
    }
    elsif ( $run{name} eq 'top' )
    {
        exec $task->{executer} eq 'docker'
            ? "$this->{mt}/shellv2 -h '$host' --sudo root --cmd 'docker exec -it $taskid top'"
            : "$this->{mt}/shellv2 -h '$host' --sudo root --cmd top";
    }
    elsif ( $run{name} eq 'nvidia-smi' )
    {
        exec $task->{executer} eq 'docker'
            ? "$this->{mt}/shellv2 -h '$host' --sudo root --cmd 'docker exec -it $taskid bash -c \"watch nvidia-smi\"'"
            : "$this->{mt}/shellv2 -h '$host' --sudo root --cmd 'watch nvidia-smi'";
    }
    elsif ( $run{name} eq 'listoutput' )
    {
            my $res = $this->_rcall( $host,
                code => 'exec',
                argv => [ "cd /data/AntDen_output && ls -l $taskid/$run{listoutput}" ]
            );
            print $res;
            exit;
    }
    elsif ( $run{name} eq 'download' )
    {
        if( "$taskid/$run{download}" =~ /\/$/ )
        {
            my $uuid = time . '.'. sprintf "%012d", int rand 1000000000000;
            my ( $f, $t ) = ( "/data/AntDen_output/$taskid.$uuid.tar.gz", "$run{to}/_TEMP_$uuid.tar.gz" );
            my $res = $this->_rcall( $host,
                code => 'exec',
                argv => [ "cd '/data/AntDen_output/$taskid/$run{download}' && tar -zcf '$f' *" ]
            );
            die "load fail: $!" if system "$this->{mt}/load -h '$host' --sudo root  --sp '$f' --dp '$t'";
            die "untar fail: $!" if system "tar -zxvf '$t' -C $run{to}/";
            unlink $t;
            exit;
        }

        exec "$this->{mt}/load -h '$host' --sudo root  --sp '/data/AntDen_output/$taskid/$run{download}' --dp '$run{to}'";
    }
    else
    {
        exec $task->{executer} eq 'docker'
            ? "$this->{mt}/shellv2 -h '$host' --sudo root --cmd 'docker exec -it $taskid bash' --ictrl 0"
            : "$this->{mt}/shellv2 -h '$host' --sudo root";
    }
}

1;
