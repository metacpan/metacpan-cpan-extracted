package LibTmux::Snapshot;
use v5.44;
use LibTmux::Schema;
use LibTmux::Selection;
use LibTmux::PaneSelection;
use LibTmux::WindowSelection;
use LibTmux::WindowLinkSelection;
use LibTmux::SessionSelection;
use LibTmux::ClientSelection;

use LibTmux::Pane;
use LibTmux::Window;
use LibTmux::WindowLink;
use LibTmux::Session;
use LibTmux::Client;
use LibTmux::X;
my %plural = (
    session     => 'sessions',
    window      => 'windows',
    window_link => 'window_links',
    pane        => 'panes',
    client      => 'clients'
);

sub from_records ($class, %args) {
    my $self = bless {
        server_id  => $args{server_id}  // 'detached',
        generation => $args{generation} // 'detached',
        complete   => exists $args{complete} ? !!$args{complete} : true,
        records    => {},
        order      => {},
        loaded     => {},
        metadata   => {%{$args{metadata} // {}}},
    }, $class;
    for my $kind (sort keys %plural) {
        my $key = $plural{$kind};
        $self->{records}{$kind} = {};
        $self->{order}{$kind}   = [];
        $self->{loaded}{$kind}  = exists $args{$key};
        next unless exists $args{$key};
        LibTmux::X::InvalidArgument->throw(
            message => "$key must be an array reference")
            unless ref($args{$key}) eq 'ARRAY';
        for my $record ($args{$key}->@*) {
            LibTmux::X::InvalidArgument->throw(
                message => "$kind record must be a hash reference")
                unless ref($record) eq 'HASH';
            my %copy;
            for my $field (sort keys %$record) {
                my $spec = LibTmux::Schema->field($kind, $field);
                if ($spec && $spec->{type} ne 'relation') {
                    $copy{$field} = LibTmux::Schema->normalize(
                        $spec,          $record->{$field},
                        "$kind.$field", 'InvalidArgument'
                    );
                }
                elsif ($field eq 'window_id' || $field eq 'session_id') {
                    LibTmux::X::InvalidArgument->throw(
                        message => 'relation ID must be scalar')
                        if ref($record->{$field});
                    $copy{$field} = $record->{$field};
                }
                else {
                    LibTmux::X::InvalidArgument->throw(
                        message => "unknown record field $kind.$field");
                }
            }
            $copy{id} //= ($copy{session_id} // '') . ':' . ($copy{index} // '')
                if $kind eq 'window_link';
            my $id = $copy{id};
            LibTmux::X::InvalidArgument->throw(message => "invalid $kind ID")
                unless defined($id) && length($id) && $id !~ /\0/;
            my %prefix = (session => '\$', window => '\@', pane => '\%');
            LibTmux::X::InvalidArgument->throw(message => "invalid $kind ID")
                if exists $prefix{$kind}
                && $id !~ /\A(?:$prefix{$kind})[0-9]+\z/;
            LibTmux::X::InvalidArgument->throw(
                message => "duplicate physical $kind ID $id")
                if exists $self->{records}{$kind}{$id};
            $self->{records}{$kind}{$id} = \%copy;
            push $self->{order}{$kind}->@*, $id;
        }
    }
    if ($self->{complete}) {
        for my $kind (qw(pane window_link client)) {
            for my $record (values $self->{records}{$kind}->%*) {
                for my $edge (qw(window_id session_id)) {
                    next
                        unless exists $record->{$edge}
                        && defined $record->{$edge};
                    my $target = $edge eq 'window_id' ? 'window' : 'session';
                    LibTmux::X::AcquisitionRace->throw(
                        message => "missing $target relation for $kind")
                        unless
                        exists $self->{records}{$target}{$record->{$edge}};
                }
            }
        }
    }
    return $self;
}
sub server_id  ($self) { $self->{server_id} }
sub generation ($self) { $self->{generation} }
sub complete   ($self) { $self->{complete} }
sub metadata   ($self) { +{$self->{metadata}->%*} }

sub _handle ($self, $kind, $id) {
    return undef unless defined $id && exists $self->{records}{$kind}{$id};
    return LibTmux::Schema->class_for($kind)->_new($self, $kind, $id);
}

sub _selection ($self, $kind, $ids = undef) {
    LibTmux::X::Unloaded->throw(message => "$kind collection was not loaded")
        unless $self->{loaded}{$kind};
    return LibTmux::Schema->selection_for($kind)
        ->new(map { $self->_handle($kind, $_) }
            ($ids // $self->{order}{$kind})->@*);
}

sub _read ($self, $kind, $id, $field) {
    my $spec = LibTmux::Schema->field($kind, $field);
    LibTmux::X::InvalidArgument->throw(message => "unknown field $kind.$field")
        unless $spec;
    my $record = $self->{records}{$kind}{$id};
    if ($spec->{type} ne 'relation') {
        if (
               defined($self->{metadata}{version})
            && defined($spec->{minimum})
            && !LibTmux::Schema->_version_at_least(
                $self->{metadata}{version},
                $spec->{minimum}
            )
            )
        {
            LibTmux::X::Unsupported->throw(
                path    => "$kind.$field",
                message => 'field requires tmux ' . $spec->{minimum}
            );
        }

        LibTmux::X::Unloaded->throw(
            path    => "$kind.$field",
            entity  => $kind,
            message => 'field was not loaded'
        ) unless exists $record->{$field};
        return $record->{$field};
    }
    LibTmux::X::Unloaded->throw(
        path    => "$kind.$field",
        message => 'relation is incomplete'
    ) unless $self->{complete};
    my $target = $spec->{entity};
    LibTmux::X::Unloaded->throw(
        path    => "$kind.$field",
        message => 'relation collection was not loaded'
    ) unless $self->{loaded}{$target};
    if ($spec->{many}) {
        my $edge = $kind eq 'session' ? 'session_id' : 'window_id';
        for my $child (values $self->{records}{$target}->%*) {
            LibTmux::X::Unloaded->throw(
                path    => "$kind.$field",
                message => 'child relation membership was not loaded'
            ) unless exists($child->{$edge}) && defined($child->{$edge});
        }
        my @ids = CORE::grep {
            my $r = $self->{records}{$target}{$_};
            (
                $kind eq 'session'
                ? ($r->{session_id} // '')
                : ($r->{window_id}  // '')
            ) eq $id
        } $self->{order}{$target}->@*;
        return $self->_selection($target, \@ids);
    }
    if ($field eq 'active_pane') {
        my @active;
        for my $pid ($self->{order}{pane}->@*) {
            LibTmux::X::Unloaded->throw(
                path    => "$kind.$field",
                message => 'pane relation membership was not loaded'
                )
                unless exists($self->{records}{pane}{$pid}{window_id})
                && defined($self->{records}{pane}{$pid}{window_id});
            next unless ($self->{records}{pane}{$pid}{window_id} // '') eq $id;
            push @active, $pid if $self->_read('pane', $pid, 'active');
        }
        LibTmux::X::AcquisitionRace->throw(
            message => 'more than one active pane in physical window')
            if @active > 1;
        return $self->_handle('pane', $active[0]);
    }
    my $foreign = $target . '_id';
    LibTmux::X::Unloaded->throw(
        path    => "$kind.$field",
        message => 'relation ID was not loaded'
    ) unless exists $record->{$foreign};
    return undef if !defined($record->{$foreign}) && $spec->{nullable};
    my $handle = $self->_handle($target, $record->{$foreign});
    LibTmux::X::Unloaded->throw(
        path    => "$kind.$field",
        message => 'related entity was not loaded'
    ) unless $handle;
    return $handle;
}
sub sessions      ($self)      { $self->_selection('session') }
sub windows       ($self)      { $self->_selection('window') }
sub window_links  ($self)      { $self->_selection('window_link') }
sub panes         ($self)      { $self->_selection('pane') }
sub clients       ($self)      { $self->_selection('client') }
sub session_by_id ($self, $id) { $self->_handle('session', $id) }
sub window_by_id  ($self, $id) { $self->_handle('window',  $id) }
sub pane_by_id    ($self, $id) { $self->_handle('pane',    $id) }

sub to_records ($self) {
    my %out = (
        server_id  => $self->server_id,
        generation => $self->generation,
        complete   => $self->complete
    );
    for my $kind (sort keys %plural) {
        next unless $self->{loaded}{$kind};
        $out{$plural{$kind}} = [map { +{%{$self->{records}{$kind}{$_}}} }
                $self->{order}{$kind}->@*];
    }
    return \%out;
}

=head1 NAME

LibTmux::Snapshot - Captured graph with explicit completeness

=head1 METHODS

=head2 from_records

C<from_records(server_id =E<gt> ..., generation =E<gt> ..., sessions =E<gt> [...], windows =E<gt> [...], window_links =E<gt> [...], panes =E<gt> [...], clients =E<gt> [...])> constructs a detached graph. Scalar records and relation IDs are copied. Omitted fields/collections remain unloaded; null is explicit. Invalid identities or inconsistent complete topology throw typed acquisition errors.

=head2 server_id

Return the captured server scope. Entity IDs are meaningful only within this scope and L</generation>.

=head2 generation

Return the captured daemon generation. L<LibTmux::Server> checks it before mutations through captured handles; retained snapshots never silently refresh.

=head2 complete

Return the capture completeness Boolean. The strict live acquisition path fails on incomplete topology; it does not synthesize empty relations.

=head2 metadata

Return a fresh metadata hash with capture start/end, daemon version, and PID where acquired. Several commands observe an interval; the snapshot is not an atomic tmux transaction.

=head2 sessions

Return a fresh L<LibTmux::SessionSelection> in captured order. Empty loaded collections yield empty selections; unloaded collections throw.

=head2 windows

Return a fresh L<LibTmux::WindowSelection> containing each physical window identity once. Context lives in L</window_links>.

=head2 window_links

Return a fresh L<LibTmux::WindowLinkSelection> retaining every session/index association, including repeated links of one physical window.

=head2 panes

Return a fresh L<LibTmux::PaneSelection> containing each physical pane identity once. Membership edits cannot change the graph store.

=head2 clients

Return a fresh L<LibTmux::ClientSelection> in captured order. A loaded empty client set is valid.

=head2 session_by_id

C<session_by_id('$1')> returns a L<LibTmux::Session> or undef. Single quotes preserve the dollar-prefixed ID instead of interpolating a regex capture.

=head2 window_by_id

C<window_by_id('@3')> returns one physical L<LibTmux::Window> or undef, independent of session link context.

=head2 pane_by_id

C<pane_by_id('%3')> returns a L<LibTmux::Pane> or undef. The returned handle retains the captured graph after this wrapper goes out of scope.

=head2 to_records

Return independent scalar records and adjacency IDs for detached use. No handles or live transport are serialized.

=head1 EXECUTION

All methods in this module operate on local captured data and perform no tmux
I/O. Ordering is deterministic; public query methods do not mutate membership.
Typed validation/evaluation errors propagate. See L<LibTmux::Server/snapshot>
for explicit acquisition and L<LibTmux::X> for machine-readable failures.

=cut
