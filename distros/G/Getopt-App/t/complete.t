use Test2::V0;
use File::Spec::Functions qw(catfile rel2abs);
use Getopt::App -capture;
use Getopt::App::Complete qw(generate_completion_script complete_reply);

my $script = rel2abs(catfile qw(example bin cool));
plan skip_all => "$script" unless -x $script;

subtest 'generate_completion_script - bash' => sub {
  local $ENV{SHELL} = '/usr/bin/bash';
  like generate_completion_script(), qr{^complete -o default -C .* complete.t;}s, 'complete';
};

subtest 'generate_completion_script - zsh' => sub {
  local $ENV{SHELL} = '/bin/zsh';
  like generate_completion_script(), qr{^_complete_t\(\)}s,                     'complete function';
  like generate_completion_script(), qr{COMP_LINE=.*COMP_POINT=.*COMP_SHELL=}s, 'environment';
  like generate_completion_script(), qr{compctl -f -K _complete_t complete\.t;}s, 'complete';
};

subtest 'complete_reply' => sub {
  local $Getopt::App::OPTIONS = [qw(file=s h v|version)];
  my $app = do($script) or die $@;
  test_complete_reply($app, '', 0, [qw(beans coffee help invalid unknown -h --completion-script)]);
  test_complete_reply($app, 'coff',      4, [qw(coffee)],                 'coffee');
  test_complete_reply($app, '--',        2, [qw(--completion-script)],    'double dash');
  test_complete_reply($app, '--',        1, [qw(-h --completion-script)], 'single dash');
  test_complete_reply($app, 'coffee ',   7, [qw(-h --version --dummy)],   'subcommand');
  test_complete_reply($app, 'coffee --', 9, [qw(--version --dummy)],      'subcommand double dash');
  test_complete_reply($app, 'coffee   -- --ve', 15, [qw(--version)],      'subcommand spaces');
};

done_testing;

sub test_complete_reply {
  my $app = shift;
  local $ENV{COMP_LINE}  = join ' ', $0, shift;
  local $ENV{COMP_POINT} = length($0) + 1 + shift;
  note "COMP_LINE='$ENV{COMP_LINE}' ($ENV{COMP_POINT})";
  my ($exp, $desc) = @_;
  my $res = capture($app);
  is [split /\n/, $res->[0]], $exp, $desc || 'complete_reply' or diag "ERR: $res->[1]";
}
