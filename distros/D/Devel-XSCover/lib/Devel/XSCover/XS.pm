package Devel::XSCover::XS;

use 5.020;
use strict;
use warnings;

use File::Find ();
use File::Spec ();

our $VERSION = '0.10';

our ($KEYWORDS);

BEGIN {
    $KEYWORDS = qr/^\s*(?:CODE|PPCODE|PREINIT|INPUT|INIT|ALIAS|OUTPUT|PROTOTYPE|C_ARGS|CLEANUP|POSTCALL|OVERLOAD|FALLBACK|ATTRS|INTERFACE|INTERFACE_MACRO|SCOPE|CASE|NO_INIT|NO_OUTPUT|PROTOTYPES|VERSIONCHECK|EXPORT_XSUB_SYMBOLS|REQUIRE|BOOT|INCLUDE|INCLUDE_COMMAND)\s*:/;
}

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        dir  => '.',
        skip => [qw(blib cover_db .git)],
    }, $class;
    $self->{$_} = $args{$_} for keys %args;
    return $self;
}

sub generated_files {
    my ($self) = @_;
    my %pair;
    my $pl = File::Spec->catfile($self->{dir}, 'Makefile.PL');
    if (open my $fh, '<', $pl) {
        my $text = do { local $/; <$fh> };
        close $fh;
        while ($text =~ /\bXS\s*=>\s*\{(.*?)\}/sg) {
            my $body = $1;
            while ($body =~ /(['"])([^'"]+)\1\s*=>\s*(['"])([^'"]+)\3/g) {
                $pair{ $self->_canon($2) } = $self->_canon($4);
            }
        }
    }
    my %skip = map { $_ => 1 } @{ $self->{skip} };
    my $top  = _slashes($self->{dir});
    File::Find::find({
        no_chdir => 1,
        wanted   => sub {
            if (-d $_) {
                my $base = (File::Spec->splitdir($_))[-1];
                $File::Find::prune = 1 if $skip{$base} && _slashes($_) ne $top;
                return;
            }
            return unless /\.xs\z/;
            my $rel = _slashes(File::Spec->abs2rel($_, $self->{dir}));
            (my $c = $rel) =~ s/\.xs\z/.c/;
            $pair{$rel} = $c unless defined $pair{$rel};
        },
    }, $self->{dir});
    return map { [ $_, $pair{$_} ] }
        grep { -f File::Spec->catfile($self->{dir}, $pair{$_}) } sort keys %pair;
}

sub line_map {
    my ($self, $c) = @_;
    my @map;
    my $own = $self->_canon($c);
    my ($file, $line, $said, $dropped) = ($own, 1, 1, undef);
    my %inverse;
    my $n = 0;
    for my $text ($self->_lines($c)) {
        $n++;
        if ($text =~ /^#line\s+(\d+)\s+"([^"]*)"/) {
            $map[$n] = [ $own, $n ];
            ($file, $line, $said) = ($self->resolve($c, $2), $1, $1);
            $dropped = $file eq $own ? undef : $self->_dropped($file);
            next;
        }
        $line++ while $dropped && $dropped->{$line};
        $inverse{$file}{$said} //= $line if $said != $line;
        $map[$n] = [ $file, $line++ ];
        $said++;
    }
    $self->{inverse}{$own} = \%inverse;
    return \@map;
}

sub _dropped {
    my ($self, $file) = @_;
    return $self->{dropped}{$file} if exists $self->{dropped}{$file};
    my %dropped;
    my $path = File::Spec->file_name_is_absolute($file) ? $file : File::Spec->catfile($self->{dir}, $file);
    if (-f $path) {
        require Devel::XSCover::Flow;
        %dropped = %{ Devel::XSCover::Flow->new->dropped([ $self->_lines($file) ]) };
    }
    return $self->{dropped}{$file} = \%dropped;
}

sub xsubs {
    my ($self, $c) = @_;
    my @lines = $self->_lines($c);
    my $canon = $self->_canon($c);
    my @xsubs;
    for my $i (0 .. $#lines) {
        next unless $lines[$i] =~ /^XS(?:_EUPXS|_EXTERNAL|_INTERNAL)?\((\w+)\)\s*$/;
        my $name = $1;
        next if $name =~ /^boot_/;
        my %xsub = (c_name => $name, c_line => $i + 1);
        for my $j ($i + 1 .. $#lines) {
            last if $lines[$j] =~ /^XS(?:_EUPXS|_EXTERNAL|_INTERNAL)?\(\w+\)\s*$/;
            next unless $lines[$j] =~ /^#line\s+(\d+)\s+"([^"]*)"/;
            my $file = $self->resolve($c, $2);
            next if $file eq $canon;
            @xsub{qw(file body_line)} = ($file, $1);
            last;
        }
        push @xsubs, \%xsub;
    }
    return @xsubs;
}

sub perl_names {
    my ($self, $c) = @_;
    my %names;
    for my $text ($self->_lines($c)) {
        next unless $text =~ /newXS\w*\s*\(\s*"([^"]+)"\s*,\s*(XS_\w+)/;
        push @{ $names{$2} }, $1;
    }
    return \%names;
}

sub declaration_line {
    my ($self, $file, $body_line, $sub) = @_;
    my @lines = $self->_lines($file);
    for (my $i = $body_line - 2; $i >= 0; $i--) {
        my $text = $lines[$i];
        next if $text =~ /^\s*$/;
        next if $text =~ $KEYWORDS;
        next if $text =~ /^\s/;
        next if $text =~ /^[{}]/;
        return undef if $text =~ /^MODULE\s*=/;
        if ($text =~ /^(\w+)\s*\(/) {
            return $i + 1 if !defined $sub || $1 eq $sub;
            return undef;
        }
    }
    return undef;
}

sub find_declaration {
    my ($self, $files, $perl_name) = @_;
    my ($package, $sub) = $perl_name =~ /^(?:(.*)::)?(\w+)$/;
    return unless defined $sub;
    $package //= '';
    for my $file (@$files) {
        my $current = '';
        my $n = 0;
        for my $text ($self->_lines($file)) {
            $n++;
            if ($text =~ /^MODULE\s*=\s*\S+(?:\s+PACKAGE\s*=\s*(\S+))?/) {
                $current = $1 // '';
                next;
            }
            return ($file, $n) if $text =~ /^\Q$sub\E\s*\(/ && ($current eq $package || $current eq '');
        }
    }
    return;
}

sub map {
    my ($self, $c) = @_;
    my $lines = $self->line_map($c);
    my $canon = $self->_canon($c);
    my %files;
    for my $entry (@$lines) {
        next unless $entry;
        $files{ $entry->[0] }++ unless $entry->[0] eq $canon;
    }
    my @files = sort keys %files;
    my $names = $self->perl_names($c);
    my %xsubs;
    for my $xsub ($self->xsubs($c)) {
        my @names = @{ $names->{ $xsub->{c_name} } || [] };
        my $sub   = @names ? ($names[0] =~ /(\w+)$/)[0] : undef;
        my $line;
        if ($xsub->{file}) {
            $line = $self->declaration_line($xsub->{file}, $xsub->{body_line}, $sub);
        }
        if (!defined $line && @names) {
            my ($file, $found) = $self->find_declaration(\@files, $names[0]);
            @{$xsub}{qw(file body_line)} = ($file, undef) if $file;
            $line = $found;
        }
        $xsubs{ $xsub->{c_name} } = {
            %$xsub,
            names => \@names,
            line  => $line,
        };
    }
    return { c => $canon, inverse => $self->{inverse}{$canon} || {}, files => \@files, lines => $lines, xsubs => \%xsubs };
}

sub subroutines {
    my ($self, $map) = @_;
    my @subs;
    for my $c_name (sort keys %{ $map->{xsubs} }) {
        my $x = $map->{xsubs}{$c_name};
        next unless defined $x->{line} && @{ $x->{names} };
        push @subs, { c_name => $c_name, file => $x->{file}, line => $x->{line}, names => $x->{names} };
    }
    return @subs;
}

sub read {
    my ($self) = @_;
    return map { $self->map($_->[1]) } $self->generated_files;
}

sub _lines {
    my ($self, $rel) = @_;
    my $path = File::Spec->file_name_is_absolute($rel) ? $rel : File::Spec->catfile($self->{dir}, $rel);
    open my $fh, '<', $path or die "xs_cover: cannot read $path: $!\n";
    my @lines = <$fh>;
    close $fh;
    chomp @lines;
    return @lines;
}

sub resolve {
    my ($self, $c, $name) = @_;
    my $canon = $self->_canon($name);
    return $canon if File::Spec->file_name_is_absolute($name);
    return $canon if -f File::Spec->catfile($self->{dir}, $canon);
    my ($vol, $dirs) = File::Spec->splitpath($c);
    my $beside = $self->_canon(File::Spec->catpath($vol, $dirs, $name));
    return -f File::Spec->catfile($self->{dir}, $beside) ? $beside : $canon;
}

sub _canon {
    my ($self, $name) = @_;
    $name =~ s{^\./+}{};
    return _slashes(File::Spec->canonpath($name));
}

sub _slashes {
    my ($path) = @_;
    $path =~ s{\\}{/}g if $^O eq 'MSWin32';
    return $path;
}

1;

__END__

=head1 NAME

Devel::XSCover::XS - the map from the generated C back to the XS

=head1 SYNOPSIS

    use Devel::XSCover::XS;
    my $xs  = Devel::XSCover::XS->new(dir => '.');
    my @map = $xs->read;

=head1 DESCRIPTION

xsubpp writes the wrapper of every XSUB into the generated C file, with C<#line>
directives that switch between the F<.xs> and the F<.c>. gcov credits the F<.xs>
for the body and the F<.c> for the wrapper. This map turns the wrapper's name and
count into the XSUB's Perl name and declaration line, and keeps the map from each
generated line to the source line it stands for.

=head1 METHODS

=head2 new

    my $xs = Devel::XSCover::XS->new(dir => '.', skip => [...]);

=head2 generated_files

The pairs of F<.xs> and generated F<.c>, relative to the directory: those the
C<XS> entry of Makefile.PL names, and every F<.c> beside an F<.xs> under the
directory. Only pairs whose F<.c> exists are returned.

=head2 line_map

    my $map = $xs->line_map('Op.c');

An array indexed by generated line, each entry the file and line it stands for.
Lines before the first C<#line> and the directives themselves map to the F<.c>.

xsubpp drops a comment line (one starting with C<#> that is not a preprocessor
directive) from an XSUB's body without a C<#line> to say so, which puts every line
after it one short in the compiler's eyes and in gcov's. The map reads the F<.xs>
and counts those lines, so a C<# uncoverable> line in a body lands where it was
written, and C<map> carries an C<inverse> table, per XS file, from the line gcov
reports to the line meant.

=head2 resolve

    my $file = $xs->resolve('t/consumer/Consumer.c', 'Consumer.xs');

The file a C<#line> directive in a generated F<.c> names, relative to the
distribution directory. xsubpp writes the name it was given, which is relative to
the directory it ran in, so a name that is not under the distribution directory but
is beside the F<.c> takes that directory.

=head2 xsubs

    my @xsubs = $xs->xsubs('Op.c');

Every wrapper definition in the file, with C<c_name>, C<c_line> and, when the
wrapper holds a C<#line> into the XS, C<file> and C<body_line>. The boot function is
left out.

=head2 perl_names

    my $names = $xs->perl_names('Op.c');

From the boot function's C<newXS> calls, the Perl names of each wrapper. An ALIAS
gives a wrapper more than one.

=head2 declaration_line

    my $line = $xs->declaration_line('Op.xs', 1191, 'is_op');

Scans upward from the body's first line past blank lines, keyword lines and
indented parameter lines to the declaration, and returns its line number when it
names the sub.

=head2 find_declaration

    my ($file, $line) = $xs->find_declaration(\@files, 'Spike::More::triple');

Finds the declaration by name in the files, within the matching C<PACKAGE>
section, for a wrapper without a C<#line> of its own.

=head2 map

    my $map = $xs->map('Op.c');

Joins the rest: C<c>, C<files> (the XS files the C was generated from), C<lines>,
C<inverse> (see C<line_map>) and C<xsubs>, each with C<names>, C<file> and C<line>.

=head2 subroutines

    my @subs = $xs->subroutines($map);

The XSUBs with a declaration line and a Perl name, for the subroutine criterion.

=head2 read

A map for every pair of C<generated_files>.

=head1 SEE ALSO

L<Devel::XSCover>

=cut
