# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::Errors;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;

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
    $self->register_webpath($self->{webpath}, "get");
    $self->register_defaultwebdata("get_defaultwebdata");
    return;
}

sub get {
    my ($self, $cgi) = @_;
    
    
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $th = $self->{server}->{modules}->{templates};
    
    # !!! Must work on form data before calling get_defaultwebdata, otherwise the header will be wrong
    my $mode = $cgi->param('mode') || 'view';
    if($mode ne "view") {
        my $command = "";
        
        my $delsth = $dbh->prepare_cached("DELETE FROM errors WHERE error_id = ? ");

        if($mode eq "ackerror"){
            my $error_id = $cgi->param('error_id') || '';
            if($error_id ne "") {
                $delsth->execute($error_id);
                $delsth->finish;
                $dbh->commit;
            }
        }
    }
    
    my %webdata = (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{pagetitle},
        PostLink        =>  $self->{webpath}
    );
    
    my $errsth = $dbh->prepare_cached("SELECT error_id, reporttime, error_type, description " .
                               "FROM errors " .
                               "WHERE error_type IN ('SAP_IN', 'SAP_OUT', 'COMMAND', 'REPORTS') " .
                               "ORDER BY reporttime"
                                )
                    or croak($dbh->errstr);
    my @errors;
    $errsth->execute or croak($dbh->errstr);
    while((my $errline = $errsth->fetchrow_hashref)) {
        $errline->{error_image} = "rbserror_" . lc($errline->{error_type}) . ".bmp";
        $th->hashquote($errline, qw[description]);
        push @errors, $errline;
    }
    $errsth->finish;
    $webdata{errors} = \@errors;
    
    $dbh->rollback;
    
    my $template = $self->{server}->{modules}->{templates}->get("errors", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

sub get_defaultwebdata {
    my ($self, $webdata) = @_;
    
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    
    my $stmt = "SELECT count(*) FROM errors " .
                "WHERE error_type IN ('SAP_IN', 'SAP_OUT', 'COMMAND', 'REPORTS')";
    
    my $sth = $dbh->prepare_cached($stmt) or croak($dbh->errstr);
    $sth->execute or croak($dbh->errstr);
    my $cnt = 0;
    while((my @line = $sth->fetchrow_array)) {
        $cnt = $line[0];
    }
    $sth->finish;
    $dbh->rollback;
    
    $webdata->{rbs_errorcount} = $cnt;
    return;
}

1;
__END__

=head1 NAME

Maplat::Web::Errors - limited view of the errors table

=head1 SYNOPSIS

This module provides a limited view of the errors table. This module is mostly deprecated, you
are recommended to use the newer "Status" module.

=head1 DESCRIPTION

This deprecated module is in use by some older projects. You should use the "Status" module instead.

=head1 Configuration

        <module>
                <modname>rbserrors</modname>
                <pm>Errors</pm>
                <options>
                        <pagetitle>Errors</pagetitle>
                        <webpath>/rbs/errors</webpath>
                        <db>maindb</db>
                        <memcache>memcache</memcache>
                </options>
        </module>

=head2 get

Handle the errors webmask.

=head1 Dependencies

This module depends on the following modules beeing configured (the 'as "somename"'
means the key name in this modules configuration):

Maplat::Web::Memcache as "memcache"
Maplat::Web::PostgresDB as "db"

=head1 SEE ALSO

Maplat::Web
Maplat::Web::SessionSettings
Maplat::Web::PostgresDB
Maplat::Web::Memcache
Maplat::Web::Status

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
