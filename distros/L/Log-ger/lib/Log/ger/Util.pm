package Log::ger::Util;

our $DATE = '2017-06-21'; # DATE
our $VERSION = '0.004'; # VERSION

use strict;
use warnings;

require Log::ger;

sub _dump {
    unless ($Log::ger::_dumper) {
        eval { require Data::Dmp };
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
                Data::Dumper::Dumper($_[0]);
            };
        } else {
            $Log::ger::_dumper = sub { Data::Dmp::dmp($_[0]) };
        }
    }
    $Log::ger::_dumper->($_[0]);
}

sub set_level {
    $Log::ger::Current_Level = numeric_level(shift);
    resetup_importers();
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

sub resetup_importers {
    for my $pkg (keys %Log::ger::Setup_Args) {
        Log::ger::setup_package($pkg, $Log::ger::Setup_Args{$pkg});
    }
}

sub set_output {
    my ($mod, %args) = @_;
    die "Invalid output module syntax" unless $mod =~ /\A\w+(::\w+)*\z/;
    $mod = "Log::ger::Output::$mod" unless $mod =~ /\ALog::ger::Output::/;
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;
    $mod->import(%args);
    resetup_importers();
}

sub _action_on_plugins {
    my $action = shift;

    my $phase = shift;
    my $plugins = $Log::ger::Plugins{$phase} or die "Unknown phase '$phase'";

    if ($action eq 'add_for_package') {
        my ($package, $plugin, $replace) = @_;
        $Log::ger::Importer_Plugins{$package}{$phase} ||= [];
        my $key;
        if (ref $plugin eq 'ARRAY') {
            $key = $plugin->[2];
        } else {
            $key = $plugin;
        }
        if ($replace) {
            $Log::ger::Importer_Plugins{$package}{$phase} = [
                grep { ref $_ eq 'ARRAY' ? $key ne $_->[2] : $key ne $_ }
                    @{ $Log::ger::Importer_Plugins{$package}{$phase} }
            ];
        } else {
            return 0
                if grep { ref $_ eq 'ARRAY' ? $key eq $_->[2] : $key eq $_ }
                @{ $Log::ger::Importer_Plugins{$package}{$phase} };
        }
        unshift @{ $Log::ger::Importer_Plugins{$package}{$phase} }, $plugin;
    } elsif ($action eq 'add') {
        my ($plugin, $replace) = @_;
        my $key;
        if (ref $plugin eq 'ARRAY') {
            $key = $plugin->[2];
        } else {
            $key = $plugin;
        }
        if ($replace) {
            $Log::ger::Plugins{$phase} = [
                grep { ref $_ eq 'ARRAY' ? $key ne $_->[2] : $key ne $_ }
                    @{ $Log::ger::Plugins{$phase} }
            ];
        } else {
            return 0
                if grep { ref $_ eq 'ARRAY' ? $key eq $_->[2] : $key eq $_ }
                @{ $Log::ger::Plugins{$phase} };
        }
        unshift @{ $Log::ger::Plugins{$phase} }, $plugin;
    } elsif ($action eq 'reset') {
        my $saved = $Log::ger::Plugins{$phase};
        $Log::ger::Plugins{$phase} = [@{ $Log::ger::Default_Plugins{$phase} }];
        return $saved;
    } elsif ($action eq 'empty') {
        my $saved = $Log::ger::Plugins{$phase};
        $Log::ger::Plugins{$phase} = [];
        return $saved;
    } elsif ($action eq 'save') {
        return [@{ $Log::ger::Plugins{$phase} }];
    } elsif ($action eq 'restore') {
        my $saved = shift;
        $Log::ger::Plugins{$phase} = [@$saved];
        return $saved;
    }
}

sub add_plugin {
    my ($phase, $plugin, $replace) = @_;
    _action_on_plugins('add', $phase, $plugin, $replace);
}

sub add_plugin_for_package {
    my ($package, $phase, $plugin, $replace) = @_;
    _action_on_plugins('add_for_package', $phase, $package, $plugin, $replace);
}

sub reset_plugins {
    my ($phase) = @_;
    _action_on_plugins('reset', $phase);
}

sub empty_plugins {
    my ($phase) = @_;
    _action_on_plugins('empty', $phase);
}

sub save_plugins {
    my ($phase) = @_;
    _action_on_plugins('save', $phase);
}

sub restore_plugins {
    my ($phase, $saved) = @_;
    _action_on_plugins('restore', $phase, $saved);
}

1;
# ABSTRACT: Utility routines for Log::ger

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Util - Utility routines for Log::ger

=head1 VERSION

version 0.004

=head1 DESCRIPTION

This package is created to keep Log::ger as minimalist as possible.

=for Pod::Coverage ^(.+)$

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
