package Linux::IO_Prio;

use strict;
use warnings;

require Exporter;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $VERSION);
use POSIX qw(ENOSYS);
use Carp;

$VERSION     = '0.03';
@ISA         = qw(Exporter);
%EXPORT_TAGS = (ionice => [qw(&ionice &ionice_class &ionice_data)],
	        c_api => [qw(&ioprio_set &ioprio_get)],
		macros => [qw(IOPRIO_PRIO_VALUE IOPRIO_PRIO_CLASS IOPRIO_PRIO_DATA)],
		who => [qw(IOPRIO_WHO_PROCESS IOPRIO_WHO_PGRP IOPRIO_WHO_USE)],
		class => [qw(IOPRIO_CLASS_NONE IOPRIO_CLASS_RT IOPRIO_CLASS_BE IOPRIO_CLASS_IDLE)]
	       );
# The tag lists are exclusive at the moment, so don't worry about duplicates.
push @{$EXPORT_TAGS{all}}, @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
Exporter::export_ok_tags($_) foreach keys %EXPORT_TAGS;

use constant IOPRIO_CLASS_SHIFT => 13;
use constant IOPRIO_PRIO_MASK => ((1 << IOPRIO_CLASS_SHIFT) - 1);
use constant {
    IOPRIO_WHO_PROCESS => 1,
    IOPRIO_WHO_PGRP => 2,
    IOPRIO_WHO_USER => 3
};
use constant {
    IOPRIO_CLASS_NONE => 0,
    IOPRIO_CLASS_RT => 1,
    IOPRIO_CLASS_BE => 2,
    IOPRIO_CLASS_IDLE => 3
};

if ($^O eq 'linux') {
    _load_syscall();
}
else {
    warn "Linux::IO_Prio: unsupported operating system -- $^O\n";
}

# Load syscall.ph
sub _load_syscall {
    return eval{require('syscall.ph') || require('sys/syscall.ph')};
}

# C API functions
# int ioprio_get(int which, int who);
sub ioprio_get {
    my ($which, $who) = @_;
    if (defined &SYS_ioprio_get) {
        return syscall(SYS_ioprio_get(), $which, $who);
    }
    else {
	return _not_implemented();
    }
}

# int ioprio_set(int which, int who, int ioprio);
sub ioprio_set {
    my ($which, $who, $ioprio) = @_;
    if (defined &SYS_ioprio_set) {
	return syscall(SYS_ioprio_set(), $which, $who, $ioprio);
    }
    else {
	return _not_implemented();
    }
}

# C API Macros
sub IOPRIO_PRIO_VALUE {
    my ($class, $data) =  @_;
    return ($class << IOPRIO_CLASS_SHIFT) | $data;
}

sub IOPRIO_PRIO_CLASS {
    my ($mask) = @_;
    return ($mask >> IOPRIO_CLASS_SHIFT);
}

sub IOPRIO_PRIO_DATA {
    my ($mask) = @_;
    return ($mask & IOPRIO_PRIO_MASK);
}

# Wrapper functions
sub ionice {
    my ($which, $who, $class, $data) = @_;
    carp "Data not permitted for class IOPRIO_CLASS_IDLE" if $class == IOPRIO_CLASS_IDLE && $data;
    return ioprio_set($which, $who, IOPRIO_PRIO_VALUE($class, $data));
}

sub ionice_class {
    my ($which, $who) = @_;
    if((my $priority = ioprio_get($which, $who)) < 0) {
	return $priority;
    }
    else {
	return IOPRIO_PRIO_CLASS($priority);	
    }
}

sub ionice_data {
    my ($which, $who) = @_;
    if((my $priority = ioprio_get($which, $who)) < 0) {
	return $priority;
    }
    else {
	return IOPRIO_PRIO_DATA($priority);
    }
}

# Stub for not implemented
sub _not_implemented {
    $! = ENOSYS;
    return -1;
}

1;
__END__

=head1 NAME

Linux::IO_Prio - Interface to Linux ioprio_set and ioprio_get via syscall or ionice wrapper.

=head1 SYNOPSIS

	use Linux::IO_Prio qw(:all);

	my $status = ioprio_set(IOPRIO_WHO_PROCESS, $$,
		IOPRIO_PRIO_VALUE(IOPRIO_CLASS_IDLE, 0));

        my $status = ionice(IOPRIO_WHO_PROCESS, $$, IOPRIO_CLASS_IDLE, 0);

=head1 DESCRIPTION

Use L<ioprio_get(2)> and L<ioprio_set(2)> from Perl.  Only Linux is supported
currently. Support for other unices will be added once the kernel capabilities
are available.

=head1 Exports

Nothing by default.

The required exports can be specified individually or by tag:

=over 4

=item :ionice -- ionice ionice_data ionice_class

=item :c_api -- ioprio_set ioprio_get

=item :macro -- IOPRIO_PRIO_VALUE IOPRIO_PRIO_CLASS IOPRIO_PRIO_DATA

=item :who -- IOPRIO_WHO_PROCESS IOPRIO_WHO_PGRP IOPRIO_WHO_USER

=item :class -- IOPRIO_CLASS_NONE IOPRIO_CLASS_RT IOPRIO_CLASS_BE IOPRIO_CLASS_IDLE 

=item :all -- all the above

=back

ionice(), ionice_class() and ionice_data() are thin wrappers around the C API
allowing conventient single function calls.  All of the other exports have the
same meaning and prototypes as the C API equivalents. See man L<ioprio_set(2)>
for further details.

=head2 Functions

=head3 C API

=over

=item $priority = ioprio_get($which, $who)

=item $staus = ioprio_set($which, $who, $priority)

=back

=head3 Wrappers

=over

=item $status = ionice($which, $who, $class, $data)

=item $class = ionice_class($which, $who)

=item $data = ionice_data($which, $who)

=back

=head2 MACROS

=over 4

=item $priority = IOPRIO_PRIO_VALUE($class, $data)

=item $class = IOPRIO_PRIO_CLASS($mask)

=item $data = IOPRIO_PRIO_DATA ($mask)

=back

=head2 CONSTANTS

=over 4

=item IOPRIO_WHO_PROCESS

=item IOPRIO_WHO_PGRP

=item IOPRIO_WHO_USER

=item IOPRIO_CLASS_NONE

=item IOPRIO_CLASS_RT

=item IOPRIO_CLASS_BE

=item IOPRIO_CLASS_IDLE

=back

=head1 COPYRIGHT

This module is Copyright (c) 2011 Mark Hindley

All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.
If you need more liberal licensing terms, please contact the
maintainer.

=head1 WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 AUTHOR

Mark Hindley <mark@hindley.org.uk>
