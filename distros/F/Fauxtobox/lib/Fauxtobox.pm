package Fauxtobox;

use strict;
use warnings;

use Scalar::Util qw(blessed);
use Data::Munge qw(eval_string);

use Exporter;
our @ISA = qw(Exporter);

our $VERSION = '0.02';

sub import {
    my $class = shift;
    @_ = map /^[a-z0-9]+\z/ ? '$_' . $_ : $_, @_;
    unshift @_, $class;
    goto &{ $class->can('SUPER::import') };
}

sub _filetest {
    my ($name) = @_;
    "test_$name" => eval_string("sub { -$name \$_[0] }")
}

sub _xlist {
    my ($n, $name) = @_;
    my $xs = join '', map "\$x$_, ", 1 .. $n;
    $name => eval_string "sub { my (\$arg, $xs) = \@_; $name(${xs}ref(\$arg) eq 'ARRAY' ? \@\$arg : \$_[0]) }"
}

sub _fixed_opt {
    my ($n, $m, $name) = @_;
    $name => do {
        no warnings 'once';
        no strict 'refs';
        *{"CORE::$name"}{CODE}
    } || eval_string do {
        my $args = join ', ', map "\$_[$_]", 0 .. $n - 1;
        my $base = "$name $args";
        my $code = $base;
        for my $c (0 .. $m - 1) {
            my $i = $n + $c;
            $base .= ", \$_[$i]";
            $code = "\@_ > $i ? $base : $code";
        }
        "sub { $code }"
    }
}

sub _fixed {
    my ($n, $name) = @_;
    _fixed_opt $n, 0, $name
}

sub _scalar {
    my ($name) = @_;
    _fixed 1, $name
}

sub _hxa {
    my ($name) = @_;
    my $body =
        $^V ge v5.12.0 ?
            "ref(\$_[0]) eq 'ARRAY' ? $name \@{\$_[0]} : $name %{\$_[0]}" :
            "$name %{\$_[0]}"
    ;
    $body = "[$body]" unless $name eq 'each';
    $name => eval_string("sub { $body }")
}

my %functions = (
    apply => sub { my $x = shift; my $f = shift; $f->($x, @_) },
    list  => sub { ref($_[0]) eq 'HASH' ? %{$_[0]} : @{$_[0]} },
    qr    => sub { @_ > 1 ? qr/(?$_[1])$_[0]/ : qr/$_[0]/ },

    m    => sub { $_[0] =~ /$_[1]/   },
    m_g  => sub { $_[0] =~ /$_[1]/g  },
    m_gc => sub { $_[0] =~ /$_[1]/gc },

    s    => sub { ref($_[2]) ? $_[0] =~ s/$_[1]/$_[2]()/e  : $_[0] =~ s/$_[1]/$_[2]/  },
    s_g  => sub { ref($_[2]) ? $_[0] =~ s/$_[1]/$_[2]()/ge : $_[0] =~ s/$_[1]/$_[2]/g },
    $^V ge v5.14.0 ? (
        s_r  => eval_string('sub { ref($_[2]) ? $_[0] =~ s/$_[1]/$_[2]()/re  : $_[0] =~ s/$_[1]/$_[2]/r  }'),
        s_gr => eval_string('sub { ref($_[2]) ? $_[0] =~ s/$_[1]/$_[2]()/gre : $_[0] =~ s/$_[1]/$_[2]/gr }'),
    ) : (
        s_r  => sub { my $s = $_[0]; if (ref $_[2]) { $s =~ s/$_[1]/$_[2]()/e  } else { $s =~ s/$_[1]/$_[2]/  } $s },
        s_gr => sub { my $s = $_[0]; if (ref $_[2]) { $s =~ s/$_[1]/$_[2]()/ge } else { $s =~ s/$_[1]/$_[2]/g } $s },
    ),

    (map _filetest($_), qw(
        r w x o
        R W X O
        e z s
        f d l p S b c t
        u g k
        T B
        M A C
    )),

    _scalar('abs'),
    _scalar('alarm'),
    _fixed(2, 'atan2'),
    bless => defined &CORE::bless ? \&CORE::bless : sub { bless $_[0], @_ > 1 ? $_[1] : scalar caller },
    _scalar('chdir'),
    _xlist(1, 'chmod'),
    _xlist(0, 'chomp'),
    _xlist(0, 'chop'),
    _xlist(2, 'chown'),
    _scalar('chr'),
    _scalar('chroot'),
    _scalar('cos'),
    _fixed(2, 'crypt'),
    defined => sub { defined $_[0] },
    delete => sub {
        ref($_[0]) eq 'ARRAY' ?
            delete $_[0][$_[1]] :
            delete $_[0]{$_[1]}
    },
    _scalar('die'),
    _hxa('each'),
    eval => sub { eval $_[0] },
    exec => sub {
        my $prog = shift;
        @_ ? exec { $prog } @_ :
        ref($prog) eq 'ARRAY' ? exec @$prog :
        exec $prog
    },
    exists => sub {
        ref($_[0]) eq 'ARRAY' ?
            exists $_[0][$_[1]] :
            exists $_[0]{$_[1]}
    },
    _scalar('exit'),
    _scalar('exp'),
    $^V ge v5.16.0 ? (fc => \&CORE::fc) : (),
    _scalar('getpgrp'),
    _scalar('getpwnam'),
    _scalar('getgrnam'),
    _scalar('gethostbyname'),
    _scalar('getnetbyname'),
    _scalar('getprotobyname'),
    _scalar('getpwuid'),
    _scalar('getgrgid'),
    _fixed(2, 'getservbyname'),
    _fixed(2, 'gethostbyaddr'),
    _fixed(2, 'getnetbyaddr'),
    _scalar('getprotobynumber'),
    _fixed(2, 'getservbyport'),
    glob => sub { [ glob $_[0] ] },
    _scalar('gmtime'),
    grep => sub { my ($arg, $f) = @_; [ grep $f->($_), @$arg ] },
    _scalar('hex'),
    _fixed_opt(2, 1, 'index'),
    _scalar('int'),
    join => sub { join $_[1], @{$_[0]} },
    _hxa('keys'),
    _xlist(1, 'kill'),
    _scalar('lc'),
    _scalar('lcfirst'),
    _scalar('length'),
    _fixed(2, 'link'),
    _scalar('localtime'),
    _scalar('log'),
    _scalar('lstat'),
    map => sub { my ($arg, $f) = @_; [ map $f->($_), @$arg ] },
    _scalar('mkdir'),
    _scalar('oct'),
    _scalar('ord'),
    _xlist(1, 'pack'),
    pop => sub { pop @{$_[0]} },
    pos => sub :lvalue { @_ > 1 ? pos($_[0]) = $_[1] : pos($_[0]) },
    _scalar('prototype'),
    push => sub { my $arg = shift; push @$arg, @_ },
    _scalar('quotemeta'),
    _scalar('rand'),
    _scalar('readlink'),
    _scalar('ref'),
    _fixed(2, 'rename'),
    _scalar('require'),
    reverse => sub { ref($_[0]) eq 'ARRAY' ? [ reverse @{$_[0]} ] : scalar reverse $_[0] },
    _fixed_opt(2, 1, 'rindex'),
    _scalar('rmdir'),
    shift => sub { shift @{$_[0]} },
    _scalar('sin'),
    _scalar('sleep'),
    sort => sub { [ @_ > 1 ? sort { $_[1]($a, $b) } @{$_[0]} : sort @{$_[0]} ] },
    splice => sub {
        my $arg = shift;
        return splice @$arg unless @_;
        my $offset = shift;
        return splice @$arg, $offset unless @_;
        my $length = shift;
        splice @$arg, $offset, $length, @_
    },
    split => sub { [ @_ > 2 ? split $_[1], $_[0], $_[2] : @_ > 1 ? split $_[1], $_[0] : split ' ', $_[0] ] },
    _xlist(1, 'sprintf'),
    _scalar('sqrt'),
    _scalar('srand'),
    _scalar('stat'),
    _fixed_opt(2, 2, 'substr'),
    _fixed(2, 'symlink'),
    syscall => sub { my $arg = shift; syscall $arg, @_ },
    system => sub {
        my $prog = shift;
        @_ ? system { $prog } @_ :
        ref($prog) eq 'ARRAY' ? system @$prog :
        system $prog
    },
    _fixed(2, 'truncate'),
    _scalar('uc'),
    _scalar('ucfirst'),
    _scalar('umask'),
    _scalar('unlink'),
    unpack => sub { unpack $_[1], $_[0] },
    unshift => sub { my $arg = shift; unshift @$arg, @_ },
    _xlist(2, 'utime'),
    _hxa('values'),
    vec => sub :lvalue { @_ > 3 ? vec($_[0], $_[1], $_[2]) = $_[3] : vec($_[0], $_[1], $_[2]) },
    _fixed(2, 'waitpid'),
    waitpid => sub { waitpid $_[0], @_ > 1 ? $_[1] : 0 },
    _scalar('warn'),
);

our @EXPORT = map '$_' . $_, keys %functions;

for my $k (keys %functions) {
    my $v = $functions{$k};
    my $svref = do { no strict 'refs'; \${"_$k"} };
    $$svref = sub { blessed($_[0]) and return shift->$k(@_); goto &$v };
    Internals::SvREADONLY($$svref, 1) if defined &Internals::SvREADONLY;
}

'ok'

__END__

=encoding UTF-8

=head1 NAME

Fauxtobox - fake autoboxing (call methods on plain scalars)

=head1 SYNOPSIS

 use Fauxtobox;

 my $n = "zomg"->$_length;  # $n = 4
 print $n->$_sqrt;          # "2"

 # ... and many methods more

=head1 DESCRIPTION

This module provides fake autoboxing support. I<Autoboxing> means being able to
call methods on non-objects like C<42> or C<'hello'> because the language will
automatically wrap them in objects. If you want that, see L<autobox>.

What this module does is much simpler: It exports a bunch of variables that can
be used like methods. These method variables can be used on any value, not just
objects.

=head2 Exported symbols

By default everything listed below is exported. If you don't want that, you can
explicitly list the variables you want:

  use Fauxtobox qw($_defined $_length $_apply);

For convenience you can omit the leading C<$_> in the import list:

  use Fauxtobox qw(defined length apply);

=head2 Methods

If you call any of these fake methods on a real object, it will simply forward
to a method of the same name, i.e. C<< $obj->$_foo(...) >> is equivalent to
C<< $obj->foo(...) >> if C<$obj> is blessed.

Several functions in Perl take or return lists. In general, the method
equivalents of these take and return array references instead, to make method
chaining possible. Exceptions are noted below.

=over

=item $_apply

C<< $X->$_apply($F) >> is equivalent to C<< $F->($X) >>, so e.g.
C<< "abc"->$_apply(\&display) >> is equivalent to C<< display("abc") >>.

=item $_list

C<< $X->$_list >> returns C<%{$X}> if C<$X> is a hash reference and C<@{$X}>
otherwise. This is useful if you have an array reference and want to turn it
into a list of its values.

=item $_qr

C<< $X->$_qr >> is equivalent to C<< qr/$X/ >>.
C<< $X->$_qr($FLAGS) >> is equivalent to C<< qr/$X/$FLAGS >> except that's a
syntax error, but e.g. C<< '^hello\s+world'->$_qr('i') >> is equivalent to
C<< qr/^hello\s+world/i >>.

See L<perlfunc/qr>.

=item $_m

C<< $X->$_m($REGEX) >> is equivalent to C<< $X =~ m/$REGEX/ >>.

See L<perlfunc/m>.

=item $_m_g

C<< $X->$_m_g($REGEX) >> is equivalent to C<< $X =~ m/$REGEX/g >>.

See L<perlfunc/m>.

=item $_m_gc

C<< $X->$_m_gc($REGEX) >> is equivalent to C<< $X =~ m/$REGEX/gc >>.

See L<perlfunc/m>.

=item $_s

C<< $X->$_s($REGEX, $REPLACEMENT) >> is equivalent to
C<< $X =~ s/$REGEX/$REPLACEMENT->()/e >> if C<$REPLACEMENT> is a subroutine
reference and C<< $X =~ s/$REGEX/$REPLACEMENT/ >> otherwise.

See L<perlfunc/s>.

=item $_s_g

C<< $X->$_s_g($REGEX, $REPLACEMENT) >> is equivalent to
C<< $X =~ s/$REGEX/$REPLACEMENT->()/ge >> if C<$REPLACEMENT> is a subroutine
reference and C<< $X =~ s/$REGEX/$REPLACEMENT/g >> otherwise.

See L<perlfunc/s>.

=item $_s_r

C<< $X->$_s_r($REGEX, $REPLACEMENT) >> is equivalent to
C<< $X =~ s/$REGEX/$REPLACEMENT->()/re >> if C<$REPLACEMENT> is a subroutine
reference and C<< $X =~ s/$REGEX/$REPLACEMENT/r >> otherwise.

See L<perlfunc/s>.

=item $_s_gr

C<< $X->$_s($REGEX, $REPLACEMENT) >> is equivalent to
C<< $X =~ s/$REGEX/$REPLACEMENT->()/gre >> if C<$REPLACEMENT> is a subroutine
reference and C<< $X =~ s/$REGEX/$REPLACEMENT/gr >> otherwise.

See L<perlfunc/s>.


=item $_test_r

=item $_test_w

=item $_test_x

=item $_test_o

=item $_test_R

=item $_test_W

=item $_test_X

=item $_test_O

=item $_test_e

=item $_test_z

=item $_test_s

=item $_test_f

=item $_test_d

=item $_test_l

=item $_test_p

=item $_test_S

=item $_test_b

=item $_test_c

=item $_test_t

=item $_test_u

=item $_test_g

=item $_test_k

=item $_test_T

=item $_test_B

=item $_test_M

=item $_test_A

=item $_test_C

These are file test operators. C<< $X->$_test_X >> is equivalent to
C<< -X $X >> for all letters I<X> listed above.

See L<perlfunc/-X>.

=item $_abs

C<< $X->$_abs >> is equivalent to C<< abs $X >>.

See L<perlfunc/abs>.

=item $_alarm

C<< $X->$_alarm >> is equivalent to C<< alarm $X >>.

See L<perlfunc/alarm>.

=item $_atan2

C<< $X->atan2($Y) >> is equivalent to C<< atan2 $X, $Y >>.

See L<perlfunc/atan2>.

=item $_bless

C<< $X->$_bless($CLASS) >> is equivalent to C<< bless $X, $CLASS >>.
C<< $X->$_bless >> is equivalent to C<< bless $X >>.

See L<perlfunc/bless>.

=item $_chdir

C<< $X->$_chdir >> is equivalent to C<< chdir $X >>.

See L<perlfunc/chdir>.

=item $_chmod

C<< $X->$_chmod($MODE) >> is equivalent to C<< chmod $MODE, @{$X} >> if
C<$X> is an array reference and C<< chmod $MODE, $X >> otherwise.

See L<perlfunc/chmod>.

=item $_chomp

C<< $X->$_chomp >> is equivalent to C<< chomp @{$X} >> if C<$X> is an array
reference and C<< chomp $X >> otherwise.

See L<perlfunc/chomp>.

=item $_chop

C<< $X->$_chop >> is equivalent to C<< chop @{$X} >> if C<$X> is an array
reference and C<< chop $X >> otherwise.

See L<perlfunc/chop>.

=item $_chown

C<< $X->$_chown($UID, $GID) >> is equivalent to
C<< chown $UID, $GID, @{$X} >> if C<$X> is an array reference and
C<< chown $UID, $GID, $X >> otherwise.

See L<perlfunc/chown>.

=item $_chr

C<< $X->$_chr >> is equivalent to C<< chr $X >>.

See L<perlfunc/chr>.

=item $_chroot

C<< $X->$_chroot >> is equivalent to C<< chroot $X >>.

See L<perlfunc/chroot>.

=item $_cos

C<< $X->$_cos >> is equivalent to C<< cos $X >>.

See L<perlfunc/cos>.

=item $_crypt

C<< $X->$_crypt($SALT) >> is equivalent to C<< crypt $X, $SALT >>.

See L<perlfunc/crypt>.

=item $_defined

C<< $X->$_defined >> is equivalent to C<< defined $X >>.

See L<perlfunc/defined>.

=item $_delete

C<< $X->$_delete($KEY) >> is equivalent to C<< delete $X->[$KEY] >> if $X is
an array reference and C<< delete $X->{$KEY} >> otherwise.

See L<perlfunc/delete>.

=item $_die

C<< $X->$_die >> is equivalent to C<< die $X >>.

See L<perlfunc/die>.

=item $_each

C<< $X->$_each >> is equivalent to C<< each @{$X} >> if C<$X> is an array
reference and C<< each %{$X} >> otherwise.

See L<perlfunc/each>.

=item $_eval

C<< $X->$_eval >> is equivalent to C<< eval $X >>.

See L<perlfunc/eval>.

=item $_exec

C<< $X->$_exec(@ARGS) >> is equivalent to C<< exec { $X } @ARGS >>.
C<< $X->$_exec >> is equivalent to C<< exec @{$X} >> if C<$X> is an array
reference and C<< exec $X >> otherwise.

See L<perlfunc/exec>.

=item $_exists

C<< $X->$_exists($KEY) >> is equivalent to C<< exists $X->[$KEY] >> if C<$X>
is an array reference and C<< exists $X->{$KEY} >> otherwise.

See L<perlfunc/exists>.

=item $_exit

C<< $X->$_exit >> is equivalent to C<< exit $X >>.

See L<perlfunc/exit>.

=item $_exp

C<< $X->$_exp >> is equivalent to C<< exp $X >>.

See L<perlfunc/exp>.

=item $_fc

C<< $X->$_fc >> is equivalent to C<< fc $X >>.

See L<perlfunc/fc>.

=item $_getpgrp

C<< $X->$_getpgrp >> is equivalent to C<< getpgrp $X >>.

See L<perlfunc/getpgrp>.

=item $_getpwnam

C<< $X->$_getpwnam >> is equivalent to C<< getpwnam $X >>.

See L<perlfunc/getpwnam>.

=item $_getgrnam

C<< $X->$_getgrnam >> is equivalent to C<< getgrnam $X >>.

See L<perlfunc/getgrnam>.

=item $_gethostbyname

C<< $X->$_gethostbyname >> is equivalent to C<< gethostbyname $X >>.

See L<perlfunc/gethostbyname>.

=item $_getnetbyname

C<< $X->$_getnetbyname >> is equivalent to C<< getnetbyname $X >>.

See L<perlfunc/getnetbyname>.

=item $_getprotobyname

C<< $X->$_getprotobyname >> is equivalent to C<< getprotobyname $X >>.

See L<perlfunc/getprotobyname>.

=item $_getpwuid

C<< $X->$_getpwuid >> is equivalent to C<< getpwuid $X >>.

See L<perlfunc/getpwuid>.

=item $_getgrgid

C<< $X->$_getgrgid >> is equivalent to C<< getgrgid $X >>.

See L<perlfunc/getgrgid>.

=item $_getservbyname

C<< $X->$_getservbyname($Y) >> is equivalent to C<< getservbyname $X, $Y >>.

See L<perlfunc/getservbyname>.

=item $_gethostbyaddr

C<< $X->$_gethostbyaddr($Y) >> is equivalent to C<< gethostbyaddr $X, $Y >>.

See L<perlfunc/gethostbyaddr>.

=item $_getnetbyaddr

C<< $X->$_getnetbyaddr($Y) >> is equivalent to C<< getnetbyaddr $X, $Y >>.

See L<perlfunc/getnetbyaddr>.

=item $_getprotobynumber

C<< $X->$_getprotobynumber >> is equivalent to C<< getprotobynumber $X >>.

See L<perlfunc/getprotobynumber>.

=item $_getservbyport

C<< $X->$_getservbyport($Y) >> is equivalent to C<< getservbyport $X, $Y >>.

See L<perlfunc/getservbyport>.

=item $_glob

C<< $X->$_glob >> is equivalent to C<< [ glob $X ] >>, i.e. it returns an array
reference of results.

See L<perlfunc/glob>.

=item $_gmtime

C<< $X->$_gmtime >> is equivalent to C<< gmtime $X >>.

See L<perlfunc/gmtime>.

=item $_grep

C<< $X->$_grep($F) >> is equivalent to C<< [ grep $F->($_), @{$X} ] >>, i.e. it
takes and returns an array reference. The function C<$F> is passed the current
element as an argument.

See L<perlfunc/grep>.

=item $_hex

C<< $X->$_hex >> is equivalent to C<< hex $X >>.

See L<perlfunc/hex>.

=item $_index

C<< $X->$_index($NEEDLE) >> is equivalent to C<< index $X, $NEEDLE >>.
C<< $X->$_index($NEEDLE, $OFFSET) >> is equivalent to C<< index $X, $NEEDLE, $OFFSET >>.

See L<perlfunc/index>.

=item $_int

C<< $X->$_int >> is equivalent to C<< int $X >>.

See L<perlfunc/int>.

=item $_join

C<< $X->$_join($SEP) >> is equivalent to C<< join $SEP, @{$X} >>.

See L<perlfunc/join>.

=item $_keys

C<< $X->$_keys >> is equivalent to C<< [ keys @{$X} ] >> if C<$X> is an array
reference and C<< [ keys %{$X} ] >> otherwise.

See L<perlfunc/keys>.

=item $_kill

C<< $X->$_kill($SIGNAL) >> is equivalent to C<< kill $SIGNAL, @{$X} >> if C<$X> is an array reference and C<< kill $SIGNAL, $X >> otherwise.

See L<perlfunc/kill>.

=item $_lc

C<< $X->$_lc >> is equivalent to C<< lc $X >>.

See L<perlfunc/lc>.

=item $_lcfirst

C<< $X->$_lcfirst >> is equivalent to C<< lcfirst $X >>.

See L<perlfunc/lcfirst>.

=item $_length

C<< $X->$_length >> is equivalent to C<< length $X >>.

See L<perlfunc/length>.

=item $_link

C<< $X->$_link($Y) >> is equivalent to C<< link $X, $Y >>.

See L<perlfunc/link>.

=item $_localtime

C<< $X->$_localtime >> is equivalent to C<< localtime $X >>.

See L<perlfunc/localtime>.

=item $_log

C<< $X->$_log >> is equivalent to C<< log $X >>.

See L<perlfunc/log>.

=item $_lstat

C<< $X->$_lstat >> is equivalent to C<< lstat $X >>.

See L<perlfunc/lstat>.

=item $_map

C<< $X->$_map($F) >> is equivalent to C<< [ map $F->($_), @{$X} ] >>, i.e. it
takes and returns an array reference. The function C<$F> is passed the current
element as an argument.

See L<perlfunc/map>.

=item $_mkdir

C<< $X->$_mkdir >> is equivalent to C<< mkdir $X >>.

See L<perlfunc/mkdir>.

=item $_oct

C<< $X->$_oct >> is equivalent to C<< oct $X >>.

See L<perlfunc/oct>.

=item $_ord

C<< $X->$_ord >> is equivalent to C<< ord $X >>.

See L<perlfunc/ord>.

=item $_pack

C<< $X->$_pack($FORMAT) >> is equivalent to C<< pack $FORMAT, @{$X} >> if C<$X>
is an array reference and C<< pack $FORMAT, $X >> otherwise.

See L<perlfunc/pack>.

=item $_pop

C<< $X->$_pop >> is equivalent to C<< pop @{$X} >>.

See L<perlfunc/pop>.

=item $_pos

C<< $X->$_pos >> is equivalent to C<< pos $X >>.
C<< $X->$_pos($Y) >> is equivalent to C<< pos($X) = $Y >>.

See L<perlfunc/pos>.

=item $_prototype

C<< $X->$_prototype >> is equivalent to C<< prototype $X >>.

See L<perlfunc/prototype>.

=item $_push

C<< $X->$_push(@VALUES) >> is equivalent to C<< push @{$X}, @VALUES >>.

See L<perlfunc/push>.

=item $_quotemeta

C<< $X->$_quotemeta >> is equivalent to C<< quotemeta $X >>.

See L<perlfunc/quotemeta>.

=item $_rand

C<< $X->$_rand >> is equivalent to C<< rand $X >>.

See L<perlfunc/rand>.

=item $_readlink

C<< $X->$_readlink >> is equivalent to C<< readlink $X >>.

See L<perlfunc/readlink>.

=item $_ref

C<< $X->$_ref >> is equivalent to C<< ref $X >>.

See L<perlfunc/ref>.

=item $_rename

C<< $X->$_rename($Y) >> is equivalent to C<< rename $X, $Y >>.

See L<perlfunc/rename>.

=item $_require

C<< $X->$_require >> is equivalent to C<< require $X >>.

See L<perlfunc/require>.

=item $_reverse

C<< $X->$_reverse >> is equivalent to C<< [ reverse @{$X} ] >> if C<$X> is an
array reference and C<< scalar reverse $X >> otherwise.

See L<perlfunc/reverse>.

=item $_rindex

C<< $X->$_rindex($NEEDLE) >> is equivalent to C<< rindex $X, $NEEDLE >>.
C<< $X->$_rindex($NEEDLE, $OFFSET) >> is equivalent to C<< rindex $X, $NEEDLE, $OFFSET >>.

See L<perlfunc/rindex>.

=item $_rmdir

C<< $X->$_rmdir >> is equivalent to C<< rmdir $X >>.

See L<perlfunc/rmdir>.

=item $_shift

C<< $X->$_shift >> is equivalent to C<< shift @{$X} >>.

See L<perlfunc/shift>.

=item $_sin

C<< $X->$_sin >> is equivalent to C<< sin $X >>.

See L<perlfunc/sin>.

=item $_sleep

C<< $X->$_sleep >> is equivalent to C<< sleep $X >>.

See L<perlfunc/sleep>.

=item $_sort

C<< $X->$_sort >> is equivalent to C<< [ sort @{$X} ] >>.
C<< $X->$_sort($CMP) >> is equivalent to C<< [ sort { $CMP->($a, $b) } @{$X} ] >>.

See L<perlfunc/sort>.

=item $_splice

C<< $X->$_splice >> is equivalent to C<< splice @{$X} >>.
C<< $X->$_splice($OFFSET) >> is equivalent to C<< splice @{$X}, $OFFSET >>.
C<< $X->$_splice($OFFSET, $LENGTH) >> is equivalent to C<< splice @{$X}, $OFFSET, $LENGTH >>.
C<< $X->$_splice($OFFSET, $LENGTH, @VALUES) >> is equivalent to
C<< splice @{$X}, $OFFSET, $LENGTH, @VALUES >>.

See L<perlfunc/splice>.

=item $_split

C<< $X->$_split >> is equivalent to C<< [ split ' ', $X ] >>.
C<< $X->$_split($REGEX) >> is equivalent to C<< [ split $REGEX, $X ] >>.
C<< $X->$_split($REGEX, $LIMIT) >> is equivalent to C<< [ split $REGEX, $X, $LIMIT ] >>.

See L<perlfunc/split>.

=item $_sprintf

C<< $X->$_sprintf($FORMAT) >> is equivalent to C<< sprintf $FORMAT, @{$X} >> if
C<$X> is an array reference and C<< sprintf $FORMAT, $X >> otherwise.

See L<perldoc/sprintf>.

=item $_sqrt

C<< $X->$_sqrt >> is equivalent to C<< sqrt $X >>.

See L<perlfunc/sqrt>.

=item $_srand

C<< $X->$_srand >> is equivalent to C<< srand $X >>.

See L<perlfunc/srand>.

=item $_stat

C<< $X->$_stat >> is equivalent to C<< stat $X >>.

See L<perlfunc/stat>.

=item $_substr

C<< $X->$_substr($OFFSET) >> is equivalent to C<< substr $X, $OFFSET >>.
C<< $X->$_substr($OFFSET, $LENGTH) >> is equivalent to C<< substr $X, $OFFSET, $LENGTH >>.
C<< $X->$_substr($OFFSET, $LENGTH, $REPLACEMENT) >> is equivalent to
C<< substr $X, $OFFSET, $LENGTH, $REPLACEMENT >>.

See L<perlfunc/substr>.

=item $_symlink

C<< $X->$_symlink($Y) >> is equivalent to C<< symlink $X, $Y >>.

See L<perlfunc/symlink>.

=item $_syscall

C<< $X->$_syscall(@ARGS) >> is equivalent to C<< syscall $X, @ARGS >>.

See L<perlfunc/syscall>.

=item $_system

C<< $X->$_system(@ARGS) >> is equivalent to C<< system { $X } @ARGS >>.
C<< $X->$_system >> is equivalent to C<< system @{$X} >> if C<$X> is an array
reference and C<< system $X >> otherwise.

See L<perlfunc/system>.

=item $_truncate

C<< $X->$_truncate($Y) >> is equivalent to C<< truncate $X, $Y >>.

See L<perlfunc/truncate>.

=item $_uc

C<< $X->$_uc >> is equivalent to C<< uc $X >>.

See L<perlfunc/uc>.

=item $_ucfirst

C<< $X->$_ucfirst >> is equivalent to C<< ucfirst $X >>.

See L<perlfunc/ucfirst>.

=item $_umask

C<< $X->$_umask >> is equivalent to C<< umask $X >>.

See L<perlfunc/umask>.

=item $_unlink

C<< $X->$_unlink >> is equivalent to C<< unlink $X >>.

See L<perlfunc/unlink>.

=item $_unpack

C<< $X->$_unpack($FORMAT) >> is equivalent to C<< unpack $FORMAT, $X >>.

See L<perlfunc/unpack>.

=item $_unshift

C<< $X->$_unshift(@VALUES) >> is equivalent to C<< unshift @{$X}, @VALUES >>.

See L<perlfunc/unshift>.

=item $_utime

C<< $X->$_utime($ATIME, $MTIME) >> is equivalent to
C<< utime $ATIME, $MTIME, @{$X} >> if C<$X> is an array reference and
C<< utime $ATIME, $MTIME, $X >> otherwise.

See L<perlfunc/utime>.

=item $_values

C<< $X->$_values >> is equivalent to C<< [ values @{$X} ] >> if C<$X> is an array
reference and C<< [ values %{$X} ] >> otherwise.

See L<perlfunc/values>.

=item $_vec

C<< $X->$_vec($OFFSET, $BITS) >> is equivalent to C<< vec $X, $OFFSET, $BITS >>.
C<< $X->$_vec($OFFSET, $BITS, $REPLACEMENT) is equivalent to
c<< vec($X, $OFFSET, $BITS) = $REPLACEMENT >>.

See L<perlfunc/vec>.

=item $_waitpid

C<< $X->$_waitpid >> is equivalent to C<< waitpid $X, 0 >>.
C<< $X->$_waitpid($FLAGS) >> is equivalent to C<< waitpid $X, $FLAGS >>.

See L<perlfunc/waitpid>.

=item $_warn

C<< $X->$_warn >> is equivalent to C<< warn $X >>.

See L<perlfunc/warn>.

=back

=head1 SEE ALSO

L<autobox>

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2013-2014 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
