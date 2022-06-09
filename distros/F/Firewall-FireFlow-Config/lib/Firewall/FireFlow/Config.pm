package Firewall::FireFlow::Config;

# ABSTRACT: turns baubles into trinkets

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 加载项目模块
#------------------------------------------------------------------------------
use Firewall::DBI::Pg;
use Firewall::Policy::Searcher;
use Firewall::Policy::Designer;
use Firewall::FireFlow::Config::Srx;
use Firewall::FireFlow::Config::Asa;
use Firewall::FireFlow::Config::Netscreen;
use Firewall::FireFlow::Config::Fortinet;
use Firewall::FireFlow::Config::H3c;
use Firewall::FireFlow::Config::Huawei;
use Firewall::FireFlow::Config::Hillstone;
use Firewall::FireFlow::Config::Topsec;
use Firewall::FireFlow::Config::Neteye;

#------------------------------------------------------------------------------
# 加载项目模块
#------------------------------------------------------------------------------
sub configFw {
  my ( $self, $src, $dst, $srv ) = @_;
  my $commandInfo = $self->getCommands( $src, $dst, $srv );
  return {success => 1, reason => "Do not need any config"} unless @{$commandInfo};
  my @result;
  for my $fw ( @{$commandInfo} ) {
    my $fwType = $fw->{fwType};
    my $config;
    try {
      \$config = "Firewall::FireFlow::Config::$fwType->new";
    }
    catch {
      confess;
    };

    #eval("\$config = Firewall::FireFlow::Config::$fwType->new;");
    #confess $@ if $@;
    my $ip         = $fw->{ip};
    my $connection = $config->connect( $ip, 'SolarwindCM', 'Dwl559tel' );
    my $execResult = $config->execCommands( $connection, $fw->{commands} );
    push @result, $execResult;
    system("/wls/firewall_manager/script/updateConf.pl -i $fw->{fwId} -m prd &");
  }
  return \@result;
} ## end sub configFw

#------------------------------------------------------------------------------
# 加载项目模块
#------------------------------------------------------------------------------
sub getCommands {
  my ( $self, $src, $dst, $srv ) = @_;
  my $dbi = Firewall::DBI::Oracle->new(
    dsn      => 'dbi:Oracle:host=ifsps.db.paic.com.cn;sid=ifsps;port=1534',
    user     => 'FWMSdata',
    password => 'CjN618thb'
  );
  $dbi->dbi->dbh->{LongReadLen} = 70_000_000;
  my @fwCommands;
  my $searcher       = Firewall::Policy::Searcher->new( dbi => $dbi );
  my $searcherReport = $searcher->search( {src => $src, dst => $dst, srv => $srv} );
  if ( $searcherReport->state == 0 ) {
    my $comment = $searcherReport->comment;
    $comment =~ s/(.+?)\s*at\s+.+/$1/s;
    return $comment;
  }
  my $designer    = Firewall::Policy::Designer->new( searcherReport => $searcherReport, dbi => $dbi );
  my $designInfos = $designer->design;
  for my $designInfo ( @{$designInfos} ) {
    next if $designInfo->{policyState} eq 'allExist';
    my %fwCommand;
    $fwCommand{fwType} = $designInfo->{fwType};
    my $fwName = $designInfo->{fwName};
    my $ip;
    if ( $fwName =~ /.+\((?<ip>.+)\)\s*/ ) {
      $ip = $+{ip};
    }
    $fwCommand{ip}   = $ip;
    $fwCommand{fwId} = $designInfo->{fwId};
    my @commands;
    my $policyContents = $designInfo->{policyContents};
    for my $commandinfo ( @{$policyContents} ) {
      if ( defined $commandinfo->{new}{content} and $commandinfo->{new}{content} ne '' ) {
        for ( split( '\n', $commandinfo->{new}{content} ) ) {
          push @commands, $_;
        }
      }
    }
    $fwCommand{commands} = \@commands;
    push @fwCommands, \%fwCommand;
  } ## end for my $designInfo ( @{...})

  return \@fwCommands;
} ## end sub getCommands

__PACKAGE__->meta->make_immutable;
1;
