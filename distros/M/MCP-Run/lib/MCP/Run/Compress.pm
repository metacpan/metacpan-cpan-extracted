package MCP::Run::Compress;
our $VERSION = '0.100';
use Mojo::Base -base;

# ABSTRACT: Output compression for LLMs


use Text::Trim qw(trim);
use List::Util qw(max min);
use Getopt::Long qw(GetOptionsFromArray);

has filters => sub { +{} };


sub _parse_command {
  my ($self, $command) = @_;
  my @words = split /\s+/, $command;
  return { program => '', subcommand => undef, flags => {}, args => [] } unless @words;

  my $program = shift @words;
  my ($subcommand, @remaining);

  # Find the subcommand (first word not starting with -)
  for my $i (0 .. $#words) {
    if ($words[$i] !~ /^-/) {
      $subcommand = $words[$i];
      @remaining = @words[$i+1 .. $#words];
      last;
    }
  }
  @remaining = @words unless defined $subcommand;

  # Parse flags with Getopt::Long
  my %flags;

  # Build a Getopt::Long spec for common flag types
  my @spec = (
    'stat'      => sub { $flags{stat} = 1 },
    'numstat'   => sub { $flags{numstat} = 1 },
    'shortstat' => sub { $flags{shortstat} = 1 },
    'w=i'       => \$flags{w},
    'width=i'   => \$flags{width},
    'stat-width=i'   => \$flags{'stat-width'},
    'stat-name-width=i' => \$flags{'stat-name-width'},
    'M=s'       => \$flags{M},
    'ignore-space-change' => sub { $flags{'ignore-space-change'} = 1 },
    'ignore-all-space' => sub { $flags{'ignore-all-space'} = 1 },
    'ignore-blank-lines' => sub { $flags{'ignore-blank-lines'} = 1 },
    'U=i'       => \$flags{U},
    'unified=i' => \$flags{unified},
    'color'     => sub { $flags{color} = 1 },
    'no-color'  => sub { $flags{color} = 0 },
    'cached'    => sub { $flags{cached} = 1 },
    'no-pager'  => sub { $flags{'no-pager'} = 1 },
  );

  # Use GetOptionsFromArray to parse - suppress warnings for unknown flags
  my $warn_handler = $SIG{__WARN__};
  local $SIG{__WARN__} = sub { };  # Suppress warnings during parsing
  GetOptionsFromArray(\@remaining, @spec);

  return {
    program    => $program,
    subcommand => $subcommand,
    flags      => \%flags,
    args       => \@remaining,
  };
}

sub register_filter {
  my $self = shift;
  my %args = @_;

  my $command = delete $args{command};
  my $parsed_command = delete $args{parsed_command};

  # Determine storage key: parsed commands use a special key format
  my $key;
  if ($parsed_command) {
    my @flag_parts;
    for my $flag (sort keys %{$parsed_command->{flags} // {}}) {
      push @flag_parts, "$flag=" . ($parsed_command->{flags}{$flag} // 1);
    }
    $key = 'parsed:' . ($parsed_command->{program} // '') . ':' . ($parsed_command->{subcommand} // '') . ':' . join(',', @flag_parts);
  } else {
    $key = $command;
  }

  $self->filters->{$key} = {
    command            => $command,
    parsed_command     => $parsed_command,
    strip_ansi           => $args{strip_ansi}           // 0,
    strip_lines_matching => $args{strip_lines_matching} // [],
    keep_lines_matching  => $args{keep_lines_matching}  // [],
    truncate_lines_at   => $args{truncate_lines_at}    // 0,
    max_lines           => $args{max_lines}            // 0,
    tail_lines          => $args{tail_lines}           // 0,
    head_lines          => $args{head_lines}           // 0,
    on_empty            => $args{on_empty}            // '',
    replace             => $args{replace}             // [],
    match_output        => $args{match_output}         // [],
    filter_stderr       => $args{filter_stderr}       // 0,
    output_detect       => $args{output_detect}       // undef,
    transform           => $args{transform}           // undef,
    command_transform  => $args{command_transform}   // undef,
  };

  return;
}

sub _match_parsed_command {
  my ($self, $filter_spec, $parsed) = @_;
  return 0 unless $parsed && $filter_spec;

  # Must match program
  return 0 if ($filter_spec->{program} // '') ne ($parsed->{program} // '');

  # Subcommand must match if specified
  if (defined $filter_spec->{subcommand}) {
    return 0 if ($filter_spec->{subcommand} // '') ne ($parsed->{subcommand} // '');
  }

  # All specified flags must be present and truthy
  for my $flag (keys %{$filter_spec->{flags} // {}}) {
    return 0 unless $parsed->{flags}{$flag};
  }

  return 1;
}

sub _build_default_filters {
  my $self = shift;

  # ls: ultra-compact for long listing - only keep type + filename
  $self->register_filter(
    command => '^ls\b',
    output_detect => qr(^[d-][rwx-]{9}.*\s+\d+\s+),
    strip_lines_matching => [
      qr(^\s*$),
      qr(^total\s+\d+),
      qr(^\s*Device:),
      qr(^\s*Inode:),
      qr(^\s*Birth:),
      qr(^/node_modules/),
      qr(^/\.git/),
      qr(^/\.target/),
      qr(^/\.next/),
      qr(^/\.nuxt/),
      qr(^/\.cache/),
      qr(^/__pycache__/),
      qr(^/\.DS_Store/),
      qr(^/vendor/bundle/),
    ],
    transform => sub {
      my ($line) = @_;
      if ($line =~ m{^([d-])[rwx-]{9}\s+\d+\s+\S+\s+\S+\s+\d+\s+\w+\s+\d+\s+[\d:]+\s+(.+)$}) {
        return $1 . " " . $2;
      }
      return $line;
    },
    truncate_lines_at => 100,
    max_lines => 50,
  );

  # stat: strip device/inode/birth (Linux)
  $self->register_filter(
    command => '^stat\b',
    strip_lines_matching => [
      qr(^\s*$),
      qr(^\s*Device:),
      qr(^\s*Inode:),
      qr(^\s*Birth:),
    ],
    truncate_lines_at => 120,
    max_lines => 20,
  );

  # grep: truncate lines, group by file
  $self->register_filter(
    command => '^grep\b',
    truncate_lines_at => 150,
    max_lines => 100,
  );

  # make: strip entering/leaving directory
  $self->register_filter(
    command => '^make\b',
    strip_lines_matching => [
      qr(^\s*$),
      qr(^make\[\d+\]:),
      qr(^Entering directory),
      qr(^Leaving directory),
      qr(Nothing to be done),
      qr(^make:\s+Nothing to be done),
    ],
    match_output => [
      { pattern => qr(^make\[\d+\]:.*?make\[\d+\]:), message => 'make: circular dependency detected' },
      { pattern => qr(^gcc.*?Error), message => 'make: compilation error' },
    ],
    max_lines => 50,
    on_empty => 'make: ok',
  );

  # git status: compact output
  $self->register_filter(
    parsed_command => {
      program    => 'git',
      subcommand => 'status',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^On branch),
      qr(^Your branch is),
      qr(^Initial commit),
    ],
    max_lines => 30,
  );

  # git diff: keep only diff content
  $self->register_filter(
    command => '^git\s+diff\b',
    strip_lines_matching => [
      qr(^\s*$),
      qr(^diff --git),
      qr(^index ),
      qr(^---\s+a/),
      qr(^\+\+\+\s+b/),
    ],
    truncate_lines_at => 150,
    max_lines => 200,
  );

  # git diff --stat: compact format "N+M- filename"
  $self->register_filter(
    parsed_command => {
      program    => 'git',
      subcommand => 'diff',
      flags      => { stat => 1 },
    },
    transform => sub {
      my ($line) = @_;
      # Format: " 1 file changed, 3 insertions(+), 2 deletions(-)" or
      #         " file1.txt | 5 +++ ---"
      # Transform to "N+M- filename" for file lines
      if ($line =~ /^\s*(\S+)\s*\|\s*(\d+)\s*\+(\d+)\s*-\s*(\d+)/) {
        # "| 5 +++ ---" format -> "3+2- filename"
        return "$2+$3-$1";
      }
      if ($line =~ /^\s*(\S+)\s*\|\s*(\d+)\s+\+(\d+),?\s*(\d+)?\s*-/) {
        # "| 5 +3 -2" format
        my ($file, $changes, $add, $del) = ($1, $2, $3, $4 // 0);
        return "$add+$del-$file";
      }
      # Remove summary line "X files changed"
      if ($line =~ /^\s*\d+\s+files?\s+changed/) {
        return undef;  # Skip this line
      }
      return $line;
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^\s*\d+\s+files?\s+changed),
      qr(^\s*\d+\s+insertions?\(\+\)),
      qr(^\s*\d+\s+deletions?\(\-\)),
    ],
    max_lines => 100,
  );

  # cat: detect and filter code
  $self->register_filter(
    command => '^cat\b',
    strip_lines_matching => [qr(^\s*$)],
    truncate_lines_at => 500,
    max_lines => 100,
  );

  # find: strip permission denied, limit results
  $self->register_filter(
    command => '^find\b',
    strip_lines_matching => [
      qr(^\s*$),
      qr(^find:.*permission denied),
    ],
    max_lines => 50,
  );

  # ps: compact output
  $self->register_filter(
    command => '^ps\b',
    strip_lines_matching => [
      qr(^\s*$),
    ],
    truncate_lines_at => 120,
    max_lines => 30,
  );

  # df: truncate wide columns
  $self->register_filter(
    command => '^df\b',
    strip_lines_matching => [qr(^\s*$)],
    truncate_lines_at => 80,
    max_lines => 20,
  );

  # docker ps: compact output
  $self->register_filter(
    parsed_command => {
      program    => 'docker',
      subcommand => 'ps',
    },
    strip_lines_matching => [qr(^\s*$)],
    truncate_lines_at => 120,
    max_lines => 30,
  );

  # docker images: compact output
  $self->register_filter(
    parsed_command => {
      program    => 'docker',
      subcommand => 'images',
    },
    strip_lines_matching => [qr(^\s*$)],
    truncate_lines_at => 120,
    max_lines => 30,
  );

  # terraform plan: strip refresh progress
  $self->register_filter(
    parsed_command => {
      program    => 'terraform',
      subcommand => 'plan',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Refreshing state\.\.\.),
      qr(^Terraform used the),
      qr(^tfe-outputs:),
    ],
    max_lines => 100,
  );

  # terraform apply: strip progress
  $self->register_filter(
    parsed_command => {
      program    => 'terraform',
      subcommand => 'apply',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Refreshing state\.\.\.),
      qr(^Terraform will perform),
      qr(^Proceeding with the following),
      qr(^tfe-outputs:),
    ],
    max_lines => 100,
  );

  # docker build: strip build progress
  $self->register_filter(
    parsed_command => {
      program    => 'docker',
      subcommand => 'build',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^#\s*\d+\s+\[\s*\d+\s+/\s*\d+\]),
      qr(^Step \d+/\d+:),
    ],
    max_lines => 50,
  );

  # docker run: compact output
  $self->register_filter(
    parsed_command => {
      program    => 'docker',
      subcommand => 'run',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Unable to find image),
      qr(^Pulling from library/),
      qr(^Digest:),
      qr(^Status:),
    ],
    max_lines => 30,
  );

  # kubectl get: compact output
  $self->register_filter(
    parsed_command => {
      program    => 'kubectl',
      subcommand => 'get',
    },
    strip_lines_matching => [qr(^\s*$)],
    truncate_lines_at => 150,
    max_lines => 50,
  );

  # kubectl describe: strip noise
  $self->register_filter(
    parsed_command => {
      program    => 'kubectl',
      subcommand => 'describe',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Name:\s+\w+),
      qr(^Namespace:\s+\w+),
      qr(^Labels:\s*$),
      qr(^Annotations:\s*$/),
    ],
    truncate_lines_at => 200,
    max_lines => 100,
  );

  # cargo build: strip compile progress
  $self->register_filter(
    parsed_command => {
      program    => 'cargo',
      subcommand => 'build',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Compiling\s+\w+),
      qr(^Fresh\s+\w+),
      qr(^Finished\s+),
    ],
    max_lines => 50,
  );

  # cargo test: compact output
  $self->register_filter(
    parsed_command => {
      program    => 'cargo',
      subcommand => 'test',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Compiling\s+\w+),
      qr(^Running\s+/),
      qr(^test result:),
    ],
    max_lines => 100,
  );

  # cpanm: strip cpanm noise
  $self->register_filter(
    command => '^cpanm\b',
    strip_lines_matching => [
      qr(^\s*$),
      qr(^--> ),
      qr(^OK$),
      qr(^FAIL$),
      qr(^Working on),
      qr(^Fetching),
      qr(^Configuring),
      qr(^Building and testing),
    ],
    match_output => [
      { pattern => qr{^\s*Successfully installed}, message => 'cpanm: ok' },
    ],
    max_lines => 30,
  );

  # npm install: strip noise
  $self->register_filter(
    parsed_command => {
      program    => 'npm',
      subcommand => 'install',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^added\s+\d+\s+packages?),
      qr(^found\s+\d+\s+packages?),
      qr(^npm warn),
    ],
    max_lines => 30,
  );

  # yarn install: similar to npm
  $self->register_filter(
    parsed_command => {
      program    => 'yarn',
      subcommand => 'install',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Done in\s+),
      qr(^Resolving completed),
      qr(^Linking completed),
    ],
    max_lines => 30,
  );

  # yarn add: similar to npm
  $self->register_filter(
    parsed_command => {
      program    => 'yarn',
      subcommand => 'add',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Done in\s+),
      qr(^Resolving completed),
      qr(^Linking completed),
    ],
    max_lines => 30,
  );

  # pnpm install: similar to npm
  $self->register_filter(
    parsed_command => {
      program    => 'pnpm',
      subcommand => 'install',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Done in\s+),
      qr(^Resolving completed),
      qr(^Linking completed),
    ],
    max_lines => 30,
  );

  # pnpm add: similar to npm
  $self->register_filter(
    parsed_command => {
      program    => 'pnpm',
      subcommand => 'add',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Done in\s+),
      qr(^Resolving completed),
      qr(^Linking completed),
    ],
    max_lines => 30,
  );

  # pip install: strip progress
  $self->register_filter(
    parsed_command => {
      program    => 'pip',
      subcommand => 'install',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Collecting\s+),
      qr(^Downloading\s+),
      qr(^Installing collected packages:),
      qr(^Successfully installed),
    ],
    max_lines => 50,
  );

  # pytest: compact output
  $self->register_filter(
    parsed_command => {
      program    => 'pytest',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^=+.*=+$/),
      qr(^Coverage report:),
      qr(^HTML report:),
    ],
    truncate_lines_at => 150,
    max_lines => 100,
  );

  # curl: strip headers
  $self->register_filter(
    parsed_command => {
      program    => 'curl',
    },
    filter_stderr => 1,
    strip_lines_matching => [
      qr(^\s*$),
      qr(^  % Total),
      qr(^  Resolving),
      qr(^Connected to),
      qr(^HTTP/\d[\d.]*\s+\d+),
    ],
    truncate_lines_at => 200,
    max_lines => 50,
  );

  # wget: strip progress
  $self->register_filter(
    parsed_command => {
      program    => 'wget',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^--\d{4}-\d{2}-\d{2}),
      qr(^Resolving),
      qr(^Connecting to),
      qr(^Length:\s+\d+),
      qr(^Saving to:),
      qr(^\d+%\s+\[),
    ],
    truncate_lines_at => 200,
    max_lines => 50,
  );

  # helm install: strip progress
  $self->register_filter(
    parsed_command => {
      program    => 'helm',
      subcommand => 'install',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^NAME:\s+\w+),
      qr(^NAMESPACE:\s+\w+),
      qr(^STATUS:\s+),
      qr(^REVISION:\s+\d+),
      qr(^NOTES:$),
    ],
    max_lines => 50,
  );

  # helm upgrade: strip progress
  $self->register_filter(
    parsed_command => {
      program    => 'helm',
      subcommand => 'upgrade',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^NAME:\s+\w+),
      qr(^NAMESPACE:\s+\w+),
      qr(^STATUS:\s+),
      qr(^REVISION:\s+\d+),
      qr(^NOTES:$),
    ],
    max_lines => 50,
  );

  # ansible-playbook: strip progress
  $self->register_filter(
    parsed_command => {
      program    => 'ansible-playbook',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^PLAY\s+\[),
      qr(^TASK\s+\[),
      qr(^RUNNING HANDLER),
      qr(^changed:\s+\[\d+\]),
      qr(^ok:\s+\[\d+\]),
      qr(^fatal:\s+\[\d+\]),
      qr(^PLAY RECAP),
    ],
    max_lines => 100,
  );

  # rsync: strip progress
  $self->register_filter(
    parsed_command => {
      program    => 'rsync',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^sent\s+\d+\s+bytes),
      qr(^received\s+\d+\s+bytes),
      qr(^total size is),
    ],
    max_lines => 30,
  );

  # iptables -L: compact
  $self->register_filter(
    parsed_command => {
      program    => 'iptables',
    },
    strip_lines_matching => [qr(^\s*$)],
    truncate_lines_at => 150,
    max_lines => 50,
  );

  # ping: strip progress
  $self->register_filter(
    parsed_command => {
      program    => 'ping',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^PING\s+),
      qr(^64 bytes from),
      qr(^---.*ping statistics---),
    ],
    max_lines => 20,
  );

  # netstat: compact output for -tulpn
  $self->register_filter(
    parsed_command => {
      program    => 'netstat',
    },
    strip_lines_matching => [qr(^\s*$)],
    truncate_lines_at => 150,
    max_lines => 50,
  );

  # ip addr: compact
  $self->register_filter(
    parsed_command => {
      program    => 'ip',
      subcommand => 'addr',
    },
    strip_lines_matching => [qr(^\s*$)],
    truncate_lines_at => 150,
    max_lines => 50,
  );

  # ip route: compact
  $self->register_filter(
    parsed_command => {
      program    => 'ip',
      subcommand => 'route',
    },
    strip_lines_matching => [qr(^\s*$)],
    max_lines => 30,
  );

  # ip link: compact
  $self->register_filter(
    parsed_command => {
      program    => 'ip',
      subcommand => 'link',
    },
    strip_lines_matching => [qr(^\s*$)],
    max_lines => 30,
  );

  # mount: strip noise
  $self->register_filter(
    parsed_command => {
      program    => 'mount',
    },
    strip_lines_matching => [qr(^\s*$)],
    truncate_lines_at => 200,
    max_lines => 50,
  );

  # lsblk: compact block device listing
  $self->register_filter(
    parsed_command => {
      program    => 'lsblk',
    },
    strip_lines_matching => [qr(^\s*$)],
    truncate_lines_at => 150,
    max_lines => 50,
  );

  # blkid: compact block device attributes
  $self->register_filter(
    parsed_command => {
      program    => 'blkid',
    },
    strip_lines_matching => [qr(^\s*$)],
    truncate_lines_at => 200,
    max_lines => 50,
  );

  # git log: compact
  $self->register_filter(
    parsed_command => {
      program    => 'git',
      subcommand => 'log',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^commit\s+[a-f0-9]+),
      qr(^Author:\s+),
      qr(^Date:\s+),
    ],
    head_lines => 20,
    tail_lines => 10,
    max_lines => 30,
  );

  # git branch: compact
  $self->register_filter(
    parsed_command => {
      program    => 'git',
      subcommand => 'branch',
    },
    strip_lines_matching => [qr(^\s*$)],
    max_lines => 30,
  );

  # git stash: compact
  $self->register_filter(
    parsed_command => {
      program    => 'git',
      subcommand => 'stash',
    },
    strip_lines_matching => [qr(^\s*$)],
    max_lines => 30,
  );

  # git commit: transform Co-Authored-By
  $self->register_filter(
    parsed_command => {
      program    => 'git',
      subcommand => 'commit',
    },
    command_transform => sub {
      my ($cmd) = @_;
      my $model = $ENV{CO_AUTHORED_BY} || $ENV{ANTHROPIC_MODEL};
      return $cmd unless $model;
      if ($cmd =~ /Co-Authored-By:/i) {
        $cmd =~ s/Co-Authored-By: [^\n]+/Co-Authored-By: $model/g;
      } else {
        $cmd =~ s/(")\s*$/$1\n\nCo-Authored-By: $model/m;
      }
      return $cmd;
    },
  );

  return;
}

sub new {
  my $self = shift->SUPER::new(@_);
  $self->_build_default_filters;
  return $self;
}

sub compress {
  my ($self, $command, $stdout, $stderr) = @_;

  my $matched_filter;
  my $parsed = $self->_parse_command($command);

  for my $key (keys %{$self->filters}) {
    my $filter = $self->filters->{$key};

    my $matches = 0;

    # Check parsed_command first if present
    if (my $pc = $filter->{parsed_command}) {
      $matches = 1 if $self->_match_parsed_command($pc, $parsed);
    }
    # Fall back to regex matching for legacy filters
    elsif ($command =~ /$key/) {
      $matches = 1;
    }

    next unless $matches;

    # Check output_detect if present - only apply filter if output matches
    if (my $detect = $filter->{output_detect}) {
      my @lines = split(/\n/, $stdout);
      my $has_match = grep { /$detect/ } @lines;
      unless ($has_match) {
        next;  # Skip this filter, try next one
      }
    }

    $matched_filter = $filter;
    last;  # Found matching filter
  }

  # Apply command_transform if any filter has it and env var allows it
  if ($matched_filter && $matched_filter->{command_transform} && !$ENV{MCP_RUN_COMPRESS_NO_CO_AUTHORED}) {
    $command = $matched_filter->{command_transform}->($command);
  }

  if (!$matched_filter) {
    return ($stdout, $stderr);
  }

  my ($out, $err) = ($stdout, $stderr // '');

  # Filter stderr into stdout if configured
  if ($matched_filter->{filter_stderr}) {
    $out .= "\n$err" if length $err;
    $err = '';
  }

  # Stage 1: Strip ANSI
  if ($matched_filter->{strip_ansi}) {
    $out =~ s/\x1b\[[0-9;]*[a-zA-Z]//g;
    $err =~ s/\x1b\[[0-9;]*[a-zA-Z]//g;
  }

  # Stage 2: Match output short-circuit
  for my $match (@{$matched_filter->{match_output}}) {
    if ($out =~ /$match->{pattern}/) {
      return ($match->{message}, $err);
    }
  }

  # Stage 3: Transform lines (if transform coderef provided)
  if ($matched_filter->{transform}) {
    $out = join("\n", map { $matched_filter->{transform}->($_) } split(/\n/, $out));
  }

  # Stage 4: Strip lines matching
  if (@{$matched_filter->{strip_lines_matching}}) {
    my @out_lines = split(/\n/, $out);
    @out_lines = grep {
      my $keep = 1;
      for my $pattern (@{$matched_filter->{strip_lines_matching}}) {
        if (/$pattern/) {
          $keep = 0;
          last;
        }
      }
      $keep;
    } @out_lines;
    $out = join("\n", @out_lines);
  }

  # Stage 5: Keep lines matching (if any)
  if (@{$matched_filter->{keep_lines_matching}}) {
    my @out_lines = split(/\n/, $out);
    @out_lines = grep {
      my $keep = 0;
      for my $pattern (@{$matched_filter->{keep_lines_matching}}) {
        if (/$pattern/) {
          $keep = 1;
          last;
        }
      }
      $keep;
    } @out_lines;
    $out = join("\n", @out_lines);
  }

  # Stage 6: Truncate lines at N chars
  if ($matched_filter->{truncate_lines_at} > 0) {
    my $max = $matched_filter->{truncate_lines_at};
    $out = join("\n", map { length $_ > $max ? substr($_, 0, $max) . '...' : $_ } split(/\n/, $out));
    $err = join("\n", map { length $_ > $max ? substr($_, 0, $max) . '...' : $_ } split(/\n/, $err)) if length $err;
  }

  # Stage 7: Head/Tail lines
  if ($matched_filter->{head_lines} > 0) {
    my @lines = split(/\n/, $out);
    my $head = $matched_filter->{head_lines};
    my $tail = $matched_filter->{tail_lines} // 0;
    my $omit = @lines - $head - $tail;
    if ($omit > 0 && $tail > 0) {
      $out = (join("\n", @lines[0..$head-1])) . "\n... $omit lines omitted ...\n" . (join("\n", @lines[-$tail..-1]));
    }
    elsif ($omit > 0) {
      $out = join("\n", @lines[0..min($head, @lines)-1]);
    }
  }
  elsif ($matched_filter->{tail_lines} > 0) {
    my @lines = split(/\n/, $out);
    $out = join("\n", @lines[-min($matched_filter->{tail_lines}, @lines)..-1]);
  }

  # Stage 8: Max lines
  if ($matched_filter->{max_lines} > 0) {
    my @out_lines = split(/\n/, $out);
    if (@out_lines > $matched_filter->{max_lines}) {
      $out = join("\n", @out_lines[0..$matched_filter->{max_lines}-1]) . "\n... " . (@out_lines - $matched_filter->{max_lines}) . " more lines ...";
    }
  }

  # Stage 9: On empty
  if (!length trim($out) && $matched_filter->{on_empty}) {
    $out = $matched_filter->{on_empty};
  }

  return ($out, $err);
}

sub process {
  my ($self, $command, $stdout, $stderr) = @_;

  my $matched_filter;
  my $parsed = $self->_parse_command($command);

  for my $key (keys %{$self->filters}) {
    my $filter = $self->filters->{$key};

    my $matches = 0;

    if (my $pc = $filter->{parsed_command}) {
      $matches = 1 if $self->_match_parsed_command($pc, $parsed);
    }
    elsif ($command =~ /$key/) {
      $matches = 1;
    }

    next unless $matches;

    if (my $detect = $filter->{output_detect}) {
      my @lines = split(/\n/, $stdout);
      my $has_match = grep { /$detect/ } @lines;
      unless ($has_match) {
        next;
      }
    }

    $matched_filter = $filter;
    last;
  }

  my ($out, $err) = ($stdout, $stderr // '');

  if ($matched_filter && $matched_filter->{command_transform} && !$ENV{MCP_RUN_COMPRESS_NO_CO_AUTHORED}) {
    $command = $matched_filter->{command_transform}->($command);
  }

  if (!$matched_filter) {
    return { command => $command, stdout => $out, stderr => $err };
  }

  if ($matched_filter->{filter_stderr}) {
    $out .= "\n$err" if length $err;
    $err = '';
  }

  if ($matched_filter->{strip_ansi}) {
    $out =~ s/\x1b\[[0-9;]*[a-zA-Z]//g;
    $err =~ s/\x1b\[[0-9;]*[a-zA-Z]//g;
  }

  for my $match (@{$matched_filter->{match_output} // []}) {
    if ($out =~ /$match->{pattern}/) {
      return { command => $command, stdout => $match->{message}, stderr => $err };
    }
  }

  if ($matched_filter->{transform}) {
    $out = join("\n", map { $matched_filter->{transform}->($_) } split(/\n/, $out));
  }

  if (@{$matched_filter->{strip_lines_matching} // []}) {
    my @out_lines = split(/\n/, $out);
    @out_lines = grep {
      my $keep = 1;
      for my $pattern (@{$matched_filter->{strip_lines_matching}}) {
        if (/$pattern/) {
          $keep = 0;
          last;
        }
      }
      $keep;
    } @out_lines;
    $out = join("\n", @out_lines);
  }

  if (@{$matched_filter->{keep_lines_matching} // []}) {
    my @out_lines = split(/\n/, $out);
    @out_lines = grep {
      my $keep = 0;
      for my $pattern (@{$matched_filter->{keep_lines_matching}}) {
        if (/$pattern/) {
          $keep = 1;
          last;
        }
      }
      $keep;
    } @out_lines;
    $out = join("\n", @out_lines);
  }

  if ($matched_filter->{truncate_lines_at} > 0) {
    my $max = $matched_filter->{truncate_lines_at};
    $out = join("\n", map { length $_ > $max ? substr($_, 0, $max) . '...' : $_ } split(/\n/, $out));
    $err = join("\n", map { length $_ > $max ? substr($_, 0, $max) . '...' : $_ } split(/\n/, $err)) if length $err;
  }

  if ($matched_filter->{head_lines} > 0) {
    my @lines = split(/\n/, $out);
    my $head = $matched_filter->{head_lines};
    my $tail = $matched_filter->{tail_lines} // 0;
    my $omit = @lines - $head - $tail;
    if ($omit > 0 && $tail > 0) {
      $out = (join("\n", @lines[0..$head-1])) . "\n... $omit lines omitted ...\n" . (join("\n", @lines[-$tail..-1]));
    }
    elsif ($omit > 0) {
      $out = join("\n", @lines[0..min($head, @lines)-1]);
    }
  }
  elsif ($matched_filter->{tail_lines} > 0) {
    my @lines = split(/\n/, $out);
    $out = join("\n", @lines[-min($matched_filter->{tail_lines}, @lines)..-1]);
  }

  if ($matched_filter->{max_lines} > 0) {
    my @out_lines = split(/\n/, $out);
    if (@out_lines > $matched_filter->{max_lines}) {
      $out = join("\n", @out_lines[0..$matched_filter->{max_lines}-1]) . "\n... " . (@out_lines - $matched_filter->{max_lines}) . " more lines ...";
    }
  }

  if (!length trim($out) && $matched_filter->{on_empty}) {
    $out = $matched_filter->{on_empty};
  }

  return { command => $command, stdout => $out, stderr => $err };
}

sub transform_command {
  my ($self, $command) = @_;
  return $command if $ENV{MCP_RUN_COMPRESS_NO_CO_AUTHORED};

  my $parsed = $self->_parse_command($command);

  for my $key (keys %{$self->filters}) {
    my $filter = $self->filters->{$key};

    my $matches = 0;

    if (my $pc = $filter->{parsed_command}) {
      $matches = 1 if $self->_match_parsed_command($pc, $parsed);
    }
    elsif ($command =~ /$key/) {
      $matches = 1;
    }

    next unless $matches;

    if ($filter->{command_transform}) {
      $command = $filter->{command_transform}->($command);
      last;  # Only apply first matching command_transform
    }
  }

  return $command;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MCP::Run::Compress - Output compression for LLMs

=head1 VERSION

version 0.100

=head1 SYNOPSIS

    use MCP::Run::Compress;

    my $compressor = MCP::Run::Compress->new;
    $compressor->register_filter(
      'command' => '^ls\b',
      'strip_lines_matching' => [qr(^\s*$), qr(^total\s+\d+)],
      'truncate_lines_at' => 120,
      'max_lines' => 50,
    );

    my ($compressed_stdout, $compressed_stderr) = $compressor->compress($command, $stdout, $stderr);

=head1 DESCRIPTION

Automatic output compression for LLM consumption. Applies command-specific
filters to reduce token count while preserving essential information.

=head2 _parse_command

    my $parsed = $self->_parse_command($command);

Parses a command string into structured components for filter matching:

    program    - first word (e.g., 'git')
    subcommand - second word if not a flag (e.g., 'diff' in 'git diff')
    flags      - hashref of parsed flags (e.g., { stat => 1, w => 5 })
    args       - remaining non-flag arguments

Supports git-style commands where the subcommand is the first non-flag word.

=head1 AUTHOR

Torsten Raudssus L<https://raudssus.de/>

=head1 COPYRIGHT

Copyright 2026 Torsten Raudssus

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-mcp-run/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
