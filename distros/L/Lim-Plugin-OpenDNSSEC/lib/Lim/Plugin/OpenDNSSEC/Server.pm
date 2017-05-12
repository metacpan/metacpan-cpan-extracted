package Lim::Plugin::OpenDNSSEC::Server;

use common::sense;

use Fcntl qw(:seek);
use IO::File ();
use Digest::SHA ();
use Scalar::Util qw(weaken);

use Lim::Plugin::OpenDNSSEC ();

use Lim::Util ();

use base qw(Lim::Component::Server);

=encoding utf8

=head1 NAME

...

=head1 VERSION

See L<Lim::Plugin::OpenDNSSEC> for version.

=over 4

=item OPENDNSSEC_VERSION_MIN

=item OPENDNSSEC_VERSION_MAX

=back

=cut

our $VERSION = $Lim::Plugin::OpenDNSSEC::VERSION;
our %ConfigFiles = (
    'conf.xml' => [
        '/etc/opendnssec/conf.xml',
        'conf.xml'
    ],
    'kasp.xml' => [
        '/etc/opendnssec/kasp.xml',
        'kasp.xml'
    ],
    'zonelist.xml' => [
        '/etc/opendnssec/zonelist.xml',
        'zonelist.xml'
    ],
    'zonefetch.xml' => [
        '/etc/opendnssec/zonefetch.xml',
        'zonefetch.xml'
    ],
    'addns.xml' => [
        '/etc/opendnssec/addns.xml',
        'addns.xml'
    ]
);

sub OPENDNSSEC_VERSION_MIN (){ 1003000 }
sub OPENDNSSEC_VERSION_MAX (){ 1004000 }

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 Init

=cut

sub Init {
    my $self = shift;
    my %args = ( @_ );

    $self->{bin} = {
        control => 0,
        enforcerd => 0,
        ksmutil => 0,
        signer => 0,
        signerd => 0,
        hsmutil => 0
    };
    $self->{bin_version} = {};
    
    my ($stdout, $stderr);
    my $cv = Lim::Util::run_cmd [ 'ods-control' ],
        '<', '/dev/null',
        '>', \$stdout,
        '2>', \$stderr;
    # ods-control exits with 1 when just running it
    if ($cv->recv) {
        if ($stderr =~ /usage:\s+ods-control/o) {
            $self->{bin}->{control} = 1;
        }
        else {
            $self->{logger}->warn('Unable to find "ods-control" executable, module functions limited');
        }
    }

    my $cv = Lim::Util::run_cmd [ 'ods-enforcerd', '-V' ],
        '<', '/dev/null',
        '>', \$stdout,
        '2>', \$stderr;
    if ($cv->recv) {
        $self->{logger}->warn('Unable to find "ods-enforcerd" executable, module functions limited');
    }
    else {
        if ($stderr =~ /opendnssec\s+version\s+([0-9]+)\.([0-9]+)\.([0-9]+)/o) {
            my ($major,$minor,$patch) = ($1, $2, $3);
            
            if ($major > 0 and $major < 10 and $minor > -1 and $minor < 10 and $patch > -1 and $patch < 100) {
                my $version = ($major * 1000000) + ($minor * 1000) + $patch;
                
                unless ($version >= OPENDNSSEC_VERSION_MIN and $version <= OPENDNSSEC_VERSION_MAX) {
                    $self->{logger}->warn('Unsupported "ods-enforcerd" executable version, unable to continue');
                }
                else {
                    $self->{bin}->{enforcerd} = $version;
                    $self->{bin_version}->{enforcerd} = $major.'.'.$minor.'.'.$patch;
                }
            }
            else {
                $self->{logger}->warn('Invalid "ods-enforcerd" version, module functions limited');
            }
        }
        else {
            $self->{logger}->warn('Unable to get "ods-enforcerd" version, module functions limited');
        }
    }

    my $cv = Lim::Util::run_cmd [ 'ods-ksmutil', '--version' ],
        '<', '/dev/null',
        '>', \$stdout,
        '2>', \$stderr;
    if ($cv->recv) {
        $self->{logger}->warn('Unable to find "ods-ksmutil" executable, module functions limited');
    }
    else {
        if ($stdout =~ /opendnssec\s+version\s+([0-9]+)\.([0-9]+)\.([0-9]+)/o) {
            my ($major,$minor,$patch) = ($1, $2, $3);
            
            if ($major > 0 and $major < 10 and $minor > -1 and $minor < 10 and $patch > -1 and $patch < 100) {
                my $version = ($major * 1000000) + ($minor * 1000) + $patch;
                
                unless ($version >= OPENDNSSEC_VERSION_MIN and $version <= OPENDNSSEC_VERSION_MAX) {
                    $self->{logger}->warn('Unsupported "ods-ksmutil" executable version, unable to continue');
                }
                else {
                    $self->{bin}->{ksmutil} = $version;
                    $self->{bin_version}->{ksmutil} = $major.'.'.$minor.'.'.$patch;
                }
            }
            else {
                $self->{logger}->warn('Invalid "ods-ksmutil" version, module functions limited');
            }
        }
        else {
            $self->{logger}->warn('Unable to get "ods-ksmutil" version, module functions limited');
        }
    }

    my $cv = Lim::Util::run_cmd [ 'ods-signer', '--help' ],
        '<', '/dev/null',
        '>', \$stdout,
        '2>', \$stderr;
    # ods-signer exits with 3 on --help
    if ($cv->recv) {
        if ($stdout =~ /Version\s+([0-9]+)\.([0-9]+)\.([0-9]+)/o) {
            my ($major,$minor,$patch) = ($1, $2, $3);
            
            if ($major > 0 and $major < 10 and $minor > -1 and $minor < 10 and $patch > -1 and $patch < 100) {
                my $version = ($major * 1000000) + ($minor * 1000) + $patch;
                
                unless ($version >= OPENDNSSEC_VERSION_MIN and $version <= OPENDNSSEC_VERSION_MAX) {
                    $self->{logger}->warn('Unsupported "ods-signer" executable version, unable to continue');
                }
                else {
                    $self->{bin}->{signer} = $version;
                    $self->{bin_version}->{signer} = $major.'.'.$minor.'.'.$patch;
                }
            }
            else {
                $self->{logger}->warn('Invalid "ods-signer" version, module functions limited');
            }
        }
        else {
            $self->{logger}->warn('Unable to get "ods-signer" version, module functions limited');
        }
    }

    my $cv = Lim::Util::run_cmd [ 'ods-signerd', '-V' ],
        '<', '/dev/null',
        '>', \$stdout,
        '2>', \$stderr;
    if ($cv->recv) {
        $self->{logger}->warn('Unable to find "ods-signerd" executable, module functions limited');
    }
    else {
        if ($stdout =~ /opendnssec\s+version\s+([0-9]+)\.([0-9]+)\.([0-9]+)/o) {
            my ($major,$minor,$patch) = ($1, $2, $3);
            
            if ($major > 0 and $major < 10 and $minor > -1 and $minor < 10 and $patch > -1 and $patch < 100) {
                my $version = ($major * 1000000) + ($minor * 1000) + $patch;
                
                unless ($version >= OPENDNSSEC_VERSION_MIN and $version <= OPENDNSSEC_VERSION_MAX) {
                    $self->{logger}->warn('Unsupported "ods-signerd" executable version, unable to continue');
                }
                else {
                    $self->{bin}->{signerd} = $version;
                    $self->{bin_version}->{signerd} = $major.'.'.$minor.'.'.$patch;
                }
            }
            else {
                $self->{logger}->warn('Invalid "ods-signerd" version, module functions limited');
            }
        }
        else {
            $self->{logger}->warn('Unable to get "ods-signerd" version, module functions limited');
        }
    }
    
    my $cv = Lim::Util::run_cmd [ 'ods-hsmutil', '-V' ],
        '<', '/dev/null',
        '>', \$stdout,
        '2>', \$stderr;
    if ($cv->recv) {
        $self->{logger}->warn('Unable to find "ods-hsmutil" executable, module functions limited');
    }
    else {
        if ($stdout =~ /version\s+([0-9]+)\.([0-9]+)\.([0-9]+)/o) {
            my ($major,$minor,$patch) = ($1, $2, $3);
            
            if ($major > 0 and $major < 10 and $minor > -1 and $minor < 10 and $patch > -1 and $patch < 100) {
                my $version = ($major * 1000000) + ($minor * 1000) + $patch;
                
                unless ($version >= OPENDNSSEC_VERSION_MIN and $version <= OPENDNSSEC_VERSION_MAX) {
                    $self->{logger}->warn('Unsupported "ods-hsmutil" executable version, unable to continue');
                }
                else {
                    $self->{bin}->{hsmutil} = $version;
                    $self->{bin_version}->{hsmutil} = $major.'.'.$minor.'.'.$patch;
                }
            }
            else {
                $self->{logger}->warn('Invalid "ods-hsmutil" version, module functions limited');
            }
        }
        else {
            $self->{logger}->warn('Unable to get "ods-hsmutil" version, module functions limited');
        }
    }

    my $version = 0;
    foreach my $program (keys %{$self->{bin}}) {
        if ($program eq 'control') {
            next;
        }
        if ($self->{bin}->{$program}) {
            if ($version and $version != $self->{bin}->{$program}) {
                die 'Missmatch version between Enforcer and Signer tools, disabling module';
            }
            $version = $self->{bin}->{$program};
        }
    }
    
    $self->{version} = $version;
}

=head2 Destroy

=cut

sub Destroy {
}

=head2 _ScanConfig

=cut

sub _ScanConfig {
    my ($self) = @_;
    my %file;
    
    foreach my $config (keys %ConfigFiles) {
        
        if ($config eq 'zonefetch.xml') {
            if ($self->{version} >= 1004000) {
                # zonefetch.xml is only pre 1.4
                next;
            }
        }
        elsif ($config eq 'addns.xml') {
            if ($self->{version} <= 1004000) {
                # addns.xml is only 1.4 and up
                next;
            }
        }
        
        foreach my $file (@{$ConfigFiles{$config}}) {
            if (defined ($_ = Lim::Util::FileWritable($file))) {
                if (exists $file{$_}) {
                    $file{$_}->{write} = 1;
                    next;
                }
                
                $file{$_} = {
                    name => $_,
                    write => 1,
                    read => 1
                };
            }
            elsif (defined ($_ = Lim::Util::FileReadable($file))) {
                if (exists $file{$_}) {
                    next;
                }
                
                $file{$_} = {
                    name => $_,
                    write => 0,
                    read => 1
                };
            }
        }
    }
    
    return \%file;
}

=head2 ReadVersion

=cut

sub ReadVersion {
    my ($self, $cb) = @_;
    my @program;
    
    foreach my $program (keys %{$self->{bin_version}}) {
        push(@program, { name => 'ods-'.$program, version => $self->{bin_version}->{$program} });
    }

    if (scalar @program) {
        $self->Successful($cb, { version => $VERSION, program => \@program });
    }
    else {
        $self->Successful($cb, { version => $VERSION });
    }
}

=head2 ReadConfigs

=cut

sub ReadConfigs {
    my ($self, $cb) = @_;
    my $files = $self->_ScanConfig;
    
    $self->Successful($cb, {
        file => [ values %$files ]
    });
}

=head2 CreateConfig

=cut

sub CreateConfig {
    my ($self, $cb) = @_;
    
    $self->Error($cb, 'Not Implemented');
}

=head2 ReadConfig

=cut

sub ReadConfig {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig;
    my $result = {};

    foreach my $read (ref($q->{file}) eq 'ARRAY' ? @{$q->{file}} : $q->{file}) {
        if (exists $files->{$read->{name}}) {
            my $file = $files->{$read->{name}};
            
            if ($file->{read} and defined (my $fh = IO::File->new($file->{name}))) {
                my ($tell, $content);
                $fh->seek(0, SEEK_END);
                $tell = $fh->tell;
                $fh->seek(0, SEEK_SET);
                if ($fh->read($content, $tell) == $tell) {
                    if (exists $result->{file}) {
                        unless (ref($result->{file}) eq 'ARRAY') {
                            $result->{file} = [ $result->{file} ];
                        }
                        push(@{$result->{file}}, {
                            name => $file->{name},
                            content => $content
                        });
                    }
                    else {
                        $result->{file} = {
                            name => $file->{name},
                            content => $content
                        };
                    }
                }
            }
        }
        else {
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'File "'.$read->{name}.'" not found in configuration files'
            ));
            return;
        }
    }
    $self->Successful($cb, $result);
}

=head2 UpdateConfig

=cut

sub UpdateConfig {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig;
    my $result = {};

    foreach my $read (ref($q->{file}) eq 'ARRAY' ? @{$q->{file}} : $q->{file}) {
        if (exists $files->{$read->{name}}) {
            my $file = $files->{$read->{name}};

            if ($file->{write} and defined (my $tmp = Lim::Util::TempFileLikeThis($file->{name}))) {
                print $tmp $read->{content};
                $tmp->flush;
                $tmp->close;
                
                my $fh = IO::File->new;
                if ($fh->open($tmp->filename)) {
                    my ($tell, $content);
                    $fh->seek(0, SEEK_END);
                    $tell = $fh->tell;
                    $fh->seek(0, SEEK_SET);
                    unless ($fh->read($content, $tell) == $tell) {
                        $self->Error($cb, Lim::Error->new(
                            code => 500,
                            message => 'Failed to write "'.$read->{name}.'" to temporary file'
                        ));
                        return;
                    }
                    unless (Digest::SHA::sha1_base64($read->{content}) eq Digest::SHA::sha1_base64($content)) {
                        $self->Error($cb, Lim::Error->new(
                            code => 500,
                            message => 'Checksum missmatch on "'.$read->{name}.'" after writing to temporary file'
                        ));
                        return;
                    }
                    unless (rename($tmp->filename, $file->{name}))
                    {
                        $self->Error($cb, Lim::Error->new(
                            code => 500,
                            message => 'Failed to rename "'.$read->{name}.'"'
                        ));
                        return;
                    }
                }
            }
        }
        else {
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'File "'.$read->{name}.'" not found in configuration files'
            ));
            return;
        }
    }
    $self->Successful($cb);
}

=head2 DeleteConfig

=cut

sub DeleteConfig {
    my ($self, $cb) = @_;
    
    $self->Error($cb, 'Not Implemented');
}

=head2 UpdateControl

=cut

sub UpdateControl {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 UpdateControlStart

=cut

sub UpdateControlStart {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{control}) {
        $self->Error($cb, 'No "ods-control" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{program}) {
        my @programs;
        foreach my $program (ref($q->{program}) eq 'ARRAY' ? @{$q->{program}} : $q->{program}) {
            if (exists $program->{name}) {
                my $name = lc($program->{name});
                if ($name eq 'enforcer' and $self->{bin}->{enforcerd}) {
                    push(@programs, $name);
                }
                elsif ($name eq 'signer' and $self->{bin}->{signerd}) {
                    push(@programs, $name);
                }
                else {
                    $self->Error($cb, Lim::Error->new(
                        code => 500,
                        message => 'Unknown program "'.$name.'" specified'
                    ));
                    return;
                }
            }
        }
        if (scalar @programs) {
            weaken($self);
            my $cmd_cb; $cmd_cb = sub {
                unless (defined $self) {
                    undef($cmd_cb);
                    return;
                }
                if (my $program = shift(@programs)) {
                    Lim::Util::run_cmd
                        [ 'ods-control', $program, 'start' ],
                        '<', '/dev/null',
                        '>', sub {
                            if (defined $_[0]) {
                                $cb->reset_timeout;
                            }
                        },
                        '2>', '/dev/null',
                        timeout => 30,
                        cb => sub {
                            unless (defined $self) {
                                undef($cmd_cb);
                                return;
                            }
                            if (shift->recv) {
                                $self->Error($cb, 'Unable to start OpenDNSSEC '.$program);
                                undef($cmd_cb);
                                return;
                            }
                            $cmd_cb->();
                        };
                }
                else {
                    $self->Successful($cb);
                    undef($cmd_cb);
                }
            };
            $cmd_cb->();
            return;
        }
    }
    else {
        weaken($self);
        Lim::Util::run_cmd
            [ 'ods-control', 'start' ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                }
            },
            '2>', '/dev/null',
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to start OpenDNSSEC');
                    return;
                }
                $self->Successful($cb);
            };
        return;
    }
    $self->Successful($cb);
}

=head2 UpdateControlStop

=cut

sub UpdateControlStop {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{control}) {
        $self->Error($cb, 'No "ods-control" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{program}) {
        my @programs;
        foreach my $program (ref($q->{program}) eq 'ARRAY' ? @{$q->{program}} : $q->{program}) {
            if (exists $program->{name}) {
                my $name = lc($program->{name});
                if ($name eq 'enforcer' and $self->{bin}->{enforcerd}) {
                    push(@programs, $name);
                }
                elsif ($name eq 'signer' and $self->{bin}->{signerd}) {
                    push(@programs, $name);
                }
                else {
                    $self->Error($cb, Lim::Error->new(
                        code => 500,
                        message => 'Unknown program "'.$name.'" specified'
                    ));
                    return;
                }
            }
        }
        if (scalar @programs) {
            weaken($self);
            my $cmd_cb; $cmd_cb = sub {
                unless (defined $self) {
                    undef($cmd_cb);
                    return;
                }
                if (my $program = shift(@programs)) {
                    Lim::Util::run_cmd
                        [ 'ods-control', $program, 'stop' ],
                        '<', '/dev/null',
                        '>', sub {
                            if (defined $_[0]) {
                                $cb->reset_timeout;
                            }
                        },
                        '2>', '/dev/null',
                        timeout => 30,
                        cb => sub {
                            unless (defined $self) {
                                undef($cmd_cb);
                                return;
                            }
                            if (shift->recv) {
                                $self->Error($cb, 'Unable to stop OpenDNSSEC '.$program);
                                undef($cmd_cb);
                                return;
                            }
                            $cmd_cb->();
                        };
                }
                else {
                    $self->Successful($cb);
                    undef($cmd_cb);
                }
            };
            $cmd_cb->();
            return;
        }
    }
    else {
        weaken($self);
        Lim::Util::run_cmd
            [ 'ods-control', 'stop' ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                }
            },
            '2>', '/dev/null',
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to stop OpenDNSSEC');
                    return;
                }
                $self->Successful($cb);
            };
        return;
    }
    $self->Successful($cb);
}

=head2 CreateEnforcer

=cut

sub CreateEnforcer {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 ReadEnforcer

=cut

sub ReadEnforcer {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 UpdateEnforcer

=cut

sub UpdateEnforcer {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 DeleteEnforcer

=cut

sub DeleteEnforcer {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 CreateEnforcerSetup

=cut

sub CreateEnforcerSetup {
    my ($self, $cb) = @_;
    
    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }
    
    # TODO confirm with user

    weaken($self);
    my ($stdout, $stderr);
    my $stdin = "Y\015";
    Lim::Util::run_cmd [ 'ods-ksmutil', 'setup' ],
        '<', \$stdin,
        '>', sub {
            if (defined $_[0]) {
                $cb->reset_timeout;
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to setup OpenDNSSEC');
                return;
            }
            $self->Successful($cb);
        };
}

=head2 UpdateEnforcerUpdate

=cut

sub UpdateEnforcerUpdate {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }
    
    my %section = (
        kasp => 1,
        zonelist => 1,
        conf => 1
    );
    
    if (exists $q->{update}) {
        my @sections;
        foreach my $section (ref($q->{update}) eq 'ARRAY' ? @{$q->{update}} : $q->{update}) {
            my $name = lc($section->{section});
            
            if (exists $section{$name}) {
                push(@sections, $name);
            }
            else {
                $self->Error($cb, Lim::Error->new(
                    code => 500,
                    message => 'Unknown Enforcer configuration section "'.$name.'" specified'
                ));
                return;
            }
        }
        if (scalar @sections) {
            weaken($self);
            my $cmd_cb; $cmd_cb = sub {
                unless (defined $self) {
                    undef($cmd_cb);
                    return;
                }
                if (my $section = shift(@sections)) {
                    my ($stdout, $stderr);
                    Lim::Util::run_cmd
                        [ 'ods-ksmutil', 'update', $section ],
                        '<', '/dev/null',
                        '>', sub {
                            if (defined $_[0]) {
                                $cb->reset_timeout;
                                $stdout .= $_[0];
                            }
                        },
                        '2>', \$stderr,
                        timeout => 30,
                        cb => sub {
                            unless (defined $self) {
                                undef($cmd_cb);
                                return;
                            }
                            if (shift->recv) {
                                $self->Error($cb, 'Unable to update Enforcer configuration section '.$section);
                                undef($cmd_cb);
                                return;
                            }
                            $cmd_cb->();
                        };
                }
                else {
                    $self->Successful($cb);
                    undef($cmd_cb);
                }
            };
            $cmd_cb->();
            return;
        }
    }
    else {
        my ($stdout, $stderr);
        weaken($self);
        Lim::Util::run_cmd
            [ 'ods-ksmutil', 'update', 'all' ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                    $stdout .= $_[0];
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to update all Enforcer configuration sections');
                    return;
                }
                $self->Successful($cb);
            };
        return;
    }
    $self->Successful($cb);
}

=head2 CreateEnforcerZone

=cut

sub CreateEnforcerZone {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }
    
    my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
    if (scalar @zones) {
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $zone = shift(@zones)) {
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'zone', 'add',
                        '--zone', $zone->{name},
                        '--policy', $zone->{policy},
                        '--signerconf', $zone->{signerconf},
                        '--input', $zone->{input},
                        '--output', $zone->{output},
                        (exists $zone->{no_xml} and $zone->{no_xml} ? '--no-xml' : ())
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 10,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to create zone ', $zone->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                $self->Successful($cb);
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
        return;
    }
    $self->Successful($cb);
}

=head2 ReadEnforcerZoneList

=cut

sub ReadEnforcerZoneList {
    my ($self, $cb) = @_;
    
    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }
    
    weaken($self);
    my ($data, $stderr, @zones);
    Lim::Util::run_cmd [ 'ods-ksmutil', 'zone', 'list' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $data .= $_[0];
                
                $cb->reset_timeout;
                
                while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                    my $line = $1;
                    
                    if ($line =~ /^Found\s+Zone:\s+([^;]+);\s+on\s+policy\s+(.+)$/o) {
                        push(@zones, {
                            name => $1,
                            policy => $2
                        });
                    }
                }
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to get Enforcer zone list');
                return;
            }
            if (scalar @zones == 1) {
                $self->Successful($cb, { zone => $zones[0] });
            }
            elsif (scalar @zones) {
                $self->Successful($cb, { zone => \@zones });
            }
            else {
                $self->Successful($cb);
            }
        };
}

=head2 DeleteEnforcerZone

=cut

sub DeleteEnforcerZone {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }
    
    my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
    if (scalar @zones) {
        foreach (@zones) {
            if (exists $_->{all} and $_->{all}) {
                weaken($self);
                my ($stdout, $stderr);
                # TODO reset timer on stdout output
                Lim::Util::run_cmd
                    [ 'ods-ksmutil', 'zone', 'delete', '--all' ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to delete all zones');
                            return;
                        }
                        $self->Successful($cb);
                    };
                return;
            }
        }
        
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $zone = shift(@zones)) {
                while (defined $zone and !exists $zone->{name}) {
                    $zone = shift(@zones);
                }
                unless (defined $zone) {
                    $self->Successful($cb);
                    undef($cmd_cb);
                    return;
                }
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'zone', 'delete',
                        '--zone', $zone->{name},
                        (exists $zone->{no_xml} and $zone->{no_xml} ? '--no-xml' : ())
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 10,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to delete zone ', $zone->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                $self->Successful($cb);
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
        return;
    }
    $self->Successful($cb);
}

=head2 ReadEnforcerRepositoryList

=cut

sub ReadEnforcerRepositoryList {
    my ($self, $cb) = @_;
    
    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }
    
    weaken($self);
    my ($data, $stderr, @repositories);
    my $skip = 2;
    Lim::Util::run_cmd [ 'ods-ksmutil', 'repository', 'list' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $data .= $_[0];
                
                $cb->reset_timeout;
                
                while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                    my $line = $1;
                    
                    if ($skip) {
                        $skip--;
                        next;
                    }
                    
                    # TODO spaces in name?
                    if ($line =~ /^(\S+)\s+(\d+)\s+((?:Yes|No))$/o) {
                        push(@repositories, {
                            name => $1,
                            capacity => $2,
                            require_backup => $3 eq 'Yes' ? 1 : 0
                        });
                    }
                }
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to get Enforcer repository list');
                return;
            }
            if (scalar @repositories == 1) {
                $self->Successful($cb, { repository => $repositories[0] });
            }
            elsif (scalar @repositories) {
                $self->Successful($cb, { repository => \@repositories });
            }
            else {
                $self->Successful($cb);
            }
        };
}

=head2 ReadEnforcerPolicyList

=cut

sub ReadEnforcerPolicyList {
    my ($self, $cb) = @_;
    
    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }
    
    weaken($self);
    my ($data, $stderr, @policies);
    my $skip = 2;
    Lim::Util::run_cmd [ 'ods-ksmutil', 'policy', 'list' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $data .= $_[0];
                
                $cb->reset_timeout;
                
                while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                    my $line = $1;
                    
                    if ($skip) {
                        $skip--;
                        next;
                    }
                    
                    # TODO spaces in name?
                    if ($line =~ /^(\S+)\s+(.+)$/o) {
                        push(@policies, {
                            name => $1,
                            description => $2
                        });
                    }
                }
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to get Enforcer policy list');
                return;
            }
            if (scalar @policies == 1) {
                $self->Successful($cb, { policy => $policies[0] });
            }
            elsif (scalar @policies) {
                $self->Successful($cb, { policy => \@policies });
            }
            else {
                $self->Successful($cb);
            }
        };
}

=head2 ReadEnforcerPolicyExport

=cut

sub ReadEnforcerPolicyExport {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    # TODO is there a way to send the database as base64 incrementaly to avoid hogning memory?
    
    if (exists $q->{policy}) {
        my @policies = ref($q->{policy}) eq 'ARRAY' ? @{$q->{policy}} : ($q->{policy});
        my %policy;
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $policy = shift(@policies)) {
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'policy', 'export',
                        '--policy', $policy->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to get Enforcer policy export for policy ', $policy->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $policy{$policy->{name}} = {
                            name => $policy->{name},
                            kasp => $stdout
                        };
                        $cmd_cb->();
                    };
            }
            else {
                if (scalar %policy) {
                    $self->Successful($cb, { policy => [ values %policy ] });
                }
                else {
                    $self->Successful($cb);
                }
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($stdout, $stderr);
        Lim::Util::run_cmd [ 'ods-ksmutil', 'policy', 'export', '--all' ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                    $stdout .= $_[0];
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to export policies');
                    return;
                }
                $self->Successful($cb, { kasp => $stdout });
            };
    }
}

=head2 DeleteEnforcerPolicyPurge

=cut

sub DeleteEnforcerPolicyPurge {
    my ($self, $cb) = @_;

    $self->Error($cb, 'Not Implemented: function experimental');
}

=head2 ReadEnforcerKeyList

=cut

sub ReadEnforcerKeyList {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{zone}) {
        my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
        my %zone;
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $zone = shift(@zones)) {
                my ($data, $stderr);
                my $skip = 2;
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'key', 'list',
                        '--zone', $zone->{name},
                        (exists $q->{verbose} and $q->{verbose} ? '--verbose' : ())
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $data .= $_[0];
                            
                            $cb->reset_timeout;
                            
                            while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                                my $line = $1;
                                
                                if ($skip) {
                                    $skip--;
                                    next;
                                }
                                
                                if ($line =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+(?:\s\S+)*)\s*(?:(\S+)\s+(\S+)\s+(\S+)){0,1}$/o) {
                                    unless (exists $zone{$1}) {
                                        $zone{$1} = {
                                            name => $1,
                                            key => []
                                        };
                                    }
                                    push(@{$zone{$1}->{key}}, {
                                        type => $2,
                                        state => $3,
                                        next_transaction => $4,
                                        (defined $5 ? (cka_id => $5) : ()),
                                        (defined $6 ? (repository => $6) : ()),
                                        (defined $7 ? (keytag => $7) : ())
                                    });
                                }
                            }
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to get Enforcer key list for zone ', $zone->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                if (scalar %zone) {
                    $self->Successful($cb, { zone => [ values %zone ] });
                }
                else {
                    $self->Successful($cb);
                }
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($data, $stderr, %zone);
        my $skip = 2;
        Lim::Util::run_cmd
            [
                'ods-ksmutil', 'key', 'list',
                (exists $q->{verbose} and $q->{verbose} ? '--verbose' : ())
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $data .= $_[0];
                    
                    $cb->reset_timeout;
                    
                    while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                        my $line = $1;
                        
                        if ($skip) {
                            $skip--;
                            next;
                        }
                        
                        if ($line =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+(?:\s\S+)*)\s*(?:(\S+)\s+(\S+)\s+(\S+)){0,1}$/o) {
                            unless (exists $zone{$1}) {
                                $zone{$1} = {
                                    name => $1,
                                    key => []
                                };
                            }
                            push(@{$zone{$1}->{key}}, {
                                type => $2,
                                state => $3,
                                next_transaction => $4,
                                (defined $5 ? (cka_id => $5) : ()),
                                (defined $6 ? (repository => $6) : ()),
                                (defined $7 ? (keytag => $7) : ())
                            });
                        }
                    }
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to get Enforcer key list');
                    return;
                }
                elsif (scalar %zone) {
                    $self->Successful($cb, { zone => [ values %zone ] });
                }
                else {
                    $self->Successful($cb);
                }
            };
    }
}

=head2 ReadEnforcerKeyExport

=cut

sub ReadEnforcerKeyExport {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{zone}) {
        my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
        my @rr;
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $zone = shift(@zones)) {
                my ($data, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'key', 'export',
                        '--zone', $zone->{name},
                        (exists $zone->{keystate} ? ('--keystate' => $zone->{keystate}) : (exists $q->{keystate} and $q->{keystate} ? ('--keystate', $q->{keystate}) : ())),
                        (exists $zone->{keytype} ? ('--keytype' => $zone->{keytype}) : (exists $q->{keytype} and $q->{keytype} ? ('--keytype', $q->{keytype}) : ())),
                        (exists $zone->{ds} ? ('--ds' => $zone->{ds}) : (exists $q->{ds} and $q->{ds} ? ('--ds') : ()))
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $data .= $_[0];
                            
                            $cb->reset_timeout;
                            
                            while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                                my $line = $1;
                                
                                $line =~ s/;.*//o;
                                
                                if ($line =~ /^(\S+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(.+)$/o) {
                                    push(@rr, {
                                        name => $1,
                                        ttl => $2,
                                        class => $3,
                                        type => $4,
                                        rdata => $5
                                    });
                                }
                            }
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to get Enforcer key export for zone ', $zone->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                if (scalar @rr == 1) {
                    $self->Successful($cb, { rr => $rr[0] });
                }
                elsif (scalar @rr) {
                    $self->Successful($cb, { rr => \@rr });
                }
                else {
                    $self->Successful($cb);
                }
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($data, $stderr, @rr);
        Lim::Util::run_cmd
            [
                'ods-ksmutil', 'key', 'export', '--all',
                (exists $q->{keystate} and $q->{keystate} ? ('--keystate', $q->{keystate}) : ()),
                (exists $q->{keytype} and $q->{keytype} ? ('--keytype', $q->{keytype}) : ()),
                (exists $q->{ds} and $q->{ds} ? ('--ds') : ())
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $data .= $_[0];
                    
                    $cb->reset_timeout;
                    
                    while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                        my $line = $1;
                        
                        $line =~ s/;.*//o;
                        
                        if ($line =~ /^(\S+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(.+)$/o) {
                            push(@rr, {
                                name => $1,
                                ttl => $2,
                                class => $3,
                                type => $4,
                                rdata => $5
                            });
                        }
                    }
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to get Enforcer key export');
                    return;
                }
                elsif (scalar @rr == 1) {
                    $self->Successful($cb, { rr => $rr[0] });
                }
                elsif (scalar @rr) {
                    $self->Successful($cb, { rr => \@rr });
                }
                else {
                    $self->Successful($cb);
                }
            };
    }
}

=head2 CreateEnforcerKeyImport

=cut

sub CreateEnforcerKeyImport {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @keys = ref($q->{key}) eq 'ARRAY' ? @{$q->{key}} : ($q->{key});

    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $key = shift(@keys)) {
            my ($stdout, $stderr);
            Lim::Util::run_cmd
                [
                    'ods-ksmutil', 'key', 'import',
                    '--zone', $key->{zone},
                    '--cka_id', $key->{cka_id},
                    '--repository', $key->{repository},
                    '--bits', $key->{bits},
                    '--algorithm', $key->{algorithm},
                    '--keystate', $key->{keystate},
                    '--keytype', $key->{keytype},
                    '--time', $key->{time},
                    (exists $key->{retire} ? ('--retire', $key->{retire}) : ())
                ],
                '<', '/dev/null',
                '>', sub {
                    if (defined $_[0]) {
                        $cb->reset_timeout;
                        $stdout .= $_[0];
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to import key cka id ', $key->{cka_id}, ' to Enforcer for zone ', $key->{zone});
                        undef($cmd_cb);
                        return;
                    }
                    $cmd_cb->();
                };
        }
        else {
            $self->Successful($cb);
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 UpdateEnforcerKeyRollover

=cut

sub UpdateEnforcerKeyRollover {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @zones;
    if (exists $q->{zone}) {
        @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
    }
    
    my @policies;
    if (exists $q->{policy}) {
        @policies = ref($q->{policy}) eq 'ARRAY' ? @{$q->{policy}} : ($q->{policy});
    }

    if (scalar @zones or scalar @policies) {
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $zone = shift(@zones)) {
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'key', 'rollover',
                        '--zone', $zone->{name},
                        (exists $zone->{keytype} ? ('--keytype' => $zone->{keytype}) : ())
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to issue Enforcer key rollover for zone ', $zone->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            elsif (my $policy = shift(@policies)) {
                my ($stdout, $stderr, $stdin);
                $stdin = "Y\015";
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'key', 'rollover',
                        '--policy', $policy->{name},
                        (exists $policy->{keytype} ? ('--keytype' => $policy->{keytype}) : ())
                    ],
                    '<', \$stdin,
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to issue Enforcer key rollover for policy ', $policy->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                $self->Successful($cb);
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
        return;
    }
    $self->Successful($cb);
}

=head2 DeleteEnforcerKeyPurge

=cut

sub DeleteEnforcerKeyPurge {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @zones;
    if (exists $q->{zone}) {
        @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
    }
    
    my @policies;
    if (exists $q->{policy}) {
        @policies = ref($q->{policy}) eq 'ARRAY' ? @{$q->{policy}} : ($q->{policy});
    }

    # TODO test parsing of output

    if (scalar @zones or scalar @policies) {
        my @keys;
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $zone = shift(@zones)) {
                my ($data, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'key', 'purge',
                        '--zone', $zone->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $data .= $_[0];
                            
                            $cb->reset_timeout;
                            
                            while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                                my $line = $1;
                                
                                if ($line =~ /^Key\s+remove\s+successful:\s+(\S+)$/o) {
                                    push(@keys, {
                                        cka_id => $1
                                    });
                                }
                            }
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to issue Enforcer key rollover for zone ', $zone->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            elsif (my $policy = shift(@policies)) {
                my ($data, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'key', 'purge',
                        '--policy', $policy->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $data .= $_[0];
                            
                            $cb->reset_timeout;
                            
                            while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                                my $line = $1;
                                
                                if ($line =~ /^Key\s+remove\s+successful:\s+(\S+)$/o) {
                                    push(@keys, {
                                        cka_id => $1
                                    });
                                }
                            }
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to issue Enforcer key rollover for policy ', $policy->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                if (scalar @keys == 1) {
                    $self->Successful($cb, { key => $keys[0] });
                }
                elsif (scalar @keys) {
                    $self->Successful($cb, { key => \@keys });
                }
                else {
                    $self->Successful($cb);
                }
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
        return;
    }
    $self->Successful($cb);
}

=head2 CreateEnforcerKeyGenerate

=cut

sub CreateEnforcerKeyGenerate {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @policies = ref($q->{policy}) eq 'ARRAY' ? @{$q->{policy}} : ($q->{policy});
    my @keys;
    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $policy = shift(@policies)) {
            my ($data, $stderr);
            Lim::Util::run_cmd
                [
                    'ods-ksmutil', 'key', 'generate',
                    '--policy', $policy->{name},
                    '--interval', $policy->{interval},
                ],
                '<', '/dev/null',
                '>', sub {
                    if (defined $_[0]) {
                        $data .= $_[0];
                        
                        $cb->reset_timeout;
                        
                        while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                            my $line = $1;
                            
                            if ($line =~ /^Created\s+(\S+)\s+size:\s+(\d+),\s+alg:\s+(\d+)\s+with\s+id:\s+(\S+)\s+in\s+repository:\s+(.*)\s+and\s+database\.$/o) {
                                push(@keys, {
                                    keytype => $1,
                                    bits => $2,
                                    algorithm => $3,
                                    cka_id => $4,
                                    repository => $5
                                });
                            }
                        }
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to generate keys for policy ', $policy->{name});
                        undef($cmd_cb);
                        return;
                    }
                    $cmd_cb->();
                };
        }
        else {
            if (scalar @keys == 1) {
                $self->Successful($cb, { key => $keys[0] });
            }
            elsif (scalar @keys) {
                $self->Successful($cb, { key => \@keys });
            }
            else {
                $self->Successful($cb);
            }
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 UpdateEnforcerKeyKskRetire

=cut

sub UpdateEnforcerKeyKskRetire {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $zone = shift(@zones)) {
            my ($stdout, $stderr, $stdin);
            $stdin = "Y\015";
            Lim::Util::run_cmd
                [
                    'ods-ksmutil', 'key', 'ksk-retire',
                    '--zone', $zone->{name},
                    (exists $zone->{cka_id} ? ('--cka_id' => $zone->{cka_id}) : ()),
                    (exists $zone->{keytag} ? ('--keytag' => $zone->{keytag}) : ())
                ],
                '<', \$stdin,
                '>', sub {
                    if (defined $_[0]) {
                        $cb->reset_timeout;
                        $stdout .= $_[0];
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        my $error;
                        if ($stdout =~ /((?:Error:|No keys in)[^,]+)/o) {
                            $error = $1;
                            $error =~ s/^Error:\s+//o;
                        }
                        $self->Error($cb, 'Unable to retire KSK keys for zone ', $zone->{name},
                            (exists $zone->{cka_id} ? ' cka_id '.$zone->{cka_id} : ''),
                            (exists $zone->{keytag} ? ' keytag '.$zone->{keytag} : ''),
                            ' error: ', (defined $error ? $error : 'unknown')
                            );
                        undef($cmd_cb);
                        return;
                    }
                    $cmd_cb->();
                };
        }
        else {
            $self->Successful($cb);
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 UpdateEnforcerKeyDsSeen

=cut

sub UpdateEnforcerKeyDsSeen {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});

    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $zone = shift(@zones)) {
            my ($stdout, $stderr);
            Lim::Util::run_cmd
                [
                    'ods-ksmutil', 'key', 'ds-seen',
                    '--zone', $zone->{name},
                    (exists $zone->{cka_id} ? ('--cka_id', $zone->{cka_id}) : ()),
                    (exists $zone->{keytag} ? ('--keytag',  $zone->{keytag}) : ()),
                    (exists $zone->{no_retire} and $zone->{no_retire} ? ('--no-retire') : ())
                ],
                '<', '/dev/null',
                '>', sub {
                    if (defined $_[0]) {
                        $cb->reset_timeout;
                        $stdout .= $_[0];
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to set key as ds seen for zone ', $zone->{name},
                            (exists $zone->{cka_id} ? ' cka_id '.$zone->{cka_id} : ''),
                            (exists $zone->{keytag} ? ' keytag '.$zone->{keytag} : '')
                            );
                        undef($cmd_cb);
                        return;
                    }
                    $cmd_cb->();
                };
        }
        else {
            $self->Successful($cb);
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 UpdateEnforcerBackupPrepare

=cut

sub UpdateEnforcerBackupPrepare {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{repository}) {
        my @repositories = ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : ($q->{repository});
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $repository = shift(@repositories)) {
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'backup', 'prepare',
                        '--repository', $repository->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to prepare backup of repository ', $repository->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                $self->Successful($cb);
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($stdout, $stderr);
        Lim::Util::run_cmd
            [
                'ods-ksmutil', 'backup', 'prepare'
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                    $stdout .= $_[0];
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to prepare backup');
                    return;
                }
                $self->Successful($cb);
            };
    }
}

=head2 UpdateEnforcerBackupCommit

=cut

sub UpdateEnforcerBackupCommit {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{repository}) {
        my @repositories = ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : ($q->{repository});
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $repository = shift(@repositories)) {
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'backup', 'commit',
                        '--repository', $repository->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to commit backup of repository ', $repository->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                $self->Successful($cb);
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($stdout, $stderr);
        Lim::Util::run_cmd
            [
                'ods-ksmutil', 'backup', 'commit'
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                    $stdout .= $_[0];
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to commit backup');
                    return;
                }
                $self->Successful($cb);
            };
    }
}

=head2 UpdateEnforcerBackupRollback

=cut

sub UpdateEnforcerBackupRollback {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{repository}) {
        my @repositories = ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : ($q->{repository});
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $repository = shift(@repositories)) {
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'backup', 'rollback',
                        '--repository', $repository->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to rollback backup of repository ', $repository->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                $self->Successful($cb);
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($stdout, $stderr);
        Lim::Util::run_cmd
            [
                'ods-ksmutil', 'backup', 'rollback'
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                    $stdout .= $_[0];
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to rollback backup');
                    return;
                }
                $self->Successful($cb);
            };
    }
}

=head2 UpdateEnforcerBackupDone

=cut

sub UpdateEnforcerBackupDone {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{repository}) {
        my @repositories = ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : ($q->{repository});
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $repository = shift(@repositories)) {
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'backup', 'done',
                        '--repository', $repository->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to take backup of repository ', $repository->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                $self->Successful($cb);
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($stdout, $stderr);
        Lim::Util::run_cmd
            [
                'ods-ksmutil', 'backup', 'done'
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                    $stdout .= $_[0];
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to take backup');
                    return;
                }
                $self->Successful($cb);
            };
    }
}

=head2 ReadEnforcerBackupList

=cut

sub ReadEnforcerBackupList {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{repository}) {
        my @respositories = ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : ($q->{repository});
        my %repository;
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $repository = shift(@respositories)) {
                my ($data, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'backup', 'list',
                        '--repository', $repository->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $data .= $_[0];
                            
                            $cb->reset_timeout;
                            
                            while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                                my $line = $1;
                                
                                if ($line =~ /^Repository\s+(.+)\s+has\s+unbacked\s+up\s+keys/o) {
                                    unless (exists $repository{$1}) {
                                        $repository{$1} = {
                                            name => $1
                                        };
                                    }
                                    $repository{$1}->{unbacked_up_keys} = 1;
                                }
                                elsif ($line =~ /^Repository\s+(.+)\s+has\s+keys\s+prepared/o) {
                                    unless (exists $repository{$1}) {
                                        $repository{$1} = {
                                            name => $1
                                        };
                                    }
                                    $repository{$1}->{prepared_keys} = 1;
                                }
                                elsif ($line =~ /^(\S+\s+\S+)\s+(\S+)$/o) {
                                    unless (exists $repository{$2}) {
                                        $repository{$2} = {
                                            name => $2
                                        };
                                    }
                                    push(@{$repository{$2}->{backup}}, {
                                        date => $1
                                    });
                                }
                            }
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to get Enforcer backup list for repository ', $repository->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                if (scalar %repository) {
                    $self->Successful($cb, { repository => [ values %repository ] });
                }
                else {
                    $self->Successful($cb);
                }
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($data, $stderr, %repository);
        Lim::Util::run_cmd
            [
                'ods-ksmutil', 'backup', 'list'
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $data .= $_[0];
                    
                    $cb->reset_timeout;
                    
                    while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                        my $line = $1;
                        
                        if ($line =~ /^Repository\s+(.+)\s+has\s+unbacked\s+up\s+keys/o) {
                            unless (exists $repository{$1}) {
                                $repository{$1} = {
                                    name => $1
                                };
                            }
                            $repository{$1}->{unbacked_up_keys} = 1;
                        }
                        elsif ($line =~ /^Repository\s+(.+)\s+has\s+keys\s+prepared/o) {
                            unless (exists $repository{$1}) {
                                $repository{$1} = {
                                    name => $1
                                };
                            }
                            $repository{$1}->{prepared_keys} = 1;
                        }
                        elsif ($line =~ /^(\S+\s+\S+)\s+(\S+)$/o) {
                            unless (exists $repository{$2}) {
                                $repository{$2} = {
                                    name => $2
                                };
                            }
                            push(@{$repository{$2}->{backup}}, {
                                date => $1
                            });
                        }
                    }
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to get Enforcer backup list');
                    return;
                }
                elsif (scalar %repository) {
                    $self->Successful($cb, { repository => [ values %repository ] });
                }
                else {
                    $self->Successful($cb);
                }
            };
    }
}

=head2 ReadEnforcerRolloverList

=cut

sub ReadEnforcerRolloverList {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{zone}) {
        my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
        my @rollovers;
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $zone = shift(@zones)) {
                my ($data, $stderr);
                my $skip = 2;
                Lim::Util::run_cmd
                    [
                        'ods-ksmutil', 'rollover', 'list',
                        '--zone', $zone->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $data .= $_[0];
                            
                            $cb->reset_timeout;
                            
                            while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                                my $line = $1;
                                
                                if ($skip) {
                                    $skip--;
                                    next;
                                }
                                
                                if ($line =~ /^(\S+)\s+(\S+)\s+(\S+\s+\S+)$/o) {
                                    push(@rollovers, {
                                        name => $1,
                                        keytype => $2,
                                        rollover_expected => $3
                                    });
                                }
                            }
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to get Enforcer rollover list for zone ', $zone->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                if (scalar @rollovers == 1) {
                    $self->Successful($cb, { zone => $rollovers[0] });
                }
                elsif (scalar @rollovers) {
                    $self->Successful($cb, { zone => \@rollovers });
                }
                else {
                    $self->Successful($cb);
                }
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($data, $stderr, @rollovers);
        my $skip = 2;
        Lim::Util::run_cmd
            [
                'ods-ksmutil', 'rollover', 'list'
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $data .= $_[0];
                    
                    $cb->reset_timeout;
                    
                    while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                        my $line = $1;
                        
                        if ($skip) {
                            $skip--;
                            next;
                        }
                        
                        if ($line =~ /^(\S+)\s+(\S+)\s+(\S+\s+\S+)$/o) {
                            push(@rollovers, {
                                name => $1,
                                keytype => $2,
                                rollover_expected => $3
                            });
                        }
                    }
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to get Enforcer rollover list');
                    return;
                }
                elsif (scalar @rollovers == 1) {
                    $self->Successful($cb, { zone => $rollovers[0] });
                }
                elsif (scalar @rollovers) {
                    $self->Successful($cb, { zone => \@rollovers });
                }
                else {
                    $self->Successful($cb);
                }
            };
    }
}

=head2 CreateEnforcerDatabaseBackup

=cut

sub CreateEnforcerDatabaseBackup {
    my ($self, $cb) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    # TODO is there a way to send the database as base64 incrementaly to avoid hogning memory?
    
    weaken($self);
    my ($stdout, $stderr);
    Lim::Util::run_cmd [ 'ods-ksmutil', 'database', 'backup' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $cb->reset_timeout;
                $stdout .= $_[0];
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to backup Enforcer database');
                return;
            }
            $self->Successful($cb);
        };
}

=head2 ReadEnforcerZonelistExport

=cut

sub ReadEnforcerZonelistExport {
    my ($self, $cb) = @_;

    unless ($self->{bin}->{ksmutil}) {
        $self->Error($cb, 'No "ods-ksmutil" executable found or unsupported version, unable to continue');
        return;
    }

    # TODO is there a way to send the database as base64 incrementaly to avoid hogning memory?
    
    weaken($self);
    my ($stdout, $stderr);
    Lim::Util::run_cmd [ 'ods-ksmutil', 'zonelist', 'export' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $cb->reset_timeout;
                $stdout .= $_[0];
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to export zonelist');
                return;
            }
            $self->Successful($cb, { zonelist => $stdout });
        };
}

=head2 ReadSigner

=cut

sub ReadSigner {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 UpdateSigner

=cut

sub UpdateSigner {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 ReadSignerZones

=cut

sub ReadSignerZones {
    my ($self, $cb) = @_;

    unless ($self->{bin}->{signer}) {
        $self->Error($cb, 'No "ods-signer" executable found or unsupported version, unable to continue');
        return;
    }

    weaken($self);
    my ($data, $stderr, @zones);
    Lim::Util::run_cmd [ 'ods-signer', 'zones' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $data .= $_[0];
                
                $cb->reset_timeout;
                
                while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                    my $line = $1;
                    
                    if ($line =~ /^-\s+(\S+)$/o) {
                        push(@zones, {
                            name => $1
                        });
                    }
                }
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to get Signer zones');
                return;
            }
            elsif (scalar @zones == 1) {
                $self->Successful($cb, { zone => $zones[0] });
            }
            elsif (scalar @zones) {
                $self->Successful($cb, { zone => \@zones });
            }
            else {
                $self->Successful($cb);
            }
        };
}

=head2 UpdateSignerSign

=cut

sub UpdateSignerSign {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{signer}) {
        $self->Error($cb, 'No "ods-signer" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{zone}) {
        my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $zone = shift(@zones)) {
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-signer', 'sign', $zone->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to issue sign to Signer for zone ', $zone->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                $self->Successful($cb);
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($stdout, $stderr);
        Lim::Util::run_cmd
            [
                'ods-signer', 'sign', '--all'
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                    $stdout .= $_[0];
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to issue sign to Signer for all zones');
                    return;
                }
                $self->Successful($cb);
            };
    }
}

=head2 UpdateSignerClear

=cut

sub UpdateSignerClear {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{signer}) {
        $self->Error($cb, 'No "ods-signer" executable found or unsupported version, unable to continue');
        return;
    }

    my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $zone = shift(@zones)) {
            my ($stdout, $stderr);
            Lim::Util::run_cmd
                [
                    'ods-signer', 'clear', $zone->{name}
                ],
                '<', '/dev/null',
                '>', sub {
                    if (defined $_[0]) {
                        $cb->reset_timeout;
                        $stdout .= $_[0];
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to issue clear to Signer for zone ', $zone->{name});
                        undef($cmd_cb);
                        return;
                    }
                    $cmd_cb->();
                };
        }
        else {
            $self->Successful($cb);
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 ReadSignerQueue

=cut

sub ReadSignerQueue {
    my ($self, $cb) = @_;

    unless ($self->{bin}->{signer}) {
        $self->Error($cb, 'No "ods-signer" executable found or unsupported version, unable to continue');
        return;
    }

    weaken($self);
    my ($data, $stderr, @task, $now);
    Lim::Util::run_cmd [ 'ods-signer', 'queue' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $data .= $_[0];
                
                $cb->reset_timeout;
                
                while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                    my $line = $1;
                    
                    if ($line =~ /^It\s+is\s+now\s+(.+)$/o) {
                        $now = $1;
                    }
                    elsif ($line =~ /On\s+(.+)\s+I\s+will\s+\[([^\]]+)\]\s+zone\s+(.+)/o) {
                        push(@task, {
                            type => $2,
                            date => $1,
                            zone => $3
                        });
                    }
                }
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to get Signer queue');
                return;
            }
            elsif (scalar @task == 1) {
                $self->Successful($cb, { now => $now, task => $task[0] });
            }
            elsif (scalar @task) {
                $self->Successful($cb, { now => $now, task => \@task });
            }
            else {
                $self->Successful($cb);
            }
        };
}

=head2 UpdateSignerFlush

=cut

sub UpdateSignerFlush {
    my ($self, $cb) = @_;

    unless ($self->{bin}->{signer}) {
        $self->Error($cb, 'No "ods-signer" executable found or unsupported version, unable to continue');
        return;
    }

    weaken($self);
    my ($stdout, $stderr);
    Lim::Util::run_cmd [ 'ods-signer', 'flush' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $cb->reset_timeout;
                $stdout .= $_[0];
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to issue flush to Signer');
                return;
            }
            $self->Successful($cb);
        };
}

=head2 UpdateSignerUpdate

=cut

sub UpdateSignerUpdate {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{signer}) {
        $self->Error($cb, 'No "ods-signer" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{zone}) {
        my @zones = ref($q->{zone}) eq 'ARRAY' ? @{$q->{zone}} : ($q->{zone});
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $zone = shift(@zones)) {
                my ($stdout, $stderr);
                Lim::Util::run_cmd
                    [
                        'ods-signer', 'update', $zone->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $cb->reset_timeout;
                            $stdout .= $_[0];
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to issue update to Signer for zone ', $zone->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                $self->Successful($cb);
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($stdout, $stderr);
        Lim::Util::run_cmd
            [
                'ods-signer', 'update', '--all'
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $cb->reset_timeout;
                    $stdout .= $_[0];
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to issue update to Signer for all zones');
                    return;
                }
                $self->Successful($cb);
            };
    }
}

=head2 ReadSignerRunning

=cut

sub ReadSignerRunning {
    my ($self, $cb) = @_;

    unless ($self->{bin}->{signer}) {
        $self->Error($cb, 'No "ods-signer" executable found or unsupported version, unable to continue');
        return;
    }

    weaken($self);
    my ($stdout, $stderr);
    Lim::Util::run_cmd [ 'ods-signer', 'running' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $cb->reset_timeout;
                $stdout .= $_[0];
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if ($stderr =~ /Engine\s+not\s+running/o) {
                $self->Successful($cb, { running => 0 });
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to issue running to Signer');
                return;
            }
            $self->Successful($cb, { running => 1 });
        };
}

=head2 UpdateSignerReload

=cut

sub UpdateSignerReload {
    my ($self, $cb) = @_;

    unless ($self->{bin}->{signer}) {
        $self->Error($cb, 'No "ods-signer" executable found or unsupported version, unable to continue');
        return;
    }

    weaken($self);
    my ($stdout, $stderr);
    Lim::Util::run_cmd [ 'ods-signer', 'reload' ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $cb->reset_timeout;
                $stdout .= $_[0];
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to issue reload to Signer');
                return;
            }
            $self->Successful($cb);
        };
}

=head2 UpdateSignerVerbosity

=cut

sub UpdateSignerVerbosity {
    my ($self, $cb, $q) = @_;

    unless ($self->{bin}->{signer}) {
        $self->Error($cb, 'No "ods-signer" executable found or unsupported version, unable to continue');
        return;
    }

    weaken($self);
    my ($stdout, $stderr);
    Lim::Util::run_cmd [ 'ods-signer', 'verbosity', $q->{verbosity} ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $cb->reset_timeout;
                $stdout .= $_[0];
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to issue verbosity ', $q->{verbosity}, ' to Signer');
                return;
            }
            $self->Successful($cb);
        };
}

=head2 CreateHsm

=cut

sub CreateHsm {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 ReadHsm

=cut

sub ReadHsm {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 DeleteHsm

=cut

sub DeleteHsm {
    my ($self, $cb) = @_;

    $self->Successful($cb);
}

=head2 ReadHsmList

=cut

sub ReadHsmList {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{hsmutil}) {
        $self->Error($cb, 'No "ods-hsmutil" executable found or unsupported version, unable to continue');
        return;
    }

    if (exists $q->{repository}) {
        my @repositories = ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : ($q->{repository});
        my @keys;
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $repository = shift(@repositories)) {
                my ($data, $stderr);
                my $skip = 5;
                Lim::Util::run_cmd
                    [
                        'ods-hsmutil', 'list', $repository->{name}
                    ],
                    '<', '/dev/null',
                    '>', sub {
                        if (defined $_[0]) {
                            $data .= $_[0];
                            
                            $cb->reset_timeout;
                            
                            while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                                my $line = $1;
                                
                                if ($skip) {
                                    $skip--;
                                    next;
                                }
                                
                                if ($line =~ /^(\S+)\s+(\S+)\s+(\w+)\/(\d+)\s*$/o) {
                                    push(@keys, {
                                        repository => $1,
                                        id => $2,
                                        keytype => $3,
                                        keysize => $4
                                    });
                                }
                            }
                        }
                    },
                    '2>', \$stderr,
                    timeout => 30,
                    cb => sub {
                        unless (defined $self) {
                            undef($cmd_cb);
                            return;
                        }
                        if (shift->recv) {
                            $self->Error($cb, 'Unable to get hsm key list for repository ', $repository->{name});
                            undef($cmd_cb);
                            return;
                        }
                        $cmd_cb->();
                    };
            }
            else {
                if (scalar @keys == 1) {
                    $self->Successful($cb, { key => $keys[0] });
                }
                elsif (scalar @keys) {
                    $self->Successful($cb, { key => \@keys });
                }
                else {
                    $self->Successful($cb);
                }
                undef($cmd_cb);
            }
        };
        $cmd_cb->();
    }
    else {
        weaken($self);
        my ($data, $stderr, @keys);
        my $skip = 5;
        Lim::Util::run_cmd
            [
                'ods-hsmutil', 'list'
            ],
            '<', '/dev/null',
            '>', sub {
                if (defined $_[0]) {
                    $data .= $_[0];
                    
                    $cb->reset_timeout;
                    
                    while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                        my $line = $1;
                        
                        if ($skip) {
                            $skip--;
                            next;
                        }
                        
                        if ($line =~ /^(\S+)\s+(\S+)\s+(\w+)\/(\d+)\s*$/o) {
                            push(@keys, {
                                repository => $1,
                                id => $2,
                                keytype => $3,
                                keysize => $4
                            });
                        }
                    }
                }
            },
            '2>', \$stderr,
            timeout => 30,
            cb => sub {
                unless (defined $self) {
                    return;
                }
                if (shift->recv) {
                    $self->Error($cb, 'Unable to get hsm key list');
                    return;
                }
                if (scalar @keys == 1) {
                    $self->Successful($cb, { key => $keys[0] });
                }
                elsif (scalar @keys) {
                    $self->Successful($cb, { key => \@keys });
                }
                else {
                    $self->Successful($cb);
                }
            };
    }
}

=head2 CreateHsmGenerate

=cut

sub CreateHsmGenerate {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{hsmutil}) {
        $self->Error($cb, 'No "ods-hsmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @keys = ref($q->{key}) eq 'ARRAY' ? @{$q->{key}} : ($q->{key});
    my @generated;
    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $key = shift(@keys)) {
            my ($data, $stderr, $bits, $keytype, $repository, $id);
            Lim::Util::run_cmd
                [
                    'ods-hsmutil', 'generate', $key->{repository}, 'rsa', $key->{keysize}
                ],
                '<', '/dev/null',
                '>', sub {
                    if (defined $_[0]) {
                        $data .= $_[0];
                        
                        $cb->reset_timeout;
                        
                        while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                            my $line = $1;
                            
                            if ($line =~ /^Generating\s+(\d+)\s+bit\s+(\w+)\s+key\s+in\s+repository:\s+(.+)$/o) {
                                ($bits, $keytype, $repository) = ($1, $2, $3);
                            }
                            elsif ($line =~ /^Key\s+generation\s+successful:\s+(\S+)$/o) {
                                $id = $1;
                            }
                        }
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to generate hsm key in repository ', $key->{name});
                        undef($cmd_cb);
                        return;
                    }
                    push(@generated, {
                        repository => $repository,
                        id => $id,
                        keytype => $keytype,
                        keysize => $bits
                    });
                    $cmd_cb->();
                };
        }
        else {
            if (scalar @generated == 1) {
                $self->Successful($cb, { key => $generated[0] });
            }
            elsif (scalar @generated) {
                $self->Successful($cb, { key => \@generated });
            }
            else {
                $self->Successful($cb);
            }
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 DeleteHsmRemove

=cut

sub DeleteHsmRemove {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{hsmutil}) {
        $self->Error($cb, 'No "ods-hsmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @keys = ref($q->{key}) eq 'ARRAY' ? @{$q->{key}} : ($q->{key});
    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $key = shift(@keys)) {
            my ($stdout, $stderr);
            Lim::Util::run_cmd
                [
                    'ods-hsmutil', 'remove', $key->{id}
                ],
                '<', '/dev/null',
                '>', sub {
                    if (defined $_[0]) {
                        $cb->reset_timeout;
                        $stdout .= $_[0];
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to remove hsm key id ', $key->{id});
                        undef($cmd_cb);
                        return;
                    }
                    $cmd_cb->();
                };
        }
        else {
            $self->Successful($cb);
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 DeleteHsmPurge

=cut

sub DeleteHsmPurge {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{hsmutil}) {
        $self->Error($cb, 'No "ods-hsmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @repositories = ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : ($q->{repository});
    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $repository = shift(@repositories)) {
            my ($stdout, $stderr, $stdin);
            $stdin = "YES\015";
            Lim::Util::run_cmd
                [
                    'ods-hsmutil', 'purge', $repository->{name}
                ],
                '<', \$stdin,
                '>', sub {
                    if (defined $_[0]) {
                        $cb->reset_timeout;
                        $stdout .= $_[0];
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to purge hsm repository ', $repository->{name});
                        undef($cmd_cb);
                        return;
                    }
                    $cmd_cb->();
                };
        }
        else {
            $self->Successful($cb);
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 CreateHsmDnskey

=cut

sub CreateHsmDnskey {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{hsmutil}) {
        $self->Error($cb, 'No "ods-hsmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @keys = ref($q->{key}) eq 'ARRAY' ? @{$q->{key}} : ($q->{key});
    my @dnskeys;
    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $key = shift(@keys)) {
            my ($stdout, $stderr);
            Lim::Util::run_cmd
                [
                    'ods-hsmutil', 'dnskey', $key->{id}, $key->{name}
                ],
                '<', '/dev/null',
                '>', sub {
                    if (defined $_[0]) {
                        $cb->reset_timeout;
                        $stdout .= $_[0];
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to remove hsm key id ', $key->{id});
                        undef($cmd_cb);
                        return;
                    }
                    $stdout =~ s/[\r\n].*//o;
                    push(@dnskeys, {
                        id => $key->{id},
                        name => $key->{name},
                        rr => $stdout
                    });
                    $cmd_cb->();
                };
        }
        else {
            if (scalar @dnskeys == 1) {
                $self->Successful($cb, { key => $dnskeys[0] });
            }
            elsif (scalar @dnskeys) {
                $self->Successful($cb, { key => \@dnskeys });
            }
            else {
                $self->Successful($cb);
            }
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 ReadHsmTest

=cut

sub ReadHsmTest {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{hsmutil}) {
        $self->Error($cb, 'No "ods-hsmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @repositories = ref($q->{repository}) eq 'ARRAY' ? @{$q->{repository}} : ($q->{repository});
    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $repository = shift(@repositories)) {
            my ($stdout, $stderr);
            Lim::Util::run_cmd
                [
                    'ods-hsmutil', 'test', $repository->{name}
                ],
                '<', '/dev/null',
                '>', sub {
                    if (defined $_[0]) {
                        $cb->reset_timeout;
                        $stdout .= $_[0];
                    }
                },
                '2>', \$stderr,
                timeout => 30,
                cb => sub {
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to test hsm repository ', $repository->{name});
                        undef($cmd_cb);
                        return;
                    }
                    $cmd_cb->();
                };
        }
        else {
            $self->Successful($cb);
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=head2 ReadHsmInfo

=cut

sub ReadHsmInfo {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{hsmutil}) {
        $self->Error($cb, 'No "ods-hsmutil" executable found or unsupported version, unable to continue');
        return;
    }

    my @repositories;
    weaken($self);
    my ($data, $stderr, $repository);
    Lim::Util::run_cmd
        [
            'ods-hsmutil', 'info'
        ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $data .= $_[0];
                
                $cb->reset_timeout;
                
                while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                    my $line = $1;
                    if ($line =~ /^Repository:\s+(.+)$/o) {
                        my $name = $1;
                        if (defined $repository) {
                            foreach (qw(name module slot token_label manufacturer model serial)) {
                                unless (exists $repository->{$_}) {
                                    undef($repository);
                                    last;
                                }
                            }
                            if (defined $repository) {
                                push(@repositories, $repository);
                            }
                        }
                        $repository = {
                            name => $name
                        };
                    }
                    elsif ($line =~ /Module:\s+(.+)$/o) {
                        $repository->{module} = $1;
                    }
                    elsif ($line =~ /Slot:\s+(\d+)$/o) {
                        $repository->{slot} = $1;
                    }
                    # TODO spaces in names?
                    elsif ($line =~ /Token\s+Label:\s+(\S+)/o) {
                        $repository->{token_label} = $1;
                    }
                    elsif ($line =~ /Manufacturer:\s+(\S+)/o) {
                        $repository->{manufacturer} = $1;
                    }
                    elsif ($line =~ /Model:\s+(\S+)/o) {
                        $repository->{model} = $1;
                    }
                    elsif ($line =~ /Serial:\s+(\S+)/o) {
                        $repository->{serial} = $1;
                    }
                }
            }
        },
        '2>', \$stderr,
        timeout => 30,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to get hsm repository info');
                return;
            }
            if (defined $repository) {
                foreach (qw(name module slot token_label manufacturer model serial)) {
                    unless (exists $repository->{$_}) {
                        undef($repository);
                        last;
                    }
                }
                if (defined $repository) {
                    push(@repositories, $repository);
                }
            }
            if (scalar @repositories == 1) {
                $self->Successful($cb, { repository => $repositories[0] });
            }
            elsif (scalar @repositories) {
                $self->Successful($cb, { repository => \@repositories });
            }
            else {
                $self->Successful($cb);
            }
        };
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

1; # End of Lim::Plugin::OpenDNSSEC::Server
