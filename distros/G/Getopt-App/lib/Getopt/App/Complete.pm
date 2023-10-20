package Getopt::App::Complete;
use feature qw(:5.16);
use strict;
use warnings;
use utf8;
use Cwd            qw(abs_path);
use File::Basename qw(basename);
use Exporter       qw(import);

our @EXPORT_OK = qw(complete_reply generate_completion_script);

require Getopt::App;
our $call_maybe = do { no warnings qw(once); $Getopt::App::call_maybe };

sub complete_reply {
  my $app = shift;
  my ($script, @argv) = split /\s+/, $ENV{COMP_LINE};

  # Recurse into subcommand
  no warnings qw(once);
  my $depth       = $Getopt::App::DEPTH;
  my $subcommands = $app->$call_maybe('getopt_subcommands') || [];
  if ($argv[$depth] and $argv[$depth] =~ m!^\w! and @$subcommands) {
    my $argv = [@argv[$depth, $#argv]];
    for my $subcommand (@$subcommands) {
      next unless $argv[$depth] eq $subcommand->[0];
      my $cb = $Getopt::App::APPS{$subcommand->[1]} ||= $app->$call_maybe(getopt_load_subcommand => $subcommand, $argv);
      local $Getopt::App::SUBCOMMAND = $subcommand;
      return $cb->([@$argv[1 .. $#$argv]]);
    }
  }

  # List matching subcommands
  my $got = substr($ENV{COMP_LINE}, 0, $ENV{COMP_POINT}) =~ m!(\S+)$! ? $1 : '';
  for my $subcommand (@$subcommands) {
    say $subcommand->[0] if index($subcommand->[0], $got) == 0;
  }

  # List matching command line options
  no warnings q(once);
  for (@{$Getopt::App::OPTIONS || []}) {
    my $opt = $_;
    $opt =~ s!(=[si][@%]?|\!|\+|\s)(.*)!!;
    ($opt) = sort { length $b <=> length $a } split /\|/, $opt;    # use --version instead of -v
    $opt = length($opt) == 1 ? "-$opt" : "--$opt";
    next unless index($opt, $got) == 0;
    say $opt;
  }

  return 0;
}

sub generate_completion_script {
  my $script_path = abs_path($0);
  my $script_name = basename($0);
  my $shell       = ($ENV{SHELL} || 'bash') =~ m!\bzsh\b! ? 'zsh' : 'bash';

  if ($shell eq 'zsh') {
    my $function = '_' . $script_name =~ s!\W!_!gr;
    return <<"HERE";
$function() {
  read -l; local l="\$REPLY";
  read -ln; local p="\$REPLY";
  reply=(\$(COMP_LINE="\$l" COMP_POINT="\$p" COMP_SHELL="zsh" $script_path));
};

compctl -f -K $function $script_name;
HERE
  }
  else {
    return "complete -o default -C $script_path $script_name;\n";
  }
}

1;

=encoding utf8

=head1 NAME

Getopt::App::Complete - Add auto-completion to you Getopt::App script

=head1 SYNOPSIS

  use Getopt::App -complete;

  run(
    'h                 # Print help',
    'completion-script # Print autocomplete script',
    sub {
      my ($app, @args) = @_;
      return print generate_completion_script() if $app->{'completion-script'};
      return print extract_usage()              if $app->{h};
    },
  );

=head1 DESCRIPTION

L<Getopt::App::Complete> contains helper functions for adding auto-completion to
your L<Getopt::App> powered script.

This module is currently EXPERIMENTAL.

=head1 EXPORTED FUNCTIONS

=head2 complete_reply

  $int = complete_reply($app_obj);

This function is the default behaviour when L<Getopt::App/run> is called with
C<COMP_POINT> and C<COMP_LINE> set.

This function will print completion options based on C<COMP_POINT> and
C<COMP_LINE> to STDOUT and is aware of subcommands.

=head2 generate_completion_script

  $str = generate_completion_script();

This function will detect if the C<bash> or C<zsh> shell is in use and return
the appropriate initialization commands.

=head1 SEE ALSO

L<Getopt::App>

=cut
