use v5.40;
use blib;
use FindBin;
use LibUI                  qw[:all];
use Affix                  qw[:all];
use Net::BitTorrent::Types qw[:state];
use File::Spec;
use POSIX qw(strftime);
use threads;
use threads::shared;
use Thread::Queue;
use Time::HiRes qw[gettimeofday tv_interval];
use JSON::PP    qw[encode_json decode_json];
my $lib = Alien::libui->dynamic_libs;
#
use constant {
    COL_NAME            => 0,
    COL_PROGRESS        => 1,
    COL_STATUS          => 2,
    COL_DOWN            => 3,
    COL_UP              => 4,
    COL_PEERS           => 5,
    COL_SIZE            => 6,
    NUM_COLUMNS         => 7,
    PEER_COL_IP         => 0,
    PEER_COL_PORT       => 1,
    PEER_COL_DOWN       => 2,
    PEER_COL_UP         => 3,
    PEER_COLSeeder      => 4,
    PEER_COLUMNS        => 5,
    CONTENT_COL_NAME    => 0,
    CONTENT_COL_SIZE    => 1,
    CONTENT_COL_ENABLED => 2,
    CONTENT_COLUMNS     => 3,
    COLUMN_TYPE_STRING  => 0,
    COLUMN_TYPE_INT     => 2,
    MAX_LOG_LINES       => 500,
};

#  Shared state created BEFORE any closures
our $shared_json          : shared = '';
our $snapshot_seq         : shared = 0;
our $shared_peers_json    : shared = '';
our $shared_files_json    : shared = '';
our $shared_trackers_json : shared = '';
our $bt_ready             : shared = 0;
our $cmd_queue = Thread::Queue->new;
our $log_queue = Thread::Queue->new;

#  BT thread code as a string whichis compiled fresh in child interpreter to avoid crashing perl_clone
my $BT_THREAD_CODE = <<'END_BT_CODE';
use v5.40;
use Net::BitTorrent;
use Net::BitTorrent::Types qw[:state];
use File::Spec;
use File::Basename;
use JSON::PP qw[encode_json decode_json];
use Digest::SHA qw[sha1];
use Path::Tiny qw[path];
use threads;
use threads::shared;
use Thread::Queue;
use Time::HiRes qw[gettimeofday tv_interval];
use POSIX qw(strftime);

my $cmd_queue = $main::cmd_queue;    # inherited from parent via interpreter clone
my $log_queue = $main::log_queue;

sub bt_log {
    my $line = strftime( '[%H:%M:%S]', localtime ) . " [BT] $_[0]";
    $log_queue->enqueue($line);
}

sub format_state_bt {
    return 'Stopped'  if $_[0] == STATE_STOPPED;
    return 'Starting' if $_[0] == STATE_STARTING;
    return 'Running'  if $_[0] == STATE_RUNNING;
    return 'Paused'   if $_[0] == STATE_PAUSED;
    return 'Metadata' if $_[0] == STATE_METADATA;
    return 'Unknown';
}

sub infohash_hex_bt {
    my $ih = $_[0]->infohash_v1();
    return unpack( 'H*', $ih ) if $ih;
    $ih = $_[0]->infohash_v2();
    return unpack( 'H*', $ih ) if $ih;
    return '?';
}

sub format_bytes_bt {
    return '0 B' if !defined $_[0] || $_[0] == 0;
    my @u = qw(B KB MB GB TB);
    my ($v, $i) = ($_[0], 0);
    while ( $v >= 1024 && $i < $#u ) { $v /= 1024; $i++ }
    return sprintf( '%.1f %s', $v, $u[$i] );
}

sub format_speed_bt {
    return '0 B/s' if !defined $_[0] || $_[0] == 0;
    return format_bytes_bt($_[0]) . '/s';
}

# --- Main BT thread entry ---
my $client = Net::BitTorrent->new(
    port       => 6881,
    encryption => 1,
    bep05      => 1,
    bep09      => 1,
    bep11      => 1,
    debug      => 1,
);

my $session_dir   = File::Spec->catdir( $FindBin::Bin, '.session' );
my $state_file    = File::Spec->catfile( $session_dir, 'state.json' );
my $manifest_file = File::Spec->catfile( $session_dir, 'manifest.json' );
my $dl_dir        = File::Spec->catdir( $FindBin::Bin, 'downloads' );
mkdir $dl_dir unless -d $dl_dir;

# Load manifest
my @manifest;
if ( -f $manifest_file ) {
    eval {
        open my $fh, '<', $manifest_file or die "open: $!";
        local $/; my $raw = <$fh>; close $fh;
        @manifest = @{ decode_json($raw) };
    };
    bt_log('Loaded manifest: ' . scalar(@manifest) . ' entries');
}

$client->on( 'log', sub ( $emitter, @args ) {
    my %data = @args;
    my $msg  = $data{log}  // '';
    my $lvl = $data{level} // 'debug';
    $log_queue->enqueue("[NBT $lvl] $msg") if $msg;
});

# Restore torrents
if (@manifest) {
    for my $entry (@manifest) {
        eval {
            if ( $entry->{type} eq 'file' && -f $entry->{path} ) {
                $client->add_torrent( $entry->{path}, $dl_dir );
            }
            elsif ( $entry->{type} eq 'magnet' && $entry->{uri} ) {
                $client->add_magnet( $entry->{uri}, $dl_dir );
            }
        };
        bt_log("restore ERROR: $@") if $@;
    }
}
if ( -f $state_file ) {
    eval { $client->load_state($state_file) };
    bt_log("load_state ERROR: $@") if $@;
}

# Auto-start
{
    my %manifest_ihs;
    for my $entry (@manifest) {
        if ( $entry->{type} eq 'magnet' && $entry->{uri} ) {
            if ( $entry->{uri} =~ /xt=urn:btih:([a-fA-F0-9]{40})/i ) {
                $manifest_ihs{lc $1} = 1;
            }
        }
    }
    for my $t ( $client->torrents()->@* ) {
        eval {
            my $should_start = 0;
            if ( $t->state() == STATE_RUNNING || $t->state() == STATE_METADATA ) {
                $should_start = 1;
            }
            elsif ( $t->state() == STATE_STOPPED ) {
                my $ih = $t->infohash_v1();
                $should_start = 1 if $ih && $manifest_ihs{ lc unpack( 'H*', $ih ) };
            }
            if ($should_start) {
                bt_log('Auto-starting: ' . ( $t->name() // '?' ));
                $t->stop();
                $t->start();
            }
        };
        bt_log("auto-start ERROR: $@") if $@;
    }
}

# Save manifest
eval {
    open my $fh, '>', $manifest_file or die "open: $!";
    print $fh encode_json( \@manifest );
    close $fh;
};

bt_log('Client ready, entering main loop.');
$bt_ready = 1;

my $shutdown = 0;

# ---- Main loop ----
my $last_tick = [gettimeofday()];
while ( !$shutdown ) {
    # Drain commands
    while ( my $cmd = $cmd_queue->dequeue_nb() ) {
        my ( $action, @args ) = @$cmd;

        if ( $action eq 'add_magnet' ) {
            eval { $client->add_magnet( $args[0], $dl_dir ) };
            if ($@) { bt_log("add_magnet ERROR: $@") }
            else {
                bt_log('Added magnet: ' . substr( $args[0], 0, 80 ) . '...');
                push @manifest, { type => 'magnet', uri => $args[0] };
                eval {
                    open my $fh, '>', $manifest_file or die;
                    print $fh encode_json(\@manifest); close $fh;
                };
            }
        }
        elsif ( $action eq 'add_file' ) {
            eval { $client->add_torrent( $args[0], $dl_dir ) };
            if ($@) { bt_log("add_torrent ERROR: $@") }
            else {
                bt_log('Added file: ' . File::Basename::basename( $args[0] ));
                push @manifest, { type => 'file', path => $args[0] };
                eval {
                    open my $fh, '>', $manifest_file or die;
                    print $fh encode_json(\@manifest); close $fh;
                };
            }
        }
        elsif ( $action eq 'start' ) {
            my $t = $client->torrents_hash()->{ pack( 'H*', $args[0] ) };
            if ($t) { eval { $t->start() }; bt_log("start ERROR: $@") if $@ }
        }
        elsif ( $action eq 'stop' ) {
            my $t = $client->torrents_hash()->{ pack( 'H*', $args[0] ) };
            if ($t) { eval { $t->stop() }; bt_log("stop ERROR: $@") if $@ }
        }
        elsif ( $action eq 'pause' ) {
            my $t = $client->torrents_hash()->{ pack( 'H*', $args[0] ) };
            if ($t) { eval { $t->pause() if $t->is_running() }; bt_log("pause ERROR: $@") if $@ }
        }
        elsif ( $action eq 'resume' ) {
            my $t = $client->torrents_hash()->{ pack( 'H*', $args[0] ) };
            if ($t) { eval { $t->resume() }; bt_log("resume ERROR: $@") if $@ }
        }
        elsif ( $action eq 'remove' ) {
            my $ih_hex = $args[0];
            my $t = $client->torrents_hash()->{ pack( 'H*', $ih_hex ) };
            if ($t) {
                eval { $client->remove_torrent($t) };
                bt_log("remove ERROR: $@") if $@;
                @manifest = grep {
                    !(
                           ( $_->{type} eq 'magnet' && defined $_->{uri} && $_->{uri} =~ /$ih_hex/i )
                        || ( $_->{type} eq 'file' && -f ( $_->{path} // '' )
                            && unpack( 'H*', sha1( path( $_->{path} )->slurp_raw ) ) eq $ih_hex )
                    )
                } @manifest;
                eval {
                    open my $fh, '>', $manifest_file or die;
                    print $fh encode_json(\@manifest); close $fh;
                };
            }
        }
        elsif ( $action eq 'shutdown' ) {
            bt_log('Shutdown requested.');
            $shutdown = 1;
            last;
        }
    }

    # Tick
    my $now = [gettimeofday()];
    my $dt  = tv_interval($last_tick);
    eval { $client->tick($dt) };
    bt_log("TICK ERROR: $@") if $@;
    $last_tick = $now;

    # Snapshot status for UI
    my @new_display;
    my @new_peers;
    my @new_files;
    my @new_trackers;

    for my $t ( $client->torrents()->@* ) {
        my $ih   = infohash_hex_bt($t);
        my $name = $t->name() // $ih;
        my $prog = $t->progress() // 0;
        my $total = 0;
        eval { $total = $t->total_size() // 0 };
        my $dl = $t->bytes_downloaded() // 0;
        my $ul = $t->bytes_uploaded()   // 0;
        my $sd = $t->speed_down()       // 0;
        my $su = $t->speed_up()         // 0;
        my $np = $t->num_peers()        // 0;
        my $ns = $t->num_seeds()        // 0;
        my $st = 'Unknown';
        eval { $st = format_state_bt( $t->state() ) };

        push @new_display, {
            name     => $name,
            progress => int($prog),
            status   => $st,
            down     => format_speed_bt($sd),
            up       => format_speed_bt($su),
            peers    => "$ns/$np",
            size     => format_bytes_bt($total),
            dl_total => format_bytes_bt($dl),
            ul_total => format_bytes_bt($ul),
            ih_hex   => $ih,
        };
    }
    $shared_json = encode_json(\@new_display);
    $snapshot_seq++;

    # Detail data for first torrent
    if (@new_display) {
        my @tlist = $client->torrents()->@*;
        my $t = $tlist[0];
        eval {
            my $trackers = $t->trackers();
            if ( $trackers && @$trackers ) {
                @new_trackers = map { ref $_ ? ( $_->{url} // $_->{announce} // '?' ) : "$_" } @$trackers;
            }
        };
        eval {
            my $peers = $t->peer_objects();
            if ($peers) {
                for my $p ( $peers->@* ) {
                    push @new_peers, {
                        ip     => $p->ip()   // '?',
                        port   => $p->port() // '?',
                        down   => format_speed_bt( $p->rate_down() // 0 ),
                        up     => format_speed_bt( $p->rate_up()   // 0 ),
                        seeder => ( $p->is_seeder() ? 'Yes' : 'No' ),
                    };
                }
            }
        };
        eval {
            my $files = $t->files();
            if ($files) {
                for my $f ( $files->@* ) {
                    my $size = -s $f;
                    push @new_files, {
                        name => File::Basename::basename($f),
                        size => defined $size ? format_bytes_bt($size) : 'Unknown'
                    };
                }
            }
        };
    }
    $shared_peers_json    = encode_json(\@new_peers);
    $shared_files_json    = encode_json(\@new_files);
    $shared_trackers_json = encode_json(\@new_trackers);

    select( undef, undef, undef, 0.05 );    # 50ms sleep
}

# Shutdown
bt_log('Saving state...');
eval { $client->save_state($state_file) } if $state_file;
eval { $client->shutdown() };
bt_log('BT thread exiting.');
threads->exit();
END_BT_CODE

#  Main thread globals (NOT shared, UI thread only)
my $mainwin;
my $table;
my $table_model;
my $selected_row         = -1;
my $last_snapshot        = 0;
my $peer_refresh_counter = 0;

# Log tab
my $log_entry;
my @log_lines;

# Detail tab label refs
my (
    $lbl_detail_name,     $lbl_detail_hash, $lbl_detail_size, $lbl_detail_progress, $lbl_detail_downloaded,
    $lbl_detail_uploaded, $lbl_detail_down, $lbl_detail_up,   $lbl_detail_peers,    $lbl_detail_seeds
);
my $lbl_trackers;

# Peer table
my $peer_model;
my @peer_data;

# Content table
my $content_model;
my @content_data;

# Display data (UI-local mirror)
my @display;

# Session persistence (UI-side for manifest display)
my $session_dir;
my $state_file;
my $manifest_file;

#  Logging on the main thread
sub log_msg($msg) {
    my $ts   = POSIX::strftime( '%H:%M:%S', localtime );
    my $line = "[$ts] $msg";
    push @log_lines, $line;
    shift @log_lines while @log_lines > MAX_LOG_LINES;
    uiMultilineEntryAppend( $log_entry, $line . "\n" ) if $log_entry;
    say $line;
}

# Utils
sub format_bytes($bytes) {
    return '0 B' if !defined $bytes || $bytes == 0;
    my @units = qw(B KB MB GB TB);
    my $i     = 0;
    my $val   = $bytes;
    while ( $val >= 1024 && $i < $#units ) { $val /= 1024; $i++ }
    return sprintf( '%.1f %s', $val, $units[$i] );
}

sub format_speed($bps) {
    return '0 B/s' if !defined $bps || $bps == 0;
    return format_bytes($bps) . '/s';
}

sub _clear_table( $model, $data_ref ) {
    while (@$data_ref) {
        pop @$data_ref;
        uiTableModelRowDeleted( $model, scalar @$data_ref );
    }
}

#  Table model handlers (main UI thread only)
my $main_handler = {
    NumColumns => sub ( $h, $m ) { return NUM_COLUMNS },
    ColumnType => sub ( $h, $m, $col ) {
        return COLUMN_TYPE_INT if $col == COL_PROGRESS;
        return COLUMN_TYPE_STRING;
    },
    NumRows   => sub ( $h, $m ) { return scalar @display },
    CellValue => sub ( $h, $m, $row, $col ) {
        return uiNewTableValueString('') if $row < 0 || $row >= scalar @display;
        my $d = $display[$row];
        return uiNewTableValueString('') unless ref $d && ref $d eq 'HASH';
        if    ( $col == COL_NAME )     { return uiNewTableValueString( $d->{name}   // '' ); }
        elsif ( $col == COL_PROGRESS ) { return uiNewTableValueInt( $d->{progress}  // 0 ); }
        elsif ( $col == COL_STATUS )   { return uiNewTableValueString( $d->{status} // '' ); }
        elsif ( $col == COL_DOWN )     { return uiNewTableValueString( $d->{down}   // '' ); }
        elsif ( $col == COL_UP )       { return uiNewTableValueString( $d->{up}     // '' ); }
        elsif ( $col == COL_PEERS )    { return uiNewTableValueString( $d->{peers}  // '' ); }
        elsif ( $col == COL_SIZE )     { return uiNewTableValueString( $d->{size}   // '' ); }
        return uiNewTableValueString('');
    },
    SetCellValue => sub ( $h, $m, $row, $col, $v ) { },
};
my $peer_handler = {
    NumColumns => sub ( $h, $m ) { return PEER_COLUMNS },
    ColumnType => sub ( $h, $m, $col ) { return COLUMN_TYPE_STRING },
    NumRows    => sub ( $h, $m ) { return scalar @peer_data },
    CellValue  => sub ( $h, $m, $row, $col ) {
        my $d    = $peer_data[$row] // {};
        my @keys = qw(ip port down up seeder);
        my $key  = $keys[$col] // '';
        return uiNewTableValueString( $d->{$key} // '' );
    },
    SetCellValue => sub ( $h, $m, $row, $col, $v ) { },
};
my $content_handler = {
    NumColumns => sub ( $h, $m ) { return CONTENT_COLUMNS },
    ColumnType => sub ( $h, $m, $col ) { return COLUMN_TYPE_STRING },
    NumRows    => sub ( $h, $m ) { return scalar @content_data },
    CellValue  => sub ( $h, $m, $row, $col ) {
        my $d = $content_data[$row] // {};
        if    ( $col == CONTENT_COL_NAME ) { return uiNewTableValueString( $d->{name} // '' ); }
        elsif ( $col == CONTENT_COL_SIZE ) { return uiNewTableValueString( $d->{size} // '' ); }
        elsif ( $col == CONTENT_COL_ENABLED ) {
            return uiNewTableValueString( ( $d->{enabled} // 1 ) ? '1' : '0' );
        }
        return uiNewTableValueString('');
    },
    SetCellValue => sub ( $h, $m, $row, $col, $v ) {
        if ( $col == CONTENT_COL_ENABLED && defined $content_data[$row] ) {
            $content_data[$row]{enabled} = ( uiTableValueString($v) // '0' ) eq '1' ? 1 : 0;
        }
    },
};

#  Session management helpers
sub _init_session_files() {
    $session_dir = File::Spec->catdir( $FindBin::Bin, '.session' );
    mkdir $session_dir unless -d $session_dir;
    $state_file    = File::Spec->catfile( $session_dir, 'state.json' );
    $manifest_file = File::Spec->catfile( $session_dir, 'manifest.json' );
}

#  Detail tab builders
sub _make_row( $parent, $label ) {
    my $hbox = uiNewHorizontalBox();
    uiBoxSetPadded( $hbox, 1 );
    uiBoxAppend( $parent, $hbox,                 0 );
    uiBoxAppend( $hbox,   uiNewLabel("$label:"), 0 );
    my $val = uiNewLabel('-');
    uiBoxAppend( $hbox, $val, 1 );
    return $val;
}

sub build_details_tab() {
    my $vbox = uiNewVerticalBox();
    uiBoxSetPadded( $vbox, 1 );
    $lbl_detail_name       = _make_row( $vbox, 'Name' );
    $lbl_detail_hash       = _make_row( $vbox, 'Info Hash' );
    $lbl_detail_size       = _make_row( $vbox, 'Size' );
    $lbl_detail_progress   = _make_row( $vbox, 'Progress' );
    $lbl_detail_downloaded = _make_row( $vbox, 'Downloaded' );
    $lbl_detail_uploaded   = _make_row( $vbox, 'Uploaded' );
    $lbl_detail_down       = _make_row( $vbox, 'Down Speed' );
    $lbl_detail_up         = _make_row( $vbox, 'Up Speed' );
    $lbl_detail_peers      = _make_row( $vbox, 'Peers' );
    $lbl_detail_seeds      = _make_row( $vbox, 'Seeds' );
    return $vbox;
}

sub build_trackers_tab() {
    my $vbox = uiNewVerticalBox();
    uiBoxSetPadded( $vbox, 1 );
    uiBoxAppend( $vbox, uiNewLabel('Tracker URLs:'), 0 );
    $lbl_trackers = uiNewLabel('-');
    uiBoxAppend( $vbox, $lbl_trackers, 1 );
    return $vbox;
}

sub build_peers_tab() {
    $peer_model = uiNewTableModel($peer_handler);
    my $params     = { Model => $peer_model, RowBackgroundColorModelColumn => -1 };
    my $peer_table = uiNewTable($params);
    uiTableAppendTextColumn( $peer_table, 'IP',     PEER_COL_IP,    -1, undef );
    uiTableAppendTextColumn( $peer_table, 'Port',   PEER_COL_PORT,  -1, undef );
    uiTableAppendTextColumn( $peer_table, 'Down',   PEER_COL_DOWN,  -1, undef );
    uiTableAppendTextColumn( $peer_table, 'Up',     PEER_COL_UP,    -1, undef );
    uiTableAppendTextColumn( $peer_table, 'Seeder', PEER_COLSeeder, -1, undef );
    return $peer_table;
}

sub build_content_tab() {
    $content_model = uiNewTableModel($content_handler);
    my $params        = { Model => $content_model, RowBackgroundColorModelColumn => -1 };
    my $content_table = uiNewTable($params);
    uiTableAppendCheckboxTextColumn( $content_table, 'File', CONTENT_COL_ENABLED, -1, CONTENT_COL_NAME, -1, undef );
    uiTableAppendTextColumn( $content_table, 'Size', CONTENT_COL_SIZE, -1, undef );
    uiTableSetSelectionMode( $content_table, 0 );
    return $content_table;
}

sub build_log_tab() {
    $log_entry = uiNewNonWrappingMultilineEntry();
    uiMultilineEntrySetReadOnly( $log_entry, 1 );
    return $log_entry;
}

# ============================================================================
#  UI Construction
# ============================================================================
sub onClosing( $w, $data ) {
    log_msg('Closing...');
    $cmd_queue->enqueue( ['shutdown'] );
    sleep(1);
    uiQuit();
    return 1;
}

sub shouldQuit($data) {
    $cmd_queue->enqueue( ['shutdown'] );
    sleep(1);
    return 1;
}

sub build_ui() {
    my $mnu_file      = uiNewMenu('File');
    my $mi_add_file   = uiMenuAppendItem( $mnu_file, 'Add Torrent File...' );
    my $mi_add_magnet = uiMenuAppendItem( $mnu_file, 'Add Magnet URI...' );
    uiMenuAppendSeparator($mnu_file);
    uiMenuAppendQuitItem($mnu_file);
    my $mnu_torrent = uiNewMenu('Torrent');
    my $mi_start    = uiMenuAppendItem( $mnu_torrent, 'Start' );
    my $mi_stop     = uiMenuAppendItem( $mnu_torrent, 'Stop' );
    my $mi_pause    = uiMenuAppendItem( $mnu_torrent, 'Pause' );
    my $mi_resume   = uiMenuAppendItem( $mnu_torrent, 'Resume' );
    uiMenuAppendSeparator($mnu_torrent);
    my $mi_remove = uiMenuAppendItem( $mnu_torrent, 'Remove' );
    my $mnu_help  = uiNewMenu('Help');
    my $mi_about  = uiMenuAppendAboutItem($mnu_help);
    $mainwin = uiNewWindow( 'Affix BitTorrent [Threaded]', 950, 700, 0 );
    uiWindowSetMargined( $mainwin, 1 );
    uiWindowOnClosing( $mainwin, \&onClosing, undef );
    uiOnShouldQuit( \&shouldQuit, undef );
    my $vbox = uiNewVerticalBox();
    uiBoxSetPadded( $vbox, 1 );
    uiWindowSetChild( $mainwin, $vbox );
    my $hbox_toolbar = uiNewHorizontalBox();
    uiBoxSetPadded( $hbox_toolbar, 1 );
    uiBoxAppend( $vbox, $hbox_toolbar, 0 );
    my $btn_add_file   = uiNewButton('Add File...');
    my $btn_add_magnet = uiNewButton('Add Magnet...');
    my $btn_start      = uiNewButton('Start');
    my $btn_stop       = uiNewButton('Stop');
    my $btn_pause      = uiNewButton('Pause');
    my $btn_resume     = uiNewButton('Resume');
    my $btn_remove     = uiNewButton('Remove');

    for my $b ( $btn_add_file, $btn_add_magnet ) {
        uiBoxAppend( $hbox_toolbar, $b, 0 );
    }
    uiBoxAppend( $hbox_toolbar, uiNewHorizontalSeparator(), 0 );
    for my $b ( $btn_start, $btn_stop, $btn_pause, $btn_resume ) {
        uiBoxAppend( $hbox_toolbar, $b, 0 );
    }
    uiBoxAppend( $hbox_toolbar, uiNewHorizontalSeparator(), 0 );
    uiBoxAppend( $hbox_toolbar, $btn_remove,                0 );
    $table_model = uiNewTableModel($main_handler);
    my $params = { Model => $table_model, RowBackgroundColorModelColumn => -1 };
    $table = uiNewTable($params);
    uiTableAppendTextColumn( $table, 'Name', COL_NAME, -1, undef );
    uiTableAppendProgressBarColumn( $table, 'Progress', COL_PROGRESS );
    uiTableAppendTextColumn( $table, 'Status', COL_STATUS, -1, undef );
    uiTableAppendTextColumn( $table, 'Down',   COL_DOWN,   -1, undef );
    uiTableAppendTextColumn( $table, 'Up',     COL_UP,     -1, undef );
    uiTableAppendTextColumn( $table, 'Peers',  COL_PEERS,  -1, undef );
    uiTableAppendTextColumn( $table, 'Size',   COL_SIZE,   -1, undef );
    uiTableSetSelectionMode( $table, 1 );
    uiBoxAppend( $vbox, $table, 1 );
    my $tab = uiNewTab();
    uiTabAppend( $tab, 'Details',  build_details_tab() );
    uiTabAppend( $tab, 'Trackers', build_trackers_tab() );
    uiTabAppend( $tab, 'Peers',    build_peers_tab() );
    uiTabAppend( $tab, 'Content',  build_content_tab() );
    uiTabAppend( $tab, 'Log',      build_log_tab() );
    uiBoxAppend( $vbox, $tab, 1 );
    my $selected_ih_hex = sub {
        return undef if $selected_row < 0 || $selected_row >= scalar @display;
        return $display[$selected_row]{ih_hex};
    };
    uiMenuItemOnClicked( $mi_add_file,   sub { _do_add_file() },       undef );
    uiMenuItemOnClicked( $mi_add_magnet, sub { show_magnet_dialog() }, undef );
    uiMenuItemOnClicked(
        $mi_start,
        sub {
            my $ih = $selected_ih_hex->();
            if ($ih) { $cmd_queue->enqueue( [ 'start', $ih ] ); log_msg("start: $ih"); }
        },
        undef
    );
    uiMenuItemOnClicked(
        $mi_stop,
        sub {
            my $ih = $selected_ih_hex->();
            if ($ih) { $cmd_queue->enqueue( [ 'stop', $ih ] ); log_msg("stop: $ih"); }
        },
        undef
    );
    uiMenuItemOnClicked(
        $mi_pause,
        sub {
            my $ih = $selected_ih_hex->();
            if ($ih) { $cmd_queue->enqueue( [ 'pause', $ih ] ); log_msg("pause: $ih"); }
        },
        undef
    );
    uiMenuItemOnClicked(
        $mi_resume,
        sub {
            my $ih = $selected_ih_hex->();
            if ($ih) { $cmd_queue->enqueue( [ 'resume', $ih ] ); log_msg("resume: $ih"); }
        },
        undef
    );
    uiMenuItemOnClicked(
        $mi_remove,
        sub {
            my $ih = $selected_ih_hex->();
            if ($ih) {
                $cmd_queue->enqueue( [ 'remove', $ih ] );
                log_msg("remove: $ih");
                $selected_row = -1;
            }
        },
        undef
    );
    uiMenuItemOnClicked(
        $mi_about,
        sub {
            uiMsgBox(
                $mainwin, 'Affix BitTorrent [Threaded]', <<~'END'
                A multi-threaded BitTorrent client
                built with LibUI.pm, Net::BitTorrent, and Affix FFI

                UI thread + dedicated BT thread
                END
            );
        },
        undef
    );
    uiButtonOnClicked( $btn_add_file,   sub { _do_add_file() },       undef );
    uiButtonOnClicked( $btn_add_magnet, sub { show_magnet_dialog() }, undef );
    uiButtonOnClicked(
        $btn_start,
        sub {
            my $ih = $selected_ih_hex->();
            if ($ih) { $cmd_queue->enqueue( [ 'start', $ih ] ); log_msg("start: $ih"); }
        },
        undef
    );
    uiButtonOnClicked(
        $btn_stop,
        sub {
            my $ih = $selected_ih_hex->();
            if ($ih) { $cmd_queue->enqueue( [ 'stop', $ih ] ); log_msg("stop: $ih"); }
        },
        undef
    );
    uiButtonOnClicked(
        $btn_pause,
        sub {
            my $ih = $selected_ih_hex->();
            if ($ih) { $cmd_queue->enqueue( [ 'pause', $ih ] ); log_msg("pause: $ih"); }
        },
        undef
    );
    uiButtonOnClicked(
        $btn_resume,
        sub {
            my $ih = $selected_ih_hex->();
            if ($ih) { $cmd_queue->enqueue( [ 'resume', $ih ] ); log_msg("resume: $ih"); }
        },
        undef
    );
    uiButtonOnClicked(
        $btn_remove,
        sub {
            my $ih = $selected_ih_hex->();
            if ($ih) {
                $cmd_queue->enqueue( [ 'remove', $ih ] );
                log_msg("remove: $ih");
                $selected_row = -1;
            }
        },
        undef
    );
    uiTableOnRowClicked(
        $table,
        sub ( $tbl, $row, $data ) {
            $selected_row = $row;
            _rebuild_detail_tabs();
        },
        undef
    );
}

# ============================================================================
#  Detail tab rebuild (reads from shared data)
# ============================================================================
sub _rebuild_detail_tabs() {
    if ( $selected_row < 0 || $selected_row >= scalar @display ) {
        for my $l (
            $lbl_detail_name,     $lbl_detail_hash, $lbl_detail_size, $lbl_detail_progress, $lbl_detail_downloaded,
            $lbl_detail_uploaded, $lbl_detail_down, $lbl_detail_up,   $lbl_detail_peers,    $lbl_detail_seeds
        ) {
            uiLabelSetText( $l, '-' ) if $l;
        }
        uiLabelSetText( $lbl_trackers, '-' ) if $lbl_trackers;
        _clear_table( $peer_model,    \@peer_data );
        _clear_table( $content_model, \@content_data );
        return;
    }
    my $d = $display[$selected_row];
    return unless $d && ref $d && ref $d eq 'HASH';
    uiLabelSetText( $lbl_detail_name,       $d->{name}   // '-' );
    uiLabelSetText( $lbl_detail_hash,       $d->{ih_hex} // '-' );
    uiLabelSetText( $lbl_detail_size,       $d->{size}   // '-' );
    uiLabelSetText( $lbl_detail_progress,   sprintf( '%.1f%%', $d->{progress} // 0 ) );
    uiLabelSetText( $lbl_detail_downloaded, $d->{dl_total} // '0 B' );
    uiLabelSetText( $lbl_detail_uploaded,   $d->{ul_total} // '0 B' );
    uiLabelSetText( $lbl_detail_down,       $d->{down}     // '0 B/s' );
    uiLabelSetText( $lbl_detail_up,         $d->{up}       // '0 B/s' );
    uiLabelSetText( $lbl_detail_peers,      $d->{peers}    // '0/0' );
    uiLabelSetText( $lbl_detail_seeds,      ( split '/', $d->{peers} // '0/0' )[0] );
    my $trackers_ref = eval { decode_json($shared_trackers_json) } || [];
    my $tracker_str  = join( "\n", @$trackers_ref ) if @$trackers_ref;
    uiLabelSetText( $lbl_trackers, $tracker_str // 'No tracker information' );
    _clear_table( $peer_model, \@peer_data );
    my $peers_ref = eval { decode_json($shared_peers_json) } || [];

    for my $p (@$peers_ref) {
        push @peer_data,
            {
            ip     => $p->{ip}     // '?',
            port   => $p->{port}   // '?',
            down   => $p->{down}   // '0 B/s',
            up     => $p->{up}     // '0 B/s',
            seeder => $p->{seeder} // 'No',
            };
        uiTableModelRowInserted( $peer_model, $#peer_data );
    }
    _clear_table( $content_model, \@content_data );
    my $files_ref = eval { decode_json($shared_files_json) } || [];
    for my $f (@$files_ref) {
        push @content_data, { name => $f->{name} // '?', size => $f->{size} // 'Unknown', enabled => 1, };
        uiTableModelRowInserted( $content_model, $#content_data );
    }
}

sub _update_detail_labels() {
    return if $selected_row < 0 || $selected_row >= scalar @display;
    my $d = $display[$selected_row] // return;
    return unless ref $d && ref $d eq 'HASH';
    uiLabelSetText( $lbl_detail_progress,   sprintf( '%.1f%%', $d->{progress} // 0 ) );
    uiLabelSetText( $lbl_detail_downloaded, $d->{dl_total} // '0 B' );
    uiLabelSetText( $lbl_detail_uploaded,   $d->{ul_total} // '0 B' );
    uiLabelSetText( $lbl_detail_down,       $d->{down}     // '0 B/s' );
    uiLabelSetText( $lbl_detail_up,         $d->{up}       // '0 B/s' );
    uiLabelSetText( $lbl_detail_peers,      $d->{peers}    // '0/0' );
    uiLabelSetText( $lbl_detail_seeds,      ( split '/', $d->{peers} // '0/0' )[0] );
}

# ============================================================================
#  Magnet URI dialog
# ============================================================================
sub show_magnet_dialog() {
    my $dlg = uiNewWindow( 'Add Magnet URI', 500, 120, 0 );
    uiWindowSetMargined( $dlg, 1 );
    my $vbox = uiNewVerticalBox();
    uiBoxSetPadded( $vbox, 1 );
    uiWindowSetChild( $dlg, $vbox );
    uiBoxAppend( $vbox, uiNewLabel('Enter magnet URI:'), 0 );
    my $entry = uiNewEntry();
    uiBoxAppend( $vbox, $entry, 0 );
    my $hbox = uiNewHorizontalBox();
    uiBoxSetPadded( $hbox, 1 );
    uiBoxAppend( $vbox, $hbox, 0 );
    my $btn_ok = uiNewButton('Add');
    uiBoxAppend( $hbox, $btn_ok, 0 );
    uiButtonOnClicked(
        $btn_ok,
        sub {
            my $uri = uiEntryText($entry);
            if ( defined $uri && length($uri) > 0 ) {
                $cmd_queue->enqueue( [ 'add_magnet', $uri ] );
                log_msg( 'queued add_magnet: ' . $uri );
            }
            uiControlHide($dlg);
        },
        undef
    );
    my $btn_cancel = uiNewButton('Cancel');
    uiBoxAppend( $hbox, $btn_cancel, 0 );
    uiButtonOnClicked( $btn_cancel, sub { uiControlHide($dlg); }, undef );
    uiWindowOnClosing( $dlg, sub { uiControlHide($dlg); 0 }, undef );
    uiControlShow($dlg);
}

sub _do_add_file() {
    my $path = uiOpenFile($mainwin);
    if ( defined $path && -f $path ) {
        $cmd_queue->enqueue( [ 'add_file', $path ] );
        log_msg( 'queued add_file: ' . $path );
    }
}

# ============================================================================
#  UI Tick -- reads shared data, updates GUI. NO BT operations here.
# ============================================================================
sub ui_tick($data) {
    while ( my $msg = $log_queue->dequeue_nb() ) {
        log_msg($msg);
    }
    if ( $bt_ready && $snapshot_seq != $last_snapshot ) {
        my @snap = eval { @{ decode_json($shared_json) } } if $shared_json;
        @snap = () if $@;
        my $old_count = scalar @display;
        my $new_count = scalar @snap;
        @display = @snap;
        if ( $new_count > $old_count ) {
            for my $i ( 0 .. $old_count - 1 ) {
                uiTableModelRowChanged( $table_model, $i );
            }
            for my $i ( $old_count .. $new_count - 1 ) {
                uiTableModelRowInserted( $table_model, $i );
            }
        }
        elsif ( $new_count < $old_count ) {
            for my $i ( 0 .. $new_count - 1 ) {
                uiTableModelRowChanged( $table_model, $i );
            }
            for my $i ( reverse $new_count .. $old_count - 1 ) {
                uiTableModelRowDeleted( $table_model, $i );
            }
            $selected_row = -1 if $selected_row >= $new_count;
        }
        else {
            uiTableModelRowChanged( $table_model, $_ ) for 0 .. $new_count - 1;
        }
        $last_snapshot = $snapshot_seq;
        _update_detail_labels();
        $peer_refresh_counter++;
        if ( $peer_refresh_counter >= 40 ) {
            $peer_refresh_counter = 0;
            if ( $selected_row >= 0 && $selected_row < $new_count ) {
                _rebuild_detail_tabs();
            }
        }
    }
    return 1;
}

# ============================================================================
#  Main -- UI thread startup
# ============================================================================
log_msg('Starting Affix BitTorrent [Threaded]...');
uiInit( { Size => 0 } );
_init_session_files();
build_ui();

# Spawn BT thread -- BT code runs via string eval in child interpreter
# to avoid crashing perl_clone_using on Windows ithreads.
log_msg('Spawning BT thread...');
my $thr = threads->create( sub { eval $BT_THREAD_CODE; die "BT thread eval failed: $@" if $@ } );

# Wire up shared queues to the BT thread
# (Thread::Queue is thread-safe; child thread will use the same queues)
# We need to pass queues to the child thread. Since Thread::Queue->new()
# inside the eval creates NEW queues, we need a different approach:
# re-create the queues after spawn and use the shared vars for communication.
# Actually Thread::Queue objects ARE shared across threads automatically.
# Wait for BT thread to be ready
while ( !$bt_ready ) {
    select( undef, undef, undef, 0.05 );
    while ( my $msg = $log_queue->dequeue_nb() ) {
        log_msg($msg);
    }
}
log_msg('BT thread is ready.');
uiTimer( 50, \&ui_tick, undef );
uiControlShow($mainwin);
log_msg('Window shown. Entering uiMain()...');
uiMain();
log_msg('UI exited. Waiting for BT thread...');
$cmd_queue->enqueue( ['shutdown'] );

for my $t ( threads->list() ) {
    $t->join() if $t->tid() != threads->tid();
}
log_msg('Shutdown complete.');
