package MYDan::Project::Deploy::Ctrl;
use strict;
use warnings;
use Carp;
use YAML::XS;
use Data::UUID;
use File::Basename;
use Data::Dumper;

sub new
{
    my ( $class, %self ) = @_;

    confess "conf undef.\n" unless $self{conf} && ref $self{conf} eq 'HASH';
    map{ die "$_ undef" unless $self{conf}->{$_} }qw( link path repo version );
#    map{ $self{conf}{$_} .= $self{name} if $self{conf}{$_} =~ /\/$/ }qw( link path );

    my $tmp = $self{conf}{version};

    $self{conf}{repo} .= "/$tmp";
    
    $self{packtype} = $tmp =~ s/\.tar\.gz$// ? 'tar.gz' : $tmp =~ s/\.tar$// ? 'tar' : 'raw';
    $self{datatype} = $tmp =~ /\.patch$/ ? 'patch' : $tmp =~ /\.inc$/ ? 'inc' : 'full';

    $self{currpath} = "$self{conf}{path}/$self{conf}{version}";

    bless \%self, ref $class || $class;
}

sub stage  
{
    my ( $this, %param ) = @_;
    my ( $conf, $currpath ) = @$this{qw( conf currpath )};
    my $repo = $conf->{repo};

    my ( $info, $succ ) = ( "$currpath/info", "$currpath/info/stage.succ" );

    return if -f "$currpath/pack" && -f $succ;

    $this->syscmd( 'stage' => "rm '$succ'" ) if -f $succ;
    $this->syscmd( 'stage' => "mkdir -p '$info'" ) unless -d $info; 

    my $limit = $param{mark} || $this->{limit};
    $limit = $limit ? "--limit-rate=${limit}k" : '';

    my( $old_md5, $old_file_md5 );
    my @try = ( split /\s+/, join " ",`cat '$currpath/pack.try'` ) if -f "$currpath/pack.try";
    if( @try > 3 ) { map{ unlink "$currpath/pack$_" if -f "$currpath/pack$_" }( '', '.md5', '.try' ); }

    if( -f "$currpath/pack.md5" )
    {
        $old_md5 = eval{ YAML::XS::LoadFile "$currpath/pack.md5" };
        unless( $old_md5 && $old_md5 =~ /^\w{32}$/ )
        {
            unlink "$currpath/pack.md5";
            $old_md5 = undef;
        }
    }

    if( -f "$currpath/pack" )
    {
        my $tmp_file_md5 = `md5sum '$currpath/pack'`;
        ( $old_file_md5 ) = split /\s+/, $tmp_file_md5 if $tmp_file_md5;
        $old_file_md5 = undef unless $old_file_md5 && $old_md5 && $old_file_md5 eq $old_md5;
    }

    system "echo 'download' >> '$currpath/pack.try'";
    $this->syscmd( 'stage' => "wget -c -t 10 $limit -q -O '$currpath/pack.md5' '$repo.md5'" ) unless $old_md5;
    $this->syscmd( 'stage' => "wget -c -t 10 $limit -q -O '$currpath/pack' '$repo'" ) unless $old_file_md5;

    my $m1 = eval{ YAML::XS::LoadFile "$currpath/pack.md5" };
    die "md5 file error" unless $m1 && $m1 =~ /^\w{32}$/;
    die "md5sum '$currpath/pack' fail" unless my $md5 = `md5sum '$currpath/pack'`;
    my ( $m2 ) = split /\s+/, $md5;
    die "md5 nomatch" unless $m1 && $m2 && $m1 eq $m2;

    $this->syscmd( 'stage' => "touch '$succ'" );
}

sub explain
{
    my ( $this, %param ) = @_;
    my ( $conf, $currpath, $packtype, $datatype )= @$this{qw( conf currpath packtype datatype )};
    my ( $repo, $path, $link, $version ) = @$conf{qw( repo path link version )};

    my @try = ( split /\s+/, join " ",`cat '$currpath/explain.try'`  ) if -f "$currpath/explain.try";
    if( @try > 3 ) { map{ unlink "$currpath/$_" if -f "$currpath/$_" }( 'pack', 'pack.md5', 'pack.try', 'explain.try', 'info/stage.succ' ); }

    $this->stage( %param, mark => undef )
        unless -f "$currpath/pack" && -f "$currpath/info/stage.succ";

    my ( $succ, $uuid )= ( "$currpath/info/explain.succ", Data::UUID->new->create_str() );

    eval{ YAML::XS::DumpFile "$currpath/data/.deploy_uuid", $uuid } 
        if $datatype eq 'full' && -d "$currpath/data" && ! -f "$currpath/data/.deploy_uuid";

    die "[explain] dump uuid to '$currpath/data/.deploy_uuid' fail: $@\n" if $@;
 
    return if -f $succ && -d "$currpath/data";

    $this->syscmd( 'explain' => "rm -f '$succ'") if -f $succ;

    $this->syscmd( 'explain' => "mkdir -p '$currpath/data'") unless -d "$currpath/data";
    my $opt = ( $packtype eq 'tar.gz' ||  $packtype eq 'raw' ) ? 'z' : '';

    system "echo 'explain' >> '$currpath/explain.try'";

    $datatype eq 'patch' && $packtype eq 'raw'
        ? $this->syscmd( 'explain' => "rsync '$currpath/pack' '$currpath/data/patch'")
        : $this->syscmd( 'explain' => "tar -${opt}xvf '$currpath/pack' -C '$currpath/data'");

    eval{ YAML::XS::DumpFile "$currpath/data/.deploy_uuid", $uuid }
        if $datatype eq 'full' && -d "$currpath/data" && !-f "$currpath/data/.deploy_uuid";
    die "[explain] dump uuid to '$currpath/data/.deploy_uuid' fail: $@\n" if $@;

    $this->syscmd( 'explain' => "touch '$succ'");
}

sub deploy
{
    my ( $this, %param ) = @_;
    my ( $conf, $currpath, $packtype, $datatype )= @$this{qw( conf currpath packtype datatype )};
    my ( $repo, $path, $link, $version ) = @$conf{qw( repo path link version )};

    my $count = $param{mark} || $this->{keep};
    $count ||= 5;

    $this->explain( %param, mark => undef ) if ! -f "$currpath/info/explain.succ" 
         || ! -e "$currpath/data" 
         || ( $datatype eq 'full' && ! -f "$currpath/data/.deploy_uuid" );

    $this->syscmd( 'deploy' => "touch '$currpath/info/$datatype'") unless -f "$currpath/info/$datatype";

    my $currlink = readlink $link;

    if( $datatype eq 'full' )
    {
         my $rollback = "$currpath/info/rollback";
         my $rolllink = readlink $rollback;

         $this->syscmd( 'deploy' => "mv '$link' '$link.old.nices'" ) if -d $link && ! -l $link && ! -e "$link.old.nices";
         $this->syscmd( 'deploy' => "ln -fsn '$link.old.nices' '$link'" ) if ! -l $link && -d "$link.old.nices" && ! -l "$link.old.nices";
        
         
	 $currlink = readlink $link unless $currlink;

         $this->syscmd( 'deploy' => "ln -fsn '$currlink' '$rollback'" )
             if $currlink && (( $rolllink && $rolllink ne $currlink && $currlink ne "$currpath/data" ) || !$rolllink );
         my $dirname = dirname $link;
         $this->syscmd( 'deploy' => "mkdir -p '$dirname'" ) unless -e $dirname;
         $this->syscmd( 'deploy' => "ln -fsn '$currpath/data' '$link'" )
             unless $currlink && $currlink eq "$currpath/data";
    }
    else
    {
        die "The current full package does not take effect\n" unless $currlink && -d $currlink;
        
        my $uuid = eval{ YAML::XS::LoadFile "$currlink/.deploy_uuid" } if -f "$currlink/.deploy_uuid";
        die "[deploy] load full uuid fail: $@" if $@;
        die "Did not find deployid\n" unless $uuid && $uuid =~ /^[\w-]+$/;

        my $privatepath = "$currpath/info/$uuid";
        unless( -f "$privatepath/done" )
        {
	    $this->syscmd( 'deploy' => "mkdir -p '$privatepath/backup'") unless -d "$privatepath/backup";

            if( $datatype eq 'patch' )
            {
                die "nofind file: $currpath/data/patch\n" unless -f "$currpath/data/patch";
                $this->syscmd( 'deploy' => "patch -f -p1 --dry-run < '$currpath/data/patch'");
                $this->syscmd( 'deploy' => "patch -f -p1 < '$currpath/data/patch'");
            } 
            else
            {
                $this->syscmd( 'deploy' => "rsync -a -b --backup-dir '$privatepath/backup' '$currpath/data/' '$currlink/'");
            }
	    $this->syscmd( 'deploy' => "touch '$privatepath/done'");
        }
    }


    my %path = map{ $_ => ( stat $_ )[10] }glob "$path/*/info/$datatype";

    delete $path{"$currpath/info/$datatype"};
    my @path = sort{ $path{$a} <=> $path{$b} }keys %path;
    while( @path > $count )
    {
        my $p = shift @path;
        $p =~ s#/info/$datatype$##;
        $this->syscmd( 'deploy' => "rm -rf '$p'");
    }

};

sub rollback
{
    my ( $this, %param ) = @_;
    my ( $conf, $currpath, $packtype, $datatype )= @$this{qw( conf currpath packtype datatype )};
    my ( $repo, $path, $link, $version ) = @$conf{qw( repo path link version )};

    my $currlink = readlink $link;

    if( $datatype eq 'full' )
    {
         my ( $currlink, $rolllink )= map{ readlink $_ }( $link, "$currpath/info/rollback" );
         die "no rollback data\n" unless $rolllink && -e $rolllink;

         $this->syscmd( 'deploy' => "ln -fsn '$rolllink' '$link'" )
             unless $currlink && $currlink eq $rolllink;
        
         $this->syscmd( 'deploy' => "rm -f '$link' && mv '$rolllink' '$link'" ) 
             if $rolllink eq "$link.old.nices" && -d "$link.old.nices" && ! -l "$link.old.nices";
    }
    else
    {
        die "The current full package does not take effect\n" unless $currlink && -d $currlink;

        my $uuid = eval{ YAML::XS::LoadFile "$currlink/.deploy_uuid" } if -f "$currlink/.deploy_uuid";
        die "[rollback] load uuid fail: $@\n" if $@;
        die "Did not find deployid\n" unless $uuid && $uuid =~ /^[\w-]+$/;

        my $privatepath = "$currpath/info/$uuid";
        die "no the backup to rollback\n" unless -f "$privatepath/done";
        if( $datatype eq 'patch' )
        {
            die "nofind file: $currpath/data/patch\n" unless -f "$currpath/data/patch";
            $this->syscmd( 'deploy' => "patch -f -R -p1 --dry-run < '$currpath/data/patch'");
            $this->syscmd( 'deploy' => "patch -f -R -p1 < '$currpath/data/patch'");
        }
        else
        {
            $this->syscmd( 'deploy' => "rsync -a '$privatepath/backup/' '$path/data/'");
        }
	$this->syscmd( 'deploy' => "rm -rf '$privatepath'");

    }
}

sub show
{
    my ( $this, %param ) = @_;
    my ( $conf, $packtype, $datatype )= @$this{qw( conf packtype datatype )};
    my ( $repo, $path, $link, $version ) = @$conf{qw( repo path link version )};


    my ( @pack, %data ) = glob "$path/*";

    if( $data{current} = readlink $link )
    {
        $data{rollback} = readlink "$data{current}/../info/rollback";
        $data{rollback} = $data{rollback} 
            ? -e $data{rollback} ? $data{rollback} : "nvalid link":"no link";

        if( $datatype eq 'patch' || $datatype eq 'inc' )
        {
            my $uuid = eval{ YAML::XS::LoadFile "$data{currlink}/.deploy_uuid" } if -f "$data{currlink}/.deploy_uuid";
            die "[show] load uuid fail: $@\n" if $@;
            unless( $uuid && $uuid =~ /^[\w-]+$/ )
            {
                $data{error} = "Did not find uuid";
            }
            else
            {
                $data{$datatype} = -f "$path/info/$uuid/done"
                    ? "$datatype is in effect" : "$datatype is not used";
            }
        }
    }
    else { $data{error} = "Current link is empty"; }

    map{ print "$_: $data{$_}\n" if $data{$_}; }qw( current rollback patch inc error );
    map{ printf "package: %s\n", basename $_; }@pack;
};

our %ctrl =
(
    stage => sub { shift->stage(@_); },
    explain => sub { shift->explain(@_); },
    deploy => sub { shift->deploy(@_); },
    rollback => sub { shift->rollback(@_); },
    show => sub { shift->show(@_); },
);

sub do
{
    my ( $this, @ctrl ) = @_;
    my $conf = $this->{conf};

    print( YAML::XS::Dump $conf ) and return unless @ctrl;

    for my $ctrl ( @ctrl )
    {
        my $mark; ( $ctrl, $mark ) = ( $1, $2 ) if $ctrl =~ /^(.+):(\d+)$/;
        die "no command $ctrl\n" unless $ctrl{$ctrl};
        &{$ctrl{$ctrl}}( $this, mark => $mark );
    }
    return 0;
}

sub syscmd
{
    my ( $this, $ctrl ) = splice @_, 0, 2;
    print( join( " ", "[$ctrl]:", @_ ), "\n" );# if $this->{verbose};
    return system( @_ ) ? die "run $ctrl ERROR\n" : $this;
}

1;
__END__
