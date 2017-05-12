package Lim::Plugin::OpenDNSSEC::CLI;

use common::sense;

use Getopt::Long ();
use Scalar::Util qw(weaken);

use Lim::Plugin::OpenDNSSEC ();

use base qw(Lim::Component::CLI);

=encoding utf8

=head1 NAME

...

=head1 VERSION

See L<Lim::Plugin::OpenDNSSEC> for version.

=cut

our $VERSION = $Lim::Plugin::OpenDNSSEC::VERSION;

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 version

=cut

sub version {
    my ($self) = @_;
    my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
    
    weaken($self);
    $opendnssec->ReadVersion(sub {
        my ($call, $response) = @_;
        
        unless (defined $self) {
            undef($opendnssec);
            return;
        }
        
        if ($call->Successful) {
            $self->cli->println('OpenDNSSEC plugin version ', $response->{version});
            if (exists $response->{program}) {
                $self->cli->println('OpenDNSSEC programs:');
                foreach my $program (ref($response->{program}) eq 'ARRAY' ? @{$response->{program}} : $response->{program}) {
                    $self->cli->println('    ', $program->{name}, ' version ', $program->{version});
                }
            }
            $self->Successful;
        }
        else {
            $self->Error($call->Error);
        }
        undef($opendnssec);
    });
}

=head2 configs

=cut

sub configs {
    my ($self) = @_;
    my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
    
    weaken($self);
    $opendnssec->ReadConfigs(sub {
        my ($call, $response) = @_;
        
        unless (defined $self) {
            undef($opendnssec);
            return;
        }
        
        if ($call->Successful) {
            $self->cli->println('OpenDNSSEC config files found:');
            if (exists $response->{file}) {
                foreach my $file (ref($response->{file}) eq 'ARRAY' ? @{$response->{file}} : $response->{file}) {
                    $self->cli->println($file->{name},
                        ' (readable: ', ($file->{read} ? 'yes' : 'no'),
                        ' writable: ', ($file->{read} ? 'yes' : 'no'),
                        ')'
                        );
                }
            }
            $self->Successful;
        }
        else {
            $self->Error($call->Error);
        }
        undef($opendnssec);
    });
}

=head2 config

=cut

sub config {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);
    
    unless ($getopt and scalar @$args) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'view') {
        if (defined $args->[1]) {
            my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
            weaken($self);
            $opendnssec->ReadConfig({
                file => {
                    name => $args->[1]
                }
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{file}) {
                        foreach my $file (ref($response->{file}) eq 'ARRAY' ? @{$response->{file}} : $response->{file}) {
                            if (ref($response->{file}) eq 'ARRAY') {
                                $file->{content} =~ s/^/$file->{name}: /gm;
                                $self->cli->println($file->{content});
                            }
                            else {
                                $self->cli->println($file->{content});
                            }
                        }
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'edit') {
        if (defined $args->[1]) {
            my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
            weaken($self);
            $opendnssec->ReadConfig({
                file => {
                    name => $args->[1]
                }
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    my $w; $w = AnyEvent->timer(
                        after => 0,
                        cb => sub {
                            if (defined (my $content = $self->cli->Editor($response->{file}->{content}))) {
                                my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
                                $opendnssec->UpdateConfig({
                                    file => {
                                        name => $args->[1],
                                        content => $content
                                    }
                                }, sub {
                                    my ($call, $response) = @_;
                                    
                                    unless (defined $self) {
                                        undef($opendnssec);
                                        return;
                                    }
                                    
                                    if ($call->Successful) {
                                        $self->cli->println('Config updated');
                                        $self->Successful;
                                    }
                                    else {
                                        $self->Error($call->Error);
                                    }
                                    undef($opendnssec);
                                });
                            }
                            else {
                                $self->cli->println('Config not update, no change');
                                $self->Successful;
                            }
                            undef($w);
                        });
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    $self->Error;
}

=head2 start

=cut

sub start {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);

    unless ($getopt) {
        $self->Error;
        return;
    }

    if (!scalar @$args) {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateControlStart(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('OpenDNSSEC started');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'enforcer') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateControlStart({
            program => {
                name => 'enforcer'
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('OpenDNSSEC Enforcer started');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'signer') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateControlStart({
            program => {
                name => 'signer'
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('OpenDNSSEC Signer started');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    $self->Error;
}

=head2 stop

=cut

sub stop {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);

    unless ($getopt) {
        $self->Error;
        return;
    }

    if (!scalar @$args) {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateControlStop(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('OpenDNSSEC stopped');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'enforcer') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateControlStop({
            program => {
                name => 'enforcer'
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('OpenDNSSEC Enforcer stopped');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'signer') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateControlStop({
            program => {
                name => 'signer'
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('OpenDNSSEC Signer stopped');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    $self->Error;
}

=head2 setup

=cut

sub setup {
    my ($self) = @_;
    my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
    
    weaken($self);
    $opendnssec->CreateEnforcerSetup(sub {
        my ($call, $response) = @_;
        
        unless (defined $self) {
            undef($opendnssec);
            return;
        }
        
        if ($call->Successful) {
            $self->cli->println('OpenDNSSEC setup successful');
            $self->Successful;
        }
        else {
            $self->Error($call->Error);
        }
        undef($opendnssec);
    });
}

=head2 update

=cut

sub update {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);

    unless ($getopt) {
        $self->Error;
        return;
    }

    if (!scalar @$args or $args->[0] eq 'all') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateEnforcerUpdate(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('OpenDNSSEC Enforcer configuration updated');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    else {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateEnforcerUpdate({
            update => {
                section => $args->[0]
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('OpenDNSSEC Enforcer configuration "', $args->[0], '" updated');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    $self->Error;
}

=head2 zone

=cut

sub zone {
    my ($self, $cmd) = @_;
    my $xml = 1;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd,
        'xml!' => \$xml
    );

    unless ($getopt and scalar @$args) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'add' and scalar @$args == 6) {
        my (undef, $zone, $policy, $signerconf, $input, $output) = @$args;
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->CreateEnforcerZone({
            zone => {
                name => $zone,
                policy => $policy,
                signerconf => $signerconf,
                input => $input,
                output => $output,
                no_xml => $xml ? 0 : 1
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('Zone ', $zone, ' added');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'list') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->ReadEnforcerZoneList(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                if (exists $response->{zone}) {
                    $self->cli->println('OpenDNSSEC Enforcer Zone List:');
                    foreach my $zone (ref($response->{zone}) eq 'ARRAY' ? @{$response->{zone}} : $response->{zone}) {
                        $self->cli->println($zone->{name}, ' (policy ', $zone->{policy}, ')');
                    }
                }
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'delete' and scalar @$args == 2) {
        my (undef, $zone) = @$args;
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->DeleteEnforcerZone({
            zone => {
                name => $zone,
                no_xml => $xml ? 0 : 1
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('Zone ', $zone, ' deleted');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    $self->Error;
}

=head2 repository

=cut

sub repository {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);

    unless ($getopt) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'list') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->ReadEnforcerRepositoryList(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                if (exists $response->{repository}) {
                    $self->cli->println(join("\t", 'Name', 'Capacity', 'Require Backup'));
                    foreach my $repository (ref($response->{repository}) eq 'ARRAY' ? @{$response->{repository}} : $response->{repository}) {
                        $self->cli->println(join("\t",
                            $repository->{name},
                            $repository->{capacity},
                            $repository->{require_backup} ? 'Yes' : 'No'
                        ));
                    }
                }
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    $self->Error;
}

=head2 policy

=cut

sub policy {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);

    unless ($getopt) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'list') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->ReadEnforcerPolicyList(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                if (exists $response->{policy}) {
                    $self->cli->println(join("\t", 'Name', 'Description'));
                    foreach my $policy (ref($response->{policy}) eq 'ARRAY' ? @{$response->{policy}} : $response->{policy}) {
                        $self->cli->println(join("\t",
                            $policy->{name},
                            $policy->{description}
                        ));
                    }
                }
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'export') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @policies;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@policies, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->ReadEnforcerPolicyExport({
                policy => \@policies
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{policy}) {
                        foreach my $policy (ref($response->{policy}) eq 'ARRAY' ? @{$response->{policy}} : $response->{policy}) {
                            $self->cli->println('Policy export for policy ', $policy->{name});
                            $self->cli->println($policy->{kasp});
                        }
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->ReadEnforcerPolicyExport(sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{kasp}) {
                        $self->cli->println($response->{kasp});
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    $self->Error;
}

=head2 key

=cut

sub key {
    my ($self, $cmd) = @_;
    my $verbose = 0;
    my $keystate;
    my $keytype;
    my $ds = 0;
    my $cka_id;
    my $keytag;
    my $retire = 1;
    my $repository;
    my $bits;
    my $algorithm;
    my $time;
    my $retire_time;
    my $zone;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd,
        'verbose' => \$verbose,
        'keystate:s' => \$keystate,
        'keytype:s' => \$keytype,
        'ds' => \$ds,
        'cka_id:s' => \$cka_id,
        'keytag:s' => \$keytag,
        'retire!' => \$retire,
        'repository:s' => \$repository,
        'bits:i' => \$bits,
        'algorithm:s' => \$algorithm,
        'time:s' => \$time,
        'retire-time:s' => \$retire_time,
        'zone:s' => \$zone
    );

    unless ($getopt and scalar @$args >= 1) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'list') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @zones;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@zones, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->ReadEnforcerKeyList({
                verbose => $verbose ? 1 : 0,
                zone => \@zones
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{zone}) {
                        $self->cli->println(join("\t", 'Zone', 'Keytype', 'State', 'Next Transaction', ($verbose ? ('CKA_ID', 'Repository', 'Keytag') : ())));
                        foreach my $zone (ref($response->{zone}) eq 'ARRAY' ? @{$response->{zone}} : $response->{zone}) {
                            foreach my $key (ref($zone->{key}) eq 'ARRAY' ? @{$zone->{key}} : $zone->{key}) {
                                $self->cli->println(join("\t",
                                    $zone->{name},
                                    $key->{type},
                                    $key->{state},
                                    $key->{next_transaction},
                                    ($verbose ? (
                                        $key->{cka_id},
                                        $key->{repository},
                                        $key->{keytag}
                                    ) : ())
                                ));
                            }
                        }
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->ReadEnforcerKeyList({
                verbose => $verbose ? 1 : 0
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{zone}) {
                        $self->cli->println(join("\t", 'Zone', 'Keytype', 'State', 'Next Transaction', ($verbose ? ('CKA_ID', 'Repository', 'Keytag') : ())));
                        foreach my $zone (ref($response->{zone}) eq 'ARRAY' ? @{$response->{zone}} : $response->{zone}) {
                            foreach my $key (ref($zone->{key}) eq 'ARRAY' ? @{$zone->{key}} : $zone->{key}) {
                                $self->cli->println(join("\t",
                                    $zone->{name},
                                    $key->{type},
                                    $key->{state},
                                    $key->{next_transaction},
                                    ($verbose ? (
                                        $key->{cka_id},
                                        $key->{repository},
                                        $key->{keytag}
                                    ) : ())
                                ));
                            }
                        }
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'export') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @zones;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@zones, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->ReadEnforcerKeyExport({
                zone => \@zones,
                (defined $keystate ? (keystate => $keystate) : ()),
                (defined $keytype ? (keytype => $keytype) : ()),
                (defined $ds and $ds ? (ds => 1) : ()),
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{rr}) {
                        $self->cli->println(join("\t", 'Name', 'TTL', 'Class', 'Type', 'RDATA'));
                        foreach my $rr (ref($response->{rr}) eq 'ARRAY' ? @{$response->{rr}} : $response->{rr}) {
                            $self->cli->println(join("\t",
                                $rr->{name},
                                $rr->{ttl},
                                $rr->{class},
                                $rr->{type},
                                $rr->{rdata}
                                ));
                        }
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->ReadEnforcerKeyExport({
                (defined $keystate ? (keystate => $keystate) : ()),
                (defined $keytype ? (keytype => $keytype) : ()),
                (defined $ds and $ds ? (ds => 1) : ()),
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{rr}) {
                        $self->cli->println(join("\t", 'Name', 'TTL', 'Class', 'Type', 'RDATA'));
                        foreach my $rr (ref($response->{rr}) eq 'ARRAY' ? @{$response->{rr}} : $response->{rr}) {
                            $self->cli->println(join("\t",
                                $rr->{name},
                                $rr->{ttl},
                                $rr->{class},
                                $rr->{type},
                                $rr->{rdata}
                                ));
                        }
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'import' and defined $cka_id and defined $repository and defined $bits and defined $algorithm and defined $keystate and defined $keytype and defined $time and defined $zone) {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->CreateEnforcerKeyImport({
            key => {
                zone => $zone,
                cka_id => $cka_id,
                repository => $repository,
                bits => $bits,
                algorithm => $algorithm,
                keystate => $keystate,
                keytype => $keytype,
                time => $time,
                (defined $retire_time ? (retire => $retire_time) : ())
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('Key imported');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'rollover' and scalar @$args >= 2 and ($args->[1] eq 'zone' or $args->[1] eq 'policy')) {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 2) {
            my @names;
            my $skip = 2;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@names, {
                    name => $_,
                    (defined $keytype ? (keytype => $keytype) : ()),
                });
            }

            weaken($self);
            $opendnssec->UpdateEnforcerKeyRollover({
                $args->[1] eq 'zone' ? (zone => \@names) : (policy => \@names)
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Rollover issued');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'purge' and scalar @$args >= 2 and ($args->[1] eq 'zone' or $args->[1] eq 'policy')) {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 2) {
            my @names;
            my $skip = 2;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@names, {
                    name => $_,
                    (defined $keytype ? (keytype => $keytype) : ()),
                });
            }

            weaken($self);
            $opendnssec->DeleteEnforcerKeyPurge({
                $args->[1] eq 'zone' ? (zone => \@names) : (policy => \@names)
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{key}) {
                        $self->cli->println('Keys (CKA_ID) purged:');
                        foreach my $key (ref($response->{key}) eq 'ARRAY' ? @{$response->{key}} : $response->{key}) {
                            $self->cli->println($key->{cka_id});
                        }
                    }
                    else {
                        $self->cli->println('No keys purged');
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'generate' and scalar @$args == 3) {
        my (undef, $policy, $interval) = @$args;
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->CreateEnforcerKeyGenerate({
            policy => {
                name => $policy,
                interval => $interval
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                if (exists $response->{key}) {
                    $self->cli->println(join("\t", 'Keytype', 'Bits', 'Algorithm', 'CKA_ID', 'Repository'));
                    foreach my $key (ref($response->{key}) eq 'ARRAY' ? @{$response->{key}} : $response->{key}) {
                        $self->cli->println(join("\t",
                            $key->{keytype},
                            $key->{bits},
                            $key->{algorithm},
                            $key->{cka_id},
                            $key->{repository}
                            ));
                    }
                }
                else {
                    $self->cli->println('No keys generated');
                }
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'ksk' and scalar @$args == 3 and $args->[1] eq 'retire') {
        my (undef, undef, $zone) = @$args;
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateEnforcerKeyKskRetire({
            zone => {
                name => $zone,
                (defined $cka_id ? (cka_id => $cka_id) : ()),
                (defined $keytag ? (keytag => $keytag) : ())
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('KSK retired');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'ds' and scalar @$args == 3 and $args->[1] eq 'seen') {
        my (undef, undef, $zone) = @$args;
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateEnforcerKeyDsSeen({
            zone => {
                name => $zone,
                (defined $cka_id ? (cka_id => $cka_id) : ()),
                (defined $keytag ? (keytag => $keytag) : ()),
                ($retire == 0 ? (no_retire => 1) : ())
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('DS marked as seen');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    $self->Error;
}

=head2 backup

=cut

sub backup {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);
    
    unless ($getopt and scalar @$args >= 1) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'prepare') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @repositories;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@repositories, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->UpdateEnforcerBackupPrepare({
                repository => \@repositories
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Backup prepared');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->UpdateEnforcerBackupPrepare(sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Backup prepared');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'commit') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @repositories;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@repositories, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->UpdateEnforcerBackupCommit({
                repository => \@repositories
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Backup committed');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->UpdateEnforcerBackupCommit(sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Backup committed');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'rollback') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @repositories;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@repositories, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->UpdateEnforcerBackupRollback({
                repository => \@repositories
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Backup rollbacked');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->UpdateEnforcerBackupRollback(sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Backup rollbacked');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'done') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @repositories;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@repositories, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->UpdateEnforcerBackupDone({
                repository => \@repositories
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Backup done');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->UpdateEnforcerBackupDone(sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Backup done');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'list') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @repositories;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@repositories, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->ReadEnforcerBackupList({
                repository => \@repositories
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{repository}) {
                        $self->cli->println(join("\t", 'Repository', 'Last Backup', 'Unbacked Up Keys', 'Prepared Keys'));
                        foreach my $repository (ref($response->{repository}) eq 'ARRAY' ? @{$response->{repository}} : $response->{repository}) {
                            my $backup = 'NONE';
                            
                            if (exists $repository->{backup}) {
                                if (ref($repository->{backup}) eq 'ARRAY') {
                                    foreach (sort {$b->{date} cmp $a->{date}} @{$repository->{backup}}) {
                                        $backup = $_;
                                        last;
                                    }
                                }
                                else {
                                    $backup = $repository->{backup};
                                }
                            }
                            
                            $self->cli->println(join("\t",
                                $repository->{name},
                                $backup,
                                exists $repository->{unbacked_up_keys} and $repository->{unbacked_up_keys} ? 'Yes' : 'No',
                                exists $repository->{prepared_keys} and $repository->{prepared_keys} ? 'Yes' : 'No'
                                ));
                        }
                    }
                    else {
                        $self->cli->println('There are no backups');
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->ReadEnforcerBackupList(sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{repository}) {
                        $self->cli->println(join("\t", 'Repository', 'Last Backup', 'Unbacked Up Keys', 'Prepared Keys'));
                        foreach my $repository (ref($response->{repository}) eq 'ARRAY' ? @{$response->{repository}} : $response->{repository}) {
                            my $backup = 'NONE';
                            
                            if (exists $repository->{backup}) {
                                if (ref($repository->{backup}) eq 'ARRAY') {
                                    foreach (sort {$b->{date} cmp $a->{date}} @{$repository->{backup}}) {
                                        $backup = $_->{date};
                                        last;
                                    }
                                }
                                else {
                                    $backup = $repository->{backup}->{date};
                                }
                            }
                            
                            $self->cli->println(join("\t",
                                $repository->{name},
                                $backup,
                                ((exists $repository->{unbacked_up_keys} and $repository->{unbacked_up_keys}) ? 'Yes' : 'No'),
                                ((exists $repository->{prepared_keys} and $repository->{prepared_keys}) ? 'Yes' : 'No')
                                ));
                        }
                    }
                    else {
                        $self->cli->println('There are no backups');
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    $self->Error;
}

=head2 rollover

=cut

sub rollover {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);
    
    unless ($getopt and scalar @$args >= 1) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'list') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @zones;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@zones, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->ReadEnforcerRolloverList({
                zone => \@zones
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{zone}) {
                        $self->cli->println(join("\t", 'Zone', 'Keytype', 'Rollover Expected'));
                        foreach my $zone (ref($response->{zone}) eq 'ARRAY' ? @{$response->{zone}} : $response->{zone}) {
                            $self->cli->println(join("\t",
                                $zone->{name},
                                $zone->{keytype},
                                $zone->{rollover_expected}
                                ));
                        }
                    }
                    else {
                        $self->cli->println('There are no rollovers expected');
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->ReadEnforcerRolloverList(sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{zone}) {
                        $self->cli->println(join("\t", 'Zone', 'Keytype', 'Rollover Expected'));
                        foreach my $zone (ref($response->{zone}) eq 'ARRAY' ? @{$response->{zone}} : $response->{zone}) {
                            $self->cli->println(join("\t",
                                $zone->{name},
                                $zone->{keytype},
                                $zone->{rollover_expected}
                                ));
                        }
                    }
                    else {
                        $self->cli->println('There are no rollovers expected');
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    $self->Error;
}

=head2 database

=cut

sub database {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);
    
    unless ($getopt and scalar @$args == 1) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'backup') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->CreateEnforcerDatabaseBackup(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('Database backed up');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    $self->Error;
}

=head2 zonelist

=cut

sub zonelist {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);
    
    unless ($getopt and scalar @$args == 1) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'export') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->ReadEnforcerZonelistExport(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                if (exists $response->{zonelist}) {
                    $self->cli->println('Zonelist:');
                    $self->cli->println($response->{zonelist});
                }
                else {
                    $self->cli->println('No zonelist received');
                }
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    $self->Error;
}

=head2 signer

=cut

sub signer {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);
    
    unless ($getopt and scalar @$args >= 1) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'zones') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->ReadSignerZones(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                if (exists $response->{zone}) {
                    $self->cli->println('Signer Zones:');
                    foreach my $zone (ref($response->{zone}) eq 'ARRAY' ? @{$response->{zone}} : $response->{zone}) {
                        $self->cli->println($zone->{name});
                    }
                }
                else {
                    $self->cli->println('No zones in Signer');
                }
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'sign') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @zones;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@zones, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->UpdateSignerSign({
                zone => \@zones
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Sign issued');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->UpdateSignerSign(sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Sign issued');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'clear' and scalar @$args > 1) {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        my @zones;
        my $skip = 1;
        
        foreach (@$args) {
            if ($skip) {
                $skip--;
                next;
            }
            
            push(@zones, { name => $_ });
        }
            
        weaken($self);
        $opendnssec->UpdateSignerClear({
            zone => \@zones
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('Clear issued');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'queue') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->ReadSignerQueue(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                if (exists $response->{task}) {
                    if (exists $response->{now}) {
                        $self->cli->println('Now: ', $response->{now});
                    }
                    $self->cli->println(join("\t", 'On', 'Task', 'Zone'));
                    foreach my $task (ref($response->{task}) eq 'ARRAY' ? @{$response->{task}} : $response->{task}) {
                        $self->cli->println(join("\t",
                            $task->{date},
                            $task->{type},
                            $task->{zone}
                        ));
                    }
                }
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'flush') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateSignerFlush(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('Flush issued');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'update') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @zones;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@zones, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->UpdateSignerUpdate({
                zone => \@zones
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Update issued');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->UpdateSignerUpdate(sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    $self->cli->println('Update issued');
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'running') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->ReadSignerRunning(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                if ($response->{running}) {
                    $self->cli->println('Signer is running');
                }
                else {
                    $self->cli->println('Signer is not running');
                }
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'reload') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateSignerReload(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('Reload issued');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'verbosity' and scalar @$args == 2 and $args->[1] =~ /^\d+$/o) {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->UpdateSignerVerbosity({
            verbosity => $args->[1]
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('Verbosity issued');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    $self->Error;
}

=head2 hsm

=cut

sub hsm {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);
    
    unless ($getopt and scalar @$args >= 1) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'list') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        if (scalar @$args > 1) {
            my @repositories;
            my $skip = 1;
            
            foreach (@$args) {
                if ($skip) {
                    $skip--;
                    next;
                }
                
                push(@repositories, { name => $_ });
            }
            
            weaken($self);
            $opendnssec->ReadHsmList({
                repository => \@repositories
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{key}) {
                        $self->cli->println(join("\t", 'Repository', 'ID', 'Keytype', 'Keysize'));
                        foreach my $key (ref($response->{key}) eq 'ARRAY' ? @{$response->{key}} : $response->{key}) {
                            $self->cli->println(join("\t",
                                $key->{repository},
                                $key->{id},
                                $key->{keytype},
                                $key->{keysize}
                            ));
                        }
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
        else {
            weaken($self);
            $opendnssec->ReadHsmList(sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($opendnssec);
                    return;
                }
                
                if ($call->Successful) {
                    if (exists $response->{key}) {
                        $self->cli->println(join("\t", 'Repository', 'ID', 'Keytype', 'Keysize'));
                        foreach my $key (ref($response->{key}) eq 'ARRAY' ? @{$response->{key}} : $response->{key}) {
                            $self->cli->println(join("\t",
                                $key->{repository},
                                $key->{id},
                                $key->{keytype},
                                $key->{keysize}
                            ));
                        }
                    }
                    $self->Successful;
                }
                else {
                    $self->Error($call->Error);
                }
                undef($opendnssec);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'generate' and scalar @$args == 3) {
        my (undef, $repository, $keysize) = @$args;
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->CreateHsmGenerate({
            key => {
                repository => $repository,
                keysize => $keysize
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                if (exists $response->{key}) {
                    $self->cli->println(join("\t", 'Repository', 'ID', 'Keytype', 'Keysize'));
                    foreach my $key (ref($response->{key}) eq 'ARRAY' ? @{$response->{key}} : $response->{key}) {
                        $self->cli->println(join("\t",
                            $key->{repository},
                            $key->{id},
                            $key->{keytype},
                            $key->{keysize}
                        ));
                    }
                }
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'remove' and scalar @$args > 1) {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        my @keys;
        my $skip = 1;
        
        foreach (@$args) {
            if ($skip) {
                $skip--;
                next;
            }
            
            push(@keys, { id => $_ });
        }
        
        weaken($self);
        $opendnssec->DeleteHsmRemove({
            key => \@keys
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('Key(s) removed');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'purge' and scalar @$args > 1) {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        my @repositories;
        my $skip = 1;
        
        # TODO ask user
        
        foreach (@$args) {
            if ($skip) {
                $skip--;
                next;
            }
            
            push(@repositories, { name => $_ });
        }
        
        weaken($self);
        $opendnssec->DeleteHsmPurge({
            repository => \@repositories
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('Repositories purged');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'dnskey' and scalar @$args == 3) {
        my (undef, $id, $name) = @$args;
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->CreateHsmDnskey({
            key => {
                id => $id,
                name => $name
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                if (exists $response->{key}) {
                    $self->cli->println('DNSKEY Resource Record(s):');
                    foreach my $key (ref($response->{key}) eq 'ARRAY' ? @{$response->{key}} : $response->{key}) {
                        $self->cli->println($key->{rr});
                    }
                }
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'test' and scalar @$args > 1) {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        my @repositories;
        my $skip = 1;
        
        foreach (@$args) {
            if ($skip) {
                $skip--;
                next;
            }
            
            push(@repositories, { name => $_ });
        }
        
        weaken($self);
        $opendnssec->ReadHsmTest({
            repository => \@repositories
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('Repositories successfully tested');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    elsif ($args->[0] eq 'info') {
        my $opendnssec = Lim::Plugin::OpenDNSSEC->Client;
        weaken($self);
        $opendnssec->ReadHsmInfo(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($opendnssec);
                return;
            }
            
            if ($call->Successful) {
                if (exists $response->{repository}) {
                    $self->cli->println(join("\t", 'Repository', 'Module', 'Slot', 'Token Label', 'Manufacturer', 'Model', 'Serial'));
                    foreach my $repository (ref($response->{repository}) eq 'ARRAY' ? @{$response->{repository}} : $response->{repository}) {
                        $self->cli->println(join("\t",
                            $repository->{name},
                            $repository->{module},
                            $repository->{slot},
                            $repository->{token_label},
                            $repository->{manufacturer},
                            $repository->{model},
                            $repository->{serial}
                        ));
                    }
                }
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($opendnssec);
        });
        return;
    }
    $self->Error;
}

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim-plugin-opendnssec/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Plugin::OpenDNSSEC

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim-plugin-opendnssec/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::Plugin::OpenDNSSEC::CLI
