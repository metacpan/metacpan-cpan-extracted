package Devel::XSCover::DB;

use 5.020;
use strict;
use warnings;

use Cwd ();
use File::Path ();
use File::Spec ();

our $VERSION = '0.02';

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
    for my $file (sort keys %$files) {
        my $f = $files->{$file};
        my $e = $out{$file} = { statement => [], branch => [], subroutine => [], condition => [] };
        for my $line (sort { $a <=> $b } keys %{ $f->{lines} }) {
            push @{ $e->{statement} }, [ $line, $f->{lines}{$line} ];
        }
        for my $b (sort { $a->{line} <=> $b->{line} } @{ $f->{blocks} }) {
            my @arms = @{ $b->{arms} };
            next if @arms < 2;
            next if $self->{macro_branches} ? 0 : !$self->_decides($file, $b->{line});
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
            my $text = $self->_source_text($file, $d->{line});
            for my $k (0 .. $#{ $d->{terms} }) {
                my $term = $d->{terms}[$k];
                push @{ $e->{condition} }, [ $d->{line}, { type => 'and_2', left => 'term ' . ($k + 1), op => 'of', right => $text }, [ $term->{true} ? 1 : 0, $term->{false} ? 1 : 0 ] ];
            }
        }
        for my $fn (sort { $a->{line} <=> $b->{line} || $a->{name} cmp $b->{name} } @{ $f->{functions} }) {
            push @{ $e->{subroutine} }, [ $fn->{line}, $fn->{name}, $fn->{count} ];
        }
    }
    for my $map (@maps) {
        my %count = map { $_->{name} => $_->{count} } @{ $generated->{ $map->{c} }{functions} || [] };
        for my $c_name (sort keys %{ $map->{xsubs} }) {
            my $x = $map->{xsubs}{$c_name};
            next unless defined $x->{line} && @{ $x->{names} };
            my $e = $out{ $x->{file} } //= { statement => [], branch => [], subroutine => [], condition => [] };
            for my $name (@{ $x->{names} }) {
                push @{ $e->{subroutine} }, [ $x->{line}, $name, $count{$c_name} // 0 ];
            }
        }
    }
    for my $e (values %out) {
        @{ $e->{subroutine} } = sort { $a->[0] <=> $b->[0] || $a->[1] cmp $b->[1] } @{ $e->{subroutine} };
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

sub _decides {
    my ($self, $file, $line) = @_;
    my $text = $self->_source_text($file, $line);
    $text =~ s{/\*.*?\*/}{ }g;
    $text =~ s{//.*}{};
    return $text =~ /\b(?:if|else|while|for|do|switch)\b|\?|&&|\|\|/ ? 1 : 0;
}

sub _source_text {
    my ($self, $file, $line) = @_;
    my $lines = $self->{source}{$file} //= do {
        my $path = File::Spec->catfile($self->{dir}, $file);
        my @l;
        if (open my $fh, '<', $path) {
            @l = <$fh>;
            close $fh;
            chomp @l;
        }
        \@l;
    };
    my $text = $lines->[ $line - 1 ] // '';
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

Options: C<dir>, C<db> (relative to C<dir> unless absolute), C<macro_branches> (keep
the branches of macros, see C<entries>), C<dry> and C<silent>.

=head2 merge

    my ($files, $generated) = $writer->merge(@objects);

Merges the objects of the reader into one hash of files and one of generated files.
A file seen from several objects, as a header with inline functions is, becomes one
entry: the union of its lines with the counts summed, its functions summed by name
and line, and the arms of its blocks summed where the same block was seen twice.

=head2 entries

    my $entries = $writer->entries($files, $generated, @maps);

The criteria per file. Every executable line is a statement. A block of two arms is
one branch with the source line as its text, the arms in gcov's order. A block of
more arms is one branch per arm, C<arm k of N>, each the arm against the sum of
the others. A block on a line whose text holds no decision (no C<if>, C<else>,
C<while>, C<for>, C<do>, C<switch>, C<?>, C<&&> or C<||> outside comments) is a
macro's own, as C<GvSVn> or C<SvTRUE> expand to, and is left out unless
C<macro_branches> is set: nothing in the source can take its other arm. Every C function is a subroutine on its first line under its C name. An
XSUB is a subroutine on its declaration line in the XS under each of its Perl
names, with the count of its wrapper from the generated C. A decision that gcc 14's
condition coverage reported becomes one condition per term, C<term k of> the
source line, with two counts: whether the term's true outcome and whether its
false outcome each decided the result at least once.

=head2 write

    my $run = $writer->write($entries);

Writes one run under the database, with the file paths relative to C<dir> as
C<cover> expects them, and returns a hash with the run's path and the counts of
files, statements, branches and subroutines written. A file that is not under
C<dir> is skipped with a warning.

=head1 SEE ALSO

L<Devel::XSCover>, L<Devel::Cover::DB>

=cut
