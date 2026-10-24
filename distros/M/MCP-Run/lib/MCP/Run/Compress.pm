package MCP::Run::Compress;
our $VERSION = '0.107';
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

# Every attribute the pipeline reads, and nothing else -- register_filter
# refuses anything not on this list (karr #28). `replace` used to be stored
# here and read by no stage, which is not the harmless kind of dead code:
# after #25 a filter setting only `replace` counted as non-shaping, was
# never selected, and then tripped the "no dead configuration" invariant,
# so its author got a test failure instead of an explanation. It is gone
# rather than implemented because nothing was missing -- per-line rewriting
# is `transform`, whole-output replacement is `match_output`, dropping
# lines is `strip_lines_matching`. Refusing unknown names rather than only
# deleting the one attribute is the actual fix: silence is what let it sit
# here unnoticed, and the next typo would have sat here just as quietly.
my %FILTER_ATTRIBUTE = map { $_ => 1 } qw(
  strip_ansi strip_lines_matching keep_lines_matching truncate_lines_at
  max_lines tail_lines head_lines on_empty match_output filter_stderr
  output_detect transform command_transform
);

sub register_filter {
  my $self = shift;
  my %args = @_;

  my $command = delete $args{command};
  my $parsed_command = delete $args{parsed_command};

  my @unknown = sort grep { !$FILTER_ATTRIBUTE{$_} } keys %args;
  die "register_filter: unknown filter attribute(s): @unknown\n" if @unknown;

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

  my $filter = {
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
    match_output        => $args{match_output}         // [],
    filter_stderr       => $args{filter_stderr}       // 0,
    output_detect       => $args{output_detect}       // undef,
    transform           => $args{transform}           // undef,
    command_transform  => $args{command_transform}   // undef,
  };

  # Derived, not configured: which of the two selections in _pipeline
  # this filter is a candidate for. Computed once here because
  # _match_filter asks it for every filter on every run.
  $filter->{_shapes_output} = $self->_shapes_output($filter);

  $self->filters->{$key} = $filter;

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


my $CO_AUTHORED_WORD  = qr{[A-Za-z0-9][A-Za-z0-9._:/+-]*};
my $CO_AUTHORED_MAIL  = qr{[A-Za-z0-9._%+-]+\@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+};
my $CO_AUTHORED_VALUE = qr{\A$CO_AUTHORED_WORD(?:[ ]$CO_AUTHORED_WORD)*(?:[ ]<$CO_AUTHORED_MAIL>)?\z};

sub _co_authored_by {
  my $model = $ENV{CO_AUTHORED_BY} || $ENV{ANTHROPIC_MODEL};
  return undef unless defined $model && length $model;
  return undef unless $model =~ $CO_AUTHORED_VALUE;
  return $model;
}


sub _collapse_cr {
  my ($text) = @_;
  return $text unless defined $text && index($text, "\r") >= 0;

  $text =~ s/\r\n/\n/g;
  return $text unless index($text, "\r") >= 0;

  my @lines = split /\n/, $text, -1;
  for my $line (@lines) {
    next unless index($line, "\r") >= 0;
    my @states = grep { length } split /\r/, $line, -1;
    $line = @states ? $states[-1] : '';
  }

  return join "\n", @lines;
}

sub _build_default_filters {
  my $self = shift;

  # ls: ultra-compact for long listing - only keep type + filename
  $self->register_filter(
    command => '^ls\b',
    # The mode column is a type letter, nine rwx characters, and -- on some
    # systems -- one more for the alternate access method: `.` for an SELinux
    # context (Fedora, Rocky, RHEL), `+` for a POSIX ACL, `@` for macOS
    # extended attributes, nothing at all on a plain Debian. That last case is
    # the one this was written on, which is why a filter that did nothing
    # whatsoever on the smokers' machines looked healthy here for years
    # (GitHub #3, karr #35). The type letter is every type `ls -l` can print,
    # not just file and directory: a listing of nothing but symlinks was not
    # even recognized as a long listing before.
    output_detect => qr(^[-bcdDlps][rwx-]{9}.*\s+\d+\s+),
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
      # type, nine mode characters, the optional access-method character
      # (see output_detect above), links, owner, group, size, date, name.
      # The size is `major, minor` for a device, which is why it is not a
      # plain \d+. What survives is the type letter and the name -- for a
      # symlink that name is `link -> target`, kept whole on purpose: the
      # target is the only thing a symlink actually says, and dropping it
      # would leave an entry that names a file and hides what it is.
      #
      # The date is not one shape either. `ls --time-style=` picks it, and
      # the formats do not agree on a single one: the locale default prints
      # `Aug 14 08:44`, long-iso prints `2026-08-23 10:00`, full-iso adds
      # seconds, nanoseconds and the zone offset, iso drops the year and
      # prints `08-23 10:00`, and a strftime format like +%Y-%m-%d prints
      # the date alone. So the date is an alternation over whole formats,
      # not a loosened single pattern: each alternative describes one
      # format completely, and a line that fits none of them stays
      # uncollapsed rather than being cut at the wrong place (karr #36).
      if ($line =~ m{
          ^([-bcdDlps])[rwx-]{9}[.+\@]?
          \s+\d+ \s+\S+ \s+\S+ \s+\d+(?:,\s*\d+)?
          \s+(?:
              \d{4}-\d{2}-\d{2} \s+ \d{1,2}:\d{2}(?::\d{2}(?:\.\d+)?)? (?:\s+[+-]\d{2}:?\d{2})?  # long-iso, full-iso
            | \d{4}-\d{2}-\d{2}                                                                 # +%Y-%m-%d
            | \d{2}-\d{2} \s+ \d{1,2}:\d{2}(?::\d{2}(?:\.\d+)?)?                               # iso
            | \w+ \s+ \d+ \s+ [\d:]+                                                           # locale
          )
          \s+(.+)$
        }x) {
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
      # Only the chatter, not every sub-make line (karr #32). This used to
      # be a bare qr(^make\[\d+\]:), which did suppress the Entering/
      # Leaving pair a recursive build prints per directory -- and also
      # `make[1]: *** [Makefile:18: lexer.o] Error 1`, the only line that
      # names the target that actually broke and the Makefile line it
      # broke on. What survived was the top-level abort, and that one
      # always says `all`. On a tree with twenty subdirectories the answer
      # to "where" was being stripped out of every failed build.
      #
      # Narrowing lets the rest of make's vocabulary through, which is
      # what we want: *** Error N, *** No rule to make target, Target not
      # remade because of errors, Circular ... dependency dropped (the
      # warning the removed short-circuit of #29 was meant to report),
      # and the jobserver warnings. All of them are one-off and all of
      # them say something.
      qr(^make\[\d+\]:\s+(?:Entering|Leaving) directory),
      # The one line of real volume the narrowing would otherwise let
      # back in: a no-op recursive build prints this once per directory,
      # and without it twenty subdirectories cost twenty lines instead of
      # the single `make: ok` that on_empty gives below.
      qr(^make\[\d+\]:\s+.*is up to date\.\s*$),
      qr(^Entering directory),
      qr(^Leaving directory),
      qr(Nothing to be done),
      qr(^make:\s+Nothing to be done),
    ],
    # Two match_output short-circuits removed here (karr #29), and adding
    # the missing /m would not have rescued either of them.
    #
    # `^make\[\d+\]:.*?make\[\d+\]:` -> "circular dependency detected"
    # never looked for the word Circular; it wanted two `make[N]:` on ONE
    # line, because `.` does not cross newlines without /s. Real circular
    # output is `make[1]: Circular a <- b dependency dropped.` -- one per
    # line, so /m changes nothing. And it is a warning: make carries on,
    # so replacing the whole build with that one note would hide how the
    # build actually ended.
    #
    # `^gcc.*?Error` -> "compilation error" wants a line starting with gcc
    # that also carries "Error". gcc writes `lexer.c:142:9: error:` --
    # lowercase, and starting with the file. The echoed `gcc -c ...` line
    # has no Error on it. So /m does not make it fire either, and if it
    # ever did it would delete the compiler diagnosis, which is the entire
    # reason someone reads a failed build.
    #
    # The honest short-circuit for make is on_empty below: it speaks only
    # when the strip list left nothing, i.e. when there is nothing to say.
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
    # No match_output short-circuit to "cpanm: ok" (karr #29). It was
    # written without /m, so its `^` anchored on the whole output and it
    # never fired -- but /m is not the fix. The first realistic run it
    # would fire on is `cpanm --installdeps .` where one distribution
    # failed: cpanm prints "Successfully installed A" and then
    # "! Installing B failed", and collapsing that to "cpanm: ok" reports
    # a broken install as a clean one. The strip list above already leaves
    # exactly the result lines -- naming the version, and the failure.
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

  # git commit: transform Co-Authored-By. Match the raw string so we
  # also catch compound commands like `cd foo && git add bar && git
  # commit -m "..."`, where the parsed top-level program isn't `git`.
  $self->register_filter(
    command => '\bgit\b[^&|;]*?(?<![=])\bcommit\b',
    command_transform => sub {
      my ($cmd) = @_;
      # Validated, not escaped: an unusable value means no trailer at all,
      # for both the replacement and the injection below. See _co_authored_by.
      my $model = _co_authored_by();
      return $cmd unless defined $model;
      # Replacement of a trailer the command already carries. The
      # substitution IS the condition: detection used to be a separate,
      # case-insensitive regex while the replacement was case-sensitive, so
      # a lower- or upper-cased trailer entered the branch, replaced
      # nothing, and returned -- skipping the injection below as well and
      # leaving the commit with no trailer at all (karr #18). With one
      # regex instead of two, "detected but not replaced" cannot happen.
      #
      # The spelling is normalized to the canonical form rather than
      # preserved: git matches trailer keys case-insensitively, so nothing
      # is lost, both paths of this transform now emit the same shape, and
      # one variable fewer is spliced into a shell command line.
      #
      # [^\n"]+ instead of [^\n]+: when the trailer sits at the end of a
      # -m "..." message, the greedy class used to swallow the closing
      # quote too, leaving the shell with an unterminated string.
      return $cmd if $cmd =~ s/Co-Authored-By:[ \t]*[^\n"]+/Co-Authored-By: $model/gi;
      # Injection. The trailer is spliced after the closing quote of the
      # last -m/--message argument inside the git commit invocation (the
      # invocation runs from `commit` up to the next shell separator).
      # The old code targeted the last quote of the whole command line, so
      # a compound command like `git commit -m "x" && git config user.name
      # "y"` had the trailer injected into user.name, corrupting the config
      # value. Injecting inside the quote (rather than appending `-m
      # "..."`) keeps the trailer part of the commit message: appended, the
      # `<model@host>` would parse as a shell redirection and break the
      # call. No -m argument (e.g. `git commit --amend` opening the editor)
      # means no safe injection point, so nothing is rewritten.
      my $tail = $cmd;
      if ( $tail =~ /\bgit\b[^&|;]*?(?<![=])\bcommit\b/ ) {
        $tail =~ s/^.*\bgit\b[^&|;]*?(?<![=])\bcommit\b//;
        my $origin = length($cmd) - length($tail);
        $tail =~ s/[&|;].*$//;
        # -[a-zA-Z]*m covers bundled short flags whose last letter is the
        # message flag (-am, -sm, -anm), not just a bare -m. The lookbehind
        # requires the dash to start an argument -- \b can't do that, since
        # `-` is not a word character, so \b- never matches after a space.
        # Without it, a path like /tmp/msg-m "x" would look like a flag.
        if ( $tail
          =~ /^(.*(?<![^\s])(?:--message|-[a-zA-Z]*m)\s+")((?:[^"\\]|\\.)*)(")/ )
        {
          substr( $cmd, $origin + length($1) + length($2), 0 )
            = "\n\nCo-Authored-By: $model";
        }
      }
      return $cmd;
    },
  );

  # ------------------------------------------------------------------
  # karr #17: filters MCP::Run::Compress::Filters documented before they
  # existed. Every strip pattern below is anchored on a literal prefix the
  # tool really prints, so a format change makes the filter do nothing
  # rather than eat a line it should have kept.
  # ------------------------------------------------------------------

  # du: the two directories that dominate any recursive disk usage run
  $self->register_filter(
    parsed_command => {
      program    => 'du',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(/\.git(?:/|$)),
      qr(/node_modules(?:/|$)),
    ],
    truncate_lines_at => 150,
    max_lines => 50,
  );

  # gcc: strip the include chain and the source echo, keep the diagnostics.
  # filter_stderr is not optional here: a compiler says everything on
  # stderr, and every stage below this one works on stdout, so without the
  # merge the filter would look at an empty string and do nothing.
  $self->register_filter(
    parsed_command => {
      program    => 'gcc',
    },
    filter_stderr => 1,
    strip_lines_matching => [
      qr(^\s*$),
      qr(^In file included from ),
      qr(^\s+from \S),
      qr(:\d+:(?:\d+:)?\s+note:),
      qr(^\s*\d+\s*\|),
      qr(^\s*\|),
    ],
    truncate_lines_at => 200,
    max_lines => 100,
  );

  # g++: same output format as gcc, same treatment
  $self->register_filter(
    parsed_command => {
      program    => 'g++',
    },
    filter_stderr => 1,
    strip_lines_matching => [
      qr(^\s*$),
      qr(^In file included from ),
      qr(^\s+from \S),
      qr(:\d+:(?:\d+:)?\s+note:),
      qr(^\s*\d+\s*\|),
      qr(^\s*\|),
    ],
    truncate_lines_at => 200,
    max_lines => 100,
  );

  # swift build: strip the build chatter, so that what is left is exactly
  # the warnings and errors -- and on_empty speaks when there are none.
  # The reference used to promise a short-circuit to "ok (build complete)"
  # *unless* warnings or errors are present; match_output cannot express
  # that negative, on_empty reaches the same result from the other end.
  $self->register_filter(
    parsed_command => {
      program    => 'swift',
      subcommand => 'build',
    },
    filter_stderr => 1,
    strip_lines_matching => [
      qr(^\s*$),
      qr(^\[\d+/\d+\]\s),
      qr(^Compiling\s),
      qr(^Fetching\s),
      qr(^Fetched\s),
      qr(^Computing version for ),
      qr(^Computed \S+ at ),
      qr(^Creating working copy for ),
      qr(^Working copy of \S+ resolved at ),
      qr(^Planning build),
      qr(^Building for ),
      qr(^Build complete!),
    ],
    max_lines => 100,
    on_empty => 'swift build: ok (build complete)',
  );

  # mix compile: Elixir prints one line per compiled batch and one per app
  $self->register_filter(
    parsed_command => {
      program    => 'mix',
      subcommand => 'compile',
    },
    filter_stderr => 1,
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Compiling \d+ files?),
      qr(^Generated \S+ app),
      qr(^==> \S+$),
      qr(^Resolving Hex dependencies),
      qr(^Dependency resolution completed),
    ],
    max_lines => 50,
    on_empty => 'mix compile: ok',
  );

  # pio run: PlatformIO opens with a full environment report before the
  # build. The memory usage lines (RAM:/Flash:) are kept -- for an embedded
  # build that is the number people ran the command for.
  $self->register_filter(
    parsed_command => {
      program    => 'pio',
      subcommand => 'run',
    },
    filter_stderr => 1,
    strip_lines_matching => [
      qr(^\s*$),
      qr(^-+$),
      qr(^Processing \S+),
      qr(^Verbose mode can be enabled),
      qr(^CONFIGURATION:),
      qr(^PLATFORM:),
      qr(^HARDWARE:),
      qr(^DEBUG:),
      qr(^PACKAGES:),
      qr(^\s*-\s+\S+ @ ),
      qr(^LDF:),
      qr(^LDF Modes:),
      qr(^Found \d+ compatible libraries),
      qr(^Scanning dependencies),
      qr(^Dependency Graph),
      qr(^\|--),
      qr(^No dependencies),
      qr(^Building in \w+ mode),
      qr(^(?:Compiling|Archiving|Indexing|Linking|Building|Checking size) \.?pio),
      qr(^Advanced Memory Usage is available),
    ],
    max_lines => 50,
    on_empty => 'pio run: ok',
  );

  # mvn: the [INFO] stream is mostly plugin bookkeeping, but not all of it
  # -- surefire reports test results on [INFO] too, and that is the line
  # people run maven for. Only the known noise goes, not every [INFO].
  $self->register_filter(
    parsed_command => {
      program    => 'mvn',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^\[INFO\]\s*$),
      qr(^\[INFO\]\s*-{5,}),
      qr(^\[INFO\] Scanning for projects),
      qr(^\[INFO\] --- ),
      qr(^\[INFO\] (?:Downloading|Downloaded) from ),
      qr(^\[INFO\] Building jar:),
      qr(^\[INFO\] Installing \S+ to ),
      qr(^\[INFO\] (?:Total time|Finished at):),
      qr(^(?:Downloading|Downloaded) from ),
      qr(^Progress \(\d+\):),
    ],
    truncate_lines_at => 200,
    max_lines => 100,
  );

  # gradle: the per-task lines are noise only while they succeed. A task
  # line carrying FAILED keeps its line -- that is the whole message.
  $self->register_filter(
    parsed_command => {
      program    => 'gradle',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^> Task :\S+(?:\s+(?:UP-TO-DATE|NO-SOURCE|SKIPPED|FROM-CACHE))?$),
      qr(^Download https?://),
      qr(^Starting a Gradle Daemon),
      qr(^Welcome to Gradle ),
      qr(^Daemon will be stopped),
    ],
    truncate_lines_at => 200,
    max_lines => 100,
  );

  # tofu plan: OpenTofu is a Terraform fork and prints the same lines
  $self->register_filter(
    parsed_command => {
      program    => 'tofu',
      subcommand => 'plan',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Refreshing state\.\.\.),
      qr(^OpenTofu used the),
      qr(^tfe-outputs:),
    ],
    max_lines => 100,
  );

  # tofu apply: mirrors the terraform apply filter above
  $self->register_filter(
    parsed_command => {
      program    => 'tofu',
      subcommand => 'apply',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Refreshing state\.\.\.),
      qr(^OpenTofu will perform),
      qr(^Proceeding with the following),
      qr(^tfe-outputs:),
    ],
    max_lines => 100,
  );

  # tofu init: a successful init carries no information beyond having
  # succeeded, so it short-circuits. Stripping the success boilerplate line by
  # line does not work -- it is wrapped prose, and a line-anchored strip leaves
  # the continuation lines behind as fragments. An init that fails does not
  # match the pattern and goes through the stages below.
  $self->register_filter(
    parsed_command => {
      program    => 'tofu',
      subcommand => 'init',
    },
    match_output => [
      { pattern => qr(has been successfully initialized!)m, message => 'tofu init: ok' },
    ],
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Initializing ),
      qr(^- (?:Finding|Installing|Installed|Using|Reusing) ),
    ],
    max_lines => 50,
  );

  # docker-compose (v1 binary): the lifecycle chatter goes, service logs stay
  $self->register_filter(
    parsed_command => {
      program    => 'docker-compose',
    },
    filter_stderr => 1,
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Creating (?:network|volume) ),
      qr(^Creating \S+ \.\.\. done$),
      qr(^Pulling \S+ ),
      qr(^Attaching to ),
      qr(^\S+ is up-to-date$),
      # v2 status table. Left unanchored on purpose: those lines start with
      # a check mark the compressor sees as raw bytes, not as a character.
      qr((?:Network|Volume|Container)\s+\S+\s+(?:Created|Creating|Started|Starting|Running|Healthy|Waiting|Recreated|Recreate|Stopped|Stopping|Removed|Removing)\s*$),
    ],
    truncate_lines_at => 200,
    max_lines => 100,
  );

  # docker compose (v2 subcommand): same output, different invocation
  $self->register_filter(
    parsed_command => {
      program    => 'docker',
      subcommand => 'compose',
    },
    filter_stderr => 1,
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Creating (?:network|volume) ),
      qr(^Creating \S+ \.\.\. done$),
      qr(^Pulling \S+ ),
      qr(^Attaching to ),
      qr(^\S+ is up-to-date$),
      qr((?:Network|Volume|Container)\s+\S+\s+(?:Created|Creating|Started|Starting|Running|Healthy|Waiting|Recreated|Recreate|Stopped|Stopping|Removed|Removing)\s*$),
    ],
    truncate_lines_at => 200,
    max_lines => 100,
  );

  # cpan: the shell narrates every step it takes
  $self->register_filter(
    parsed_command => {
      program    => 'cpan',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Reading '),
      qr(^Database was generated on ),
      qr(^Fetching with ),
      qr(^Checksum for ),
      qr(^Running (?:make|test|install) for ),
      qr(^Configuring \S+ with ),
      qr(^CPAN\.pm: Building ),
      qr(^\s*Has already been (?:unwrapped|made)),
    ],
    truncate_lines_at => 200,
    max_lines => 60,
  );

  # cpm: one DONE line per distribution, then the summary that matters
  $self->register_filter(
    parsed_command => {
      program    => 'cpm',
    },
    filter_stderr => 1,
    strip_lines_matching => [
      qr(^\s*$),
      qr(^DONE (?:resolve|fetch|configure|install) ),
    ],
    max_lines => 30,
    on_empty => 'cpm: ok',
  );

  # composer install: repository loading, lock file and autoload bookkeeping
  $self->register_filter(
    parsed_command => {
      program    => 'composer',
      subcommand => 'install',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Loading composer repositories),
      qr(^(?:Updating|Installing) dependencies),
      qr(^Package operations:),
      qr(^\s*-\s+(?:Installing|Downloading|Locking|Upgrading|Removing) ),
      qr(^Writing lock file),
      qr(^Generating (?:optimized )?autoload files),
    ],
    max_lines => 50,
    on_empty => 'composer install: ok',
  );

  # brew install: downloads and bottle pouring. "==> Installing dependencies
  # for x" is noise, "==> Installing x" is the answer and stays.
  $self->register_filter(
    parsed_command => {
      program    => 'brew',
      subcommand => 'install',
    },
    filter_stderr => 1,
    strip_lines_matching => [
      qr(^\s*$),
      qr(^==> (?:Downloading|Downloaded|Fetching|Pouring|Verifying)),
      qr(^==> Installing dependencies),
      qr(^==> (?:Auto-updat|Updat)),
      qr(^Already downloaded:),
    ],
    truncate_lines_at => 200,
    max_lines => 50,
  );

  # poetry install: one bullet line per package. The bullet itself is a
  # non-ASCII glyph the compressor never sees as a character, so the line is
  # recognised by its shape -- verb, package, parenthesised version.
  $self->register_filter(
    parsed_command => {
      program    => 'poetry',
      subcommand => 'install',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Installing dependencies from lock file),
      qr(^Resolving dependencies),
      qr(^Package operations:),
      qr(^\s*\S*\s*(?:Installing|Updating|Downgrading|Removing)\s+\S+\s+\(),
      qr(^Writing lock file),
    ],
    max_lines => 50,
    on_empty => 'poetry install: ok',
  );

  # uv sync: timings and the +/- package list; "Installed N packages" stays
  $self->register_filter(
    parsed_command => {
      program    => 'uv',
      subcommand => 'sync',
    },
    filter_stderr => 1,
    strip_lines_matching => [
      qr(^\s*$),
      qr(^(?:Resolved|Prepared|Audited) \d+ packages? in ),
      qr(^\s*[+~-]\s+\S+==\S+$),
      qr(^Using CPython ),
      qr(^Creating virtual environment ),
      qr(^Downloading \S+ ),
    ],
    max_lines => 50,
    on_empty => 'uv sync: ok',
  );

  # systemctl status: keep the unit line and Active:, drop the accounting
  $self->register_filter(
    parsed_command => {
      program    => 'systemctl',
      subcommand => 'status',
    },
    filter_stderr => 1,
    transform => sub {
      my ($line) = @_;
      # The unit header opens with a state glyph in column 0. It is removed
      # as "leading run of non-ASCII bytes" rather than by naming it,
      # because the pipeline works on raw command bytes, not on decoded
      # text -- and because systemd has more than one such glyph. The state
      # is not lost with it: the Active: line spells it out.
      $line =~ s/^[^\x00-\x7f]+\s*//;
      return $line;
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^\s*Loaded:),
      qr(^\s*Docs:),
      qr(^\s*Main PID:),
      qr(^\s*Tasks:),
      qr(^\s*Memory:),
      qr(^\s*CPU:),
      qr(^\s*CGroup:),
      # the indented process tree under CGroup:, drawn with box glyphs in a
      # UTF-8 locale and with |- / `- everywhere else
      qr(^\s{4,}(?:[^\x00-\x7f]|[|`]-)),
    ],
    truncate_lines_at => 200,
    max_lines => 30,
  );

  # journalctl: the journal's own bracket lines
  $self->register_filter(
    parsed_command => {
      program    => 'journalctl',
    },
    strip_lines_matching => [
      qr(^\s*$),
      qr(^-- Reboot --),
      qr(^-- (?:Logs|Journal) begins? at ),
      qr(^-- No entries --),
      qr(^-- Boot \S+ --),
    ],
    truncate_lines_at => 300,
    max_lines => 100,
  );

  # fail2ban-client: blank lines, max 30
  $self->register_filter(
    parsed_command => {
      program    => 'fail2ban-client',
    },
    strip_lines_matching => [qr(^\s*$)],
    max_lines => 30,
  );

  # ollama run: the output is the model's answer, so nothing is dropped,
  # truncated or line-limited here -- only the spinner is removed.
  $self->register_filter(
    parsed_command => {
      program    => 'ollama',
      subcommand => 'run',
    },
    strip_ansi => 1,
    transform => sub {
      my ($line) = @_;
      # Braille spinner frames, U+2800..U+28FF, matched as their UTF-8
      # bytes: the pipeline sees raw command output, never decoded text.
      # A frame at the start of a line takes its trailing blanks with it;
      # elsewhere only the frame goes, so indentation inside the answer --
      # a code block, a list -- survives untouched.
      $line =~ s/\A(?:\xe2[\xa0-\xa3][\x80-\xbf][ \t]*)+//;
      $line =~ s/\xe2[\xa0-\xa3][\x80-\xbf]//g;
      return $line;
    },
  );

  # quarto render: a successful render says so in one line, and that line
  # is the entire result -- everything before it is progress.
  $self->register_filter(
    parsed_command => {
      program    => 'quarto',
      subcommand => 'render',
    },
    filter_stderr => 1,
    match_output => [
      { pattern => qr(^Output created:\s*\S)m, message => 'quarto render: ok (output created)' },
    ],
    strip_lines_matching => [
      qr(^\s*$),
      qr(^processing file: ),
      qr(^(?:Validating|Resolving) ),
      qr(^\s*\|?[.\s]*\|?\s*\d+%\s*$),
    ],
    truncate_lines_at => 200,
    max_lines => 60,
  );

  # jj: Jujutsu ends most commands with a hint and a working copy report,
  # both on stderr
  $self->register_filter(
    parsed_command => {
      program    => 'jj',
    },
    filter_stderr => 1,
    strip_lines_matching => [
      qr(^\s*$),
      qr(^Hint: ),
      qr(^Working copy now at: ),
      qr(^Parent commit\s*:),
      qr(^Rebased \d+ (?:descendant )?commits?),
    ],
    truncate_lines_at => 200,
    max_lines => 30,
  );

  # shopify theme push/pull: a long upload log whose only interesting part
  # is the tail (result and preview URL). Registered as a regex rather than
  # a parsed_command because the deciding word is the third one, and
  # _match_parsed_command only knows program and subcommand -- a
  # { shopify, theme } filter would also swallow `shopify theme list`,
  # whose output is nothing but the answer.
  $self->register_filter(
    command => '^shopify\s+theme\s+(?:push|pull)\b',
    filter_stderr => 1,
    strip_lines_matching => [qr(^\s*$)],
    tail_lines => 5,
  );

  return;
}

sub new {
  my $self = shift->SUPER::new(@_);
  $self->_build_default_filters;
  return $self;
}


sub _filter_matches {
  my ($self, $key, $filter, $command, $parsed, $stdout) = @_;

  if (my $pc = $filter->{parsed_command}) {
    return 0 unless $self->_match_parsed_command($pc, $parsed);
  }
  # Fall back to regex matching for legacy filters
  elsif ($command !~ /$key/) {
    return 0;
  }

  # Check output_detect if present - only apply filter if output matches
  if (defined $stdout && (my $detect = $filter->{output_detect})) {
    return 0 unless grep { /$detect/ } split(/\n/, $stdout);
  }

  return 1;
}


my @SHAPING_ATTRIBUTES = qw(
  filter_stderr strip_ansi match_output transform
  strip_lines_matching keep_lines_matching truncate_lines_at
  head_lines tail_lines max_lines on_empty
);

sub _shapes_output {
  my ($self, $filter) = @_;

  for my $attribute (@SHAPING_ATTRIBUTES) {
    my $value = $filter->{$attribute};
    next unless defined $value;
    return 1 if ref $value eq "ARRAY" ? scalar(@$value) : $value;
  }

  return 0;
}


sub _match_filter {
  my ($self, $command, $stdout, $parsed) = @_;

  $parsed //= $self->_parse_command($command);
  my $matched_filter;

  for my $key (keys %{$self->filters}) {
    my $filter = $self->filters->{$key};
    next unless $filter->{_shapes_output};
    next unless $self->_filter_matches($key, $filter, $command, $parsed, $stdout);

    # parsed_command filters win over legacy regex filters when both
    # match — the parsed form is more specific (program + subcommand +
    # flags) and is what users reach for when they want transform-style
    # rewrites like `git diff --stat -> "5+2-file"`. Without this
    # guard, hash iteration order decides the winner and `git diff
    # --stat` would land on the bare `^git\s+diff\b` filter, which
    # doesn't have the transform.
    if (!$matched_filter) {
      $matched_filter = $filter;
    }
    elsif ($filter->{parsed_command} && !$matched_filter->{parsed_command}) {
      $matched_filter = $filter;
    }
    last if $matched_filter->{parsed_command};
  }

  return $matched_filter;
}


sub _pipeline {
  my ($self, $command, $stdout, $stderr) = @_;

  # Normalize so downstream split/join/grep can't trip on undef inputs.
  $stdout //= '';
  $stderr //= '';

  # Two independent decisions, and they used to be one lookup (karr #25):
  # how is the output compressed, and does the command get rewritten. A
  # compound command can call for both -- `cat msg.txt && git commit -m
  # "fix"` wants the cat filter AND the trailer -- and with a single winner
  # it got whichever one hash order handed it. The output filter is chosen
  # among filters that actually shape output; the rewrite is
  # transform_command's rule, unchanged and deliberately not copied here.
  my $parsed = $self->_parse_command($command);
  my $matched_filter = $self->_match_filter($command, $stdout, $parsed);
  $command = $self->transform_command($command, $parsed);

  my ($out, $err) = ($stdout, $stderr);

  if (!$matched_filter) {
    # No filter, no filtering -- with one exception: the \r collapse still
    # runs (karr #22). It used to sit inside the filtered part of the pipeline,
    # so a command no filter knows returned here and its progress bar went
    # through whole: bun, gradle, deno, mise and every self-written script
    # draw bars and have no filter, and a bar is one single line to every
    # line-based stage. Collapsing \r overwrites is not filtering, it is
    # rendering what the terminal showed -- nothing the user would have
    # seen is lost. Everything else about the pass-through stays untouched:
    # nothing is stripped, truncated or counted, and output without a \r
    # comes back byte for byte.
    return ($command, _collapse_cr($out), _collapse_cr($err));
  }

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

  # Stage 2: Collapse carriage-return overwrites (progress bars). Has to
  # run before every line-based stage below -- they all split on /\n/, so a
  # bar of thousands of \r-separated states is one single line to them and
  # slips through whole. Unconditional, not per filter: a filter that does
  # not opt in would reopen the hole (karr #16).
  $out = _collapse_cr($out);
  $err = _collapse_cr($err);

  # Stage 3: Match output short-circuit
  for my $match (@{$matched_filter->{match_output} // []}) {
    if ($out =~ /$match->{pattern}/) {
      return ($command, $match->{message}, $err);
    }
  }

  # Stage 4: Transform lines (if transform coderef provided).
  # A transform may return undef to drop a line (e.g. git diff --stat's
  # summary line) — filter those out so join() doesn't warn.
  if ($matched_filter->{transform}) {
    $out = join("\n", grep { defined } map { $matched_filter->{transform}->($_) } split(/\n/, $out));
  }

  # Stage 5: Strip lines matching
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

  # Stage 6: Keep lines matching (if any)
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

  # Stage 7: Truncate lines at N chars
  if ($matched_filter->{truncate_lines_at} > 0) {
    my $max = $matched_filter->{truncate_lines_at};
    $out = join("\n", map { length $_ > $max ? substr($_, 0, $max) . '...' : $_ } split(/\n/, $out));
    $err = join("\n", map { length $_ > $max ? substr($_, 0, $max) . '...' : $_ } split(/\n/, $err)) if length $err;
  }

  # Stage 8: Head/Tail lines
  if ($matched_filter->{head_lines} > 0) {
    my @lines = split(/\n/, $out);
    my $head = $matched_filter->{head_lines};
    my $tail = $matched_filter->{tail_lines} // 0;
    my $omit = @lines - $head - $tail;
    if ($omit > 0 && $tail > 0) {
      $out = (join("\n", @lines[0..$head-1])) . "\n... $omit lines omitted ...\n" . (join("\n", @lines[-$tail..-1]));
    }
    elsif ($omit > 0) {
      # Marker after the kept lines -- here it is the end that is missing.
      # Trailing is the exposed end: stage 9 keeps the FIRST max_lines
      # lines, so this marker survives only while max_lines > head_lines.
      # t/compress.t guards that config instead of teaching stage 9 to
      # recognise markers.
      $out = (join("\n", @lines[0..$head-1])) . "\n... $omit lines omitted ...";
    }
  }
  elsif ($matched_filter->{tail_lines} > 0) {
    # Was the one branch that cut without saying so, on the assumption
    # that no filter reaches it -- until `shopify theme push` did, and
    # started handing the model its last five lines as if they were the
    # whole output (karr #31).
    my @lines = split(/\n/, $out);
    my $tail = min($matched_filter->{tail_lines}, scalar @lines);
    my $omit = @lines - $tail;
    # Marker before the kept lines -- it is the beginning that is missing,
    # and leading is also the durable end: stage 9 cuts from the back, so
    # neither the marker nor the count it carries can be invalidated by
    # whatever max_lines does to the tail below.
    $out = ($omit > 0 ? "... $omit lines omitted ...\n" : '')
      . join("\n", @lines[-$tail..-1]);
  }

  # Stage 9: Max lines
  if ($matched_filter->{max_lines} > 0) {
    my @out_lines = split(/\n/, $out);
    if (@out_lines > $matched_filter->{max_lines}) {
      $out = join("\n", @out_lines[0..$matched_filter->{max_lines}-1]) . "\n... " . (@out_lines - $matched_filter->{max_lines}) . " more lines ...";
    }
  }

  # Stage 10: On empty
  if (!length trim($out) && $matched_filter->{on_empty}) {
    $out = $matched_filter->{on_empty};
  }

  return ($command, $out, $err);
}

sub compress {
  my ($self, $command, $stdout, $stderr) = @_;
  my (undef, $out, $err) = $self->_pipeline($command, $stdout, $stderr);
  return ($out, $err);
}

sub process {
  my ($self, $command, $stdout, $stderr) = @_;
  my ($transformed, $out, $err) = $self->_pipeline($command, $stdout, $stderr);
  return { command => $transformed, stdout => $out, stderr => $err };
}

sub transform_command {
  my ($self, $command, $parsed) = @_;
  return $command if $ENV{MCP_RUN_COMPRESS_NO_CO_AUTHORED};

  # $parsed is an optional shortcut for callers that already parsed the
  # command -- _pipeline does, and parsing runs Getopt::Long.
  $parsed //= $self->_parse_command($command);

  # Only the filters that rewrite commands are candidates, and the winner is
  # the first of them that matches. sort: with more than one such filter,
  # unsorted keys would pick the winner by Perl's per-process hash order --
  # the bug that #25 was in the output-filter selection. Skipping the rest
  # by hash lookup instead of by regex also keeps this cheap enough to call
  # from _pipeline on every single run.
  for my $key (sort grep { $self->filters->{$_}{command_transform} } keys %{$self->filters}) {
    my $filter = $self->filters->{$key};

    # undef stdout: there is no output here, so output_detect is skipped --
    # this rewrites the command, it does not filter anything. In the hook's
    # PreToolUse path the command has not even run yet.
    next unless $self->_filter_matches($key, $filter, $command, $parsed, undef);

    $command = $filter->{command_transform}->($command);
    last;  # Only apply first matching command_transform
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

version 0.107

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

=head2 _co_authored_by

    my $model = _co_authored_by();

The Co-Authored-By replacement value from C<CO_AUTHORED_BY>, falling back to
C<ANTHROPIC_MODEL>, or undef when neither is set or the value is not a valid
trailer.

The value gets spliced into a shell command line -- inside the double quotes
of the C<git commit -m "..."> argument -- so it is checked against a narrow
positive list of what a Co-Authored-By trailer may look like: a name of one or
more words separated by single spaces, each word built from letters, digits
and C<. _ - + : />, optionally followed by an C<< <mail@host> >> address.
Anything else is refused; in particular C<">, C<\>, C<$>, backtick and newline
can never pass, so the value cannot end the quoted string, start a command
substitution or append a command of its own.

A refused value means the command is returned B<unchanged> -- no trailer at
all. Rejecting beats escaping here: a silently escaped, mangled trailer sits in
a real commit where nobody notices it, a missing trailer is honest. For the
same reason an invalid C<CO_AUTHORED_BY> does not fall back to
C<ANTHROPIC_MODEL>: the explicit setting wins, and is then refused.

=head2 _collapse_cr

    my $text = _collapse_cr($text);

Reduces carriage-return overwrites to what a terminal would actually show.
Build tools (cargo, npm, pip, docker, wget, curl, ...) draw progress by
writing thousands of states over each other with C<\r> and no newline at all.
Every stage of the pipeline splits on C</\n/>, so such a bar is a single line
to it: C<max_lines> cannot help, and the 28 of 48 filters without
C<truncate_lines_at> pass the whole thing through untouched.

Per line, the C<\r>-separated states are reduced to the last non-empty one --
what stayed on screen. Two details matter: C<\r\n> is a line ending and is
normalized to C<\n> first, so Windows output is not mistaken for a progress
bar; and a bar usually ends on a bare C<\r>, which makes the last state empty,
so the last B<non-empty> one wins. Text without a C<\r> is returned unchanged,
byte for byte.

=head2 _filter_matches

    my $bool = $self->_filter_matches($key, $filter, $command, $parsed, $stdout);

Whether one registered filter applies to a command. C<parsed_command>
filters are matched structurally, legacy filters by their key as a regex
against the raw command.

C<$stdout> is what the C<output_detect> check looks at; pass C<undef> when
there is no output yet (L</transform_command> only rewrites the command),
which skips that check.

=head2 _shapes_output

    my $bool = $self->_shapes_output($filter);

Whether a filter has anything to say about the B<output> -- i.e. whether any
of the pipeline stages would do something for it.

Not every filter does. The git-commit filter carries no output attribute at
all; it is registered only for its C<command_transform>. Such a filter must
stay out of the output-filter selection, see L</_match_filter>.

The list is the stages of L</_pipeline>: a new stage attribute belongs in
here too, otherwise a filter using only that attribute is never selected.

=head2 _match_filter

    my $filter = $self->_match_filter($command, $stdout);

The one filter that shapes the output for this command, or undef when none
matches.

Only filters that shape output take part -- a filter registered purely for
its C<command_transform> is not an answer to "how is this output
compressed?". Letting it compete decided two unrelated questions with one
lookup: for `cat msg.txt && git commit -m "fix"` both the anchored cat
filter and the deliberately unanchored git-commit filter match, and whoever
won, one of the two concerns lost -- the trailer or the filtering, picked by
hash order (karr #25). The command rewrite is now L</transform_command>'s
own decision.

=head2 _pipeline

    my ($command, $stdout, $stderr) = $self->_pipeline($command, $stdout, $stderr);

The eleven-stage compression pipeline, and the only copy of it. L</compress>
and L</process> are the two shapes it is returned in -- a list for the hook,
a hashref for the MCP server -- and nothing else may differ between them.

It used to exist twice, hand-kept in sync. Both copies had to be touched
separately for the same fixes, and the test suite reached one through
C<compress()> and the other through C<process()>, so a fix landing in only
one of them was invisible (karr #23). t/compress.t compares the two entry
points over the whole filter table for that reason.

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

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
