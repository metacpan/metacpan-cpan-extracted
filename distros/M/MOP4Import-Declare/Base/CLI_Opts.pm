package MOP4Import::Base::CLI_Opts;
use strict;
use warnings;
use MOP4Import::Base::CLI -as_base
#  , [extend => FieldSpec => qw/type alias/]
  , [fields => qw/_cmd __cmd/]
;
use MOP4Import::Opts;
use Carp ();
use Data::Dumper;

use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};

use MOP4Import::Types::Extend
      FieldSpec => [[fields => qw/type alias command real_name required for_subcmd/]];

print STDERR "FieldSpec = ", FieldSpec, "\n" if DEBUG;

sub new {
    my MY $self = fields::new(shift);
    my $pre = {};
    $self->configure_for_cli_opts($pre, @_);
    $self->after_new;
    $self;
}

sub invoke {
    my ( $self, $cmd, @args ) = @_;
    $self->{_cmd} = $cmd;
    if ( my $subref = $self->can("cmd_$cmd") ) {
        $self->configure_for_cli_opts({for_subcmd => 1}, @args);
        $subref->($self, @args);
    }
    else {
        Carp::croak("Cmd `$cmd` is not implemented.\n");
    }
}


use MOP4Import::Opts qw/Opts m4i_args m4i_opts/;
use MOP4Import::Util;

sub import {
    my ($myPack, @decls) = @_;

    m4i_log_start() if DEBUG;

    if (  (grep { $_ eq '-as_base' } @decls) && not (grep { $_ eq 'options' } map { ref($_) ? @$_ : $_ } @decls) ) {
        DEBUG && print STDERR "Because of no 'options', we set 'help' and 'version' automatically.\n";
        push @decls, [
            options =>
                ['help|h', 'command', 'help'],
                ['version', 'command', 'version'],
        ];
    }

    my Opts $opts = m4i_opts([caller]);

    @decls = $myPack->default_exports unless @decls;

    $myPack->dispatch_declare($opts, $myPack->always_exports, @decls);

    m4i_log_end($opts->{callpack}) if DEBUG;
}


sub default_options {
    return (
        help    => ['command' => 'help', 'type' => 'flag', 'alias' => 'h'],
        version => ['command' => 'version', 'type' => 'flag'],
    );
}


sub _default_opt {
    my ( $myPack, $decls ) = @_;
    my %auto      = $myPack->default_options;
    my %rev_alias = map { # aliasの逆リンクをつくる
        my %pair = @{ $auto{$_} };
        defined $pair{alias} ? ($pair{alias} => $_) : ();
    } keys %auto;

    for my $dec (@$decls) {
        if ( $dec->[0] =~ /^([-a-zA-Z0-9]+)(?:\|([a-zA-Z0-9]))?(?:=[is]@?)?$/ ) {
            my $optname = $1;
            my $alias   = $2 // '';
            for my $k ( $optname, $alias ) {
                my $rev_alias = $rev_alias{$k};
                my %opt = @{$auto{$k} || []};
                if ( exists $opt{alias} ) { # オプションがユーザー定義されているならaliasも不要
                    delete $auto{$opt{alias}};
                }
                if ( $rev_alias ) {
                   my %pair = @{ $auto{$rev_alias} || [] };
                   delete $pair{alias};
                   $auto{$rev_alias} = [%pair] if exists $auto{$rev_alias};
                }
                delete $auto{$k};
            }
        }
    }

    for my $k ( sort keys %auto ) {
        push @$decls, [$k, @{$auto{$k}}];
    }
    #print "decls:", Dumper($decls);
}

sub declare_options {
    (my $myPack, my Opts $opts, my (@decls)) = m4i_args(@_);

    $myPack->_default_opt(\@decls);

    $myPack->declare_fields($opts, map {
        my $o = ref $_ ? $_ : [$_];

        unless ( $o->[0] =~ /([-\w]+)(?:\|([-\w]+))?(?:=([is]@?))?/ ) {
            Carp::croak("Invalid option format - " . $o->[0]);
        }

        my ($optline, %pair) = @$o;
        if (exists $pair{'for_subcmd'}) {
            if ( ref $pair{'for_subcmd'} ) {
                $pair{'for_subcmd'} = +{ map { $_ => 1 } @{ $pair{'for_subcmd'} } };
            }
            elsif ( $pair{'for_subcmd'} ne '1' ) {
                $pair{'for_subcmd'} =  { $pair{'for_subcmd'} => 1 };
            }
            @$o = ($optline, %pair);
        }

        my ($name, $alias, $type) = ($1, $2, $3);
        $type ||= 'flag';
        if (DEBUG) {
            print STDERR $name;
            if (defined $alias) {print " - $alias"}
            print STDERR " = $type";
            print "\n";
        }
        push @$o, real_name => $name;
        $name =~ s/-/_/g;
        $o->[0] = $name;
        push @$o, alias => $alias if defined $alias;
        push @$o, type => $type;
        $o;
    } @decls);
}

sub parse_opts_for_cli_opts {
    my ($class, $list, $result, @rest) = @_;
    my $fields = MOP4Import::Declare::fields_hash($class);
    print STDERR "fields for $class : ", Data::Dumper->new([$fields])->Dump, "\n" if DEBUG;

    my %alias;
    my $form = {};
    my $preserve = (ref($result) && scalar(@$result) && $result->[0]) ? shift(@$result) : {};
    unshift @{ $result }, { %$preserve, without_value => {} }; # SUPER::parse_optsで失われると困る情報を保持

    {
        foreach my $name (keys %$fields) {
            my FieldSpec $spec = $fields->{$name};
            if ( UNIVERSAL::isa($spec, FieldSpec) ) {
                if ( $preserve->{for_subcmd} ) { # at this time, $class is a created object.
                    next if not $spec->{for_subcmd};
                    if ( ref $spec->{for_subcmd} ) {
                        next unless $spec->{for_subcmd}->{ $class->{_cmd} };
                    }
                }
                elsif ( $spec->{for_subcmd} ) {
                    next;
                }

                $form->{ $name } = $spec if $spec->{type};
                if ( $spec->{alias} ) {
                    $alias{$spec->{alias}} = $name;
                    $form->{ $spec->{alias} } = $form->{ $name };
                }
            }
        }
    }
    print STDERR "option format: ", Data::Dumper->new([$form])->Dump, "\n" if DEBUG;
    my $key = 1;
    my @stack;
    my $cmd;
    my $req_value;
    for my $arg ( @$list ) {
        if ( $key ) {
            if ( $arg =~ /^-([^=]+)=(.+)$/ ) { # -f=foo
                push @stack, $arg;
            }
            elsif ( $arg =~ /^--([^=]+)=(.+)$/ ) { # --foo=baz
                push @stack, $arg;
            }
            elsif ( !$cmd && $arg =~ /^-([^-=]+)/ ) { # -fb( value)
                my $myaby_opts = $1;
                for my $s (split//, $myaby_opts) {
                    if ( not defined $form->{$s} ) {
                        Carp::croak("Invalid option format - " . $arg);
                    }
                    if ( $form->{$s}->{type} ne 'flag' ) {
                        push @stack, '-' . $s;
                        $key = 0;
                        if (not $req_value) {
                            $req_value = $myaby_opts;
                        }
                    }
                    else {
                        push @stack, '-' . $s;
                    }
                }
            }
            elsif ( !$cmd && $arg =~ /^--([^=]+)/ ) { # --bar( value)
                if ( not defined $form->{_hyphen2underscore($1)} ) {
                    Carp::croak("Invalid option format - " . $arg);
                }
                if ( $form->{_hyphen2underscore($1)}->{type} ne 'flag' ) {
                    push @stack, $arg;
                    $key = 0;
                    if (not $req_value) {
                        $req_value = _hyphen2underscore($1);
                    }
                }
                else {
                    push @stack, $arg;
                }
            }
            else { # perhaps this is command!
                $cmd = $arg;
                push @stack, $arg;
            }
        }
        else { # change to Base::CLI aware format
            $stack[-1] .= '=' . $arg;
            $key = 1;
            $req_value = '';
        }
    }
    #print Dumper($list);
    #print Dumper(\@stack);
    @$list = @stack;

    if ($req_value) {
        $result->[0]->{without_value}->{ $req_value } = 1;
    }

    $class->parse_opts($list, $result, \%alias, @rest);
}


sub configure_for_cli_opts {
    my ( $self, @args ) = @_;
    my $fields = MOP4Import::Declare::fields_hash($self);
    my @res;
    my %map;
    my $command;

    my $preserved = shift @args;

    my (%required, %default);
    for my $spec ( values %$fields ) {
        next unless UNIVERSAL::isa($spec, FieldSpec);
        next if ( $preserved->{for_subcmd} and not $spec->{for_subcmd} );
        next if ( not $preserved->{for_subcmd} and $spec->{for_subcmd} );
        if ( $preserved->{for_subcmd} and ref($spec->{for_subcmd}) and not $spec->{for_subcmd}->{ $self->{_cmd} } ) {
            next;
        }
        $required{ $spec->{name} } = $spec->{required} if exists $spec->{required};
        $default{ $spec->{name} }  = $spec->{default}  if exists $spec->{default};
        if ( $spec->{alias} && exists $preserved->{without_value}->{ $spec->{alias} } ) {
            $preserved->{without_value}->{ $spec->{name} } = $preserved->{without_value}->{ $spec->{alias} };
            delete $preserved->{without_value}->{ $spec->{alias} };
        }
    }

    while ( defined(my $name = shift @args) ) {
        my $type = $fields->{$name}->{type} // '';
        my $val  = shift(@args);

        if ( $type =~ /(.)@/ ) {
            if ( $1 eq 'i' ) {
                if ( $val !~ /^[0-9]+$/ ) {
                    Carp::croak("option `$name` takes integer.");
                }
            }

            if (not exists $map{$name}) {
                push @res, $name;
                push @res, [$val];
                $map{$name} = $#res;
            }
            else {
                push @{ $res[ $map{$name} ] }, $val;
            }
            next;
        }
        elsif ( $type eq 'i' ) {
            if ( $val !~ /^[0-9]+$/ ) {
                Carp::croak("option `$name` takes integer.");
            }
        }

        if ( $fields->{$name}->{command} ) {
            if ( defined $command ) {
                Carp::croak("command invoking option was already called before `$name`.");
            }
            $command = $fields->{$name}->{command};
            $self->{__cmd} = [$command, $val];
            next;
        }

        delete $required{$name} if not exists $preserved->{without_value}->{ $name };
        delete $default{$name};

        push @res, $name;
        push @res, $val;
    }

    for my $key (keys %default) {
        push @res, $key, $default{$key};
        delete $required{$key};
    }
    if (%required) {
        my $opt = (sort keys %required)[0];
        Carp::croak("$opt is required.");
    }
    #print Dumper([@res]);
    $self->configure(@res);
}


sub cmd_default { }

sub cmd_version {
    my $v = shift->VERSION // '0.0';
    print "$v\n";
}

sub cmd_help { # From  MOP4Import::Base::CLI, original cmd_help do 'die'
    my $self   = shift;
    my $pack   = ref $self || $self;
    my $fields = MOP4Import::Declare::fields_hash($self);
    my $names  = MOP4Import::Declare::fields_array($self);

    require MOP4Import::Util::FindMethods;

    my @methods = MOP4Import::Util::FindMethods::FindMethods($pack, sub {s/^cmd_//});

    print join("\n", <<END);
Usage: @{[File::Basename::basename($0)]} [--opt=value].. <command> [--opt=value].. ARGS...

Commands:
  @{[join("\n  ", @methods)]}
END

    my $max_len  = 0;
    my %opt;
    for my $name ( grep {/^[a-z]/} @$names ) {
        my FieldSpec $fs = $fields->{$name};
        my $cmds = ['__common__'];
        my $str;
        if (ref $fs) {
            $str =
                do{ '  --' . (UNIVERSAL::isa($fs, FieldSpec) ? ($fs->{real_name} // '') : $name) } .
                do{ UNIVERSAL::isa($fs, FieldSpec) and $fs->{ alias } ? ', -' . $fs->{ alias } : ''  },
            ;
            if ( exists $fs->{for_subcmd} ) {
                if ( ref $fs->{for_subcmd} ) {
                    $cmds = [ sort keys %{ $fs->{for_subcmd} } ];
                }
            }
        }
        else {
            $str = $name;
        }
        $max_len = length $str if length $str > $max_len;

        next if $str eq '  --';

        for my $name ( @$cmds ) {
            push @{ $opt{ $name } }, [$str, $fs->{doc} ? $fs->{doc} : ''];
        }
    }

    my @opts = [ 'common option', delete $opt{'__common__'} ];
    push @opts, map { [ 'for ' . $_ => $opt{$_} ] } sort keys %opt;

    print join("\n", <<END);

Options:
END

    $max_len += 2;
    for my $optset ( @opts ) {
        my ( $subcmd, $opts ) = @$optset;
        print " [$subcmd]\n";
        for my $opt (@$opts) {
            printf( "%-${max_len}s%s\n", @$opt );
        }
        print "\n";
    }

    exit();
}

sub run {
    my ($class, $arglist) = @_;
    my $default_cmd = 'default';
    my $fields = MOP4Import::Declare::fields_hash($class);
    # $arglist を parse し、 $class->new 用のパラメータリストを作る
    my @opts = $class->parse_opts_for_cli_opts($arglist);
    my MY $obj = fields::new($class);
    $obj->configure_for_cli_opts(@opts);
    $obj->after_new;
    # 次の引数を取り出して、サブコマンドとして解釈を試みる
    my $cmd = shift @$arglist || _set_cmd_by_option($obj, $arglist) || $default_cmd;
    $obj->{_cmd} = $cmd;
    my $result = [ { for_subcmd => 1 } ];
    $obj->configure_for_cli_opts(@{ $obj->parse_opts_for_cli_opts($arglist, $result) });
    # サブコマンド毎の処理を行う
    # 結果を何らかの形式で出力する
    # 望ましい終了コードを返す（差し当たり、必要ならば各メソッド内で指定する）
    if (my $sub = $obj->can("cmd_$cmd")) {
        $sub->($obj, @$arglist);
    } else {
        print STDERR "Cmd `$cmd` is not implemented.\n";
        exit(1);
    }
}

sub _hyphen2underscore {
    my ($v) = @_;
    $v =~ tr/-/_/;
    return $v;
}

sub _set_cmd_by_option {
    my ($obj, $arglist) = @_;
    return unless $obj->{__cmd};
    push @$arglist, $obj->{__cmd}->[1];
    return $obj->{__cmd}->[0];
}

1;
