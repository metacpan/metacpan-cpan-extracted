package Desktop::Workspace::Util;

use 5.010001;
use strict 'subs', 'vars';
use utf8;
use warnings;
use Log::ger;

use Exporter qw(import);
use List::Util qw(first);
use Perinci::Sub::Util qw(gen_modified_sub);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-04-15'; # DATE
our $DIST = 'Desktop-Workspace-Util'; # DIST
our $VERSION = '0.003'; # VERSION

our @EXPORT_OK = qw(
                       get_desktop_workspace_module
                       instantiate_desktop_workspace_module
                       list_desktop_workspace_items
                       open_desktop_workspace_items
               );

our %SPEC;

our %argspec0_module = (
    module => {
        schema => 'perl::modname*',
        req => 1,
        pos => 0,
    },
);

our %argspecopt_ns_prefixes = (
    ns_prefixes => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'ns_prefix',
        summary => 'List of namespaces to search for a Desktop Workspace specification modules',
        schema => ['array*', of=>['any*', of=>['perl::modname', ['str', in=>[""]]]]],
        default => ['DesktopWorkspace', ''],
    },
);

our %argspecs_module = (
    %argspec0_module,
    %argspecopt_ns_prefixes,
);

our %argspecopt_module_args = (
    module_args => {
        schema => 'hash*',
    },
);

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to DesktopWorkspace',
};

$SPEC{get_desktop_workspace_module} = {
    v => 1.1,
    summary => 'Get the first Perl desktop workspace specification module',
    args => {
        %argspecs_module,
    },
    result_naked => 1,
};
sub get_desktop_workspace_module {
    my %args = @_;

    my $module      = $args{module} or die "Please specify 'module'";
    my $ns_prefixes = $args{ns_prefixes} // ["DesktopWorkspace"];

    push @$ns_prefixes, "" unless @$ns_prefixes;

    for my $ns_prefix (@$ns_prefixes) {
        my $mod = (length($ns_prefix) ? "$ns_prefix\::" : "") . $module;
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        if (eval { require $mod_pm; 1 }) {
            return $mod;
        }
    }
    die "Can't find desktop workspace specification module '$module' (searched in ". join(", ", @$ns_prefixes).")";
}

$SPEC{instantiate_desktop_workspace_module} = {
    v => 1.1,
    summary => 'Instantiate the desktop workspace specification module (class)',
    args => {
        %argspecs_module,
        %argspecopt_module_args,
    },
    result_naked => 1,
};
sub instantiate_desktop_workspace_module {
    my %args = @_;

    my $mod = get_desktop_workspace_module(
        module => $args{module}, ns_prefixes => $args{ns_prefixes});
    $mod->new(%{ $args{module_args} // {} });
}

sub _find_window {
    my ($re, $all_windows) = @_;
    log_trace "Checking existing window (%s) ...", $re;
    for my $row (@$all_windows) {
        if ($row->{title} =~ $re) {
            log_trace "Found matching window %s", $row;
            return $row;
        }
    }
    return;
}

sub _items2windows {
    require Desktop::XWindowManager::Util;

    my $items = shift;

    my $windowkey;
    my $auto_file_num = 0;
    my $auto_prog_num = 0;
    my $auto_firefox_num = 0;
    my $auto_dolphin_num = 0;
    my %windows; # key = prefix+arbitrary number

    my $all_windows;
    {
        my $res = Desktop::XWindowManager::Util::list_xwm_windows(
            detail=>1,
            with_kde_activity_name => 1,
        );
        return [500, "Can't list windows: $res->[0] - $res->[1]"]
            unless $res->[0] == 200;
        $all_windows = $res->[2];
    }

  ITEM:
    for my $item (@$items) {
        if (defined($item->{url}) || defined($item->{dir})) {
            my $url = $item->{url} // $item->{dir};
            if (defined $item->{dolphin_window_num}) {
                $windowkey = "dolphin_".sprintf("%04d", $item->{dolphin_window_num});
            } elsif (defined $item->{firefox_window_num}) {
                $windowkey = "firefox_".sprintf("%04d", $item->{firefox_window_num});
            } else {
                my ($app, $num);
                if ($item->{new_browser_window}) {
                    $app = "firefox";
                    $num = ++$auto_firefox_num;
                } elsif ($item->{new_file_manager_window}) {
                    $app = "dolphin";
                    $num = ++$auto_dolphin_num;
                } else {
                    if (defined($item->{url})) {
                        $app = "firefox";
                        $num = $auto_firefox_num;
                    } else {
                        $app = "dolphin";
                        $num = $auto_dolphin_num;
                    }
                }
                $windowkey = "${app}_auto_".sprintf("%04d", $num);
            }
        } elsif (defined $item->{file}) {
            $windowkey = "file_" . (++$auto_file_num);
        } elsif (defined $item->{prog_name} or defined $item->{prog_path}) {
            $windowkey = "prog_" . (++$auto_prog_num);
        }

        $windows{$windowkey} //= { items=>[] };
        push @{ $windows{$windowkey}{items} }, $item;
    } # for item

  CHECK_EXISTING_WINDOWS: {
        for my $windowkey (sort keys %windows) {
            my $window = $windows{$windowkey};
            my $re = $window->{items}[-1]{window_title_re};
            if (!$re && $windowkey =~ /^dolphin/) {
                my $url = $window->{items}[-1]{url} // $window->{items}[-1]{dir};
                $re = qr/\Q$url\E — Dolphin$/;
            }
            if ($re) {
                my $w = _find_window($re, $all_windows);
                if ($w) {
                    $window->{existing_window_id} = $w->{id};
                    $window->{existing_window_kde_activity_name} = $w->{kde_activity_name};
                }
            }
        }
    }

    \%windows;
}

$SPEC{list_desktop_workspace_items} = {
    v => 1.1,
    summary => 'List the items from desktop workspace specification module, with filtering options',
    args => {
        %argspecs_module,
        %argspecopt_module_args,

        all => {
            summary => 'Whether to include items that are not included by default (has property `include_by_default`=0)',
            schema => 'bool*',
            tags => ['category:filtering'],
        },
        include_any_tags => {
            summary => 'Include all items that have any tag specified',
            schema => ['array*', of=>'str*'],
            tags => ['category:filtering'],
        },
        include_all_tags => {
            summary => 'Include all items that have ALL tags specified',
            schema => ['array*', of=>'str*'],
            tags => ['category:filtering'],
        },
        exclude_any_tags => {
            summary => 'Exclude all items that have any tags specified',
            schema => ['array*', of=>'str*'],
            tags => ['category:filtering'],
        },
        exclude_all_tags => {
            summary => 'Exclude all items that have ALL tags specified',
            schema => ['array*', of=>'str*'],
            tags => ['category:filtering'],
        },
        include_url => {
            summary => 'Whether to include URL items',
            schema => ['bool*'],
            tags => ['category:filtering'],
        },
        include_file => {
            summary => 'Whether to include file items',
            schema => ['bool*'],
            tags => ['category:filtering'],
        },
        include_dir => {
            summary => 'Whether to include dir items',
            schema => ['bool*'],
            tags => ['category:filtering'],
        },
        include_prog => {
            summary => 'Whether to include program items',
            schema => ['bool*'],
            tags => ['category:filtering'],
        },
        query => {
            schema => ['array*', of=>'str*'],
            pos => 1,
            slurpy => 1,
            tags => ['category:filtering'],
        },

        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
            tags => ['category:result'],
        },
        shuffle => {
            schema => 'bool*',
            tags => ['category:result'],
        },
    },
};
sub list_desktop_workspace_items {
    my %args = @_;

    my $obj = instantiate_desktop_workspace_module(
        module => $args{module},
        ns_prefixes => $args{ns_prefixes},
        module_args => $args{module_args},
    );

    my $items = $obj->items;

    if ($args{shuffle}) {
        require List::Util;
        $items = [List::Util::shuffle(@$items)];
    }

    require List::Util::Find;
    my @filtered_items;
  ITEM:
    for my $i (0 .. $#{$items}) {
        my $item = $items->[$i];

        # if not included by default, will be included only if specifically matching a filter
        my $include_by_default = $args{all} ? 1 :
            ($item->{include_by_default} // 1);

        my $match_a_filter = 0;

      FILTER: {
          INCLUDE_ANY_TAGS: {
                last unless $args{include_any_tags} && @{ $args{include_any_tags} };
                do { log_debug "Skipping item %s: does not pass include_any_tags %s", $item, $args{include_any_tags}; next ITEM }
                    unless List::Util::Find::hasanystrs($args{include_any_tags}, @{ $item->{tags} // []});
                $match_a_filter++;
            }
          INCLUDE_ALL_TAGS: {
                last unless $args{include_all_tags} && @{ $args{include_all_tags} };
                do { log_debug "Skipping item %s: does not pass include_all_tags %s", $item, $args{include_all_tags}; next ITEM }
                    unless List::Util::Find::hasallstrs($args{include_all_tags}, @{ $item->{tags} // []});
                $match_a_filter++;
            }
          EXCLUDE_ANY_TAGS: {
                last unless $args{exclude_any_tags} && @{ $args{exclude_any_tags} };
                do { log_debug "Skipping item %s: does not pass exclude_any_tags %s", $item, $args{exclude_any_tags}; next ITEM }
                    if List::Util::Find::hasanystrs($args{exclude_any_tags}, @{ $item->{tags} // []});
                $match_a_filter++;
            }
          EXCLUDE_ALL_TAGS: {
                last unless $args{exclude_all_tags} && @{ $args{exclude_all_tags} };
                do { log_debug "Skipping item %s: does not pass exclude_all_tags %s", $item, $args{exclude_all_tags}; next ITEM }
                    if List::Util::Find::hasallstrs($args{exclude_all_tags}, @{ $item->{tags} // []});
                $match_a_filter++;
            }
          QUERY: {
                last unless $args{query} && @{ $args{query} };
                my $num_positive_queries = 0;
                my $num_negative_queries = 0;
                my $match = 0;
              Q:
                for my $query0 (@{ $args{query} }) {
                    my ($is_negative, $query) = $query0 =~ /\A(-?)(.*)/;
                    $num_positive_queries++ if !$is_negative;
                    $num_negative_queries++ if  $is_negative;

                    if (defined $item->{url}) {
                        if ($item->{url} =~ /$query/i) {
                            if ($is_negative) { goto L1 } else { $match = 1; last Q }
                        }
                    }
                    if (defined $item->{file}) {
                        if ($item->{file} =~ /$query/i) {
                            if ($is_negative) { goto L1 } else { $match = 1; last Q }
                        }
                    }
                    if (defined $item->{dir}) {
                        if ($item->{dir} =~ /$query/i) {
                            if ($is_negative) { goto L1 } else { $match = 1; last Q }
                        }
                    }
                    if (defined $item->{prog_name}) {
                        if ($item->{prog_name} =~ /$query/i) {
                            if ($is_negative) { goto L1 } else { $match = 1; last Q }
                        }
                    }
                    if (defined $item->{prog_path}) {
                        if ($item->{prog_path} =~ /$query/i) {
                            if ($is_negative) { goto L1 } else { $match = 1; last Q }
                        }
                    }
                    for my $tag (@{ $item->{tags} // [] }) {
                        if ($tag =~ /$query/i) {
                            if ($is_negative) { goto L1 } else { $match = 1; last Q }
                        }
                    }
                    if (defined $item->{firefox_container}) {
                        if ($item->{firefox_container} =~ /$query/i) {
                            if ($is_negative) { goto L1 } else { $match = 1; last Q }
                        }
                    }
                } # for query
                $match++ if $num_positive_queries == 0;
              L1:
                do { log_debug "Skipping item %s: does not pass query %s", $item, $args{query}; next ITEM }
                    unless $match;
                $match_a_filter++;
            } # QUERY
        } # FILTER

        if (!$include_by_default && !$match_a_filter) {
            log_debug "Skipping item %s: not included by default and does not match filter(s)", $item;
            next ITEM;
        }

        push @filtered_items, $item;
    } # for item

    unless ($args{detail}) {
        @filtered_items = map {
            $_->{url} // $_->{file} // $_->{dir} // $_->{prog_name} // $_->{prog_path}
        } @filtered_items;
    }

    [200, "OK", \@filtered_items, {
        'func.obj' => $obj,
    }];
}

gen_modified_sub(
    die => 1,
    output_name => 'open_desktop_workspace_items',
    base_name => 'list_desktop_workspace_items',
    summary => 'Open desktop workspace items',
    description => <<'MARKDOWN',


MARKDOWN
    add_args => {
        kde_activity => {
            summary => 'Switch to the specified KDE activity name',
            description => <<'MARKDOWN',

Override's desktop workspace specification's `kde_activity` property.

MARKDOWN
            schema => 'str*',
        },
        reuse_window => {
            summary => 'Do not open if existing window is detected',
            schema => 'bool*',
        },
    },
    modify_meta => sub {
        my $meta = shift;

        $meta->{features} = {
            dry_run => 1,
        };
        $meta->{deps} = {
            all => [
                {prog => 'dolphin'},
                {prog => 'firefox-container'},
            ],
        };

    },
    wrap_code => sub {
        require IPC::System::Options;

        my $orig = shift;
        my %args = @_;

        my $dry_run = $args{-dry_run};

        my $obj;
        my $items;
      LIST_ITEMS: {
            my $res = $orig->(%args, detail=>1);
            unless ($res->[0] == 200) {
                return [500, "Can't list desktop workspace items: $res->[0] - $res->[1]"];
            }
            $items = $res->[2];
            $obj = $res->[3]{'func.obj'};
        } # LIST_ITEMS

        my $windows = _items2windows($items);

      WINDOW:
        for my $windowkey (sort keys %$windows) {
            my $window = $windows->{$windowkey};
            my $items = $window->{items};

            my $target_kde_activity;
          GET_TARGET_KDE_ACTIVITY: {
                my $item_kde_activity = first {defined $_->{kde_activity}} @$items; $item_kde_activity = $item_kde_activity->{kde_activity} if defined $item_kde_activity;
                $target_kde_activity = $args{kde_activity} // $item_kde_activity // $obj->{kde_activity};
            }

          REUSE_EXISTING_WINDOW: {
                last unless $window->{existing_window_id};
                log_trace "Window for items %s already exists (ID %s)%s",
                    $items,
                    $window->{existing_window_id},
                    $args{reuse_window} ? ", reusing it" : "";
                last unless $args{reuse_window};
                #log_error "D: target kde activity: %s, existing window's kde activity: %s", $target_kde_activity, $window->{existing_window_kde_activity_name};
                if (defined($window->{existing_window_kde_activity_name}) &&
                    defined($target_kde_activity) &&
                    $window->{existing_window_kde_activity_name} ne $target_kde_activity) {
                    log_trace "%sMoving window ID %s from KDE activity %s to KDE activity %s ...",
                        $args{-dry_run} ? "[DRY-RUN]" : "",
                        $window->{existing_window_id},
                        $window->{existing_window_kde_activity_name},
                        $target_kde_activity;
                    last if $args{-dry_run};
                    require Desktop::XWindowManager::Util;
                    my $res = Desktop::XWindowManager::Util::move_windows_to_kde_activity(
                        id => $window->{existing_window_id},
                        activity_name => $target_kde_activity,
                    );
                    log_warn "Can't move window ID %s to KDE activity %s: %d - %s",
                        $window->{existing_window_id},
                        $target_kde_activity,
                        $res->[0], $res->[1]
                        unless $res->[0] == 200;
                }
                next WINDOW;
            } # REUSE_EXISTING_WINDOW

          SWITCH_KDE_ACTIVITY: {
                last unless defined $target_kde_activity;
                log_trace "%sSetting KDE activity to %s ...",
                    $args{-dry_run} ? "[DRY-RUN]" : "",
                    $target_kde_activity;
                last if $args{-dry_run};
                require Desktop::KDEActivity::Util;
                my $res = Desktop::KDEActivity::Util::set_current_kde_activity(
                    name => $target_kde_activity);
                return [500, "Can't set current KDE activity: $res->[0] - $res->[1]"]
                    unless $res->[0] == 200;
            }

            if ($windowkey =~ /^firefox/) {

                my $i = 0;
                for my $item (@$items) {
                    $i++;
                    my $url = $item->{url};

                    my @ff_args;
                    my $env;
                    if ($i == 1) {
                        push @ff_args, "--new-window", $url;
                    } else {
                        push @ff_args, $url;
                    }

                    if (defined $item->{firefox_container}) {
                        $env->{FIREFOX_CONTAINER} = $item->{firefox_container};
                    }

                    log_trace "%sOpening URL %s in firefox (window %s) tab [#%d/%d]%s ...",
                        $dry_run ? "[DRY-RUN]" : "",
                        $url,
                        $windowkey,
                        $i,
                        scalar(@$items),
                        (defined $item->{firefox_container} ? " container $item->{firefox_container}" : "");
                    unless ($dry_run) {
                        IPC::System::Options::system(
                            {env=>$env, log=>1},
                            "firefox-container", @ff_args);
                    }
                } # for item

            } elsif ($windowkey =~ /^file_/) {

                my $i = 0;
                for my $item (@$items) {
                    $i++;
                    my $file = $item->{file};
                    log_trace "%sOpening file %s (window %s) ...",
                        $dry_run ? "[DRY-RUN]" : "",
                        $file,
                        $windowkey;
                    unless ($dry_run) {
                        Desktop::Open::open_desktop($file);
                    }
                } # for item

            } elsif ($windowkey =~ /^dolphin_/) {

                my $i = 0;
                my @urls;
                for my $item (@$items) {
                    $i++;
                    my $url = $item->{dir} // $item->{url};
                    push @urls, $url;
                }
                log_trace "%sOpening dirs %s (window %s) ...",
                    $dry_run ? "[DRY-RUN]" : "",
                    \@urls,
                    $windowkey;
                unless ($dry_run) {
                    IPC::System::Options::system(
                        {log=>1, shell=>1},
                        "dolphin", "--new-window", @urls, \"&");
                }

            } elsif ($windowkey =~ /^prog_/) {

                my $i = 0;
                for my $item (@$items) {
                    $i++;
                    my $prog = $item->{prog_name} // $item->{prog_path};
                    log_trace "%sOpening program %s (window %s) ...",
                        $dry_run ? "[DRY-RUN]" : "",
                        $prog,
                        $windowkey;
                    unless ($dry_run) {
                        IPC::System::Options::system(
                            {log=>1, shell=>1},
                            $prog, ($item->{prog_args} ? @{ $item->{prog_args} } : ()),
                            \"&");
                    }
                }

            } else {

                die "BUG: Unknown window type $windowkey";

            }

        } # for window

        [200];
    },
);

1;
# ABSTRACT: Utilities related to DesktopWorkspace

__END__

=pod

=encoding UTF-8

=head1 NAME

Desktop::Workspace::Util - Utilities related to DesktopWorkspace

=head1 VERSION

This document describes version 0.003 of Desktop::Workspace::Util (from Perl distribution Desktop-Workspace-Util), released on 2026-04-15.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 get_desktop_workspace_module

Usage:

 get_desktop_workspace_module(%args) -> any

Get the first Perl desktop workspace specification module.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<module>* => I<perl::modname>

(No description)

=item * B<ns_prefixes> => I<array[perl::modname|str]> (default: ["DesktopWorkspace",""])

List of namespaces to search for a Desktop Workspace specification modules.


=back

Return value:  (any)



=head2 instantiate_desktop_workspace_module

Usage:

 instantiate_desktop_workspace_module(%args) -> any

Instantiate the desktop workspace specification module (class).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<module>* => I<perl::modname>

(No description)

=item * B<module_args> => I<hash>

(No description)

=item * B<ns_prefixes> => I<array[perl::modname|str]> (default: ["DesktopWorkspace",""])

List of namespaces to search for a Desktop Workspace specification modules.


=back

Return value:  (any)



=head2 list_desktop_workspace_items

Usage:

 list_desktop_workspace_items(%args) -> [$status_code, $reason, $payload, \%result_meta]

List the items from desktop workspace specification module, with filtering options.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<bool>

Whether to include items that are not included by default (has property `include_by_default`=0).

=item * B<detail> => I<bool>

(No description)

=item * B<exclude_all_tags> => I<array[str]>

Exclude all items that have ALL tags specified.

=item * B<exclude_any_tags> => I<array[str]>

Exclude all items that have any tags specified.

=item * B<include_all_tags> => I<array[str]>

Include all items that have ALL tags specified.

=item * B<include_any_tags> => I<array[str]>

Include all items that have any tag specified.

=item * B<include_dir> => I<bool>

Whether to include dir items.

=item * B<include_file> => I<bool>

Whether to include file items.

=item * B<include_prog> => I<bool>

Whether to include program items.

=item * B<include_url> => I<bool>

Whether to include URL items.

=item * B<module>* => I<perl::modname>

(No description)

=item * B<module_args> => I<hash>

(No description)

=item * B<ns_prefixes> => I<array[perl::modname|str]> (default: ["DesktopWorkspace",""])

List of namespaces to search for a Desktop Workspace specification modules.

=item * B<query> => I<array[str]>

(No description)

=item * B<shuffle> => I<bool>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 open_desktop_workspace_items

Usage:

 open_desktop_workspace_items(%args) -> [$status_code, $reason, $payload, \%result_meta]

Open desktop workspace items.

This function is not exported by default, but exportable.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<bool>

Whether to include items that are not included by default (has property `include_by_default`=0).

=item * B<detail> => I<bool>

(No description)

=item * B<exclude_all_tags> => I<array[str]>

Exclude all items that have ALL tags specified.

=item * B<exclude_any_tags> => I<array[str]>

Exclude all items that have any tags specified.

=item * B<include_all_tags> => I<array[str]>

Include all items that have ALL tags specified.

=item * B<include_any_tags> => I<array[str]>

Include all items that have any tag specified.

=item * B<include_dir> => I<bool>

Whether to include dir items.

=item * B<include_file> => I<bool>

Whether to include file items.

=item * B<include_prog> => I<bool>

Whether to include program items.

=item * B<include_url> => I<bool>

Whether to include URL items.

=item * B<kde_activity> => I<str>

Switch to the specified KDE activity name.

Override's desktop workspace specification's C<kde_activity> property.

=item * B<module>* => I<perl::modname>

(No description)

=item * B<module_args> => I<hash>

(No description)

=item * B<ns_prefixes> => I<array[perl::modname|str]> (default: ["DesktopWorkspace",""])

List of namespaces to search for a Desktop Workspace specification modules.

=item * B<query> => I<array[str]>

(No description)

=item * B<reuse_window> => I<bool>

Do not open if existing window is detected.

=item * B<shuffle> => I<bool>

(No description)


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Desktop-Workspace-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Desktop-Workspace-Util>.

=head1 SEE ALSO

L<DesktopWorkspace>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords perlancar

perlancar <perlancar@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Desktop-Workspace-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
