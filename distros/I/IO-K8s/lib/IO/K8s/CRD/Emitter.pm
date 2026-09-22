package IO::K8s::CRD::Emitter;
# ABSTRACT: Render generated IO::K8s classes as house-style Perl source
our $VERSION = '1.108';
use v5.10;
use Moo;
use Carp qw( croak );
# Deliberate exception to the "no Data::Dumper in shipped code" house rule:
# _scalar_literal below renders a single scalar as a Perl literal via Dumper,
# to reproduce its number-vs-string quoting byte-for-byte. Codegen, not debug.
use Data::Dumper ();
use Digest::SHA qw( sha1_hex );
use re ();
use Types::Standard qw( Str HashRef );
use IO::K8s::AutoGen ();
use IO::K8s::Resource ();
use IO::K8s::Role::Resource ();



has base    => (is => 'ro', isa => Str, required => 1);
has names   => (is => 'ro', isa => HashRef, default => sub { {} });
has overlay => (is => 'ro', isa => HashRef, default => sub { {} });
has version => (is => 'ro', isa => Str, default => sub { $VERSION });

# The reverse of IO::K8s::Resource's class-prefix map (full namespace ->
# short prefix), longest full namespace first so a more specific prefix
# ('IO::K8s::Api::Core') is tried before a shorter one that would also
# match as a '::'-bounded prefix. Built once per emitter instance -- the
# map itself never changes mid-render.
has _prefix_pairs => (is => 'lazy', init_arg => undef);

sub _build__prefix_pairs {
    my $prefixes = IO::K8s::Resource::class_prefixes();
    return [
        sort { length($b->[1]) <=> length($a->[1]) }
        map  { [ $_, $prefixes->{$_} ] } keys %$prefixes
    ];
}


# Bounds only the suffix this method appends below `base` -- AutoGen's own
# $MAX_CLASS_NAME bounds the full namespace-qualified name IT generates,
# which this has no control over and does not need to duplicate.
my $MAX_PACKAGE_SUFFIX = 200;

# A filesystem path component -- and much tooling that shells out to a file
# name -- tops out around 255 bytes. A long `base` plus an otherwise-short
# suffix can still cross that even when the suffix alone passes the check
# above, so the joined package name as a whole is capped too.
my $MAX_PACKAGE_LENGTH = 255;

sub package_for {
    my ($self, $class) = @_;
    my $root = $self->{_root} // croak 'package_for needs a render() first';
    return $self->base . '::' . $self->names->{$class} if $self->names->{$class};
    my $kind = (split /::/, $root)[-1];

    # The field path, independent of whatever (possibly hash-shortened)
    # Perl name AutoGen gave the class -- see the POD above.
    my $path = IO::K8s::AutoGen::class_path($class);
    unless (defined $path) {
        ($path = $class) =~ s/^\Q$root\E(?:::)?//;
    }

    # overlay.names is keyed by that same logical path, not by $class --
    # unlike L</names>, an overlay is written once per Kind against the
    # upstream Go types and has no way to know what (possibly shortened)
    # Perl name AutoGen happened to give a class this run.
    if (length $path and my $overlay_names = $self->overlay->{names}) {
        if (my $name = $overlay_names->{$path}) {
            # k120: an overlay name carrying '::' (or a leading '+') is an
            # ABSOLUTE target -- a fully-qualified package under another
            # version directory of this same provider (ExternalSecrets'
            # v1alpha1 generators reuse the v1 Auth types) or any other
            # checked-in class. It is used verbatim rather than joined below
            # $base, and _is_external_ref treats it as a bare reference that
            # this render does not itself emit a file for. A bare name (no
            # '::') is a package under $base as before.
            $name =~ s/^\+//;
            return $name =~ /::/ ? $name : $self->base . '::' . $name;
        }
    }

    my $joined = join '', $kind, split /::/, $path;
    my $full   = $self->base . '::' . $joined;
    if (length($joined) > $MAX_PACKAGE_SUFFIX || length($full) > $MAX_PACKAGE_LENGTH) {
        $joined = $kind . '_' . substr(sha1_hex($path), 0, 10);
        $full   = $self->base . '::' . $joined;
    }
    return $full;
}


sub render {
    my ($self, $root) = @_;
    $self->{_root} = $root;   # kept after render() so package_for() stays usable
    my %files;
    my %functional;
    my %origins;
    my @todo = ($root);
    my %seen;
    while (my $class = shift @todo) {
        next if $seen{$class}++;
        my ($source, @nested) = $self->_render_class($class);
        my $functional = $self->_functional_source($source);
        (my $path = $self->package_for($class)) =~ s{::}{/}g;
        $path .= '.pm';
        if (exists $files{$path}) {
            croak 'IO::K8s::CRD::Emitter: target ' . $path
                . ' has non-identical generated classes ' . $origins{$path}
                . ' and ' . $class
                if $functional{$path} ne $functional;
        }
        # Deliberately retain the last equivalent source, matching the
        # overwrite selection render() made before collision detection.
        $files{$path} = $source;
        $functional{$path} = $functional;
        $origins{$path} = $class;
        push @todo, @nested;
    }
    return \%files;
}

# The collision identity is the generated class's executable declaration
# surface. Contextual # ABSTRACT and POD text describe the same wire class
# differently across upstream GVKs; they must not turn that alias into a
# rejected collision. `use utf8` is equally documentation-only when no
# remaining executable source needs it, because _render_class adds it for
# non-ASCII POD too.
sub _functional_source {
    my ($self, $source) = @_;
    (my $functional = $source) =~ s/\n\n(?:=encoding UTF-8\n\n=cut\n\n)?=attr\b.*\z//s;
    $functional =~ s/^# ABSTRACT:.*\n//m;
    my $without_utf8 = $functional;
    $without_utf8 =~ s/^use utf8;\n//m;
    $functional = $without_utf8 unless $without_utf8 =~ /[^\x00-\x7F]/;
    return $functional;
}

# A generated class is one this emitter renders; anything else is stock.
# IO::K8s::AutoGen::class_root is authoritative when it knows the class --
# it is exactly the bookkeeping _nested_class itself relies on, so it is
# never fooled by a name merely looking related. Fall back to the string
# prefix test for anything AutoGen has no record of (a stock class, or a
# class from a namespace this emitter never generated) -- a plain
# index()==0 test on its own would also match a sibling whose name merely
# starts with the same string -- root ...::V1::Knob would wrongly claim
# ...::V1::KnobExtra as its own -- so the fallback still requires the '::'
# boundary (or an exact match on the root itself).
sub _is_generated {
    my ($self, $class) = @_;
    my $root = $self->{_root};
    return 1 if IO::K8s::AutoGen::class_root($class) eq $root;
    return $class eq $root || index($class, "$root\::") == 0;
}

# k120: a generated class an overlay `names` entry redirects to an ABSOLUTE
# package outside this render's own `base` -- a cross-version reference to a
# type another version directory already ships. It is still referenced
# (_class_ref emits '+<that package>' via package_for, exactly as a
# hand-written class writes it), but this render neither recurses into it nor
# writes a file for it: the version directory that owns the target renders it.
# A normal generated class resolves under `base::...` and is not external.
sub _is_external_ref {
    my ($self, $class) = @_;
    return 0 unless $self->_is_generated($class);
    return index($self->package_for($class), $self->base . '::') != 0;
}

sub _class_ref {
    my ($self, $class) = @_;

    # k120: an overlay redirect to an absolute package outside this render
    # (a cross-version provider type, or a core class the reuse heuristic
    # would not pick on its own -- a single-key {name} that stays
    # Core::V1::LocalObjectReference). Reference the TARGET package exactly
    # as a hand-written class does: a core/apimachinery type by its short
    # prefix (Core::V1::X, Meta::V1::X), any other package -- a cross-version
    # provider type -- kept in the full '+IO::K8s::...' form. class_prefixes()
    # also carries provider prefixes (for the DSL's own expansion), so
    # restricting the shortening to the core groups here is what keeps a
    # provider cross-ref from collapsing to 'ExternalSecrets::V1::X' where
    # lib writes '+IO::K8s::ExternalSecrets::V1::X'.
    if ($self->_is_external_ref($class)) {
        my $target = $self->package_for($class);
        return "'+$target'" unless $target =~ /^IO::K8s::(?:Api|Apimachinery)::/;
        $class = $target;
    }
    elsif ($self->_is_generated($class)) {
        return "'+" . $self->package_for($class) . "'";
    }

    # IO::K8s::Resource::class_prefixes(), longest full namespace first --
    # see _build__prefix_pairs.
    for my $pair (@{ $self->_prefix_pairs }) {
        my ($short, $full) = @$pair;
        next unless index($class, "$full\::") == 0;
        return "'$short\::" . substr($class, length($full) + 2) . "'";
    }

    # class_prefixes() only carries the groups with their own entry
    # (Core, Apps, Meta, ...); a shipped IO::K8s::Api::<X> subgroup with no
    # entry of its own (e.g. Apiserverinternal) still renders the short way
    # a hand-written class under it would, by dropping just the common
    # IO::K8s::Api:: prefix -- the same fallback the old @SHORT_PREFIXES
    # catch-all gave it.
    return "'" . substr($class, length('IO::K8s::Api::')) . "'"
        if index($class, 'IO::K8s::Api::') == 0;

    return "'+$class'";
}

# The apimachinery Quantity pattern carried by the affected CRD schemas.
# It is an exact wire contract, so a merely similar pattern must not select
# Quantity during rendering.
my $CANONICAL_QUANTITY_PATTERN = q{^(\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))))?$};

# `u` is the implicit UTF-8 artifact and `p` does not affect matching, the
# same two flags _pattern_literal ignores. Every other flag changes the
# contract and keeps the field as IntOrStr.
sub _is_canonical_quantity_pattern {
    my ($value) = @_;
    return defined($value) && $value eq $CANONICAL_QUANTITY_PATTERN unless ref $value;
    return 0 unless ref $value eq 'Regexp';

    my ($pattern, $flags) = re::regexp_pattern($value);
    $flags = '' unless defined $flags;
    $flags =~ s/[up]//g;
    return $pattern eq $CANONICAL_QUANTITY_PATTERN && !length $flags;
}

sub _is_quantity_entry {
    my ($info) = @_;
    return unless $info->{is_int_or_string};
    my $opts = $info->{options};
    return unless $opts && exists $opts->{pattern};
    return _is_canonical_quantity_pattern($opts->{pattern});
}

# The DSL type spec for one registry entry, as source. Returns
# ($source, $nested_class_or_undef). $class/$key are diagnostic context
# only, for the croak below -- the caller already has both.
sub _type_source {
    my ($self, $info, $class, $key) = @_;
    my $nested = $info->{class} && $self->_is_generated($info->{class})
        && !$self->_is_external_ref($info->{class}) ? $info->{class} : undef;
    return ($self->_class_ref($info->{class}), $nested)                if $info->{is_object};
    return ('[' . $self->_class_ref($info->{class}) . ']', $nested)    if $info->{is_array_of_objects};
    return ('{ ' . $self->_class_ref($info->{class}) . ' => 1 }', $nested) if $info->{is_hash_of_objects};
    return ('[Str]')      if $info->{is_array_of_str};
    return ('[Int]')      if $info->{is_array_of_int};
    return ('[Bool]')     if $info->{is_array_of_bool};
    return ('[Num]')      if $info->{is_array_of_num};
    return ('[IntOrStr]') if $info->{is_array_of_int_or_string};
    return ('[Quantity]') if $info->{is_array_of_quantity};
    return ('[Time]')     if $info->{is_array_of_time};
    return ('[ {} ]')     if $info->{is_array_of_hash};
    return ('[ [] ]')     if $info->{is_array_of_array};
    return ('{ Str => 1 }')      if $info->{is_hash_of_str};
    return ('{ Int => 1 }')      if $info->{is_hash_of_int};
    return ('{ Num => 1 }')      if $info->{is_hash_of_num};
    return ('{ Bool => 1 }')     if $info->{is_hash_of_bool};
    return ('{ Quantity => 1 }') if $info->{is_hash_of_quantity};
    return ('{ Time => 1 }')     if $info->{is_hash_of_time};
    return ('{ IntOrStr => 1 }') if $info->{is_hash_of_int_or_string};
    return ('Str')      if $info->{is_str};
    return ('Int')      if $info->{is_int};
    return ('Num')      if $info->{is_num};
    return ('Bool')     if $info->{is_bool};
    return ('Quantity') if _is_quantity_entry($info);
    return ('IntOrStr') if $info->{is_int_or_string};
    return ('Quantity') if $info->{is_quantity};
    return ('Time')     if $info->{is_time};
    croak "IO::K8s::CRD::Emitter: registry entry with no recognizable type for field '$key' of $class";
}

# A pattern string re-quoted into `qr/.../ ` source is interpolated by Perl
# just like a double-quoted string: an unescaped '@' tries to interpolate an
# array -- '^[a-z]+@example\.com$' would die "Global symbol '@example'
# requires explicit package name" at compile time -- and an unescaped '$'
# not already meaning "end of string/group/alternative" tries to
# interpolate a scalar. '@' is always escaped, unconditionally: '\@' means
# a literal '@' in a regex no matter what follows it, so escaping it can
# never change what the pattern matches, and it is the only way to rule out
# every '@'-led interpolation form at once -- '@name', '@{...}', and
# '@$name'/'@$' (an array deref through a scalar, including the
# punctuation variable $) or $| that '@$' immediately before a bare ')' or
# '|' would reach for). A narrower rule that only escaped '@' before a word
# character or '{' missed exactly that last form: '(a@$)' left both the
# '@' (not followed by \w/{) and the '$' (immediately before ')') bare,
# and '@$)' interpolated away to nothing, silently turning the pattern
# into '(a)'. '$' cannot be escaped unconditionally the same way -- unlike
# '@', a bare '$' is meaningful in a regex (the end-of-string/line anchor),
# so it is only escaped when it is NOT in one of the anchor positions
# ("...$", "(...$)", "...$|...") a schema pattern realistically uses;
# escaping it there would turn the anchor into a literal '$' character
# instead of leaving it as an anchor -- wrong regex, not just wrong Perl.
# Walks the pattern one (possibly backslash-escaped) unit at a time so an
# already-escaped character -- notably a pattern that came in as
# '\/api\/v1' -- is left exactly as it was instead of gaining a second
# backslash.
#
# Since k114 only the '/' branch normally reaches a rendered file: an escape
# this adds that Perl would still be carrying in the compiled pattern makes
# _pattern_literal reject the qr// form altogether and emit a plain string
# instead, so the '@'/'$'/non-ASCII branches now mostly serve the round-trip
# probe that decides that. They are not dead either way -- a '@' left bare
# would interpolate the candidate away and the probe would then compare
# against a different pattern, which is the same bug one step earlier.
sub _escape_pattern_body {
    my ($pattern) = @_;
    my $out = '';
    while ($pattern =~ /\G(?:(\\.)|(.))/gs) {
        if (defined $1) {
            $out .= $1;
            next;
        }
        my $c = $2;
        if ($c eq '/') {
            $out .= '\\/';
        }
        elsif ($c eq '@') {
            $out .= '\\@';
        }
        elsif ($c eq '$') {
            my $rest = substr($pattern, pos($pattern));
            $out .= ($rest eq '' || $rest =~ /\A[)|]/) ? '$' : '\\$';
        }
        elsif (ord($c) > 0x7F) {
            # A codepoint above ASCII, interpolated raw into 'qr/.../ ',
            # only round-trips through this emitted .pm file when it is
            # BOTH saved to disk as UTF-8 bytes AND compiled under 'use
            # utf8' -- neither of which this method controls once the
            # caller has the rendered source in hand. \x{HEX} means the
            # same codepoint either way: a schema pattern like
            # '^[0-9]+\x{b5}s$' matches '100\x{b5}s' (100, MICRO SIGN, s)
            # exactly like the generated class does, independent of that
            # pragma. See render()'s own use-utf8/=encoding decision for
            # the one place non-ASCII text still goes into the file
            # unescaped: a schema's free-form 'description', in POD.
            $out .= sprintf('\x{%x}', ord($c));
        }
        else {
            $out .= $c;
        }
    }
    return $out;
}

# A double-quoted Perl string literal that stays ASCII-only regardless of
# what $str holds: '\', '"', '$' and '@' are escaped so the double-quoted
# form -- unlike Data::Dumper's default single-quoted style, this one DOES
# interpolate -- carries nothing but the literal value, and every character
# above ASCII becomes \x{HEX}, the same escape and the same reason as
# _escape_pattern_body above. Single-quoted Perl strings cannot carry a
# \x{...} escape at all (only \\ and \' mean anything inside them), which is
# why a value that needs this can't just be tacked onto Data::Dumper's
# normal single-quoted output.
sub _quote_utf8_string {
    my ($str) = @_;
    (my $escaped = $str) =~ s{ ([\\"\$\@]) | ([^\x00-\x7F]) }{
        defined $1 ? "\\$1" : sprintf('\x{%x}', ord($2))
    }gex;
    return qq{"$escaped"};
}

# One scalar option value (an enum member, or `default`), rendered via
# Data::Dumper's own single-quoted style for anything ASCII -- byte-for-byte
# what every rendered file already produced -- or, for anything that is
# not, via _quote_utf8_string above.
sub _scalar_literal {
    my ($value) = @_;
    return _quote_utf8_string($value)
        if !ref($value) && defined($value) && $value =~ /[^\x00-\x7F]/;
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Useqq    = 0;
    my $dumped = Data::Dumper::Dumper($value);
    $dumped =~ s/^\s+|\s+$//g;
    return $dumped;
}

# A Perl literal for an option value. A Regexp is rendered as qr/.../, read
# back out via re::regexp_pattern in LIST context -- the scalar-context form
# returns the whole "(?^:PATTERN)" wrapper, which is not what a hand-written
# `k8s x => Str, { pattern => qr/.../ };` line looks like anywhere else in
# this distribution. 'u' is dropped from the flags before they are appended:
# every pattern IO::K8s::CRD compiles starts life as a UTF8-flagged string
# out of YAML::PP, and interpolating one into qr/$p/ tags the result with an
# implicit 'u' that reflects nothing the CRD schema's `pattern` asked for --
# rendering it back would forge a modifier into the source. A real modifier
# a pattern did ask for (i, m, s, x) still comes through.
sub _literal {
    my ($value) = @_;
    if (ref $value eq 'Regexp') {
        my ($pattern, $flags) = re::regexp_pattern($value);
        my $body = _escape_pattern_body($pattern);
        $flags =~ s/u//g if defined $flags;
        return "qr/$body/" . ($flags // '');
    }
    if (ref $value eq 'ARRAY' && @$value) {
        # The qw() shorthand only for a list of genuinely bareword-safe
        # values (D6-friendly enum members like Always/IfNotPresent): word
        # characters, dots, colons, dashes and slashes -- ASCII only, never
        # empty. An enum entry that is the empty string -- a real, if
        # unusual, upstream value -- would otherwise vanish: 'qw( Always
        # IfNotPresent)' from ('', 'Always', 'IfNotPresent') silently drops
        # the '', and the emitted class would then reject a value the
        # generated one accepts. A non-ASCII entry is excluded the same
        # way even though Perl's \w matches a Unicode letter like 'µ' when
        # the string carries the UTF8 flag (as one loaded from a CRD
        # manifest does) -- qw() has no escape syntax at all, so a raw
        # non-ASCII byte inside it would be exactly the bug this emitter
        # exists to avoid.
        my $qw_safe = !grep { ref $_ || !defined $_ || $_ !~ /\A[\w.:\/-]+\z/ || $_ =~ /[^\x00-\x7F]/ } @$value;
        return '[qw(' . join(' ', @$value) . ')]' if $qw_safe;
        # Not qw()-safe: render element by element rather than handing the
        # whole arrayref to Data::Dumper, so a non-ASCII element can switch
        # to the double-quoted \x{HEX} form on its own while its ASCII
        # siblings keep Dumper's ordinary single-quoted style -- Dumper has
        # no way to quote just one element of a list differently.
        return '[' . join(',', map { _scalar_literal($_) } @$value) . ']';
    }
    return _scalar_literal($value);
}

# A `pattern` option specifically (k110, k114). Everything else still goes
# through _literal above.
#
# The qr/.../ form stays the default: it is what every hand-written class in
# this distribution writes, and IO::K8s::CRD translates one back into the
# ECMA262 text a CRD's openAPIV3Schema.pattern is specified in.
#
# What it cannot translate is a regex FLAG. A CRD pattern is a bare string
# with nowhere to carry one, so IO::K8s::CRD croaks on a flagged qr// rather
# than dropping the flag and emitting a pattern that means something else.
# Rendering `qr/.../i` would therefore hand the caller a class that compiles,
# validates correctly in Perl, and then cannot be turned back into a CRD --
# which is how IO::K8s::PrometheusOperator::V1::RuleGroup came to carry one
# (upstream's own `^(?i)(abort|warn)?$` picked up an 'i' flag on the way
# through AutoGen's qr/$p/, and this method wrote it back out).
#
# So a flagged pattern is folded back into the pattern TEXT as an inline
# (?flags) group -- the spelling upstream uses anyway, and one Go's regexp
# engine takes -- and rendered as a plain string. That is the escape hatch
# IO::K8s::CRD passes through untouched: whatever upstream put in its CRD
# goes back out unchanged, because upstream knows what its apiserver
# accepts. Perl-side validation is unaffected either way -- Resource.pm
# compiles a string pattern with qr/$p/, and an inline (?i) sets exactly
# what the /i modifier set.
#
# The other thing a qr// cannot always carry is the pattern's own BYTES
# (k114). Rendering one means writing the text back as `qr/.../` SOURCE, and
# _escape_pattern_body has to escape whatever Perl would otherwise
# interpolate -- an '@', a '$' that is not in an anchor position -- and to
# spell a non-ASCII codepoint as \x{HEX} so the file needs no `use utf8`.
# Perl keeps those backslashes in the compiled pattern: only the delimiter's
# own '\/' is stripped again by the tokenizer. So they survive into the
# registry and out through IO::K8s::CRD, and upstream's
# '^.*@.*\.iam\.gserviceaccount\.com$' goes back to a cluster as
# '^.*\@.*...', Traefik's '^([0-9]+(ns|us|µs|ms|s|m|h)?)+$' as
# '...\x{b5}s...'. Neither breaks the Go/RE2 engine the apiserver actually
# validates with -- '\@' is not even a valid ECMA262 identity escape and
# '\x{...}' is no ECMA262 at all -- but both are IO::K8s' own Perl artifacts
# sitting in a text that is supposed to be upstream's, which is the thing
# k110 set out to stop rather than a different problem.
#
# So the qr// form ships only where it is byte-exact: the candidate source is
# compiled and its text read back, and a pattern that does not come out
# identical takes the same plain-string path a flagged one does. That also
# catches the loss in the other direction -- a '\/' upstream wrote itself
# ('^\/api\/v1$') passes through _escape_pattern_body untouched, but the
# tokenizer then strips that backslash, so the qr// form would hand back
# '^/api/v1$', again not the bytes upstream wrote.
#
# Perl-side validation is unaffected either way: Resource.pm compiles a
# string pattern with qr/$p/, where '\@' and '@', '\$' and a '$' inside a
# character class, and '\x{b5}' and a literal MICRO SIGN are each the same
# regex as the other.
sub _pattern_literal {
    my ($value) = @_;
    return _literal($value) unless ref $value eq 'Regexp';

    my ($pattern, $flags) = re::regexp_pattern($value);
    $flags = '' unless defined $flags;
    # 'u' for the same reason _literal drops it (an artifact of the
    # UTF8-flagged string the pattern was compiled from, not something the
    # schema asked for); 'p' never changes what a pattern matches.
    $flags =~ s/[up]//g;
    return _scalar_literal(_fold_pattern_flags($pattern, $flags)) if length $flags;

    return _literal($value) if _qr_round_trips($pattern);
    return _scalar_literal($pattern);
}

# Whether `qr/BODY/` -- BODY as _escape_pattern_body renders it, which is
# literally the source _literal is about to emit -- compiles back to exactly
# $pattern, carrying no flag it was not given.
#
# Verified by compiling that source, the same discipline _fold_pattern_flags
# uses, and here the only faithful one: `qr/$body/` with $body INTERPOLATED
# is a different thing from the literal the rendered file carries, because
# delimiter unescaping ('\/' -> '/') happens in the tokenizer and never
# touches an interpolated string. A candidate that will not compile at all
# (a pattern ending in a lone backslash, say) fails the check too, which is
# the right answer: that source would not have compiled in the rendered file
# either, and the string form carries it without a delimiter to escape.
sub _qr_round_trips {
    my ($pattern) = @_;
    my $re = eval 'qr/' . _escape_pattern_body($pattern) . '/';
    return 0 unless ref $re eq 'Regexp';
    my ($text, $flags) = re::regexp_pattern($re);
    $flags = '' unless defined $flags;
    $flags =~ s/[up]//g;
    return $text eq $pattern && $flags eq '';
}

# The fold is verified rather than assumed: the candidate text is compiled
# and its own (text, flags) read back, so the result only ships when Perl
# agrees it carries the same modifiers. Two candidates, in order:
#
#   * the text unchanged -- Perl hoists a leading (?i) INTO the flags while
#     leaving it in the text, so a pattern upstream already wrote that way
#     needs no prefix and must not get a duplicate one;
#   * the text with '(?flags)' prefixed.
#
# Neither verifying is a croak, not a silent flag drop.
sub _fold_pattern_flags {
    my ($pattern, $flags) = @_;
    my $want = join '', sort split //, $flags;
    for my $candidate ($pattern, '(?' . $flags . ')' . $pattern) {
        my $re = eval { qr/$candidate/ } or next;
        my ($text, $got) = re::regexp_pattern($re);
        $got = '' unless defined $got;
        $got =~ s/[up]//g;
        return $candidate
            if $text eq $candidate && join('', sort split //, $got) eq $want;
    }
    croak "IO::K8s::CRD::Emitter: the /$flags flags on qr/$pattern/ cannot be"
        . ' folded into the pattern text, and a CRD pattern has nowhere to'
        . ' carry a flag';
}

my @OPTION_ORDER = qw( required enum minimum maximum pattern default nullable preserve_unknown );

# `required` is rendered as `required => 'schema'`: recorded for the CRD
# schema, never enforced at construction -- the same policy AutoGen applies,
# because a cluster returns `status: {}` for a fresh object whatever the
# status schema requires. A hand-written class that wants enforcement
# writes `'required'` itself.
sub _options_source {
    my ($info) = @_;
    my %opts = %{ $info->{options} // {} };
    delete $opts{description};             # goes to POD
    delete $opts{pattern} if _is_quantity_entry($info);
    $opts{required} = 'schema' if $info->{required};
    return '' unless %opts;
    my @parts = map { "$_ => " . ($_ eq 'pattern' ? _pattern_literal($opts{$_}) : _literal($opts{$_})) }
                grep { exists $opts{$_} } @OPTION_ORDER;
    return ', { ' . join(', ', @parts) . ' }';
}

# The class-level ABSTRACT text from a schema's `description`: every run of
# whitespace (a multi-line description included -- a literal newline in a
# `# ABSTRACT:` comment would not compile) collapsed to one space, then the
# first sentence of that (up to the first '. ' or the end), the same way a
# hand-written class's # ABSTRACT line is one line, not the whole paragraph.
# Returns undef -- never an empty string -- for a missing or whitespace-only
# description, so the caller's fallback triggers on truthiness.
sub _first_sentence {
    my ($text) = @_;
    return undef unless defined $text;
    (my $flat = $text) =~ s/\s+/ /g;
    $flat =~ s/\A\s+|\s+\z//g;
    return undef unless length $flat;
    my ($first) = $flat =~ /\A(.*?\.)(?:\s|\z)/;
    return $first // $flat;
}

# A schema's free-form description lands in POD (the =attr block). Guard
# against it breaking the surrounding document: a line starting with '='
# would open a bogus POD command instead of just being text -- E<61> is the
# POD escape for a literal '=' (ASCII 61) -- and a run of blank lines would
# split the paragraph into several, an artifact of however the upstream
# text happened to be wrapped rather than anything meaningful.
sub _pod_safe {
    my ($text) = @_;
    return $text unless defined $text;
    $text =~ s/^[ \t]+$//gm;
    $text =~ s/\n{3,}/\n\n/g;
    $text =~ s/^=/E<61>/gm;
    return $text;
}

sub _render_class {
    my ($self, $class) = @_;
    my $info  = $class->_k8s_attr_info;
    my $attrs = $class->_k8s_attributes;
    my $is_top = $class->can('_is_resource') ? 1 : 0;
    my $package = $self->package_for($class);

    # `metadata` is registered in the generated class's own registry (D10's
    # AutoGen adds it via the k8s DSL so _inflate_struct knows its type),
    # but no hand-written top-level class ever declares it explicitly --
    # `use IO::K8s::APIObject ...;` already does, the same way this
    # rendered source will. Emitting it again would be a harmless but
    # un-idiomatic duplicate line no template class carries.
    my %skip = $is_top ? (metadata => 1) : ();

    # The printed field name -- quoted when it is not a bareword-safe Perl
    # identifier -- is what actually lines up in the source, so the column
    # width is measured on it, not on the (possibly shorter, unquoted) raw
    # JSON key.
    my %name = map {
        my $key = $info->{$_}{json_key} // $_;
        ($_ => ($key =~ /^[A-Za-z_]\w*$/ ? $key : "'$key'"));
    } grep { !$skip{$_} } @$attrs;

    my @nested;
    my (@lines, @pod);
    my $width = 0;
    for my $attr (@$attrs) {
        next if $skip{$attr};
        $width = length $name{$attr} if length $name{$attr} > $width;
    }
    for my $attr (@$attrs) {
        next if $skip{$attr};
        my $i   = $info->{$attr};
        my $key = $i->{json_key} // $attr;
        my ($type, $nested) = $self->_type_source($i, $class, $key);
        push @nested, $nested if $nested;
        push @lines, sprintf("k8s %-*s => %s%s;", $width, $name{$attr}, $type, _options_source($i));
        my $desc = _pod_safe($i->{options}{description}) // 'No description in the upstream schema.';
        push @pod, "=attr $key\n\n$desc\n\n=cut\n";
    }

    my $abstract = _first_sentence(IO::K8s::AutoGen::class_description($class))
        || ($is_top ? $class->kind : (split /::/, $package)[-1]);
    my $header = join "\n",
        "package $package;",
        "# ABSTRACT: $abstract",
        "our \$VERSION = '" . $self->version . "';";
    my $use;
    if ($is_top) {
        my $plural = $class->resource_plural;
        my @use_lines = (defined $plural && length $plural)
            ? (
                'use IO::K8s::APIObject',
                "    api_version     => '" . $class->api_version . "',",
                "    resource_plural => '$plural';",
              )
            : ("use IO::K8s::APIObject api_version => '" . $class->api_version . "';");

        # overlay: with/extra, for the root Kind only. 'with' defaults to
        # Namespaced when the class composes it and to no roles otherwise
        # -- an overlay entry (including an explicit empty list) always
        # wins over that default.
        my $with = $self->overlay->{with};
        $with = [ $class->does('IO::K8s::Role::Namespaced') ? 'IO::K8s::Role::Namespaced' : () ]
            unless defined $with;
        push @use_lines, "with " . join(', ', map { "'$_'" } @$with) . ';' if @$with;
        push @use_lines, @{ $self->overlay->{extra} // [] };

        $use = join "\n", @use_lines;
    }
    else {
        $use = 'use IO::K8s::Resource;';
    }

    # Every value that could carry non-ASCII text -- a pattern, an enum
    # member, a default -- is already rendered ASCII-only above (\x{HEX}
    # escapes; see _escape_pattern_body / _quote_utf8_string). The one place
    # non-ASCII text still reaches this file unescaped is a schema's
    # free-form 'description', left verbatim in POD (the # ABSTRACT comment
    # above, or an =attr block) by design -- descriptions are documentation,
    # not data a client-side check runs against, so there is nothing to
    # protect by mangling them. 'use utf8' and '=encoding UTF-8' are added
    # together, only when that happens: the former is Perl's own rule for a
    # literal non-ASCII byte anywhere in a file it compiles (POD included),
    # the latter is what a POD viewer needs to decode that text correctly.
    # An all-ASCII file -- the overwhelming majority -- carries neither.
    if (grep { /[^\x00-\x7F]/ } ($header, $use, @lines, @pod)) {
        $header .= "\nuse utf8;";
        unshift @pod, "=encoding UTF-8\n\n=cut\n";
    }

    my $source = join "\n", $header, $use, '', @lines, '', @pod, '1;', '';
    return ($source, @nested);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CRD::Emitter - Render generated IO::K8s classes as house-style Perl source

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    my $classes = IO::K8s::CRD->generate($crd, 'IO::K8s::_SUGGEST');
    my $emitter = IO::K8s::CRD::Emitter->new(
        base  => 'IO::K8s::Traefik::V1alpha1',
        names => { "$root\::Spec::RateLimit" => 'RateLimit' },   # D6: upstream Go type names
    );
    my $files = $emitter->render($classes->{'traefik.io/v1alpha1'});
    # { 'IO/K8s/Traefik/V1alpha1/Middleware.pm' => "package ...", ... }

=head1 DESCRIPTION

The source half of D10: what L<IO::K8s::CRD> generates at runtime, rendered
as checked-in, hand-maintained class files this distribution ships -- one
output file per target path, the C<k8s> DSL line per field with its options,
the schema description as the field's C<=attr> POD. Several generated classes
may name the same target only when their functional declarations are identical;
contextual C<# ABSTRACT> and POD may differ, and one source is retained. A
functional difference croaks before either class can overwrite the other. It
reads nothing but the attribute registry of the generated classes, so it
renders any AutoGen class set, and it never writes a file: callers get
C<< { path => source } >> and decide (C<maint/crd-drift-check.pl --suggest>
prints, C<--suggest-dir> writes outside C<lib/>).

Descriptions go into POD, not into the C<description> field option: the
house format documents every field once, in the C<=attr> block.

For an C<is_int_or_string> registry entry whose pattern is exactly Kubernetes'
apimachinery Quantity pattern, rendering uses C<Quantity> and removes only that
redundant pattern from the emitted options; all other options and the dynamic
AutoGen registry remain unchanged. Exact matching accepts either the pattern
text or a regexp with only non-semantic C<u> and C<p> flags, so a near match or
semantic flag stays C<IntOrStr>. Consequently, numeric-looking C<'42'> is a JSON
string in emitted Quantity code, while the dynamic C<IntOrStr> class still
serializes it as a JSON number.

=head2 base

The package prefix of the rendered classes, e.g. C<IO::K8s::Traefik::V1alpha1>.
Required.

=head2 names

Hashref from a generated class name to the bare package name it should get
under L</base>: C<< { 'IO::K8s::_AUTOGEN_x::...::Middleware::Spec::RateLimit' => 'RateLimit' } >>.
Classes not listed get their path joined: C<Middleware::Spec::RateLimit>
becomes C<MiddlewareSpecRateLimit>. This is where the upstream Go type
names (D6) come in. Checked before L</overlay>'s own C<names> map.

=head2 overlay

The per-Kind slice of a provider's C<maint/crd-render/E<lt>ProviderE<gt>.yaml>
(the render-side counterpart of L</names>): a hashref with C<with> (arrayref
of role class names composed on one C<with> line), C<extra> (arrayref of
verbatim source lines rendered right after the C<with> line) and C<names>
(a map from the LOGICAL class path below the Kind -- what
L<IO::K8s::AutoGen/class_path> returns, e.g. C<Spec>, C<Spec::RateLimit> --
to the bare Go type name), applied while rendering the root Kind passed to
L</render>. C<with> defaults to C<['IO::K8s::Role::Namespaced']> when the
root class composes that role and C<[]> otherwise, when not given. This
attribute holds one Kind's overlay, not the whole provider file -- slicing
C<< $provider_overlay->{kinds}{$kind} >> out of the YAML is the caller's job.

An C<names> value carrying C<::> (k120) is an B<absolute> target -- a
fully-qualified package this render references but does not itself write a
file for: a cross-version type another version directory of the same
provider already ships (C<IO::K8s::ExternalSecrets::V1::AWSAuth> named under a
v1alpha1 Kind), or a core class the D5 reuse heuristic would not fold on its
own (a single-key C<{name}> that stays C<IO::K8s::Api::Core::V1::LocalObjectReference>).
See L</package_for>. The sibling C<no_reuse_core>
key of a provider overlay file is B<not> read here: it is a generation-time
concern the render driver passes to L<IO::K8s::AutoGen> as C<reuse_core_except>,
so that a provider's own named type is generated for such a path before this
overlay renames it.

=head2 version

The C<$VERSION> line to write. Defaults to this distribution's.

=head2 package_for

    my $package = $emitter->package_for($generated_class);

The package a generated class is rendered as: L</names> when listed there
by the generated class's own (possibly hash-shortened) Perl name, else
L</overlay>'s C<names> when listed there by logical path, otherwise
L</base> plus the class's path segments below its Kind joined together
(the Kind itself for the root).

An overlay C<names> value that carries C<::> (k120) is used verbatim as an
absolute package (a leading C<+> is stripped) rather than joined below
L</base> -- the cross-version / core external targets described under
L</overlay>. Such a class satisfies C<_is_external_ref>: L</render> neither
recurses into it nor writes a file for it, and its reference is emitted the
way a hand-written class writes that target package.

A class deep enough that L<IO::K8s::AutoGen> had to shorten its own
namespace-qualified Perl name (past its 251-character identifier limit --
see C<$MAX_CLASS_NAME> there) is rendered from C<< IO::K8s::AutoGen::class_path
>>, the field path AutoGen records regardless of shortening, not from the
class's own (possibly hashed) name -- this emitter's own C<base> is
normally much shorter than the AutoGen namespace prefix that forced the
shortening, so the joined package name here often fits fine even when
AutoGen's did not. That same logical path is what L</overlay>'s C<names>
map is keyed by. Only when the joined name would itself run past
C<$MAX_PACKAGE_SUFFIX> characters, or C<base> is itself long enough that
the full package name would, does the emitted package fall back to
C<< <Kind>_<10 hex chars> >>, the hex digits a C<sha1_hex> of the field
path; give such a class a proper name via L</names> or L</overlay> instead
of relying on that fallback.

=head2 render

    my $files = $emitter->render($root_class);

Renders C<$root_class> and every generated class reachable from its fields
(objects, arrays of objects, maps of objects) into
C<< { 'Relative/Path.pm' => $source } >>. The result has one entry per target
path, not necessarily per logical class: two classes mapped to the same path
share it only when their executable declarations are identical after ignoring
contextual C<# ABSTRACT> and POD; otherwise C<render> croaks naming the path
and both logical classes. Stock classes referenced by a field (C<ObjectMeta>,
core types) are written by their short name and not rendered.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
