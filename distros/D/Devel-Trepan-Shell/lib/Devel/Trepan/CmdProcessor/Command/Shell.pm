# Copyright (C) 2011-2012, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

package Devel::REPL::Plugin::TrepanShell;

use Devel::REPL::Plugin;
use namespace::clean -except => [ 'meta' ];

has 'history' => (
   isa => 'ArrayRef', is => 'rw', required => 1, lazy => 1,
   default => sub { [] }
);

around 'read' => sub {
   my $orig = shift;
   my ($self, @args) = @_;
   my $line = $self->$orig(@args);
   if (defined $line) {
      if ($line =~ m/^%(.*)$/) {
         $Devel::REPL::Plugin::TrepanShell::DEBUGGER_COMMAND = $1;
         return undef;
      }
   }
   return $line;
};

my $repl;
use rlib '../../../..';
package Devel::Trepan::CmdProcessor::Command::Shell;
use vars qw($DEBUGGER_COMMAND);
use Devel::Trepan::CmdProcessor::Command;
use English;
no strict;
use if !@ISA, Devel::Trepan::CmdProcessor::Command ;
unless (@ISA) {
    eval <<"EOE";
use constant ALIASES    => ('re.pl');
use constant CATEGORY   => 'support';
use constant SHORT_HELP => 'Run a shell via re.pl';
use constant NEED_STACK => 0;
use constant MIN_ARGS   => 0;  # Need at least this many
use constant MAX_ARGS   => 0;  # Need at most this many - undef -> unlimited.
EOE
}

use strict;
our @ISA = @CMD_ISA;  # value inherited from parent
use vars @CMD_VARS;   # value inherited from parent

our $NAME = set_name();
=head2 Synopsis:

=cut
our $HELP = <<"HELP";
=pod

B<shell>

Run a command shell via Devel::REPL

To issue a debugger command inside the shell start the line with a '%'
For example:

   %info program  # shows debugged program information


To leave the shell enter a single .

=head2 See also:

L<C<eval>|Devel::Trepan::CmdProcessor::Command::Eval>
=cut
HELP

# sub complete($$)
# {
#     my ($self, $prefix) = @_;
#     my @completions = sort ('.', DB::LineCache::file_list());
#     Devel::Trepan::Complete::complete_token(\@completions, $prefix);
# }

use Devel::REPL;
# This method runs the command
sub run($$)
{
  my ($self, $args) = @_;
  my $proc = $self->{proc};
  unless (defined($repl)) {
    my $input = $proc->{interfaces}[-1]{input};
    my $prompt = "\ntrepan.pl>> ";
    if (UNIVERSAL::isa( $input, "HASH" )) {
      $repl = Devel::REPL->new( prompt => $prompt,
				term => $input->{readline} );
    } else {
      $repl = Devel::REPL->new( prompt => $prompt);
    }
    $repl->load_plugin('LexEnv');         # 'my' variables should persist.
    $repl->load_plugin('MultiLine::PPI'); # for indent depth
    $repl->load_plugin('Packages');       # for current package
    $repl->load_plugin('TrepanShell');       # for current package
    $self->msg("To issue a debugger command inside the shell start the line with a '%'");
    $self->msg("To leave the shell enter a single '%'");
  }

  while (!$proc->{leave_cmd_loop}) {
    $DEBUGGER_COMMAND='';
    eval {
      $repl->run;
    };
    if ($EVAL_ERROR) {
      $self->errmsg($EVAL_ERROR);
    }
    my $cmd = $Devel::REPL::Plugin::TrepanShell::DEBUGGER_COMMAND;
    if ($cmd) {
      $proc->run_command($cmd);
    } else { last; }
  }
}

unless (caller) {
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
    my $cmd = __PACKAGE__->new($proc);
    $cmd->run([$NAME]);
}

1;
