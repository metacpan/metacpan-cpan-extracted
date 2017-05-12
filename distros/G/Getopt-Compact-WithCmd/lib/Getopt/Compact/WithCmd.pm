package Getopt::Compact::WithCmd;

use strict;
use warnings;
use 5.008_001;
use Data::Dumper ();
use List::Util qw(max);
use Getopt::Long qw(GetOptionsFromArray);
use Carp ();
use constant DEFAULT_CONFIG => (
    no_auto_abbrev => 1,
    no_ignore_case => 1,
    bundling       => 1,
);

our $VERSION = '0.22';

my $TYPE_MAP = {
    'Bool'   => '!',
    'Incr'   => '+',
    'Str'    => '=s',
    'Int'    => '=i',
    'Num'    => '=f',
    'ExNum'  => '=o',
};

my $TYPE_GEN = {};

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        cmd         => $args{cmd} || do { require File::Basename; File::Basename::basename($0) },
        name        => $args{name},
        version     => $args{version} || $::VERSION,
        modes       => $args{modes},
        opt         => {},
        usage       => exists $args{usage} && !$args{usage} ? 0 : 1,
        args        => $args{args} || '',
        _argv       => \@ARGV,
        struct      => [],
        summary     => {},
        requires    => {},
        ret         => 0,
        error       => undef,
        other_usage => undef,
        commands    => [],
        _struct     => $args{command_struct} || {},
    }, $class;

    my %config = (DEFAULT_CONFIG, %{$args{configure} || {}});
    my @gconf = grep $config{$_}, keys %config;
    Getopt::Long::Configure(@gconf) if @gconf;

    $self->_init_summary($args{command_struct});

    $self->_init_struct($args{global_struct} || []);
    my $opthash = $self->_parse_struct || return $self;
    if ($args{command_struct}) {
        if (my @gopts = $self->_parse_argv) {
            $self->{ret} = $self->_parse_option(\@gopts, $opthash);
            unshift @ARGV, @gopts;
            return $self unless $self->{ret};
            return $self if $self->_want_help;
        }
        $self->_check_requires;
    }
    else {
        $self->{ret} = $self->_parse_option(\@ARGV, $opthash);
        return $self unless $self->{ret};
        return $self if $self->_want_help;
        $self->_check_requires;
        return $self;
    }

    $self->_parse_command_struct($args{command_struct});
    return $self;
}

sub new_from_array {
    my ($class, $args, %options) = @_;
    unless (ref $args eq 'ARRAY') {
        Carp::croak("Usage: $class->new_from_array(\\\@args, %options)");
    }
    local *ARGV = $args;
    return $class->new(%options);
}

sub new_from_string {
    my ($class, $str, %options) = @_;
    unless (defined $str) {
        Carp::croak("Usage: $class->new_from_string(\$str, %options)");
    }
    require Text::ParseWords;
    my $args = [Text::ParseWords::shellwords($str)];
    local *ARGV = $args;
    return $class->new(%options);
}

sub args       { $_[0]->{_argv}     }
sub error      { $_[0]->{error}||'' }
sub command    { $_[0]->{command}   }
sub commands   { $_[0]->{commands}  }
sub status     { $_[0]->{ret}       }
sub is_success { $_[0]->{ret}       }
sub pod2usage  { Carp::carp('Not implemented') }

sub opts {
    my($self) = @_;
    my $opt = $self->{opt};
    if ($self->{usage} && ($opt->{help} || $self->status == 0)) {
        # display usage message & exit
        print $self->usage;
        exit !$self->status;
    }
    return $opt;
}

sub usage {
    my($self, @targets) = @_;
    my $usage = '';
    my(@help, @commands);

    if ((defined $self->command && $self->command eq 'help') || @targets) {
        delete $self->{command};
        @targets = @{$self->{_argv}} unless @targets;
        for (my $i = 0; $i < @targets; $i++) {
            my $target = $targets[$i];
            last unless defined $target;
            unless (ref $self->{_struct}{$target} eq 'HASH') {
                $self->{error} = "Unknown command: $target";
                last;
            }
            else {
                $self->{command} = $target;
                push @{$self->{commands}}, $target;
                $self->_init_struct($self->{_struct}{$target}{options});
                $self->_extends_usage($self->{_struct}{$target});

                if (ref $self->{_struct}{$target}{command_struct} eq 'HASH') {
                    $self->{_struct} = $self->{_struct}{$target}{command_struct};
                }
                else {
                    $self->{summary} = {};
                }
            }
        }
    }

    my($name, $version, $cmd, $struct, $args, $summary, $error, $other_usage) = map
        $self->{$_} || '', qw/name version cmd struct args summary error other_usage/;

    $usage .= "$error\n" if $error;

    if ($name) {
        $usage .= $name;
        $usage .= " v$version" if $version;
        $usage .= "\n";
    }

    if ($self->command && $self->command ne 'help') {
        my $sub_command = join q{ }, @{$self->commands} ? @{$self->commands} : $self->command;
        $usage .= "usage: $cmd $sub_command [options]";
    }
    else {
        $usage .= "usage: $cmd [options]";
        $usage .= ' COMMAND' if keys %$summary;
    }
    $usage .= ($args ? " $args" : '') . "\n\n";

    for my $o (@$struct) {
        my ($name_spec, $desc, $arg_spec, $dist, $opts) = @$o;
        $desc = '' unless defined $desc;
        my @onames = $self->_option_names($name_spec);
        my $optname = join
            (', ', map { (length($_) > 1 ? '--' : '-').$_ } @onames);
        $optname = '    '.$optname unless length($onames[0]) == 1;
        my $info = do {
            local $Data::Dumper::Indent = 0;
            local $Data::Dumper::Terse  = 1;
            my $info = [];
            push @$info, $self->_opt_spec2name($arg_spec) || $arg_spec || '';
            push @$info, $opts->{required}        ? "(required)" : '';
            push @$info, defined $opts->{default} ? "(default: ".Data::Dumper::Dumper($opts->{default}).")" : '';
            $info;
        };
        push @help, [ $optname, $info, ucfirst($desc) ];
    }

    if (@help) {
        require Text::Table;
        my $sep = \'   ';
        $usage .= "options:\n";
        $usage .= Text::Table->new($sep, '', $sep, '', $sep, '')->load($self->_format_info(@help))->stringify."\n";
    }

    if (defined $other_usage && length $other_usage > 0) {
        $other_usage =~ s/\n$//ms;
        $usage .= "$other_usage\n\n";
    }

    if (!$self->command || $self->{has_sub_command}) {
        for my $command (sort keys %$summary) {
            push @commands, [ $command, ucfirst $summary->{$command} ];
        }

        if (@commands) {
            require Text::Table;
            my $sep = \'   ';
            $usage .= "Implemented commands are:\n";
            $usage .= Text::Table->new($sep, '', $sep, '')->load(@commands)->stringify."\n";
            my $help_command = "$cmd help COMMAND";
            if (@{$self->commands}) {
                my $sub_commands = join q{ }, @{$self->commands};
                $help_command = "$cmd $sub_commands COMMAND --help";
            }
            $usage .= "See '$help_command' for more information on a specific command.\n\n";
        }
    }

    return $usage;
}

sub show_usage {
    my $self = shift;
    print $self->usage(@_);
    exit !$self->status;
}

sub completion {
    my($self, $shell) = @_;
    $shell ||= 'bash';

    if ($shell eq 'bash') {
        return $self->_completion_bash;
    } else {
        Carp::carp("Not implemented: completion for $shell");
        return "";
    }
}

sub show_completion {
    my $self = shift;
    print $self->completion(@_);
    exit !$self->status;
}

sub _completion_bash {
    my $self = shift;
    my $comp = '';

    my $prog  = $self->{name} || substr($0, rindex($0, '/')+1);
    my $fname = $prog;
    $fname =~ s/[.-]/_/g;

    my @global_opts;
    my @commands;
    my $case = {
        word  => '"$cmd"',
        cases => [],
    };

    @global_opts = $self->_options2optarg($self->{struct});

    for my $cmd (sort keys %{ $self->{_struct} }) {
        my $s = $self->{_struct}{$cmd};

        my @opts = $self->_options2optarg($s->{options});
        my @commands2;

        if (ref $s->{command_struct} eq 'HASH') {
            for my $cmd (sort keys %{ $s->{command_struct} }) {
                my $s = $s->{command_struct}{$cmd};
                my @opts = $self->_options2optarg($s->{options});

                push @commands2, {
                    cmd  => $cmd,
                    opts => \@opts,
                };
            }
        }

        push @commands, {
            cmd    => $cmd,
            opts   => \@opts,
            subcmd => \@commands2,
            args   => ($s->{args} || ''),
        };
    }

    $comp .= "_$fname() {\n";
    $comp .= <<'EOC';
  COMPREPLY=()
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  local cmd=()
  for ((i=1; i<COMP_CWORD; i++)); do
    # skip global opts and type to find cmd
    if [[ "${COMP_WORDS[$i]}" != -* && "${COMP_WORDS[$i]}" != [A-Z]* ]]; then
      cmd[${#cmd[@]}]=${COMP_WORDS[$i]}
    fi
  done

EOC

    $comp .= sprintf qq{  local global_opts="%s"\n},
        join(" ", map { @{$_->{opt}} } @global_opts);
    $comp .= sprintf qq{  local cmds="%s"\n},
        join(" ", map { $_->{cmd} } @commands);
    $comp .= "\n";

    ### sub commands
    for my $command (@commands) {

        my $case_prev = {
            word  => '"$prev"',
            cases => [
                _opts2casecmd(@{ $command->{opts} }),
                {
                    pat => '*',
                    cmd => ['COMPREPLY=($(compgen -W "'._gen_wordlist($command).'" -- "$cur"))'],
                },
            ],
        };

        if (scalar(@{ $command->{subcmd} }) > 0) {
            my @cases;

            for my $subcommand (@{ $command->{subcmd} }) {
                next if (scalar(@{ $subcommand->{opts} }) <= 0);
                push @cases, {
                    pat => $subcommand->{cmd},
                    cmd => [{
                        word  => '"$prev"',
                        cases => [
                            _opts2casecmd(@{ $subcommand->{opts} }),
                            {
                                pat => '*',
                                cmd => ['COMPREPLY=($(compgen -W "'._gen_wordlist($subcommand).'" -- "$cur"))'],
                            },
                        ],
                    }],
                };
            }

            push @cases, {
                pat => '*',
                cmd => [ $case_prev ],
            };

            push @{ $case->{cases} }, {
                pat => $command->{cmd},
                cmd => [{
                    word  => '"${cmd[1]}"',
                    cases => [@cases],
                }],
            };
        } else {
            push @{ $case->{cases} }, {
                pat => $command->{cmd},
                cmd => [ $case_prev ],
            };
        }
    }

    ### global opts
    push @{ $case->{cases} }, {
        pat => '*',
        cmd => [{
            word  => '"$prev"',
            cases => [
                _opts2casecmd(@global_opts),
                {
                    pat => '*',
                    cmd => ['COMPREPLY=($(compgen -W "$global_opts $cmds" -- "$cur"))'],
                },
            ],
        }],
    };

    my @c = _generate_case_command($case);
    $comp .= join("\n", map {"  ".$_} @c)."\n";

    $comp .= <<"EOC";
}

complete -F _$fname $prog
EOC
    return $comp;
}

# take following hashref and generate case command string
# +{
#     word  => WORD, # case WORD in
#     cases => [
#         {
#             pat => PATTERN,               # PATTERN)
#             cmd => ['cmd1', 'cmd2', ...], # COMMANDS;;
#         },
#         {
#             pat => PATTERN,               # PATTERN)
#             cmd => [                      # nested case command
#                 {
#                     word  => WORD,
#                     cases => [ ... ],
#                 },
#             ],
#         },
#     ],
# }
sub _generate_case_command {
    my $case = shift;
    my @line;

    push @line, "case $case->{word} in";
    for my $c (@{ $case->{cases} }) {
        push @line, "  $c->{pat})";
        for my $cmd (@{ $c->{cmd} }, ';;') {
            if (ref $cmd eq 'HASH') {
                push @line, map {"    ".$_} _generate_case_command->($cmd);
            } else {
                push @line, "    ".$cmd;
            }
        }
    }
    push @line, "esac";

    return @line;
}

sub _options2optarg {
    my($self, $opts) = @_;
    my @optarg;

    for my $o (@{ $opts }) {
        my ($name_spec, $desc, $arg_spec, $dist, $opts) = @$o;
        my @onames = map { (length($_) > 1 ? '--' : '-').$_ } $self->_option_names($name_spec);
        my $arg = $self->_opt_spec2name($arg_spec) || $arg_spec || '';
        $arg = '' if $arg eq 'Incr';
        push @optarg, {
            opt => \@onames,
            arg => $arg,
        };
    }

    return @optarg;
}

sub _opts2casecmd {
    my @cases;
    for my $o (grep { $_->{arg} } @_) {
        push @cases, {
            pat => join("|", @{ $o->{opt} }),
            cmd => ['COMPREPLY=($(compgen -W "'.$o->{arg}.'" -- "$cur"))'],
        };
    }

    return @cases;
}

sub _gen_wordlist {
    my $command = shift;

    return join(" ",
                '-h', '--help',
                (map { @{$_->{opt}} } @{ $command->{opts} }),
                ($command->{args}||''),
                (map { $_->{cmd} } @{ $command->{subcmd} }),
            );
}

sub _opt_spec2name {
    my ($self, $spec) = @_;
    my $name = '';
    return $name unless defined $spec;
    my ($type, $dest) = $spec =~ /^[=:]?([!+isof])([@%])?/;
    if ($type) {
        $name =
            $type eq '!' ? 'Bool'  :
            $type eq '+' ? 'Incr'  :
            $type eq 's' ? 'Str'   :
            $type eq 'i' ? 'Int'   :
            $type eq 'f' ? 'Num'   :
            $type eq 'o' ? 'ExNum' : '';
    }
    if ($dest) {
        $name = $dest eq '@' ? "Array[$name]" : $dest eq '%' ? "Hash[$name]" : $name;
    }
    return $name;
}

sub _format_info {
    my ($self, @help) = @_;

    my $type_max     = 0;
    my $required_max = 0;
    my $default_max  = 0;
    for my $row (@help) {
        my ($type, $required, $default) = @{$row->[1]};
        $type_max     = max $type_max, length($type);
        $required_max = max $required_max, length($required);
        $default_max  = max $default_max, length($default);
    }

    for my $row (@help) {
        my ($type, $required, $default) = @{$row->[1]};
        my $parts = [];
        for my $stuff ([$type_max, $type], [$required_max, $required], [$default_max, $default]) {
            push @$parts, sprintf '%-*s', @$stuff if $stuff->[0] > 0;
        }
        $row->[1] = join ' ', @$parts;
    }

    return @help;
}

sub _parse_command_struct {
    my ($self, $command_struct) = @_;
    $command_struct ||= {};

    my $command_map = { map { $_ => 1 } keys %$command_struct };
    my $command = shift @ARGV;
    unless (defined $command) {
        $self->{ret} = $self->_check_requires;
        return $self;
    }

    unless ($command_map->{help}) {
        $command_map->{help} = 1;
        $command_struct->{help} = {
            args => '[COMMAND]',
            desc => 'show help message',
        };
    }

    unless (exists $command_map->{$command}) {
        $self->{error} = "Unknown command: $command";
        $self->{ret} = 0;
        return $self;
    }

    $self->{command} ||= $command;

    if ($command eq 'help') {
        $self->{ret} = 0;
        delete $self->{error};
        if (defined $ARGV[0] && exists $command_struct->{$ARGV[0]}) {
            my $nested_struct = $command_struct->{$ARGV[0]}{command_struct};
            $self->_init_nested_struct($nested_struct) if $nested_struct;
        }
        return $self;
    }

    push @{$self->{commands} ||= []}, $command;
    $self->_init_struct($command_struct->{$command}{options});
    $self->_extends_usage($command_struct->{$command});
    my $opthash = $self->_parse_struct || return $self;

    if (my $nested_struct = $command_struct->{$command}{command_struct}) {
        $self->_init_nested_struct($nested_struct);

        my @opts = $self->_parse_argv($nested_struct);
        $self->{ret} = $self->_parse_option(\@opts, $opthash);
        unshift @ARGV, @opts;
        $self->_check_requires;
        if ($self->_want_help) {
            delete $self->{error};
            $self->{ret} = 0;
        }
        return $self unless $self->{ret};
        $self->_parse_command_struct($nested_struct);
    }
    else {
        $self->{ret} = $self->_parse_option(\@ARGV, $opthash);
        $self->_check_requires;
        $self->{has_sub_command} = 0;
        if ($self->_want_help) {
            delete $self->{error};
            $self->{ret} = 0;
        }
    }

    return $self;
}

sub _want_help {
    exists $_[0]->{opt}{help} && $_[0]->{opt}{help} ? 1 : 0;
}

sub _init_nested_struct {
    my ($self, $nested_struct) = @_;
    $self->{summary} = {}; # reset
    $self->_init_summary($nested_struct);
    $self->{has_sub_command} = 1;
}

sub _parse_option {
    my ($self, $argv, $opthash) = @_;
    local $SIG{__WARN__} = sub {
        $self->{error} = join '', @_;
        chomp $self->{error};
    };
    my $ret = GetOptionsFromArray($argv, %$opthash) ? 1 : 0;

    $self->{parsed_opthash} = $opthash;

    return $ret;
}

sub _parse_argv {
    my ($self, $struct) = @_;
    $struct ||= $self->{_struct};

    my @opts;
    while (@ARGV) {
        my $argv = shift @ARGV;
        push @opts, $argv;
        last if exists $struct->{$argv};
    }
    return @opts;
}

sub _parse_struct {
    my ($self) = @_;
    my $struct = $self->{struct};

    my $opthash = {};
    my $default_opthash = {};
    my $default_args = [];
    for my $s (@$struct) {
        my($m, $descr, $spec, $ref, $opts) = @$s;
        my @onames = $self->_option_names($m);
        my($longname) = grep length($_) > 1, @onames;
        my ($type, $cb) = $self->_compile_spec($spec);
        my $o = join('|', @onames).($type||'');
        my $dest = $longname ? $longname : $onames[0];
        $opts ||= {};
        my $destination;
        if (ref $cb eq 'CODE') {
            my $t =
                substr($type, -1, 1) eq '@' ? 'Array' :
                substr($type, -1, 1) eq '%' ? 'Hash'  : '';
            if (ref $ref eq 'CODE') {
                $destination = sub { $ref->($_[0], $cb->($_[1])) };
            }
            elsif (ref $ref) {
                if (ref $ref eq 'SCALAR' || ref $ref eq 'REF') {
                    $$ref = $t eq 'Array' ? [] : $t eq 'Hash' ? {} : undef;
                }
                elsif (ref $ref eq 'ARRAY') {
                    @$ref = ();
                }
                elsif (ref $ref eq 'HASH') {
                    %$ref = ();
                }
                $destination = sub {
                    if ($t eq 'Array') {
                        if (ref $ref eq 'SCALAR' || ref $ref eq 'REF') {
                            push @{$$ref}, scalar $cb->($_[1]);
                        }
                        elsif (ref $ref eq 'ARRAY') {
                            push @$ref, scalar $cb->($_[1]);
                        }
                        elsif (ref $ref eq 'HASH') {
                            my @kv = split '=', $_[1], 2;
                            die qq(Option $_[0], key "$_[1]", requires a value\n)
                                unless @kv == 2;
                            $ref->{$kv[0]} = scalar $cb->($kv[1]);
                        }
                    }
                    elsif ($t eq 'Hash') {
                        if (ref $ref eq 'SCALAR' || ref $ref eq 'REF') {
                            $$ref->{$_[1]} = scalar $cb->($_[2]);
                        }
                        elsif (ref $ref eq 'ARRAY') {
                            # XXX but Getopt::Long is $ret = join '=', $_[1], $_[2];
                            push @$ref, $_[1], scalar $cb->($_[2]);
                        }
                        elsif (ref $ref eq 'HASH') {
                            $ref->{$_[1]} = scalar $cb->($_[2]);
                        }
                    }
                    else {
                        if (ref $ref eq 'SCALAR' || ref $ref eq 'REF') {
                            $$ref = $cb->($_[1]);
                        }
                        elsif (ref $ref eq 'ARRAY') {
                            @$ref = (scalar $cb->($_[1]));
                        }
                        elsif (ref $ref eq 'HASH') {
                            my @kv = split '=', $_[1], 2;
                            die qq(Option $_[0], key "$_[1]", requires a value\n)
                                unless @kv == 2;
                            %$ref = ($kv[0] => scalar $cb->($kv[1]));
                        }
                    }
                };
            }
            else {
                $destination = sub {
                    if ($t eq 'Array') {
                        $self->{opt}{$dest} ||= [];
                        push @{$self->{opt}{$dest}}, scalar $cb->($_[1]);
                    }
                    elsif ($t eq 'Hash') {
                        $self->{opt}{$dest} ||= {};
                        $self->{opt}{$dest}{$_[1]} = $cb->($_[2]);
                    }
                    else {
                        $self->{opt}{$dest} = $cb->($_[1]);
                    }
                };
            }
        }
        else {
            $destination = ref $ref ? $ref : \$self->{opt}{$dest};
        }
        if (exists $opts->{default}) {
            my $value = $opts->{default};
            if (ref $value eq 'ARRAY') {
                push @$default_args, map {
                    ("--$dest", $_) 
                } grep { defined $_ } @$value;
            }
            elsif (ref $value eq 'HASH') {
                push @$default_args, map {
                    (my $key = $_) =~ s/=/\\=/g;
                    ("--$dest" => "$key=$value->{$_}")
                } grep {
                    defined $value->{$_}  
                } keys %$value;
            }
            elsif (not ref $value) {
                if (!$spec || ($TYPE_MAP->{$spec} || $spec) eq '!') {
                    push @$default_args, "--$dest" if $value;
                }
                else {
                    push @$default_args, "--$dest", $value if defined $value;
                }
            }
            else {
                $self->{error} = "Invalid default option for $dest";
                $self->{ret} = 0;
            }
            $default_opthash->{$o} = $destination;
        }
        $opthash->{$o} = $destination;
        $self->{requires}{$dest} = $o if $opts->{required};
    }

    return if $self->{error};
    if (@$default_args) {
        $self->{ret} = $self->_parse_option($default_args, $default_opthash);
        unshift @ARGV, @$default_args;
        return unless $self->{ret};
    }

    return $opthash;
}

sub _init_struct {
    my ($self, $struct) = @_;
    $self->{struct} = ref $struct eq 'ARRAY' ? $struct : ref $struct eq 'HASH' ? $self->_normalize_struct($struct) : [];

    if (ref $self->{modes} eq 'ARRAY') {
        my @modeopt;
        for my $m (@{$self->{modes}}) {
            my($mc) = $m =~ /^(\w)/;
            push @modeopt, [[$mc, $m], qq($m mode)];
        }
        unshift @$struct, @modeopt;
    }

    unshift @{$self->{struct}}, [[qw(h help)], qq(this help message)]
        if $self->{usage} && !$self->_has_option('help');
}

sub _normalize_struct {
    my ($self, $struct) = @_;

    my $result = [];
    for my $option (keys %$struct) {
        my $data = $struct->{$option} || {};
        $data = ref $data eq 'HASH' ? $data : {};
        my $row = [];
        push @$row, [
            $option,
            ref $data->{alias} eq 'ARRAY' ? @{$data->{alias}} :
            defined $data->{alias}        ? $data->{alias}    :  (),
        ];
        push @$row, $data->{desc};
        push @$row, $data->{type};
        push @$row, $data->{dest};
        push @$row, $data->{opts};
        push @$result, $row;
    }

    return $result;
}

sub _compile_spec {
    my ($self, $spec) = @_;
    return if !defined $spec or $spec eq '';
    return $spec if $self->_opt_spec2name($spec);
    my ($type, $cb);
    if ($spec =~ /^(Array|Hash)\[(\w+)\]$/) {
        $type  = $TYPE_MAP->{$2} || Carp::croak("Can't find type constraint '$2'");
        $type .= $1 eq 'Array' ? '@' : '%';
        $cb    = $TYPE_GEN->{$2};
    }
    elsif ($type = $TYPE_MAP->{$spec}) {
        $cb = $TYPE_GEN->{$spec};
    }
    else {
        Carp::croak("Can't find type constraint '$spec'");
    }
    return $type, $cb;
}

sub add_type {
    my ($class, $name, $src_type, $cb) = @_;
    unless (defined $name && $src_type && ref $cb eq 'CODE') {
        Carp::croak("Usage: $class->add_type(\$name, \$src_type, \$cb)");
    }
    unless ($TYPE_MAP->{$src_type}) {
        Carp::croak("$src_type is not defined src type");
    }
    $TYPE_MAP->{$name} = $TYPE_MAP->{$src_type};
    $TYPE_GEN->{$name} = $cb;
}

sub _init_summary {
    my ($self, $command_struct) = @_;
    if ($command_struct) {
        for my $key (keys %$command_struct) {
            $self->{summary}{$key} = $command_struct->{$key}->{desc} || '';
        }
    }
    else {
        $self->{summary} = {};
    }
}

sub _extends_usage {
    my ($self, $command_option) = @_;
    for my $key (qw/args other_usage/) {
        $self->{$key} = $command_option->{$key} if exists $command_option->{$key};
    }
}

sub _check_requires {
    my ($self) = @_;
    for my $dest (sort keys %{$self->{requires}}) {
        unless (defined $self->{opt}{$dest}) {
            unless (defined ${$self->{parsed_opthash}{$self->{requires}{$dest}}}) {
                $self->{ret}   = 0;
                $self->{error} = "`--$dest` option must be specified";
                return 0;
            }
        }
    }
    return 1;
}

sub _option_names {
    my($self, $m) = @_;
    my @sorted = sort {
        my ($la, $lb) = (length($a), length($b));
        return $la <=> $lb if $la < 2 or $lb < 2;
        return 0;
    } ref $m eq 'ARRAY' ? @$m : $m;
    return @sorted;
}

sub _has_option {
    my($self, $option) = @_;
    return 1 if grep { $_ eq $option } map { $self->_option_names($_->[0]) } @{$self->{struct}};
    return 0;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Getopt::Compact::WithCmd - sub-command friendly, like Getopt::Compact

=head1 SYNOPSIS

inside foo.pl:

  use Getopt::Compact::WithCmd;
  
  my $go = Getopt::Compact::WithCmd->new(
     name          => 'foo',
     version       => '0.1',
     args          => 'FILE',
     global_struct => [
        [ [qw/f force/], 'force overwrite', '!', \my $force ],
     ],
     command_struct => {
        get => {
            options     => [
                [ [qw/d dir/], 'dest dir', '=s', undef, { default => '.' } ],
                [ [qw/o output/], 'output file name', '=s', undef, { required => 1 }],
            ],
            desc        => 'get file from url',
            args        => 'url',
            other_usage => 'blah blah blah',
        },
        remove => {
            ...
        }
     },
  );
  
  my $opts = $go->opts;
  my $cmd  = $go->command;
  
  if ($cmd eq 'get') {
      my $url = shift @ARGV;
  }

how will be like this:

  $ ./foo.pl -f get -o bar.html http://example.com/

usage, running the command './foo.pl -x' results in the following output:

  $ ./foo.pl -x
  Unknown option: x
  foo v0.1
  usage: foo.pl [options] COMMAND FILE
  
  options:
     -h, --help           This help message
     -f, --force   Bool   Force overwrite
  
  Implemented commands are:
     get   Get file from url
  
  See 'foo.pl help COMMAND' for more information on a specific command.

in addition, running the command './foo.pl get' results in the following output:

  $ ./foo.pl get
  `--output` option must be specified
  foo v0.1
  usage: foo.pl get [options] url
  
  options:
     -h, --help                                     This help message
     -d, --dir      Str            (default: '.')   Dest dir
     -o, --output   Str (required)                  Output file name
  
  blah blah blah

=head1 DESCRIPTION

Getopt::Compact::WithCmd is yet another Getopt::* module.
This module is respected L<Getopt::Compact>.
This module is you can define of git-like option.
In addition, usage can be set at the same time.

=head1 METHODS

=head2 new(%args)

Create an object.
The option most Getopt::Compact compatible.
But I<struct> is cannot use.

The new I<%args> are:

=over

=item C<< global_struct($arrayref) >>

This option is sets common options across commands.
This option value is Getopt::Compact compatible.
In addition, extended to other values can be set.

  use Getopt::Compact::WithCmd;
  my $go = Getopt::Compact::WithCmd->new(
      global_struct => [
          [ $name_spec_arrayref, $description_scalar, $argument_spec_scalar, \$destination_scalar, $opt_hashref ],
          [ ... ]
      ],
  );

And you can also write in hash style.

  use Getopt::Compact::WithCmd;
  my $go = Getopt::Compact::WithCmd->new(
      global_struct => {
          $name_scalar => {
              alias => $name_spec_arrayref,
              desc  => $description_scalar,
              type  => $argument_spec_scalar,
              dest  => \$destination_scalar,
              opts  => $opt_hashref,
          },
          $other_name_scalar => {
              ...
          },
      },
  );

I<$argument_spec_scalar> can be set value are L<< Getopt::Long >>'s option specifications.
And you can also specify the following readable style:

  Bool     # eq !
  Incr     # eq +
  Str      # eq =s
  Int      # eq =i
  Num      # eq =f
  ExNum    # eq =o

In addition, Array and Hash type are:

  Array[Str] # eq =s@
  Hash[Int]  # eq =i%
  ...

I<$opt_hasref> are:

  {
      default  => $value, # default value
      required => $bool,
  }

=item C<< command_struct($hashref) >>

This option is sets sub-command and options.

  use Getopt::Compact::WithCmd;
  my $go = Getopt::Compact::WithCmd->new(
      command_struct => {
          $command => {
              options        => $options,
              args           => $args,
              desc           => $description,
              other_usage    => $other_usage,
              command_struct => $command_struct,
          },
      },
  );

I<$options>

This value is compatible to C<global_struct>.

I<$args>

command args.

I<$description>

command description.

I<$other_usage>

other usage message.
be added to the end of the usage message.

I<$command_struct>

support nesting.

  use Getopt::Compact::WithCmd;
  my $go = Getopt::Compact::WithCmd->new(
      command_struct => {
          $command => {
              options        => $options,
              args           => $args,
              desc           => $description,
              other_usage    => $other_usage,
              command_struct => {
                  $sub_command => {
                      options => ...
                  },
              },
          },
      },
  );

  # will run cmd:
  $ ./foo.pl $command $sub_command ...

=back

=head2 add_type($new_type, $src_type, $code_ref);

This method is additional your own type.
You must be call before new() method.

  use JSON;
  use Data::Dumper;

  Getopt::Compact::WithCmd->add_type(JSON => Str => sub { decode_json(shift) });
  my $go = Getopt::Compact::WithCmd->new(
      global_struct => {
          from_json => {
              type => 'JSON',
          },
      },
  );
  my $data = $go->opts->{from_json};
  print Dumper $data;

  # will run cmd:
  $ ./add_type.pl --from_json '{"foo":"bar"}'
  $VAR1 = {
            'foo' => 'bar'
          };

=head2 new_from_array(\@myopts, %args);

C<< new_from_array >> can be used to parse options from an arbitrary array.

  $go = Getopt::Compact::WithCmd->new_from_array(\@myopts, ...);

=head2 new_from_string($option_string, %args);

C<< new_from_string >> can be used to parts options from an arbitrary string.

This method using L<< Text::ParseWords >> on internal.

  $go = Getopt::Compact::WithCmd->new_from_string('--foo bar baz', ...);

=head2 opts

Returns a hashref of options keyed by option name.
Return value is merged global options and command options.

=head2 command

Gets sub-command name.

  # inside foo.pl
  use Getopt::Compact::WithCmd;
  
  my $go = Getopt::Compact::WithCmd->new(
     command_struct => {
        bar => {},
     },
  );
  
  print "command: ", $go->command, "\n";
  
  # running the command
  $ ./foo.pl bar
  bar

=head2 commands

Get sub commands. Returned value is ARRAYREF.

  # inside foo.pl
  use Getopt::Compact::WithCmd;
  
  my $go = Getopt::Compact::WithCmd->new(
     command_struct => {
        bar => {
            command_struct => {
                baz => {},
            },
        },
     },
  );
  
  print join(", ", @{$go->commands}), "\n";
  
  # running the command
  $ ./foo.pl bar baz
  bar, baz

=head2 status

This is a true value if the command line was processed successfully. Otherwise it returns a false result.

  $go->status ? "success" : "fail";

=head2 is_success

Alias of C<status>

  $go->is_success # == $go->status

=head2 usage

Gets usage message.

  my $message = $go->usage;
  my $message = $go->usage($target_command_name); # must be implemented command.

=head2 show_usage

Display usage message and exit.

  $go->show_usage;
  $go->show_usage($target_command_name);

=head2 completion

Gets shell completion string.

  my $comp = $go->completion('bash');

NOTICE:
completion() supports only one nested level of "command_struct".
completion() supports only bash.

=head2 show_completion

Display completion string and exit.

  $go->show_completion('bash');

=head2 error

Return value is an error message or empty string.

  $go->error;

=head2 args

Return value is array reference to any remaining arguments.

  $go->args # like \@ARGV

=head2 pod2usage

B<Not implemented.>

=head1 AUTHOR

xaicron E<lt>xaicron {at} cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2010 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Getopt::Compact>

=cut
