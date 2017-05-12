package MDK::Common::Func;

=head1 NAME

MDK::Common::Func - miscellaneous functions

=head1 SYNOPSIS

    use MDK::Common::Func qw(:all);

=head1 EXPORTS

=over

=item may_apply(CODE REF, SCALAR)

C<may_apply($f, $v)> is C<$f ? $f-E<gt>($v) : $v>

=item may_apply(CODE REF, SCALAR, SCALAR)

C<may_apply($f, $v, $otherwise)> is C<$f ? $f-E<gt>($v) : $otherwise>

=item if_(BOOL, LIST)

special constructs to workaround a missing perl feature:
C<if_($b, "a", "b")> is C<$b ? ("a", "b") : ()>

example of use: C<f("a", if_(arch() =~ /i.86/, "b"), "c")> which is not the
same as C<f("a", arch()=~ /i.86/ && "b", "c")>

=item if__(SCALAR, LIST)

if_ alike. Test if the value is defined

=item fold_left { CODE } LIST

if you don't know fold_left (aka foldl), don't use it ;p

    fold_left { $::a + $::b } 1, 3, 6

gives 10 (aka 1+3+6)

=item mapn { CODE } ARRAY REF, ARRAY REF, ...

map lists in parallel:

    mapn { $_[0] + $_[1] } [1, 2], [2, 4] # gives 3, 6
    mapn { $_[0] + $_[1] + $_[2] } [1, 2], [2, 4], [3, 6] gives 6, 12

=item mapn_ { CODE } ARRAY REF, ARRAY REF, ... 

mapn alike. The difference is what to do when the lists have not the same
length: mapn takes the minimum common elements, mapn_ takes the maximum list
length and extend the lists with undef values

=item find { CODE } LIST

returns the first element where CODE returns true (or returns undef)

    find { /foo/ } "fo", "fob", "foobar", "foobir"

gives "foobar"

=item any { CODE } LIST

returns 1 if CODE returns true for an element in LIST (otherwise returns 0)

    any { /foo/ } "fo", "fob", "foobar", "foobir"

gives 1

=item every { CODE } LIST

returns 1 if CODE returns true for B<every> element in LIST (otherwise returns 0)

    every { /foo/ } "fo", "fob", "foobar", "foobir"

gives 0

=item map_index { CODE } LIST

just like C<map>, but set C<$::i> to the current index in the list:

    map_index { "$::i $_" } "a", "b"

gives "0 a", "1 b"

=item each_index { CODE } LIST

just like C<map_index>, but doesn't return anything

    each_index { print "$::i $_\n" } "a", "b"

prints "0 a", "1 b"

=item grep_index { CODE } LIST

just like C<grep>, but set C<$::i> to the current index in the list:

    grep_index { $::i == $_ } 0, 2, 2, 3

gives (0, 2, 3)

=item find_index { CODE } LIST

returns the index of the first element where CODE returns true (or throws an exception)

    find_index { /foo/ } "fo", "fob", "foobar", "foobir"

gives 2

=item map_each { CODE } HASH

returns the list of results of CODE applied with $::a (key) and $::b (value)

    map_each { "$::a is $::b" } 1=>2, 3=>4

gives "1 is 2", "3 is 4"

=item grep_each { CODE } HASH

returns the hash key/value for which CODE applied with $::a (key) and $::b
(value) is true:

    grep_each { $::b == 2 } 1=>2, 3=>4, 4=>2

gives 1=>2, 4=>2

=item partition { CODE } LIST

alike C<grep>, but returns both the list of matching elements and non matching elements

    my ($greater, $lower) = partition { $_ > 3 } 4, 2, 8, 0, 1

gives $greater = [ 4, 8 ] and $lower = [ 2, 0, 1 ]

=item before_leaving { CODE }

the code will be executed when the current block is finished

    # create $tmp_file
    my $b = before_leaving { unlink $tmp_file };
    # some code that may throw an exception, the "before_leaving" ensures the
    # $tmp_file will be removed

=item cdie(SCALAR)

aka I<conditional die>. If a C<cdie> is catched, the execution continues
B<after> the cdie, not where it was catched (as happens with die & eval)

If a C<cdie> is not catched, it mutates in real exception that can be catched
with C<eval>

cdie is useful when you want to warn about something weird, but when you can
go on. In that case, you cdie "something weird happened", and the caller
decide wether to go on or not. Especially nice for libraries.

=item catch_cdie { CODE1 } sub { CODE2 }

If a C<cdie> occurs while executing CODE1, CODE2 is executed. If CODE2
returns true, the C<cdie> is catched.

=back

=head1 SEE ALSO

L<MDK::Common>

=cut

use MDK::Common::Math;


use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(may_apply if_ if__ fold_left mapn mapn_ find any every map_index each_index grep_index find_index map_each grep_each partition before_leaving catch_cdie cdie);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);


sub may_apply { $_[0] ? $_[0]->($_[1]) : (@_ > 2 ? $_[2] : $_[1]) }

# prototype is needed for things like: if_(/foo/, bar => 'boo')
sub if_($@) {
    my $b = shift;
    $b or return ();
    wantarray() || @_ <= 1 or die("if_ called in scalar context with more than one argument :\nargs="  . join(", ", @_) . "\ncaller=" . join(":", caller()));
    wantarray() ? @_ : $_[0];
}
sub if__($@) {
    my $b = shift;
    defined $b or return ();
    wantarray() || @_ <= 1 or die("if__ called in scalar context with more than one argument :\nargs="  . join(", ", @_) . "\ncaller=" . join(":", caller()));
    wantarray() ? @_ : $_[0];
}

sub fold_left(&@) {
    my ($f, $initial, @l) = @_;
    local ($::a, $::b);
    $::a = $initial;
    foreach (@l) { $::b = $_; $::a = &$f() }
    $::a;
}

sub smapn {
    my $f = shift;
    my $n = shift;
    my @r;
    for (my $i = 0; $i < $n; $i++) { push @r, &$f(map { $_->[$i] } @_) }
    @r;
}
sub mapn(&@) {
    my $f = shift;
    smapn($f, MDK::Common::Math::min(map { scalar @$_ } @_), @_);
}
sub mapn_(&@) {
    my $f = shift;
    smapn($f, MDK::Common::Math::max(map { scalar @$_ } @_), @_);
}

sub find(&@) {
    my $f = shift;
    $f->($_) and return $_ foreach @_;
    undef;
}
sub any(&@) {
    my $f = shift;
    $f->($_) and return 1 foreach @_;
    0;
}
sub every(&@) {
    my $f = shift;
    $f->($_) or return 0 foreach @_;
    1;
}

sub map_index(&@) {
    my $f = shift;
    my @v; local $::i = 0;
    map { @v = $f->(); $::i++; @v } @_;
}
sub each_index(&@) {
    my $f = shift;
    local $::i = 0;
    foreach (@_) {
	$f->();
	$::i++;
    }
}
sub grep_index(&@) {
    my $f = shift;
    my $v; local $::i = 0;
    grep { $v = $f->(); $::i++; $v } @_;
}
sub find_index(&@) {
    my $f = shift;
    local $_;
    for (my $i = 0; $i < @_; $i++) {
	$_ = $_[$i];
	&$f and return $i;
    }
    die "find_index failed in @_";
}
sub map_each(&%) {
    my ($f, %h) = @_;
    my @l;
    local ($::a, $::b);
    while (($::a, $::b) = each %h) { push @l, &$f($::a, $::b) }
    @l;
}
sub grep_each(&%) {
    my ($f, %h) = @_;
    my %l;
    local ($::a, $::b);
    while (($::a, $::b) = each %h) { $l{$::a} = $::b if &$f($::a, $::b) }
    %l;
}
sub partition(&@) {
    my $f = shift;
    my (@a, @b);
    foreach (@_) {
	$f->($_) ? push(@a, $_) : push(@b, $_);
    }
    \@a, \@b;
}

sub add_f4before_leaving {
    my ($f, $b, $name) = @_;

    $MDK::Common::Func::before_leaving::_list->{$b}{$name} = $f;
    if (!$MDK::Common::Func::before_leaving::_added{$name}) {
	$MDK::Common::Func::before_leaving::_added{$name} = 1;
	no strict 'refs';
	*{"MDK::Common::Func::before_leaving::$name"} = sub {
	    my $f = $MDK::Common::Func::before_leaving::_list->{$_[0]}{$name} or die '';
	    $name eq 'DESTROY' and delete $MDK::Common::Func::before_leaving::_list->{$_[0]};
	    &$f;
	};
    }
}

#- ! the functions are not called in the order wanted, in case of multiple before_leaving :(
sub before_leaving(&) {
    my ($f) = @_;
    my $b = bless {}, 'MDK::Common::Func::before_leaving';
    add_f4before_leaving($f, $b, 'DESTROY');
    $b;
}

sub catch_cdie(&&) {
    my ($f, $catch) = @_;

    local @MDK::Common::Func::cdie_catches;
    unshift @MDK::Common::Func::cdie_catches, $catch;
    &$f();
}

sub cdie {
    my ($err) = @_;
    foreach (@MDK::Common::Func::cdie_catches) {
	$@ = $err;
	if (my $v = $_->(\$err)) {
	    return $v;
	}
    }
    die $err;
}

1;

