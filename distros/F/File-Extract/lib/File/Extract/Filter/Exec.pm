# $Id: /mirror/perl/File-Extract/trunk/lib/File/Extract/Filter/Exec.pm 4210 2007-10-27T13:43:07.499967Z daisuke  $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package File::Extract::Filter::Exec;
use strict;
use base qw(File::Extract::Filter::Base);
use IO::Scalar;
use IPC::Open2;
use UNIVERSAL::isa;

sub new
{
    my $class = shift;
    my %args  = @_;

    my $self = bless { cmd => $args{cmd} }, $class;
    return $self;
}

sub cmd { shift->{cmd} }

sub filter
{
    my $self = shift;
    my %args = @_;

    my $file = $args{file};
    my $o = $args{output};
    my $output = 
        (ref($o) && UNIVERSAL::isa($o, 'GLOB'))   ? $o :
        (ref($o) && UNIVERSAL::isa($o, 'SCALAR')) ? IO::Scalar->new($o) :
        die "output must be a GLOB or ref to SCALAR";

    my $cmd = $self->cmd; # XXX - if we wanted to be paranoid, we need to
                          # cleanse this guy, but oh well..
=head1
    if ($cmd !~ /\|\s*$/) {
        $cmd .= " |"; # make sure it's piped
    }
    if ($cmd !~ /^\s*\|$/) {
        $cmd = "| " . $cmd; # make sure it's piped
    }
=cut

    open(my $input, $file) or die "Failed to open file $file: $!";
    my($p_read, $p_write);
    open2($p_read, $p_write, $cmd) or die "Failed to execute $cmd";

    while (<$input>) {
        print $p_write $_;
    }
    close($input);
    close($p_write);

    while (<$p_read>) {
        print $output $_;
    }
    close($p_read);
}

1;

__END__

=head1 NAME

File::Extract::Filter::Exec - Execute A Command To Filter File Contents

=head1 SYNOPSIS

  use File::Extract::Filter::Exec;

  my $filter = File::Extract::Filter::Exec->new(
    cmd => "/usr/bin/pdf2html",
    output => $output
  )

  $filter->filter($file);

=head1 DESCRIPTION

This filter executes a command, and writes the filtered output into a temporary
file such that the new temporary file can be passed to

=cut
