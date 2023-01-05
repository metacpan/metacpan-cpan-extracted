package Getopt::App;
use feature qw(:5.16);
use strict;
use warnings;
use utf8;

use Carp         qw(croak);
use Getopt::Long ();
use List::Util   qw(first);

our $VERSION = '0.11';

our ($OPT_COMMENT_RE, $OPTIONS, $SUBCOMMAND, $SUBCOMMANDS, %APPS) = (qr{\s+\#\s+});

our $call_maybe = sub {
  my ($app, $m) = (shift, shift);
  local $Getopt::App::APP_CLASS;
  $m = $app->can($m) || __PACKAGE__->can("_$m");
  return $m ? $app->$m(@_) : undef;
};

sub bundle {
  my ($class, $script, $OUT) = (@_, \*STDOUT);
  my ($package, @script);

  open my $SCRIPT, '<', $script or croak "Can't read $script: $!";
  while (my $line = readline $SCRIPT) {
    if ($line =~ m!^\s*package\s+\S+\s*;!) {    # look for app class name
      $package .= $line;
      last;
    }
    elsif ($. == 1) {                           # look for hashbang
      $line =~ m/^#!/ ? print {$OUT} $line : do { print {$OUT} "#!$^X\n"; push @script, $line };
    }
    else {
      push @script, $line;
      last if $line =~ m!^[^#]+;!;
    }
  }

  my $out_line = '';
  open my $SELF, '<', __FILE__ or croak "Can't read Getopt::App: $!";
  while (my $line = readline $SELF) {
    next if $line =~ m!(?:\bVERSION\s|^\s*$)!;                 # TODO: Should version get skipped?
    next if $line =~ m!^sub bundle\s\{! .. $line =~ m!^}$!;    # skip bundle()
    last if $line =~ m!^1;\s*$!;                               # do not include POD

    chomp $line;
    if ($line =~ m!^sub\s!) {
      print {$OUT} $out_line, "\n" if $out_line;
      $line =~ m!\}$! ? print {$OUT} $line, "\n" : ($out_line = $line);
    }
    elsif ($line =~ m!^}$!) {
      print {$OUT} $out_line, $line, "\n";
      $out_line = '';
    }
    else {
      $line =~ s!^[ ]{2,}!!;    # remove leading white space
      $line =~ s!\#\s.*!!;      # remove comments
      $out_line .= $line;
    }
  }

  print {$OUT} qq(BEGIN{\$INC{'Getopt/App.pm'}='BUNDLED'}\n);
  print {$OUT} +($package || "package main\n");
  print {$OUT} @script;
  print {$OUT} $_ while readline $SCRIPT;
}

sub capture {
  my ($app, $argv) = @_;
  my ($exit_value, $stderr, $stdout) = (-1, '', '');

  local *STDERR;
  local *STDOUT;
  open STDERR, '>', \$stderr;
  open STDOUT, '>', \$stdout;
  ($!, $@) = (0, '');
  eval {
    $exit_value = $app->($argv || [@ARGV]);
    1;
  } or do {
    print STDERR $@;
    $exit_value = int $!;
  };

  return [$stdout, $stderr, $exit_value];
}

sub extract_usage {
  my %pod2usage;
  $pod2usage{'-sections'} = shift;
  $pod2usage{'-input'}    = shift || (caller)[1];
  $pod2usage{'-verbose'}  = 99 if $pod2usage{'-sections'};

  require Pod::Usage;
  open my $USAGE, '>', \my $usage;
  Pod::Usage::pod2usage(-exitval => 'noexit', -output => $USAGE, %pod2usage);
  close $USAGE;

  $usage //= '';
  $usage =~ s!^(.*?)\n!!s if $pod2usage{'-sections'};
  $usage =~ s!^Usage:\n\s+([A-Z])!$1!s;                 # Remove "Usage" header if SYNOPSIS has a description
  $usage =~ s!^    !!gm;

  return join '', $usage, _usage_for_subcommands($SUBCOMMANDS || []), _usage_for_options($OPTIONS || []);
}

sub import {
  my ($class, @flags) = @_;
  my $caller = caller;

  $_->import for qw(strict warnings utf8);
  feature->import(':5.16');

  my $skip_default;
  no strict qw(refs);
  while (my $flag = shift @flags) {
    if ($flag eq '-capture') {
      *{"$caller\::capture"} = \&capture;
      $skip_default = 1;
    }
    elsif ($flag eq '-complete') {
      require Getopt::App::Complete;
      *{"$caller\::generate_completion_script"} = \&Getopt::App::Complete::generate_completion_script;
    }
    elsif ($flag eq '-signatures') {
      require experimental;
      experimental->import(qw(signatures));
    }
    elsif ($flag !~ /^-/) {
      croak "package definition required - cannot extend main with $flag!" if $caller eq 'main';
      croak "require $flag FAIL $@" unless eval "require $flag;1";
      push @{"${caller}::ISA"}, $flag;
    }
  }

  unless ($skip_default) {
    *{"$caller\::extract_usage"} = \&extract_usage unless $caller->can('extract_usage');
    *{"$caller\::new"}           = \&new           unless $caller->can('new');
    *{"$caller\::run"}           = \&run;
  }
}

sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub run {
  my @rules = @_;
  my $class = $Getopt::App::APP_CLASS || caller;
  return sub { local $Getopt::App::APP_CLASS = $class; run(@_, @rules) }
    if !$Getopt::App::APP_CLASS and defined wantarray;

  my $cb   = pop @rules;
  my $argv = ref $rules[0] eq 'ARRAY' ? shift @rules : [@ARGV];
  local $OPTIONS = [@rules];
  @rules = map {s!$OPT_COMMENT_RE.*$!!r} @rules;

  my $app = $class->new;
  return $app->$call_maybe('getopt_complete_reply') if defined $ENV{COMP_POINT} and defined $ENV{COMP_LINE};

  $app->$call_maybe(getopt_pre_process_argv => $argv);

  local $SUBCOMMANDS = $app->$call_maybe('getopt_subcommands');
  my $exit_value = $SUBCOMMANDS ? _subcommand_run_maybe($app, $SUBCOMMANDS, $argv) : undef;
  return _exit($app, $exit_value) if defined $exit_value;

  my @configure = $app->$call_maybe('getopt_configure');
  my $prev      = Getopt::Long::Configure(@configure);
  my $valid     = Getopt::Long::GetOptionsFromArray($argv, $app, @rules) ? 1 : 0;
  Getopt::Long::Configure($prev);
  $app->$call_maybe(getopt_post_process_argv => $argv, {valid => $valid});

  return _exit($app, $valid ? $app->$cb(@$argv) : 1);
}

sub _getopt_complete_reply { Getopt::App::Complete::complete_reply(@_) }

sub _getopt_configure {qw(bundling no_auto_abbrev no_ignore_case pass_through require_order)}

sub _getopt_load_subcommand {
  my ($app, $subcommand, $argv) = @_;
  return $subcommand->[1] if ref $subcommand->[1] eq 'CODE';

  ($@, $!) = ('', 0);
  croak "Unable to load subcommand $subcommand->[0]: $@ ($!)" unless my $code = do $subcommand->[1];
  return $code;
}

sub _getopt_post_process_argv {
  my ($app, $argv, $state) = @_;
  return unless $state->{valid};
  return unless $argv->[0] and $argv->[0] =~ m!^-!;
  $! = 1;
  die "Invalid argument or argument order: @$argv\n";
}

sub _getopt_unknown_subcommand {
  my ($app, $argv) = @_;
  $! = 2;
  die "Unknown subcommand: $argv->[0]\n";
}

sub _exit {
  my ($app, $exit_value) = @_;
  $exit_value = $app->$call_maybe(getopt_post_process_exit_value => $exit_value) // $exit_value;
  $exit_value = 0   unless $exit_value and $exit_value =~ m!^\d{1,3}$!;
  $exit_value = 255 unless $exit_value < 255;
  exit $exit_value unless $Getopt::App::APP_CLASS;
  return $exit_value;
}

sub _subcommand_run {
  my ($app, $subcommand, $argv) = @_;
  local $Getopt::App::SUBCOMMAND = $subcommand;
  unless ($APPS{$subcommand->[1]}) {
    $APPS{$subcommand->[1]} = $app->$call_maybe(getopt_load_subcommand => $subcommand, $argv);
    croak "$subcommand->[0] did not return a code ref" unless ref $APPS{$subcommand->[1]} eq 'CODE';
  }

  return $APPS{$subcommand->[1]}->([@$argv[1 .. $#$argv]]);
}

sub _subcommand_run_maybe {
  my ($app, $subcommands, $argv) = @_;
  return undef unless $argv->[0] and $argv->[0] =~ m!^\w!;
  return $app->$call_maybe(getopt_unknown_subcommand => $argv)
    unless my $subcommand = first { $_->[0] eq $argv->[0] } @$subcommands;
  return _subcommand_run($app, $subcommand, $argv);
}

sub _usage_for_options {
  my ($rules) = @_;
  return '' unless @$rules;

  my ($len, @options) = (0);
  for (@$rules) {
    my @o = split $OPT_COMMENT_RE, $_, 2;
    $o[0] =~ s/(=[si][@%]?|\!|\+)$//;
    $o[0] = join ', ', map { length($_) == 1 ? "-$_" : "--$_" } sort { length($b) <=> length($a) } split /\|/, $o[0];
    $o[1] //= '';

    my $l = length $o[0];
    $len = $l if $l > $len;
    push @options, \@o;
  }

  return "Options:\n" . join('', map { sprintf "  %-${len}s  %s\n", @$_ } @options) . "\n";
}

sub _usage_for_subcommands {
  my ($subcommands) = @_;
  return '' unless @$subcommands;

  my ($len, @cmds) = (0);
  for my $s (@$subcommands) {
    my $l = length $s->[0];
    $len = $l if $l > $len;
    push @cmds, [$s->[0], $s->[2] // ''];
  }

  return "Subcommands:\n" . join('', map { sprintf "  %-${len}s  %s\n", @$_ } @cmds) . "\n";
}

1;

=encoding utf8

=head1 NAME

Getopt::App - Write and test your script with ease

=head1 SYNOPSIS

=head2 The script file

  #!/usr/bin/env perl
  package My::Script;
  use Getopt::App -complete, -signatures;

  # See "APPLICATION METHODS"
  sub getopt_post_process_argv ($app, $argv, $state) { ... }
  sub getopt_configure ($app) { ... }

  # run() must be the last statement in the script
  run(

    # Specify your Getopt::Long options and optionally a help text
    'h|help            # Output help',
    'v+                # Verbose output',
    'name=s            # Specify a name',
    'completion-script # Print autocomplete script',

    # Here is the main sub that will run the script
    sub ($app, @extra) {
      return print generate_completion_script() if $app->{'completion-script'};
      return print extract_usage()              if $app->{h};
      say $app->{name} // 'no name';            # Access command line options
      return 42;                                # Reture value is used as exit code
    }
  );

=head2 Running the script

The example script above can be run like any other script:

  $ my-script --name superwoman; # prints "superwoman"
  $ echo $? # 42

=head2 Testing

  use Test::More;
  use Cwd qw(abs_path);
  use Getopt::App -capture;

  # Sourcing the script returns a callback
  my $app = do(abs_path('./bin/myapp'));

  # The callback can be called with any @ARGV
  subtest name => sub {
    my $got = capture($app, [qw(--name superwoman)]);
    is $got->[0], "superwoman\n", 'stdout';
    is $got->[1], '', 'stderr';
    is $got->[2], 42, 'exit value';
  };

  done_testing;

=head2 Subcommands

  #!/usr/bin/env perl
  # Define a package to avoid mixing methods after loading the subcommand script
  package My::App::main;
  use Getopt::App -complete;

  # getopt_subcommands() is called by Getopt::App
  sub getopt_subcommands {
    my $app = shift;

    return [
      ['find',   '/path/to/subcommand/find.pl',   'Find things'],
      ['update', '/path/to/subcommand/update.pl', 'Update things'],
    ];
  }

  # run() is only called if there are no matching sub commands
  run(
    'h                 # Print help',
    'completion-script # Print autocomplete script',
    sub {
      my ($app, @args) = @_;
      return print generate_completion_script() if $app->{'completion-script'};
      return print extract_usage();
    }
  );

See L</getopt_subcommands> and L<https://github.com/jhthorsen/getopt-app/tree/main/example>
for more details.

=head1 DESCRIPTION

L<Getopt::App> is a module that helps you structure your scripts and integrates
L<Getopt::Long> with a very simple API. In addition it makes it very easy to
test your script, since the script file can be sourced without actually being
run.

L<Getopt::App> also supports infinite nested L<subcommands|/getopt_subcommands>
and a method for L<bundling|/bundle> this module with your script to prevent
depending on a module from CPAN.

=head1 APPLICATION METHODS

These methods are optional, but can be defined in your script to override the
default behavior.

=head2 getopt_complete_reply

  $app->getopt_complete_reply;

This method will be called instead of the L</run> callback when the
C<COMP_LINE> and C<COMP_POINT> environment variables are set. The default
implementation will call L<Getopt::App::Complete/complete_reply>.

See also "Completion" under L</import>.

=head2 getopt_configure

  @configure = $app->getopt_configure;

This method can be defined if you want L<Getopt::Long/Configure> to be set up
differently. The default return value is:

  qw(bundling no_auto_abbrev no_ignore_case pass_through require_order)

The default return value is currently EXPERIMENTAL.

=head2 getopt_load_subcommand

  $code = $app->getopt_load_subcommand($subcommand, [@ARGV]);

Takes the subcommand found in the L</getopt_subcommands> list and the command
line arguments and must return a CODE block. The default implementation is
simply:

    $code = do($subcommand->[1]);

=head2 getopt_post_process_argv

  $bool = $app->getopt_post_process_argv([@ARGV], {%state});

This method can be used to post process the options. C<%state> contains a key
"valid" which is true or false, depending on the return value from
L<Getopt::Long/GetOptionsFromArray>.

This method can C<die> and optionally set C<$!> to avoid calling the function
passed to L</run>.

The default behavior is to check if the first item in C<$argv> starts with a
hyphen, and C<die> with an error message if so:

  Invalid argument or argument order: @$argv\n

=head2 getopt_post_process_exit_value

  $exit_value = $app->getopt_post_process_exit_value($exit_value);

A method to be called after the L</run> function has been called.
C<$exit_value> holds the return value from L</run> which could be any value,
not just 0-255. This value can then be changed to change the exit value from
the program.

  sub getopt_post_process_exit_value ($app, $exit_value) {
    return int(1 + rand 10);
  }

=head2 getopt_pre_process_argv

  $app->getopt_pre_process_argv($argv);

This method can be defined to pre-process C<$argv> before it is passed on to
L<Getopt::Long/GetOptionsFromArray>. Example:

  sub getopt_pre_process_argv ($app, $argv) {
    $app->{first_non_option} = shift @$argv if @$argv and $argv->[0] =~ m!^[a-z]!;
  }

This method can C<die> and optionally set C<$!> to avoid calling the actual
L</run> function.

=head2 getopt_subcommands

  $subcommands = $app->getopt_subcommands;

This method must be defined in the script to enable sub commands. The return
value must be either C<undef> to disable subcommands or an array-ref of
array-refs like this:

  [["subname", "/abs/path/to/sub-command-script", "help text"], ...]

The first element in each array-ref "subname" will be matched against the first
argument passed to the script, and when matched the "sub-command-script" will
be sourced and run inside the same perl process. The sub command script must
also use L<Getopt::App> for this to work properly.

The sub-command will have C<$Getopt::App::SUBCOMMAND> set to the item found in
the list.

See L<https://github.com/jhthorsen/getopt-app/tree/main/example> for a working
example.

=head2 getopt_unknown_subcommand

  $exit_value = $app->getopt_unknown_subcommand($argv);

Will be called when L</getopt_subcommands> is defined but C<$argv> does not
match an item in the list. Default behavior is to C<die> with an error message:

  Unknown subcommand: $argv->[0]\n

Returning C<undef> instead of dying or a number (0-255) will cause the L</run>
callback to be called.

=head1 EXPORTED FUNCTIONS

=head2 capture

  use Getopt::App -capture;
  my $app = do '/path/to/bin/myapp';
  my $array_ref = capture($app, [@ARGV]); # [$stdout, $stderr, $exit_value]

Used to run an C<$app> and capture STDOUT, STDERR and the exit value in that
order in C<$array_ref>. This function will also capture C<die>. C<$@> will be
set and captured in the second C<$array_ref> element, and C<$exit_value> will
be set to C<$!>.

=head2 extract_usage

  # Default to "SYNOPSIS" from current file
  my $str = extract_usage($section, $file);
  my $str = extract_usage($section);
  my $str = extract_usage();

Will extract a C<$section> from POD C<$file> and append command line option
descriptions when called from inside of L</run>. Command line options can
optionally have a description with "spaces-hash-spaces-description", like this:

  run(
    'o|option  # Some description',
    'v|verbose # Enable verbose output',
    sub {
      ...
    },
  );

This function will I<not> be exported if a function with the same name already
exists in the script.

=head2 new

  my $obj = new($class, %args);
  my $obj = new($class, \%args);

This function is exported into the caller package so we can construct a new
object:

  my $app = Application::Class->new(\%args);

This function will I<not> be exported if a function with the same name already
exists in the script.

=head2 run

  # Run a code block on valid @ARGV
  run(@rules, sub ($app, @extra) { ... });

  # For testing
  my $cb = run(@rules, sub ($app, @extra) { ... });
  my $exit_value = $cb->([@ARGV]);

L</run> can be used to call a callback when valid command line options is
provided. On invalid arguments, warnings will be issued and the program exit
with C<$?> set to 1.

C<$app> inside the callback is a hash blessed to the caller package. The keys
in the hash are the parsed command line options, while C<@extra> is the extra
unparsed command line options.

C<@rules> are the same options as L<Getopt::Long> can take. Example:

  # app.pl -vv --name superwoman -o OptX cool beans
  run(qw(h|help v+ name=s o=s@), sub ($app, @extra) {
    die "No help here" if $app->{h};
    warn $app->{v};    # 2
    warn $app->{name}; # "superwoman"
    warn @{$app->{o}}; # "OptX"
    warn @extra;       # "cool beans"
    return 0;          # Used as exit code
  });

In the example above, C<@extra> gets populated, since there is a non-flag value
"cool" after a list of valid command line options.

=head1 METHODS

=head2 bundle

  Getopt::App->bundle($path_to_script);
  Getopt::App->bundle($path_to_script, $fh);

This method can be used to combine L<Getopt::App> and C<$path_to_script> into a
a single script that does not need to have L<Getopt::App> installed from CPAN.
This is for example useful for sysadmin scripts that otherwise only depends on
core Perl modules.

The script will be printed to C<$fh>, which defaults to C<STDOUT>.

Example usage:

  perl -MGetopt::App -e'Getopt::App->bundle(shift)' ./src/my-script.pl > ./bin/my-script;

=head2 import

  use Getopt::App;
  use Getopt::App 'My::Script::Base', -signatures;
  use Getopt::App -capture;

=over 2

=item * Default

  use Getopt::App;

Passing in no flags will export the default functions L</extract_usage>,
L</new> and L</run>. In addition it will save you from a lot of typing, since
it will also import the following:

  use strict;
  use warnings;
  use utf8;
  use feature ':5.16';

=item * Completion

  use Getopt::App -complete;

Same as L</Default>, but will also load L<Getopt::App::Complete> and import
L<generate_completion_script()|Getopt::App::Complete/generate_completion_script>.

=item * Signatures

  use Getopt::App -signatures;

Same as L</Default>, but will also import L<experimental/signatures>. This
requires Perl 5.20+.

=item * Class name

  package My::Script::Foo;
  use Getopt::App 'My::Script';

Same as L</Default> but will also make C<My::Script::Foo> inherit from
L<My::Script>. Note that a package definition is required.

=item * Capture

  use Getopt::App -capture;

This will only export L</capture>.

=back

=head1 COPYRIGHT AND LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
