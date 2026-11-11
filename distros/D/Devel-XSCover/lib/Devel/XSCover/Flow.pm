package Devel::XSCover::Flow;

use 5.020;
use strict;
use warnings;

use File::Spec ();

our $VERSION = '0.10';

our ($DECISION, $DIRECTIVE);

BEGIN {
    $DECISION  = qr/\b(?:if|while|for|switch)\s*\(/;
    $DIRECTIVE = qr/^\s*#\s*(?:if|ifdef|ifndef|elif|else|endif|define|undef|include|line|pragma|error|warning)\b/;
}

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        dir    => '.',
        silent => 0,
    }, $class;
    $self->{$_} = $args{$_} for keys %args;
    return $self;
}

sub parse_llvm {
    my ($self, $text, $files, $xsubs) = @_;
    my (@functions, $fn, $block);
    for my $line (split /\n/, $text) {
        if ($line =~ /^===== (.*) \((\d+)\) @ (.*):(\d+)\s*$/) {
            $fn = { name => $1, ident => $2, file => $3, line => $4, blocks => {} };
            push @functions, $fn;
            $block = undef;
            next;
        }
        next unless $fn;
        if ($line =~ /^Block : (\d+) Counter : (\d+)/) {
            $block = $fn->{blocks}{$1} = { id => $1, count => $2, succ => [], lines => {} };
            next;
        }
        next unless $block;
        if ($line =~ /^\s*Destination Edges : (.*)/) {
            my $edges = $1;
            push @{ $block->{succ} }, [ $1, $2 ] while $edges =~ /\*?(\d+) \((\d+)\)/g;
            next;
        }
        if ($line =~ /^\s*File: (\d+): (.*)/) {
            push @{ $block->{lines}{$1} }, grep { length } split /,/, $2;
            next;
        }
    }
    my %name = $self->_llvm_files(\@functions, $files, $xsubs);
    my %flow = (complete => 1, files => {});
    for my $f (@functions) {
        for my $b (values %{ $f->{blocks} }) {
            my $key  = "$f->{ident}:$b->{id}";
            my @arcs = map { [ $key, "$f->{ident}:$_->[0]", $_->[1] ] } @{ $b->{succ} };
            for my $index (keys %{ $b->{lines} }) {
                my $file = $name{$index} // next;
                for my $n (@{ $b->{lines}{$index} }) {
                    my $l = $flow{files}{$file}{$n} //= { blocks => {}, arcs => [], count => undef };
                    $l->{blocks}{$key} = 1;
                    push @{ $l->{arcs} }, @arcs;
                }
            }
        }
    }
    return \%flow;
}

sub _llvm_files {
    my ($self, $functions, $files, $xsubs) = @_;
    my (%name, %lines, %own, %score);
    for my $f (@$functions) {
        for my $b (values %{ $f->{blocks} }) {
            for my $index (keys %{ $b->{lines} }) {
                $lines{$index}{$_} = 1 for @{ $b->{lines}{$index} };
                $own{ $f->{ident} }{$index} = 1 if grep { $_ == $f->{line} } @{ $b->{lines}{$index} };
            }
        }
    }
    for my $index (keys %lines) {
        for my $file (keys %{ $files || {} }) {
            my $have = $files->{$file}{lines} || {};
            my $both = grep { $have->{$_} } keys %{ $lines{$index} };
            next unless $both;
            $score{$index}{$file} = $both / (keys(%{ $lines{$index} }) + keys(%$have) - $both);
        }
    }
    for my $f (@$functions) {
        for my $index (sort { $a <=> $b } keys %{ $own{ $f->{ident} } || {} }) {
            next if defined $name{$index};
            if (my $sc = $score{$index}) {
                my $s = $sc->{ $f->{file} } // 0;
                my ($top) = sort { $sc->{$b} <=> $sc->{$a} } keys %$sc;
                next unless $s >= 0.5 || $top eq $f->{file};
            }
            $name{$index} = $f->{file};
        }
    }
    for my $f (@$functions) {
        my $body = $xsubs && $xsubs->{ $f->{name} } or next;
        for my $b (values %{ $f->{blocks} }) {
            for my $index (keys %{ $b->{lines} }) {
                $name{$index} = $body if !defined $name{$index} && !$own{ $f->{ident} }{$index};
            }
        }
    }
    my %taken = map { $_ => 1 } values %name;
    for my $index (sort { $a <=> $b } keys %lines) {
        next if defined $name{$index};
        my ($best, $score) = (undef, 0);
        for my $file (sort keys %{ $score{$index} || {} }) {
            next if $taken{$file};
            my $s = $score{$index}{$file};
            ($best, $score) = ($file, $s) if $s > $score;
        }
        next unless defined $best;
        $name{$index} = $best;
        $taken{$best} = 1;
    }
    return %name;
}

sub parse_gcc {
    my ($self, $json) = @_;
    require JSON::PP;
    my $data = JSON::PP->new->decode($json);
    my %flow = (complete => 0, files => {});
    for my $f (@{ $data->{files} || [] }) {
        my $file = $f->{file};
        for my $l (@{ $f->{lines} || [] }) {
            my $n = $l->{line_number};
            my $entry = $flow{files}{$file}{$n} //= { blocks => {}, arcs => [], count => undef };
            $entry->{count} = $l->{count} if defined $l->{count};
            $entry->{blocks}{$_} = 1 for @{ $l->{block_ids} || [] };
            for my $b (@{ $l->{branches} || [] }) {
                next unless defined $b->{source_block_id} && defined $b->{destination_block_id};
                push @{ $entry->{arcs} }, [ $b->{source_block_id}, $b->{destination_block_id}, $b->{count} || 0 ];
            }
        }
    }
    return \%flow;
}

sub decisions {
    my ($self, $flow, $inverse) = @_;
    my %out;
    for my $file (sort keys %{ $flow->{files} }) {
        my $lines = $flow->{files}{$file};
        my $path  = File::Spec->file_name_is_absolute($file) ? $file : File::Spec->catfile($self->{dir}, $file);
        open my $fh, '<', $path or next;
        my @src = <$fh>;
        close $fh;
        if (my $to = $inverse && $inverse->{$file}) {
            @src = map { $src[ ($to->{$_} // $_) - 1 ] // "\n" } 1 .. @src;
        }
        my @found;
        for my $r ($self->ranges(\@src)) {
            my $arms = $self->_arms($flow, $lines, $r);
            push @found, { line => $r->{line}, arms => $arms } if @$arms >= 2;
        }
        $out{$file} = \@found;
    }
    return \%out;
}

sub _arms {
    my ($self, $flow, $lines, $r) = @_;
    my (%member, @arcs, %seen, %succ);
    for my $n ($r->{line} .. $r->{end}) {
        my $l = $lines->{$n} or next;
        $member{$_} = 1 for keys %{ $l->{blocks} };
        for my $a (@{ $l->{arcs} }) {
            push @arcs, $a unless $seen{"$a->[0] $a->[1]"}++;
        }
    }
    return [] unless %member;
    push @{ $succ{ $_->[0] } }, $_->[1] for @arcs;
    my (%tally, %at);
    my ($body, $has_body) = (0, 0);
    for my $a (@arcs) {
        my ($s, $d, $c) = @$a;
        my $plain = @{ $succ{$s} } <= 1;
        if ($member{$d}) {
            next unless $flow->{complete} && !$plain;
            my %seen;
            while ($member{$d} && @{ $succ{$d} || [] } <= 1 && !$seen{$d}++) {
                last unless @{ $succ{$d} || [] };
                $d = $succ{$d}[0];
            }
            next if $member{$d} && @{ $succ{$d} || [] } > 1;
            if ($r->{body}) {
                $body += $c;
                $has_body = 1;
                next;
            }
        }
        elsif ($flow->{complete} && $plain) {
            next;
        }
        $tally{$d} += $c;
        ($at{$d}) = $d =~ /(\d+)\z/;
    }
    my @arms = map { $tally{$_} } sort { $at{$a} <=> $at{$b} } sort keys %tally;
    if ($r->{body} && !$flow->{complete}) {
        my $count = $lines->{ $r->{line} }{count};
        my $seen  = 0;
        $seen += $_ for @arms;
        unshift @arms, defined $count && $count > $seen ? $count - $seen : 0;
    }
    elsif ($has_body) {
        unshift @arms, $body;
    }
    return \@arms;
}

sub dropped {
    my ($self, $src) = @_;
    my (%dropped, $in_body);
    my $n = 0;
    for my $text (@$src) {
        $n++;
        $in_body = 1 if !$in_body && $text =~ /^MODULE\s*=/;
        next unless $in_body && $text =~ /^\s*#/;
        next if $text =~ $DIRECTIVE;
        $dropped{$n} = 1;
    }
    return \%dropped;
}

sub ranges {
    my ($self, $src) = @_;
    my @clean = $self->clean($src);
    my @ranges;
    for my $i (0 .. $#clean) {
        my $t = $clean[$i];
        next unless $t =~ $DECISION;
        my $pos = $+[0] - 1;
        my ($depth, $j, $rest) = (0, $i, undef);
        LINE: while ($j <= $#clean) {
            my $s = $clean[$j];
            for (my $k = $j == $i ? $pos : 0; $k < length $s; $k++) {
                my $c = substr $s, $k, 1;
                if ($c eq '(') {
                    $depth++;
                }
                elsif ($c eq ')' && !--$depth) {
                    $rest = substr $s, $k + 1;
                    last LINE;
                }
            }
            $j++;
        }
        next unless defined $rest;
        $rest =~ s/^\s+|\s+$//g;
        push @ranges, { line => $i + 1, end => $j + 1, body => length $rest && $rest ne '{' && $rest ne ';' ? 1 : 0 };
    }
    return @ranges;
}

sub clean {
    my ($self, $src) = @_;
    my ($comment, $directive) = (0, 0);
    my @out;
    for my $line (@$src) {
        my $s = $line;
        chomp $s;
        my $o = '';
        if ($directive) {
            $directive = $s =~ /\\\z/ ? 1 : 0;
            push @out, '';
            next;
        }
        if (!$comment && $s =~ /^\s*#/) {
            $directive = $s =~ /\\\z/ ? 1 : 0;
            push @out, '';
            next;
        }
        my $i = 0;
        while ($i < length $s) {
            if ($comment) {
                my $end = index $s, '*/', $i;
                if ($end < 0) {
                    $i = length $s;
                }
                else {
                    $i = $end + 2;
                    $comment = 0;
                }
                next;
            }
            my $c = substr $s, $i, 1;
            if ($c eq '/' && substr($s, $i + 1, 1) eq '*') {
                $comment = 1;
                $i += 2;
                $o .= ' ';
                next;
            }
            if ($c eq '/' && substr($s, $i + 1, 1) eq '/') {
                last;
            }
            if ($c eq '"' || $c eq "'") {
                my $j = $i + 1;
                while ($j < length $s) {
                    my $d = substr $s, $j, 1;
                    $j++ if $d eq '\\';
                    $j++;
                    last if $d eq $c;
                }
                $o .= $c . $c;
                $i = $j;
                next;
            }
            $o .= $c;
            $i++;
        }
        push @out, $o;
    }
    return @out;
}

1;

__END__

=head1 NAME

Devel::XSCover::Flow - the decisions of the C source, from gcov's flow graph

=head1 SYNOPSIS

    use Devel::XSCover::Flow;
    my $flow      = Devel::XSCover::Flow->new(dir => '.');
    my $graph     = $flow->parse_llvm($dump, $files);
    my $decisions = $flow->decisions($graph);

=head1 DESCRIPTION

gcov's text names the blocks on a line and the count of each arm leaving them,
but not where an arm goes, and on a line such as C<if (!stash || !HvNAME_get(stash))>
most of the blocks are the macro's own: its inner tests jump within the line and
nothing in the source can take their other arm. The flow graph the compiler wrote
beside the counters says where every arc goes. A decision in the source is then
read from it the way Devel::Cover reads a Perl one: the arcs that leave the lines
of the C<if> are its outcomes, the arcs that stay on them are not.

=head1 METHODS

=head2 new

    my $flow = Devel::XSCover::Flow->new(dir => '.');

C<dir> is where the source files are read from for the decisions.

=head2 parse_llvm

    my $graph = $flow->parse_llvm($text, $files, $xsubs);

Reads what C<llvm-cov gcov --dump> prints: every function with its blocks, each
block's count, its arcs with their counts, and its lines by file. The dump names a
file by an index, so a function's own file, given in its header, names the index its
first line is under. C<$xsubs>, the XS map's table of C wrapper name to the F<.xs> file
holding its body, names the other index of each XSUB wrapper, and an index still
unnamed is matched to the file of the gcov text (C<$files>, as
L<Devel::XSCover::Gcov> parsed it) whose executable lines it shares most of. With
many XS files of similar shape the table is what tells them apart.

=head2 parse_gcc

    my $graph = $flow->parse_gcc($json);

Reads what C<gcov --json-format> writes on gcc 9 and later: for every line of every
file, the blocks on it and the arcs leaving its conditional blocks, with their
destinations and counts. The arcs of a block with one successor are not in it, so
the graph is marked incomplete.

Both return the same structure: C<complete>, and under C<files>, for every line of
every file, C<blocks> (the blocks on the line), C<arcs> (C<[from, to, count]> for
the arcs leaving them) and C<count> (the line's count, from the JSON only).

=head2 decisions

    my $decisions = $flow->decisions($graph);

For every file in the graph, the decisions of its source: each C<if>, C<while>,
C<for> and C<switch>, with the arcs that leave the lines its parentheses span, one
arm per destination in the order the compiler laid the destinations out, which puts
the arm into the body first. A statement on the same line as the closing parenthesis
is a body of its own: with a complete graph its arm is the arcs into it, and with
gcc's the line's count less the arms that are seen. A block on the decision's lines
with one way out, as clang places the C<if> statement's merge block and a macro's
arms, stands for where its chain of such blocks ends: the arcs into it count towards
that destination, its own arc not again. Returns a hash of file to a list
of C<{ line, arms }>, decisions with fewer than two arms left out.
C<$inverse>, when given, is the XS map's table per file from the line gcov reports to
the line written (xsubpp drops a C<#> comment line from an XSUB body without a
C<#line>, so the two differ by the comment lines above, within the body): the
source of such a file is read in the lines gcov reports, so that its decisions sit
where the graph has them, and the XS map moves them to the lines written afterwards.

=head2 dropped

    my $dropped = $flow->dropped(\@lines);

The lines of an XS file that xsubpp drops from its output without a C<#line> to say
so: from the first C<MODULE => line on, every line starting with C<#> that is not a
preprocessor directive, such as a C<# uncoverable> mark. Returns a hash of line
number to 1.

=head2 ranges

    my @ranges = $flow->ranges(\@source_lines);

The decisions of a source, each with its first C<line>, the line its parentheses
C<end> on, and whether a C<body> follows on that line.

=head2 clean

    my @lines = $flow->clean(\@source_lines);

The source with comments, string and character literals and preprocessor lines
blanked, so that an C<if> inside any of them is not a decision.

=head1 SEE ALSO

L<Devel::XSCover::Gcov>, L<Devel::XSCover::DB>

=cut
