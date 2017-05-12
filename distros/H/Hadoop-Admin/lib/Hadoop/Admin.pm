use strict;
package Hadoop::Admin;
{
  $Hadoop::Admin::VERSION = '0.4';
}
use warnings;
use Moose;
use LWP::UserAgent;
use JSON -support_by_pp;

has 'namenode' => (
    is  => 'ro',
    isa => 'Str',
    reader => 'get_namenode',
    predicate => 'has_namenode',
    );

has 'namenode_port' => (
    is      => 'ro',
    isa     => 'Int',
    default => '50070',
    reader  => 'get_namenode_port',
    predicate => 'has_namenode_port',
    );

has 'jobtracker' => (
    is  => 'ro',
    isa => 'Str',
    reader => 'get_jobtracker',
    predicate => 'has_jobtracker',
    );

has 'jobtracker_port' => (
    is      => 'ro',
    isa     => 'Int',
    default => '50030',
    reader  => 'get_jobtracker_port',
    predicate => 'has_jobtracker_port',
    );

has 'secondarynamenode' => (
    is  => 'ro',
    isa => 'Str',
    reader => 'get_secondarynamenode',
    predicate => 'has_secondarynamenode',
    );

has 'resourcemanager' => (
    is  => 'ro',
    isa => 'Str',
    reader => 'get_resourcemanager',
    predicate => 'has_resourcemanager',
    );

has 'resourcemanager_port' => (
    is      => 'ro',
    isa     => 'Int',
    default => '8088',
    reader  => 'get_resourcemanager_port',
    predicate => 'has_resourcemanager_port',
    );

has 'socksproxy' => (
    is  => 'ro',
    isa => 'Str',
    reader => 'get_socksproxy',
    predicate => 'has_socksproxy',
    );

has 'socksproxy_port' => (
    is      => 'ro',
    isa     => 'Int',
    default => '1080',
    reader  => 'get_socksproxy_port',
    predicate => 'has_socksproxy_port',
    );

has 'ua' => (
    is  => 'rw',
    isa => 'Object',
    predicate => 'has_ua',
    );

has '_test_namenodeinfo' => (
    is  => 'ro',
    isa => 'Str',
    );

has '_test_jobtrackerinfo' => (
    is  => 'ro',
    isa => 'Str',
    );

has '_test_resourcemanagerinfo' => (
    is  => 'ro',
    isa => 'Str',
    );

# ABSTRACT: Module for administration of Hadoop clusters


sub BUILD{

    my $self=shift;

    if ( $self->has_resourcemanager && $self->has_jobtracker ){
	die "Can't have both ResourceManager and JobTracker\n";
    }

    $self->ua(new LWP::UserAgent());
    if ( defined $self->get_socksproxy ){
	$self->ua->proxy([qw(http https)] => 'socks://'.$self->get_socksproxy.':1080');
    }
    ## Hooks for testing during builds.  Doesn't connect to a real cluster.
    if ( defined $self->_test_namenodeinfo ){
	my $test_nn_string;
	{
	    local $/=undef;
	    open (my $fh, '<', $self->_test_namenodeinfo) or die "Couldn't open file: $!";
	    $test_nn_string = <$fh>;
	    close $fh;
	}
	$self->parse_nn_jmx($test_nn_string);
    }else{
	if ( defined $self->get_namenode ){
	    $self->gather_nn_jmx('NameNodeInfo');
	}
    }
    ## Hooks for testing during builds.  Doesn't connect to a real cluster.
    if ( defined $self->_test_jobtrackerinfo ){
	my $test_jt_string;
	{
	    local $/=undef;
	    open(my $fh, '<', $self->_test_jobtrackerinfo) or die "Couldn't open file: $!";
	    $test_jt_string = <$fh>;
	    close $fh;
	}
	$self->parse_jt_jmx($test_jt_string);
    }else{
	if ( defined $self->get_jobtracker ){
	    $self->gather_jt_jmx('JobTrackerInfo');
	}
    }
    
    ## Hooks for testing during builds.  Doesn't connect to a real cluster.
    if ( defined $self->_test_resourcemanagerinfo ){
	my $test_rm_string;
	{
	    local $/=undef;
	    open(my $fh, '<', $self->_test_resourcemanagerinfo) or die "Couldn't open file: $!";
	    $test_rm_string = <$fh>;
	    close $fh;
	}
	$self->parse_rm_jmx($test_rm_string);
    }else{
	if ( defined $self->get_resourcemanager ){
	    $self->gather_rm_jmx('RMNMInfo');
	}
    }
    
    return $self;
}

sub datanode_live_list{
    my $self=shift;
    return keys %{$self->{'NameNodeInfo_LiveNodes'}};
}

sub datanode_dead_list{
    my $self=shift;
    return keys %{$self->{'NameNodeInfo_DeadNodes'}};
}

sub datanode_decom_list{
    my $self=shift;
    return keys %{$self->{'NameNodeInfo_DecomNodes'}};
}


sub nodemanager_live_list{
    my $self=shift;
    my @returnValue=();
    foreach my $hostref ( @{$self->{'RMNMInfo_LiveNodeManagers'}} ) {
	push @returnValue, $hostref->{'HostName'};
    }
    return @returnValue;
}

sub tasktracker_live_list{
    my $self=shift;
    my @returnValue=();
    use Data::Dumper;
    foreach my $hostref ( @{$self->{'JobTrackerInfo_AliveNodesInfoJson'}} ) {
	push @returnValue, $hostref->{'hostname'};
    }
    return @returnValue;
}

sub tasktracker_blacklist_list{
    my $self=shift;
    my @returnValue=();
    foreach my $hostref ( @{$self->{'JobTrackerInfo_BlacklistedNodesInfoJson'}} ) {
	push @returnValue, $hostref->{'hostname'};
    }
    return @returnValue;
}

sub tasktracker_graylist_list{
    my $self=shift;
    my @returnValue=();
    foreach my $hostref ( @{$self->{'JobTrackerInfo_BlacklistedNodesInfoJson'}} ) {
	push @returnValue, $hostref->{'hostname'};
    }
    return @returnValue;
}

sub gather_nn_jmx{
    my $self=shift;
    my $bean=shift;
    my $qry;
    if ($bean eq 'NameNodeInfo'){
	$qry='Hadoop%3Aservice%3DNameNode%2Cname%3DNameNodeInfo';
    }
    my $jmx_url= "http://".$self->get_namenode.":".$self->get_namenode_port."/jmx?qry=$qry";
    my $response = $self->{'ua'}->get($jmx_url);
    if (! $response->is_success) {
	print "Can't get JMX data from Namenode: $@";
	exit(1);
    }
    $self->parse_nn_jmx($response->decoded_content);
}

sub parse_nn_jmx{
    my $self=shift;
    my $nn_content=shift;
    my $json=new JSON();
    my $json_text = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->pretty->decode($nn_content);
    foreach my $bean (@{$json_text->{beans}}){
	if ($bean->{name} eq "Hadoop:service=NameNode,name=NameNodeInfo"){
	    foreach my $var (keys %{$bean}){
		$self->{"NameNodeInfo_$var"}=$bean->{$var};
	    }
	    $self->{'NameNodeInfo_LiveNodes'}=$json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->pretty->decode($bean->{LiveNodes});
	    $self->{'NameNodeInfo_DeadNodes'}=$json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->pretty->decode($bean->{DeadNodes});
	    $self->{'NameNodeInfo_DecomNodes'}=$json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->pretty->decode($bean->{DecomNodes});
	}
	
    }
}

sub gather_jt_jmx{
    my $self=shift;
    my $bean=shift;
    my $qry;
    if ($bean eq "JobTrackerInfo"){
	$qry='Hadoop%3Aservice%3DJobTracker%2Cname%3DJobTrackerInfo';
    }
    my $jmx_url= "http://".$self->get_jobtracker.":".$self->get_jobtracker_port."/jmx?qry=$qry";
    my $response = $self->{'ua'}->get($jmx_url);
    if (! $response->is_success) {
	print "Can't get JMX data from JobTracker: $@";
	exit(1);
    }
    $self->parse_jt_jmx($response->decoded_content);

}

sub parse_jt_jmx{
    my $self=shift;
    my $jt_content=shift;
    my $json=JSON->new();
    my $json_text = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->pretty->decode($jt_content);
    foreach my $bean (@{$json_text->{beans}}){
	foreach my $var (keys %{$bean}){
	    $self->{"JobTrackerInfo_$var"}=$bean->{$var};
	}
	if ($bean->{name} eq "Hadoop:service=JobTracker,name=JobTrackerInfo"){
	    $self->{'JobTrackerInfo_AliveNodesInfoJson'}=$json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->pretty->decode($bean->{AliveNodesInfoJson});
	    $self->{'JobTrackerInfo_BlacklistedNodesInfoJson'}=$json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->pretty->decode($bean->{BlacklistedNodesInfoJson});
	    $self->{'JobTrackerInfo_GraylistedNodesInfoJson'}=$json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->pretty->decode($bean->{GraylistedNodesInfoJson});
	}
	
    }
}
sub gather_rm_jmx{
    my $self=shift;
    my $bean=shift;
    my $qry;
    if ($bean eq "RMNMInfo"){
	$qry='Hadoop%3Aservice%3DResourceManager%2Cname%3DRMNMInfo';
    }
    my $jmx_url= "http://".$self->get_resourcemanager.":".$self->get_resourcemanager_port."/jmx?qry=$qry";
    my $response = $self->{'ua'}->get($jmx_url);
    if (! $response->is_success) {
	print "Can't get JMX data from ResourceManager: $@";
	exit(1);
    }
    $self->parse_rm_jmx($response->decoded_content);
}

sub parse_rm_jmx{
    my $self=shift;
    my $rm_content=shift;
    my $json=JSON->new();
    my $json_text = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->pretty->decode($rm_content);
    foreach my $bean (@{$json_text->{beans}}){
	foreach my $var (keys %{$bean}){
	    $self->{"RMNMInfo_$var"}=$bean->{$var};
	}
	if ($bean->{name} eq "Hadoop:service=ResourceManager,name=RMNMInfo"){
	    $self->{'RMNMInfo_LiveNodeManagers'}=$json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->pretty->decode($bean->{LiveNodeManagers});
	}
	
    }
}

1;


__END__
=pod

=head1 NAME

Hadoop::Admin - Module for administration of Hadoop clusters

=head1 VERSION

version 0.4

=head1 SYNOPSIS

    use Hadoop::Admin; 

    my $cluster=Hadoop::Admin->new({
      'namenode'          => 'namenode.host.name',
      'jobtracker'        => 'jobtracker.host.name',
    });

    print $cluster->datanode_live_list();

=head1 DESCRIPTION

This module connects to Hadoop servers using http.  The JMX Proxy
Servlet is queried for specific mbeans.

This module requires Hadoop the changes in
https://issues.apache.org/jira/browse/HADOOP-7144.  They are available
in versions 0.20.204.0, 0.23.0 or later.

=head1 INTERFACE FUNCTIONS

=head2 new ()

=over 4

=item Description

Create a new instance of the Hadoop::Admin class.  

The method requires a hash containing at minimum one of the
namenode's, the resourcemanager's, and the jobtracker's hostnames.
Optionally, you may provide a socksproxy for the http connection.  Use
of both a jobtracker and resourcemanger is prohibited.  It is not a
valid cluster configuration to have both a jobtracker and a
resourcemanager.

Creation of this object will cause an immediate querry to servers
provided to the constructor.

=item namenode => <hostname>

=item namenode_port => <port number>

=item jobtracker => <hostname>

=item jobtracker_port => <port number>

=item resourcemanager => <hostname>

=item resourcemanager_port => <port number>

=item socksproxy => <hostname>

=item socksproxy_port => <port number>

=back

=head2 datanode_live_list ()

=over 4

=item Description

Returns a list of the current live DataNodes.

=item Return values

Array containing hostnames.

=back

=head2 datanode_dead_list ()

=over 4

=item Description

Returns a list of the current dead DataNodes.

=item Return values

Array containing hostnames.

=back

=head2 datanode_decom_list ()

=over 4

=item Description

Returns a list of the currently decommissioning DataNodes.

=item Return values

Array containing hostnames.

=back

=head2 nodemanager_live_list ()

=over 4

=item Description

Returns a list of the current live NodeManagers.

=item Return values

Array containing hostnames.

=back

=head2 tasktracker_live_list ()

=over 4

=item Description

Returns a list of the current live TaskTrackers.

=item Return values

Array containing hostnames.

=back

=head2 tasktracker_blacklist_list ()

=over 4

=item Description

Returns a list of the current blacklisted TaskTrackers.

=item Return values

Array containing hostnames.

=back

=head2 tasktracker_graylist_list ()

=over 4

=item Description

Returns a list of the current graylisted TaskTrackers.

=item Return values

Array containing hostnames.

=back

=head1 KNOWN BUGS

None known at this time.  Please log issues at: 

https://github.com/cwimmer/hadoop-admin/issues

=head1 AVAILABILITY

Source code is available on GitHub:

https://github.com/cwimmer/hadoop-admin

Module available on CPAN as Hadoop::Admin:

http://search.cpan.org/~cwimmer/

=for Pod::Coverage gather_jt_jmx
gather_nn_jmx
gather_rm_jmx
parse_jt_jmx
parse_nn_jmx
parse_rm_jmx
BUILD

=head1 AUTHOR

Charles A. Wimmmer (charles@wimmer.net)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Charles A. Wimmer.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

