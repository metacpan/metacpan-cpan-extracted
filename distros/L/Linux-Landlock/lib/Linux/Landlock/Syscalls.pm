package Linux::Landlock::Syscalls;

use strict;
use warnings;
use Config;
use Exporter 'import';
our @EXPORT_OK = qw(NR Q_pack);

my %SYSCALLS;

my $supports_Q = eval { no warnings 'void'; pack('Q', 1); 1 };
# endianness test from https://perldoc.perl.org/perlpacktut#Pack-Recipes
my $is_le = unpack('c', pack('s', 1));
# emulate pack('Q', ...) on Perl without 64-bit integer support

#@type $arg Math::BigInt
sub Q_pack {
    my ($arg) = @_;

    if ($supports_Q) {
        return pack('Q', $arg->numify);
    } else {
        my $high = $arg >> 32;
        my $low  = $arg & 0xFFFFFFFF;
        if ($is_le) {
            return pack('VV', $low, $high);
        } else {
            return pack('NN', $high, $low);
        }
    }
}

sub NR {
    my ($name) = @_;

    if (!%SYSCALLS && $^O eq 'linux') {
        my $re_arm     = qr/arm/x;
        my $re_aarch64 = qr/aarch64/x;
        my $re_x86     = qr/i686/x;
        my $re_x86_64  = qr/x86_64/x;
        if (my ($arch) = $Config{archname} =~ /($re_x86_64|$re_x86|$re_arm|$re_aarch64)/x) {
            my %prctl = (
                aarch64 => 167,
                arm     => 172,
                i686    => 172,
                x86_64  => 157,
            );
            %SYSCALLS = (
                landlock_create_ruleset => 444,
                landlock_add_rule       => 445,
                landlock_restrict_self  => 446,
                prctl                   => $prctl{$arch},
            );
        } elsif ($^O eq 'linux' && (eval { require 'syscall.ph'; } || eval { require 'sys/syscall.ph'; })) {
            %SYSCALLS = (
                landlock_create_ruleset => &SYS_landlock_create_ruleset,
                landlock_add_rule       => &SYS_landlock_add_rule,
                landlock_restrict_self  => &SYS_landlock_restrict_self,
                prctl                   => &SYS_prctl,
            );
        } else {
            warn "Could not determine syscall numbers, disabling Landlock support,\n";
            return;
        }
    }
    return $SYSCALLS{$name};
}

1;
