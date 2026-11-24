use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# The reference's index lists every module, A to Z, and what callers use
# from each, A to Z, a heading each, as DBIx-Squirrel's does. This keeps
# it in step with the code: each module has an entry; each name a module
# exports, and each public method it defines, is listed, but for those
# named internal below; each name listed is one the module can call;
# each has a synopsis, says "Exported by default." or "Exported upon
# request." as it's exported, and ends with a link, a paragraph of its
# own, to a section of the reference before the index, which doesn't
# open with a synopsis; Tooling names each of its tags; and a manual
# lists nothing.
# The test is DBIx-Squirrel's, but for the modules it names and the
# wording of a name exported on request, which Iain chose for Ekorn.
# An author test, as the reference isn't in the distribution.

use B          qw();
use File::Find qw();

my $REFERENCE = 'docs/REFERENCE.md';
skip_all "the reference isn't here" unless -e $REFERENCE;

# Functions and methods of modules that are for Ekorn's own use, as the
# reference says, so not listed: an iterator or a feed is made by its
# pipeline, not by its new; DESTROY ends a run let go; and unimport is
# what no Ekorn::Pipeline::Operators calls.
my %INTERNAL = (
    'Ekorn::Pipeline::Feed'      => [qw(new)],
    'Ekorn::Pipeline::Iterator'  => [qw(new DESTROY)],
    'Ekorn::Pipeline::Operators' => [qw(unimport)],
);

# Classes a module makes, which define methods its entry lists: a sink is
# made a Sink::One or a Sink::Many, each with its role method.
my %CLASSES = ('Ekorn::Pipeline::Sink' =>
    [qw(Ekorn::Pipeline::Sink::One Ekorn::Pipeline::Sink::Many)]);


# Return the key a name sorts by: in any case, with one starting with a
# symbol last.
sub sort_key ($name) {
    my $key = lc $name;
    $key = "\x{ffff}$key" if $key =~ s( \A [^a-z0-9:]+ )()x;
    return $key;
}


# Return a heading's anchor, as GitHub makes it.
sub anchor ($heading) {
    my $anchor = lc $heading;
    $anchor =~ s( [^\w\-\ ] )()xg;
    $anchor =~ s( \  )(-)xg;
    return $anchor;
}


# Return the anchors of the reference's headings before the index, each
# true if its section opens with a block of code, and the index's
# entries, in order: each a module's name, the text saying what it is,
# and its names, in order, each with its text.
sub index_entries () {
    open my $in, '<', $REFERENCE or die "Can't read $REFERENCE: $!";
    my $text = do { local $/; <$in> };
    close $in;
    my($body, $index) = $text =~ m( \A (.*?) ^\#\#\ Index\n (.*) \z )xms
        or die "No index in $REFERENCE";
    my @lines = split m( \n )x, $body;
    my(%anchors, $in_code);
    for my $i (0 .. $#lines) {
        $in_code = !$in_code if $lines[$i] =~ m( \A ``` )x;
        next if $in_code || $lines[$i] !~ m( \A \#+ \  (.+) \z )x;    # a comment in code isn't a heading
        my $anchor = anchor($1);
        next if exists $anchors{$anchor};
        my($next) = grep { $lines[$_] =~ m( \S )x } $i + 1 .. $#lines;
        $anchors{$anchor} = $lines[$next // $i] =~ m( \A ``` )x ? 1 : 0;
    }
    my @entries;
    for my $block (split m( (?= ^\#\#\#\  ) )xm, $index) {
        my($module, $about, $rest)
            = $block =~ m( \A \#\#\#\ (\S+) \n (.*?) (?: ^ (\#\#\#\#\ .*) | \z ) )xms
            or next;
        my @names = map { [m( \A \#\#\#\#\ (\S+) \n (.*) \z )xs] }
            split m( (?= ^\#\#\#\#\  ) )xm, $rest // '';
        push @entries, {module => $module, about => $about, names => \@names};
    }
    return \%anchors, @entries;
}


# Return the module each file under lib is: .pm and .pod alike.
sub modules () {
    my @files;
    File::Find::find(
        sub { push @files, $File::Find::name if m( \. (?: pm | pod ) \z )x },
        'lib',
    );
    return sort map { s( \A lib/ | \. \w+ \z )()xgr =~ s( / )(::)xgr } @files;
}


# Return a module's public names: what it exports, and the subs it
# defines, but for import, those starting with _, and an overload's.
sub public_names ($module) {
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    my %names = map { $_ => 1 } @{ "${module}::EXPORT" },
        @{ "${module}::EXPORT_OK" };
    for my $name (keys %{ "${module}::" }) {
        next if $name eq 'import' || $name !~ m( \A [^\W_] \w* \z )x;
        my $code = *{ "${module}::$name" }{CODE} or next;
        $names{$name} = 1
            if B::svref_2object($code)->GV->STASH->NAME eq $module;
    }
    delete @names{@{ $INTERNAL{$module} // [] }};
    return sort keys %names;
}


my($anchors, @entries) = index_entries();
my @modules = modules();

is [map { $_->{module} } @entries],
    [sort { sort_key($a) cmp sort_key($b) } @modules],
    'each module has an entry, A to Z';

for my $entry (@entries) {
    my $module = $entry->{module};
    my @names  = map { $_->[0] } @{ $entry->{names} };
    is \@names, [sort { sort_key($a) cmp sort_key($b) } @names],
        "$module: its names A to Z";
    is [
        map { $_->[0] }
        grep {
            $_->[1] !~ m( \n\n See \s+ \[ [^\]]+ \] \( \#[^\)]+ \) \. \s* \z )xs
        } @{ $entry->{names} }
        ],
        [],
        "$module: each name ends with a link to where it's in use, a paragraph of its own";

    # Its synopsis, all its forms, as code, is here; its link goes to a
    # section of the reference text that shows it in use, which doesn't
    # open with a synopsis.
    is [
        map  { $_->[0] }
        grep { $_->[1] !~ m( \A \s* ```perl\n .+? ^```$ )xms } @{ $entry->{names} }
        ],
        [], "$module: each name opens with a synopsis";
    my %to = map {
        my($to)
            = $_->[1] =~ m( \s See \s+ \[ [^\]]+ \] \( \# ([^\)]+) \) \. \s* \z )xs;
        ($_->[0] => $to)
    } @{ $entry->{names} };
    is [grep { !defined $to{$_} || !exists $anchors->{$to{$_}} } sort keys %to],
        [], "$module: each name links to a section of the reference";
    is [grep { defined $to{$_} && $anchors->{$to{$_}} } sort keys %to],
        [], "$module: no section it links to opens with a synopsis";
}

for my $entry (@entries) {
    my($module, $about) = @$entry{qw(module about)};
    my %listed = map { $_->[0] => $_->[1] } @{ $entry->{names} };
    if ($module =~ m( ::Manual:: )x) {
        is [sort keys %listed], [], "$module: lists nothing";
        next;
    }
    (my $file = "$module.pm") =~ s( :: )(/)xg;
    require $file;
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)

    # Tooling lists no names, but says what its tags are.
    if ($module eq 'Ekorn::Pipeline::Tooling') {
        is [sort keys %listed], [], "$module: lists no names";
        my @tags = sort keys %{ "${module}::EXPORT_TAGS" };
        is [grep { $about !~ m( `:\Q$_\E` )x } @tags], [], "$module: names each tag";
        next;
    }

    is [grep { !$listed{$_} } public_names($module)], [],
        "$module: lists every public name";
    my @classes = ($module, @{ $CLASSES{$module} // [] });
    is [
        grep {
            my $name = $_;
            !grep { $_->can($name) } @classes
        } sort keys %listed
        ],
        [],
        "$module: lists only names it has";

    # An exported name it lists says how; a name exported by default is
    # so on request too.
    my %default = map { $_ => 1 } grep { $listed{$_} } @{ "${module}::EXPORT" };
    my %request = map { $_ => 1 } grep { $listed{$_} } @{ "${module}::EXPORT_OK" };
    is [
        grep { $listed{$_} !~ m( \s Exported \s+ by \s+ default \. )x }
        sort keys %default
        ],
        [],
        "$module: says which are exported by default";
    my @upon_request = grep { !$default{$_} } sort keys %request;
    is [grep { $listed{$_} !~ m( \s Exported \s+ upon \s+ request \. )x }
            @upon_request], [],
        "$module: says which are exported upon request";
}

done_testing;
