package ValidateFields;

use strict;
use warnings;

# TDLib silently ignores a field it does not know on a request it does know.
# So a typo in a field name, or a field TDLib renamed under us, is dropped
# with no error from any layer -- the request simply does something other
# than what was asked. Nothing else in the suite checks the names we emit:
# schema_pin checks the @type strings, schema_slots checks the classes
# nested inside, and neither looks at the keys of the request itself.
#
# Hooked on send(), not _send(): most test files replace _send with a stub of
# their own, which would take this hook with it. send() is where every
# convenience method funnels, and it still has the hashref before encoding.

my ($checked, $funcs) = (0, {});
my $nested_seen = {};
my @bad;

sub import {
    require EV::Telegram::TDLib;
    my $orig = EV::Telegram::TDLib->can('send') or die "no send to hook";
    no warnings 'redefine';
    no strict 'refs';
    *{'EV::Telegram::TDLib::send'} = sub {
        my ($self, $request, @rest) = @_;
        _check($request) if ref $request eq 'HASH';
        return $orig->($self, $request, @rest);
    };
}

sub _check {
    my ($req) = @_;
    my $type = $req->{'@type'} or return;
    my $known = $EV::Telegram::TDLib::Schema::FUNCTIONS{$type};
    return unless defined $known;      # not a function: nothing to check here
    $checked++;
    $funcs->{$type} = 1;
    my %ok = map { $_ => 1 } split ' ', $known;
    for my $k (sort keys %$req) {
        next if $k =~ /\A\@/;          # @type and @extra are ours, not TDLib's
        push @bad, "$type: $k" unless $ok{$k};
        _nested($req->{$k});
    }
}

# The same silent-drop applies inside every nested TL object, and the checks
# above stop at the top level: schema_slots asks whether a nested @type is the
# right class for its slot, never whether the field name it sits under is real.
#
# Only the object-typed fields are policed here, and "object" means a value
# that actually carries an @type. %CLASS_SLOTS records object_ptr slots and
# only those, so it is a complete oracle for those and no oracle at all for
# anything else: checked against a scalar it reports every legitimate string
# and integer in the schema, and json_bool returns a ref, so "the value is a
# reference" reports every boolean too.
sub _carries_type {
    my ($x) = @_;
    return 1 if ref $x eq 'HASH' && defined $x->{'@type'};
    return 1 if ref $x eq 'ARRAY' && @$x
             && ref $x->[0] eq 'HASH' && defined $x->[0]{'@type'};
    return 0;
}

sub _nested {
    my ($v) = @_;
    if (ref $v eq 'ARRAY') { _nested($_) for @$v; return }
    return unless ref $v eq 'HASH';
    my $class = $v->{'@type'};
    # a hash with no @type is ours (an option bag), not something TDLib parses
    return unless defined $class;
    my $slots = $EV::Telegram::TDLib::Schema::CLASS_SLOTS{$class} || {};
    for my $k (sort keys %$v) {
        next if $k =~ /\A\@/;
        push @bad, "$class: $k"
            if _carries_type($v->{$k}) && !exists $slots->{$k};
        _nested($v->{$k});
    }
    $nested_seen->{$class} = 1;
}

END {
    my %seen;
    my @u = grep { !$seen{$_}++ } @bad;
    print STDERR "FIELD-NAMES-BAD: $_\n" for @u;
    printf STDERR "FIELD-NAMES-DONE %d %d %d\n",
        $checked, scalar keys %$funcs, scalar keys %$nested_seen;
}

1;
