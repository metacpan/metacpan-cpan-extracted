package Log::Any::App;

our $DATE = '2019-01-09'; # DATE
our $VERSION = '0.540'; # VERSION

# i need this to run on centos 5.x. otherwise all my other servers are debian
# 5.x and 6.x+ (perl 5.010).
use 5.008000;
use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use Log::Any::IfLOG;
use Log::Any::Adapter;

use vars qw($dbg_ctx);

our %PATTERN_STYLES = (
    plain             => '%m',
    plain_nl          => '%m%n',
    script_short      => '[%r] %m%n',
    script_long       => '[%d] %m%n',
    daemon            => '[pid %P] [%d] %m%n',
    syslog            => '[pid %p] %m',
);
for (keys %PATTERN_STYLES) {
    $PATTERN_STYLES{"cat_$_"} = "[cat %c]$PATTERN_STYLES{$_}";
    $PATTERN_STYLES{"loc_$_"} = "[loc %l]$PATTERN_STYLES{$_}";
}

my $init_args;
our $init_called;
my $is_daemon;

# poor man's version of 5.10's //
sub _ifdef {
    my $def = pop @_;
    for (@_) {
        return $_ if defined($_);
    }
    $def;
}

# j=as json (except the last default)
sub _ifdefj {
    require JSON::MaybeXS;

    my $def = pop @_;
    for (@_) {
        return JSON::MaybeXS::decode_json($_) if defined($_);
    }
    $def;
}

sub init {
    return if $init_called++;

    $is_daemon = undef;

    my ($args, $caller) = @_;
    $caller ||= caller();

    my $spec = _parse_opts($args, $caller);
    if ($spec->{log} && $spec->{init}) {
        _init_log4perl($spec);
        if ($ENV{LOG_ENV}) {
           my $log_main = Log::Any->get_logger(category => 'main');
           $log_main->tracef("Environment variables: %s", \%ENV);
       }
    }
    $spec;
}

sub _gen_appender_config {
    my ($ospec, $apd_name, $filter) = @_;

    my $name = $ospec->{name};
    my $class;
    my $params = {};
    if ($name =~ /^dir/i) {
        $class = "Log::Dispatch::Dir";
        $params->{dirname}   = $ospec->{path};
        $params->{filename_pattern} = $ospec->{filename_pattern};
        $params->{max_size}  = $ospec->{max_size} if $ospec->{max_size};
        $params->{max_files} = $ospec->{histories}+1 if $ospec->{histories};
        $params->{max_age}   = $ospec->{max_age} if $ospec->{max_age};
    } elsif ($name =~ /^file/i) {
        $class = "Log::Dispatch::FileWriteRotate";
        my ($dir, $prefix) = $ospec->{path} =~ m!(.+)/(.+)!;
        $dir ||= "."; $prefix ||= $ospec->{path};
        $params->{dir}         = $dir;
        $params->{prefix}      = $prefix;
        $params->{suffix}      = $ospec->{suffix};
        $params->{size}        = $ospec->{max_size};
        $params->{period}      = $ospec->{period};
        $params->{histories}   = $ospec->{histories};
        $params->{buffer_size} = $ospec->{buffer_size};
    } elsif ($name =~ /^screen/i) {
        $class = "Log::Log4perl::Appender::" .
            ($ospec->{color} ? "ScreenColoredLevels" : "Screen");
        $params->{stderr}  = $ospec->{stderr} ? 1:0;
        $params->{"color.WARN"} = "bold blue"; # blue on black is so unreadable
    } elsif ($name =~ /^syslog/i) {
        $class = "Log::Dispatch::Syslog";
        $params->{mode}     = 'append';
        $params->{ident}    = $ospec->{ident};
        $params->{facility} = $ospec->{facility};
    } elsif ($name =~ /^unixsock/i) {
        $class = "Log::Log4perl::Appender::Socket::UNIX";
        $params->{Socket} = $ospec->{path};
    } elsif ($name =~ /^array/i) {
        $class = "Log::Dispatch::ArrayWithLimits";
        $params->{array}     = $ospec->{array};
        $params->{max_elems} = $ospec->{max_elems};
    } else {
        die "BUG: Unknown appender type: $name";
    }

    join(
        "",
        "log4perl.appender.$apd_name = $class\n",
        (map { "log4perl.appender.$apd_name.$_ = $params->{$_}\n" }
             grep {defined $params->{$_}} keys %$params),
        "log4perl.appender.$apd_name.layout = PatternLayout\n",
        "log4perl.appender.$apd_name.layout.ConversionPattern = $ospec->{pattern}\n",
        ($filter ? "log4perl.appender.$apd_name.Filter = $filter\n" : ""),
    );
}

sub _lit {
    require Data::Dump;
    Data::Dump::dump(shift);
}

sub _gen_l4p_config {
    my ($spec) = @_;

    my @otypes = qw(file dir screen syslog unixsock array);

    # we use a custom perl code to implement filter_* specs.
    my @fccode;
    push @fccode, 'my %p = @_';
    push @fccode, 'my $str';
    for my $ospec (map { @{ $spec->{$_} } } @otypes) {
        if (defined $ospec->{filter_text}) {
            push @fccode, '$str = '._lit($ospec->{filter_text});
            push @fccode, 'return 0 if $p{name} eq '._lit($ospec->{name}).
                ' && index($_, $str) == -1';
        }
        if (defined $ospec->{filter_no_text}) {
            push @fccode, '$str = '._lit($ospec->{filter_no_text});
            push @fccode, 'return 0 if $p{name} eq '._lit($ospec->{name}).
                ' && index($_, $str) > -1';
        }
        if (defined $ospec->{filter_citext}) {
            push @fccode, '$str = '._lit($ospec->{filter_citext});
            push @fccode, 'return 0 if $p{name} eq '._lit($ospec->{name}).
                ' && !/\Q$str/io';
        }
        if (defined $ospec->{filter_no_citext}) {
            push @fccode, '$str = '._lit($ospec->{filter_no_citext});
            push @fccode, 'return 0 if $p{name} eq '._lit($ospec->{name}).
                ' && /\Q$str/io';
        }
        if (defined $ospec->{filter_re}) {
            push @fccode, '$str = '._lit($ospec->{filter_re});
            push @fccode, 'return 0 if $p{name} eq '._lit($ospec->{name}).
                ' && $_ !~ ' . (ref($ospec->{filter_re}) eq 'Regexp' ? '$str' : 'qr/$str/o');
        }
        if (defined $ospec->{filter_no_re}) {
            push @fccode, '$str = '._lit($ospec->{filter_no_re});
            push @fccode, 'return 0 if $p{name} eq '._lit($ospec->{name}).
                ' && $_ =~ ' . (ref($ospec->{filter_re}) eq 'Regexp' ? '$str' : 'qr/$str/o');
        }
    }
    push @fccode, "1";
    my $fccode = join "; ", @fccode;

    my $filters_str = join(
        "",
        "log4perl.filter.FilterCustom = sub { $fccode }\n",
        "\n",
        "log4perl.filter.FilterOFF0 = Log::Log4perl::Filter::LevelRange\n",
        "log4perl.filter.FilterOFF0.LevelMin = TRACE\n",
        "log4perl.filter.FilterOFF0.LevelMax = FATAL\n",
        "log4perl.filter.FilterOFF0.AcceptOnMatch = false\n",
        "\n",
        "log4perl.filter.FilterOFF = Log::Log4perl::Filter::Boolean\n",
        "log4perl.filter.FilterOFF.logic = FilterOFF0 && FilterCustom\n",
        map {join(
            "",
            "log4perl.filter.Filter${_}0 = Log::Log4perl::Filter::LevelRange\n",
            "log4perl.filter.Filter${_}0.LevelMin = $_\n",
            "log4perl.filter.Filter${_}0.LevelMax = FATAL\n",
            "log4perl.filter.Filter${_}0.AcceptOnMatch = true\n",
            "\n",
            "log4perl.filter.Filter$_ = Log::Log4perl::Filter::Boolean\n",
            "log4perl.filter.Filter$_.logic = Filter${_}0 && FilterCustom\n",
            "\n",
        )} qw(FATAL ERROR WARN INFO DEBUG), # TRACE
    );

    my %levels; # key = output name; value = { cat => level, ... }
    my %cats;   # list of categories
    my %ospecs; # key = oname; this is just a shortcut to get ospec

    # 1. list all levels for each category and output
    for my $ospec (map { @{ $spec->{$_} } } @otypes) {
        my $oname = $ospec->{name};
        $ospecs{$oname} = $ospec;
        $levels{$oname} = {};
        my %seen_cats;
        if ($ospec->{category_level}) {
            while (my ($cat0, $level) = each %{ $ospec->{category_level} }) {
                my @cat = _extract_category($ospec, $cat0);
                for my $cat (@cat) {
                    next if $seen_cats{$cat}++;
                    $cats{$cat}++;
                    $levels{$oname}{$cat} = $level;
                }
            }
        }
        if ($spec->{category_level}) {
            while (my ($cat0, $level) = each %{ $spec->{category_level} }) {
                my @cat = _extract_category($ospec, $cat0);
                for my $cat (@cat) {
                    next if $seen_cats{$cat}++;
                    $cats{$cat}++;
                    $levels{$oname}{$cat} = $level;
                }
            }
        }
        my @cat = _extract_category($ospec);
        for my $cat (@cat) {
            next if $seen_cats{$cat}++;
            $cats{$cat}++;
            $levels{$oname}{$cat} = $ospec->{level};
        }
    }
    #print Dumper \%levels; exit;

    my $find_olevel = sub {
        my ($oname, $cat) = @_;
        my $olevel = $levels{$oname}{''};
        my @c = split /\./, $cat;
        for (my $i=0; $i<@c; $i++) {
            my $c = join(".", @c[0..$i]);
            if ($levels{$oname}{$c}) {
                $olevel = $levels{$oname}{$c};
            }
        }
        $olevel;
    };

    # 2. determine level for each category (which is the minimum level of all
    # appenders for that category)
    my %cat_configs; # key = cat, value = [catlevel, apdname, ...]
    my $add_str = '';
    my $apd_str = '';
    for my $cat0 (sort {$a cmp $b} keys %cats) {
        $add_str .= "log4perl.additivity.$cat0 = 0\n" unless $cat0 eq '';
        my @cats = ($cat0);
        # since we don't use additivity, we need to add supercategories ourselves
        while ($cat0 =~ s/\.[^.]+$//) { push @cats, $cat0 }
        for my $cat (@cats) {
            my $cat_level;
            for my $oname (keys %levels) {
                my $olevel = $find_olevel->($oname, $cat);
                next unless $olevel;
                $cat_level = _ifdef($cat_level, $olevel);
                $cat_level = _min_level($cat_level, $olevel);
            }
            $cat_configs{$cat} = [uc($cat_level)];
            #next if $cat_level eq 'off';
        }
    }
    #print Dumper \%cat_configs; exit;

    # 3. add appenders for each category
    my %generated_appenders; # key = apdname, just a memory hash
    for my $cat (keys %cat_configs) {
        my $cat_level = $cat_configs{$cat}[0];
        for my $oname (keys %levels) {
            my $ospec = $ospecs{$oname};
            my $olevel = $find_olevel->($oname, $cat);
            #print "D:oname=$oname, cat=$cat, olevel=$olevel, cat_level=$cat_level\n";
            my $apd_name;
            my $filter;
            if ($olevel ne $cat_level &&
                    _min_level($olevel, $cat_level) eq $cat_level) {
                # we need to filter the appender, since the category level is
                # lower than the output level
                $apd_name = $oname . "_" . uc($olevel);
                $filter = "Filter".uc($olevel);
            } else {
                $apd_name = $oname;
                $filter = "FilterCustom";
            }
            unless ($generated_appenders{$apd_name}++) {
                $apd_str .= _gen_appender_config($ospec, $apd_name, $filter).
                    "\n";
            }
            push @{ $cat_configs{$cat} }, $apd_name;
        }
    }
    #print Dumper \%cat_configs; exit;

    # 4. write out log4perl category line
    my $cat_str = '';
    for my $cat (sort {$a cmp $b} keys %cat_configs) {
        my $l = $cat eq '' ? '' : ".$cat";
        $cat_str .= "log4perl.logger$l = ".join(", ", @{ $cat_configs{$cat} })."\n";
    }

    join(
        "",
        "# filters\n", $filters_str,
        "# categories\n", $cat_str, $add_str, "\n",
        "# appenders\n", $apd_str,
    );
}

sub _init_log4perl {
    require Log::Log4perl;

    my ($spec) = @_;

    # create intermediate directories for dir
    for (@{ $spec->{dir} }) {
        my $dir = _dirname($_->{path});
        make_path($dir) if length($dir) && !(-d $dir);
    }

    # create intermediate directories for file
    for (@{ $spec->{file} }) {
        my $dir = _dirname($_->{path});
        make_path($dir) if length($dir) && !(-d $dir);
    }

    my $config_str = _gen_l4p_config($spec);
    if ($spec->{dump}) {
        require Data::Dump;
        print "Log::Any::App configuration:\n",
            Data::Dump::dump($spec);
        print "Log4perl configuration: <<EOC\n", $config_str, "EOC\n";
    }

    Log::Log4perl->init(\$config_str);
    Log::Any::Adapter->set('Log4perl');
}

sub _basename {
    my $path = shift;
    my ($vol, $dir, $file) = File::Spec->splitpath($path);
    $file;
}

sub _dirname {
    my $path = shift;
    my ($vol, $dir, $file) = File::Spec->splitpath($path);
    $dir;
}

# we separate args and opts, because we need to export logger early
# (BEGIN), but configure logger in INIT (to be able to detect
# existence of other modules).

sub _parse_args {
    my ($args, $caller) = @_;
    $args = _ifdef($args, []); # if we don't import(), we never get args

    my $i = 0;
    while ($i < @$args) {
        my $arg = $args->[$i];
        do { $i+=2; next } if $arg =~ /^-(\w+)$/;
        if ($arg eq '$log') {
            _export_logger($caller);
        } else {
            die "Unknown arg '$arg', valid arg is '\$log' or -OPTS";
        }
        $i++;
    }
}

sub _parse_opts {
    require File::HomeDir;

    my ($args, $caller) = @_;
    $args = _ifdef($args, []); # if we don't import(), we never get args
    _debug("parse_opts: args = [".join(", ", @$args)."]");

    my $i = 0;
    my %opts;
    while ($i < @$args) {
        my $arg = $args->[$i];
        do { $i++; next } unless $arg =~ /^-(\w+)$/;
        my $opt = $1;
        die "Missing argument for option $opt" unless $i++ < @$args-1;
        $arg = $args->[$i];
        $opts{$opt} = $arg;
        $i++;
    }

    my $spec = {};

    $spec->{log} = _ifdef($ENV{LOG}, 1);
    if (defined $opts{log}) {
        $spec->{log} = $opts{log};
        delete $opts{log};
    }
    # exit as early as possible if we are not doing any logging
    goto END_PARSE_OPTS unless $spec->{log};

    $spec->{name} = _basename($0);
    if (defined $opts{name}) {
        $spec->{name} = $opts{name};
        delete $opts{name};
    }

    $spec->{level_flag_paths} = [File::HomeDir->my_home, "/etc"];
    if (defined $opts{level_flag_paths}) {
        $spec->{level_flag_paths} = $opts{level_flag_paths};
        delete $opts{level_flag_paths};
    }

    $spec->{level} = _set_level("", "", $spec);
    if (!$spec->{level} && defined($opts{level})) {
        $spec->{level} = _check_level($opts{level}, "-level");
        _debug("Set general level to $spec->{level} (from -level)");
    } elsif (!$spec->{level}) {
        $spec->{level} = "warn";
        _debug("Set general level to $spec->{level} (default)");
    }
    delete $opts{level};

    $spec->{category_alias} = _ifdefj($ENV{LOG_CATEGORY_ALIAS}, {});
    if (defined $opts{category_alias}) {
        die "category_alias must be a hashref"
            unless ref($opts{category_alias}) eq 'HASH';
        $spec->{category_alias} = $opts{category_alias};
        delete $opts{category_alias};
    }

    if (defined $opts{category_level}) {
        die "category_level must be a hashref"
            unless ref($opts{category_level}) eq 'HASH';
        $spec->{category_level} = {};
        for (keys %{ $opts{category_level} }) {
            $spec->{category_level}{$_} =
                _check_level($opts{category_level}{$_}, "-category_level{$_}");
        }
        delete $opts{category_level};
    }

    $spec->{init} = 1;
    if (defined $opts{init}) {
        $spec->{init} = $opts{init};
        delete $opts{init};
    }

    $spec->{daemon} = 0;
    if (defined $opts{daemon}) {
        $spec->{daemon} = $opts{daemon};
        _debug("setting is_daemon=$opts{daemon} (from daemon option)");
        $is_daemon = $opts{daemon};
        delete $opts{daemon};
    }

    $spec->{dump} = $ENV{LOGANYAPP_DEBUG};
    if (defined $opts{dump}) {
        $spec->{dump} = 1;
        delete $opts{dump};
    }

    $spec->{filter_text} = $ENV{LOG_FILTER_TEXT};
    if (defined $opts{filter_text}) {
        $spec->{filter_text} = $opts{filter_text};
        delete $opts{filter_text};
    }
    $spec->{filter_no_text} = $ENV{LOG_FILTER_NO_TEXT};
    if (defined $opts{filter_no_text}) {
        $spec->{filter_no_text} = $opts{filter_no_text};
        delete $opts{filter_no_text};
    }
    $spec->{filter_citext} = $ENV{LOG_FILTER_CITEXT};
    if (defined $opts{filter_citext}) {
        $spec->{filter_citext} = $opts{filter_citext};
        delete $opts{filter_citext};
    }
    $spec->{filter_no_citext} = $ENV{LOG_FILTER_NO_CITEXT};
    if (defined $opts{filter_no_citext}) {
        $spec->{filter_no_citext} = $opts{filter_no_citext};
        delete $opts{filter_no_citext};
    }
    $spec->{filter_re} = $ENV{LOG_FILTER_RE};
    if (defined $opts{filter_re}) {
        $spec->{filter_re} = $opts{filter_re};
        delete $opts{filter_re};
    }
    $spec->{filter_no_re} = $ENV{LOG_FILTER_NO_RE};
    if (defined $opts{filter_no_re}) {
        $spec->{filter_no_re} = $opts{filter_no_re};
        delete $opts{filter_no_re};
    }

    $spec->{file} = [];
    _parse_opt_file($spec, _ifdef($opts{file}, ($0 ne '-e' ? 1:0)));
    delete $opts{file};

    $spec->{dir} = [];
    _parse_opt_dir($spec, _ifdef($opts{dir}, 0));
    delete $opts{dir};

    $spec->{screen} = [];
    _parse_opt_screen($spec, _ifdef($opts{screen}, !_is_daemon()));
    delete $opts{screen};

    $spec->{syslog} = [];
    _parse_opt_syslog($spec, _ifdef($opts{syslog}, _is_daemon()));
    delete $opts{syslog};

    $spec->{unixsock} = [];
    _parse_opt_unixsock($spec, _ifdef($opts{unixsock}, 0));
    delete $opts{unixsock};

    $spec->{array} = [];
    _parse_opt_array($spec, _ifdef($opts{array}, 0));
    delete $opts{array};

    if (keys %opts) {
        die "Unknown option(s) ".join(", ", keys %opts)." Known opts are: ".
            "log, name, level, category_level, category_alias, dump, init, ".
                "filter_{,no_}{text,citext,re}, file, dir, screen, syslog, ".
                    "unixsock, array";
    }

  END_PARSE_OPTS:
    #use Data::Dump; dd $spec;
    $spec;
}

sub _is_daemon {
    if (defined $is_daemon) { return $is_daemon }
    if (defined $main::IS_DAEMON) {
        $is_daemon = $main::IS_DAEMON;
        _debug("Setting is_daemon=$main::IS_DAEMON (from \$main::IS_DAEMON)");
        return $main::IS_DAEMON;
    }

    for (
        "App/Daemon.pm",
        "Daemon/Easy.pm",
        "Daemon/Daemonize.pm",
        "Daemon/Generic.pm",
        "Daemonise.pm",
        "Daemon/Simple.pm",
        "HTTP/Daemon.pm",
        "IO/Socket/INET/Daemon.pm",
        #"Mojo/Server/Daemon.pm", # simply loading Mojo::UserAgent will load this too
        "MooseX/Daemonize.pm",
        "Net/Daemon.pm",
        "Net/Server.pm",
        "Proc/Daemon.pm",
        "Proc/PID/File.pm",
        "Win32/Daemon/Simple.pm") {
        if ($INC{$_}) {
            _debug("setting is_daemon=1 (from existence of module $_)");
            $is_daemon = 1;
            return 1;
        }
    }
    _debug("setting is_daemon=0 (no indication that we are a daemon)");
    $is_daemon = 0;
    0;
}

sub _parse_opt_OUTPUT {
    my (%args) = @_;
    my $kind = $args{kind};
    my $default_sub = $args{default_sub};
    my $postprocess = $args{postprocess};
    my $spec = $args{spec};
    my $arg = $args{arg};

    return unless $arg;

    if (!ref($arg) || ref($arg) eq 'HASH') {
        my $name = uc($kind).(@{ $spec->{$kind} }+0);
        local $dbg_ctx = $name;
        push @{ $spec->{$kind} }, $default_sub->($spec);
        $spec->{$kind}[-1]{name} = $name;
        if (!ref($arg)) {
            # leave every output parameter as is
        } else {
            for my $k (keys %$arg) {
                for ($spec->{$kind}[-1]) {
                    exists($_->{$k}) or die "Invalid $kind argument: $k, please".
                        " only specify one of: " . join(", ", sort keys %$_);
                    $_->{$k} = $k eq 'level' ?
                        _check_level($arg->{$k}, "-$kind") : $arg->{$k};
                    _debug("Set level of $kind to $_->{$k} (spec)")
                        if $k eq 'level';
                }
            }
        }
        $spec->{$kind}[-1]{main_spec} = $spec;
        _set_pattern($spec->{$kind}[-1], $kind);
        $postprocess->(spec => $spec, ospec => $spec->{$kind}[-1])
            if $postprocess;
    } elsif (ref($arg) eq 'ARRAY') {
        for (@$arg) {
            _parse_opt_OUTPUT(%args, arg => $_);
        }
    } else {
        die "Invalid argument for -$kind, ".
            "must be a boolean or hashref or arrayref";
    }
}

sub _set_pattern_style {
    my ($x) = @_;
    ($ENV{LOG_SHOW_LOCATION} ? 'loc_':
         $ENV{LOG_SHOW_CATEGORY} ? 'cat_':'') . $x;
}

sub _default_file {
    require File::HomeDir;

    my ($spec) = @_;
    my $level = _set_level("file", "file", $spec);
    if (!$level) {
        $level = $spec->{level};
        _debug("Set level of file to $level (general level)");
    }
    return {
        level => $level,
        category_level => _ifdefj($ENV{FILE_LOG_CATEGORY_LEVEL},
                                  $ENV{LOG_CATEGORY_LEVEL},
                                  $spec->{category_level}),
        path => $> ? File::Spec->catfile(File::HomeDir->my_home, "$spec->{name}.log") :
            "/var/log/$spec->{name}.log", # XXX and on Windows?
        max_size => undef,
        histories => undef,
        period => undef,
        buffer_size => undef,
        category => '',
        pattern_style => _set_pattern_style('daemon'),
        pattern => undef,

        filter_text      => _ifdef($ENV{FILE_LOG_FILTER_TEXT}, $spec->{filter_text}),
        filter_no_text   => _ifdef($ENV{FILE_LOG_FILTER_NO_TEXT}, $spec->{filter_no_text}),
        filter_citext    => _ifdef($ENV{FILE_LOG_FILTER_CITEXT}, $spec->{filter_citext}),
        filter_no_citext => _ifdef($ENV{FILE_LOG_FILTER_NO_CITEXT}, $spec->{filter_no_citext}),
        filter_re        => _ifdef($ENV{FILE_LOG_FILTER_RE}, $spec->{filter_re}),
        filter_no_re     => _ifdef($ENV{FILE_LOG_FILTER_NO_RE}, $spec->{filter_no_re}),
    };
}

sub _parse_opt_file {
    my ($spec, $arg) = @_;

    if (!ref($arg) && $arg && $arg !~ /^(1|yes|true)$/i) {
        $arg = {path => $arg};
    }

    _parse_opt_OUTPUT(
        kind => 'file', default_sub => \&_default_file,
        spec => $spec, arg => $arg,
        postprocess => sub {
            my (%args) = @_;
            my $spec  = $args{spec};
            my $ospec = $args{ospec};
            if ($ospec->{path} =~ m!/$!) {
                my $p = $ospec->{path};
                $p .= "$spec->{name}.log";
                _debug("File path ends with /, assumed to be dir, ".
                           "final path becomes $p");
                $ospec->{path} = $p;
            }
        },
    );
}

sub _default_dir {
    require File::HomeDir;

    my ($spec) = @_;
    my $level = _set_level("dir", "dir", $spec);
    if (!$level) {
        $level = $spec->{level};
        _debug("Set level of dir to $level (general level)");
    }
    return {
        level => $level,
        category_level => _ifdefj($ENV{DIR_LOG_CATEGORY_LEVEL},
                                   $ENV{LOG_CATEGORY_LEVEL},
                                   $spec->{category_level}),
        path => $> ? File::Spec->catfile(File::HomeDir->my_home, "log", $spec->{name}) :
            "/var/log/$spec->{name}", # XXX and on Windows?
        max_size => undef,
        max_age => undef,
        histories => undef,
        category => '',
        pattern_style => _set_pattern_style('plain'),
        pattern => undef,
        filename_pattern => undef,

        filter_text      => _ifdef($ENV{DIR_LOG_FILTER_TEXT}, $spec->{filter_text}),
        filter_no_text   => _ifdef($ENV{DIR_LOG_FILTER_NO_TEXT}, $spec->{filter_no_text}),
        filter_citext    => _ifdef($ENV{DIR_LOG_FILTER_CITEXT}, $spec->{filter_citext}),
        filter_no_citext => _ifdef($ENV{DIR_LOG_FILTER_NO_CITEXT}, $spec->{filter_no_citext}),
        filter_re        => _ifdef($ENV{DIR_LOG_FILTER_RE}, $spec->{filter_re}),
        filter_no_re     => _ifdef($ENV{DIR_LOG_FILTER_NO_RE}, $spec->{filter_no_re}),
    };
}

sub _parse_opt_dir {
    my ($spec, $arg) = @_;

    if (!ref($arg) && $arg && $arg !~ /^(1|yes|true)$/i) {
        $arg = {path => $arg};
    }

    _parse_opt_OUTPUT(
        kind => 'dir', default_sub => \&_default_dir,
        spec => $spec, arg => $arg,
    );
}

sub _default_screen {
    my ($spec) = @_;
    my $level = _set_level("screen", "screen", $spec);
    if (!$level) {
        $level = $spec->{level};
        _debug("Set level of screen to $level (general level)");
    }
    return {
        color => _ifdef($ENV{COLOR}, (-t STDOUT)),
        stderr => 1,
        level => $level,
        category_level => _ifdefj($ENV{SCREEN_LOG_CATEGORY_LEVEL},
                                   $ENV{LOG_CATEGORY_LEVEL},
                                   $spec->{category_level}),
        category => '',
        pattern_style => _set_pattern_style(
            $ENV{LOG_ELAPSED_TIME_IN_SCREEN} ? 'script_short' : 'plain_nl'),
        pattern => undef,

        filter_text      => _ifdef($ENV{SCREEN_LOG_FILTER_TEXT}, $spec->{filter_text}),
        filter_no_text   => _ifdef($ENV{SCREEN_FILTER_NO_TEXT}, $spec->{filter_no_text}),
        filter_citext    => _ifdef($ENV{SCREEN_FILTER_CITEXT}, $spec->{filter_citext}),
        filter_no_citext => _ifdef($ENV{SCREEN_FILTER_NO_CITEXT}, $spec->{filter_no_citext}),
        filter_re        => _ifdef($ENV{SCREEN_FILTER_RE}, $spec->{filter_re}),
        filter_no_re     => _ifdef($ENV{SCREEN_FILTER_NO_RE}, $spec->{filter_no_re}),
    };
}

sub _parse_opt_screen {
    my ($spec, $arg) = @_;
    _parse_opt_OUTPUT(
        kind => 'screen', default_sub => \&_default_screen,
        spec => $spec, arg => $arg,
    );
}

sub _default_syslog {
    my ($spec) = @_;
    my $level = _set_level("syslog", "syslog", $spec);
    if (!$level) {
        $level = $spec->{level};
        _debug("Set level of syslog to $level (general level)");
    }
    return {
        level => $level,
        category_level => _ifdefj($ENV{SYSLOG_LOG_CATEGORY_LEVEL},
                                   $ENV{LOG_CATEGORY_LEVEL},
                                   $spec->{category_level}),
        ident => $spec->{name},
        facility => 'daemon',
        pattern_style => _set_pattern_style('syslog'),
        pattern => undef,
        category => '',

        filter_text      => _ifdef($ENV{SYSLOG_LOG_FILTER_TEXT}, $spec->{filter_text}),
        filter_no_text   => _ifdef($ENV{SYSLOG_FILTER_NO_TEXT}, $spec->{filter_no_text}),
        filter_citext    => _ifdef($ENV{SYSLOG_FILTER_CITEXT}, $spec->{filter_citext}),
        filter_no_citext => _ifdef($ENV{SYSLOG_FILTER_NO_CITEXT}, $spec->{filter_no_citext}),
        filter_re        => _ifdef($ENV{SYSLOG_FILTER_RE}, $spec->{filter_re}),
        filter_no_re     => _ifdef($ENV{SYSLOG_FILTER_NO_RE}, $spec->{filter_no_re}),
    };
}

sub _parse_opt_syslog {
    my ($spec, $arg) = @_;
    _parse_opt_OUTPUT(
        kind => 'syslog', default_sub => \&_default_syslog,
        spec => $spec, arg => $arg,
    );
}

sub _default_unixsock {
    require File::HomeDir;

    my ($spec) = @_;
    my $level = _set_level("unixsock", "unixsock", $spec);
    if (!$level) {
        $level = $spec->{level};
        _debug("Set level of unixsock to $level (general level)");
    }
    return {
        level => $level,
        category_level => _ifdefj($ENV{UNIXSOCK_LOG_CATEGORY_LEVEL},
                                  $ENV{LOG_CATEGORY_LEVEL},
                                  $spec->{category_level}),
        path => $> ? File::Spec->catfile(File::HomeDir->my_home, "$spec->{name}-log.sock") :
            "/var/run/$spec->{name}-log.sock", # XXX and on Windows?
        category => '',
        pattern_style => _set_pattern_style('daemon'),
        pattern => undef,

        filter_text      => _ifdef($ENV{UNIXSOCK_LOG_FILTER_TEXT}, $spec->{filter_text}),
        filter_no_text   => _ifdef($ENV{UNIXSOCK_LOG_FILTER_NO_TEXT}, $spec->{filter_no_text}),
        filter_citext    => _ifdef($ENV{UNIXSOCK_LOG_FILTER_CITEXT}, $spec->{filter_citext}),
        filter_no_citext => _ifdef($ENV{UNIXSOCK_LOG_FILTER_NO_CITEXT}, $spec->{filter_no_citext}),
        filter_re        => _ifdef($ENV{UNIXSOCK_LOG_FILTER_RE}, $spec->{filter_re}),
        filter_no_re     => _ifdef($ENV{UNIXSOCK_LOG_FILTER_NO_RE}, $spec->{filter_no_re}),
    };
}

sub _parse_opt_unixsock {
    my ($spec, $arg) = @_;

    if (!ref($arg) && $arg && $arg !~ /^(1|yes|true)$/i) {
        $arg = {path => $arg};
    }

    _parse_opt_OUTPUT(
        kind => 'unixsock', default_sub => \&_default_unixsock,
        spec => $spec, arg => $arg,
        postprocess => sub {
            my (%args) = @_;
            my $spec  = $args{spec};
            my $ospec = $args{ospec};
            if ($ospec->{path} =~ m!/$!) {
                my $p = $ospec->{path};
                $p .= "$spec->{name}-log.sock";
                _debug("Unix socket path ends with /, assumed to be dir, ".
                           "final path becomes $p");
                $ospec->{path} = $p;
            }

            # currently Log::Log4perl::Appender::Socket::UNIX *connects to an
            # existing and listening* Unix socket and prints log to it. we are
            # *not* creating a listening unix socket where clients can connect
            # and see logs. to do that, we'll need a separate thread/process
            # that listens to unix socket and stores (some) log entries and
            # display it to users when they connect and request them.
            #
            #if ($ospec->{create} && !(-e $ospec->{path})) {
            #    _debug("Creating Unix socket $ospec->{path} ...");
            #    require IO::Socket::UNIX::Util;
            #    IO::Socket::UNIX::Util::create_unix_socket(
            #        $ospec->{path});
            #}
        },
    );
}

sub _default_array {
    my ($spec) = @_;
    my $level = _set_level("array", "array", $spec);
    if (!$level) {
        $level = $spec->{level};
        _debug("Set level of array to $level (general level)");
    }
    return {
        level => $level,
        category_level => _ifdefj($ENV{ARRAY_LOG_CATEGORY_LEVEL},
                                  $ENV{LOG_CATEGORY_LEVEL},
                                  $spec->{category_level}),
        array => [],
        max_elems => undef,
        category => '',
        pattern_style => _set_pattern_style('script_long'),
        pattern => undef,

        filter_text      => _ifdef($ENV{ARRAY_LOG_FILTER_TEXT}, $spec->{filter_text}),
        filter_no_text   => _ifdef($ENV{ARRAY_LOG_FILTER_NO_TEXT}, $spec->{filter_no_text}),
        filter_citext    => _ifdef($ENV{ARRAY_LOG_FILTER_CITEXT}, $spec->{filter_citext}),
        filter_no_citext => _ifdef($ENV{ARRAY_LOG_FILTER_NO_CITEXT}, $spec->{filter_no_citext}),
        filter_re        => _ifdef($ENV{ARRAY_LOG_FILTER_RE}, $spec->{filter_re}),
        filter_no_re     => _ifdef($ENV{ARRAY_LOG_FILTER_NO_RE}, $spec->{filter_no_re}),
    };
}

sub _parse_opt_array {
    my ($spec, $arg) = @_;

    _parse_opt_OUTPUT(
        kind => 'array', default_sub => \&_default_array,
        spec => $spec, arg => $arg,
    );
}

sub _set_pattern {
    my ($s, $name) = @_;
    _debug("Setting $name pattern ...");
    unless (defined($s->{pattern})) {
        die "BUG: neither pattern nor pattern_style is defined ($name)"
            unless defined($s->{pattern_style});
        die "Unknown pattern style for $name `$s->{pattern_style}`, ".
            "use one of: ".join(", ", keys %PATTERN_STYLES)
            unless defined($PATTERN_STYLES{ $s->{pattern_style} });
        $s->{pattern} = $PATTERN_STYLES{ $s->{pattern_style} };
        _debug("Set $name pattern to `$s->{pattern}` ".
                   "(from style `$s->{pattern_style}`)");
    }
}

sub _extract_category {
    my ($ospec, $c) = @_;
    my $c0 = _ifdef($c, $ospec->{category});
    my @res;
    if (ref($c0) eq 'ARRAY') { @res = @$c0 } else { @res = ($c0) }
    # replace alias with real value
    for (my $i=0; $i<@res; $i++) {
        my $c1 = $res[$i];
        my $a = $ospec->{main_spec}{category_alias}{$c1};
        next unless defined($a);
        if (ref($a) eq 'ARRAY') {
            splice @res, $i, 1, @$a;
            $i += (@$a-1);
        } else {
            $res[$i] = $a;
        }
    }
    for (@res) {
        s/::/./g;
        # $_ = lc; # XXX do we need this?
    }
    @res;
}

sub _cat2apd {
    my $cat = shift;
    $cat =~ s/[^A-Za-z0-9_]+/_/g;
    $cat;
}

sub _check_level {
    my ($level, $from) = @_;
    $level =~ /^(off|fatal|error|warn|info|debug|trace)$/i
        or die "Unknown level (from $from): $level";
    lc($1);
}

sub _set_level {
    my ($prefix, $which, $spec) = @_;
    #use Data::Dump; dd $spec;
    my $p_ = $prefix ? "${prefix}_" : "";
    my $P_ = $prefix ? uc("${prefix}_") : "";
    my $F_ = $prefix ? ucfirst("${prefix}_") : "";
    my $pd = $prefix ? "${prefix}-" : "";
    my $pr = $prefix ? qr/$prefix(_|-)/ : qr//;
    my ($level, $from);

    my @label2level =([trace=>"trace"], [debug=>"debug"],
                      [verbose=>"info"], [quiet=>"error"]);

    _debug("Setting ", ($which ? "level of $which" : "general level"), " ...");
  SET:
    {
        if ($INC{"App/Options.pm"}) {
            my $key;
            for (qw/log_level loglevel/) {
                $key = $p_ . $_;
                _debug("Checking \$App::options{$key}: ", _ifdef($App::options{$key}, "(undef)"));
                if ($App::options{$key}) {
                    $level = _check_level($App::options{$key}, "\$App::options{$key}");
                    $from = "\$App::options{$key}";
                    last SET;
                }
            }
            for (@label2level) {
                $key = $p_ . $_->[0];
                _debug("Checking \$App::options{$key}: ", _ifdef($App::options{$key}, "(undef)"));
                if ($App::options{$key}) {
                    $level = $_->[1];
                    $from = "\$App::options{$key}";
                    last SET;
                }
            }
        }

        my $i = 0;
        _debug("Checking \@ARGV ...");
        while ($i < @ARGV) {
            my $arg = $ARGV[$i];
            $from = "cmdline arg $arg";
            if ($arg =~ /^--${pr}log[_-]?level=(.+)/) {
                _debug("\$ARGV[$i] looks like an option to specify level: $arg");
                $level = _check_level($1, "ARGV $arg");
                last SET;
            }
            if ($arg =~ /^--${pr}log[_-]?level$/ and $i < @ARGV-1) {
                _debug("\$ARGV[$i] and \$ARGV[${\($i+1)}] looks like an option to specify level: $arg ", $ARGV[$i+1]);
                $level = _check_level($ARGV[$i+1], "ARGV $arg ".$ARGV[$i+1]);
                last SET;
            }
            for (@label2level) {
                if ($arg =~ /^--${pr}$_->[0](=(1|yes|true))?$/i) {
                    _debug("\$ARGV[$i] looks like an option to specify level: $arg");
                    $level = $_->[1];
                    last SET;
                }
            }
            $i++;
        }

        for (qw/LOG_LEVEL LOGLEVEL/) {
            my $key = $P_ . $_;
            _debug("Checking environment variable $key: ", _ifdef($ENV{$key}, "(undef)"));
            if ($ENV{$key}) {
                $level = _check_level($ENV{$key}, "ENV $key");
                $from = "\$ENV{$key}";
                last SET;
            }
        }
        for (@label2level) {
            my $key = $P_ . uc($_->[0]);
            _debug("Checking environment variable $key: ", _ifdef($ENV{$key}, "(undef)"));
            if ($ENV{$key}) {
                $level = $_->[1];
                $from = "\$ENV{$key}";
                last SET;
            }
        }

        for my $dir (@{$spec->{level_flag_paths}}) {
            for (@label2level) {
                my $filename = "$dir/$spec->{name}." . $P_ . "log_level";
                my $exists = -f $filename;
                my $content;
                if ($exists) {
                    open my($f), $filename;
                    $content = <$f>;
                    chomp($content) if defined($content);
                    close $f;
                }
                _debug("Checking level flag file content $filename: ",
                       (defined($content) ? $content : "(undef)"));
                if (defined $content) {
                    $level = _check_level($content,
                                          "level flag file $filename");
                    $from = $filename;
                    last SET;
                }

                $filename = "$dir/$spec->{name}." . $P_ . uc($_->[0]);
                $exists = -e $filename;
                _debug("Checking level flag file $filename: ",
                       ($exists ? "EXISTS" : 0));
                if ($exists) {
                    $level = $_->[1];
                    $from = $filename;
                    last SET;
                }
            }
        }

        no strict 'refs';
        for ("${F_}Log_Level", "${P_}LOG_LEVEL", "${p_}log_level",
             "${F_}LogLevel",  "${P_}LOGLEVEL",  "${p_}loglevel") {
            my $varname = "main::$_";
            _debug("Checking variable \$$varname: ", _ifdef($$varname, "(undef)"));
            if ($$varname) {
                $from = "\$$varname";
                $level = _check_level($$varname, "\$$varname");
                last SET;
            }
        }
        for (@label2level) {
            for my $varname (
                "main::$F_" . ucfirst($_->[0]),
                "main::$P_" . uc($_->[0])) {
                _debug("Checking variable \$$varname: ", _ifdef($$varname, "(undef)"));
                if ($$varname) {
                    $from = "\$$varname";
                    $level = $_->[1];
                    last SET;
                }
            }
        }
    }

    _debug("Set ", ($which ? "level of $which" : "general level"), " to $level (from $from)") if $level;
    return $level;
}

# return the lower level (e.g. _min_level("debug", "INFO") -> INFO
sub _min_level {
    my ($l1, $l2) = @_;
    my %vals = (OFF=>99,
                FATAL=>6, ERROR=>5, WARN=>4, INFO=>3, DEBUG=>2, TRACE=>1);
    $vals{uc($l1)} > $vals{uc($l2)} ? $l2 : $l1;
}

sub _export_logger {
    my ($caller) = @_;
    my $log_for_caller = Log::Any->get_logger(category => $caller);
    my $varname = "$caller\::log";
    no strict 'refs';
    *$varname = \$log_for_caller;
}

sub _debug {
    return unless $ENV{LOGANYAPP_DEBUG};
    print $dbg_ctx, ": " if $dbg_ctx;
    print @_, "\n";
}

sub import {
    my ($self, @args) = @_;
    my $caller = caller();
    _parse_args(\@args, $caller);
    $init_args = \@args;
}

{
    no warnings;
    # if we are loaded at run-time, it's too late to run INIT blocks, so user
    # must call init() manually. but sometimes this is what the user wants. so
    # shut up perl warning.
    INIT {
        my $caller = caller();
        init($init_args, $caller);
    }
}

1;
# ABSTRACT: An easy way to use Log::Any in applications

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::App - An easy way to use Log::Any in applications

=head1 VERSION

This document describes version 0.540 of Log::Any::App (from Perl distribution Log-Any-App), released on 2019-01-09.

=head1 SYNOPSIS

Most of the time you only need to do this:

 # in your script.pl
 use Log::Any::App '$log';
 $log->warn("blah ...");
 if ($log->is_debug) { ... }

 # or, in command line
 % perl -MLog::Any::App -MModuleThatUsesLogAny -e'...'

Here's the default logging that Log::Any::App sets up for you:

 Condition                        screen  file               syslog        dir
 --------------------------------+-------+------------------+-------------+---
 -e (one-liners)                  y       -                  -             -
 Scripts running as normal user   y       ~/NAME.log         -             -
 Scripts running as root          y       /var/log/NAME.log  -             -
 Daemons                          -       y                  y             -

You can customize level from outside the script, using environment variables or
command-line options (won't interfere with command-line processing modules like
Getopt::Long etc):

 % DEBUG=1 script.pl
 % LOG_LEVEL=trace script.pl
 % script.pl --verbose

And to customize other stuffs:

 use Log::Any::App '$log',
     -syslog => 1, # turn on syslog logging explicitly
     -screen => 0, # turn off screen logging explicitly
     -file   => {path=>'/foo/bar', max_size=>'10M', histories=>10};
                # customize file logging

For more customization like categories, per-category level, per-output level,
multiple outputs, string patterns, etc see L</USING AND EXAMPLES> and init().

=head1 DESCRIPTION

IMPORTANT: Please read L</"ROAD TO 1.0"> on some incompatibilities in the near
future, before 1.0 is released.

Log::Any::App is a convenient combo for L<Log::Any> and L<Log::Log4perl>
(although alternative backends beside Log4perl might be considered in the
future). To use Log::Any::App you need to be sold on the idea of Log::Any first,
so please do a read up on that first.

The goal of Log::Any::App is to provide developers an easy and concise way to
add logging to their I<*applications*>. That is, instead of modules; modules
remain using Log::Any to produce logs. Applications can upgrade to full Log4perl
later when necessary, although in my experience, they usually don't.

With Log::Any::App, you can replace this code in your application:

 use Log::Any '$log';
 use Log::Any::Adapter;
 use Log::Log4perl;
 my $log4perl_config = '
   some
   long
   multiline
   config...';
 Log::Log4perl->init(\$log4perl_config);
 Log::Any::Adapter->set('Log4perl');

with just this:

 use Log::Any::App '$log'; # plus some other options when necessary

Most of the time you don't need to configure anything as Log::Any::App will
construct the most appropriate default Log4perl configuration for your
application.

=head1 USING AND EXAMPLES

To use Log::Any::App, just do:

 use Log::Any::App '$log';

or from the command line:

 % perl -MLog::Any::App -MModuleThatUsesLogAny -e ...

This will send logs to screen as well as file (unless -e scripts, which only log
to screen). Default log file is ~/$SCRIPT_NAME.log, or /var/log/$SCRIPT_NAME.log
if script is running as root. Default level is 'warn'.

The 'use Log::Any::App' statement can be issued before or after the modules that
use Log::Any, it doesn't matter. Logging will be initialized in the INIT phase
by Log::Any::App.

You are not required to import '$log', and don't need to if you do not produce
logs in your application (only in the modules).

=head2 Changing logging level

Since one of the most commonly tweaked logging setting is level (for example:
increasing level when debugging problems), Log::Any::App provides several
mechanisms to change log level, either from the script or from outside the
script, for your convenience. Below are the mechanisms, ordered from highest
priority:

=over 4

=item * import argument (inside the script)

=item * command line arguments (outside the script)

=item * environment variables (outside the script)

=item * level flag files (outside the script)

=item * variables in 'main' package (inside the script)

=back

These mechanisms are explained in more details in the documentation for the
B<init()> function. But below are some examples.

To change level from inside the script:

 use Log::Any::App '$log', -level => 'debug';

This is useful if you want a fixed level that cannot be overridden by other
mechanisms (since setting level using import argument has the highest priority).
But oftentimes what you want is changing level without modifying the script
itself. Thereby, just write:

 use Log::Any::App '$log';

and then you can use environment variables to change level:

 TRACE=1 script.pl;         # setting level to trace
 DEBUG=1 script.pl;         # setting level to debug
 VERBOSE=1 script.pl;       # setting level to info
 QUIET=1 script.pl;         # setting level to error
 LOG_LEVEL=trace script.pl; # setting a specific log level

or command-line options:

 script.pl --trace
 script.pl --debug
 script.pl --verbose
 script.pl --quiet
 script.pl --log_level=debug;   # '--log-level debug' will also do

Regarding command-line options: Log::Any::App won't consume the command-line
options from @ARGV and thus won't interfere with command-line processing modules
like L<Getopt::Long> or L<App::Options>. If you use a command-line processing
module and plan to use command-line options to set level, you might want to
define these level options, or your command-line processing module will complain
about unknown options.

=head2 Changing default level

The default log level is 'warn'. To change the default level, you can use 'main'
package variables (since they have the lowest priority):

 use Log::Any::App '$log';
 BEGIN { our $Log_Level = 'info' } # be more verbose by default

Then you will still be able to use level flag files or environment variables or
command-line options to override this setting.

=head2 Changing per-output level

Logging level can also be specified on a per-output level. For example, if you
want your script to be chatty on the screen but still logs to file at the
default 'warn' level:

 SCREEN_VERBOSE=1 script.pl
 SCREEN_DEBUG=1 script.pl
 SCREEN_TRACE=1 script.pl
 SCREEN_LOG_LEVEL=info script.pl

 script.pl --screen_verbose
 script.pl --screen-debug
 script.pl --screen-trace=1
 script.pl --screen-log-level=info

Similarly, to set only file level, use FILE_VERBOSE, FILE_LOG_LEVEL,
--file-trace, and so on.

=head2 Setting default per-output level

As with setting default level, you can also set default level on a per-output
basis:

 use Log::Any::App '$log';
 BEGIN {
     our $Screen_Log_Level = 'off';
     our $File_Quiet = 1; # setting file level to 'error'
     # and so on
 }

If a per-output level is not specified, it will default to the general log level.

=head2 Enabling/disabling output

To disable a certain output, you can do this:

 use Log::Any::App '$log', -file => 0;

or:

 use Log::Any::App '$log', -screen => {level=>'off'};

and this won't allow the output to be re-enabled from outside the script. However
if you do this:

 use Log::Any::App;
 BEGIN { our $Screen_Log_Level = 'off' }

then by default screen logging is turned off but you will be able to override
the screen log level using level flag files or environment variables or
command-line options (SCREEN_DEBUG, --screen-verbose, and so on).

=head2 Changing log level of cron scripts

Environment variables and command-line options allow changing log level without
modifying the script. But for scripts specified in crontab, they still require
changing crontab entries, e.g.:

 # turn on debugging
 */5 * * * * DEBUG=1 foo

 # be silent
 */5 * * * * bar --quiet

Another mechanism, level flag file, is useful in this case. By doing:

 $ echo debug > ~/foo.log_level
 # touch /etc/bar.QUIET

you can also change log levels without modifying your crontab.

=head2 Changing log file name/location

By default Log::Any::App will log to file to ~/$NAME.log (or /var/log/$NAME.log
if script is running as root), where $NAME is taken from the basename of $0. But
this can be changed using:

 use Log::Any::App '$log', -name => 'myprog';

Or, using custom path:

 use Log::Any::App '$log', -file => '/path/to/file';

=head2 Changing other output parameters

Each output argument can accept a hashref to specify various options. For
example:

 use Log::Any::App '$log',
     -screen => {color=>0},   # never use color
     -file   => {path=>'/var/log/foo',
                 max_size=>'10M',
                 histories=>10,
                },

For all the available options of each output, see the init() function.

=head2 Logging to syslog

Logging to syslog is enabled by default if your script looks like or declare
that it is a daemon, e.g.:

 use Net::Daemon; # this indicate your program is a daemon
 use Log::Any::App; # syslog logging will be turned on by default

 use Log::Any::App -daemon => 1; # script declares that it is a daemon

 # idem
 package main;
 our $IS_DAEMON = 1;

But if you are certain you don't want syslog logging:

 use Log::Any::App -syslog => 0;

=head2 Logging to directory

This is done using L<Log::Dispatch::Dir> where each log message is logged to a
different file in a specified directory. By default logging to dir is not turned
on, to turn it on:

 use Log::Any::App '$log', -dir => 1;

For all the available options of directory output, see the init() function.

=head2 Multiple outputs

Each output argument can accept an arrayref to specify more than one output. For
example below is a code to log to three files:

 use Log::Any::App '$log',
     -file => [1, # default, to ~/$NAME.log or /var/log/$NAME.log
               "/var/log/log1",
               {path=>"/var/log/debug_foo", category=>'Foo', level=>'debug'}];

=head2 Changing level of certain module(s)

Suppose you want to shut up logs from modules Foo, Bar::Baz, and Qux (and their
submodules as well, e.g. Foo::Alpha, Bar::Baz::Beta::Gamma) because they are too
noisy:

 use Log::Any::App '$log',
     -category_level => { Foo => 'off', 'Bar::Baz' => 'off', Qux => 'off' };

or (same thing):

 use Log::Any::App '$log',
     -category_alias => { -noisy => [qw/Foo Bar::Baz Qux/] },
     -category_level => { -noisy => 'off' };

You can even specify this on a per-output basis. Suppose you only want to shut
up the noisy modules on the screen, but not on the file:

 use Log::Any::App '$log',
    -category_alias => { -noisy => [qw/Foo Bar::Baz Qux/] },
    -screen => { category_level => { -noisy => 'off' } };

Or perhaps, you want to shut up the noisy modules everywhere, except on the
screen:

 use Log::Any::App '$log',
     -category_alias => { -noisy => [qw/Foo Bar::Baz Qux/] },
     -category_level => { -noisy => 'off' },
     -syslog => 1,                        # uses general -category_level
     -file   => "/var/log/foo",           # uses general -category_level
     -screen => { category_level => {} }; # overrides general -category_level

You can also do this from the outside the script using environment variable,
which is more flexible. Encode data structure using JSON:

 % LOG_SHOW_CATEGORY=1 \
   LOG_CATEGORY_ALIAS='{"-noisy":["Foo","Bar::Baz","Quz"]}' \
   LOG_CATEGORY_LEVEL='{"-noisy":"off"}' script.pl ...

=head2 Only displaying log from certain module(s)

Use a combination of LOG_LEVEL and LOG_CATEGORY_LEVEL. For example:

 % LOG_LEVEL=off LOG_CATEGORY_LEVEL='{"Foo.Bar":"trace", "Baz":"info"}' \
   script.pl ...

=head2 Displaying category name

 % LOG_SHOW_CATEGORY=1 script.pl ...

Now instead of:

 [25] Starting baz ritual ...

now log messages will be prefixed with category:

 [cat Foo.Bar][25] Starting baz ritual ...

=head2 Displaying location name

 % LOG_SHOW_LOCATION=1 script.pl ...

Now log messages will be prefixed with location (function/file/line number)
information:

 [loc Foo::Bar lib/Foo/Bar.pm (12)][25] Starting baz ritual ...

=head2 Preventing logging level to be changed from outside the script

Sometimes, for security/audit reasons, you don't want to allow script caller to
change logging level. As explained previously, you can use the 'level' import
argument (the highest priority of level-setting):

 use Log::Any::App '$log', -level => 'debug'; # always use debug level

TODO: Allow something like 'debug+' to allow other mechanisms to *increase* the
level but not decrease it. Or 'debug-' to allow other mechanisms to decrease
level but not increase it. And finally 'debug,trace' to specify allowable levels
(is this necessary?)

=head2 Debugging

To see the Log4perl configuration that is generated by Log::Any::App and how it
came to be, set environment LOGANYAPP_DEBUG to true.

=head1 PATTERN STYLES

Log::Any::App provides some styles for Log4perl patterns. You can specify
C<pattern_style> instead of directly specifying C<pattern>. example:

 use Log::Any::App -screen => {pattern_style=>"script_long"};

 Name           Description                        Example output
 ----           -----------                        --------------
 plain          The message, the whole message,    Message
                and nothing but the message.
                Used by dir logging.

                Equivalent to pattern: '%m'

 plain_nl       Message plus newline. The default  Message
                for screen without
                LOG_ELAPSED_TIME_IN_SCREEN.

                Equivalent to pattern: '%m%n'

 script_short   For scripts that run for a short   [234] Message
                time (a few seconds). Shows just
                the number of milliseconds. This
                is the default for screen under
                LOG_ELAPSED_TIME_IN_SCREEN.

                Equivalent to pattern:
                '[%r] %m%n'

 script_long    Scripts that will run for a        [2010-04-22 18:01:02] Message
                while (more than a few seconds).
                Shows date/time.

                Equivalent to pattern:
                '[%d] %m%n'

 daemon         For typical daemons. Shows PID     [pid 1234] [2010-04-22 18:01:02] Message
                and date/time. This is the
                default for file logging.

                Equivalent to pattern:
                '[pid %P] [%d] %m%n'

 syslog         Style suitable for syslog          [pid 1234] Message
                logging.

                Equivalent to pattern:
                '[pid %p] %m'

For each of the above there are also C<cat_XXX> (e.g. C<cat_script_long>) which
are the same as XXX but with C<[cat %c]> in front of the pattern. It is used
mainly to show categories and then filter by categories. You can turn picking
default pattern style with category using environment variable
LOG_SHOW_CATEGORY.

And for each of the above there are also C<loc_XXX> (e.g. C<loc_syslog>) which
are the same as XXX but with C<[loc %l]> in front of the pattern. It is used to
show calling location (file, function/method, and line number). You can turn
picking default pattern style with location prefix using environment variable
LOG_SHOW_LOCATION.

If you have a favorite pattern style, please do share them.

=head1 BUGS/TODOS

Need to provide appropriate defaults for Windows/other OS.

=head1 ROAD TO 1.0

Here are some planned changes/development before 1.0 is reached. There might be
some incompatibilities, please read this section carefully.

=over 4

=item * Everything is configurable via environment/command-line/option file

As I I<love> specifying log options from environment, I will make I<every>
init() options configurable from outside the script
(environment/command-line/control file). Of course, init() arguments still take
precedence for authors that do not want some/all options to be overridden from
outside.

=item * Reorganization of command-line/environment names

Aside from the handy and short TRACE (--trace), DEBUG, VERBOSE, QUIET, all the
other environment names will be put under LOG_ prefix. This means FILE_LOG_LEVEL
will be changed to LOG_FILE_LEVEL, and so on. SCREEN_VERBOSE will be changed to
VERBOSE_SCREEN.

This is meant to reduce "pollution" of the environment variables namespace.

Log option file (option file for short, previously "flag file") will be searched
in <PROG>.log_options. Its content is in JSON and will become init() arguments.
For example:

 {"file": 1, "screen":{"level":"trace"}}

or more akin to init() (both will be supported):

 ["-file": 1, "-screen":{"level":"trace"}]

=item * Possible reorganization of package variable names

To be more strict and reduce confusion, case variation might not be searched.

=item * Pluggable backend

This is actually the main motivator to reach 1.0 and all these changes. Backends
will be put in Log::Any::App::Backend::Log4perl, and so on.

=item * Pluggable output

Probably split to Log::Any::App::Output::file, and so on. Each output needs
its backend support.

=item * App::Options support will probably be dropped

I no longer use App::Options these days, and I don't know of any Log::Any::App
user who does.

=item * Probably some hooks to allow for more flexibility.

For example, if user wants to parse or detect levels/log file paths/etc from
some custom logic.

=back

=head1 FUNCTIONS

None is exported.

=head2 init(\@args)

This is the actual function that implements the setup and configuration of
logging. You normally need not call this function explicitly (but see below), it
will be called once in an INIT block. In fact, when you do:

 use Log::Any::App 'a', 'b', 'c';

it is actually passed as:

 init(['a', 'b', 'c']);

You will need to call init() manually if you require Log::Any::App at runtime,
in which case it is too late to run INIT block. If you want to run Log::Any::App
in runtime phase, do this:

 require Log::Any::App;
 Log::Any::App::init(['a', 'b', 'c']);

Arguments to init can be one or more of:

=over 4

=item -log => BOOL

Whether to do log at all. Default is from LOG environment variable, or 1. This
option is only to allow users to disable Log::Any::App (thus speeding up startup
by avoiding loading Log4perl, etc) by passing LOG=1 environment when running
programs. However, if you explicitly set this option to 1, Log::Any::App cannot
be disabled this way.

=item -init => BOOL

Whether to call Log::Log4perl->init() after setting up the Log4perl
configuration. Default is true. You can set this to false, and you can
initialize Log4perl yourself (but then there's not much point in using this
module, right?)

=item -name => STRING

Change the program name. Default is taken from $0.

=item -level_flag_paths => ARRAY OF STRING

Edit level flag file locations. The default is [$homedir, "/etc"].

=item -daemon => BOOL

Declare that script is a daemon. Default is no. Aside from this, to declare that
your script is a daemon you can also set $main::IS_DAEMON to true.

=item -category_alias => {ALIAS=>CATEGORY, ...}

Create category aliases so the ALIAS can be used in place of real categories in
each output's category specification. For example, instead of doing this:

 init(
     -file   => [category=>[qw/Foo Bar Baz/], ...],
     -screen => [category=>[qw/Foo Bar Baz/]],
 );

you can do this instead:

 init(
     -category_alias => {-fbb => [qw/Foo Bar Baz/]},
     -file   => [category=>'-fbb', ...],
     -screen => [category=>'-fbb', ...],
 );

You can also specify this from the environment variable LOG_CATEGORY_ALIAS using
JSON encoding, e.g.

 LOG_CATEGORY_ALIAS='{"-fbb":["Foo","Bar","Baz"]}'

=item -category_level => {CATEGORY=>LEVEL, ...}

Specify per-category level. Categories not mentioned on this will use the
general level (-level). This can be used to increase or decrease logging on
certain categories/modules.

You can also specify this from the environment variable LOG_CATEGORY_LEVEL using
JSON encoding, e.g.

 LOG_CATEGORY_LEVEL='{"-fbb":"off"}'

=item -level => 'trace'|'debug'|'info'|'warn'|'error'|'fatal'|'off'

Specify log level for all outputs. Each output can override this value. The
default log level is determined as follow:

B<Search in command-line options>. If L<App::Options> is present, these keys are
checked in B<%App::options>: B<log_level>, B<trace> (if true then level is
C<trace>), B<debug> (if true then level is C<debug>), B<verbose> (if true then
level is C<info>), B<quiet> (if true then level is C<error>).

Otherwise, it will try to scrape @ARGV for the presence of B<--log-level>,
B<--trace>, B<--debug>, B<--verbose>, or B<--quiet> (this usually works because
Log::Any::App does this in the INIT phase, before you call L<Getopt::Long>'s
GetOptions() or the like).

B<Search in environment variables>. Otherwise, it will look for environment
variables: B<LOG_LEVEL>, B<QUIET>. B<VERBOSE>, B<DEBUG>, B<TRACE>.

B<Search in level flag files>. Otherwise, it will look for existence of files
with one of these names C<$NAME.QUIET>, C<$NAME.VERBOSE>, C<$NAME.TRACE>,
C<$NAME.DEBUG>, or content of C<$NAME.log_level> in ~ or /etc.

B<Search in main package variables>. Otherwise, it will try to search for
package variables in the C<main> namespace with names like C<$Log_Level> or
C<$LOG_LEVEL> or C<$log_level>, C<$Quiet> or C<$QUIET> or C<$quiet>, C<$Verbose>
or C<$VERBOSE> or C<$verbose>, C<$Trace> or C<$TRACE> or C<$trace>, C<$Debug> or
C<$DEBUG> or C<$debug>.

If everything fails, it defaults to 'warn'.

=item -filter_text => STR

Only show log lines matching STR. Default from C<LOG_FILTER_TEXT> environment.

=item -filter_no_text => STR

Only show log lines not matching STR. Default from C<LOG_FILTER_NO_TEXT>
environment.

=item -filter_citext => STR

Only show log lines matching STR (case insensitive). Default from
C<LOG_FILTER_CITEXT> environment.

=item -filter_no_citext => STR

Only show log lines not matching STR (case insensitive). Default from
C<LOG_FILTER_NO_CITEXT> environment.

=item -filter_re => RE

Only show log lines matching regex pattern RE. Default from C<LOG_FILTER_RE>
environment.

=item -filter_no_re => RE

Only show log lines not matching regex pattern RE. Default from
C<LOG_FILTER_NO_RE> environment.

=item -file => 0 | 1|yes|true | PATH | {opts} | [{opts}, ...]

Specify output to one or more files, using L<Log::Dispatch::FileWriteRotate>.

If the argument is a false boolean value, file logging will be turned off. If
argument is a true value that matches /^(1|yes|true)$/i, file logging will be
turned on with default path, etc. If the argument is another scalar value then
it is assumed to be a path. If the argument is a hashref, then the keys of the
hashref must be one of: C<level>, C<path>, C<max_size> (maximum size before
rotating, in bytes, 0 means unlimited or never rotate), C<histories> (number of
old files to keep, excluding the current file), C<suffix> (will be passed to
Log::Dispatch::FileWriteRotate's constructor), C<period> (will be passed to
Log::Dispatch::FileWriteRotate's constructor), C<buffer_size> (will be passed to
Log::Dispatch::FileWriteRotate's constructor), C<category> (a string of ref to
array of strings), C<category_level> (a hashref, similar to -category_level),
C<pattern_style> (see L<"PATTERN STYLES">), C<pattern> (Log4perl pattern),
C<filter_text>, C<filter_no_text>, C<filter_citext>, C<filter_no_citext>,
C<filter_re>, C<filter_no_re>.

If the argument is an arrayref, it is assumed to be specifying multiple files,
with each element of the array as a hashref.

How Log::Any::App determines defaults for file logging:

If program is a one-liner script specified using "perl -e", the default is no
file logging. Otherwise file logging is turned on.

If the program runs as root, the default path is C</var/log/$NAME.log>, where
$NAME is taken from B<$0> (or C<-name>). Otherwise the default path is
~/$NAME.log. Intermediate directories will be made with L<File::Path>.

If specified C<path> ends with a slash (e.g. "/my/log/"), it is assumed to be a
directory and the final file path is directory appended with $NAME.log.

Default rotating behaviour is no rotate (max_size = 0).

Default level for file is the same as the global level set by B<-level>. But
App::options, command line, environment, level flag file, and package variables
in main are also searched first (for B<FILE_LOG_LEVEL>, B<FILE_TRACE>,
B<FILE_DEBUG>, B<FILE_VERBOSE>, B<FILE_QUIET>, and the similars).

You can also specify category level from environment FILE_LOG_CATEGORY_LEVEL.

=item -dir => 0 | 1|yes|true | PATH | {opts} | [{opts}, ...]

Log messages using L<Log::Dispatch::Dir>. Each message is logged into separate
files in the directory. Useful for dumping content (e.g. HTML, network dumps, or
temporary results).

If the argument is a false boolean value, dir logging will be turned off. If
argument is a true value that matches /^(1|yes|true)$/i, dir logging will be
turned on with defaults path, etc. If the argument is another scalar value then
it is assumed to be a directory path. If the argument is a hashref, then the
keys of the hashref must be one of: C<level>, C<path>, C<max_size> (maximum
total size of files before deleting older files, in bytes, 0 means unlimited),
C<max_age> (maximum age of files to keep, in seconds, undef means unlimited).
C<histories> (number of old files to keep, excluding the current file),
C<category>, C<category_level> (a hashref, similar to -category_level),
C<pattern_style> (see L<"PATTERN STYLES">), C<pattern> (Log4perl pattern),
C<filename_pattern> (pattern of file name), C<filter_text>, C<filter_no_text>,
C<filter_citext>, C<filter_no_citext>, C<filter_re>, C<filter_no_re>.

If the argument is an arrayref, it is assumed to be specifying multiple
directories, with each element of the array as a hashref.

How Log::Any::App determines defaults for dir logging:

Directory logging is by default turned off. You have to explicitly turn it on.

If the program runs as root, the default path is C</var/log/$NAME/>, where $NAME
is taken from B<$0>. Otherwise the default path is ~/log/$NAME/. Intermediate
directories will be created with File::Path. Program name can be changed using
C<-name>.

Default rotating parameters are: histories=1000, max_size=0, max_age=undef.

Default level for dir logging is the same as the global level set by B<-level>.
But App::options, command line, environment, level flag file, and package
variables in main are also searched first (for B<DIR_LOG_LEVEL>, B<DIR_TRACE>,
B<DIR_DEBUG>, B<DIR_VERBOSE>, B<DIR_QUIET>, and the similars).

You can also specify category level from environment DIR_LOG_CATEGORY_LEVEL.

=item -screen => 0 | 1|yes|true | {opts}

Log messages using L<Log::Log4perl::Appender::ScreenColoredLevels>.

If the argument is a false boolean value, screen logging will be turned off. If
argument is a true value that matches /^(1|yes|true)$/i, screen logging will be
turned on with default settings. If the argument is a hashref, then the keys of
the hashref must be one of: C<color> (default is true, set to 0 to turn off
color), C<stderr> (default is true, set to 0 to log to stdout instead),
C<level>, C<category>, C<category_level> (a hashref, similar to
-category_level), C<pattern_style> (see L<"PATTERN STYLE">), C<pattern>
(Log4perl string pattern), C<filter_text>, C<filter_no_text>, C<filter_citext>,
C<filter_no_citext>, C<filter_re>, C<filter_no_re>.

How Log::Any::App determines defaults for screen logging:

Screen logging is turned on by default.

Default level for screen logging is the same as the global level set by
B<-level>. But App::options, command line, environment, level flag file, and
package variables in main are also searched first (for B<SCREEN_LOG_LEVEL>,
B<SCREEN_TRACE>, B<SCREEN_DEBUG>, B<SCREEN_VERBOSE>, B<SCREEN_QUIET>, and the
similars).

Color can also be turned on/off using environment variable COLOR (if B<color>
argument is not set).

You can also specify category level from environment SCREEN_LOG_CATEGORY_LEVEL.

=item -syslog => 0 | 1|yes|true | {opts}

Log messages using L<Log::Dispatch::Syslog>.

If the argument is a false boolean value, syslog logging will be turned off. If
argument is a true value that matches /^(1|yes|true)$/i, syslog logging will be
turned on with default level, ident, etc. If the argument is a hashref, then the
keys of the hashref must be one of: C<level>, C<ident>, C<facility>,
C<category>, C<category_level> (a hashref, similar to -category_level),
C<pattern_style> (see L<"PATTERN STYLES">), C<pattern> (Log4perl pattern),
C<filter_text>, C<filter_no_text>, C<filter_citext>, C<filter_no_citext>,
C<filter_re>, C<filter_no_re>.

How Log::Any::App determines defaults for syslog logging:

If a program is a daemon (determined by detecting modules like L<Net::Server> or
L<Proc::PID::File>, or by checking if -daemon or $main::IS_DAEMON is true) then
syslog logging is turned on by default and facility is set to C<daemon>,
otherwise the default is off.

Ident is program's name by default ($0, or C<-name>).

Default level for syslog logging is the same as the global level set by
B<-level>. But App::options, command line, environment, level flag file, and
package variables in main are also searched first (for B<SYSLOG_LOG_LEVEL>,
B<SYSLOG_TRACE>, B<SYSLOG_DEBUG>, B<SYSLOG_VERBOSE>, B<SYSLOG_QUIET>, and the
similars).

You can also specify category level from environment SYSLOG_LOG_CATEGORY_LEVEL.

=item -unixsock => 0 | 1|yes|true | PATH | {opts} | [{opts}, ...]

Specify output to one or more B<existing, listening, datagram> Unix domain
sockets, using L<Log::Log4perl::Appender::Socket::UNIX>.

The listening end might be a different process, or the same process using a
different thread of nonblocking I/O. It usually makes little sense to make the
same program the listening end. If you want, for example, to let a client
connects to your program to see logs being produced, you might want to setup an
in-memory output (C<-array>) and create another thread or non-blocking I/O to
listen to client requests and show them the content of the array when requested.

If the argument is a false boolean value, Unix domain socket logging will be
turned off. If argument is a true value that matches /^(1|yes|true)$/i, Unix
domain socket logging will be turned on with default path, etc. If the argument
is another scalar value then it is assumed to be a path. If the argument is a
hashref, then the keys of the hashref must be one of: C<level>, C<path>,
C<filter_text>, C<filter_no_text>, C<filter_citext>, C<filter_no_citext>,
C<filter_re>, C<filter_no_re>.

If the argument is an arrayref, it is assumed to be specifying multiple sockets,
with each element of the array as a hashref.

How Log::Any::App determines defaults for Unix domain socket logging:

By default Unix domain socket logging is off.

If the program runs as root, the default path is C</var/run/$NAME-log.sock>,
where $NAME is taken from B<$0> (or C<-name>). Otherwise the default path is
~/$NAME-log.sock.

If specified C<path> ends with a slash (e.g. "/my/log/"), it is assumed to be a
directory and the final socket path is directory appended with $NAME-log.sock.

Default level is the same as the global level set by B<-level>. But
App::options, command line, environment, level flag file, and package variables
in main are also searched first (for B<UNIXSOCK_LOG_LEVEL>, B<UNIXSOCK_TRACE>,
B<UNIXSOCK_DEBUG>, B<UNIXSOCK_VERBOSE>, B<UNIXSOCK_QUIET>, and the similars).

You can also specify category level from environment
UNIXSOCK_LOG_CATEGORY_LEVEL.

=item -array => 0 | {opts} | [{opts}, ...]

Specify output to one or more Perl arrays. Logging will be done using
L<Log::Dispatch::ArrayWithLimits>. Note that the syntax is:

 -array => {array=>$ary}

and not just:

 -array => $ary

because that will be interpreted as multiple array outputs:

 -array => [{output1}, ...]

If the argument is a false boolean value, array logging will be turned off.
Otherwise argument must be a hashref or an arrayref (to specify multiple
outputs). If the argument is a hashref, then the keys of the hashref must be one
of: C<level>, C<array> (defaults to new anonymous array []), C<filter_text>,
C<filter_no_text>, C<filter_citext>, C<filter_no_citext>, C<filter_re>,
C<filter_no_re>. If the argument is an arrayref, it is assumed to be specifying
multiple sockets, with each element of the array as a hashref.

How Log::Any::App determines defaults for array logging:

By default array logging is off.

Default level is the same as the global level set by B<-level>. But
App::options, command line, environment, level flag file, and package variables
in main are also searched first (for B<ARRAY_LOG_LEVEL>, B<ARRAY_TRACE>,
B<ARRAY_DEBUG>, B<ARRAY_VERBOSE>, B<ARRAY_QUIET>, and the similars).

You can also specify category level from environment ARRAY_LOG_CATEGORY_LEVEL.

=item -dump => BOOL

If set to true then Log::Any::App will dump the generated Log4perl config.
Useful for debugging the logging.

=back

=head1 FAQ

=head2 Why?

I initially wrote Log::Any::App because I'm sick of having to parse command-line
options to set log level like --verbose, --log-level=debug for every script.
Also, before using Log::Any I previously used Log4perl directly and modules
which produce logs using Log4perl cannot be directly use'd in one-liners without
Log4perl complaining about uninitialized configuration or some such. Thus, I
like Log::Any's default null adapter and want to settle using Log::Any for any
kind of logging. Log::Any::App makes it easy to output Log::Any logs in your
scripts and even one-liners.

=head2 What's the benefit of using Log::Any::App?

You get all the benefits of Log::Any, as what Log::Any::App does is just wrap
Log::Any and Log4perl with some nice defaults. It provides you with an easy way
to consume Log::Any logs and customize level/some other options via various
ways.

=head2 And what's the benefit of using Log::Any?

This is better described in the Log::Any documentation itself, but in short:
Log::Any frees your module users to use whatever logging framework they want. It
increases the reusability of your modules.

=head2 Do I need Log::Any::App if I am writing modules?

No, if you write modules just use Log::Any.

=head2 Why use Log4perl?

Log::Any::App uses the Log4perl adapter to display the logs because it is
mature, flexible, featureful. The other alternative adapter is Log::Dispatch,
but you can use Log::Dispatch::* output modules in Log4perl and (currently) not
vice versa.

Other adapters might be considered in the future, for now I'm fairly satisfied
with Log4perl. It does have a slightly heavy startup cost for my taste, but it
is still bearable.

=head2 Are you coupling adapter with Log::Any (thus defeating Log::Any's purpose)?

No, producing logs are still done with Log::Any as usual and not tied to
Log4perl in any way. Your modules, as explained above, only 'use Log::Any' and
do not depend on Log::Any::App at all.

Should portions of your application code get refactored into modules later, you
don't need to change the logging part. And if your application becomes more
complex and Log::Any::App doesn't suffice your custom logging needs anymore, you
can just replace 'use Log::Any::App' line with something more adequate.

=head2 How do I create extra logger objects?

The usual way as with Log::Any:

 my $other_log = Log::Any->get_logger(category => $category);

=head2 My needs are not met by the simple configuration system of Log::Any::App!

You can use the Log4perl adapter directly and write your own Log4perl
configuration (or even other adapters). Log::Any::App is meant for quick and
simple logging output needs anyway (but do tell me if your logging output needs
are reasonably simple and should be supported by Log::Any::App).

=head2 What is array output for?

Logging to a Perl array might be useful for testing/debugging, or (one use-case
I can think of) for letting users of your program connect to your program
directly to request viewing the logs being produced (although logging to other
outputs doesn't preclude this ability). For example, here is a program that uses
a separate thread to listen to Unix socket for requests to view the (last 100)
logs. Requires perl built with threads enabled.

 use threads;
 use threads::shared;
 BEGIN { our @buf :shared }
 use IO::Socket::UNIX::Util qw(create_unix_stream_socket);
 use Log::Any::App '$log', -array => [{array => 'main::buf', max_elems=>100}];

 my $sock = create_unix_stream_socket('/tmp/app-logview.sock');

 # thread to listen to unix socket and receive log viewing instruction
 my $thr = threads->create(
    sub {
        local $| = 1;
        while (my $cli = $sock->accept) {
            while (1) {
                print $cli "> ";
                my $line = <$cli>;
                last unless $line;
                if ($line =~ /\Ar(ead)?\b/i) {
                    print $cli @buf;
                } else {
                    print $cli "Unknown command\n";
                }
            }
        }
    });

 # main thread, application which produces logs
 $|++;
 while (1) {
     $log->warnf("Log (%d) ...", ++$i);
     sleep 1;
 }

After you run this program, you can connect to it, e.g. from another terminal:

 % socat UNIX-CONNECT:/tmp/app-logview.sock -
 > read
 [2014/07/06 23:34:49] Log (1) ...
 [2014/07/06 23:34:50] Log (2) ...
 [2014/07/06 23:34:50] Log (3) ...
 [2014/07/06 23:34:51] Log (4) ...
 [2014/07/06 23:34:51] Log (5) ...

=head1 ENVIRONMENT

Below is summary of environment variables used.

=head2 Turning on/off logging

 LOG (bool)

=head2 Setting general level

 TRACE (bool)       setting general level to trace
 DEBUG (bool)       setting general level to debug
 VERBOSE (bool)     setting general level to info
 QUIET (bool)       setting general level to error (turn off warnings)
 LOG_LEVEL (str)

=head2 Setting per-output level

 FILE_TRACE, FILE_DEBUG, FILE_VERBOSE, FILE_QUIET, FILE_LOG_LEVEL
 SCREEN_TRACE and so on
 DIR_TRACE and so on
 SYSLOG_TRACE and so on
 UNIXSOCK_TRACE and so on
 ARRAY_TRACE and so on

=head2 Setting per-category level

 LOG_CATEGORY_LEVEL (hash, json)
 LOG_CATEGORY_ALIAS (hash, json)

=head2 Setting per-output, per-category level

 FILE_LOG_CATEGORY_LEVEL
 SCREEN_LOG_CATEGORY_LEVEL
 and so on

=head2 Controlling extra fields to log

 LOG_SHOW_LOCATION
 LOG_SHOW_CATEGORY

=head2 Force-enable or disable color

 COLOR (bool)

=head2 Turn on Log::Any::App's debugging

 LOGANYAPP_DEBUG (bool)

=head2 Turn on showing elapsed time in screen

 LOG_ELAPSED_TIME_IN_SCREEN (bool)

Note that elapsed time is currently produced using Log::Log4perl's %r (number of
milliseconds since the program started, where program started means when
Log::Log4perl starts counting time).

=head2 Filtering

 LOG_FILTER_TEXT (str)
 LOG_FILTER_NO_TEXT (str)
 LOG_FILTER_CITEXT (str)
 LOG_FILTER_NO_CITEXT (str)
 LOG_FILTER_RE (str)
 LOG_FILTER_NO_RE (str)

=head2 Per-output filtering

 {FILE,DIR,SCREEN,SYSLOG,UNIXSOCK,ARRAY}_LOG_FILTER_TEXT (str)
 and so on

=head2 Extra things to log

=over

=item * LOG_ENV (bool)

If set to 1, will dump environment variables at the start of program. Useful for
debugging e.g. CGI or git hook scripts. You might also want to look at
L<Log::Any::Adapter::Core::Patch::UseDataDump> to make the dump more readable.

Logging will be done under category C<main> and at level C<trace>.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-Any-App>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-Any-App>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Any-App>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::Any> and L<Log::Log4perl>

Some alternative logging modules: L<Log::Dispatchouli> (based on
L<Log::Dispatch>), L<Log::Fast>, L<Log::Log4perl::Tiny>. Really, there are 7,451
of them (roughly one third of CPAN) at the time of this writing.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2015, 2014, 2013, 2012, 2011, 2010 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
