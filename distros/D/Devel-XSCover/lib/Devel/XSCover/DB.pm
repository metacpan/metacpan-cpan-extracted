package Devel::XSCover::DB;

use 5.020;
use strict;
use warnings;

use Cwd ();
use File::Path ();
use File::Spec ();

use Devel::XSCover::Flow ();

our $VERSION = '0.07';

our (@CRITERIA);

BEGIN {
    @CRITERIA = qw(statement branch subroutine);
}

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        dir    => '.',
        db     => 'cover_db',
        dry    => 0,
        silent => 0,
    }, $class;
    $self->{$_} = $args{$_} for keys %args;
    return $self;
}

sub merge {
    my ($self, @objects) = @_;
    my (%files, %generated);
    for my $object (@objects) {
        _merge_into(\%files, $object->{files} || {});
        _merge_into(\%generated, $object->{generated} || {});
    }
    return (\%files, \%generated);
}

sub _merge_into {
    my ($into, $from) = @_;
    for my $name (sort keys %$from) {
        my $src = $from->{$name};
        my $dst = $into->{$name} //= { lines => {}, functions => [], blocks => [], conditions => [] };
        $dst->{lines}{$_} += $src->{lines}{$_} for keys %{ $src->{lines} };
        my %fn = map { ("$_->{name}\0$_->{line}", $_) } @{ $dst->{functions} };
        for my $f (@{ $src->{functions} }) {
            my $key = "$f->{name}\0$f->{line}";
            if ($fn{$key}) {
                $fn{$key}{count} += $f->{count};
            }
            else {
                push @{ $dst->{functions} }, $fn{$key} = { %$f };
            }
        }
        my %seen;
        my %have;
        for my $b (@{ $dst->{blocks} }) {
            push @{ $have{ $b->{line} } }, $b;
        }
        for my $b (@{ $src->{blocks} }) {
            my $n    = $seen{ $b->{line} }++;
            my $peer = $have{ $b->{line} }[$n];
            if ($peer && @{ $peer->{arms} } == @{ $b->{arms} }) {
                $peer->{arms}[$_] += $b->{arms}[$_] for 0 .. $#{ $b->{arms} };
            }
            else {
                my $copy = { line => $b->{line}, arms => [ @{ $b->{arms} } ] };
                push @{ $dst->{blocks} }, $copy;
                push @{ $have{ $b->{line} } }, $copy;
            }
        }
        if ($src->{decisions}) {
            my (%dseen, %dhave);
            $dst->{decisions} //= [];
            push @{ $dhave{ $_->{line} } }, $_ for @{ $dst->{decisions} };
            for my $d (@{ $src->{decisions} }) {
                my $n    = $dseen{ $d->{line} }++;
                my $peer = $dhave{ $d->{line} }[$n];
                if ($peer && @{ $peer->{arms} } == @{ $d->{arms} }) {
                    $peer->{arms}[$_] += $d->{arms}[$_] for 0 .. $#{ $d->{arms} };
                }
                else {
                    my $copy = { line => $d->{line}, arms => [ @{ $d->{arms} } ] };
                    push @{ $dst->{decisions} }, $copy;
                    push @{ $dhave{ $d->{line} } }, $copy;
                }
            }
        }
        my (%cseen, %chave);
        push @{ $chave{ $_->{line} } }, $_ for @{ $dst->{conditions} };
        for my $d (@{ $src->{conditions} || [] }) {
            my $n    = $cseen{ $d->{line} }++;
            my $peer = $chave{ $d->{line} }[$n];
            if ($peer && @{ $peer->{terms} } == @{ $d->{terms} }) {
                for my $k (0 .. $#{ $d->{terms} }) {
                    $peer->{terms}[$k]{$_} ||= $d->{terms}[$k]{$_} for qw(true false);
                }
            }
            else {
                my $copy = { line => $d->{line}, covered => $d->{covered}, total => $d->{total}, terms => [ map { { %$_ } } @{ $d->{terms} } ] };
                push @{ $dst->{conditions} }, $copy;
                push @{ $chave{ $d->{line} } }, $copy;
            }
        }
    }
}

sub entries {
    my ($self, $files, $generated, @maps) = @_;
    my %out;
    for my $map (@maps) {
        my $inverse = $map->{inverse} or next;
        for my $file (keys %$inverse) {
            $self->_relocate($files->{$file}, $inverse->{$file}) if $files->{$file};
        }
    }
    for my $file (sort keys %$files) {
        my $f = $files->{$file};
        my $e = $out{$file} = { statement => [], branch => [], subroutine => [], condition => [] };
        for my $line (sort { $a <=> $b } keys %{ $f->{lines} }) {
            next if $self->_braces_only($file, $line);
            push @{ $e->{statement} }, [ $line, $f->{lines}{$line} ];
        }
        my @branches = $f->{decisions} && !$self->{macro_branches}
            ? @{ $f->{decisions} }
            : grep { @{ $_->{arms} } >= 2 && ($self->{macro_branches} || $self->_decides($file, $_->{line})) } @{ $f->{blocks} };
        for my $b (sort { $a->{line} <=> $b->{line} } @branches) {
            my @arms = @{ $b->{arms} };
            if (@arms == 2) {
                push @{ $e->{branch} }, [ $b->{line}, $self->_source_text($file, $b->{line}), [@arms] ];
                next;
            }
            my $total = 0;
            $total += $_ for @arms;
            for my $k (0 .. $#arms) {
                push @{ $e->{branch} }, [ $b->{line}, sprintf('arm %d of %d', $k + 1, scalar @arms), [ $arms[$k], $total - $arms[$k] ] ];
            }
        }
        for my $d (sort { $a->{line} <=> $b->{line} } @{ $f->{conditions} || [] }) {
            next unless $self->{macro_branches} || $self->_terms($file, $d->{line}) == @{ $d->{terms} };
            my $text = $self->_source_text($file, $d->{line});
            for my $k (0 .. $#{ $d->{terms} }) {
                my $term = $d->{terms}[$k];
                push @{ $e->{condition} }, [ $d->{line}, { type => 'and_2', left => 'term ' . ($k + 1), op => 'of', right => $text }, [ $term->{true} ? 1 : 0, $term->{false} ? 1 : 0 ] ];
            }
        }
        for my $fn (sort { $a->{line} <=> $b->{line} } sort { $a->{name} cmp $b->{name} } @{ $f->{functions} }) {
            push @{ $e->{subroutine} }, [ $fn->{line}, $fn->{name}, $fn->{count} ];
        }
    }
    for my $map (@maps) {
        my %count = map { $_->{name} => $_->{count} } @{ $generated->{ $map->{c} }{functions} || [] };
        for my $c_name (sort keys %{ $map->{xsubs} }) {
            my $x = $map->{xsubs}{$c_name};
            next unless defined $x->{line} && @{ $x->{names} };
            next if %count && !exists $count{$c_name};
            my $e = $out{ $x->{file} } //= { statement => [], branch => [], subroutine => [], condition => [] };
            for my $name (@{ $x->{names} }) {
                push @{ $e->{subroutine} }, [ $x->{line}, $name, $count{$c_name} // 0 ];
            }
        }
    }
    for my $e (values %out) {
        @{ $e->{subroutine} } = sort { $a->[0] <=> $b->[0] } sort { $a->[1] cmp $b->[1] } @{ $e->{subroutine} };
    }
    return \%out;
}

sub write {
    my ($self, $entries) = @_;
    require Devel::Cover::DB;
    require Devel::Cover::DB::Structure;
    my $here = Cwd::getcwd();
    chdir $self->{dir} or die "xs_cover: cannot chdir to $self->{dir}: $!\n";
    my $db = File::Spec->rel2abs($self->{db});
    my @criteria = (@CRITERIA, (grep { @{ $_->{condition} || [] } } values %$entries) ? ('condition') : ());
    my %run = (collected => [@criteria], start => time, run => "xs_cover $self->{dir}", perl => sprintf('%vd', $^V), OS => $^O);
    my $structure = Devel::Cover::DB::Structure->new;
    $structure->add_criteria(@criteria);
    my %summary = (files => 0, statement => 0, branch => 0, subroutine => 0, condition => 0);
    for my $file (sort keys %$entries) {
        my $e = $entries->{$file};
        unless (-f $file) {
            warn "xs_cover: no source $file under $self->{dir}, skipped\n";
            next;
        }
        $run{digests}{$file} = $structure->set_file($file);
        $summary{files}++;
        for my $s (@{ $e->{statement} }) {
            $structure->add_statement($file, $s->[0]);
            push @{ $run{count}{$file}{statement} }, $s->[1];
            $summary{statement}++;
        }
        for my $b (@{ $e->{branch} }) {
            $structure->add_branch($file, [ $b->[0], { text => $b->[1] } ]);
            push @{ $run{count}{$file}{branch} }, [ @{ $b->[2] } ];
            $summary{branch}++;
        }
        for my $s (@{ $e->{subroutine} }) {
            $structure->add_subroutine($file, [ $s->[0], $s->[1] ]);
            push @{ $run{count}{$file}{subroutine} }, $s->[2];
            $summary{subroutine}++;
        }
        for my $c (@{ $e->{condition} || [] }) {
            $structure->add_condition($file, [ $c->[0], $c->[1] ]);
            push @{ $run{count}{$file}{condition} }, [ @{ $c->[2] } ];
            $summary{condition}++;
        }
    }
    $run{finish} = time;
    my $name = $run{start} . ".$$." . sprintf '%05d', rand 2**16;
    my $path = File::Spec->catdir($db, 'runs', $name);
    $self->_say(sprintf 'xs_cover: writing %d file%s, %d statements, %d branches, %d subroutines%s to %s',
        $summary{files}, $summary{files} == 1 ? '' : 's', @summary{qw(statement branch subroutine)}, $summary{condition} ? ", $summary{condition} conditions" : '', $path);
    unless ($self->{dry}) {
        my $cover = Devel::Cover::DB->new(base => $db, runs => { $name => \%run }, structure => $structure);
        File::Path::make_path(File::Spec->catdir($db, 'runs'));
        $cover->{db} = $path;
        $cover->write;
    }
    chdir $here;
    return { run => $path, %summary };
}

sub _relocate {
    my ($self, $f, $to) = @_;
    my %lines;
    $lines{ $to->{$_} // $_ } += $f->{lines}{$_} for keys %{ $f->{lines} };
    $f->{lines} = \%lines;
    for my $list (qw(functions blocks conditions decisions)) {
        $_->{line} = $to->{ $_->{line} } // $_->{line} for @{ $f->{$list} || [] };
    }
}

sub _decides {
    my ($self, $file, $line) = @_;
    my $text = $self->_source_text($file, $line);
    $text =~ s{/\*.*?\*/}{ }g;
    $text =~ s{//.*}{};
    return $text =~ /\b(?:if|else|while|for|do|switch)\b|\?|&&|\|\|/ ? 1 : 0;
}

sub _braces_only {
    my ($self, $file, $line) = @_;
    my $src = $self->_clean_source($file)->{lines}[$line - 1];
    return defined $src && $src =~ /\}/ && $src =~ /^[\s{}]*(?:else[\s{}]*)?$/ ? 1 : 0;
}


sub _terms {
    my ($self, $file, $line) = @_;
    my $clean = $self->_clean_source($file);
    my ($from, $to) = ($line, $line);
    for my $r (@{ $clean->{ranges} }) {
        next unless $r->{line} <= $line && $line <= $r->{end};
        ($from, $to) = ($r->{line}, $r->{end});
        last;
    }
    my $text = join ' ', map { $clean->{lines}[$_ - 1] // '' } $from .. $to;
    my $ops = () = $text =~ /&&|\|\|/g;
    return $ops + 1 if $ops || $from < $to || $text =~ /\b(?:if|while|for|switch)\s*\(|\?/;
    return 0;
}

sub _clean_source {
    my ($self, $file) = @_;
    return $self->{clean}{$file} if $self->{clean}{$file};
    my $flow = Devel::XSCover::Flow->new(dir => $self->{dir});
    my @raw  = map { "$_\n" } @{ $self->_source_lines($file) };
    return $self->{clean}{$file} = { lines => [ $flow->clean(\@raw) ], ranges => [ $flow->ranges(\@raw) ] };
}

sub _source_lines {
    my ($self, $file) = @_;
    return $self->{source}{$file} if $self->{source}{$file};
    my $path = File::Spec->catfile($self->{dir}, $file);
    my @l;
    if (open my $fh, '<', $path) {
        @l = <$fh>;
        close $fh;
        chomp @l;
    }
    return $self->{source}{$file} = \@l;
}

sub _source_text {
    my ($self, $file, $line) = @_;
    my $text = $self->_source_lines($file)->[ $line - 1 ] // '';
    $text =~ s/^\s+|\s+$//g;
    $text =~ s/\s+/ /g;
    return $text;
}

sub _say {
    my ($self, $line) = @_;
    print "$line\n" unless $self->{silent};
}

1;

__END__

=head1 NAME

Devel::XSCover::DB - the C coverage written into Devel::Cover's database

=head1 SYNOPSIS

    use Devel::XSCover::DB;
    my $writer = Devel::XSCover::DB->new(dir => '.', db => 'cover_db');
    my ($files, $generated) = $writer->merge(@objects);
    my $entries = $writer->entries($files, $generated, @maps);
    my $run     = $writer->write($entries);

=head1 DESCRIPTION

Turns what the gcov reader and the XS map found into one Devel::Cover run with
three criteria for every C and XS file, statements, branches and subroutines, and
conditions too when the compiler reported them.
C<cover> then reads it beside the Perl runs of the same test run.

=head1 METHODS

=head2 new

    my $writer = Devel::XSCover::DB->new(%options);

Options: C<dir>, C<db> (relative to C<dir> unless absolute), C<macro_branches>
(every gcov block as a branch, see C<entries>), C<dry> and C<silent>.

=head2 merge

    my ($files, $generated) = $writer->merge(@objects);

Merges the objects of the reader into one hash of files and one of generated files.
A file seen from several objects, as a header with inline functions is, becomes one
entry: the union of its lines with the counts summed, its functions summed by name
and line, and the arms of its blocks summed where the same block was seen twice.

=head2 entries

    my $entries = $writer->entries($files, $generated, @maps);

A map that carries an C<inverse> table first moves every record of that XS file from
the line gcov reported to the line meant, since xsubpp drops a comment line from an
XSUB body without a C<#line>.

The criteria per file. Every executable line is a statement, but a line of nothing
but braces (and perhaps C<else>), which clang credits with the code after a C<return>
inside a macro, is not. A branch is a decision
of the source, an C<if>, C<while>, C<for> or C<switch>, with one arm per way out of
it, as L<Devel::XSCover::Flow> read them from the flow graph: a decision of two arms
is one branch with the source line as its text, the arm into the body first, and one
of more arms is one branch per arm, C<arm k of N>, each the arm against the sum of
the others. A file the flow graph did not cover, as with a gcov older than 9, gets
its branches from gcov's blocks instead, one per block with two or more arms in
gcov's order, leaving out a block on a line whose text holds no decision (no C<if>,
C<else>, C<while>, C<for>, C<do>, C<switch>, C<?>, C<&&> or C<||> outside comments),
which is a macro's own, as C<GvSVn> or C<SvTRUE> expand to: nothing in the source
can take its other arm. C<macro_branches> keeps every block of every file that way
instead. Every C function is a subroutine on its first line under its C name. An
XSUB is a subroutine on its declaration line in the XS under each of its Perl
names, with the count of its wrapper from the generated C, and an XSUB whose wrapper the
compiler never saw, under a preprocessor condition the build left out, is not a
subroutine of this build. A decision that gcc 14's
condition coverage reported becomes one condition per term, C<term k of> the
source line, with two counts: whether the term's true outcome and whether its
false outcome each decided the result at least once. gcc counts the terms of the
expression as the preprocessor left it, so a decision with more terms than its source
holds (one more than the C<&&> and C<||> over the lines its parentheses span, one for
a plain C<if> or a C<?>) has a macro's own among them, as C<HvNAME_get> expands to, and
is left out: nothing in the source tells its terms from the macro's. A line with no
decision in its text is a macro's altogether. C<macro_branches> keeps them all.

=head2 write

    my $run = $writer->write($entries);

Writes one run under the database, with the file paths relative to C<dir> as
C<cover> expects them, and returns a hash with the run's path and the counts of
files, statements, branches and subroutines written. A file that is not under
C<dir> is skipped with a warning.

=head1 SEE ALSO

L<Devel::XSCover>, L<Devel::Cover::DB>

=cut
