# $Id: apache.pm,v 1.1.1.1 2000/12/14 16:41:42 lstein Exp $
package HTTPD::GroupAdmin::DBM::apache;
# Modified 10 Oct 1996, by Alex Wong <alexw@toolshed.org>
use Carp ();
use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(HTTPD::GroupAdmin::DBM);
$VERSION = (qw$Revision: 1.1.1.1 $)[1];

sub add {
    my($self,$uid,$group) = @_;
    local($HTTPD::GroupAdmin::DBM::DLM) = ",";
    $group ||= $self->{NAME};
    HTTPD::GroupAdmin::DBM::add($self,$group,$uid);
}

sub delete {
    my($self,$uid,$group) = @_;
    my $status;
    local($HTTPD::GroupAdmin::DBM::DLM) = ",";
    $group ||= $self->{NAME};
    $status = $self->{'_HASH'}{$uid} =~ s/\b$group\b//g;
    $self->{'_HASH'}{$uid} =~ s/,,+/,/g;
    $self->{'_HASH'}{$uid} =~ s/^,?(.*?),?$/$1/;
    delete $self->{'_HASH'}{$uid} unless $self->{'_HASH'}{$uid};
    $status;
}

sub remove {
    my($self,$group) = @_;
    my $user;
    my $result = 0;
    $group ||= $self->{NAME};

    foreach $user (keys %{$self->{'_HASH'}}) {
	next unless defined $self->{'_HASH'}{$user};

    	$result += $self->{'_HASH'}{$user} =~ s/\b$group\b//g;
    	$self->{'_HASH'}{$user} =~ s/,,+/,/g;
    	$self->{'_HASH'}{$user} =~ s/^,?(.*?),?$/$1/;
    }

    $result;
}

sub exists {
    my($self, $name, $user) = @_;
    return grep { $_ eq $user } $self->list($name) if $user;
    grep { $_ eq $name} $self->list;
}

sub list {
    my($self, $group) = @_;
    my %results;
    my $thisgroup;
    my $thisuser;

    if (defined($group) and $group ne '') {
	foreach $thisuser (keys %{$self->{'_HASH'}}) {
	    next unless $self->{'_HASH'}{$thisuser} =~ /\b$group\b/;
     	    $results{$thisuser} = '1';
    	}
    
    	return keys %results;

    } else {
	foreach $thisuser (keys %{$self->{'_HASH'}}) {
    	    foreach $thisgroup (split /,/, $self->{'_HASH'}{$thisuser}) {
		$results{$thisgroup} = '1';
	    }
    	}
    
    	return keys %results;
   
    }
}

sub rename {
    my($self,$group,$newname) = @_;
    my $user;
    my $result = 0;

    return 0 if $group eq '' or $newname eq '';

    foreach $user (keys %{$self->{'_HASH'}}) {
	next unless defined $self->{'_HASH'}{$user};

    	$result += $self->{'_HASH'}{$user} =~ s/\b$group\b/$newname/g;
    }

    $result;
}

1;


