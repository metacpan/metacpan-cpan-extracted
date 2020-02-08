package Log::ger::Output::Composite;

our $DATE = '2020-02-06'; # DATE
our $VERSION = '0.011'; # VERSION

use strict;
use warnings;
use Log::ger::Util;

# this can be used to override all level settings as it has the highest
# precedence.
our $Current_Level;

sub _get_min_max_level {
    my $level = shift;
    my ($min, $max);
    if (defined $level) {
        if (defined $Current_Level) {
            $min = 0;
            $max = $Current_Level;
        } elsif (ref $level eq 'ARRAY') {
            $min = Log::ger::Util::numeric_level($level->[0]);
            $max = Log::ger::Util::numeric_level($level->[1]);
            ($min, $max) = ($max, $min) if $min > $max;
        } else {
            $min = 0;
            $max = Log::ger::Util::numeric_level($level);
        }
    }
    ($min, $max);
}

sub get_hooks {
    my %conf = @_;

    # check arguments
    for my $k (keys %conf) {
        my $conf = $conf{$k};
        if ($k eq 'outputs') {
            for my $o (keys %$conf) {
                for my $oconf (ref $conf->{$o} eq 'ARRAY' ?
                                   @{ $conf->{$o} } : $conf->{$o}) {
                    for my $k2 (keys %$oconf) {
                        unless ($k2 =~
                                    /\A(conf|level|category_level|layout)\z/) {
                            die "Unknown configuration for output '$o': '$k2'";
                        }
                    }
                }
            }
        } elsif ($k =~ /\A(category_level)\z/) {
        } else {
            die "Unknown configuration: '$k'";
        }
    }

    my @ospecs;
    {
        my $outputs = $conf{outputs};
        for my $oname (sort keys %$outputs) {
            my $ospec0 = $outputs->{$oname};
            my @ospecs0;
            if (ref $ospec0 eq 'ARRAY') {
                @ospecs0 = map { +{ %{$_} } } @$ospec0;
            } else {
                @ospecs0 = (+{ %{ $ospec0 } });
            }

            die "Invalid output name '$oname'"
                unless $oname =~ /\A\w+(::\w+)*\z/;
            my $mod = "Log::ger::Output::$oname";
            (my $mod_pm = "$mod.pm") =~ s!::!/!g;
            require $mod_pm;
            for my $ospec (@ospecs0) {
                $ospec->{_name} = $oname;
                $ospec->{_mod} = $mod;
                push @ospecs, $ospec;
            }
        }
    }

    return {
        create_logml_routine => [
            __PACKAGE__, # key
            50,          # priority
            sub {        # hook
                no strict 'refs';
                require Data::Dmp;

                my %hook_args = @_;

                my $target = $hook_args{target};
                my $target_arg = $hook_args{target_arg};

                my $loggers = [];
                my $logger_is_ml = [];
                my $layouters = [];
                for my $ospec (@ospecs) {
                    my $oname = $ospec->{_name};
                    my $mod = "Log::ger::Output::$oname";
                    my $hooks = &{"$mod\::get_hooks"}(%{ $ospec->{conf} || {} })
                        or die "Output module $mod does not return any hooks";
                    my @hook_args = (
                        target => $hook_args{target},
                        target_arg => $hook_args{target_arg},
                        init_args => $hook_args{init_args},
                    );
                    my $res;
                    {
                        if ($hooks->{create_logml_routine}) {
                            $res = $hooks->{create_logml_routine}->[2]->(
                                @hook_args);
                            if ($res->[0]) {
                                push @$loggers, $res->[0];
                                push @$logger_is_ml, 1;
                                last;
                            }
                        }
                        push @hook_args, (level => 60, str_level => 'trace');
                        if ($hooks->{create_log_routine}) {
                            $res = $hooks->{create_log_routine}->[2]->(
                                @hook_args);
                            if ($res->[0]) {
                                push @$loggers, $res->[0];
                                push @$logger_is_ml, 0;
                                last;
                            }
                        }
                        die "Output module $mod does not produce logger in ".
                            "its create_logml_routine nor create_log_routine ".
                                "hook";
                    }
                    if ($ospec->{layout}) {
                        my $lname = $ospec->{layout}[0];
                        my $lconf = $ospec->{layout}[1] || {};
                        my $lmod  = "Log::ger::Layout::$lname";
                        (my $lmod_pm = "$lmod.pm") =~ s!::!/!g;
                        require $lmod_pm;
                        my $lhooks = &{"$lmod\::get_hooks"}(%$lconf)
                            or die "Layout module $lmod does not return ".
                            "any hooks";
                        $lhooks->{create_layouter}
                            or die "Layout module $mod does not declare ".
                            "layouter";
                        my @lhook_args = (
                            target => $hook_args{target},
                            target_arg => $hook_args{target_arg},
                            init_args => $hook_args{init_args},
                        );
                        my $lres = $lhooks->{create_layouter}->[2]->(
                            @lhook_args) or die "Hook from layout module ".
                                "$lmod does not produce layout routine";
                        ref $lres->[0] eq 'CODE'
                            or die "Layouter from layout module $lmod ".
                            "is not a coderef";
                        push @$layouters, $lres->[0];
                    } else {
                        push @$layouters, undef;
                    }
                }
                unless (@$loggers) {
                    $Log::ger::_logger_is_null = 1;
                    return [sub {0}];
                }

                # put the data that are mentioned in string-eval'ed code in a
                # package so they are addressable
                my $varname = do {
                    my $suffix;
                    if ($hook_args{target} eq 'package') {
                        $suffix = $hook_args{target_arg};
                    } else {
                        ($suffix) = "$hook_args{target_arg}" =~ /\(0x(\w+)/;
                    }
                    "Log::ger::Stash::OComposite_$suffix";
                };
                {
                    no strict 'refs';
                    ${$varname} = [];
                    ${$varname}->[0] = $loggers;
                    ${$varname}->[1] = $layouters;
                    ${$varname}->[2] = $hook_args{init_args};
                }

                # generate our logger routine
                my $logger;
                {
                    my @src;
                    push @src, "sub {\n";
                    push @src, "  my (\$ctx, \$lvl, \$msg) = \@_;\n";

                    for my $i (0..$#ospecs) {
                        my $ospec = $ospecs[$i];
                        push @src, "  # output #$i: $ospec->{_name}\n";
                        push @src, "  {\n";

                        # filter by output's category_level and category-level
                        if ($ospec->{category_level} || $conf{category_level}) {
                            push @src, "    my \$cat = \$ctx->{category} || ".
                                "'';\n";

                            my @cats;
                            if ($ospec->{category_level}) {
                                for my $cat (keys %{$ospec->{category_level}}) {
                                    my $clevel = $ospec->{category_level}{$cat};
                                    push @cats, [$cat, 1, $clevel];
                                }
                            }
                            if ($conf{category_level}) {
                                for my $cat (keys %{$conf{category_level}}) {
                                    my $clevel = $conf{category_level}{$cat};
                                    push @cats, [$cat, 2, $clevel];
                                }
                            }

                            for my $cat (sort {
                                length($b->[0]) <=> length($a->[0]) ||
                                    $a->[0] cmp $b->[0] ||
                                        $a->[1] <=> $b->[1]} @cats) {
                                push @src, "    if (\$cat eq ".Data::Dmp::dmp($cat->[0])." || index(\$cat, ".Data::Dmp::dmp("$cat->[0]\::").") == 0) { ";
                                my ($min_level, $max_level) =
                                    _get_min_max_level($cat->[2]);
                                push @src, "if (\$lvl >= $min_level && ".
                                    "\$lvl <= $max_level) { goto L } else { last }";
                                push @src, " }\n";
                            }
                            push @src, "\n";
                        }

                        # filter by output level
                        my ($min_level, $max_level) = _get_min_max_level(
                            $ospec->{level});
                        if (defined $min_level) {
                            push @src, "    if (\$lvl >= $min_level && ".
                                "\$lvl <= $max_level) { goto L } else { last }\n";
                        }

                        # filter by general level
                        push @src, "    if (\$Log::ger::Current_Level >= \$lvl) { goto L } else { last }\n";

                        # run output's log routine
                        if ($logger_is_ml->[$i]) {
                            push @src, "    L: if (\$$varname\->[1][$i]) { \$$varname\->[0][$i]->(\$ctx, \$lvl, \$$varname\->[1][$i]->(\$msg, \$$varname\->[2], \$lvl, Log::ger::Util::string_level(\$lvl))) } else { \$$varname\->[0][$i]->(\$ctx, \$lvl, \$msg) }\n";
                        } else {
                            push @src, "    L: if (\$$varname\->[1][$i]) { \$$varname\->[0][$i]->(\$ctx,        \$$varname\->[1][$i]->(\$msg, \$$varname\->[2], \$lvl, Log::ger::Util::string_level(\$lvl))) } else { \$$varname\->[0][$i]->(\$ctx,        \$msg) }\n";
                        }
                        push @src, "  }\n";
                        push @src, "  # end output #$i\n\n";
                    } # for ospec

                    push @src, "};\n";
                    my $src = join("", @src);
                    #print "D: logger source code: <<$src>>\n";

                    $logger = eval $src;
                }
                [$logger];
            }] # hook record
    };
}

sub set_level {
    $Current_Level = Log::ger::Util::numeric_level(shift);
    Log::ger::Util::reinit_all_targets();
}

1;
# ABSTRACT: Composite output

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::Composite - Composite output

=head1 VERSION

version 0.011

=head1 SYNOPSIS

 use Log::ger::Output Composite => (
     outputs => {
         # single screen output
         Screen => {
             conf   => { use_color=>1 },                        # output config, optional.
             level  => 'info',                                  # set per-output level. optional.
             layout => [Pattern => {format=>'%d (%F:%L)> %m'}], # add per-output layout, optional.
         },
         # multiple file outputs
         File => [
             {
                 conf  => { path=>'/var/log/myapp.log' },
                 level => 'warn',
                 category_level => {                            # set per-category, per-output level. optional.
                     # don't log MyApp::Security messages to this file
                     'MyApp::Security' => 'off',
                     ...
                 },
             },
             {
                 conf => { path => '/var/log/myapp-security.log' },
                 level => 'warn',
                 category_level => {
                     # only MyApp::Security messages go to this file
                     'MyApp::Security' => 'warn',
                     ...
                 },
             },
         ],
     },
     category_level => {                                        # set per-category level. optional.
        'MyApp::SubModule1' => 'info',
        'MyApp::SubModule2' => 'debug',
        ...
     },
 );
 use Log::ger;

 log_warn "blah...";

=head1 DESCRIPTION

This is a L<Log::ger> output that can multiplex output to several outputs and do
filtering on the basis of per-category level, per-output level, or per-output
per-category level. It can also apply per-output layout.

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head2 outputs => hash

Specify outputs. It's a hash with output name as keys and output specification
as values.

Output name is the name of output module without the C<Log::ger::Output::>
prefix, e.g. L<Screen|Log::ger::Output::Screen> or
L<File|Log::ger::Output::File>.

Output specification is either a hashref or arrayref of hashrefs to specify
multiple outputs per type (e.g. if you want to output to two File's). Known
hashref keys:

=over

=item * conf => hashref

Specify output configuration. Optional. See each output documentation for the
list of available configuration parameters.

=item * level => str|int|[min, max]

Specify per-output level. Optional. If specified, logging will be done at this
level instead of the general level. For example, if this is set to C<debug> then
debug messages and higher will be sent to output even though the general level
is C<warn>. Vice versa, if this is set to C<error> then even though the general
level is C<warn>, warning messages won't be sent to this output; only C<error>
messages and higher will be sent.

You can specify a single level (e.g. 1 or "trace") or a two-element array to
specify minimum and maximum level (e.g. C<<["trace", "info"]>>). If you
accidentally mix up minimum and maximum, this module will helpfully fix it for
you.

=item * category_level => hash

Specify per-output per-category level. Optional. Hash key is category name,
value is level (which can be a string/numeric level or a two-element array
containing minimum and maximum level).

=item * layout => [Name => {conf1=>..., conf2=>..., ...}]

Specify per-output layout. Optional. Value is two-element array containing
layout name (without the C<Log::ger::Layout::> prefix, e.g.
L<Pattern|Log::ger::Layout::Pattern>) and configuration hash. See each layout
module documentation for the list of available configuration parameters.

Note that if you also use a layout module outside of Composite configuration,
e.g.:

 use Log::ger::Output Composite => (...);
 use Log::ger::Layout Pattern => (format => '...');

then both layouts will be applied, the general layout will be applied before the
per-output layout.

=back

=head2 category_level => hash

Specify per-category level. Optional. Hash key is category name, value is level
(which can be a string/numeric level or a two-element array containing minimum
and maximum level).

=head1 FAQS

=head2 Why doesn't re-setting log level using Log::ger::Util::set_level() work?

This output plugin sets its own levels and logs using a multilevel routine
(which gets called for all levels). Re-setting log level dynamically via
L<Log::ger::Util>'s C<set_level> will not work as intended, which is fortunate
or unfortunate depending on your need.

If you want to override all levels settings with a single value, you can use
C<Log::ger::Output::Composite::set_level>, for example:

 Log::ger::Util::set_level('trace'); # also set this too
 Log::ger::Output::Composite::set_level('trace');

This sets an internal level setting which is respected and has the highest
precedence so all levels settings will use this instead. If previously you have:

 Log::ger::Output->set(Composite => {
     default_level => 'error',
     outputs => {
         File => {path=>'/foo', level=>'debug'},
         Screen => {level=>'info', category_level=>{MyApp=>'warn'}},
     },
     category_level => {
         'MyApp::SubModule1' => 'debug',
     },
 });

then after the C<Log::ger::Output::Composite::set_level('trace')>, all the above
per-category and per-output levels will be set to C<trace>.

=head1 ENVIRONMENT

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
