use strict;
use warnings FATAL => 'all';

package MarpaX::Database::Terminfo::Interface;
use MarpaX::Database::Terminfo;
use MarpaX::Database::Terminfo::String;
use MarpaX::Database::Terminfo::Constants qw/:all/;
use File::ShareDir qw/:ALL/;
use Carp qw/carp croak/;
use Sereal::Decoder 3.015 qw/decode_sereal/;
use Time::HiRes qw/usleep/;
use Log::Any qw/$log/;
use constant BAUDBYTE => 9; # From GNU Ncurses: 9 = 7 bits + 1 parity + 1 stop
our $HAVE_POSIX = eval "use POSIX; 1;" || 0;

# ABSTRACT: Terminfo interface

our $VERSION = '0.012'; # VERSION


sub new {
    my ($class, $optp) = @_;

    $optp //= {};

    if (ref($optp) ne 'HASH') {
        croak 'Options must be a reference to a HASH';
    }

    my $file = $optp->{file} // $ENV{MARPAX_DATABASE_TERMINFO_FILE} // '';
    my $txt  = $optp->{txt}  // $ENV{MARPAX_DATABASE_TERMINFO_TXT}  // '';
    my $bin  = $optp->{bin}  // $ENV{MARPAX_DATABASE_TERMINFO_BIN}  // dist_file('MarpaX-Database-Terminfo', 'share/ncurses-terminfo.sereal');
    my $caps = $optp->{caps} // $ENV{MARPAX_DATABASE_TERMINFO_CAPS} // (
        $^O eq 'aix'     ? dist_file('MarpaX-Database-Terminfo', 'share/ncurses-Caps.aix4')   :
        $^O eq 'hpux'    ? dist_file('MarpaX-Database-Terminfo', 'share/ncurses-Caps.hpux11') :
        $^O eq 'dec_osf' ? dist_file('MarpaX-Database-Terminfo', 'share/ncurses-Caps.osf1r5') :
        dist_file('MarpaX-Database-Terminfo', 'share/ncurses-Caps'));

    my $cache_stubs_as_txt = $optp->{cache_stubs_as_txt} // $ENV{MARPAX_DATABASE_TERMINFO_CACHE_STUBS_AS_TXT} // 1;
    my $cache_stubs        = $optp->{cache_stubs}        // $ENV{MARPAX_DATABASE_TERMINFO_CACHE_STUBS}        // 1;
    my $stubs_txt;
    my $stubs_bin;
    if ($cache_stubs) {
        $stubs_txt   = $optp->{stubs_txt} // $ENV{MARPAX_DATABASE_TERMINFO_STUBS_TXT} // '';
        $stubs_bin   = $optp->{stubs_bin} // $ENV{MARPAX_DATABASE_TERMINFO_STUBS_BIN} // dist_file('MarpaX-Database-Terminfo', 'share/ncurses-terminfo-stubs.sereal');
    } else {
        $stubs_txt = '';
        $stubs_bin = '';
    }
    my $bsd_tputs = $optp->{bsd_tputs} // $ENV{MARPAX_DATABASE_TERMINFO_BSD_TPUTS} // 0;
    my $use_env   = $optp->{use_env  } // $ENV{MARPAX_DATABASE_TERMINFO_USE_ENV}   // 1;

    # -------------
    # Load Database
    # -------------
    my $db = undef;
    my $db_ok = 0;
    if ($file) {
        my $fh;
        if ($log->is_debug) {
            $log->debugf('Loading %s', $file);
        }
        if (! open($fh, '<', $file)) {
            carp "Cannot open $file, $!";
        } else {
            my $content = do {local $/; <$fh>;};
            close($fh) || carp "Cannot close $file, $!";
            if ($log->is_debug) {
                $log->debugf('Parsing %s', $file);
            }
            eval {$db = MarpaX::Database::Terminfo->new()->parse(\$content)->value()};
            if ($@) {
                carp $@;
            } else {
                $db_ok = 1;
            }
        }
    }
    if (! $db_ok && $txt) {
        if ($log->is_debug) {
            $log->debugf('Parsing txt');
        }
        eval {$db = MarpaX::Database::Terminfo->new()->parse(\$txt)->value()};
        if ($@) {
            carp $@;
        } else {
            $db_ok = 1;
        }
    }
    $db_ok = _load_sereal($bin, $db) unless $db_ok;
    if (! $db_ok) {
        croak 'Cannot get a valid terminfo database';
    }
    # -----------------------
    # Load terminfo<->termcap
    # -----------------------
    my %t2other = ();
    my %c2other = ();
    my %capalias = ();
    my %infoalias = ();
    {
        if ($log->is_debug) {
            $log->debugf('Loading %s', $caps);
        }
        my $fh;
        if (! open($fh, '<', $caps)) {
            carp "Cannot open $caps, $!";
        } else {
            #
            # Get translations
            #
            my $line = 0;
            while (defined($_ = <$fh>)) {
                ++$line;
                if (/^\s*#/) {
                    next;
                }
                s/\s*$//;
                if (/^\s*capalias\b/) {
                    my ($capalias, $alias, $name, $set, $description) = split(/\s+/, $_, 5);
                    $capalias{$alias} = {name => $name, set => $set, description => $description};
                } elsif (/^\s*infoalias\b/) {
                    my ($infoalias, $alias, $name, $set, $description) = split(/\s+/, $_, 5);
                    $infoalias{$alias} = {name => $name, set => $set, description => $description};
                } else {
                    my ($variable, $feature, $type, $termcap, $keyname, $keyvalue, $translation, $description) = split(/\s+/, $_, 8);
                    if ($type eq 'bool') {
                        $type = TERMINFO_BOOLEAN;
                    } elsif ($type eq 'num') {
                        $type = TERMINFO_NUMERIC;
                    } elsif ($type eq 'str') {
                        $type = TERMINFO_STRING;
                    } else {
                        $log->warnf('%s(%d): wrong type \'%s\'', $caps, $line, $type); exit;
                        next;
                    }
                    $t2other{$feature} = {type => $type, termcap => $termcap, variable => $variable};
                    $c2other{$termcap} = {type => $type, feature => $feature, variable => $variable};
                }
            }
            close($fh) || carp "Cannot close $caps, $!";
        }
    }
    # -----------------
    # Load stubs as txt
    # -----------------
    my $cached_stubs_as_txt = {};
    my $cached_stubs_as_txt_ok = 0;
    if ($cache_stubs) {
        if ($stubs_txt) {
            my $fh;
            if ($log->is_debug) {
                $log->debugf('Loading %s', $stubs_txt);
            }
            if (! open($fh, '<', $stubs_txt)) {
                carp "Cannot open $stubs_txt, $!";
            } else {
                my $content = do {local $/; <$fh>;};
                close($fh) || carp "Cannot close $stubs_txt, $!";
                if ($log->is_debug) {
                    $log->debugf('Evaluating %s', $stubs_txt);
                }
                {
                    #
                    # Because Data::Dumper have $VARxxx
                    #
                    no strict 'vars';
                    #
                    # Untaint data
                    #
                    my ($untainted) = $content =~ m/(.*)/s;
                    $cached_stubs_as_txt = eval $untainted; ## no critic
                    if ($@) {
                        carp "$stubs_txt: $@";
                    } else {
                        $cached_stubs_as_txt_ok = 1;
                    }
                }
            }
        }
        if (! $cached_stubs_as_txt_ok && $stubs_bin) {
            $cached_stubs_as_txt_ok = _load_sereal($stubs_bin, $cached_stubs_as_txt);
        }
    }

    my $self = {
        _terminfo_db => $db,
        _terminfo_current => undef,
        _t2other => \%t2other,
        _c2other => \%c2other,
        _capalias => \%capalias,
        _infoalias => \%infoalias,
        _stubs => {},
        _cache_stubs => $cache_stubs,
        _cached_stubs => {},
        _cache_stubs_as_txt => $cache_stubs_as_txt,
        _cached_stubs_as_txt => $cached_stubs_as_txt,
        _flush => [ sub {} ],
        _bsd_tputs => $bsd_tputs,
        _term => undef,              # Current terminal
        _use_env => $use_env,
    };

    bless($self, $class);

    #
    # Initialize
    #
    $self->_terminfo_init();

    return $self;
}

sub _load_sereal {
    my $bin = shift;  # Output is on the stack at $_[0]
    my $rc = 0;

    my $fh;
    if ($log->is_debug) {
        $log->debugf('Loading %s', $bin);
    }
    if (! open($fh, '<', $bin)) {
        carp "Cannot open $bin, $!";
    } else {
        if (! binmode $fh) {
            carp "Cannot binmode $bin, $!";
        } else {
            my @stat = stat($fh);
            if (! @stat) {
                carp "Cannot stat $bin, $!";
            } else {
                my $bytes = $stat[7];
                my $blob;
                if (read($fh, $blob, $bytes) != $bytes) {
                    carp "Cannot read $bytes bytes from $bin, $!";
                } else {
                    my $decoder = Sereal::Decoder->new();
                    eval {
                        $decoder->decode($blob, $_[0]);
                        $rc = 1;
                    } || carp "Cannot deserialize $bin, $@";
                }
            }
        }
        close($fh) || carp "Cannot close $bin, $!";
    }

    return $rc;
}


sub _terminfo_db {
    my ($self) = (@_);
    if ($log->is_warn && ! defined($self->{_terminfo_db})) {
        $log->warnf('Undefined database');
    }
    return $self->{_terminfo_db};
}


sub _terminfo_current {
    my $self = shift;
    if (@_) {
        $self->{_terminfo_current} = shift;
    }
    if ($log->is_warn && ! defined($self->{_terminfo_current})) {
        $log->warnf('Undefined current terminfo entry');
    }
    return $self->{_terminfo_current};
}


sub _t2other {
    my ($self) = (@_);
    if ($log->is_warn && ! defined($self->{_t2other})) {
        $log->warnf('Undefined terminfo->termcap translation hash');
    }
    return $self->{_t2other};
}


sub _c2other {
    my ($self) = (@_);
    if ($log->is_warn && ! defined($self->{_c2other})) {
        $log->warnf('Undefined terminfo->termcap translation hash');
    }
    return $self->{_c2other};
}


sub _capalias {
    my ($self) = (@_);
    if ($log->is_warn && ! defined($self->{_capalias})) {
        $log->warnf('Undefined terminfo->termcap translation hash');
    }
    return $self->{_capalias};
}


sub _infoalias {
    my ($self) = (@_);
    if ($log->is_warn && ! defined($self->{_infoalias})) {
        $log->warnf('Undefined terminfo->termcap translation hash');
    }
    return $self->{_infoalias};
}


sub _terminfo_init {
    my ($self) = (@_);
    if (! defined($self->{_terminfo_current})) {
        $self->tgetent($ENV{TERM} || 'unknown');
    }
    return defined($self->_terminfo_current);
}


sub flush {
    my ($self, $cb, @args) = @_;
    if (defined($cb)) {
        $self->{_flush} = [ $cb, @args ];
    }
    return $self->{_flush};
}


sub _find {
    my ($self, $name, $from) = @_;

    my $rc = undef;
    $from //= '';

    if ($log->is_debug) {
        if ($from) {
            $log->debugf('Loading %s -> %s', $from, $name);
        } else {
            $log->debugf('Loading %s', $name);
        }
    }

    my $terminfo_db = $self->_terminfo_db;
    if (defined($terminfo_db)) {
        foreach (@{$terminfo_db}) {
            my $terminfo = $_;

            if (grep {$_ eq $name} @{$terminfo->{alias}}) {
                if ($log->is_trace) {
                    $log->tracef('Found alias \'%s\' in terminfo with aliases %s longname \'%s\'', $name, $terminfo->{alias}, $terminfo->{longname});
                }
                $rc = $terminfo;
                last;
            }
        }
    }
    return $rc;
}

sub tgetent {
    my ($self, $name, $fh) = (@_);

    if (! defined($self->_terminfo_db)) {
        return -1;
    }
    my $found = $self->_find($name);
    if (! defined($found)) {
        return 0;
    }
    #
    # Process cancellations and use=
    #
    my %cancelled = ();
    {
        my %featured = ();
        my $i = 0;
        while ($i <= $#{$found->{feature}}) {
            my $feature = $found->{feature}->[$i];
            if ($feature->{type} == TERMINFO_BOOLEAN && substr($feature->{name}, -1, 1) eq '@') {
                my $cancelled = $feature->{name};
                substr($cancelled, -1, 1, '');
                $cancelled{$cancelled} = 1;
                if ($log->is_trace) {
                    $log->tracef('[Loading %s] New cancellation %s', $name, $cancelled);
                }
                ++$i;
            } elsif ($feature->{type} == TERMINFO_STRING && $feature->{name} eq 'use') {
                if ($log->is_trace) {
                    $log->tracef('[Loading %s] use=\'%s\' with cancellations %s', $name, $feature->{value}, [ keys %cancelled ]);
                }
                my $insert = $self->_find($feature->{value}, $name);
                if (! defined($insert)) {
                    return 0;
                }
                my @keep = ();
                foreach (@{$insert->{feature}}) {
                    if (exists($cancelled{$_->{name}})) {
                        if ($log->is_trace) {
                            $log->tracef('[Loading %s] Skipping cancelled feature \'%s\' from terminfo with aliases %s longname \'%s\'', $name, $_->{name}, $insert->{alias}, $insert->{longname});
                        }
                        next;
                    }
                    if (exists($featured{$_->{name}})) {
                        if ($log->is_trace) {
                            $log->tracef('[Loading %s] Skipping overwriting feature \'%s\' from terminfo with aliases %s longname \'%s\'', $name, $_->{name}, $insert->{alias}, $insert->{longname});
                        }
                        next;
                    }
                    if ($log->is_trace) {
                        $log->tracef('[Loading %s] Pushing feature %s from terminfo with aliases %s longname \'%s\'', $name, $_, $insert->{alias}, $insert->{longname});
                    }
                    push(@keep, $_);
                }
                splice(@{$found->{feature}}, $i, 1, @keep);
            } else {
                if ($log->is_trace) {
                    $log->tracef('[Loading %s] New feature %s', $name, $feature);
                }
                $featured{$feature->{name}} = 1;
                ++$i;
            }
        }
    }
    #
    # Remember cancelled things
    #
    $found->{cancelled} = \%cancelled;
    #
    # Drop needless cancellations
    #
    {
        my $i = $#{$found->{feature}};
        foreach (reverse @{$found->{feature}}) {
            if ($_->{type} == TERMINFO_BOOLEAN && substr($_->{name}, -1, 1) eq '@') {
                if ($log->is_trace) {
                    $log->tracef('[Loading %s] Dropping cancellation \'%s\' from terminfo', $name, $found->{feature}->[$i]->{name});
                }
                splice(@{$found->{feature}}, $i, 1);
            }
            --$i;
        }
    }
    #
    # Drop commented features
    #
    {
        my $i = $#{$found->{feature}};
        foreach (reverse @{$found->{feature}}) {
            if (substr($_->{name}, 0, 1) eq '.') {
                if ($log->is_trace) {
                    $log->tracef('[Loading %s] Dropping commented \'%s\' from terminfo', $name, $found->{feature}->[$i]->{name});
                }
                splice(@{$found->{feature}}, $i, 1);
            }
            --$i;
        }
    }
    #
    # The raw terminfo is is the features referenced array.
    # For faster lookup we fill the terminfo, termcap and variable hashes.
    # These are used in the subroutine _tget().
    #
    $found->{terminfo} = {};
    $found->{termcap} = {};
    $found->{variable} = {};
    my $pad_char = undef;
    my $cursor_up = undef;
    my $backspace_if_not_bs = undef;
    {
        foreach (@{$found->{feature}}) {
            my $feature = $_;
            my $key = $feature->{name};
            #
            # For terminfo lookup
            #
            if (! exists($found->{terminfo}->{$key})) {
                $found->{terminfo}->{$key} = $feature;
            } else {
                if ($log->is_warn) {
                    $log->warnf('[Loading %s] Multiple occurence of feature \'%s\'', $name, $key);
                }
            }
            #
            # Translation exist ?
            #
            if (! exists($self->_t2other->{$key})) {
                if ($log->is_trace) {
                    $log->tracef('[Loading %s] Untranslated feature \'%s\'', $name, $key);
                }
                next;
            }
            #
            # Yes, check consistency
            #
            my $type = $self->_t2other->{$key}->{type};
            if ($feature->{type} != $type) {
                if ($log->is_warn) {
                    $log->warnf('[Loading %s] Wrong type when translating feature \'%s\': %d instead of %d', $name, $key, $type, $feature->{type});
                }
                next;
            }
            #
            # Convert to termcap
            #
            my $termcap  = $self->_t2other->{$key}->{termcap};
            if (! defined($termcap)) {
                if ($log->is_trace) {
                    $log->tracef('[Loading %s] Feature \'%s\' has no termcap equivalent', $name, $key);
                }
            } else {
                if ($log->is_trace) {
                    $log->tracef('[Loading %s] Pushing termcap feature \'%s\'', $name, $termcap);
                }
                if (! exists($found->{termcap}->{$termcap})) {
                    $found->{termcap}->{$termcap} = $feature;
                } else {
                    if ($log->is_warn) {
                        $log->warnf('[Loading %s] Multiple occurence of termcap \'%s\'', $name, $termcap);
                    }
                }
            }
            #
            # Convert to variable
            #
            my $variable = $self->_t2other->{$key}->{variable};
            if (! defined($variable)) {
                if ($log->is_trace) {
                    $log->tracef('[Loading %s] Feature \'%s\' has no variable equivalent', $name, $key);
                }
            } else {
                if ($log->is_trace) {
                    $log->tracef('[Loading %s] Pushing variable feature \'%s\'', $name, $variable);
                }
                if (! exists($found->{variable}->{$variable})) {
                    $found->{variable}->{$variable} = $feature;
                    #
                    # Keep track of pad_char, cursor_up and backspace_if_not_bs
                    if ($type == TERMINFO_STRING) {
                        if ($variable eq 'pad_char') {
                            $pad_char = $feature;
                            if ($log->is_trace) {
                                $log->tracef('[Loading %s] pad_char is \'%s\'', $name, $pad_char->{value});
                            }
                        } elsif ($variable eq 'cursor_up') {
                            $cursor_up = $feature;
                            if ($log->is_trace) {
                                $log->tracef('[Loading %s] cursor_up is \'%s\'', $name, $cursor_up->{value});
                            }
                        } elsif ($variable eq 'backspace_if_not_bs') {
                            $backspace_if_not_bs = $feature;
                            if ($log->is_trace) {
                                $log->tracef('[Loading %s] backspace_if_not_bs is \'%s\'', $name, $backspace_if_not_bs->{value});
                            }
                        }
                    }
                } else {
                    if ($log->is_warn) {
                        $log->warnf('[Loading %s] Multiple occurence of variable \'%s\'', $name, $key);
                    }
                }
            }
        }

        # The variables PC, UP and BC are set by tgetent to the terminfo entry's data for pad_char, cursor_up and backspace_if_not_bs, respectively.
        #
        # PC is used in the delay function.
        #
        if (defined($pad_char)) {
            if ($log->is_trace) {
                $log->tracef('[Loading %s] Initialized PC to \'%s\'', $name, $pad_char->{value});
            }
            $found->{variable}->{PC} = $pad_char;
        }
        #
        # UP is not used by ncurses.
        #
        if (defined($cursor_up)) {
            if ($log->is_trace) {
                $log->tracef('[Loading %s] Initialized UP to \'%s\'', $name, $cursor_up->{value});
            }
            $found->{variable}->{UP} = $cursor_up;
        }
        #
        # BC is used in the tgoto emulation.
        #
        if (defined($backspace_if_not_bs)) {
            if ($log->is_trace) {
                $log->tracef('[Loading %s] Initialized BC to \'%s\'', $name, $backspace_if_not_bs->{value});
            }
            $found->{variable}->{BC} = $backspace_if_not_bs;
        }
        #
        # The variable ospeed is set in a system-specific coding to reflect the terminal speed.
        #
        my ($baudrate, $ospeed) = $self->_get_ospeed_and_baudrate($fh);
        my $OSPEED = {name => 'ospeed', type => TERMINFO_NUMERIC, value => $ospeed};
        if ($log->is_trace) {
            $log->tracef('[Loading %s] Initialized ospeed to %d', $name, $OSPEED->{value});
        }
        $found->{variable}->{ospeed} = $OSPEED;
        #
        # The variable baudrate is used eventually in delay
        #
        my $BAUDRATE = {name => 'baudrate', type => TERMINFO_NUMERIC, value => $baudrate};
        if ($log->is_trace) {
            $log->tracef('[Loading %s] Initialized baudrate to %d', $name, $BAUDRATE->{value});
        }
        $found->{variable}->{baudrate} = $BAUDRATE;
        #
        # ospeed and baudrate are add-ons, not in the terminfo database.
        # If you look to the terminfo<->Caps translation files, you will see that none of ospeed
        # nor baudrate variables exist. Nevertheless, we check if they these entries WOULD exist
        # and warn about it, because we would overwrite them.
        #
        if (exists($found->{terminfo}->{ospeed})) {
            if ($log->is_warn) {
                $log->tracef('[Loading %s] Overwriting ospeed to \'%s\'', $name, $OSPEED->{value});
            }
        }
        $found->{terminfo}->{ospeed} = $found->{variable}->{ospeed};
        if (exists($found->{terminfo}->{baudrate})) {
            if ($log->is_warn) {
                $log->tracef('[Loading %s] Overwriting baudrate to \'%s\'', $name, $BAUDRATE->{value});
            }
        }
        $found->{terminfo}->{baudrate} = $found->{variable}->{baudrate};
    }

    #
    # Remove any static/dynamic var
    #
    $found->{_static_vars} = [];
    $found->{_dynamic_vars} = [];

    $self->_terminfo_current($found);

    #
    # Create stubs for every string
    #
    $self->_stubs($name);

    return 1;
}

sub _stub {
    my ($self, $featurevalue) = @_;

    if ($self->{_cache_stubs}) {
        if (exists($self->{_cached_stubs}->{$featurevalue})) {
            if ($log->is_trace) {
                $log->tracef('Getting \'%s\' compiled stub from cache', $featurevalue);
            }
            $self->{_stubs}->{$featurevalue} = $self->{_cached_stubs}->{$featurevalue};
        }
    }
    if (! exists($self->{_stubs}->{$featurevalue})) {
        my $stub_as_txt = undef;
        if ($self->{_cache_stubs_as_txt}) {
            if (exists($self->{_cached_stubs_as_txt}->{$featurevalue})) {
                if ($log->is_trace) {
                    $log->tracef('Getting \'%s\' stub as txt from cache', $featurevalue);
                }
                $stub_as_txt = $self->{_cached_stubs_as_txt}->{$featurevalue};
            }
        }
        if (! defined($stub_as_txt)) {
            #
            # Very important: we restore the ',': it is parsed as either
            # and EOF (normal case) or an ENDIF (some entries are MISSING
            # the '%;' ENDIF tag at the very end). I am not going to change
            # the grammar when documentation says that a string follows
            # the ALGOL68, which has introduced the ENDIF tag to solve the
            # IF-THEN-ELSE-THEN ambiguity.
            # There is no side-effect doing so, but keeping the grammar clean.
            my $string = "$featurevalue,";
            if ($log->is_trace) {
                $log->tracef('Parsing \'%s\'', $string);
            }
            my $parseTreeValue = MarpaX::Database::Terminfo::String->new()->parse(\$string)->value();
            #
            # Enclose the result for anonymous subroutine evaluation
            # We reindent everything by two spaces
            #
            my $indent = join("\n", @{${$parseTreeValue}});
            $indent =~ s/^/  /smg;
            $stub_as_txt = "
#
# Stub version of: $featurevalue
#
sub {
  my (\$self, \$dynamicp, \$staticp, \@param) = \@_;
  # Initialized with \@param to be termcap compatible
  my \@iparam = \@param;
  my \$rc = '';

$indent
  return \$rc;
}
";
            if ($log->is_trace) {
                $log->tracef('Parsing \'%s\' gives stub: %s', $string, $stub_as_txt);
            }
            if ($self->{_cache_stubs_as_txt}) {
                $self->{_cached_stubs_as_txt}->{$featurevalue} = $stub_as_txt;
            }
        }
        if ($log->is_trace) {
            $log->tracef('Compiling \'%s\' stub', $featurevalue);
        }
        #
        # Untaint data
        #
        my ($untainted) = $stub_as_txt =~ m/(.*)/s;
        $self->{_stubs}->{$featurevalue} = eval $untainted;  ## no critic
        if ($@) {
            carp "Problem with $featurevalue\n$stub_as_txt\n$@\nReplaced by a stub returning empty string...";
            $self->{_stubs}->{$featurevalue} = sub {return '';};
        }
        if ($self->{_cache_stubs}) {
            $self->{_cached_stubs}->{$featurevalue} = $self->{_stubs}->{$featurevalue};
        }
    }

    return $self->{_stubs}->{$featurevalue};
}

sub _stubs {
    my ($self, $name) = @_;

    $self->{_stubs} = {};

    foreach (values %{$self->_terminfo_current->{terminfo}}) {
        my $feature = $_;
        if ($feature->{type} == TERMINFO_STRING) {
            $self->_stub($feature->{value});
        }
    }
}

#
# _get_ospeed_and_baudrate calculates baudrate and ospeed
#
# POSIX module does not contain all the constants. Here they are.
#
our %OSPEED_TO_BAUDRATE = (
    0    => 0,
    1    => 50,
    2    => 75,
    3    => 110,
    4    => 134,
    5    => 150,
    6    => 200,
    7    => 300,
    8    => 600,
    9    => 1200,
    10   => 1800,
    11   => 2400,
    12   => 4800,
    13   => 9600,
    14   => 19200,
    15   => 38400,
    4097 => 57600,
    4098 => 115200,
    4099 => 230400,
    4100 => 460800,
    4101 => 500000,
    4102 => 576000,
    4103 => 921600,
    4104 => 1000000,
    4105 => 1152000,
    4107 => 2000000,
    4108 => 2500000,
    4109 => 3000000,
    4110 => 3500000,
    4111 => 4000000,
    );

sub _get_ospeed_and_baudrate {
    my ($self, $fh) = (@_);

    my $baudrate = 0;
    my $ospeed = 0;

    if (defined($fh)) {
        my $reffh = ref($fh);
        if ($reffh ne 'GLOB') {
            if ($log->is_warn) {
                $log->warnf('filehandle should be a reference to GLOB instead of %s', $reffh || '<nothing>');
            }
        }
        $fh = undef;
    }

    if (defined($ENV{MARPAX_DATABASE_TERMINFO_OSPEED})) {
        $ospeed = $ENV{MARPAX_DATABASE_TERMINFO_OSPEED};
    } else {
        if ($HAVE_POSIX) {
            my $termios = eval { POSIX::Termios->new() };
            if (! defined($termios)) {
                if ($log->is_trace) {
                    $log->tracef('POSIX::Termios->new() failure, %s', $@);
                }
            } else {
                my $fileno = defined($fh) ? fileno($fh) : (fileno(\*STDIN) || 0);
                if ($log->is_trace) {
                    $log->tracef('Trying to get attributes on fileno %d', $fileno);
                }
                eval {$termios->getattr($fileno)};
                if ($@) {
                    if ($log->is_trace) {
                        $log->tracef('POSIX::Termios::getattr(%d) failure, %s', $fileno, $@);
                    }
                    $termios = undef;
                }
            }
            if (defined($termios)) {
                my $this = eval { $termios->getospeed() };
                if (! defined($this)) {
                    if ($log->is_trace) {
                        $log->tracef('getospeed() failure, %s', $@);
                    }
                } else {
                    $ospeed = $this;
                    if ($log->is_trace) {
                        $log->tracef('getospeed() returned %d', $ospeed);
                    }
                }
            }
        }
    }



    if (! exists($OSPEED_TO_BAUDRATE{$ospeed})) {
        if ($log->is_warn) {
            $log->warnf('ospeed %d is an unknown value', $ospeed);
        }
        $ospeed = 0;
    }

    if (! $ospeed) {
        $ospeed = 13;
        if ($log->is_warn) {
            $log->warnf('ospeed defaulting to %d', $ospeed);
        }
    }

    $baudrate = $ENV{MARPAX_DATABASE_TERMINFO_BAUDRATE} || $OSPEED_TO_BAUDRATE{$ospeed} || 0;

    if ($log->is_trace) {
        $log->tracef('ospeed/baudrate: %d/%d', $ospeed, $baudrate);
    }

    return ($baudrate, $ospeed);
}

#
# space refers to termcap, feature (i.e. terminfo) or variable
#
sub _tget {
    my ($self, $space, $default, $default_if_cancelled, $default_if_wrong_type, $default_if_found, $type, $id, $areap) = (@_);

    my $rc = $default;
    my $found = undef;

    if ($self->_terminfo_init()) {
        #
        # First lookup in the hashes. If found, we will get the raw terminfo feature entry.
        #
        if (! exists($self->_terminfo_current->{$space}->{$id})) {
            #
            # No such entry
            #
            if ($log->is_trace) {
                $log->tracef('No %s entry with id \'%s\'', $space, $id);
            }
        } else {
            #
            # Get the raw terminfo entry. The only entries for which it may not There is no check, it must exist by construction, c.f.
            # routine tgetent(), even for variables ospeed and baudrate that are add-ons.
            #
            my $t = $self->_terminfo_current->{$space}->{$id};
            my $feature = $self->_terminfo_current->{terminfo}->{$t->{name}};
            if ($log->is_trace) {
                $log->tracef('%s entry with id \'%s\' maps to terminfo feature %s', $space, $id, $feature);
            }
            if (defined($default_if_cancelled) && exists($self->_terminfo_current->{cancelled}->{$feature->{name}})) {
                if ($log->is_trace) {
                    $log->tracef('Cancelled %s feature %s', $space, $feature->{name});
                }
                $rc = $default_if_cancelled;
            } else {
                #
                # Check if this is the correct type
                #
                if ($feature->{type} == $type) {
                    $found = $feature;
                    if ($type == TERMINFO_STRING) {
                        $rc = defined($default_if_found) ? $default_if_found : \$feature->{value};
                    } else {
                        $rc = defined($default_if_found) ? $default_if_found : $feature->{value};
                    }
                } elsif (defined($default_if_wrong_type)) {
                    if ($log->is_trace) {
                        $log->tracef('Found %s feature %s with type %d != %d', $space, $id, $feature->{type}, $type);
                    }
                    $rc = $default_if_wrong_type;
                }
            }
        }
    }

    if (defined($found) && defined($areap) && ref($areap)) {
        if ($type == TERMINFO_STRING) {
            if (! defined(${$areap})) {
                ${$areap} = '';
            }
            my $pos = pos(${$areap}) || 0;
            substr(${$areap}, $pos, 0, $found->{value});
            pos(${$areap}) = $pos + length($found->{value});
        } else {
            ${$areap} = $found->{value};
        }
    }

    return $rc;
}


sub delay {
    my ($self, $ms) = @_;

    #
    # $self->{_outc} and $self->{_outcArgs} are created/destroyed by tputs() and al.
    #
    my $outc = $self->{_outc};
    if (defined($outc)) {
        my $PC;
        if ($self->tvgetflag('no_pad_char') || ! $self->tvgetstr('PC', \$PC)) {
            #
            # usleep() unit is micro-second
            #
            usleep($ms * 1000);
        } else {
            #
            # baudrate is always defined.
            #
            my $baudrate;
            $self->tvgetnum('baudrate', \$baudrate);
            my $nullcount = int(($ms * $baudrate) / (BAUDBYTE * 1000));
            #
            # We have no interface to 'tack' program, so no need to have a global for _nulls_sent
            #
            while ($nullcount-- > 0) {
                &$outc($self->tparm($PC), @{$self->{_outcArgs}});
            }
            #
            # Call for a flush
            #
            my ($flushcb, @flushargs) = @{$self->flush};
            &$flushcb(@flushargs);
        }
    }
}


sub tgetflag {
    my ($self, $id) = @_;
    return $self->_tget('termcap', 0, undef, undef, undef, TERMINFO_BOOLEAN, $id, undef);
}


sub tigetflag {
    my ($self, $id) = @_;
    return $self->_tget('terminfo', 0, 0, -1, undef, TERMINFO_BOOLEAN, $id, undef);
}


sub tvgetflag {
    my ($self, $id) = @_;
    return $self->_tget('variable', 0, 0, 0, 1, TERMINFO_BOOLEAN, $id);
}


sub tgetnum {
    my ($self, $id) = @_;
    return $self->_tget('termcap', -1, undef, undef, undef, TERMINFO_NUMERIC, $id, undef);
}


sub tigetnum {
    my ($self, $id) = @_;
    return $self->_tget('terminfo', -1, -1, -2, undef, TERMINFO_NUMERIC, $id, undef);
}


sub tvgetnum {
    my ($self, $id, $areap) = @_;
    return $self->_tget('variable', 0, 0, 0, 1, TERMINFO_NUMERIC, $id, $areap);
}


sub tgetstr {
    my ($self, $id, $areap) = @_;
    return $self->_tget('termcap', 0, undef, undef, undef, TERMINFO_STRING, $id, $areap);
}


sub tigetstr {
    my ($self, $id) = @_;
    return $self->_tget('terminfo', 0, 0, -1, undef, TERMINFO_STRING, $id, undef);
}


sub tvgetstr {
    my ($self, $id, $areap
) = @_;
    return $self->_tget('variable', 0, 0, 0, 1, TERMINFO_STRING, $id, $areap);
}


sub tputs {
    my ($self, $str, $affcnt, $outc, @outcArgs) = @_;

    $self->{_outc} = $outc;
    $self->{_outcArgs} = \@outcArgs;

    $self->_tputs($str, $affcnt, $outc, @outcArgs);

    $self->{_outc} = undef;
    $self->{_outcArgs} = undef;
}

sub _tputs {
    my ($self, $str, $affcnt, $outc, @outcArgs) = @_;

    $affcnt //= 1;

    my $bell = '';
    $self->tvgetstr('bell', \$bell);
    my $flash_screen = '';
    $self->tvgetstr('flash_screen', \$flash_screen);

    my $always_delay;
    my $normal_delay;

    if (! defined($self->{_term})) {
        #
        # No current terminal: setuppterm() has not been called
        #
        $always_delay = 0;
        $normal_delay = 1;
    } else {
        my $xon_xoff = $self->tvgetflag('xon_xoff');
        my $padding_baud_rate = 0;
        $self->tvgetnum('padding_baud_rate', \$padding_baud_rate);
        my $baudrate = 0;
        $self->tvgetnum('baudrate', \$baudrate);

        $always_delay = ($str eq $bell || $str eq $flash_screen) ? 1 : 0;
        $normal_delay = (! $xon_xoff && $padding_baud_rate && $baudrate >= $padding_baud_rate) ? 1 : 0;
    }

    my $trailpad = 0;
    pos($str) = undef;
    if ($self->{_bsd_tputs} && length($str) > 0) {
        if ($str =~ /^([[:digit:]]+)(?:\.([[:digit:]])?[[:digit:]]*)?(\*)?/) {
            my ($one, $two, $three) = (
                substr($str, $-[1], $+[1] - $-[1]),
                defined($-[2]) ? substr($str, $-[2], $+[2] - $-[2]) : 0,
                defined($-[3]) ? 1 : 0);
            $trailpad = $one * 10;
            $trailpad += $two;
            if ($three) {
                $trailpad *= $affcnt;
            }
            pos($str) = $+[0];
        }
    }
    my $indexmax = length($str);
    my $index = pos($str) || 0;
    while ($index <= $indexmax) {
        my $c = substr($str, $index, 1);
        if ($c ne '$') {
            &$outc($c, @outcArgs);
        } else {
            $index++;
            $c = ($index <= $indexmax) ? substr($str, $index, 1) : '';
            if ($c ne '<') {
                &$outc('$', @outcArgs);
                if ($c) {
                    &$outc($c, @outcArgs);
                }
            } else {
                $c = (++$index <= $indexmax) ? substr($str, $index, 1) : '';
                if ((! ($c =~ /[[:digit:]]/) && $c ne '.') ||
                    # Note: if $index is after the end $str, perl treat it as the end
                    index($str, '>', $index) < $index) {
                    &$outc('$', @outcArgs);
                    &$outc('<', @outcArgs);
                    #
                    # The EOF will automatically go here
                    #
                    next;
                }

                my $number = 0;
                $c = ($index <= $indexmax) ? substr($str, $index, 1) : '';
                while ($c =~ /[[:digit:]]/) {
                    $number = $number * 10 + $c;
                    $c = (++$index <= $indexmax) ? substr($str, $index, 1) : '';
                }
                $number *= 10;
                $c = ($index <= $indexmax) ? substr($str, $index, 1) : '';
                if ($c eq '.') {
                    $c = ($index <= $indexmax) ? substr($str, $index, 1) : '';
                    if ($c =~ /[[:digit:]]/) {
                        $number += $c;
                        $index++;
                    }
                    while (($index <= $indexmax) && substr($str, $index, 1) =~ /[[:digit:]]/) {
                        $index++;
                    }
                }
                my $mandatory = 0;
                $c = ($index <= $indexmax) ? substr($str, $index, 1) : '';
                while ($c eq '*' || $c eq '/') {
                    if ($c eq '*') {
                        $number *= $affcnt;
                        $index++;
                    } else {
                        $mandatory = 1;
                        $index++;
                    }
                    $c = ($index <= $indexmax) ? substr($str, $index, 1) : '';
                }

                if ($number > 0 && ($always_delay || $normal_delay || $mandatory)) {
                    $self->delay(int($number / 10));
                }
            }
        }

        $index++;
    }

    if ($trailpad > 0 && ($always_delay || $normal_delay)) {
        $self->delay(int($trailpad / 10));
    }
}


sub putp {
    my ($self, $str) = @_;

    return $self->tputs($str, 1, sub {print STDOUT shift});
}


sub _tparm {
    my ($self, $string, @param) = (@_);

    my $stub = $self->_stub($string);

    return $self->$stub($self->_terminfo_current->{_dynamic_vars}, $self->_terminfo_current->{_static_vars}, @param);
}

sub tparm {
    my ($self, $string, @param) = (@_);

    return $self->_tparm($string, @param);
}


sub tgoto {
    my ($self, $string, $col, $row) = (@_);
    #
    # We are in a pure terminfo workflow: capnames capability are translated to a terminfo feature, and the
    # string feature is derived from the found terminfo feature.
    # Reversal of arguments is intentional
    #
    return $self->_tparm($string, $row, $col);
}


sub use_env {
    my $self = shift;

    if (@_) {
        $self->{_use_env} = shift;
        #
        # If user gave undef as argument, convert it to 0.
        #
        if (! defined($self->{_use_env})) {
            $self->{_use_env} = 0;
        }
        #
        # Finally convert it to 1 if ! false
        #
        if (! $self->{_use_env}) {
            $self->{_use_env} = 1;
        }
    }

    return $self->{_use_env};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Database::Terminfo::Interface - Terminfo interface

=head1 VERSION

version 0.012

=head1 SYNOPSIS

    use MarpaX::Database::Terminfo::Interface qw/:all/;
    use Log::Log4perl qw/:easy/;
    use Log::Any::Adapter;
    use Log::Any qw/$log/;
    #
    # Init log
    #
    our $defaultLog4perlConf = '
    log4perl.rootLogger              = WARN, Screen
    log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.stderr  = 0
    log4perl.appender.Screen.layout  = PatternLayout
    log4perl.appender.Screen.layout.ConversionPattern = %d %-5p %6P %m{chomp}%n
    ';
    Log::Log4perl::init(\$defaultLog4perlConf);
    Log::Any::Adapter->set('Log4perl');

    tgetent('ansi');

=head1 DESCRIPTION

This modules implements a terminfo X/open-compliant interface.

=head1 SUBROUTINES/METHODS

=head2 new($class, $opts)

Instance an object. An optional $opt is a reference to a hash:

=over

=item $opts->{file} or $ENV{MARPAX_DATABASE_TERMINFO_FILE}

File path to the terminfo database. This module will then parse it using Marpa. If set to any true value, this setting has precedence over the following txt key/value.

=item $opts->{txt} or $ENV{MARPAX_DATABASE_TERMINFO_TXT}

Text version of the terminfo database. This module will then parse it using Marpa. If set to any true value, this setting has precedence over the following bin key/value.

=item $opts->{bin} or $ENV{MARPAX_DATABASE_TERMINFO_BIN}

Path to a binary version of the terminfo database, created using Sereal. This module is distributed with such a binary file, which contains the GNU ncurses definitions. The default behaviour is to use this file.

=item $opts->{caps} or $ENV{MARPAX_DATABASE_TERMINFO_CAPS}

Path to a text version of the terminfo<->termcap translation. This module is distributed with GNU ncurses translation files, namely: ncurses-Caps (default), ncurses-Caps.aix4 (default on AIX), ncurses-Caps.hpux11 (default on HP/UX), ncurses-Caps.keys, ncurses-Caps.osf1r5 (default on OSF1) and ncurses-Caps.uwin.

=item $opts->{cache_stubs} or $ENV{MARPAX_DATABASE_TERMINFO_CACHE_STUBS}

Flag saying if the compiled stubs of string features should be cached. Default is true.

=item $opts->{cache_stubs_as_txt} or $ENV{MARPAX_DATABASE_TERMINFO_CACHE_STUBS_AS_TXT}

Flag saying if the string versions (i.e. not compiled) stubs of string features should be cached or not. Default is true.

=item $opts->{stubs_txt} or $ENV{MARPAX_DATABASE_TERMINFO_STUBS_TXT}

Path to a text version of the terminfo string features<->stubs mapping, created using Data::Dumper. The content of this file is the text version of all stubs, that will be compiled if needed. This option is used only if cache_stubs is on. If set to any true value, this setting has precedence over the following bin key/value. Mostly useful for debugging or readability: the created stubs are immediately comprehensive, and if there is a bug in them, this option could be used.

=item $opts->{stubs_bin} or $ENV{MARPAX_DATABASE_TERMINFO_STUBS_BIN}

Path to a binary version of the terminfo string features<->stubs mapping, created using Sereal module. The content of this file is the text version of all stubs, that will all be compiled if needed. This option is used only if cache_stubs is on. This module is distributed with such a binary file, which contains the GNU ncurses stubs definitions. The default behaviour is to use this file.

=item $opts->{bsd_tputs} or $ENV{MARPAX_DATABASE_TERMINFO_BSD_TPUTS}

Specific to ancient BSD programs, like nethack, that likes to get systematic delays. Default is false.

=item $opts->{use_env} or $ENV{MARPAX_DATABASE_TERMINFO_USE_ENV}

Initial value of use_env boolean, saying if lines and columns specified in terminfo are used or not. Default value is true. Please refer to the use_env() method.

=back

Default terminal setup is done using the $ENV{TERM} environment variable, if it exist, or 'unknown'. The database used is not a compiled database as with GNU ncurses, therefore the environment variable TERMINFO is not used. Instead, a compiled database should a perl's Sereal version of a text database parsed by Marpa. See $ENV{MARPAX_DATABASE_TERMINFO_BIN} upper.

=head2 _terminfo_db($self)

Internal function. Returns the raw database, in the form of an array of hashes.

=head2 _terminfo_current($self)

Internal function. Returns the current terminfo entry.

=head2 _t2other($self)

Internal function. Returns the terminfo->termcap translation hash.

=head2 _c2other($self)

Internal function. Returns the terminfo->termcap translation hash.

=head2 _capalias($self)

Internal function. Returns the termcap aliases.

=head2 _infoalias($self)

Internal function. Returns the termcap aliases.

=head2 _terminfo_init($self)

Internal function. Initialize if needed and if possible the current terminfo. Returns a pointer to the current terminfo entry.

=head2 flush($self, $cb, @args);

Defines a flush callback function $cb with optional @arguments. Such callback is used in some case like a delay. If called as $self->flush(), returns undef or a reference to an array containing [$cb, @args].

=head2 tgetent($self, $name[, $fh])

Loads the entry for $name. Returns 1 on success, 0 if no entry, -1 if the terminfo database could not be found. This function will warn if the database has a problem. $name must be an alias in the terminfo database. If multiple entries have the same alias, the first that matches is taken. The variables PC, UP and BC are set by tgetent to the terminfo entry's data for pad_char, cursor_up and backspace_if_not_bs, respectively. The variable ospeed is set in a system-specific coding to reflect the terminal speed, or $ENV{MARPAX_DATABASE_TERMINFO_OSPEED} if defined, otherwise we attempt to get the value using POSIX interface, or "13". ospeed should be a value between 0 and 15, or 4097 and 4105, or 4107 and 4111. The variable baudrate can be $ENV{MARPAX_DATABASE_TERMINFO_BAUDRATE} (unchecked! i.e. at your own risk) or is derived from ospeed, or "9600". $fh is an optional opened filehandle, used to guess about baudrate and ospeed. Defaults to fileno(\*STDIN) or 0. When loading a terminfo, termcap and variable entries are automatically derived using the caps parameter as documented in _new_instance().

=head2 delay($self, $ms)

Do a delay of $ms milliseconds when producing the output. If the current terminfo variable no_pad_char is true, or if there is no PC variable, do a system sleep. Otherwise use the PC variable as many times as necessary followed by a flush callback. Do nothing if outside of a "producing output" context (i.e. tputs(), etc...). Please note that delay by itself in the string is not recognized as a grammar lexeme. This is tputs() that is seeing the delay.

=head2 tgetflag($self, $id)

Gets the boolean value for termcap entry $id, or 0 if not available. Only the first two characters of the id parameter are compared in lookups.

=head2 tigetflag($self, $id)

Gets the boolean value for terminfo entry $id. Returns the value -1 if $id is not a boolean capability, or 0 if it is canceled or absent from the terminal description.

=head2 tvgetflag($self, $id)

Search for the boolean variable $id. Return true if found, false in all other cases.

=head2 tgetnum($self, $id)

Stores the numeric value for termcap entry $id, or -1 if not available. Only the first two characters of the id parameter are compared in lookups.

=head2 tigetnum($self, $id)

Gets the numeric value for terminfo entry $id. Returns the value -2 if $id is not a numeric capability, or -1 if it is canceled or absent from the terminal description.

=head2 tvgetnum($self, $id, [$areap])

Search for the numeric variable $id. If found, return true and store its value in the eventual ${$areap}, return false in all other cases.

=head2 tgetstr($self, $id, [$areap])

Returns a reference to termcap string entry for $id, or zero if it is not available. If $areap is defined and is a reference: if $id is a string then the found value is inserted at current pos()isition in ${$areap} and pos()isition is updated, otherwise (i.e. boolean and numeric cases) ${$areap} is overwritten with the found value. Only the first two characters of the id parameter are compared in lookups.

=head2 tigetstr($self, $id)

Returns a reference to terminfo string entry for $id, or -1 if $id is not a string capabilitty, or 0 it is canceled or absent from terminal description.

=head2 tvgetstr($self, $id, [$areap])

Search for the string variable $id. If found, return true and insert its value at pos()istion of eventual ${$areap}, this pos() being updated after the insert, return false in all other cases.

=head2 tputs($self, $str, $affcnt, $outc, @outcArgs)

Applies padding information to the string $str and outputs it. The $str must be a terminfo string variable or the return value from tparm(), tgetstr(), or tgoto(). $affcnt is the number of lines affected, or 1 if not applicable. $outc is a putchar-like routine to which the characters are passed, one at a time, as first argument, and @outcArgs as remaining arguments.

=head2 putp($self, $str)

Calls $self->tputs($str, 1, sub {print STDOUT shift}). Note that the output of putp always goes to stdout, not to the fildes specified in setupterm..

=head2 tparm($self, $string, @param)

Instantiates the string $string with parameters @param. Returns the string with the parameters applied.

=head2 tgoto($self, $string, $col, $row)

Instantiates the parameters into the given capability. The output from this routine is to be passed to tputs.

=head2 use_env($self[, $boolean])

Returns or set the use_env boolean. $boolean can be anything, this is internally convert to either 0 or 1.

=head1 SEE ALSO

L<Unix Documentation Project - terminfo|http://nixdoc.net/man-pages/HP-UX/man4/terminfo.4.html#Formal%20Grammar>

L<GNU Ncurses|http://www.gnu.org/software/ncurses/>

L<Marpa::R2|http://metacpan.org/release/Marpa-R2>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX-Database-Terminfo>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/jddurand/marpax-database-terminfo>

  git clone git://github.com/jddurand/marpax-database-terminfo.git

=head1 AUTHOR

jddurand <jeandamiendurand@free.fr>

=head1 CONTRIBUTOR

=for stopwords Jean-Damien Durand

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
