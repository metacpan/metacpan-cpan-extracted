package PoisonHarvest;

use strict;
use warnings;
use Scalar::Util qw(blessed reftype);
use Data::Dumper ();
use B ();

# Loaded with -MPoisonHarvest into one t/ file by xt/argument_poison.t. Every
# outermost call a test makes into a public sub of the module is recorded
# with its arguments and whether it croaked, and so is each reply the test
# injects for a request; the sweep replays the calls and keeps the ones that
# reach the wire.
#
# Written line by line as they happen rather than at END: a test that forks or
# leaves through POSIX::_exit would otherwise lose everything.

my $OUT = $ENV{POISON_HARVEST_OUT} or die "POISON_HARVEST_OUT is not set\n";
my $PID = $$;
our $DEPTH = 0;
my %SEEN;

sub clone {
    my ($v, $d) = @_;
    return '__DEEP__' if $d > 12;
    return $v unless ref $v;
    if (blessed $v) {
        return '__TD__' if $v->isa('EV::Telegram::TDLib');
        return $v;
    }
    my $t = reftype $v;
    return [ map { clone($_, $d + 1) } @$v ] if $t eq 'ARRAY';
    return { map { $_ => clone($v->{$_}, $d + 1) } keys %$v } if $t eq 'HASH';
    return $v;
}

sub kind_of {
    my ($inv) = @_;
    return blessed $inv && $inv->isa('EV::Telegram::TDLib') ? 'obj'
         : defined $inv && !ref $inv && $inv eq 'EV::Telegram::TDLib' ? 'class'
         : 'func';
}

sub record {
    my ($pkg, $name, $kind, $args, $ok) = @_;
    return if $$ != $PID;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Deepcopy = 1;
    my $dump = eval { Data::Dumper::Dumper($args) };
    return unless defined $dump && $dump !~ /\n/;
    my $line = join "\t", $pkg, $name, $kind, ($ok ? 0 : 1), $dump;
    return if $SEEN{$line}++;
    open my $fh, '>>', $OUT or return;
    print {$fh} "$line\n";
    close $fh;
}

# compiled into the method's own package: Carp skips frames of a package that
# trusts the caller, so a croak still names the test's line and the t/ file
# asserting that keeps running to its later calls
sub wrapper_in {
    my ($pkg) = @_;
    my $code = <<"CODE";
package $pkg;
sub {
    my (\$name, \$orig) = \@_;
    return sub {
        return \$orig->(\@_) if \$PoisonHarvest::DEPTH;
        local \$PoisonHarvest::DEPTH = 1;
        my \$kind = PoisonHarvest::kind_of(\$_[0]);
        my \$args = PoisonHarvest::clone([ \$kind eq 'func' ? \@_ : \@_[1 .. \$#_] ], 0);
        my \$want = wantarray;
        my \@r;
        my \$ok = eval {
            if (\$want) { \@r = \$orig->(\@_) }
            elsif (defined \$want) { \$r[0] = \$orig->(\@_) }
            else { \$orig->(\@_) }
            1;
        };
        my \$err = \$@;
        PoisonHarvest::record('$pkg', \$name, \$kind, \$args, \$ok);
        die \$err unless \$ok;
        return \$want ? \@r : \$r[0];
    };
}
CODE
    return eval $code || die $@;
}

# The replies a test injects for the requests it made, by function name: with
# no td_api.h to build a reply from, these are what lets the sweep reach a
# request that is only sent once a reply lands.
my (%REQUEST_TYPE, %REPLIES);

sub note_request {
    my ($client, $request, $extra) = @_;
    $REQUEST_TYPE{"$client->{client_id}:$extra"} = $request->{'@type'}
        if defined $extra && ref $request eq 'HASH' && defined $client->{client_id};
}

sub record_reply {
    my ($client_id, $json) = @_;
    return if $$ != $PID || !defined $json;
    my ($extra) = $json =~ /"\@extra"\s*:\s*"?(\d+)/ or return;
    my $type = $REQUEST_TYPE{"$client_id:$extra"} or return;
    return if $json =~ /"\@type"\s*:\s*"error"/ || $json =~ /[\r\n\t]/;
    return if ++$REPLIES{$type} > 3;
    open my $fh, '>>', $OUT or return;
    print {$fh} join("\t", 'REPLY', $type, $json), "\n";
    close $fh;
}

sub import {
    require EV::Telegram::TDLib;
    my %handler;
    no strict 'refs';
    no warnings qw(redefine once);
    my ($send_once, $dispatch) = eval <<'CODE' or die $@;
package EV::Telegram::TDLib;
my $send_once = \&EV::Telegram::TDLib::send_once;
my $dispatch  = \&EV::Telegram::TDLib::dispatch_raw;
(sub {
    my $extra = $send_once->(@_);
    PoisonHarvest::note_request($_[0], $_[1], $extra);
    return $extra;
 },
 sub {
    PoisonHarvest::record_reply(@_[0, 1]);
    goto &$dispatch;
 });
CODE
    *EV::Telegram::TDLib::send_once    = $send_once;
    *EV::Telegram::TDLib::dispatch_raw = $dispatch;
    my @pkgs = ('EV::Telegram::TDLib', @EV::Telegram::TDLib::ISA);
    for my $pkg (@pkgs) {
        $handler{$_} = 1 for values %{"${pkg}::UPDATES"};
    }
    for my $pkg (@pkgs) {
        my $wrap = wrapper_in($pkg);
        for my $name (sort keys %{"${pkg}::"}) {
            next if $name !~ /\A[a-z]/;
            my $orig = *{"${pkg}::$name"}{CODE} or next;
            next if $orig == $send_once || $orig == $dispatch;
            next if $handler{$orig};
            next if B::svref_2object($orig)->GV->STASH->NAME ne $pkg;
            *{"${pkg}::$name"} = $wrap->($name, $orig);
        }
    }
}

1;
