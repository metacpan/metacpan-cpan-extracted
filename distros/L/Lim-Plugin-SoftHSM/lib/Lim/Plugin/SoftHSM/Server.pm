package Lim::Plugin::SoftHSM::Server;

use common::sense;

use Fcntl qw(:seek);
use IO::File ();
use Digest::SHA ();
use Scalar::Util qw(weaken);

use Lim::Plugin::SoftHSM ();

use Lim::Util ();

use base qw(Lim::Component::Server);

=encoding utf8

=head1 NAME

Lim::Plugin::SoftHSM::Server - Server class for SoftHSM management plugin

=head1 VERSION

See L<Lim::Plugin::SoftHSM> for version.

=cut

our $VERSION = $Lim::Plugin::SoftHSM::VERSION;

=head1 SYNOPSIS

  use Lim::Plugin::SoftHSM;

  # Create a Server object
  $client = Lim::Plugin::SoftHSM->Server;

=head1 CONFIGURATION

TODO

=over 4

=item SOFTHSM_VERSION_MIN

=item SOFTHSM_VERSION_MAX

=back

=cut

our $VERSION = $Lim::Plugin::SoftHSM::VERSION;
our %ConfigFiles = (
    'softhsm.conf' => [
        '/etc/softhsm/softhsm.conf',
        '/etc/softhsm.conf',
        'softhsm.conf'
    ]
);

sub SOFTHSM_VERSION_MIN (){ 1003000 }
sub SOFTHSM_VERSION_MAX (){ 1003003 }

=head1 INTERNAL METHODS

These are only internal methods and should not be used externally.

=over 4

=item Init

=cut

sub Init {
    my $self = shift;
    my %args = ( @_ );

    $self->{bin} = {
        softhsm => 0
    };
    $self->{version} = {};
    
    my ($stdout, $stderr);
    my $cv = Lim::Util::run_cmd [ 'softhsm', '--version' ],
        '<', '/dev/null',
        '>', \$stdout,
        '2>', \$stderr;
    if ($cv->recv) {
        $self->{logger}->warn('Unable to find "softhsm" executable, module functions limited');
    }
    else {
        if ($stdout =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)/o) {
            my ($major,$minor,$patch) = ($1, $2, $3);
            
            if ($major > 0 and $major < 10 and $minor > -1 and $minor < 10 and $patch > -1 and $patch < 100) {
                my $version = ($major * 1000000) + ($minor * 1000) + $patch;
                
                unless ($version >= SOFTHSM_VERSION_MIN and $version <= SOFTHSM_VERSION_MAX) {
                    $self->{logger}->warn('Unsupported "softhsm" executable version, unable to continue');
                }
                else {
                    $self->{bin}->{softhsm} = $version;
                    $self->{version}->{softhsm} = $major.'.'.$minor.'.'.$patch;
                }
            }
            else {
                $self->{logger}->warn('Invalid "softhsm" version, module functions limited');
            }
        }
        else {
            $self->{logger}->warn('Unable to get "softhsm" version, module functions limited');
        }
    }
}

=item Destroy

=cut

sub Destroy {
}

=item $server->_ScanConfig

Scan for SoftHSM configuration files and return a hash reference.

  $hash_ref->{<full path file name>} = {
      name => <full path file name>,
      write => <true if writable>,
      read => <true if readable>
  };

=cut

sub _ScanConfig {
    my ($self) = @_;
    my %file;
    
    foreach my $config (keys %ConfigFiles) {
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

=back

=head1 METHODS

These methods are called from the Lim framework and should not be used else
where.

Please see L<Lim::Plugin::SoftHSM> for full documentation of calls.

=over 4

=item $server->ReadVersion(...)

Get the version of the plugin and version of SoftHSM found.

=cut

sub ReadVersion {
    my ($self, $cb) = @_;
    my @program;
    
    if ($self->{version}->{softhsm}) {
        push(@program, { name => 'softhsm', version => $self->{version}->{softhsm} });
    }

    if (scalar @program) {
        $self->Successful($cb, { version => $VERSION, program => \@program });
    }
    else {
        $self->Successful($cb, { version => $VERSION });
    }
}

=item $server->ReadConfigs(...)

Get a list of all config files that can be managed by this plugin.

=cut

sub ReadConfigs {
    my ($self, $cb) = @_;
    my $files = $self->_ScanConfig;
    
    $self->Successful($cb, {
        file => [ values %$files ]
    });
}

=item $server->CreateConfig(...)

Create a new config file.

=cut

sub CreateConfig {
    my ($self, $cb) = @_;
    
    $self->Error($cb, 'Not Implemented');
}

=item $server->ReadConfig(...)

Returns a config file as a content.

=cut

sub ReadConfig {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig;
    my $result = {};

    foreach my $read (ref($q->{file}) eq 'ARRAY' ? @{$q->{file}} : $q->{file}) {
        unless (exists $files->{$read->{name}}) {
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'File "'.$read->{name}.'" not found in configuration files'
            ));
            return;
        }
    }
    
    foreach my $read (ref($q->{file}) eq 'ARRAY' ? @{$q->{file}} : $q->{file}) {
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
    $self->Successful($cb, $result);
}

=item $server->UpdateConfig(...)

Update a config file, this will overwrite the file.

=cut

sub UpdateConfig {
    my ($self, $cb, $q) = @_;
    my $files = $self->_ScanConfig;
    my $result = {};

    foreach my $read (ref($q->{file}) eq 'ARRAY' ? @{$q->{file}} : $q->{file}) {
        unless (exists $files->{$read->{name}}) {
            $self->Error($cb, Lim::Error->new(
                code => 500,
                message => 'File "'.$read->{name}.'" not found in configuration files'
            ));
            return;
        }
    }

    foreach my $read (ref($q->{file}) eq 'ARRAY' ? @{$q->{file}} : $q->{file}) {
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
    $self->Successful($cb);
}

=item $server->DeleteConfig(...)

Delete a config file.

=cut

sub DeleteConfig {
    my ($self, $cb) = @_;
    
    $self->Error($cb, 'Not Implemented');
}

=item $server->ReadShowSlots(...)

Get a list of all SoftHSM slots that are available.

=cut

sub ReadShowSlots {
    my ($self, $cb) = @_;
    
    unless ($self->{bin}->{softhsm}) {
        $self->Error($cb, 'No "softhsm" executable found or unsupported version, unable to continue');
        return;
    }
    
    my ($stderr, @slots, $slot, $data);
    Lim::Util::run_cmd
        [
            'softhsm',
            '--show-slots'
        ],
        '<', '/dev/null',
        '>', sub {
            if (defined $_[0]) {
                $data .= $_[0];
                
                $cb->reset_timeout;
                
                while ($data =~ s/^([^\r\n]*)\r?\n//o) {
                    my $line = $1;
                    
                    if ($line =~ /^Slot\s+([0-9]+)/o) {
                        if (defined $slot) {
                            push(@slots, $slot);
                        }
                        $slot = {
                            id => $1
                        };
                    }
                    elsif (!defined $slot) {
                        next;
                    }
                    elsif ($line =~ /Token\s+present:\s+(\w+)/o) {
                        if (lc($1) eq 'yes') {
                            $slot->{token_present} = 1;
                        }
                        else {
                            $slot->{token_present} = 0;
                        }
                    }
                    elsif ($line =~ /Token\s+initialized:\s+(\w+)/o) {
                        if (lc($1) eq 'yes') {
                            $slot->{token_initialized} = 1;
                        }
                        else {
                            $slot->{token_initialized} = 0;
                        }
                    }
                    elsif ($line =~ /User\s+PIN\s+initialized:\s+(\w+)/o) {
                        if (lc($1) eq 'yes') {
                            $slot->{user_pin_initialized} = 1;
                        }
                        else {
                            $slot->{user_pin_initialized} = 0;
                        }
                    }
                    elsif ($line =~ /Token\s+label:\s+(\w+)/o) {
                        # TODO spaces in token label??
                        $slot->{token_label} = $1;
                    }
                }
            }
        },
        '2>', \$stderr,
        timeout => 15,
        cb => sub {
            unless (defined $self) {
                return;
            }
            if (shift->recv) {
                $self->Error($cb, 'Unable to read slots');
            }
            else {
                if (defined $slot) {
                    push(@slots, $slot);
                }
                if (scalar @slots == 1) {
                    $self->Successful($cb, { slot => $slots[0] });
                }
                elsif (scalar @slots) {
                    $self->Successful($cb, { slot => \@slots });
                }
                else {
                    $self->Successful($cb);
                }
            }
        };
}

=item $server->CreateInitToken(...)

Initialize a slot.

=cut

sub CreateInitToken {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{softhsm}) {
        $self->Error($cb, 'No "softhsm" executable found or unsupported version, unable to continue');
        return;
    }
    
    my @tokens = ref($q->{token}) eq 'ARRAY' ? @{$q->{token}} : ($q->{token});
    if (scalar @tokens) {
        weaken($self);
        my $cmd_cb; $cmd_cb = sub {
            unless (defined $self) {
                undef($cmd_cb);
                return;
            }
            if (my $token = shift(@tokens)) {
                my ($stdout, $stderr);
                unless (length($token->{so_pin}) >= 4 and length($token->{so_pin}) <= 255) {
                    $self->Error($cb, 'Unable to create token ', $token->{label}, ': so_pin not between 4 and 255 characters');
                    undef($cmd_cb);
                    return;
                }
                unless (length($token->{pin}) >= 4 and length($token->{pin}) <= 255) {
                    $self->Error($cb, 'Unable to create token ', $token->{label}, ': pin not between 4 and 255 characters');
                    undef($cmd_cb);
                    return;
                }
                Lim::Util::run_cmd
                    [
                        'softhsm',
                        '--init-token',
                        '--slot', $token->{slot},
                        '--label', $token->{label},
                        '--so-pin', $token->{so_pin},
                        '--pin', $token->{pin}
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
                            $self->Error($cb, 'Unable to create token ', $token->{label});
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

=item $server->CreateImport(...)

Import a key into a slot.

=cut

sub CreateImport {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{softhsm}) {
        $self->Error($cb, 'No "softhsm" executable found or unsupported version, unable to continue');
        return;
    }
    
    my @key_pairs = ref($q->{key_pair}) eq 'ARRAY' ? @{$q->{key_pair}} : ($q->{key_pair});

    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $key_pair = shift(@key_pairs)) {
            my $tmp = Lim::Util::FileWriteContent($key_pair->{content});
            unless (defined $tmp) {
                $self->Error($cb, 'Unable to write content key pair id ', $key_pair->{id}, ' to a file');
                undef($cmd_cb);
                return;
            }
            my ($stdout, $stderr);
            Lim::Util::run_cmd
                [
                    'softhsm',
                    '--import', $tmp->filename,
                    '--slot', $key_pair->{slot},
                    '--pin', $key_pair->{pin},
                    '--label', $key_pair->{label},
                    '--id', $key_pair->{id},
                    (exists $key_pair->{file_pin} ? ('--file-pin', $key_pair->{file_pin}) : ())
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
                    undef($tmp);
                    unless (defined $self) {
                        undef($cmd_cb);
                        return;
                    }
                    if (shift->recv) {
                        $self->Error($cb, 'Unable to import key_pair id ', $key_pair->{id});
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

=item $server->ReadExport(...)

Export a key from a slot.

=cut

sub ReadExport {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{softhsm}) {
        $self->Error($cb, 'No "softhsm" executable found or unsupported version, unable to continue');
        return;
    }
    
    my @key_pairs = ref($q->{key_pair}) eq 'ARRAY' ? @{$q->{key_pair}} : ($q->{key_pair});
    my @exports;

    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $key_pair = shift(@key_pairs)) {
            my $tmp = Lim::Util::TempFile;
            my ($stdout, $stderr);
            Lim::Util::run_cmd
                [
                    'softhsm',
                    '--export', $tmp->filename,
                    '--slot', $key_pair->{slot},
                    '--pin', $key_pair->{pin},
                    '--id', $key_pair->{id},
                    (exists $key_pair->{file_pin} ? ('--file-pin', $key_pair->{file_pin}) : ())
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
                        $self->Error($cb, 'Unable to export key_pair id ', $key_pair->{id});
                        undef($cmd_cb);
                    }
                    elsif (defined (my $content = Lim::Util::FileReadContent($tmp->filename))) {
                        push(@exports, {
                            id => $key_pair->{id},
                            content => $content
                        });
                        $cmd_cb->();
                    }
                    else {
                        $self->Error($cb, 'Unable to read export key_pair id ', $key_pair->{id}, ' file ', $tmp->filename);
                        undef($cmd_cb);
                    }
                };
        }
        else {
            if (scalar @exports == 1) {
                $self->Successful($cb, { key_pair => $exports[0] });
            }
            elsif (scalar @exports) {
                $self->Successful($cb, { key_pair => \@exports });
            }
            else {
                $self->Successful($cb);
            }
            undef($cmd_cb);
        }
    };
    $cmd_cb->();
}

=item $server->UpdateOptimize(...)

Optimize the SoftHSM database.

=cut

sub UpdateOptimize {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{softhsm}) {
        $self->Error($cb, 'No "softhsm" executable found or unsupported version, unable to continue');
        return;
    }
    
    my @slots = ref($q->{slot}) eq 'ARRAY' ? @{$q->{slot}} : ($q->{slot});

    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $slot = shift(@slots)) {
            my ($stdout, $stderr);
            Lim::Util::run_cmd
                [
                    'softhsm',
                    '--optimize',
                    '--slot', $slot->{id},
                    '--pin', $slot->{pin}
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
                        $self->Error($cb, 'Unable to optimize softhsm');
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

=item $server->UpdateTrusted(...)

Update the trusted status of a key.

=cut

sub UpdateTrusted {
    my ($self, $cb, $q) = @_;
    
    unless ($self->{bin}->{softhsm}) {
        $self->Error($cb, 'No "softhsm" executable found or unsupported version, unable to continue');
        return;
    }
    
    my @key_pairs = ref($q->{key_pair}) eq 'ARRAY' ? @{$q->{key_pair}} : ($q->{key_pair});

    weaken($self);
    my $cmd_cb; $cmd_cb = sub {
        unless (defined $self) {
            undef($cmd_cb);
            return;
        }
        if (my $key_pair = shift(@key_pairs)) {
            unless (exists $key_pair->{id} or exists $key_pair->{label}) {
                $self->Error($cb, 'Unable to mark key pair trusted, no id or label given');
                undef($cmd_cb);
                return;
            }
            if (exists $key_pair->{id} and exists $key_pair->{label}) {
                $self->Error($cb, 'Unable to mark key pair trusted, both id and label given');
                undef($cmd_cb);
                return;
            }
            
            my ($stdout, $stderr);
            Lim::Util::run_cmd
                [
                    'softhsm',
                    '--trusted', $key_pair->{trusted} ? 'true' : 'false',
                    '--slot', $key_pair->{slot},
                    '--so-pin', $key_pair->{so_pin},
                    '--type', $key_pair->{type},
                    (exists $key_pair->{id} ? ('--id', $key_pair->{id}) : ()),
                    (exists $key_pair->{label} ? ('--label', $key_pair->{label}) : ())
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
                        $self->Error($cb, 'Unable to mark key pair ',
                            (exists $key_pair->{id} ? ('id ', $key_pair->{id}) : ()),
                            (exists $key_pair->{label} ? ('label ', $key_pair->{label}) : ()),
                            ' trusted ',
                            $key_pair->{trusted} ? 'true' : 'false');
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

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim-plugin-softhsm/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Plugin::SoftHSM

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim-plugin-softhsm/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::Plugin::SoftHSM::Server
