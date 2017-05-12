package Lim::Plugin::SoftHSM::CLI;

use common::sense;

use Getopt::Long ();
use Scalar::Util qw(weaken);

use Lim::Plugin::SoftHSM ();

use Lim::Util ();

use base qw(Lim::Component::CLI);

=encoding utf8

=head1 NAME

Lim::Plugin::SoftHSM::CLI - CLI class for SoftHSM management plugin

=head1 VERSION

See L<Lim::Plugin::SoftHSM> for version.

=cut

our $VERSION = $Lim::Plugin::SoftHSM::VERSION;

=head1 SYNOPSIS

  use Lim::Plugin::SoftHSM;

  # Create a CLI object
  $client = Lim::Plugin::SoftHSM->CLI;

=head1 METHODS

These methods are called from the Lim framework and should not be used else
where.

Please see L<Lim::Plugin::SoftHSM> for full documentation of calls.

=over 4

=item version

Show version of the plugin and SoftHSM.

=cut

sub version {
    my ($self) = @_;
    my $softhsm = Lim::Plugin::SoftHSM->Client;
    
    weaken($self);
    $softhsm->ReadVersion(sub {
        my ($call, $response) = @_;
        
        unless (defined $self) {
            undef($softhsm);
            return;
        }
        
        if ($call->Successful) {
            $self->cli->println('SoftHSM plugin version ', $response->{version});
            if (exists $response->{program}) {
                $self->cli->println('SoftHSM programs:');
                foreach my $program (ref($response->{program}) eq 'ARRAY' ? @{$response->{program}} : $response->{program}) {
                    $self->cli->println('    ', $program->{name}, ' version ', $program->{version});
                }
            }
            $self->Successful;
        }
        else {
            $self->Error($call->Error);
        }
        undef($softhsm);
    });
}


=item configs

List configuration files.

=cut

sub configs {
    my ($self) = @_;
    my $softhsm = Lim::Plugin::SoftHSM->Client;
    
    weaken($self);
    $softhsm->ReadConfigs(sub {
        my ($call, $response) = @_;
        
        unless (defined $self) {
            undef($softhsm);
            return;
        }
        
        if ($call->Successful) {
            $self->cli->println('SoftHSM config files found:');
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
        undef($softhsm);
    });
}

=item config view <file>

Display the content of a configuration file.

=item config edit <file>

Edit a configuration file.

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
            my $softhsm = Lim::Plugin::SoftHSM->Client;
            weaken($self);
            $softhsm->ReadConfig({
                file => {
                    name => $args->[1]
                }
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($softhsm);
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
                undef($softhsm);
            });
            return;
        }
    }
    elsif ($args->[0] eq 'edit') {
        if (defined $args->[1]) {
            my $softhsm = Lim::Plugin::SoftHSM->Client;
            weaken($self);
            $softhsm->ReadConfig({
                file => {
                    name => $args->[1]
                }
            }, sub {
                my ($call, $response) = @_;
                
                unless (defined $self) {
                    undef($softhsm);
                    return;
                }
                
                if ($call->Successful) {
                    my $w; $w = AnyEvent->timer(
                        after => 0,
                        cb => sub {
                            if (defined (my $content = $self->cli->Editor($response->{file}->{content}))) {
                                my $softhsm = Lim::Plugin::SoftHSM->Client;
                                $softhsm->UpdateConfig({
                                    file => {
                                        name => $args->[1],
                                        content => $content
                                    }
                                }, sub {
                                    my ($call, $response) = @_;
                                    
                                    unless (defined $self) {
                                        undef($softhsm);
                                        return;
                                    }
                                    
                                    if ($call->Successful) {
                                        $self->cli->println('Config updated');
                                        $self->Successful;
                                    }
                                    else {
                                        $self->Error($call->Error);
                                    }
                                    undef($softhsm);
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
                undef($softhsm);
            });
            return;
        }
    }
    $self->Error;
}

=item show slots

List information about SoftHSM slots.

=cut

sub show {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);
    
    unless ($getopt and scalar @$args) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'slots') {
        my $softhsm = Lim::Plugin::SoftHSM->Client;
        weaken($self);
        $softhsm->ReadShowSlots(sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($softhsm);
                return;
            }
            
            if ($call->Successful) {
                if (exists $response->{slot}) {
                    $self->cli->println(join("\t", 'Slot', 'Token Label', 'Token Present', 'Token Initialized', 'User Pin Initialized'));
                    foreach my $slot (ref($response->{slot}) eq 'ARRAY' ? @{$response->{slot}} : $response->{slot}) {
                        $self->cli->println(join("\t",
                            $slot->{id},
                            $slot->{token_label},
                            $slot->{token_present} ? 'Yes' : 'No',
                            $slot->{token_initialized} ? 'Yes' : 'No',
                            $slot->{user_pin_initialized} ? 'Yes' : 'No'
                        ));
                    }
                }
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($softhsm);
        });
        return;
    }
    $self->Error;
}

=item init token <slot> <label> <SO pin> <pin>

Initialize a slot.

=cut

sub init {
    my ($self, $cmd) = @_;
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd);
    
    unless ($getopt and scalar @$args) {
        $self->Error;
        return;
    }

    if ($args->[0] eq 'token' and scalar @$args == 5) {
        my (undef, $slot, $label, $so_pin, $pin) = @$args;
        my $softhsm = Lim::Plugin::SoftHSM->Client;
        weaken($self);
        $softhsm->CreateInitToken({
            token => {
                slot => $slot,
                label => $label,
                so_pin => $so_pin,
                pin => $pin
            }
        }, sub {
            my ($call, $response) = @_;
            
            unless (defined $self) {
                undef($softhsm);
                return;
            }
            
            if ($call->Successful) {
                $self->cli->println('Token created');
                $self->Successful;
            }
            else {
                $self->Error($call->Error);
            }
            undef($softhsm);
        });
        return;
    }
    $self->Error;
}

=item import [--slot <slot>] [--pin <pin>] [--id <id>] [--label <label>] [--file-pin <file pin>] <file>

Import a key into SoftHSM from a local file.

=cut

sub import {
    my ($self, $cmd) = @_;
    my ($slot, $pin, $label, $id, $file_pin);
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd,
        'slot=s' => \$slot,
        'pin=s' => \$pin,
        'label=s' => \$label,
        'id=s' => \$id,
        'file-pin:s' => \$file_pin
    );
    
    unless ($getopt and scalar @$args == 1 and defined $slot and defined $pin and defined $label and defined $id) {
        $self->Error;
        return;
    }

    my $content = Lim::Util::FileReadContent($args->[0]);
    unless (defined $content) {
        $self->Error;
        return;
    }

    my $softhsm = Lim::Plugin::SoftHSM->Client;
    weaken($self);
    $softhsm->CreateImport({
        key_pair => {
            content => $content,
            slot => $slot,
            pin => $pin,
            label => $label,
            id => $id,
            (defined $file_pin ? (file_pin => $file_pin) : ())
        }
    }, sub {
        my ($call, $response) = @_;
        
        unless (defined $self) {
            undef($softhsm);
            return;
        }
        
        if ($call->Successful) {
            $self->cli->println('Key pair imported');
            $self->Successful;
        }
        else {
            $self->Error($call->Error);
        }
        undef($softhsm);
    });
}

=item export [--slot <slot>] [--pin <pin>] [--id <id>] [--file-pin <file pin>] <file>

Export a key from SoftHSM into a local file.

=cut

sub export {
    my ($self, $cmd) = @_;
    my ($slot, $pin, $id, $file_pin);
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd,
        'slot=s' => \$slot,
        'pin=s' => \$pin,
        'id=s' => \$id,
        'file-pin:s' => \$file_pin
    );
    
    unless ($getopt and scalar @$args == 1 and defined $slot and defined $pin and defined $id) {
        $self->Error;
        return;
    }

    my $softhsm = Lim::Plugin::SoftHSM->Client;
    weaken($self);
    $softhsm->ReadExport({
        key_pair => {
            slot => $slot,
            pin => $pin,
            id => $id,
            (defined $file_pin ? (file_pin => $file_pin) : ())
        }
    }, sub {
        my ($call, $response) = @_;
        
        unless (defined $self) {
            undef($softhsm);
            return;
        }
        
        if ($call->Successful) {
            if (exists $response->{key_pair}) {
                foreach my $key_pair (ref($response->{key_pair}) eq 'ARRAY' ? @{$response->{key_pair}} : $response->{key_pair}) {
                    if (Lim::Util::FileWriteContent($args->[0], $key_pair->{content})) {
                        $self->cli->println('Key pair exported to file ', $args->[0]);
                    }
                    else {
                        $self->cli->println('Unable to write key pair content to file ', $args->[0]);
                    }
                    last;
                }
            }
            $self->Successful;
        }
        else {
            $self->Error($call->Error);
        }
        undef($softhsm);
    });
}

=item optimize [--pin <pin>] <slots ... >

Optimize slot(s).

=cut

sub optimize {
    my ($self, $cmd) = @_;
    my ($pin);
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd,
        'pin=s' => \$pin
    );
    
    unless ($getopt and scalar @$args and defined $pin) {
        $self->Error;
        return;
    }

    my @slots;
    foreach (@$args) {
        push(@slots, {
            id => $_,
            pin => $pin
        });
    }
    
    my $softhsm = Lim::Plugin::SoftHSM->Client;
    weaken($self);
    $softhsm->UpdateOptimize({
        slot => \@slots 
    }, sub {
        my ($call, $response) = @_;
        
        unless (defined $self) {
            undef($softhsm);
            return;
        }
        
        if ($call->Successful) {
            $self->cli->println('Optimize complete');
            $self->Successful;
        }
        else {
            $self->Error($call->Error);
        }
        undef($softhsm);
    });
}

=item trust [--slot <slot>] [--so-pin <SO pin>] [--type <type>] < --id <id> | --label <label> >

Mark a key as trusted.

=cut

sub trust {
    my ($self, $cmd) = @_;
    my ($slot, $so_pin, $type, $id, $label);
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd,
        'slot=s' => \$slot,
        'so-pin=s' => \$so_pin,
        'type=s' => \$type,
        'id:s' => \$id,
        'label:s' => \$label
    );
    
    unless ($getopt and defined $slot and defined $so_pin and defined $type and (defined $id or defined $label)) {
        $self->Error;
        return;
    }

    my $softhsm = Lim::Plugin::SoftHSM->Client;
    weaken($self);
    $softhsm->UpdateTrusted({
        key_pair => {
            trusted => 'true',
            slot => $slot,
            so_pin => $so_pin,
            type => $type,
            (defined $id ? (id => $id) : ()),
            (defined $label ? (label => $label) : ())
        }
    }, sub {
        my ($call, $response) = @_;
        
        unless (defined $self) {
            undef($softhsm);
            return;
        }
        
        if ($call->Successful) {
            $self->cli->println('Key pair marked trusted');
            $self->Successful;
        }
        else {
            $self->Error($call->Error);
        }
        undef($softhsm);
    });
}

=item untrust [--slot <slot>] [--so-pin <SO pin>] [--type <type>] < --id <id> | --label <label> >

Remove the trusted marking on a key.

=cut

sub untrust {
    my ($self, $cmd) = @_;
    my ($slot, $so_pin, $type, $id, $label);
    my ($getopt, $args) = Getopt::Long::GetOptionsFromString($cmd,
        'slot=s' => \$slot,
        'so-pin=s' => \$so_pin,
        'type=s' => \$type,
        'id:s' => \$id,
        'label:s' => \$label
    );
    
    unless ($getopt and defined $slot and defined $so_pin and defined $type and (defined $id or defined $label)) {
        $self->Error;
        return;
    }

    my $softhsm = Lim::Plugin::SoftHSM->Client;
    weaken($self);
    $softhsm->UpdateTrusted({
        key_pair => {
            trusted => 'false',
            slot => $slot,
            so_pin => $so_pin,
            type => $type,
            (defined $id ? (id => $id) : ()),
            (defined $label ? (label => $label) : ())
        }
    }, sub {
        my ($call, $response) = @_;
        
        unless (defined $self) {
            undef($softhsm);
            return;
        }
        
        if ($call->Successful) {
            $self->cli->println('Key pair marked unstrusted');
            $self->Successful;
        }
        else {
            $self->Error($call->Error);
        }
        undef($softhsm);
    });
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

1; # End of Lim::Plugin::SoftHSM::CLI
