package Devel::XSCover::Build;

use 5.020;
use strict;
use warnings;

use Config ();
use File::Find ();
use File::Spec ();

our $VERSION = '0.02';

our (%SOURCE_EXT, $COVERAGE);

BEGIN {
    %SOURCE_EXT = map { $_ => 1 } qw(xs c cc cpp cxx h hh hpp);
    $COVERAGE = '-fprofile-arcs -ftest-coverage';
}

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        dir     => '.',
        make    => 'make',
        perl    => $^X,
        cc      => $Config::Config{cc},
        gcov    => undef,
        conditions => undef,
        dry     => 0,
        silent  => 0,
        skip    => [qw(blib cover_db .git)],
    }, $class;
    $self->{$_} = $args{$_} for keys %args;
    return $self;
}

sub dir { $_[0]{dir} }

sub compiler {
    my ($self) = @_;
    return $self->{compiler} if $self->{compiler};
    my $banner = $self->_capture($self->{cc}, '--version');
    my ($first) = split /\n/, $banner // '';
    $first //= '';
    my %c = (cc => $self->{cc}, name => 'unknown', major => 0, banner => $first);
    if ($first =~ /clang version (\d+)/) {
        @c{qw(name major)} = ('clang', $1);
    }
    elsif ($first =~ /\b(?:gcc|g\+\+|GCC)\b/ || $banner =~ /Free Software Foundation/
        || $first =~ /^\S+ \([^)]*\) \d+\.\d+(?:\.\d+)?\b/) {
        @c{qw(name major)} = ('gcc', $first =~ /(\d+)\.\d+(?:\.\d+)?/ ? $1 : 0);
    }
    return $self->{compiler} = \%c;
}

sub gcov_command {
    my ($self) = @_;
    return [ split ' ', $self->{gcov} ] if defined $self->{gcov} && length $self->{gcov};
    my $c = $self->compiler;
    if ($c->{name} eq 'clang') {
        my $gcov = $self->_which('gcov');
        if ($gcov) {
            my $banner = $self->_capture($gcov, '--version') // '';
            return [$gcov] if $banner =~ /LLVM/;
        }
        for my $name ("llvm-cov-$c->{major}", 'llvm-cov') {
            my $path = $self->_which($name);
            return [$path, 'gcov'] if $path;
        }
        if ($^O eq 'darwin') {
            my $found = $self->_capture('xcrun', '--find', 'llvm-cov') // '';
            chomp $found;
            return [$found, 'gcov'] if length $found && -x $found;
        }
        return [ $gcov || 'gcov' ];
    }
    for my $name ("gcov-$c->{major}", 'gcov') {
        my $path = $self->_which($name);
        return [$path] if $path;
    }
    return ['gcov'];
}

sub conditions {
    my ($self) = @_;
    return $self->{conditions} ? 1 : 0 if defined $self->{conditions};
    my $c = $self->compiler;
    return $c->{name} eq 'gcc' && $c->{major} >= 14 ? 1 : 0;
}

sub flags {
    my ($self) = @_;
    my $condition = $self->conditions ? ' -fcondition-coverage' : '';
    return (
        "OPTIMIZE=-O0 -g $COVERAGE -fprofile-update=atomic$condition",
        "OTHERLDFLAGS=$COVERAGE",
    );
}

sub needs_configure {
    my ($self) = @_;
    my $makefile = File::Spec->catfile($self->{dir}, 'Makefile');
    my $pl       = File::Spec->catfile($self->{dir}, 'Makefile.PL');
    return 1 unless -f $makefile;
    return 1 unless -f $pl;
    return (stat $makefile)[9] < (stat $pl)[9] ? 1 : 0;
}

sub clean_globs {
    my ($self) = @_;
    my $pl = File::Spec->catfile($self->{dir}, 'Makefile.PL');
    open my $fh, '<', $pl or return;
    my $text = do { local $/; <$fh> };
    close $fh;
    my @globs;
    while ($text =~ /clean\s*=>\s*\{[^}]*?FILES\s*=>\s*(['"])(.*?)\1/sg) {
        push @globs, split ' ', $2;
    }
    my ($name) = $text =~ /\bNAME\s*=>\s*(['"])(.*?)\1/ ? $2 : '';
    (my $dist = $name) =~ s/::/-/g;
    my @out;
    for my $glob (@globs) {
        $glob =~ s/\$\(DISTNAME\)/$dist/g;
        next if $glob =~ /\$\(/;
        push @out, $glob;
    }
    return @out;
}

sub tarballs_at_risk {
    my ($self) = @_;
    my %seen;
    my @hit;
    for my $glob ($self->clean_globs) {
        for my $file (glob File::Spec->catfile($self->{dir}, $glob)) {
            next unless $file =~ /\.(?:tar\.gz|tgz|zip)\z/ && -f $file;
            push @hit, $file unless $seen{$file}++;
        }
    }
    return @hit;
}

sub configure {
    my ($self) = @_;
    return 0 unless $self->needs_configure;
    if (-f File::Spec->catfile($self->{dir}, 'Makefile')) {
        my @risk = $self->tarballs_at_risk;
        warn "xs_cover: a stale Makefile reruns clean by itself, and the clean glob in "
           . "Makefile.PL matches @risk\n" if @risk;
    }
    return $self->_run($self->{perl}, 'Makefile.PL');
}

sub touch {
    my ($self) = @_;
    my %skip = map { $_ => 1 } @{ $self->{skip} };
    my $now = time;
    my @touched;
    File::Find::find({
        no_chdir => 1,
        wanted   => sub {
            if (-d $_) {
                my $base = (File::Spec->splitdir($_))[-1];
                $File::Find::prune = 1 if $skip{$base} && $_ ne $self->{dir};
                return;
            }
            return unless /\.([A-Za-z]+)\z/ && $SOURCE_EXT{ lc $1 };
            push @touched, $_;
            utime $now, $now, $_ unless $self->{dry};
        },
    }, $self->{dir});
    $self->_say(sprintf 'xs_cover: touched %d source file%s', scalar @touched, @touched == 1 ? '' : 's');
    return @touched;
}

sub build {
    my ($self) = @_;
    return $self->_run($self->{make}, $self->flags);
}

sub run {
    my ($self) = @_;
    my $status = $self->configure;
    return $status if $status;
    $self->touch;
    return $self->build;
}

sub _run {
    my ($self, @cmd) = @_;
    $self->_say("xs_cover: running @cmd");
    return 0 if $self->{dry};
    my $status;
    if ($self->{dir} eq '.') {
        $status = system @cmd;
    }
    else {
        require Cwd;
        my $here = Cwd::getcwd();
        chdir $self->{dir} or die "xs_cover: cannot chdir to $self->{dir}: $!\n";
        $status = system @cmd;
        chdir $here;
    }
    return $status == -1 ? 127 : $status >> 8;
}

sub _say {
    my ($self, $line) = @_;
    print "$line\n" unless $self->{silent};
}

sub _capture {
    my ($self, @cmd) = @_;
    my $pid = open my $fh, '-|';
    return undef unless defined $pid;
    if (!$pid) {
        open STDERR, '>', File::Spec->devnull;
        exec @cmd or exit 127;
    }
    my $out = do { local $/; <$fh> };
    close $fh;
    return $out;
}

sub _which {
    my ($self, $name) = @_;
    for my $dir (File::Spec->path) {
        my $path = File::Spec->catfile($dir, $name);
        return $path if -f $path && -x $path;
    }
    return undef;
}

1;

__END__

=head1 NAME

Devel::XSCover::Build - the instrumented build of a distribution

=head1 SYNOPSIS

    use Devel::XSCover::Build;
    my $build  = Devel::XSCover::Build->new(dir => '.');
    my $status = $build->run;

=head1 DESCRIPTION

Rebuilds every XS and C source of a distribution with the compiler's coverage
instrumentation. The flags go on the make command line as C<OPTIMIZE> and
C<OTHERLDFLAGS>, so the distribution's own Makefile.PL is never edited and its
C<CCFLAGS> stay as they are. The sources are touched first so make rebuilds every
object. C<make clean> is never run.

=head1 METHODS

=head2 new

    my $build = Devel::XSCover::Build->new(%options);

Options: C<dir> (the distribution directory), C<make>,
C<perl>, C<cc> (the compiler, from perl's configuration by default), C<gcov> (a
tool overriding the detection), C<conditions> (condition coverage on or off,
decided by the compiler when not given), C<dry>, C<silent> and C<skip> (directory
names not touched, C<blib>, C<cover_db> and C<.git> by default).

=head2 conditions

True when the build asks the compiler for condition coverage: gcc 14 and later
have C<-fcondition-coverage>, which records for every term of a decision whether
its true and its false outcome each decided the result, and C<gcov --conditions>
reports it. Other compilers have nothing of the kind in gcov's output, so the
condition column stays empty for C with them.

=head2 compiler

    my $c = $build->compiler;

Runs the compiler with C<--version> and returns a hash reference with C<name>
(C<clang>, C<gcc> or C<unknown>), C<major> and C<banner>.

=head2 gcov_command

    my @cmd = @{ $build->gcov_command };

The gcov tool as a list of words. For clang it is the C<gcov> on the path when that
is LLVM's (as on macOS), else C<llvm-cov gcov>, else on macOS the one C<xcrun> finds.
For gcc it is C<gcov-N> for the compiler's major version when on the path, else
C<gcov>. The C<gcov> option overrides all of that.

=head2 flags

    my @flags = $build->flags;

The make macros: C<OPTIMIZE> with C<-O0 -g>, the coverage flags, atomic profile
updates (threads lose half their counts without them) and C<-fcondition-coverage>
when C<conditions> says so, and C<OTHERLDFLAGS> with the coverage flags.

=head2 needs_configure

True when there is no Makefile or it is older than Makefile.PL.

=head2 clean_globs

The globs of the C<clean> entry in Makefile.PL, with C<$(DISTNAME)> filled in and
any other macro dropped.

=head2 tarballs_at_risk

The archives in the directory that those globs match. A stale Makefile reruns clean
by itself when Makefile.PL is run, and that takes them.

=head2 configure

Runs C<perl Makefile.PL> when needed, warning first when tarballs are at risk.
Returns the exit status.

=head2 touch

Sets the modification time of every C<.xs>, C<.c>, C<.cc>, C<.cpp>, C<.cxx>, C<.h>,
C<.hh> and C<.hpp> under the directory to now, skipping the directories in C<skip>.
Returns the files touched.

=head2 build

Runs make with the flags. Returns the exit status.

=head2 run

C<configure>, C<touch> and C<build> in that order, stopping at the first failure.
Returns the exit status.

=head2 dir

The distribution directory.

=head1 SEE ALSO

L<Devel::XSCover>

=cut
