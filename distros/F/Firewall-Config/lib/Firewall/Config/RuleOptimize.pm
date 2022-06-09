package Firewall::Config::RuleOptimize;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use JSON;
use POSIX;

#------------------------------------------------------------------------------
# 加载项目模块
#------------------------------------------------------------------------------
use Firewall::DBI::Pg;
use Firewall::Utils::Ip;
use Firewall::Utils::Set;
use Firewall::Config::Dao::Parser;

#------------------------------------------------------------------------------
# 数据库联结插件
#------------------------------------------------------------------------------
has dbi => ( is => 'ro', does => 'Firewall::DBI::Role', );

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
sub optimizeRule {
  my ( $self, $fwId ) = @_;
  my $dao    = Firewall::Config::Dao::Parser->new( dbi => $self->dbi );
  my $parser = $dao->loadParser($fwId);
  my $class  = ref($parser);
  eval("use $class");
  confess $@ if !!$@;

  my @rules  = values %{$parser->{elements}->{rule}};
  my $length = @rules;
  my %result;

  for ( my $i = 0; $i < $length; $i++ ) {
    next if $rules[$i]->{isDisable} eq 'disable';
    for ( my $j = $i + 1; $j < $length; $j++ ) {
      next if $rules[$j]->{isDisable} eq 'disable';
      if ( !( $rules[$i]->{fromZone} eq $rules[$j]->{fromZone} and $rules[$i]->{toZone} eq $rules[$j]->{toZone} ) ) {
        next;
      }

      my $src     = $rules[$i]->{srcAddressGroup}->range->compare( $rules[$j]->srcAddressGroup->range );
      my $dst     = $rules[$i]->dstAddressGroup->range->compare( $rules[$j]->dstAddressGroup->range );
      my $srvSet1 = $self->getSrvSet( $rules[$i]->serviceGroup->dstPortRangeMap );
      my $srvSet2 = $self->getSrvSet( $rules[$j]->serviceGroup->dstPortRangeMap );
      my $srv     = $srvSet1->compare($srvSet2);
      my $states  = {equal => [], containButNotEqual => [], belongButNotEqual => [], other => []};
      push @{$states->{$src}}, 'src';
      push @{$states->{$dst}}, 'dst';
      push @{$states->{$srv}}, 'srv';

      if ( @{$states->{equal}} + @{$states->{containButNotEqual}} == 3 ) {
        push @{$result{$rules[$i]->{sign}}{contain}}, $rules[$j]->{sign};
      }
      elsif ( @{$states->{equal}} + @{$states->{belongButNotEqual}} == 3 ) {
        push @{$result{$rules[$j]->{sign}}{contain}}, $rules[$i]->{sign};
      }
      elsif ( @{$states->{equal}} == 2 ) {
        push @{$result{$rules[$i]->{sign}}{combine}}, $rules[$j]->{sign};
      }
    }
  }

  my $params;
  for my $rule ( keys %result ) {
    my @rule;
    push @rule, $parser->fwId;
    push @rule, $rule;
    for my $element ( keys %{$result{$rule}} ) {
      my @subRule = (@rule);
      push @subRule,   $element;
      push @subRule,   encode_json $result{$rule}{$element};
      push @{$params}, \@subRule;
    }
  }
  $self->dbi->delete( where => {fw_id => $parser->fwId}, table => "fw_rule_optimize" );
  my $sql = "INSERT INTO fw_rule_optimize (fw_id,rule_id_name,optimize,other_rule) VALUES (?,?,?,?)";
  $self->dbi->batchExecute( $params, $sql );
  $sql = "UPDATE fw_info SET optistatus=0 WHERE fw_id = $fwId";
  $self->dbi->execute($sql);
  return {success => 1};
}

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
sub getSrvSet {
  my ( $self, $portMap ) = @_;
  my $retSet = Firewall::Utils::Set->new;

  for my $proto ( keys %{$portMap} ) {
    if ( $proto eq '0' or $proto =~ /any/i ) {
      return Firewall::Utils::Set->new( 0, 16777215 );
    }
    elsif ( $proto =~ /tcp|udp|icmp|\d+/i ) {
      my $protoNum;
      if ( $proto =~ /tcp/i ) {
        $protoNum = 6;
      }
      elsif ( $proto =~ /udp/i ) {
        $protoNum = 17;
      }
      elsif ( $proto =~ /icmp/i ) {
        $protoNum = 1;
      }
      elsif ( $proto =~ /\d+/i ) {
        $protoNum = $proto;
      }

      my $min     = ( $protoNum << 16 );
      my $tempSet = Firewall::Utils::Set->new;
      $tempSet->mergeToSet( $portMap->{$proto} );
      for ( my $i = 0; $i < $tempSet->length; $i++ ) {
        $tempSet->mins->[$i] += $min;
        $tempSet->maxs->[$i] += $min;
      }
      $retSet->mergeToSet($tempSet);
    }
  }
  return $retSet;
}

__PACKAGE__->meta->make_immutable;
1;

