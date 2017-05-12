use strict;
use warnings;

my @n_lower = qw(loglevel log_level);
my @n_ucfirst = qw(LogLevel Log_Level);
my @n_uc = qw(LOGLEVEL LOG_LEVEL);
my @n = (@n_lower, @n_ucfirst, @n_uc);
my @outputs = qw(dir file screen syslog);
my @s_lower = qw(quiet verbose debug trace);
my @s_ucfirst = map {ucfirst} @s_lower;
my @s_uc = map {uc} @s_lower;
my @s = (@s_lower, @s_ucfirst, @s_uc);

my @global_vars = (@n, @s);
for my $o (@outputs) { push @global_vars, $o."_".$_ for @n_lower }
for my $o (@outputs) { push @global_vars, ucfirst($o)."_".$_ for @n_ucfirst }
for my $o (@outputs) { push @global_vars, uc($o)."_".$_ for @n_uc }
for my $o (@outputs) { push @global_vars, $o."_".$_ for @s_lower }
for my $o (@outputs) { push @global_vars, ucfirst($o)."_".$_ for @s_ucfirst }
for my $o (@outputs) { push @global_vars, uc($o)."_".$_ for @s_uc }

my %orig_env;
BEGIN { %orig_env = %ENV }

sub reset_vars {
    %App::options = ();
    delete $ENV{$_} for keys %ENV; $ENV{$_} = $orig_env{$_} for keys %orig_env;
    @ARGV = ();
    no strict 'refs';
    no warnings;
    for my $v (@global_vars) { $v = "main::$v"; $$v = undef }
}

sub test_init {
    my %args = @_;
    my $name = $args{name};
    my $init_args = $args{init_args} ? [@{ $args{init_args} }] : [];
    push @$init_args, -init => 0;

    reset_vars();
    $args{pre}->() if $args{pre};
    $Log::Any::App::init_called = 0;
    my $spec = Log::Any::App::init($init_args);

    if (defined $args{num_dirs}) {
        is(scalar(@{ $spec->{dir} }), $args{num_dirs}, "$name: num of dir output is $args{num_dirs}");
    }
    if (defined $args{num_files}) {
        is(scalar(@{ $spec->{file} }), $args{num_files}, "$name: num of file output is $args{num_files}");
    }
    if (defined $args{num_screens}) {
        is(scalar(@{ $spec->{screen} }), $args{num_screens}, "$name: num of screen output is $args{num_screens}");
    }
    if (defined $args{num_syslogs}) {
        is(scalar(@{ $spec->{syslog} }), $args{num_syslogs}, "$name: num of syslog output is $args{num_syslogs}");
    }

    if (defined $args{level}) {
        is(uc($spec->{level}), uc($args{level}), "$name: general level is $args{level}");
    }
    if (defined $args{dir_level}) {
        is(uc($spec->{dir}[0]{level}), uc($args{dir_level}), "$name: dir level is $args{dir_level}");
    }
    if (defined $args{file_level}) {
        is(uc($spec->{file}[0]{level}), uc($args{file_level}), "$name: file level is $args{file_level}");
    }
    if (defined $args{screen_level}) {
        is(uc($spec->{screen}[0]{level}), uc($args{screen_level}), "$name: screen level is $args{screen_level}");
    }
    if (defined $args{syslog_level}) {
        is(uc($spec->{syslog}[0]{level}), uc($args{syslog_level}), "$name: syslog level is $args{syslog_level}");
    }

    if (defined $args{dir_params}) {
        _test_params("dir", $spec->{dir}[0], $args{dir_params}, $name);
    }
    if (defined $args{file_params}) {
        _test_params("file", $spec->{file}[0], $args{file_params}, $name);
    }
    if (defined $args{screen_params}) {
        _test_params("screen", $spec->{screen}[0], $args{screen_params}, $name);
    }
    if (defined $args{syslog_params}) {
        _test_params("syslog", $spec->{syslog}[0], $args{syslog_params}, $name);
    }

    if ($args{check}) {
        $args{check}->($spec, $name);
    }
}

sub _test_params {
    my ($kind, $ospec, $params, $name) = @_;
    while (my ($k, $v) = each %$params) {
        if (ref($v) eq 'Regexp') {
            like($ospec->{$k}, $v, "$name: $kind param '$k' matches $v");
        } else {
            is  ($ospec->{$k}, $v, "$name: $kind param '$k' is $v");
        }
    }
}

1;
