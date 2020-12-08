package Make;

use strict;
use warnings;

our $VERSION = '2.010';

use Carp qw(confess croak);
use Config;
use Cwd;
use File::Spec;
use Make::Target ();
use Make::Rule   ();
use File::Temp;
use Text::Balanced qw(extract_bracketed);
use Text::ParseWords qw(parse_line);
use File::Spec::Functions qw(file_name_is_absolute);
## no critic (ValuesAndExpressions::ProhibitConstantPragma)
use constant DEBUG => $ENV{MAKE_DEBUG};
## use critic
require Make::Functions;

my $DEFAULTS_AST;
my %date;
my %fs_function_map = (
    glob          => sub { glob $_[0] },
    fh_open       => sub { open my $fh, $_[0], $_[1] or confess "open @_: $!"; $fh },
    fh_write      => sub { my $fh = shift;                                     print {$fh} @_ },
    file_readable => sub { -r $_[0] },
    mtime         => sub { ( stat $_[0] )[9] },
    is_abs        => sub { goto &file_name_is_absolute },
);
my @RECMAKE_FINDS = ( \&_find_recmake_cd, );

sub _find_recmake_cd {
    my ($cmd) = @_;
    return unless $cmd =~ /\bcd\s+([^\s;&]+)\s*(?:;|&&)\s*make\s*(.*)/;
    my ( $dir, $makeargs ) = ( $1, $2 );
    require Getopt::Long;
    local @ARGV = Text::ParseWords::shellwords($makeargs);
    Getopt::Long::GetOptions( "f=s" => \my $makefile );
    my ( $vars, $targets ) = parse_args(@ARGV);
    return ( $dir, $makefile, $vars, $targets );
}

## no critic (Subroutines::RequireArgUnpacking Subroutines::RequireFinalReturn)
sub load_modules {
    for (@_) {
        my $pkg = $_;    # to not mutate inputs
        $pkg =~ s#::#/#g;
        ## no critic (Modules::RequireBarewordIncludes)
        eval { require "$pkg.pm"; 1 } or die;
        ## use critic
    }
}

sub phony {
    my ( $self, $name ) = @_;
    return exists $self->{PHONY}{$name};
}

sub suffixes {
    my ($self) = @_;
    ## no critic (Subroutines::ProhibitReturnSort)
    return sort keys %{ $self->{'SUFFIXES'} };
    ## use critic
}

sub target {
    my ( $self, $target ) = @_;
    unless ( exists $self->{Depend}{$target} ) {
        my $t = $self->{Depend}{$target} = Make::Target->new( $target, $self );
        if ( $target =~ /%/ ) {
            $self->{Pattern}{$target} = $t;
        }
        elsif ( $target =~ /^\./ ) {
            $self->{Dot}{$target} = $t;
        }
    }
    return $self->{Depend}{$target};
}

sub has_target {
    my ( $self, $target ) = @_;
    confess "Trying to has_target undef value" unless defined $target;
    return exists $self->{Depend}{$target};
}

sub targets {
    my ($self) = @_;
    ## no critic ( BuiltinFunctions::RequireBlockGrep )
    return grep !/%|^\./, keys %{ $self->{Depend} };
    ## use critic
}

# Utility routine for patching %.o type 'patterns'
my %pattern_cache;

sub patmatch {
    my ( $pat, $target ) = @_;
    return $target if $pat eq '%';
    ## no critic (BuiltinFunctions::RequireBlockMap)
    $pattern_cache{$pat} = join '(.*)', map quotemeta, split /%/, $pat
        if !exists $pattern_cache{$pat};
    ## use critic
    $pat = $pattern_cache{$pat};
    if ( $target =~ /^$pat$/ ) {
        return $1;
    }
    return;
}

sub in_dir {
    my ( $fsmap, $dir, $file ) = @_;
    return $file if defined $file and $fsmap->{is_abs}->($file);
    my @dir  = defined($dir) ? split /\//, $dir : ();
    my @file = split /\//, $file;
    while ( @dir and @file and $file[0] eq '..' ) {

        # normalise out ../ in $file - no account taken of symlinks
        shift @file;
        pop @dir;
    }
    join '/', @dir, @file;
}

sub locate {
    my ( $self, $file ) = @_;
    my $fsmap    = $self->fsmap;
    my $readable = $fsmap->{file_readable};
    foreach my $key ( sort keys %{ $self->{Vpath} } ) {
        next unless defined( my $Pat = patmatch( $key, $file ) );
        foreach my $dir ( @{ $self->{Vpath}{$key} } ) {
            ( my $maybe_file = $dir ) =~ s/%/$Pat/g;
            return $maybe_file if $readable->( in_dir $fsmap, $self->{InDir}, $maybe_file );
        }
    }
    return;
}

# Convert traditional .c.o rules into GNU-like into %.o : %.c
sub dotrules {
    my ($self) = @_;
    my @suffix = $self->suffixes;
    my $Dot    = delete $self->{Dot};
    foreach my $f (@suffix) {
        foreach my $t ( '', @suffix ) {
            delete $self->{Depend}{ $f . $t };
            next unless my $r = delete $Dot->{ $f . $t };
            DEBUG and print STDERR "Pattern %$t : %$f\n";
            my $target   = $self->target( '%' . $t );
            my $thisrule = $r->rules->[-1];             # last-specified
            die "Failed on pattern rule for '$f$t', no prereqs allowed"
                if @{ $thisrule->prereqs };
            my $rule = Make::Rule->new( '::', [ '%' . $f ], $thisrule->recipe, $thisrule->recipe_raw );
            $self->target( '%' . $t )->add_rule($rule);
        }
    }
    return;
}

#
# Return modified date of name if it exists
#
sub date {
    my ( $self, $name ) = @_;
    my $fsmap = $self->fsmap;
    unless ( exists $date{$name} ) {
        $date{$name} = $self->fsmap->{mtime}->( in_dir $fsmap, $self->{InDir}, $name );
    }
    return $date{$name};
}

#
# See if we can find a %.o : %.c rule for target
# .c.o rules are already converted to this form
#
sub patrule {
    my ( $self, $target, $kind ) = @_;
    DEBUG and print STDERR "Trying pattern for $target\n";
    foreach my $key ( sort keys %{ $self->{Pattern} } ) {
        DEBUG and print STDERR " Pattern $key trying\n";
        next unless defined( my $Pat = patmatch( $key, $target ) );
        DEBUG and print STDERR " Pattern $key matched ($Pat)\n";
        my $t = $self->{Pattern}{$key};
        foreach my $rule ( @{ $t->rules } ) {
            my @dep = @{ $rule->prereqs };
            DEBUG and print STDERR "  Try rule : @dep\n";
            next unless @dep;
            my @failed;
            for my $this_dep (@dep) {
                $this_dep =~ s/%/$Pat/g;
                next if $self->date($this_dep) or $self->has_target($this_dep);
                my $maybe = $self->locate($this_dep);
                if ( defined $maybe ) {
                    $this_dep = $maybe;
                    next;
                }
                push @failed, $this_dep;
            }
            DEBUG and print STDERR "  " . ( @failed ? "Failed: (@failed)" : "Matched (@dep)" ) . "\n";
            next if @failed;
            return Make::Rule->new( $kind, \@dep, $rule->recipe, $rule->recipe_raw );
        }
    }
    return;
}

sub evaluate_macro {
    my ( $key, @args ) = @_;
    my ( $function_packages, $vars_search_list, $fsmap ) = @args;
    my $value;
    return '' if !length $key;
    if ( $key =~ /^([\w._]+|\S)(?::(.*))?$/ ) {
        my ( $var, $subst ) = ( $1, $2 );
        foreach my $hash (@$vars_search_list) {
            last if defined( $value = $hash->{$var} );
        }
        $value = '' if !defined $value;
        if ( defined $subst ) {
            my @parts = split /=/, $subst, 2;
            die "Syntax error: expected form x=y in '$subst'" if @parts != 2;
            $value = join ' ', Make::Functions::patsubst( $fsmap, @parts, $value );
        }
    }
    elsif ( $key =~ /([\w._]+)\s+(.*)$/ ) {
        my ( $func, $args ) = ( $1, $2 );
        my $code;
        foreach my $package (@$function_packages) {
            last if $code = $package->can($func);
        }
        die "'$func' not found in (@$function_packages)" if !defined $code;
        ## no critic (BuiltinFunctions::RequireBlockMap)
        $value = join ' ', $code->( $fsmap, map subsvars( $_, @args ), split /\s*,\s*/, $args );
        ## use critic
    }
    elsif ( $key =~ /^\S*\$/ ) {

        # something clever, expand it
        $key = subsvars( $key, @args );
        return evaluate_macro( $key, @args );
    }
    return subsvars( $value, @args );
}

sub subsvars {
    my ( $remaining, $function_packages, $vars_search_list, $fsmap ) = @_;
    confess "Trying to expand undef value" unless defined $remaining;
    my $ret = '';
    my $found;
    while (1) {
        last unless $remaining =~ s/(.*?)\$//;
        $ret .= $1;
        my $char = substr $remaining, 0, 1;
        if ( $char eq '$' ) {
            $ret .= $char;    # literal $
            substr $remaining, 0, 1, '';
            next;
        }
        elsif ( $char =~ /[\{\(]/ ) {
            ( $found, my $tail ) = extract_bracketed $remaining, '{}()', '';
            die "Syntax error in '$remaining'" if !defined $found;
            $found     = substr $found, 1, -1;
            $remaining = $tail;
        }
        else {
            $found = substr $remaining, 0, 1, '';
        }
        my $value = evaluate_macro( $found, $function_packages, $vars_search_list, $fsmap );
        if ( !defined $value ) {
            warn "Cannot evaluate '$found'\n";
            $value = '';
        }
        $ret .= $value;
    }
    return $ret . $remaining;
}

# Perhaps should also understand "..." and '...' ?
# like GNU make will need to understand \ to quote spaces, for deps
# also C:\xyz as a non-target (overlap with parse_makefile)
sub tokenize {
    my ( $string, @extrasep ) = @_;
    ## no critic ( BuiltinFunctions::RequireBlockGrep BuiltinFunctions::RequireBlockMap)
    my $pat  = join '|', '\s+', map quotemeta, @extrasep;
    my @toks = grep defined && length, parse_line $pat, 1, $string;
    ## use critic
    s/\\(\s)/$1/g for @toks;
    return \@toks;
}

sub get_full_line {
    my ($fh) = @_;
    my $final = my $line = <$fh>;
    return if !defined $line;
    my $raw = $line;
    $raw   =~ s/^\t//;
    $final =~ s/\r?\n\z//;
    while ( $final =~ /\\$/ ) {
        $final =~ s/\s*\\\z//;
        $line = <$fh>;
        last if !defined $line;
        my $raw_line = $line;
        $raw_line =~ s/^\t//;
        $raw .= $raw_line;
        $line =~ s/\s*\z//;
        $line =~ s/^\s*/ /;
        $final .= $line;
    }
    $raw =~ s/\r?\n\z//;
    return ( $final, $raw );
}

sub set_var {
    my ( $self, $name, $value ) = @_;
    $self->{Vars}{$name} = $value;
}

sub vars {
    my ($self) = @_;
    $self->{Vars};
}

sub function_packages {
    my ($self) = @_;
    $self->{FunctionPackages};
}

sub fsmap {
    my ($self) = @_;
    $self->{FSFunctionMap};
}

sub expand {
    my ( $self, $text ) = @_;
    return subsvars( $text, $self->function_packages, [ $self->vars, \%ENV ], $self->fsmap );
}

sub process_ast_bit {
    my ( $self, $type, @args ) = @_;
    return if $type eq 'comment';
    if ( $type eq 'include' ) {
        my $opt = $args[0];
        my ($tokens) = tokenize( $self->expand( $args[1] ) );
        foreach my $file (@$tokens) {
            eval {
                my $fsmap = $self->fsmap;
                $file = in_dir $fsmap, $self->{InDir}, $file;
                my $mf  = $fsmap->{fh_open}->( '<', $file );
                my $ast = parse_makefile($mf);
                close($mf);
                $self->process_ast_bit(@$_) for @$ast;
                1;
            } or warn $@ if $opt ne '-';
        }
    }
    elsif ( $type eq 'var' ) {
        $self->set_var( $args[0], defined $args[1] ? $args[1] : "" );
    }
    elsif ( $type eq 'vpath' ) {
        my ( $pattern, @vpath ) = @args;
        $self->{Vpath}{$pattern} = \@vpath;
    }
    elsif ( $type eq 'rule' ) {
        my ( $targets, $kind, $prereqs, $cmnds, $cmnds_raw ) = @args;
        ($prereqs) = tokenize( $self->expand($prereqs) );
        ($targets) = tokenize( $self->expand($targets) );
        $self->{Vars}{'.DEFAULT_GOAL'} ||= $targets->[0]
            if $targets->[0] !~ /%|^\./;
        unless ( @$targets == 1 and $targets->[0] =~ /^\.[A-Z]/ ) {
            $self->target($_) for @$prereqs;    # so "exist or can be made"
        }
        my $rule = Make::Rule->new( $kind, $prereqs, $cmnds, $cmnds_raw );
        $self->target($_)->add_rule($rule) for @$targets;
    }
    return;
}

#
# read makefile (or fragment of one) either as a result
# of a command line, or an 'include' in another makefile.
#
sub parse_makefile {
    my ($fh) = @_;
    my @ast;
    my $raw;
    ( local $_, $raw ) = get_full_line($fh);
    while (1) {
        last unless ( defined $_ );
        s/^\s+//;
        next if !length;
        if (/^(-?)include\s+(.*)$/) {
            push @ast, [ 'include', $1, $2 ];
        }
        elsif (s/^#+\s*//) {
            push @ast, [ 'comment', $_ ];
        }
        elsif (/^\s*([\w._]+)\s*:?=\s*(.*)$/) {
            push @ast, [ 'var', $1, $2 ];
        }
        elsif (/^vpath\s+(\S+)\s+([^#]*)/) {
            my ( $pattern, $path ) = ( $1, $2 );
            my @path = @{ tokenize $path, $Config{path_sep} };
            push @ast, [ 'vpath', $pattern, @path ];
        }
        elsif (
            /^
                \s*
                ([^:\#]*?)
                \s*
                (::?)
                \s*
                ((?:[^;\#]*\#.*|.*?))
                (?:\s*;\s*(.*))?
            $/sx
            )
        {
            my ( $target, $kind, $prereqs, $maybe_cmd ) = ( $1, $2, $3, $4 );
            my @cmnds     = defined $maybe_cmd ? ($maybe_cmd) : ();
            my @cmnds_raw = @cmnds;
            $prereqs =~ s/\s*#.*//;
            while ( ( $_, $raw ) = get_full_line($fh) ) {
                next if /^\s*#/;
                next if /^\s*$/;
                last unless /^\t/;
                next if /^\s*$/;
                s/^\s+//;
                push @cmnds,     $_;
                push @cmnds_raw, $raw;
            }
            push @ast, [ 'rule', $target, $kind, $prereqs, \@cmnds, \@cmnds_raw ];
            redo;
        }
        else {
            warn "Ignore '$_'\n";
        }
    }
    continue {
        ( $_, $raw ) = get_full_line($fh);
    }
    return \@ast;
}

sub pseudos {
    my $self = shift;
    foreach my $key (qw(SUFFIXES PHONY PRECIOUS PARALLEL)) {
        delete $self->{Depend}{ '.' . $key };
        my $t = delete $self->{Dot}{ '.' . $key };
        if ( defined $t ) {
            $self->{$key} = {};
            ## no critic (BuiltinFunctions::RequireBlockMap)
            foreach my $dep ( map @{ $_->prereqs }, @{ $t->rules } ) {
                ## use critic
                $self->{$key}{$dep} = 1;
            }
        }
    }
    return;
}

sub find_makefile {
    my ( $self, $file, $dir ) = @_;
    ## no critic ( BuiltinFunctions::RequireBlockGrep )
    my @dirs = grep defined, $self->{InDir}, $dir;
    $dir = join '/', @dirs if @dirs;
    ## use critic
    my $fsmap = $self->fsmap;
    return in_dir $fsmap, $dir, $file if defined $file;
    my @search = qw(makefile Makefile);
    unshift @search, 'GNUmakefile' if $self->{GNU};
    ## no critic (BuiltinFunctions::RequireBlockMap)
    @search = map in_dir( $fsmap, $dir, $_ ), @search;
    ## use critic
    for (@search) {
        return $_ if $fsmap->{file_readable}->($_);
    }
    return;
}

sub parse {
    my ( $self, $file ) = @_;
    my $fh;
    if ( ref $file eq 'SCALAR' ) {
        open my $tfh, "+<", $file;
        $fh = $tfh;
    }
    else {
        $file = $self->find_makefile($file);
        $fh   = $self->fsmap->{fh_open}->( '<', $file );
    }
    my $ast = parse_makefile($fh);
    $self->process_ast_bit(@$_) for @$ast;
    undef $fh;

    # Next bits should really be done 'lazy' on need.

    $self->pseudos;     # Pull out .SUFFIXES etc.
    $self->dotrules;    # Convert .c.o into %.o : %.c
    return $self;
}

sub PrintVars {
    my $self = shift;
    local $_;
    my $vars = $self->vars;
    foreach ( sort keys %$vars ) {
        print "$_ = ", $vars->{$_}, "\n";
    }
    print "\n";
    return;
}

sub parse_cmdline {
    my ($line) = @_;
    $line =~ s/^([\@\s-]*)//;
    my $prefix = $1;
    my %parsed = ( line => $line );
    $parsed{silent}   = 1 if $prefix =~ /\@/;
    $parsed{can_fail} = 1 if $prefix =~ /-/;
    return \%parsed;
}

## no critic (BuiltinFunctions::RequireBlockMap)
my %NAME_QUOTING     = map +( $_ => sprintf "%%%02x", ord $_ ), qw(% :);
my $NAME_QUOTE_CHARS = join '', '[', ( map quotemeta, sort keys %NAME_QUOTING ), ']';

sub name_encode {
    join ':', map {
        my $s = $_;
        $s =~ s/($NAME_QUOTE_CHARS)/$NAME_QUOTING{$1}/gs;
        $s
    } @{ $_[0] };
}

sub name_decode {
    my ($s) = @_;
    [
        map {
            my $s = $_;
            $s =~ s/%(..)/chr hex $1/ges;
            $s
        } split ':',
        $_[0]
    ];
}
## use critic

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub exec {
    my ( $self, $line ) = @_;
    undef %date;
    my $parsed = parse_cmdline($line);
    print "$parsed->{line}\n" unless $parsed->{silent};
    my $code = system $parsed->{line};
    if ( $code && !$parsed->{can_fail} ) {
        $code >>= 8;
        die "Code $code from $parsed->{line}";
    }
    return;
}
## use critic

## no critic (Subroutines::RequireFinalReturn)
sub NextPass { shift->{Pass}++ }
sub pass     { shift->{Pass} }
## use critic

## no critic (RequireArgUnpacking)
sub parse_args {
    my ( @vars, @targets );
    foreach (@_) {
        if (/^(\w+)=(.*)$/) {
            push @vars, [ $1, $2 ];
        }
        else {
            push @targets, $_;
        }
    }
    return \@vars, \@targets;
}
## use critic

sub _rmf_search_rule {
    my ( $rule, $target_obj, $target, $rule_no, $rmfs ) = @_;
    my @found;
    my $line = -1;
    for my $cmd ( $rule->exp_recipe($target_obj) ) {
        $line++;
        my @rec_vars;
        for my $rf (@$rmfs) {
            last if @rec_vars = $rf->($cmd);
        }
        next unless @rec_vars;
        push @found, [ $target, $rule_no, $line, @rec_vars ];
    }
    return @found;
}

sub find_recursive_makes {
    my ($self) = @_;
    my @found;
    my $rmfs = $self->{RecursiveMakeFinders};
    for my $target ( sort $self->targets ) {
        my $target_obj = $self->target($target);
        my $rule_no    = 0;
        ## no critic (BuiltinFunctions::RequireBlockMap)
        push @found, map _rmf_search_rule( $_, $target_obj, $target, $rule_no++, $rmfs ), @{ $target_obj->rules };
        ## use critic
    }
    return @found;
}

sub as_graph {
    my ( $self,     %options )        = @_;
    my ( $no_rules, $recursive_make ) = @options{qw(no_rules recursive_make)};
    require Graph;
    my $g = Graph->new( $no_rules ? ( multiedged => 1 ) : () );
    my ( %recipe_cache, %seen );
    my $rmfs      = $self->{RecursiveMakeFinders};
    my $fsmap     = $self->fsmap;
    my $fr        = $fsmap->{file_readable};
    my %make_args = (
        FunctionPackages => $self->function_packages,
        FSFunctionMap    => $fsmap,
    );
    my $InDir = $self->{InDir};

    for my $target ( sort $self->targets ) {
        my $node_name = $no_rules ? $target : name_encode( [ 'target', $target ] );
        $g->add_vertex($node_name);
        my $rule_no    = -1;
        my $target_obj = $self->target($target);
        for my $rule ( @{ $target_obj->rules } ) {
            $rule_no++;
            my $recipe      = $rule->recipe;
            my $recipe_hash = { recipe => $recipe, recipe_raw => $rule->recipe_raw };
            my $from_id;
            if ($no_rules) {
                $from_id = $node_name;
            }
            else {
                $from_id = $recipe_cache{$recipe}
                    || ( $recipe_cache{$recipe} = name_encode( [ 'rule', $target, $rule_no ] ) );
                $g->set_vertex_attributes( $from_id, $recipe_hash );
                $g->add_edge( $node_name, $from_id );
            }
            my $prereqs  = $rule->prereqs;
            my @to_nodes = ( $no_rules && !@$prereqs ) ? $node_name : @$prereqs;
            for my $dep (@to_nodes) {
                my $dep_node = $no_rules ? $dep : name_encode( [ 'target', $dep ] );
                $g->add_vertex($dep_node);
                if ($no_rules) {
                    my @edge = ( $from_id, $dep_node, $rule_no );
                    $g->set_edge_attributes_by_id( @edge, $recipe_hash );
                }
                else {
                    $g->add_edge( $from_id, $dep_node );
                }
            }
            next if !$recursive_make;
            for my $t ( _rmf_search_rule( $rule, $target_obj, $target, $rule_no, $rmfs ) ) {
                my ( undef, $rule_index, $line, $dir, $makefile, $vars, $targets ) = @$t;
                my $from           = $no_rules ? $target : name_encode( [ 'rule', $target, $rule_index ] );
                my $indir_makefile = $self->find_makefile( $makefile, $dir );
                next unless $indir_makefile && $fr->($indir_makefile);
                ## no critic (BuiltinFunctions::RequireBlockMap)
                my $cache_key = join ' ', $indir_makefile, sort map join( '=', @$_ ), @$vars;
                ## use critic
                if ( !$seen{$cache_key}++ ) {
                    my $make2 = ref($self)->new( %make_args, InDir => in_dir( $fsmap, $InDir, $dir ) );
                    $make2->parse($makefile);
                    $make2->set_var(@$_) for @$vars;
                    $targets = [ $make2->{Vars}{'.DEFAULT_GOAL'} ] unless @$targets;
                    my $g2 = $make2->as_graph(%options);
                    $g2->rename_vertices(
                        sub {
                            return in_dir( $fsmap, $dir, $_[0] ) if $no_rules;
                            my ( $type, $name, @other ) = @{ name_decode( $_[0] ) };
                            name_encode( [ $type, in_dir( $fsmap, $dir, $name ), @other ] );
                        }
                    );
                    $g->ingest($g2);
                }
                if ($no_rules) {
                    ## no critic (BuiltinFunctions::RequireBlockMap)
                    $g->add_edge( $from, $_ ) for map "$dir/$_", @$targets;
                    ## use critic
                }
                else {
                    ## no critic (BuiltinFunctions::RequireBlockMap)
                    $g->set_edge_attribute( $from, $_, fromline => $line )
                        for map name_encode( [ 'target', "$dir/$_" ] ), @$targets;
                    ## use critic
                }
            }
        }
    }
    return $g;
}

sub apply {
    my ( $self, $method, @args ) = @_;
    $self->NextPass;
    my ( $vars, $targets ) = parse_args(@args);
    $self->set_var(@$_) for @$vars;
    $targets = [ $self->{Vars}{'.DEFAULT_GOAL'} ] unless @$targets;
    ## no critic (BuiltinFunctions::RequireBlockGrep BuiltinFunctions::RequireBlockMap)
    my @bad_targets = grep !$self->{Depend}{$_}, @$targets;
    die "Cannot '$method' (@args) - no target @bad_targets" if @bad_targets;
    return map $self->target($_)->recurse($method), @$targets;
    ## use critic
}

# Spew a shell script to perfom the 'make' e.g. make -n
sub Script {
    my ( $self, @args ) = @_;
    my $com = ( $^O eq 'MSWin32' ) ? 'rem ' : '# ';
    my @results;
    for ( $self->apply( Make => @args ) ) {
        my ( $name, @cmd ) = @$_;
        push @results, $com . $name . "\n";
        ## no critic (BuiltinFunctions::RequireBlockMap)
        push @results, map parse_cmdline($_)->{line} . "\n", @cmd;
        ## use critic
    }
    return @results;
}

sub Print {
    my ( $self, @args ) = @_;
    return $self->apply( Print => @args );
}

sub Make {
    my ( $self, @args ) = @_;
    for ( $self->apply( Make => @args ) ) {
        my ( $name, @cmd ) = @$_;
        $self->exec($_) for @cmd;
    }
    return;
}

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {
        Pattern              => {},                      # GNU style %.o : %.c
        Dot                  => {},                      # Trad style .c.o
        Vpath                => {},                      # vpath %.c info
        Vars                 => {},                      # Variables defined in makefile
        Depend               => {},                      # hash of targets
        Pass                 => 0,                       # incremented each sweep
        Done                 => {},
        FunctionPackages     => [qw(Make::Functions)],
        FSFunctionMap        => \%fs_function_map,
        RecursiveMakeFinders => \@RECMAKE_FINDS,
        %args,
    }, $class;
    $self->set_var( 'CC',     $Config{cc} );
    $self->set_var( 'AR',     $Config{ar} );
    $self->set_var( 'CFLAGS', $Config{optimize} );
    load_modules( @{ $self->function_packages } );
    $DEFAULTS_AST ||= parse_makefile( \*DATA );
    $self->process_ast_bit(@$_) for @$DEFAULTS_AST;
    return $self;
}

=head1 NAME

Make - Pure-Perl implementation of a somewhat GNU-like make.

=head1 SYNOPSIS

    require Make;
    my $make = Make->new;
    $make->parse($file)->Make(@ARGV);

    # to see what it would have done
    print $make->Script(@ARGV);

    # to see an expanded version of the makefile
    $make->Print(@ARGV);

    my $targ = $make->target($name);
    my $rule = Make::Rule->new(':', \@prereqs, \@recipe, \@recipe_raw);
    $targ->add_rule($rule);
    my @rules = @{ $targ->rules };

    my @prereqs  = @{ $rule->prereqs };
    my @commands = @{ $rule->recipe };

=head1 DESCRIPTION

Implements in pure Perl a somewhat GNU-like make, intended to be highly
customisable.

Via pure-perl-make Make has built perl/Tk from the C<MakeMaker> generated
Makefiles...

=head1 MAKEFILE SYNTAX

Broadly, there are macros, directives, and rules (including recipes).

Macros:

    varname = value

Directives:

    vpath %.c src/%.c
    [-]include otherfile.mk # - means no warn on failure to include

Please note the C<vpath> does not have the GNU-make behaviour of
discarding the found path if an inferred target must be rebuilt, since
this is too non-deterministic / confusing behaviour for this author.

Rules:

    target : prerequisite1 prerequisite2[; immediate recipe]
    (tab character)follow-on recipe...

Recipe lines can start with C<@> (do not echo), C<-> (continue on failure).

In addition to traditional

	.c.o :
		$(CC) -c ...

GNU make's 'pattern' rules e.g.

	%.o : %.c
		$(CC) -c ...

The former gets internally translated to the latter.

=head1 METHODS

There are other methods (used by parse) which can be used to add and
manipulate targets and their prerequites.

=head2 new

Class method, takes pairs of arguments in name/value form. Arguments:

=head3 Vars

A hash-ref of values that sets variables, overridable by the makefile.

=head3 Jobs

Number of concurrent jobs to run while building. Not implemented.

=head3 GNU

If true, then F<GNUmakefile> is looked for first.

=head3 FunctionPackages

Array-ref of package names to search for GNU-make style
functions. Defaults to L<Make::Functions>.

=head3 FSFunctionMap

Hash-ref of file-system functions by which to access the
file-system. Created to help testing, but might be more widely useful.
Defaults to code accessing the actual local filesystem. The various
functions are expected to return real Perl filehandles. Relevant keys:
C<glob>, C<fh_open>, C<fh_write>, C<mtime>, C<file_readable>,
C<is_abs>.

=head3 InDir

Optional. If supplied, will be treated as the current directory instead
of the default which is the real current directory.

=head3 RecursiveMakeFinders

Array-ref of functions to be called in order, searching an expanded
recipe line for a recursive make invocation (cf
L<Recursive Make Considered Harmful|http://www.real-linux.org.uk/recursivemake.pdf>)
that would run a C<make> in a subdirectory. Each returns either an empty
list, or

    ($dir, $makefile, $vars, $targets)

The C<$makefile> might be <undef>, in which case the default will be
searched for. C<$vars> and C<$targets> are array-refs of pairs and
strings, respectively. The C<$targets> can be empty.

Defaults to a single, somewhat-suitable, function.

=head2 parse

Parses the given makefile. If none or C<undef>, these files will be tried,
in order: F<GNUmakefile> if L</GNU>, F<makefile>, F<Makefile>.

If a scalar-ref, will be makefile text.

Returns the make object for chaining.

=head2 Make

Given a target-name, builds the target(s) specified, or the first 'real'
target in the makefile.

=head2 Print

Print to current C<select>'ed stream a form of the makefile with all
variables expanded.

=head2 Script

Print to current C<select>'ed stream the equivalent bourne shell script
that a make would perform i.e. the output of C<make -n>.

=head2 set_var

Given a name and value, sets the variable to that.

May gain a "type" parameter to distinguish immediately-expanded from
recursively-expanded (the default).

=head2 expand

Uses L</subsvars> to return its only arg with any macros expanded.

=head2 target

Find or create L<Make::Target> for given target-name.

=head2 has_target

Returns boolean on whether the given target-name is known to this object.

=head2 targets

List all "real" (non-dot, non-inference) target-names known to this object
at the time called, unsorted. Note this might change when C<Make> is
called, as targets will be added as part of the dependency-search process.

=head2 patrule

Search registered pattern-rules for one matching given
target-name. Returns a L<Make::Rule> for that of the given kind, or false.

Uses GNU make's "exists or can be made" algorithm on each rule's proposed
requisite to see if that rule matches.

=head2 find_recursive_makes

    my @found = $make->find_recursive_makes;

Iterate over all the rules, expanding them for their targets, and find
any recursive make invocations using the L</RecursiveMakeFinders>.

Returns a list of array-refs with:

    [ $from_target, $rule_index, $line_index, $dir, $makefile, $vars, $targets ]

=head1 ATTRIBUTES

These are read-only.

=head2 vars

Returns a hash-ref of the current set of variables.

=head2 function_packages

Returns an array-ref of the packages to search for macro functions.

=head2 fsmap

Returns a hash-ref of the L</FSFunctionMap>.

=head2 as_graph

Returns a L<Graph::Directed> object representing the makefile.
Takes options as a hash:

=head3 recursive_make

If true (default false), uses L</RecursiveMakeFinders> to find recursive
make invocations in the current makefile, parses those, then includes
them, with an edge created to the relevant target.

=head3 no_rules

If true, the graph will only have target vertices, but will be
"multiedged". The edges will have an ID of the zero-based index of the
rule on the predecessor target, and will have attributes C<recipe>
and C<recipe_raw>. Rules with no prerequisites will be indicated with
an edge back to the same target.

If false (the default), the vertices are named either C<target:name>
(representing L<Make::Target>s) or C<rule:name:rule_index> (representing
L<Make::Rule>s). The names encoded with L</name_encode>. Rules are named
according to the first (alphabetically) target they are attached to.

The rule vertices have attributes with the same values as the
L<Make::Rule> attributes:

=over

=item recipe

=item recipe_raw

=back

=head1 FUNCTIONS

=head2 name_encode

=head2 name_decode

    my $encoded = Make::name_encode([ 'target', 'all' ]);
    my $tuple = Make::name_decode($encoded); # [ 'target', 'all' ]

Uses C<%>-encoding and -decoding to allow C<%> and C<:> characters in
components without problems.

=head2 parse_makefile

Given a file-handle, returns array-ref of Abstract Syntax-Tree (AST)
fragments, representing the contents of that file. Each is an array-ref
whose first element is the node-type (C<comment>, C<include>, C<vpath>,
C<var>, C<rule>), followed by relevant data.

=head2 tokenize

Given a line, returns array-ref of the space-separated "tokens". Also
splits on any further args.

=head2 subsvars

    my $expanded = Make::subsvars(
        'hi $(shell echo there)',
        \@function_packages,
        [ \%vars ],
        $fsmap,
    );
    # "hi there"

Given a piece of text, will substitute any macros in it, either a
single-character macro, or surrounded by either C<{}> or C<()>. These
can be nested. Uses the array-ref as a list of hashes to search
for values.

If the macro is of form C<$(varname:a=b)>, then this will be a GNU
(and others) make-style "substitution reference". First "varname" will
be expanded. Then all occurrences of "a" at the end of words within
the expanded text will be replaced with "b". This is intended for file
suffixes.

For GNU-make style functions, see L<Make::Functions>.

=head1 DEBUGGING

To see debugging messages on C<STDERR>, set environment variable
C<MAKE_DEBUG> to a true value;

=head1 BUGS

More attention needs to be given to using the package to I<write> makefiles.

The rules for matching 'dot rules' e.g. .c.o   and/or pattern rules e.g. %.o : %.c
are suspect. For example give a choice of .xs.o vs .xs.c + .c.o behaviour
seems a little odd.

=head1 SEE ALSO

L<pure-perl-make>

L<https://pubs.opengroup.org/onlinepubs/9699919799/utilities/make.html> POSIX standard for make

L<https://www.gnu.org/software/make/manual/make.html> GNU make docs

=head1 AUTHOR

Nick Ing-Simmons

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1996-1999 Nick Ing-Simmons.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
#
# Remainder of file is in makefile syntax and constitutes
# the built in rules
#
__DATA__

.SUFFIXES: .o .c .y .h .sh .cps

.c.o :
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

.c   :
	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $< $(LDFLAGS) $(LDLIBS)

.y.o:
	$(YACC) $<
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ y.tab.c
	$(RM) y.tab.c

.y.c:
	$(YACC) $<
	mv y.tab.c $@
