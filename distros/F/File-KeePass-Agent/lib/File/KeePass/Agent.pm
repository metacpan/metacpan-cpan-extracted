#!/usr/bin/perl

=head1 NAME

File::KeePass::Agent - Application agent for working with File::KeePass objects

=cut

File::KeePass::Agent::run(),exit if $0 eq __FILE__;

package File::KeePass::Agent;

use strict;
use warnings;
use Carp qw(croak);
use File::KeePass '2.02';

our $VERSION = '2.01';
our @ISA;
BEGIN {
    my $os = lc($^O);
    if (! eval { require "File/KeePass/Agent/$os.pm" }) {
        croak "It appears that \"$os\" is not yet supported by ".__PACKAGE__.": $@";
    }
    @ISA = (__PACKAGE__."::$os");
}

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub run {
    my $self = ref($_[0]) ? shift() : __PACKAGE__->new;

    $self->init;

    # handle args coming in a multitude of ways
    my @pairs;
    if (@_) {
        my ($files, $passes) = @_;
        if (ref($_[0]) eq 'ARRAY') {
            push @pairs, [$files->[$_], $passes->[$_]] for 0 .. $#$files;
        } elsif (ref($_[0] eq 'HASH')) {
            push @pairs, map {[$_ => $files->{$_}]} sort keys %$files;
        } else {
            push @pairs, [$files, $passes]; # single file/pass set
        }
    } elsif (@ARGV) {
        for (my $i = 0; $i < @ARGV; $i++) {
            my $file = $ARGV[$i];
            next if $file =~ /^--?\w+$/;
            my %erg;
            while ($ARGV[$i+1] && $ARGV[$i+1] =~ /^--?(password|pass|keyfile)(?:(=)(.*))?$/) {
                $i++;
                $erg{$1} = $2 ? $3 : $ARGV[++$i];
            }
            my $pass = exists($erg{'password'}) ? $erg{'password'} : $erg{'pass'};
            $pass = [$pass, $erg{'keyfile'}] if exists($erg{'keyfile'});
            push @pairs, [$file, $pass];
        }
    } else {
        my $file = $self->prompt_for_file or die "Cannot continue without kdb file\n";
        push @pairs, map {[$_, undef]} glob $file;
    }
    die "No files given as input\n" if ! @pairs;

    # check file existence
    my @callbacks;
    for my $pair (@pairs) {
        my ($file, $pass) = @$pair;
        die "File \"$file\" does not exist\n" if ! -e $file;
        die "File \"$file\" does not appear to be readible\n" if ! -r $file;
        die "File \"$file\" does not appear to be a valid keepass db file\n" if ! -B $file;
    }
    OUTER: for my $pair (@pairs) {
        my ($file, $pass) = @$pair;
        my $k;
        if (! defined $pass) {
            $k = $self->_prompt_for_pass_and_key($file);
            print "Skipping file $file\n" if ! $k;
        } else {
            $k = $self->load_keepass($file, $pass);
        }
    }

    $self->main_loop;
}

sub _prompt_for_pass_and_key {
    my ($self, $file) = @_;
    while (1) {
        my $pass = $self->prompt_for_pass($file);
        if (! defined($pass) || !length($pass)) {
            my $keyfile = $self->prompt_for_keyfile($file);
            $pass = [$pass, $keyfile] if defined($keyfile) && length($keyfile);
        }
        my $k = eval { $self->load_keepass($file, $pass) };
        my $err = $@;
        if (! $k && defined($pass) && ref($pass) ne 'ARRAY' && length($pass)) {
            my $keyfile = $self->prompt_for_keyfile($file);
            if (defined($keyfile) && length($keyfile)) {
                $pass = [$pass, $keyfile];
                $k = eval { $self->load_keepass($file, $pass) };
                $err = $@;
            }
        }
        return if !defined($pass) || !length($pass);
        warn "Could not load database: $@" if ! $k;
        return $k if $k;
    }
}


sub load_keepass {
    my ($self, $file, $pass) = @_;
    my $kdb = $self->keepass_class->new;
    $kdb->load_db($file, $pass);
    push @{ $self->keepass }, [$file, $kdb];
    return $kdb;
}

sub keepass { shift->{'keepass'} ||= [] }

sub keepass_class { 'File::KeePass' }

sub unload_keepass {
    my ($self, $file) = @_;
    my $kdbs = $self->keepass;
    for my $i (0 .. $#$kdbs) {
        next if $kdbs->[$i]->[0] ne $file;
        splice @$kdbs, $i, 1, ();
        last;
    }
}

###----------------------------------------------------------------###

sub active_callbacks {
    my $self = shift;
    my @callbacks;
    foreach my $row ($self->active_entries) {
        my ($file, $entries) = @$row;
        foreach my $e (@$entries) {
            next if ! $e->{'comment'} || $e->{'comment'} !~ /^Custom-Global-Shortcut:\s*(.+?)\s*$/m;
            my %info = map {lc($_) => 1} split /[\s+-]+/, $1;
            my $at = (($e->{'auto_type'} || [])->[0] || {})->{'keys'} || '{PASSWORD}{ENTER}';
            my $s = {
                ctrl  => delete($info{'control'}) || delete($info{'cntrl'}) || delete($info{'ctrl'}),
                shift => delete($info{'shift'}) || delete($info{'shft'}),
                alt   => delete($info{'alt'}),
                win   => delete($info{'win'}),
            };
            my @keys = keys %info;
            if (@keys != 1) {
                croak "Cannot set global shortcut with more than one key (@keys) for entry \"$e->{'title'}\"\n";
            }
            $s->{'key'} = lc $keys[0];
            push @callbacks, [$s, "entry $e->{'title'}", sub {
                my ($self, $title, $event) = @_;
                return $self->do_auto_type({auto_type => $at, entry => $e, file => $file}, $title, $event);
            }];
        }
    }
    if (my $s = $self->read_config('global_shortcut')) {
        push @callbacks, [$s, 'global shortcut', 'search_auto_type'];
    }
    return @callbacks;
}

sub shortcut_name {
    my ($self, $s) = @_;
    my $mod = join("-", map {ucfirst $_} grep {$s->{$_}} qw(ctrl shift alt win));
    return $mod ? "$mod $s->{'key'}" : $s->{'key'};
}

sub active_entries {
    my $self = shift;
    my @rows;
    foreach my $pair (@{ $self->keepass }) {
        my ($file, $kdb) = @$pair;
        my @entries = $kdb->find_entries({active => 1, 'group_title !' => 'Backup', 'title !' => 'Meta-Info'});
        push @rows, [$file, \@entries] if @entries;
    }
    return @rows;
}

sub active_searches {
    my $self = shift;
    my $s = $self->{'active_searches'} ||= do {
        my @s;
        foreach my $row ($self->active_entries) {
            my ($file, $entries) = @$row;
            foreach my $e (@$entries) {
                foreach my $at (@{ $e->{'auto_type'} || [] }) {
                    my ($win, $keys) = @$at{qw(window keys)};
                    next if ! defined($win) || ! length($win);
                    if (! defined($keys) || ! length($keys)) {
                        my $kdb = (map {$_->[1]} grep {$_->[0] eq $file} @{ $self->keepass })[0];
                        my ($e2, $group) = $kdb->find_entry($e);
                        $keys = $group->{'auto_type_default'};
                        next if ! defined($keys) || ! length($keys);
                    }
                    $win = quotemeta($win);
                    $win =~ s{^\\\*}{.*};
                    $win =~ s{\\\*$}{.*};
                    $win = qr{^$win$};
                    push @s, {'qr' => $win, auto_type => $keys, file => $file, entry => $e};
                }
            }
        }
        \@s;
    };
    return @$s;
}

sub search_auto_type {
    my ($self, $title, $event) = @_;
    my @matches;
    foreach my $row ($self->active_searches) {
        next if $title !~ $row->{'qr'};
        push @matches, $row;
    }
    if (!@matches) {
        $self->do_no_match($title);
    }
    elsif (@matches > 1) {
        $self->do_auto_type_mult(\@matches, $title, $event);
    }
    else {
        $self->do_auto_type($matches[0], $title, $event);
    }
}

sub do_no_match {
    my ($self, $title) = @_;
    warn "No match for \"$title\"\n";
}

sub do_auto_type {
    my ($self, $match, $title, $event) = @_;
    my ($auto_type, $file, $entry) = @$match{qw(auto_type file entry)};
    $auto_type =~ s{ \{ TAB      \} }{\t}xg;
    $auto_type =~ s{ \{ ENTER    \} }{\n}xg;
    $auto_type =~ s{ \{ PASSWORD \} }{
        my %kdbs = map {$_->[0], $_->[1]} @{ $self->keepass };
        $kdbs{$file}->locked_entry_password($entry);
    }xeg;
    $auto_type =~ s{ \{ (\w+)    \} }{
        my $key = lc $1;
        defined($entry->{$key}) ? $entry->{$key} : return $self->do_auto_type_unsupported($key);
    }xeg;
    return if ! length $auto_type;
    return if $self->{'_last_send'} && time - $self->{'_last_send'} < 2;
    $self->{'_last_send'} = time;
    $self->send_key_press($auto_type, $entry, $title, $event);
}

sub do_auto_type_mult {
    my ($self, $matches, $title, $event) = @_;
    warn "Found multiple matches - using the first\n";
    $self->do_auto_type($matches->[0], $title, $event);
}

sub do_auto_type_unsupported {
    my ($self, $key) = @_;
    warn "Auto-type key \"$key\" is currently not supported.";
}

1;

__END__

=head1 SYNOPSIS

   use File::KeePass::Agent;
   File::KeePass::Agent->new->run($file, $pass);


   File::KeePass::Agent->new->run;  # will read from @ARGV or prompt


   File::KeePass::Agent::run();  # will read from @ARGV or prompt


   File::KeePass::Agent::run(\%files);  # file/pass pairs


   File::KeePass::Agent::run(\@files);

   File::KeePass::Agent::run(\@files, \@passes);  # parallel arrays


You may pass the name of the keepass filename that you would like to
open.  Otherwise you are prompted for the file to open.

You are then prompted for the password and/or the keyfile that will be
used to open the file.

See L<File::KeePass> for a listing of what KeyPass database features
are currently handled.

=head1 OS

File::KeePass::Agent (FKPA) will try to load a module based on the OS
returned by the $^O variable.  OS support during the initial releases
is very sparse.

=head1 FKPA OS API

The unix module variant contains documentation about what methods are
necessary to support the FKPA api.

See L<File::KeePass::Agent::unix/FKPA METHODS>.

=head1 METHODS

=over 4

=item C<new>

Returns an object blessed into the FKPA class.

=item C<run>

Reads the file, password, prints out a summary of the database, and
binds any shortcut keys.  Eventually, this will most likely support
more maintenance features.

=item C<keepass>

Returns an arrayref of arrayrefs continaing file and File::KeePass
object pairs.

=item C<shortcut_name>

Returns a human readable name from a shortcut hashref.

=item C<active_entries>

Finds current active entries from any of the open databases.

=item C<active_searches>

Parses the active searches and returns a listing of qr
matches/auto-type string/entry records.

=item C<search_auto_type>

Takes an window title and compares it against the current active searches.

=item C<do_no_match>

Called if search_auto_type didn't find a matching window.

=item C<do_auto_type>

Called if search_auto_type found a single match.

=item C<do_auto_type_mult>

Called if search_auto_type found multiple matching windows.

=item C<do_auto_type_unsupported>

Called when FKPA doesn't support an auto-type directive.

=back

=head1 GLOBAL SHORTCUTS

FKPA will read for the current global shortcut listed in the keepassx
configuration file.  At the moment this must first be configured using
keepassx itself.  Future support will allow for configuring this
through FKPA itself.

If this global shortcut is defined, when pressed it will call
search_auto_type to find entries matching against the current window
title.  If found, it will auto-type the matching entry.

Additionally, custom global shortcuts may defined in the comments
section of the FKP database entries.  They have the form:

   Custom-Global-Shortcut: Ctrl-Alt-Shift w

This allows for individual entry auto-typing to be called directly.

=head1 AUTOTYPE SUPPORT

Version 2 databases natively support auto-type entries.  Comment
sections of version 1 database entries may contain Auto-type entries
in the following form:

    Auto-Type-Window: Admin Login*
    Auto-Type-Window: Login*
    Auto-Type: {USERNAME}{TAB}{PASSWORD}{ENTER}

The Auto-Type-Window items are used to match against window titles.  You
may put a leading * and/or a trailing * on the item to allow for wildcard
matching.

If a window matches an Auto-Type-Window entry the corresponding
Auto-Type item will be processed and "auto-typed" to the current window.

Currently the following auto-type directives are supported:

=over 4

=item C<USERNAME>

The username for the entry.

=item C<PASSWORD>

The password for the entry.

=item C<URL>

The URL for the entry.

=item C<...>

All properties of the entry may be accessed.

=item C<TAB>

The tab character.

=item C<ENTER>

The enter character.

=back

=head1 STATUS

This module and program are proof of concept.  They work, but are
limited in their feature set.  There currently are no managment
capabilities.

=head1 AUTHOR

Paul Seamons <paul at seamons dot com>

=head1 LICENSE

This module may be distributed under the same terms as Perl itself.

=cut
