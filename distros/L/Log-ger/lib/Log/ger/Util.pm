package Log::ger::Util;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-31'; # DATE
our $DIST = 'Log-ger'; # DIST
our $VERSION = '0.038'; # VERSION

use strict;
use warnings;

require Log::ger;
require Log::ger::Heavy;

sub _dump {
    unless ($Log::ger::_dumper) {
        eval {
            no warnings 'once';
            require Data::Dmp;
            $Data::Dmp::OPT_REMOVE_PRAGMAS = 1;
            1;
        };
        if ($@) {
            no warnings 'once';
            require Data::Dumper;
            $Log::ger::_dumper = sub {
                local $Data::Dumper::Terse = 1;
                local $Data::Dumper::Indent = 0;
                local $Data::Dumper::Useqq = 1;
                local $Data::Dumper::Deparse = 1;
                local $Data::Dumper::Quotekeys = 0;
                local $Data::Dumper::Sortkeys = 1;
                local $Data::Dumper::Trailingcomma = 1;
                local $Data::Dumper::Useqq = 1; # to show "\034", possible bug in Data::Dumper
                Data::Dumper::Dumper($_[0]);
            };
        } else {
            $Log::ger::_dumper = sub { Data::Dmp::dmp($_[0]) };
        }
    }
    $Log::ger::_dumper->($_[0]);
}

sub numeric_level {
    my $level = shift;
    return $level if $level =~ /\A\d+\z/;
    return $Log::ger::Levels{$level}
        if defined $Log::ger::Levels{$level};
    return $Log::ger::Level_Aliases{$level}
        if defined $Log::ger::Level_Aliases{$level};
    die "Unknown level '$level'";
}

sub string_level {
    my $level = shift;
    return $level if defined $Log::ger::Levels{$level};
    $level = $Log::ger::Level_Aliases{$level}
        if defined $Log::ger::Level_Aliases{$level};
    for (keys %Log::ger::Levels) {
        my $v = $Log::ger::Levels{$_};
        return $_ if $v == $level;
    }
    die "Unknown level '$level'";
}

sub set_level {
    no warnings 'once';
    $Log::ger::Current_Level = numeric_level(shift);
    reinit_all_targets();
}

sub _action_on_hooks {
    no warnings 'once';

    my ($action, $target_type, $target_name, $phase) = splice @_, 0, 4;

    my $hooks = $Log::ger::Global_Hooks{$phase} or die "Unknown phase '$phase'";
    if ($target_type eq 'package') {
        $hooks = ($Log::ger::Per_Package_Hooks{$target_name}{$phase} ||= []);
    } elsif ($target_type eq 'object') {
        my ($addr) = $target_name =~ $Log::ger::re_addr;
        $hooks = ($Log::ger::Per_Object_Hooks{$addr}{$phase} ||= []);
    } elsif ($target_type eq 'hash') {
        my ($addr) = $target_name =~ $Log::ger::re_addr;
        $hooks = ($Log::ger::Per_Hash_Hooks{$addr}{$phase} ||= []);
    }

    if ($action eq 'add') {
        my $hook = shift;
        # XXX remove duplicate key
        # my $key = $hook->[0];
        unshift @$hooks, $hook;
    } elsif ($action eq 'remove') {
        my $code = shift;
        for my $i (reverse 0..$#{$hooks}) {
            splice @$hooks, $i, 1 if $code->($hooks->[$i]);
        }
    } elsif ($action eq 'reset') {
        my $saved = [@$hooks];
        splice @$hooks, 0, scalar(@$hooks),
            @{ $Log::ger::Default_Hooks{$phase} };
        return $saved;
    } elsif ($action eq 'empty') {
        my $saved = [@$hooks];
        splice @$hooks, 0;
        return $saved;
    } elsif ($action eq 'save') {
        return [@$hooks];
    } elsif ($action eq 'restore') {
        my $saved = shift;
        splice @$hooks, 0, scalar(@$hooks), @$saved;
        return $saved;
    }
}

sub add_hook {
    my ($phase, $hook) = @_;
    _action_on_hooks('add', '', undef, $phase, $hook);
}

sub add_per_target_hook {
    my ($target_type, $target_name, $phase, $hook) = @_;
    _action_on_hooks('add', $target_type, $target_name, $phase, $hook);
}

sub remove_hook {
    my ($phase, $code) = @_;
    _action_on_hooks('remove', '', undef, $phase, $code);
}

sub remove_per_target_hook {
    my ($target_type, $target_name, $phase, $code) = @_;
    _action_on_hooks('remove', $target_type, $target_name, $phase, $code);
}

sub reset_hooks {
    my ($phase) = @_;
    _action_on_hooks('reset', '', undef, $phase);
}

sub reset_per_target_hooks {
    my ($target_type, $target_name, $phase) = @_;
    _action_on_hooks('reset', $target_type, $target_name, $phase);
}

sub empty_hooks {
    my ($phase) = @_;
    _action_on_hooks('empty', '', undef, $phase);
}

sub empty_per_target_hooks {
    my ($target_type, $target_name, $phase) = @_;
    _action_on_hooks('empty', $target_type, $target_name, $phase);
}

sub save_hooks {
    my ($phase) = @_;
    _action_on_hooks('save', '', undef, $phase);
}

sub save_per_target_hooks {
    my ($target_type, $target_name, $phase) = @_;
    _action_on_hooks('save', $target_type, $target_name, $phase);
}

sub restore_hooks {
    my ($phase, $saved) = @_;
    _action_on_hooks('restore', '', undef, $phase, $saved);
}

sub restore_per_target_hooks {
    my ($target_type, $target_name, $phase, $saved) = @_;
    _action_on_hooks('restore', $target_type, $target_name, $phase, $saved);
}

sub reinit_target {
    my ($target_type, $target_name) = @_;

    # adds target if not already exists
    Log::ger::add_target($target_type, $target_name, {}, 0);

    if ($target_type eq 'package') {
        my $per_target_conf = $Log::ger::Package_Targets{$target_name};
        Log::ger::init_target(package => $target_name, $per_target_conf);
    } elsif ($target_type eq 'object') {
        my ($obj_addr) = $target_name =~ $Log::ger::re_addr
            or die "Invalid object '$target_name': not a reference";
        my $v = $Log::ger::Object_Targets{$obj_addr}
            or die "Unknown object target '$target_name'";
        Log::ger::init_target(object => $v->[0], $v->[1]);
    } elsif ($target_type eq 'hash') {
        my ($hash_addr) = $target_name =~ $Log::ger::re_addr
            or die "Invalid hashref '$target_name': not a reference";
        my $v = $Log::ger::Hash_Targets{$hash_addr}
            or die "Unknown hash target '$target_name'";
        Log::ger::init_target(hash => $v->[0], $v->[1]);
    } else {
        die "Unknown target type '$target_type'";
    }
}

sub reinit_all_targets {
    for my $pkg (keys %Log::ger::Package_Targets) {
        #print "D:reinit package $pkg\n";
        Log::ger::init_target(
            package => $pkg, $Log::ger::Package_Targets{$pkg});
    }
    for my $k (keys %Log::ger::Object_Targets) {
        my ($obj, $per_target_conf) = @{ $Log::ger::Object_Targets{$k} };
        Log::ger::init_target(object => $obj, $per_target_conf);
    }
    for my $k (keys %Log::ger::Hash_Targets) {
        my ($hash, $per_target_conf) = @{ $Log::ger::Hash_Targets{$k} };
        Log::ger::init_target(hash => $hash, $per_target_conf);
    }
}

sub set_plugin {
    my %args = @_;

    my $hooks;
    if ($args{hooks}) {
        $hooks = $args{hooks};
    } else {
        no strict 'refs';
        my $prefix = $args{prefix} || 'Log::ger::Plugin::';
        my $mod = $args{name};
        $mod = $prefix . $mod unless index($mod, $prefix) == 0;
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;
        my $meta  = $mod->can("meta") ? $mod->meta : {v=>1};
        my $v     = $meta->{v} || 1;

        # history of v bumping:
        #
        # - v increased from 1 to 2 in Log::ger v0.037 to force all plugins that
        #   were not compatible with Log::ger 0.032 (removed
        #   create_logml_routine phase) to be upgraded.

        unless ($v == 2) {
            die "Plugin '$mod' (version ".(${"$mod\::VERSION"} || "dev").")".
                " follows meta version $v but Log::ger (version ".
                (${__PACKAGE__."::VERSION"} || "dev").
                ") (>0.032) requires meta version 2, ".
                "please upgrade the plugin first";
        }
        $hooks = &{"$mod\::get_hooks"}(%{ $args{conf} || {} });
    }

    {
        last unless $args{replace_package_regex};
        my $all_hooks;
        if (!$args{target}) {
            $all_hooks = \%Log::ger::Global_Hooks;
        } elsif ($args{target} eq 'package') {
            $all_hooks = $Log::ger::Per_Package_Hooks{ $args{target_arg} };
        } elsif ($args{target} eq 'object') {
            my ($addr) = $args{target_arg} =~ $Log::ger::re_addr;
            $all_hooks = $Log::ger::Per_Object_Hooks{$addr};
        } elsif ($args{target} eq 'hash') {
            my ($addr) = $args{target_arg} =~ $Log::ger::re_addr;
            $all_hooks = $Log::ger::Per_Hash_Hooks{$addr};
        }
        last unless $all_hooks;
        for my $phase (keys %$all_hooks) {
            my $hooks = $all_hooks->{$phase};
            for my $i (reverse 0..$#{$hooks}) {
                splice @$hooks, $i, 1
                    if $hooks->[$i][0] =~ $args{replace_package_regex};
            }
        }
    }

    for my $phase (keys %$hooks) {
        my $hook = $hooks->{$phase};
        if (defined $args{target}) {
            add_per_target_hook(
                $args{target}, $args{target_arg}, $phase, $hook);
        } else {
            add_hook($phase, $hook);
        }
    }

    my $reinit = $args{reinit};
    $reinit = 1 unless defined $reinit;
    if ($reinit) {
        if (defined $args{target}) {
            reinit_target($args{target}, $args{target_arg});
        } else {
            reinit_all_targets();
        }
    }
}

1;
# ABSTRACT: Utility routines for Log::ger

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Util - Utility routines for Log::ger

=head1 VERSION

version 0.038

=head1 DESCRIPTION

This package is created to keep Log::ger as minimalist as possible.

=for Pod::Coverage ^(.+)$

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
