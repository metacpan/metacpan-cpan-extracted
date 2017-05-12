package IPC::ShellCmd::ShBase;

use strict;
use String::ShellQuote qw(shell_quote);
use Carp qw(croak);

=head1 NAME

  IPC::ShellCmd::ShBase - Base class for shell commands

=head1 SYNOPSIS

  package IPC::ShellCmd::Other;
  use base qw/IPC::ShellCmd::ShBase/;
  # Note that this is an abstract class..

=head1 DESCRIPTION

Abstract base class for other IPC::ShellCmd command types.

=cut

sub new {
    my $package = shift;
    my %args = @_;

    my $self = bless { args => \%args }, $package;

    return $self;
}

sub chain {
    croak "Abstract Class";
}

sub generate_sh_cmd {
    my $self = shift;
    my $cmd = shift;
    my $args = shift;

    my $cmd_string = shell_quote(@$cmd);

    if(defined $args->{'-stdin'}) {
	$cmd_string .= ' < ' . shell_quote($args->{'-stdin'});
    }
    if(defined $args->{'-stdout'}) {
	$cmd_string .= ' > ' . shell_quote($args->{'-stdout'});
    }
    if(defined $args->{'-stderr'}) {
	$cmd_string .= ' 2> ' . shell_quote($args->{'-stderr'});
    }

    if($args->{'-env'}) {
	for my $k (keys %{$args->{'-env'}}) {
	    $cmd_string = $k . "=" . shell_quote($args->{'-env'}->{$k}) . ' ' .
		$cmd_string;
	}
    }

    if(defined $args->{'-umask'}) {
	$cmd_string = sprintf('umask 0%o && %s', $args->{'-umask'}, $cmd_string);
    }

    if(defined $args->{'-wd'}) {
	$cmd_string = sprintf('cd %s && %s', shell_quote($args->{'-wd'}),
	    $cmd_string);
    }

    return $cmd_string;
}

=head1 BUGS

I don't know of any, but that doesn't mean they're not there.

=head1 AUTHORS

See L<IPC::ShellCmd> for authors.

=head1 LICENSE

See L<IPC::ShellCmd> for the license.

=cut

1;
