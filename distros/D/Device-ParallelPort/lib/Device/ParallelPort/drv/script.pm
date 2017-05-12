package Device::ParallelPort::drv::script;
use strict;
use Carp;

=head1 NAME

Device::ParallelPort::drv::script - Call a script to do your hardware actions

=head1 DESCRIPTION

This basic drive allows you to write a completely seperate piece of code to 
control the bits, and still allow the usual interface. This is fairly pointeless 
interface by itself but does allow for testing and unusal circumstances.

Really there is not much point in this module, however it was useful at one
time to me, and therefore may be to others.

=head1 CAPABILITIES

=head2 Operating System

Totally depends on the scripts available... but this code is independent.

=head2 Special Requirements

Anything special about the scripts, eg: root/not etc. If the script requires
root access then so does this system (unless you are using unix setuid)

Script parameters

The script has the following substituted before execution automatically.
Things like port should be included in the parameter automatically.

        {offset}        Which byte to set, from 0
        {byte}          What is the byte to set

=head1 HOW IT WORKS

=head1 LIMITATIONS

This system can only write a byte to the output script, it uses the previouslly
set values to return the current state of the output.

If you want to set the base port address, that is up to you in the script. 
For example your script could be along the lines of

	myscript 0x378 {offset} {byte}

=head1 COPYRIGHT

Copyright (c) 2002,2004 Scott Penrose. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Scott Penrose L<scottp@dd.com.au>, L<http://linux.dd.com.au/>

=head1 SEE ALSO

L<Device::ParallelPort>

=cut

use base qw/Device::ParallelPort::drv/;

sub init {
        my ($this, $str, @params) = @_;
        $this->{DATA}{SCRIPT} = $str;
        my ($script, $rest) = split(/ /, $str, 2);
        unless (-x $script) {
                croak "Must provide a script as the parameter, $script not executable";
        }
        $this->{BYTES} = [];
}

sub INFO {
        return {
                'os' => 'any',
                'type' => 'byte',
        };
}

sub set_byte {
        my ($this, $byte, $val) = @_;

        # Get the script and the byte
        my $script = $this->{DATA}{SCRIPT};
        $this->{BYTES}[$byte] = $val;

        # Set the values
        $script =~ s/{offset}/$byte/g;
        $script =~ s/{byte}/$val/g;

        # Execute
        print STDERR "Script exec - $script\n" if ($this->{DEBUG});
        system($script);
}

sub get_byte {
        my ($this, $byte) = @_;
        return $this->{BYTES}[$byte];
}

1;

