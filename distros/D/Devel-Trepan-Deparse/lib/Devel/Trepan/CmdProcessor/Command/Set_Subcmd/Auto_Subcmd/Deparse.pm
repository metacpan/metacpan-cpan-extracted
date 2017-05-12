# -*- coding: utf-8 -*-
# Copyright (C) 2015 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';

use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;

package Devel::Trepan::CmdProcessor::Command::Set::Auto::Deparse;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::SetBoolSubsubcmd);
# Values inherited from parent

use vars @Devel::Trepan::CmdProcessor::Command::Subsubcmd::SUBCMD_VARS;

our $IN_LIST      = 1;
our $HELP         = <<'HELP';
=pod

B<set auto deparse> [B<on>|B<off>]

Set to run a C<deparse> when there is an ambiguity in line number.

=head2 See also:

L<C<show auto deparse>|Devel::Trepan::CmdProcessor::Command::Show::Auto::List>

=cut
HELP

our $MIN_ABBREV   = length('de');
use constant MAX_ARGS => 1;
our $SHORT_HELP   = "show deparse output on line ambiguity";

sub new
{
    my ($class, $parent, $name) = @_;
    my $self = Devel::Trepan::CmdProcessor::Command::Subsubcmd::new($class, $parent, $name);
    bless $self, $class;
    my $deparse_cmd = $self->{proc}{commands}{'deparse'};
    $self->{autodeparse_hook}  = ['autodeparse',
                               sub{ $deparse_cmd->run(['deparse']) if $deparse_cmd}];
    return $self
}

sub run($$)
{
    my ($self, $args) = @_;
    $self->SUPER::run($args);
    my $proc = $self->{proc};
    if ( $proc->{settings}{autodeparse} ) {
        $proc->{cmdloop_prehooks}->insert_if_new(10, $self->{autodeparse_hook}[0],
                                                 $self->{autodeparse_hook}[1]);
    } else {
        $proc->{cmdloop_prehooks}->delete_by_name('autodeparse');
    }


}

unless (caller) {
  # Demo it.
  # require_relative '../../../mock'
  # name = File.basename(__FILE__, '.rb')

  # dbgr, set_cmd = MockDebugger::setup('set')
  # max_cmd       = Trepan::SubSubcommand::SetMax.new(dbgr.core.processor,
  #                                                     set_cmd)
  # cmd_ary       = Trepan::SubSubcommand::SetMaxList::PREFIX
  # cmd_name      = cmd_ary.join(' ')
  # subcmd        = Trepan::SubSubcommand::SetMaxList.new(set_cmd.proc,
    #                                                        max_cmd,
  #                                                        cmd_name)
  # prefix_run = cmd_ary[1..-1]
  # subcmd.run(prefix_run)
  # subcmd.run(prefix_run + %w(0))
  # subcmd.run(prefix_run + %w(20))
  # name = File.basename(__FILE__, '.rb')
  # subcmd.summary_help(name)
  # puts
  # puts '-' * 20
  # puts subcmd.save_command
}

1;
