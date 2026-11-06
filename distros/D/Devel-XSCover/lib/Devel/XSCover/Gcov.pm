package Devel::XSCover::Gcov;

use 5.020;
use strict;
use warnings;

use Cwd ();
use File::Find ();
use File::Path ();
use File::Spec ();
use IPC::Open3 ();
use Symbol ();

use Devel::XSCover::Flow ();

our $VERSION = '0.08';

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        dir       => '.',
        gcov      => ['gcov'],
        ignore    => [],
        generated => [],
        xsubs     => {},
        inverse   => {},
        skip      => [qw(blib cover_db .git)],
        save      => undef,
        conditions => 0,
        flow      => '',
        dry       => 0,
        silent    => 0,
    }, $class;
    $self->{$_} = $args{$_} for keys %args;
    return $self;
}

sub find_gcda {
    my ($self) = @_;
    my %skip = map { $_ => 1 } @{ $self->{skip} };
    my $top  = _slashes($self->{dir});
    my @found;
    File::Find::find({
        no_chdir => 1,
        wanted   => sub {
            if (-d $_) {
                my $base = (File::Spec->splitdir($_))[-1];
                $File::Find::prune = 1 if $skip{$base} && _slashes($_) ne $top;
                return;
            }
            push @found, _slashes(File::Spec->abs2rel($_, $self->{dir})) if /\.gcda\z/;
        },
    }, $self->{dir});
    return sort @found;
}

sub run_gcov {
    my ($self, $gcda) = @_;
    (my $stem = $gcda) =~ s/\.gcda\z//;
    my $name = (File::Spec->splitpath($stem))[2];
    my @cmd  = (@{ $self->{gcov} }, '-abct', ($self->{conditions} ? '--conditions' : ()), '-o', $gcda, $name);
    $self->_say("xs_cover: running @cmd");
    return '' if $self->{dry};
    my $here = Cwd::getcwd();
    chdir $self->{dir} or die "xs_cover: cannot chdir to $self->{dir}: $!\n";
    my $text = $self->_capture(@cmd);
    chdir $here;
    die "xs_cover: @cmd produced nothing in $self->{dir}\n" unless defined $text && length $text;
    if ($self->{save}) {
        File::Path::make_path($self->{save});
        (my $flat = $stem) =~ s{[/\\]}{#}g;
        my $path = File::Spec->catfile($self->{save}, "$flat.gcov.txt");
        open my $fh, '>', $path or die "xs_cover: cannot write $path: $!\n";
        print $fh $text;
        close $fh;
    }
    return $text;
}

sub run_flow {
    my ($self, $gcda) = @_;
    my $kind = $self->{flow} or return '';
    (my $stem = $gcda) =~ s/\.gcda\z//;
    my $name = (File::Spec->splitpath($stem))[2];
    my @cmd  = $kind eq 'llvm'
        ? (@{ $self->{gcov} }, '--dump', '-n', '-o', $gcda, $name)
        : (@{ $self->{gcov} }, '-abct', '--json-format', ($self->{conditions} ? '--conditions' : ()), '-o', $gcda, $name);
    $self->_say("xs_cover: running @cmd");
    return '' if $self->{dry};
    my $here = Cwd::getcwd();
    chdir $self->{dir} or die "xs_cover: cannot chdir to $self->{dir}: $!\n";
    my $text = $kind eq 'llvm' ? $self->_capture_stderr(@cmd) : $self->_capture(@cmd);
    chdir $here;
    unless (defined $text && length $text) {
        warn "xs_cover: @cmd produced no flow graph in $self->{dir}, branches come from gcov's blocks alone\n";
        return '';
    }
    if ($self->{save}) {
        File::Path::make_path($self->{save});
        (my $flat = $stem) =~ s{[/\\]}{#}g;
        my $path = File::Spec->catfile($self->{save}, "$flat.flow." . ($kind eq 'llvm' ? 'txt' : 'json'));
        open my $fh, '>', $path or die "xs_cover: cannot write $path: $!\n";
        print $fh $text;
        close $fh;
    }
    return $text;
}

sub attach_decisions {
    my ($self, $parsed, $text) = @_;
    return 0 unless defined $text && length $text;
    my $flow  = Devel::XSCover::Flow->new(dir => $self->{dir}, silent => $self->{silent});
    my $graph = $self->{flow} eq 'llvm' ? $flow->parse_llvm($text, $parsed, $self->{xsubs}) : $flow->parse_gcc($text);
    my $decisions = $flow->decisions($graph, $self->{inverse});
    my $n = 0;
    for my $file (keys %$decisions) {
        next unless $parsed->{$file};
        $parsed->{$file}{decisions} = $decisions->{$file};
        $n++;
    }
    return $n;
}

sub parse {
    my ($self, $text) = @_;
    my %files;
    my ($file, $pending, $block, $last_line, $decision);
    for my $line (split /\n/, $text) {
        if ($line =~ /^\s*-:\s*0:Source:(.*?)\s*$/) {
            $file = $1;
            $files{$file} //= { lines => {}, functions => [], blocks => [], conditions => [] };
            ($pending, $block, $last_line, $decision) = (undef, undef, undef, undef);
            next;
        }
        next unless defined $file;
        next if $line =~ /^\s*-:\s*0:/;
        if ($line =~ /^function\s+(\S+)\s+called\s+(\d+)/) {
            $pending = { name => $1, count => $2 };
            next;
        }
        if ($line =~ /^\s*\S+:\s*(\d+)-block\s+\d+/) {
            $block = { line => $1, arms => [] };
            push @{ $files{$file}{blocks} }, $block;
            next;
        }
        if ($line =~ /^branch\s+\d+\s+(?:taken\s+(\d+)%?|never executed)/) {
            my $count = $1 // 0;
            unless ($block) {
                $block = { line => $last_line // 0, arms => [] };
                push @{ $files{$file}{blocks} }, $block;
            }
            push @{ $block->{arms} }, $count;
            next;
        }
        if ($line =~ /^condition outcomes covered (\d+)\/(\d+)/) {
            $decision = { line => $last_line // 0, covered => $1, total => $2, missing => {} };
            push @{ $files{$file}{conditions} }, $decision;
            next;
        }
        if ($line =~ /^condition\s+(\d+) not covered \(([^)]+)\)/) {
            $decision->{missing}{$1}{$_} = 1 for split ' ', $2;
            next;
        }
        next if $line =~ /^(?:call|unconditional)\s/;
        if ($line =~ /^\s*([^:\s]+):\s*(\d+):/) {
            my ($count, $number) = ($1, $2);
            $last_line = $number;
            $block     = undef;
            if ($pending) {
                $pending->{line} = $number;
                push @{ $files{$file}{functions} }, $pending;
                $pending = undef;
            }
            next if $count eq '-';
            $count = 0 if $count eq '#####' || $count eq '=====';
            $count =~ s/\*\z//;
            next unless $count =~ /^\d+\z/;
            $files{$file}{lines}{$number} = $count;
        }
    }
    for my $f (values %files) {
        $f->{blocks} = [ grep { @{ $_->{arms} } } @{ $f->{blocks} } ];
        for my $d (@{ $f->{conditions} }) {
            my $missing = delete $d->{missing};
            $d->{terms} = [ map { { true => $missing->{$_}{true} ? 0 : 1, false => $missing->{$_}{false} ? 0 : 1 } } 0 .. int($d->{total} / 2) - 1 ];
        }
    }
    return \%files;
}

sub filter {
    my ($self, $files, $gcda) = @_;
    my $root = Cwd::abs_path($self->{dir});
    $root = File::Spec->rel2abs($self->{dir}) unless defined $root;
    $root = _slashes($root);
    my %generated = map { $_ => 1 } @{ $self->{generated} };
    my @ignore    = map { qr/$_/ } @{ $self->{ignore} };
    my ($vol, $beside) = defined $gcda ? File::Spec->splitpath($gcda) : ('', '');
    my (%kept, %aside);
    for my $name (sort keys %$files) {
        my $rel = $name;
        if (File::Spec->file_name_is_absolute($rel)) {
            my $abs = Cwd::abs_path($rel);
            $abs = $rel unless defined $abs;
            $abs = _slashes($abs);
            next unless index($abs, "$root/") == 0;
            $rel = File::Spec->abs2rel($abs, $root);
        }
        elsif (length $beside && !-f File::Spec->catfile($self->{dir}, $rel)) {
            my $near = File::Spec->catpath($vol, $beside, $rel);
            $rel = $near if -f File::Spec->catfile($self->{dir}, $near);
        }
        $rel =~ s{^\./+}{};
        $rel = _slashes(File::Spec->canonpath($rel));
        next if (File::Spec->splitpath($rel))[2] eq 'ppport.h';
        if ($generated{$rel}) {
            $aside{$rel} = $files->{$name};
            next;
        }
        next if grep { $rel =~ $_ } @ignore;
        $kept{$rel} = $files->{$name};
    }
    return (\%kept, \%aside);
}

sub read {
    my ($self) = @_;
    my @objects;
    for my $gcda ($self->find_gcda) {
        my $text = $self->run_gcov($gcda);
        next unless length $text;
        my $parsed = $self->parse($text);
        $self->attach_decisions($parsed, $self->run_flow($gcda));
        my ($files, $generated) = $self->filter($parsed, $gcda);
        push @objects, { object => $gcda, files => $files, generated => $generated };
    }
    $self->_say(sprintf 'xs_cover: read %d object%s', scalar @objects, @objects == 1 ? '' : 's');
    return @objects;
}

sub _capture {
    my ($self, @cmd) = @_;
    return $self->_run_capture(0, @cmd);
}

sub _capture_stderr {
    my ($self, @cmd) = @_;
    return $self->_run_capture(1, @cmd);
}

sub _run_capture {
    my ($self, $stderr, @cmd) = @_;
    local *NULL;
    open NULL, '>', File::Spec->devnull;
    my ($in, $out, $err) = (undef, Symbol::gensym(), Symbol::gensym());
    my $pid = eval { IPC::Open3::open3($in, $stderr ? '>&NULL' : $out, $stderr ? $err : '>&NULL', @cmd) };
    return undef unless $pid;
    close $in;
    my $fh   = $stderr ? $err : $out;
    my $text = do { local $/; <$fh> };
    close $fh;
    waitpid $pid, 0;
    return $text;
}

sub _slashes {
    my ($path) = @_;
    $path =~ s{\\}{/}g if $^O eq 'MSWin32';
    return $path;
}

sub _say {
    my ($self, $line) = @_;
    print "$line\n" unless $self->{silent};
}

1;

__END__

=head1 NAME

Devel::XSCover::Gcov - the counters the compiler wrote, read through gcov

=head1 SYNOPSIS

    use Devel::XSCover::Gcov;
    my $reader  = Devel::XSCover::Gcov->new(dir => '.', gcov => ['gcov']);
    my @objects = $reader->read;

=head1 DESCRIPTION

Finds every counter file the instrumented objects wrote, runs gcov on each from the
distribution directory, and parses its text into one structure per object that
knows nothing of Devel::Cover: the executable lines with their counts, the functions
with their first line and call count, and the blocks that end in a jump with the
count of each arm. Where the tool can also give the flow graph, the decisions of
each source are read from it too, through L<Devel::XSCover::Flow>.

=head1 METHODS

=head2 new

    my $reader = Devel::XSCover::Gcov->new(%options);

Options: C<dir>, C<gcov> (the tool as a list of words), C<conditions> (ask gcov for
condition coverage, gcc 14 and later), C<flow> (C<llvm> or C<gcc> to ask the tool
for the flow graph too, as L<Devel::XSCover::Build> detects it, or empty), C<ignore>
(patterns on the relative path), C<generated> (the generated C files to keep aside), C<xsubs> (C wrapper name to the
F<.xs> file of its body, for the llvm flow dump), C<inverse> (per XS file, the line gcov
reports to the line written, for the decisions of a body with dropped comment lines),
C<skip> (directories not searched, C<blib>, C<cover_db> and C<.git> by default),
C<save> (a directory to keep each object's gcov text in), C<dry> and C<silent>.

=head2 find_gcda

Every F<.gcda> under the directory, relative to it, sorted.

=head2 run_gcov

    my $text = $reader->run_gcov('src/helper.gcda');

Runs the tool from the distribution directory with C<-abct> and the counter file,
and returns the text. The source paths gcov records are relative to the directory
the object was compiled in, so it must run there.

=head2 run_flow

    my $graph = $reader->run_flow('src/helper.gcda');

The flow graph of the same object as text: C<llvm-cov gcov --dump> for C<llvm>, which
prints it on its error stream, and C<gcov --json-format> for C<gcc>. Nothing when
C<flow> is empty, and a warning and nothing when the tool gives nothing, in which case
the branches of that object come from gcov's blocks alone. Saved beside the gcov text
as F<NAME.flow.txt> or F<NAME.flow.json>.

=head2 attach_decisions

    my $files_with = $reader->attach_decisions($parsed, $graph);

Reads the decisions of every source in the graph and puts them under C<decisions> in
the parsed structure of that file, a list of C<{ line, arms }>. A file with that key
gets its branches from it, with or without entries, and one without gets them from its
blocks.

=head2 parse

    my $files = $reader->parse($text);

The structure, keyed by source file as gcov names it:

    { 'Spike.xs' => {
        lines     => { 27 => 353062, 37 => 1 },
        functions => [ { name => 'only_from_one', line => 8, count => 2 } ],
        blocks    => [ { line => 36, arms => [2, 1] }, { line => 47, arms => [1, 1, 1, 0, 1] } ],
        conditions => [ { line => 36, covered => 3, total => 4, terms => [ { true => 1, false => 1 }, { true => 1, false => 0 } ] } ],
    } }

A count of C<-> is not an executable line. C<#####> and C<=====> are zero, a trailing
C<*> is dropped. A function's line is the first source line after its summary. A
block's arms are the C<branch> lines after it, a never executed arm counting zero,
and blocks without arms are dropped. Branch lines without a block of their own make
one block for the line. A C<condition outcomes covered N/M> line, which gcc 14's
C<gcov --conditions> writes under a line, is a decision of M/2 terms, and the
C<condition K not covered (true)> lines after it say which outcome of which term
never decided the result. Each term ends up with a C<true> and a C<false> flag.

=head2 filter

    my ($kept, $aside) = $reader->filter($files, $gcda);

Drops every file outside the distribution directory, F<ppport.h>, and files matching
an C<ignore> pattern. Files in C<generated> are returned apart, as the second value,
for the XS map. Absolute paths under the directory become relative. A relative name
that is not under the directory itself but is beside the counter file, when one is
given, takes that directory: an object compiled in a subdirectory, a test's own XS
module say, names its sources from there.

=head2 read

Runs the steps for every counter file, gcov, the flow graph when there is one, the
parse and the filter, and returns a list of hashes with C<object> (the counter
file), C<files> and C<generated>.

=head1 SEE ALSO

L<Devel::XSCover>

=cut
