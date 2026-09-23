package ArgumentPoison;

use strict;
use warnings;
use B ();
use B::Deparse ();
use Cpanel::JSON::XS ();
use File::Spec ();
use File::Temp ();
use MIME::Base64 ();
use Scalar::Util qw(refaddr reftype blessed);
use overload ();

# The engine behind xt/argument_poison.t: replay real calls with a reference
# substituted for one argument at a time, capture everything that reaches
# tdjson, and look for the reference's address, its string form, or the
# reference itself in what went out.

my @CORE = ('EV::Telegram::TDLib');
my $JSON  = Cpanel::JSON::XS->new->utf8->allow_nonref;
my $CANON = Cpanel::JSON::XS->new->utf8->allow_nonref->canonical;
my $RETURNED = Cpanel::JSON::XS->new->utf8->allow_nonref->canonical->allow_blessed;
my $REFRE = qr/(?:HASH|ARRAY|CODE|GLOB|SCALAR|REF|Regexp|IO|LVALUE|FORMAT|VSTRING)\(0x[0-9a-f]+\)/i;
our $MARK = '__poison__';
our @KINDS = qw(HASH ARRAY CODE GLOB SCALAR);

sub new {
    my ($class, %arg) = @_;
    my $self = bless { %arg, wire => [], stat => {} }, $class;
    $self->{packages} = [ @CORE, @EV::Telegram::TDLib::ISA ];
    $self->load_schema;
    $self->load_surface;
    $self->install_capture;
    $self->{db} = File::Temp::tempdir(CLEANUP => 1);
    $self->open_client;
    return $self;
}

sub open_client {
    my ($self) = @_;
    $self->{td} = EV::Telegram::TDLib->new(api_id => 1, api_hash => 'x',
        database_directory => "$self->{db}/td", on_error => sub {});
}

# ---------------------------------------------------------------- schema

sub load_schema {
    my ($self) = @_;
    my (%func, %ctor, %subs);
    # the prebuilt Alien::TDLib that CI installs ships no td_api.h, so the
    # fallback is what CI runs: POISON_NO_TD_API=1 runs it here too
    my $header = $ENV{POISON_NO_TD_API} ? undef : eval {
        require Alien::TDLib;
        Alien::TDLib->dist_dir . '/include/td/telegram/td_api.h';
    };
    if (defined $header && open my $h, '<', $header) {
        my $src = do { local $/; <$h> };
        close $h;
        while ($src =~ /^class (\w+) final : public (\w+) \{\n(.*?)^\};/msg) {
            my ($name, $base, $body) = ($1, $2, $3);
            my %f;
            $f{$2} = $1 while $body =~ /^  ([\w<>]+) (\w+)_;$/mg;
            if ($base eq 'Function') {
                my ($ret) = $body =~ /using ReturnType = object_ptr<(\w+)>;/;
                $func{$name} = { ret => $ret, fields => \%f };
            } else {
                $ctor{$name} = { base => $base, fields => \%f };
                push @{ $subs{$base} }, $name;
            }
        }
    }
    if (keys %func > 500) {
        $self->{schema_source} = 'td_api.h';
    } else {
        # the shipped tables know object-typed slots only and no return types
        no warnings 'once';
        %func = %ctor = %subs = ();
        my $slots = \%EV::Telegram::TDLib::Schema::CLASS_SLOTS;
        for my $name (sort keys %EV::Telegram::TDLib::Schema::CLASS_BASE) {
            my $base = $EV::Telegram::TDLib::Schema::CLASS_BASE{$name};
            my %f = map {
                my $t = $slots->{$name}{$_};
                $_ => ($t =~ /\Aarray:(\w+)\z/ ? "array<object_ptr<$1>>" : "object_ptr<$t>")
            } keys %{ $slots->{$name} || {} };
            if ($base eq 'Function') { $func{$name} = { ret => undef, fields => \%f } }
            else { $ctor{$name} = { base => $base, fields => \%f }; push @{ $subs{$base} }, $name }
        }
        $self->{schema_source} = 'Schema.pm';
    }
    @$self{qw(func ctor subs)} = (\%func, \%ctor, \%subs);
    $self->{fake} = {};
}

sub fake {
    my ($self, $type, $depth) = @_;
    return 1   if $type eq 'int32' || $type eq 'int53';
    return '1' if $type eq 'int64';
    return 1.5 if $type eq 'double';
    return 's' if $type eq 'string';
    return ''  if $type eq 'bytes';
    return Cpanel::JSON::XS::true() if $type eq 'bool';
    if ($type =~ /\Aarray<(.+)>\z/) {
        return [] if $depth > 3;
        my $e = $self->fake($1, $depth + 1);
        return defined $e ? [$e] : [];
    }
    my $cls = $type =~ /\Aobject_ptr<(\w+)>\z/ ? $1 : $type;
    my $c = $self->{ctor}{$cls} ? $cls : ($self->{subs}{$cls} || [])->[0];
    return undef unless defined $c;
    my $o = { '@type' => $c };
    return $o if $depth > 4;
    my $f = $self->{ctor}{$c}{fields};
    for my $k (sort keys %$f) {
        my $v = $self->fake($f->{$k}, $depth + 1);
        $o->{$k} = $v if defined $v;
    }
    return $o;
}

# Built from the return type when td_api.h is there. Without it, the reply a
# t/ file injected for the same function stands in; failing that, a bare ok,
# which reaches no follow-up that reads a field of the reply.
sub reply_json {
    my ($self, $function, $extra) = @_;
    my $ret = $self->{func}{$function} ? $self->{func}{$function}{ret} : undef;
    my $j = $self->{fake}{$function} //= do {
        my $o = defined $ret ? $self->fake($ret, 0)
              : ($self->{replies}{$function} || [])->[0];
        my %o = ref $o eq 'HASH' ? %$o : ('@type' => 'ok');
        delete $o{'@extra'};
        $CANON->encode(\%o);
    };
    return '{"@extra":' . $JSON->encode("$extra") . ',' . substr($j, 1);
}

# ---------------------------------------------------------------- surface

my %PLUMBING = map { $_ => 1 } qw(send send_once send_retrying retry_attempt
    call guarded emit_error drain_error dispatch_raw handle_update closed
    abandon inject_raw execute);

sub load_surface {
    my ($self) = @_;
    my $dp = B::Deparse->new;
    my (%sub, %handler);
    no strict 'refs';
    for my $pkg (@{ $self->{packages} }) {
        $handler{ refaddr $_ } = 1 for values %{"${pkg}::UPDATES"};
    }
    # private helpers are read too: _folder is where the folder spec keys are
    for my $pkg (@{ $self->{packages} }) {
        for my $name (sort keys %{"${pkg}::"}) {
            next if $name !~ /\A_*[a-z]/;
            my $cv = *{"${pkg}::$name"}{CODE} or next;
            next if B::svref_2object($cv)->GV->STASH->NAME ne $pkg;
            # a public name defined twice is xt/mixin_collisions.t's to report
            next if $sub{$name} && $name =~ /\A[a-z]/;
            my $text = eval { $dp->coderef2text($cv) } // '';
            my (%keys, %deps);
            $keys{$1} = 1 while $text =~ /\{'([^'\$]+)'\}/g;
            while ($text =~ /\{((?:'[^']+',\s*)+'[^']+')\}/g) {
                my $s = $1;
                $keys{$1} = 1 while $s =~ /'([^']+)'/g;
            }
            $keys{$_} = 1 for captured_strings($cv);
            $deps{$1} = 1 while $text =~ /(?:->|\b)(\w+)\s*\(/g;
            $deps{$1} = 1 while $text =~ /->(\w+)\b/g;
            my ($first) = $text =~ /my\s*\(([^)]*)\)\s*=\s*\@_/;
            my $kind = !defined $first ? ($text =~ /\bshift\b|\$_\[0\]\{/ ? 'obj' : 'func')
                     : $first =~ /\A\s*(?:\$self|\$class|\$proto|undef)\b/ ? 'obj'
                     : 'func';
            # two private helpers of one name in different mixins are read as one
            if (my $twin = $sub{$name}) {
                %{ $twin->{own_keys} } = (%{ $twin->{own_keys} }, %keys);
                %{ $twin->{deps} } = (%{ $twin->{deps} }, %deps);
                $twin->{calls_opts} ||= $text =~ /\bopts\(/ ? 1 : 0;
                next;
            }
            $sub{$name} = {
                name => $name, pkg => $pkg, cv => $cv, kind => $kind,
                public => $name =~ /\A[a-z]/ ? 1 : 0,
                update_handler => $handler{ refaddr $cv } ? 1 : 0,
                own_keys => \%keys, deps => \%deps,
                calls_opts => $text =~ /\bopts\(/ ? 1 : 0,
            };
        }
    }
    $self->{sub} = \%sub;
    for my $m (values %sub) {
        my (%k, %seen, $opts);
        my @q = ([ $m->{name}, 0 ]);
        while (my $e = shift @q) {
            my ($n, $d) = @$e;
            my $s = $sub{$n};
            next if !$s || $seen{$n}++;
            $k{$_} = 1 for keys %{ $s->{own_keys} };
            $opts = 1 if $s->{calls_opts} && $d <= 2;
            next if $d >= 3;
            push @q, map { [ $_, $d + 1 ] }
                     grep { $sub{$_} && !$PLUMBING{$_} } keys %{ $s->{deps} };
        }
        delete @k{ grep { !/\A[a-z][a-z0-9_]*\z/ } keys %k };
        $m->{keys} = [ sort keys %k ];
        $m->{takes_opts} = $opts ? 1 : 0;
    }
}

# the file-scoped tables a sub closes over: %MEDIA_EXTRA, @RECIPIENT_FLAGS
# and the like hold option names that no constant subscript spells out
sub captured_strings {
    my ($cv) = @_;
    my $padlist = B::svref_2object($cv)->PADLIST;
    return () unless $padlist && $padlist->can('NAMES');
    my @names = $padlist->NAMES->ARRAY;
    my @vals  = $padlist->ARRAYelt(1)->ARRAY;
    my (%s, %seen);
    for my $i (0 .. $#names) {
        my $n = $names[$i];
        next unless ref $n && $n->can('PVX') && $n->can('FLAGS');
        my $pv = $n->PVX;
        next unless defined $pv && $pv =~ /\A[%@]/;
        next unless $n->FLAGS & B::PADNAMEf_OUTER();
        my @q = ($vals[$i]->object_2svref);
        while (@q) {
            my $x = shift @q;
            if (ref $x) {
                next if blessed $x || $seen{ refaddr $x }++;
                my $t = reftype $x;
                if ($t eq 'HASH') { $s{$_} = 1 for keys %$x; push @q, values %$x }
                elsif ($t eq 'ARRAY') { push @q, @$x }
                next;
            }
            $s{$x} = 1 if defined $x;
        }
    }
    return grep { /\A[a-z][a-z0-9_]*\z/ } keys %s;
}

# ---------------------------------------------------------------- capture

# The structure is taken where it is still Perl, so a reference passed
# through intact can be recognised by address; the JSON is taken where it
# leaves for tdjson, so what is checked is exactly what TDLib would parse.
# A request that fails to encode never gets its JSON and is not checked: its
# caller got a croak, which is loud rather than a silent leak.
sub install_capture {
    my ($self) = @_;
    my $wire = $self->{wire};
    my $attach = sub {
        my ($json, $sync) = @_;
        my ($open) = grep { !defined $_->{json} && !$_->{sync} == !$sync } reverse @$wire;
        if ($open) { $open->{json} = $json } else { push @$wire, { json => $json, sync => $sync } }
    };
    no strict 'refs';
    no warnings 'redefine';
    my $send_once = \&EV::Telegram::TDLib::send_once;
    my $execute   = \&EV::Telegram::TDLib::execute;
    my $exec_xs   = \&EV::Telegram::TDLib::_execute;
    *EV::Telegram::TDLib::send_once = sub {
        push @$wire, { req => $_[1] };
        return $send_once->(@_);
    };
    *EV::Telegram::TDLib::execute = sub {
        push @$wire, { req => $_[1], sync => 1 };
        return $execute->(@_);
    };
    *EV::Telegram::TDLib::_send    = sub { $attach->($_[1], 0) };
    *EV::Telegram::TDLib::_execute = sub { $attach->($_[0], 1); $exec_xs->(@_) };
}

my %KEEP = map { $_ => 1 } qw(json opt client_id auto_auth application_name seq keepalive);

sub reset_client {
    my ($self) = @_;
    # a call that closes the client (an injected Closed state, say) would
    # otherwise silently turn every later call into one that sends nothing
    $self->open_client unless $self->{td}{client_id};
    my $td = $self->{td};
    delete $td->{$_} for grep { !$KEEP{$_} } keys %$td;
    $td->{pending}   = {};
    $td->{abandoned} = {};
    $td->{cache}     = { options => { my_id => 777 } };
    $td->{state}     = 'authorizationStateReady';
}

sub decode_wire {
    my ($w) = @_;
    return $w->{obj} if exists $w->{obj};
    return undef unless defined $w->{json};
    my $o = eval { $JSON->decode($w->{json}) };
    $w->{obj} = ref $o eq 'HASH' ? $o : undef;
    return $w->{obj};
}

# run one call, answering whatever it leaves pending so the requests it only
# sends once a reply lands are captured too
sub invoke {
    my ($self, $m, $args) = @_;
    $self->reset_client;
    my $wire = $self->{wire};
    @$wire = ();
    my $td = $self->{td};
    my (@ret, $err);
    local $SIG{__WARN__} = sub {};
    my $ok = eval {
        if    ($m->{kind} eq 'func')  { @ret = $m->{cv}->(@$args) }
        elsif ($m->{kind} eq 'class') { @ret = $m->{cv}->('EV::Telegram::TDLib', @$args) }
        else                          { @ret = $m->{cv}->($td, @$args) }
        1;
    };
    $err = $ok ? undef : "$@";
    my $direct = @$wire;
    my ($answered, $injected) = ({}, 0);
    for my $round (1 .. 4) {
        eval { EV::run(EV::RUN_NOWAIT()); 1 };
        my @open;
        for my $w (@$wire) {
            my $o = decode_wire($w) or next;
            my $x = $o->{'@extra'};
            next if !defined $x || $answered->{$x}++ || !$td->{pending}{$x};
            push @open, [ $o->{'@type'} // '', $x ];
        }
        last unless @open;
        for my $p (@open) {
            last if ++$injected > 16;
            eval { $td->inject_raw($self->reply_json(@$p)); 1 };
        }
    }
    $_->{followup} = 1 for @$wire[ $direct .. $#$wire ];
    $self->{closed_by}{ $m->{name} }++ unless $td->{client_id};
    my @sent = grep { defined $_->{json} } @$wire;
    $self->{stat}{followups} += grep { $_->{followup} } @sent;
    $self->{stat}{calls}++;
    return { err => $err, ret => \@ret, wire => \@sent };
}

sub reached {
    my ($res) = @_;
    return 1 if !$res->{err} && @{ $res->{wire} };
    return 1 if !$res->{err} && grep { ref eq 'HASH' || ref eq 'ARRAY' } @{ $res->{ret} };
    return 0;
}

sub canon_wire {
    my ($res) = @_;
    return join "\n", map {
        my $o = decode_wire($_);
        $o ? do { my %c = %$o; delete $c{'@extra'}; $CANON->encode(\%c) } : $_->{json}
    } @{ $res->{wire} };
}

# ---------------------------------------------------------------- poisons

sub poison {
    my ($kind) = @_;
    return { $MARK => 1 } if $kind eq 'HASH';
    return [ $MARK ] if $kind eq 'ARRAY';
    return sub { $MARK } if $kind eq 'CODE';
    if ($kind eq 'GLOB') { open my $fh, '<', \(my $empty = '') or die $!; return $fh }
    return \(my $s = $MARK);
}

sub dclone {
    my ($v) = @_;
    return $v if !ref $v || blessed $v;
    my $t = reftype $v;
    return [ map { dclone($_) } @$v ] if $t eq 'ARRAY';
    return { map { $_ => dclone($v->{$_}) } keys %$v } if $t eq 'HASH';
    return $v;
}

sub get_at {
    my ($root, $path) = @_;
    my $c = $root;
    $c = $_ =~ /\A\{(.*)\}\z/s ? $c->{$1} : $c->[$_] for @$path;
    return $c;
}

sub set_at {
    my ($root, $path, $val) = @_;
    my $c = get_at($root, [ @$path[ 0 .. $#$path - 1 ] ]);
    my $last = $path->[-1];
    if ($last =~ /\A\{(.*)\}\z/s) { $c->{$1} = $val } else { $c->[$last] = $val }
}

sub label { join '', map { /\A\{/ ? $_ : "[$_]" } @{ $_[0] } }

sub is_spec_hash { ref $_[0] eq 'HASH' && !exists $_[0]{'@type'} }

# every positional, every element of an array argument, every field of a spec
# hash (one without an @type: a caller-built TL object passes through by
# design), each existing site and each key the code reads but the call left out
sub sites {
    my ($self, $m, $args) = @_;
    my (@site, @hashes);
    my $walk;
    $walk = sub {
        my ($v, $path, $depth) = @_;
        return if $depth > 6;
        if (ref $v eq 'ARRAY') {
            my @idx = 0 .. $#$v;
            @idx = grep { $_ < 2 || $_ == $#$v } @idx if $depth > 1 && !$self->{exhaustive};
            for my $i (@idx) {
                push @site, { path => [ @$path, $i ] };
                $walk->($v->[$i], [ @$path, $i ], $depth + 1);
            }
        } elsif (is_spec_hash($v) && $depth > 0) {
            push @hashes, [ $path, $v ];
            for my $k (sort keys %$v) {
                push @site, { path => [ @$path, "{$k}" ] };
                $walk->($v->{$k}, [ @$path, "{$k}" ], $depth + 1);
            }
        }
    };
    $walk->($args, [], 0);
    undef $walk;
    for my $h (@hashes) {
        my ($path, $v) = @$h;
        push @site, map { { path => [ @$path, "{$_}" ], added => 1 } }
                    grep { !exists $v->{$_} } @{ $m->{keys} };
    }
    if ($m->{takes_opts}) {
        my %have = map { defined && !ref ? ($_ => 1) : () } @$args;
        push @site, map { { opt => $_ } } grep { !$have{$_} } @{ $m->{keys} };
    }
    return @site;
}

sub apply_site {
    my ($args, $site, $value) = @_;
    my $a = dclone($args);
    if (defined $site->{opt}) {
        my @a = @$a;
        my $cb = @a && ref $a[-1] eq 'CODE' ? pop @a : undef;
        push @a, $site->{opt}, $value;
        push @a, $cb if $cb;
        return \@a;
    }
    set_at($a, $site->{path}, $value);
    return $a;
}

sub site_label {
    my ($site) = @_;
    return "+opt $site->{opt}" if defined $site->{opt};
    my $l = label($site->{path});
    $l =~ s/\{([^{}]*)\}\z/{+$1}/ if $site->{added};
    return $l;
}

# ---------------------------------------------------------------- checker

sub addresses_in {
    my ($v, $out, $seen) = @_;
    return unless ref $v;
    return if $seen->{ refaddr $v }++;
    push @$out, refaddr $v;
    return if blessed $v;
    my $t = reftype $v;
    if ($t eq 'ARRAY') { addresses_in($_, $out, $seen) for @$v }
    elsif ($t eq 'HASH') { addresses_in($_, $out, $seen) for values %$v }
}

sub matcher {
    my (@addr) = @_;
    my @alt = map { (sprintf('%x', $_), "$_") } @addr;
    return undef unless @alt;
    my $re = join '|', map { quotemeta } sort { length $b <=> length $a } @alt;
    return qr/($re)/i;
}

# findings for one decoded request: [ class, path, detail ]. The marker is
# only trusted as a hash key: as a string it is a legitimate element of a
# string list built from the ARRAY poison, which is the conversion working.
sub scan_request {
    my ($self, $obj, $ctx) = @_;
    my @out;
    my $walk;
    $walk = sub {
        my ($v, $path) = @_;
        if (ref $v eq 'HASH') {
            push @out, [ 'passed-through', $path, 'the HASH poison or a copy of it' ]
                if $ctx->{marker} && exists $v->{$MARK};
            for my $k (sort keys %$v) {
                next if $k eq '@extra';
                push @out, $self->scan_string($k, "$path\{key}", $ctx);
                $walk->($v->{$k}, "$path.$k");
            }
        } elsif (ref $v eq 'ARRAY') {
            $walk->($v->[$_], "$path\[$_]") for 0 .. $#$v;
        } elsif (!ref $v && defined $v) {
            push @out, $self->scan_string($v, $path, $ctx);
        }
    };
    $walk->($obj, $obj->{'@type'} // '?');
    undef $walk;
    return @out;
}

# the poison itself inside the request as built, before encoding: the only
# way to see an ARRAY passed through intact rather than rebuilt
sub scan_identity {
    my ($self, $req, $poison) = @_;
    my $pa = refaddr $poison;
    my (@out, %seen);
    my $walk;
    $walk = sub {
        my ($v, $path) = @_;
        return unless ref $v;
        return if $seen{ refaddr $v }++;
        if (refaddr $v == $pa) {
            push @out, [ 'passed-through', $path, 'the ' . reftype($v) . ' poison itself' ];
            return;
        }
        return if blessed $v;
        if (reftype $v eq 'HASH') {
            for my $k (sort keys %$v) {
                next if $k eq '@extra';
                $walk->($v->{$k}, "$path.$k");
            }
        } elsif (reftype $v eq 'ARRAY') {
            $walk->($v->[$_], "$path\[$_]") for 0 .. $#$v;
        }
    };
    $walk->($req, (ref $req eq 'HASH' ? $req->{'@type'} : undef) // '?');
    undef $walk;
    return @out;
}

sub scan_string {
    my ($self, $s, $path, $ctx) = @_;
    my @out;
    push @out, [ 'stringified', $path, $1, $s ] if $s =~ /($REFRE)/;
    my $re = $ctx->{addr_re};
    if ($re && $s =~ $re) {
        push @out, [ 'address', $path, $s, $s ];
    } elsif ($s =~ /\A-?[0-9]{9,20}\z/ && abs($s) > 2**32) {
        for my $a (@{ $ctx->{addr} }) {
            next unless abs($s - $a) <= 65536;
            push @out, [ 'address', $path, "$s (within 64K of $a)", $s ];
            last;
        }
    }
    if (length($s) >= 8 && length($s) % 4 == 0 && $s =~ m{\A[A-Za-z0-9+/]+={0,2}\z}) {
        my $d = MIME::Base64::decode_base64($s);
        push @out, [ 'base64', $path, "decodes to $1", $s ] if $d =~ /($REFRE)/;
        push @out, [ 'base64', $path, "decodes to $1", $s ] if $re && $d =~ $re;
    }
    return @out;
}

sub scan_return {
    my ($self, $ret, $ctx) = @_;
    my @out;
    my %seen;
    my $walk;
    $walk = sub {
        my ($v, $path) = @_;
        if (ref $v) {
            return if blessed $v || $seen{ refaddr $v }++;
            my $t = reftype $v;
            if ($t eq 'HASH') { $walk->($v->{$_}, "$path.$_") for sort keys %$v }
            elsif ($t eq 'ARRAY') { $walk->($v->[$_], "$path\[$_]") for 0 .. $#$v }
            return;
        }
        push @out, $self->scan_string($v, $path, $ctx) if defined $v;
    };
    $walk->($ret->[$_], "RETURN[$_]") for 0 .. $#$ret;
    undef $walk;
    return @out;
}

# every finding in one call's capture, each tagged with the request it sits in
sub check {
    my ($self, $res, $args, $poison, $inner) = @_;
    my @addr;
    if ($poison) { addresses_in($poison, \@addr, {}) }
    else         { addresses_in($args, \@addr, {}) }
    my $ctx = { addr => \@addr, addr_re => matcher(@addr), marker => $poison ? 1 : 0 };
    my @found;
    for my $w (@{ $res->{wire} }) {
        my $o = decode_wire($w);
        my @f = $o ? $self->scan_request($o, $ctx)
                   : map { [ 'stringified', 'raw', $_, $_ ] } $w->{json} =~ /($REFRE)/g;
        if ($poison && ref $w->{req}) {
            push @f, $self->scan_identity($w->{req}, $_) for grep { defined } $poison, $inner;
        }
        my %dup;
        push @found, map { { class => $_->[0], field => $_->[1], detail => $_->[2],
                             needle => $_->[3] // $MARK, wire => $w->{json},
                             sync => $w->{sync}, followup => $w->{followup} } }
                     grep { !$dup{"$_->[0] $_->[1]"}++ } @f;
    }
    if (my @r = $self->scan_return($res->{ret}, $ctx)) {
        my $json = 'returned ' . (eval { $RETURNED->encode($res->{ret}) } // '(unencodable)');
        push @found, map { { class => $_->[0], field => $_->[1], detail => $_->[2],
                             needle => $_->[3], wire => $json } } @r;
    }
    return @found;
}

# ---------------------------------------------------------------- constructor

my @AUTH_STATES = map { "authorizationState$_" }
    qw(WaitTdlibParameters WaitPhoneNumber WaitRegistration WaitEmailAddress
       WaitEmailCode WaitCode WaitPassword);

# A fresh client per call: its options only reach the wire once TDLib walks
# the login states, and each credential handler submits $$credential.
sub drive_ctor {
    my ($self, $opt, $credential) = @_;
    my $wire = $self->{wire};
    @$wire = ();
    local $SIG{__WARN__} = sub {};
    my $submit = sub { my $s = $_[1]; eval { $s->($$credential); 1 } };
    my $td = eval {
        EV::Telegram::TDLib->new(api_id => 1, api_hash => 'x',
            database_directory => "$self->{db}/ctor", on_error => sub {},
            (map { $_ => $submit } qw(on_code on_password on_email on_email_code)),
            %$opt);
    };
    $self->{stat}{ctor_calls}++;
    return { err => "$@", wire => [], ret => [] } unless $td;
    eval { $td->login(sub {}); 1 };
    for my $state (@AUTH_STATES) {
        my $j = $JSON->encode({ '@type' => 'updateAuthorizationState',
                                authorization_state => { '@type' => $state, code_info => {} } });
        eval { $td->inject_raw($j); 1 };
    }
    eval { EV::Telegram::TDLib::closed($td); 1 };
    return { err => undef, wire => [ grep { defined $_->{json} } @$wire ], ret => [] };
}

# ---------------------------------------------------------------- rendering

sub render {
    my ($v, $poison) = @_;
    return 'undef' unless defined $v;
    if (ref $v) {
        return '<' . reftype($v) . ' poison>' if $poison && refaddr $v == refaddr $poison;
        return 'sub {...}' if ref $v eq 'CODE';
        return ref($v) . '->new(' . render("$v") . ')' if blessed $v && overload::Method($v, '""');
        return ref $v if blessed $v;
        return '[' . join(', ', map { render($_, $poison) } @$v) . ']' if reftype $v eq 'ARRAY';
        return '{ ' . join(', ', map { (/\A[a-z_]\w*\z/i ? $_ : "'$_'") . ' => ' . render($v->{$_}, $poison) }
                                 sort keys %$v) . ' }'
            if reftype $v eq 'HASH';
        return '\\' . render($$v, $poison) if reftype $v eq 'SCALAR' && !ref $$v;
        return lc reftype $v;
    }
    return $v if $v =~ /\A-?[0-9]+(?:\.[0-9]+)?\z/;
    (my $s = $v) =~ s/([\\'])/\\$1/g;
    return "'$s'" unless $s =~ /[^\x20-\x7e]/;
    # a diag line must stay bytes: a wide character would warn from Test2
    ($s = $v) =~ s/([\\"\$\@])/\\$1/g;
    $s =~ s/([^\x20-\x7e])/sprintf '\\x{%x}', ord $1/ge;
    return qq("$s");
}

sub render_call {
    my ($m, $args, $poison) = @_;
    my $inv = $m->{kind} eq 'obj' ? '$td->' : $m->{kind} eq 'class' ? 'EV::Telegram::TDLib->' : "$m->{pkg}::";
    return $inv . $m->{name} . '(' . join(', ', map { render($_, $poison) } @$args) . ')';
}

sub trim_wire {
    my ($wire, $needle, $max) = @_;
    $max //= 260;
    return $wire if length $wire <= $max;
    my $at = defined $needle ? index($wire, $needle) : -1;
    $at = index($wire, $MARK) if $at < 0;
    $at = 0 if $at < 0;
    my $from = $at - int($max / 2);
    $from = 0 if $from < 0;
    return ($from ? '...' : '') . substr($wire, $from, $max) . '...';
}

# ---------------------------------------------------------------- harvest

# Each t/ file runs as a child of this process, with this process's @INC so a
# -I pointing at another lib reaches the children too, and with the
# environment the caller had before this test adjusted it.
sub harvest {
    my ($self, $env, @tests) = @_;
    my ($fh, $out) = File::Temp::tempfile(UNLINK => 1);
    close $fh;
    local %ENV = (%ENV, %$env, POISON_HARVEST_OUT => $out);
    delete @ENV{ grep { !defined $ENV{$_} } keys %ENV };
    my @inc = map { "-I$_" } grep { !ref } @INC;
    my @failed;
    # silenced in the parent rather than between fork and exec: the TDLib
    # reader thread is running, and a forked child should do nothing but exec
    open my $saved_out, '>&', \*STDOUT or die "dup STDOUT: $!";
    open my $saved_err, '>&', \*STDERR or die "dup STDERR: $!";
    open STDOUT, '>', File::Spec->devnull or die "devnull: $!";
    open STDERR, '>&', \*STDOUT or die "devnull: $!";
    for my $t (@tests) {
        system { $^X } $^X, @inc, '-MPoisonHarvest', $t;
        push @failed, "$t (exit " . ($? >> 8) . ', signal ' . ($? & 127) . ')' if $?;
    }
    open STDOUT, '>&', $saved_out or die "restore STDOUT: $!";
    open STDERR, '>&', $saved_err or die "restore STDERR: $!";
    my @rows;
    open my $in, '<', $out or die "$out: $!";
    while (my $l = <$in>) {
        chomp $l;
        if ($l =~ /\AREPLY\t(\w+)\t(.*)\z/s) {
            my ($type, $json) = ($1, $2);
            my $o = eval { $JSON->decode($json) };
            push @{ $self->{replies}{$type} }, $o if ref $o eq 'HASH';
            next;
        }
        my ($pkg, $name, $kind, $died, $dump) = split /\t/, $l, 5;
        push @rows, { pkg => $pkg, name => $name, kind => $kind, died => $died, dump => $dump };
    }
    close $in;
    return (\@rows, \@failed);
}

# ---------------------------------------------------------------- helpers swap

# the helpers every mixin aliases in from the core; the positive control swaps
# them for the unguarded forms the round-20 conversion replaced
sub helper_globs {
    my ($self, $name) = @_;
    no strict 'refs';
    my $orig = \&{"EV::Telegram::TDLib::$name"};
    return grep { defined *{"${_}::$name"}{CODE} && *{"${_}::$name"}{CODE} == $orig }
           @{ $self->{packages} };
}

1;
