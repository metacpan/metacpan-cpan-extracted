# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::Accesslog;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);

our $VERSION = 0.995;

use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
        
    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we only use the template and database module
    return;
}

sub register {
    my $self = shift;
    
    $self->register_prefilter("prefilter");
    $self->register_postfilter("postfilter");
    return;
}


sub prefilter {
    my ($self, $cgi) = @_;
    
    my $webpath = $cgi->path_info() || '--unknown--';
    
    my @params = $cgi->param;
    my $paramlist = "";
    foreach my $param (@params) {
        my $val = $cgi->param($param);
        if($param eq "password") {
            $val = "****";
        }
        $paramlist .= "$param=$val;";
    }
    my $host = $cgi->remote_addr() || '--unknown--';
    my $method = $cgi->request_method() || '--unknown--';
    
    my %requestdata = (
        url     => $webpath,
        method  => $method,
        parameters  => $paramlist,
        remotehost    => $host,
    );
    
    
    $self->{requestdata} = \%requestdata;
    return;
    
}
sub postfilter {
    my ($self, $cgi, $header, $result) = @_;
    
    return if(!defined($self->{requestdata}));
    my %requestdata = %{$self->{requestdata}};
    
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $auth = $self->{server}->{modules}->{$self->{login}};
    
    
    $requestdata{username} = "";
    if(defined($auth->{currentData}->{user})) {
        $requestdata{username} = $auth->{currentData}->{user};
    } else {
        $requestdata{username} = '';
    }
    
    $requestdata{returncode} = $result->{status};
    $requestdata{doctype} = $result->{type};
    if(!defined($requestdata{doctype}) || $requestdata{doctype} eq '') {
        $requestdata{doctype} = '--unknown--';
    }
    
    my $stmt = "INSERT INTO accesslog (url, method, parameters, remotehost, username, returncode, doctype)
                VALUES (?,?,?,?,?,?,?)";
    my $sth = $dbh->prepare_cached($stmt) or croak($dbh->errstr);
    $sth->execute($requestdata{url},
                  $requestdata{method},
                  $requestdata{parameters},
                  $requestdata{remotehost},
                  $requestdata{username},
                  $requestdata{returncode},
                  $requestdata{doctype},
                  )
            or croak($dbh->errstr);
    $dbh->commit;
    
    delete $self->{requestdata};
    
    return;
}

1;
__END__

=head1 NAME

Maplat::Web::Accesslog - log all access to the webgui

=head1 SYNOPSIS

This module logs all access to the webgui to the database.

=head1 DESCRIPTION

Log all access to database (similar to the file-based apache log files). Please
make sure you use according to local law.

=head1 Configuration

    <module>
        <modname>accesslog</modname>
        <pm>Accesslog</pm>
        <options>
            <memcache>memcache</memcache>
            <db>maindb</db>
            <login>authentification</login>
        </options>
    </module>


=head2 prefilter

Internal function.

=head2 postfilter

Internal function.

=head1 SEE ALSO

Maplat::Web

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
