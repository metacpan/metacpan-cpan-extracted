package HTML::Template::Compiled::Compiler;
use strict;
use warnings;
use Data::Dumper;
use Carp qw(croak carp);
use HTML::Template::Compiled::Expression qw(:expressions);
use HTML::Template::Compiled::Utils qw(:walkpath);
use File::Basename qw(dirname);

our $VERSION = '1.003'; # VERSION

our $DISABLE_NEW_ALIAS = 0;

use Carp qw(croak carp);
use constant D             => 0;

use constant T_VAR         => 'VAR';
use constant T_IF          => 'IF';
use constant T_UNLESS      => 'UNLESS';
use constant T_ELSIF       => 'ELSIF';
use constant T_ELSE        => 'ELSE';
use constant T_IF_DEFINED  => 'IF_DEFINED';
use constant T_END         => '__EOT__';
use constant T_WITH        => 'WITH';
use constant T_SWITCH      => 'SWITCH';
use constant T_CASE        => 'CASE';
use constant T_INCLUDE     => 'INCLUDE';
use constant T_LOOP        => 'LOOP';
use constant T_WHILE       => 'WHILE';
use constant T_EACH        => 'EACH';
use constant T_INCLUDE_VAR => 'INCLUDE_VAR';
use constant T_INCLUDE_STRING => 'INCLUDE_STRING';
use constant T_USE_VARS    => 'USE_VARS';
use constant T_SET_VAR     => 'SET_VAR';
use constant T_WRAPPER     => 'WRAPPER';

use constant INDENT        => '    ';

use constant NO_TAG        => 0;
use constant OPENING_TAG   => 1;
use constant CLOSING_TAG   => 2;

use constant ATTR_ESCAPES    => 0;
use constant ATTR_TAGS       => 1;
use constant ATTR_NAME_RE    => 2;

sub set_escapes    { $_[0]->[ATTR_ESCAPES] = $_[1] }
sub get_escapes    { $_[0]->[ATTR_ESCAPES] }
sub set_tags       { $_[0]->[ATTR_TAGS] = $_[1] }
sub add_tags       {
    for my $key (keys %{ $_[1] }) {
        $_[0]->[ATTR_TAGS]->{$key} = $_[1]->{$key};
    }
}
sub get_tags       { $_[0]->[ATTR_TAGS] }
sub set_name_re    { $_[0]->[ATTR_NAME_RE] = $_[1] }
sub get_name_re    { $_[0]->[ATTR_NAME_RE] }

our %ESCAPES;

sub delete_subs {
    # delete all userdefined subs
    %ESCAPES = ();
}

sub setup_escapes {
    my ($class, $plug_class, $escapes) = @_;
    for my $key (keys %$escapes) {
        my $def = $escapes->{$key};
        my $sub;
        if (ref $def eq 'HASH') {
            $sub = $def->{code};
            if (my $arguments = $def->{arguments} ) {
                $ESCAPES{ $plug_class }->{ $key }->{arguments} = $arguments;
            }
        }
        else {
            $sub = $def;
        }
        if (ref $sub eq 'CODE') {
            $ESCAPES{ $plug_class }->{ $key }->{code} = $sub;
        }
        else {
            $ESCAPES{ $plug_class }->{ $key }->{code} = \&{ $sub };
        }
    }
}

sub add_escapes {
    my ($self, $plug_class, $new_escapes) = @_;
    my $escapes = $self->get_escapes;
    for my $key (keys %$new_escapes) {
        $escapes->{ $key } = $plug_class;
    }
}

sub new {
    my $class = shift;
    my $self = [];
    bless $self, $class;
    $self->set_escapes({});
    return $self;
}

sub _escape_expression {
    my ( $self, $exp, $escape ) = @_;
    return $exp unless $escape;
    my @escapes = split m/\|/, uc $escape;
    my $escapes = $self->get_escapes();
    for (@escapes) {
        if ( $_ eq 'HTML' ) {
            $exp =
                _expr_function( 'HTML::Template::Compiled::Utils::escape_html',
                $exp, );
        }
        elsif ( $_ eq 'HTML_ALL' ) {
            $exp =
                _expr_function( 'HTML::Template::Compiled::Utils::escape_html_all',
                $exp, );
        }
        elsif ( $_ eq 'URL' ) {
            $exp =
                _expr_function( 'HTML::Template::Compiled::Utils::escape_uri',
                $exp, );
        }
        elsif ( $_ eq 'JS' ) {
            $exp =
                _expr_function( 'HTML::Template::Compiled::Utils::escape_js',
                $exp, );
        }
        elsif ( $_ eq 'IJSON' ) {
            $exp =
                _expr_function( 'HTML::Template::Compiled::Utils::escape_ijson',
                $exp, );
        }
        elsif ( $_ eq 'DUMP' ) {
            $exp = _expr_method( 'dump', _expr_literal('$t'), $exp, );
        }
        elsif (my $plug_class = $escapes->{$_}) {
            my $subref = "\$HTML::Template::Compiled::Compiler::ESCAPES\{'$plug_class'\}->\{'$_'\}->\{code\}";
            my @args = $exp;
            if (my $arguments = $ESCAPES{ $plug_class }->{ $_ }->{arguments}) {
                @args = ();
                for my $arg (@$arguments) {
                    if ($arg eq 'var') {
                        push @args, $exp;
                    }
                    elsif ($arg eq 'self') {
                        push @args, "\$t->get_plugin('$plug_class')";
                        #push @args, 23;
                    }
                }
            }
            $exp = HTML::Template::Compiled::Expression::SubrefCall->new( $subref, @args );
        }
    }
    return ref $exp ? $exp->to_string : $exp;
}

sub init_name_re {
    my ($self, %args) = @_;
    my $re = qr#
        \Q$args{deref}\E |
        \Q$args{method_call}\E |
        \Q$args{formatter_path}\E
        #x;
        $self->set_name_re($re);
}

my %loop_context = (
    __index__   => '$__ix__',
    __counter__ => '$__ix__+1',
    __first__   => '$__ix__ == $[',
    __last__    => '$__ix__ == $__size__',
    __odd__     => '!($__ix__ & 1)',
    __even__    => '($__ix__ & 1)',
    __inner__   => '$__ix__ != $[ && $__ix__ != $__size__',
    __outer__   => '$__ix__ == $[ || $__ix__ == $__size__',
    __key__     => '$__key__',
    __value__   => '$__value__',
    __break__   => '$__break__',
    __filename__ => '$t->get_file',
    __filenameshort__ => '$t->get_filename',
    __wrapped__ => '$args->{wrapped}',
);

sub parse_var {
    my ( $self, $t, %args ) = @_;
    my $lexicals = $args{lexicals};
    my $context = $args{context};
    # calling context. 'list' or empty (which means scalar)
    my $ccontext = $args{ccontext} || '';


    if (!defined $args{var} and defined $args{expr}) {
        my $compiler = $args{compiler};
        return HTML::Template::Compiled::Expr->parse_expr(
            $compiler,
            $t,
            %args,
            expr   => $args{expr},
            context => $context,
        );
    }


    if (!$t->validate_var($args{var})) {
        $t->get_parser->_error_wrong_tag_syntax(
            {
                fname => $context->get_file,
                line  => $context->get_line,
                token => "",
            },
            $args{var},

        );
    }
    if ( grep { defined $_ && $args{var} eq $_ } @$lexicals ) {
        my $varstr = "\$HTML::Template::Compiled::_lexi_$args{var}";
        return $varstr;
    }
    my $lexi = join '|', grep defined, @$lexicals;
    my $varname = '$var';
    my $re = $self->get_name_re;
#    warn __PACKAGE__.':'.__LINE__.": re: $re\n";
    #warn __PACKAGE__.':'.__LINE__.": ========== ($args{var})\n";
    my $root         = 0;
    my $up_stack = 0;
    my $initial_var = '$$C';
    my $is_object_var = '$C_IS_OBJECT';
    my $root_hash = 0;
    my $OPT_INITIAL_VAR = $t->get_optimize->{initial_var};
    my $OPT_IS_OBJECT = $t->get_optimize->{object_check};
    my $OPT_ROOT_HASH = $t->get_optimize->{root_hash};
    my $use_initial_var = $OPT_INITIAL_VAR ? 1 : 0;
    if ( $t->get_loop_context && $args{var} =~ m/^__(\w+)__$/ ) {
        if (exists $loop_context{ lc $args{var} }) {
            my $lc = $loop_context{ lc $args{var} };
            return $lc;
        }
    }
    # explicitly use aliases with '$' at the beginning
    if (not $DISABLE_NEW_ALIAS and $args{var} =~ s/^\$(\w+)//) {
        $initial_var = "\$HTML::Template::Compiled::_lexi_$1";
        $is_object_var = '';
    }
    elsif ($lexi and $args{var} =~ s/^($lexi)($re)/$2/) {
        $initial_var = "\$HTML::Template::Compiled::_lexi_$1";
        $is_object_var = '';
    }
    elsif ( $args{var} =~ m/^_/ && $args{var} !~ m/^__(\w+)__$/ ) {
        $args{var} =~ s/^_//;
        $root = 0;
        $is_object_var = '';
    }
    elsif ( my @roots = $args{var} =~ m/\G($re)/gc) {
        #print STDERR "ROOTS: (@roots)\n";
        $root = 1 if @roots == 1;
        $args{var} =~ s/^($re)+//;
        if (@roots > 1) {
            croak "Cannot navigate up the stack" if !$t->get_global_vars & 2;
            $up_stack = $#roots;
            $initial_var = "\$t->get_globalstack->[-$up_stack]";
            $use_initial_var = 0;
            $is_object_var = '';
        }
        elsif (@roots == 1) {
            $initial_var = '$P';
            $is_object_var = '$P_IS_OBJECT';
            $root_hash = 1 if $OPT_ROOT_HASH;
        }
    }
    my @split = split m/(?=$re)/, $args{var};
    @split = map {
        my @ret;
        my $count = 0;
        if (s/#\z//) {
            $count = 1;
        }
        if ( m/(.*)\[(-?\d+)\]/ ) {
            my @slice = "[$2]";
            my $var = "$1";
            while ($var =~ s/\[(-?\d+)\]\z//) {
                unshift @slice, "[$1]";
            }
            @ret = ($var, @slice)
        }
        else {
            @ret = $_
        }
        push @ret, '#' if $count;
        @ret;
    } @split;
    my @paths;
    #print STDERR "paths: (@split)\n";
    my $count = 0;
    my $use_objects = $t->get_objects;
    my $strict = $use_objects eq 'strict' ? 1 : 0;
    my $method_args = '';
    my $varstr = '';
    @split = map {
        s#\\#\\\\#g;
        s#'#\\'#g;
        length $_ ? $_ : ()
    } @split;
    if (@split == 1) {
        $varname = $initial_var;
    }
    my $used_initial_var = 0;
    for my $i (0 .. $#split) {
        if ($i == $#split and defined $args{method_args}) {
            $method_args = $args{method_args};
        }
        my $around = ['', ''];
        if ($i == $#split and $ccontext eq 'list') {
            if ($context->get_name eq 'EACH') {
                $around = ['+{', '}'];
            }
            elsif ($context->get_name eq 'LOOP') {
                $around = ['[', ']'];
            }
        }
        my $p = $split[$i];
        #warn __PACKAGE__.':'.__LINE__.": path: $p\n";
        my $copy = $p;
        my $array_index;
        my $get_length;
        my $method_call;
        my $deref;
        my $formatter_call;
        my $guess;
        my $try_global;
        if ( $p =~ s/^\[(-?\d+)\]$/$1/ ) {
            # array index
            $array_index = $1;
        }
        elsif ( $p =~ s/^#$// ) {
            # number of elements
            $get_length = 1;
        }
        elsif ( $use_objects and $p =~ s/^\Q$args{method_call}// ) {
            # maybe method call
            $method_call = 1;
        }
        elsif ( $p =~ s/^\Q$args{deref}// ) {
            # deref
            $deref = 1;
        }
        elsif ( $p =~ s/^\Q$args{formatter_path}// ) {
            $formatter_call = 1;
        }
        else {
            # guess
            $guess = 1;
        }
        if ($method_call || $guess) {
            unless ($p =~ m/^[A-Za-z_][A-Za-z0-9_]*\z/) {
                # not a valid method name
                $deref = 1;
                $method_call = $guess = 0;
            }
        }
        if ($method_call || $guess || $deref) {
            if ($count == 0 && $t->get_global_vars & 1) {
                $try_global = 1;
                $method_call = $guess = $deref = 0;
            }
        }

        my $path = $t->get_case_sensitive ? $p : lc $p;
        my $code;
        if ( defined $array_index ) {
            # array index
            $code = "$varname\->[$array_index]";
        }

        elsif ( $get_length ) {
            # number of elements
            $code = "scalar \@{$varname || []}";
        }

        elsif ($try_global) {
            $code = "\$t->try_global($varname, '$path')";
        }

        elsif ( $method_call || $guess) {
            # maybe method call
            my $check_object = "UNIVERSAL::can($varname,'can')";
            my $local_varname = $varname;
            if ($i == 0) {
                if ($use_initial_var) {
                    $local_varname = $initial_var;
                    $used_initial_var = 1;
                    $check_object = "UNIVERSAL::can($local_varname,'can')";
                }
                if ($OPT_IS_OBJECT and $is_object_var) {
                    $check_object = $is_object_var;
                }

            }
            if ($i == 0 and $root_hash) {
                $code = "$local_varname\->\{'$path'\}";
            }
            elsif ($strict) {
                $code = "($check_object ? $local_varname->$p($method_args) : $local_varname\->\{'$path'\})";
            }
            else {
                $code = "(Scalar::Util::blessed($local_varname) ? $local_varname->can('$p') ? $local_varname->$p($method_args) : undef : $local_varname\->\{'$path'\})";
            }
        }

        elsif ( $deref ) {
            $code = "$varname\->\{'$path'\}";
        }

        elsif ( $formatter_call ) {
            $code = "\$t->_walk_formatter($varname, '$p', @{[$t->get_global_vars]})";
        }
        $code = $around->[0] . $code . $around->[1];
        if (0 or @split > 1) {
            if ($used_initial_var and $i==0) {
                $varstr .= "my $varname = $code;";
            }
            else {
                $varstr .= "$varname = $code;";
            }
        }
        else {
            $varstr = $code;
        }

        $count++;
    }
    #my $final = $context->get_name eq 'VAR' ? 1 : 0;
    if (0 or @split > 1) {
        if ($used_initial_var) {
            $varstr = "do { $varstr $varname }";
        }
        else {
            $varstr = "do { my $varname = $initial_var; $varstr $varname }";
        }
    }
    else {
        $varstr = $initial_var unless length $varstr;
        $varstr = "$varstr";
    }
    return $varstr;
}

sub dump_string {
    my ($self, $string) = @_;
    my $dump = HTML::Template::Compiled->dump_var($string, 'string');
    $dump =~ s#^\$string *= *## or die "dump_string() failed";
    $dump =~ s/;$//;
    return $dump;
}

sub compile {
    my ( $class, $self, $text, $fname ) = @_;
    D && $self->log("compile($fname)");
    if ( my $filter = $self->get_filter ) {
        require HTML::Template::Compiled::Filter;
        $filter->filter($text);
    }
    my $parser = $self->get_parser;
    my @p = $parser->parse($fname, $text);
    if (my $df = $self->get_debug->{file}) {
        my $debugfile = $df =~ m/short/ ? $self->get_filename : $self->get_file;
        if ($df =~ m/start/) {
            unshift @p, 
            HTML::Template::Compiled::Token::Text->new([
                '<!-- start ' . $debugfile . ' -->', 0,
                undef, undef, undef, $self->get_file, 0
            ]);
        }
        if ($df =~ m/end/) {
            push @p, 
            HTML::Template::Compiled::Token::Text->new([
                '<!-- end ' . $debugfile . ' -->', 0,
                undef, undef, undef, $self->get_file, 0
            ]);
        }
    }
    my $code  = '';
    my $info = {}; # for query()
    my $info_stack = [$info];

my $test = $self->get_debug->{options};
    # got this trick from perlmonks.org
    my $anon = D
      || ($self->get_debug->{options} & HTML::Template::Compiled::DEBUG_COMPILED()) ? qq{local *__ANON__ = "htc_$fname";\n} : '';

    no warnings 'uninitialized';
    my $string_output = '$OUT .= ';
    my $fh_output = 'print $OFH ';
    my $output = $string_output;
    my $out_fh = $self->get_out_fh;
    if ($out_fh) {
        $output = $fh_output;
    }
    my @outputs = ($output);
    my $warnings_string = "no warnings;\n";
    if (my $warnings = $self->get_warnings) {
        if ($warnings eq 1) {
            $warnings_string = "use warnings;\n";
        }
        elsif ($warnings eq 'fatal') {
            $warnings_string = "use warnings FATAL => qw(all);\n";
        }
    }
    my $OPT_IS_OBJECT = $self->get_optimize->{object_check};
    my $OPT_ROOT_HASH = $self->get_optimize->{root_hash};
    my $header = <<"EOM";
sub {
    use vars qw/ \$__ix__ \$__key__ \$__value__ \$__break__ \$__size__ /;
    use strict;
$warnings_string
$anon
    my (\$t, \$P, \$C, \$OFH, \$args) = \@_;
    my \$OUT = '';
EOM
    if ($OPT_IS_OBJECT) {
        if ($OPT_ROOT_HASH) {
            $header .= <<"EOM";
    my \$P_IS_OBJECT = 1;
EOM
        }
        else {
            $header .= <<"EOM";
    my \$P_IS_OBJECT = UNIVERSAL::can(\$P, 'can');
EOM
        }
        $header .= <<"EOM";
    my \$C_IS_OBJECT = UNIVERSAL::can(\$\$C, 'can');
EOM
    }

    my @lexicals;
    my @switches;
    my $tags = $class->get_tags;
        my $meth     = $self->method_call;
        my $deref    = $self->deref;
        my $format   = $self->formatter_path;
    $class->init_name_re(
        deref          => $deref,
        method_call    => $meth,
        formatter_path => $format,
    );
    my %var_args = (
        deref          => $deref,
        method_call    => $meth,
        formatter_path => $format,
        lexicals       => \@lexicals,
    );
    my %use_vars;
    my @wrapped;
    my $globalstack = '';
    if ($self->get_global_vars) {
        $globalstack = '$new->set_globalstack($t->get_globalstack);';
    }
    my $line_info = $self->get_line_info;
    for my $token (@p) {
        @use_vars{ @lexicals } = () if @lexicals;
        my ($text, $line, $open_close, $tname, $attr, $f, $nlevel) = @$token;
        #print STDERR "tags: ($text, $line, $open_close, $tname, $attr)\n";
        #print STDERR "p: '$text'\n";
        my $indent = INDENT x $nlevel;
        $code .= "#line $line $fname\n" if $line_info;
        if (!$token->is_tag) {
            if ( length $text ) {
                # don't ask me about this line. i tried to get HTC
                # running with utf8 (directly in the template),
                # and without this line i only got invalid characters.
                local $Data::Dumper::Deparse = 1;

                if ($text =~ m/\A(?:\r?\n|\r)\z/) {
                    $text =~ s/\r/\\r/;
                    $text =~ s/\n/\\n/;
                    $code .= qq#$indent$output "$text";# . $/;
                }
                else {
                    $code .= qq#$indent$output # . $class->dump_string($text) . ';' . $/;
                }
            }
        }
        elsif ($token->is_open) {
        # --------- TMPL_VAR
        if ($tname eq T_VAR) {
            my $var    = $attr->{NAME};
            if ($self->get_use_query) {
                $info_stack->[-1]->{lc $var}->{type} = T_VAR;
            }
            my $expr;
            if (exists $tags->{$tname} && exists $tags->{$tname}->{open}) {
                $expr = $tags->{$tname}->{open}->($class, $self, {
                        %var_args,
                        context => $token,
                    },);
            }
            else {
               $expr = $class->_compile_OPEN_VAR($self, {
                        %var_args,
                        context => $token,
                    },);
            }
            $code .= qq#${indent}$output #
            . $expr . qq#;\n#;
        }

        # ---------- TMPL_PERL
        elsif ($tname eq 'PERL') {
            my $perl    = $attr->{PERL};
            my %map = (
                __HTC__     => '$t',
                __ROOT__    => '$P',
                __CURRENT__ => '$$C',
                __OUT__     => $output,
                __INDEX__   => '$__ix__',
            );
            my $re = join '|', keys %map;
            $perl =~ s/($re)/exists $map{$1} ? $map{$1} : $1/eg;
            $code .= $perl;
        }

        # --------- TMPL_WITH
        elsif ($tname eq T_WITH) {
            my $var    = $attr->{NAME};
            my $varstr = $class->parse_var($self,
                %var_args,
                var => $var,
                context => $token,
                compiler => $class,
                expr   => $attr->{EXPR},
            );
            $code .= <<"EOM";
${indent}\{
EOM
            if ($self->get_global_vars) {
                $code .= _expr_method(
                    'pushGlobalstack',
                    '$t', '$$C'
                )->to_string($nlevel) . ";\n";
            }
            $code .= <<"EOM";
${indent}    my \$C = \\$varstr;
${indent}    if (defined \$\$C) {
EOM
            if ($OPT_IS_OBJECT) {
            $code .= <<"EOM";
${indent}    my \$C_IS_OBJECT = UNIVERSAL::can(\$\$C, 'can');
EOM
            }
        }

        if ( $tname eq T_USE_VARS ) {
            my $vars     = $attr->{NAME};
            my @l = grep length, split /\s*,\s*/, $vars;
            for my $var (@l) {
                if ($var =~ tr/a-zA-Z0-9_//c) {
                    $self->get_parser->_error_wrong_tag_syntax(
                        {
                            fname => $token->get_file,
                            line  => $token->get_line,
                            token => "",
                        },
                        $var,
                        'invalid SET_VAR/USE_VARS var name',
                    );
                }
            }
            push @lexicals, @l;
        }
        elsif ( $tname eq T_SET_VAR ) {
            my $var     = $attr->{NAME};
            if ($var =~ tr/a-zA-Z0-9_//c) {
                $self->get_parser->_error_wrong_tag_syntax(
                    {
                        fname => $token->get_file,
                        line  => $token->get_line,
                        token => "",
                    },
                    $var,
                    'invalid SET_VAR/USE_VARS var name',
                );
            }
            my $value;
            my $expr;
            if (exists $attr->{VALUE}) {
                $value = $attr->{VALUE};
            }
            elsif (exists $attr->{EXPR}) {
                $expr = $attr->{EXPR};
            }
            else {
                $self->get_parser->_error_wrong_tag_syntax(
                    {
                        fname => $token->get_file,
                        line  => $token->get_line,
                        token => "",
                    },
                    $var,
                    'missing VALUE or EXPR',
                );
            }

            unshift @lexicals, $var;
            my $varstr = $class->parse_var($self,
                %var_args,
                var         => $value,
                context     => $token,
                compiler    => $class,
                expr        => $expr,
            );
            $code .= <<"EOM";
${indent}local \$HTML::Template::Compiled::_lexi_$var = $varstr;
EOM
        }
        # --------- TMPL_LOOP TMPL_WHILE TMPL_EACH
        elsif ( ($tname eq T_LOOP || $tname eq T_WHILE || $tname eq T_EACH) ) {
            my $var     = $attr->{NAME};
            my $ccontext = $attr->{CONTEXT} || '';
            my $varstr = $class->parse_var($self,
                %var_args,
                var         => $var,
                context     => $token,
                compiler    => $class,
                expr        => $attr->{EXPR},
                ccontext    => $ccontext,
            );
            my $ind    = INDENT;
            if ($self->get_use_query) {
                $info_stack->[-1]->{lc $var}->{type} = $tname;
                $info_stack->[-1]->{lc $var}->{children} ||= {};
                push @$info_stack, $info_stack->[-1]->{lc $var}->{children};
            }
            my $lexical = $attr->{ALIAS};
            my $insert_break = '';
            if (defined (my $break = $attr->{BREAK})) {
                $break =~ tr/0-9//cd;
                if ($break) {
                    $insert_break = qq#local \$__break__ = ! ((\$__ix__+1 ) \% $break);#;
                }
            }
            push @lexicals, $lexical;
            my $sort_keys = '';
            # SORT=ALPHA or SORT not set => cmp
            # SORT=NUM => <=>
            # SORT=0 or anything else => don't sort

            my $sort_key_a = '$a';
            my $sort_key_b = '$b';
            if ($attr->{SORTBY}) {
                my $varstr = $class->parse_var($self,
                    %var_args,
                    var   => $attr->{SORTBY},
                    context => $token,
                    compiler => $class,
                );
                ($sort_key_a, $sort_key_b) = ($varstr, $varstr);
                $sort_key_a =~ s/\$\$C/\$hash\{\$a\}/g;
                $sort_key_b =~ s/\$\$C/\$hash\{\$b\}/g;
            }

            if ($attr->{REVERSE}) {
                ($sort_key_b, $sort_key_a) = ($sort_key_a, $sort_key_b);
            }
            my $sort_op = 'cmp';
            if (!defined $attr->{SORT} or uc $attr->{SORT} eq 'ALPHA') {
            }
            elsif (uc $attr->{SORT} eq 'NUM') {
                $sort_op = '<=>';
            }
            $sort_keys = "sort \{ $sort_key_a $sort_op $sort_key_b \}";

            my $global = '';
            my $lexi =
              defined $lexical ? "${indent}local \$HTML::Template::Compiled::_lexi_$lexical = \$\$C;\n" : "";
            if ($self->get_global_vars) {
                my $pop_global = _expr_method(
                    'pushGlobalstack',
                    '$t', '$$C'
                );
                $global = $pop_global->to_string($nlevel).";\n";

            }
            if ($tname eq T_WHILE) {
                $code .= "\{" . "\n";
                $code .= <<"EOM";
$global
${indent}${indent}local \$__ix__ = -1;
$insert_break
${indent}${ind}while (my \$next = $varstr) {
${indent}${indent}\$__ix__++;
${indent}${indent}my \$C = \\\$next;
$lexi
EOM
                if ($OPT_IS_OBJECT) {
                    $code .= <<"EOM";
    ${indent}    my \$C_IS_OBJECT = UNIVERSAL::can(\$\$C, 'can');
EOM
                }
            }
            elsif ($tname eq T_EACH) {
                # bug in B::Deparse, so do double ref
                $code .= <<"EOM";
${indent}if (my \%hash = eval \{ \%\$\{ \\$varstr \} \} ) \{
${indent}${indent}local \$__ix__ = -1;
${indent}${ind}local (\$__key__,\$__value__);
${indent}${ind}for \$__key__ ($sort_keys keys \%hash) \{
${indent}${ind}    local \$__value__ = \$hash\{\$__key__};
${indent}${indent}\$__ix__++;
$insert_break
EOM
            }
            else {

                my $join_code = '';
                if (defined (my $join = $attr->{JOIN})) {
                    my $dump = HTML::Template::Compiled->dump_var($join, 'join');
                    $dump =~ s{\$join *= *}{};
                    $dump =~ s{;$}{};
                    $join_code = <<"EOM";
\{
  unless (\$__ix__ == \$[) \{
$output $dump;
\}
\}
EOM
                    
                }
                # bug in B::Deparse, so do double ref
                $code .= <<"EOM";
${indent}if (my \@array = eval { \@\$\{ \\$varstr \} } )\{
${indent}${ind}local \$__size__ = \$#array;
$global

${indent}${ind}
${indent}${ind}for \$__ix__ (\$[..\$__size__ + \$[) \{
${indent}${ind}${ind}my \$C = \\ (\$array[\$__ix__]);
$insert_break
$lexi
$join_code
EOM
                if ($OPT_IS_OBJECT) {
                    $code .= <<"EOM";
    ${indent}    my \$C_IS_OBJECT = UNIVERSAL::can(\$\$C, 'can');
EOM
                }
            }
        }

        # --------- TMPL_ELSE
        elsif ($tname eq T_ELSE) {
            my $exp = "\} else \{";
            $code .= $exp;
        }

        # --------- TMPL_IF TMPL_UNLESS TMPL_ELSIF TMPL_IF_DEFINED
        elsif ($tname eq T_IF) {
            my $expr = $class->_compile_OPEN_IF($self, {
                    %var_args,
                    context => $token,
                },);
            $code .= $expr;
        }
        elsif ($tname eq T_IF_DEFINED) {
            my $expr = $class->_compile_OPEN_IF_DEFINED($self, {
                    %var_args,
                    context => $token,
                },);
            $code .= $expr;
        }
        elsif ($tname eq T_UNLESS) {
            my $expr = $class->_compile_OPEN_UNLESS($self, {
                    %var_args,
                    context => $token,
                },);
            $code .= $expr;
        }

        # --------- TMPL_ELSIF
        elsif ($tname eq T_ELSIF) {
            my $var    = $attr->{NAME};
            my $varstr = $class->parse_var($self,
                %var_args,
                var   => $var,
                context => $token,
                compiler => $class,
                expr   => $attr->{EXPR},
            );
            my $operand = _expr_literal($varstr);
            my $exp = _expr_elsif($operand);
            my $str = $exp->to_string($nlevel);
            $code .= $str . $/;
        }

        # --------- TMPL_SWITCH
        elsif ($tname eq T_SWITCH) {
            my $var = $attr->{NAME};
            push @switches, 0;
            my $varstr = $class->parse_var($self,
                %var_args,
                var   => $var,
                context => $token,
                compiler => $class,
                expr   => $attr->{EXPR},
            );
            $code .= <<"EOM";
${indent}SWITCH: for my \$_switch ($varstr) \{
EOM
        }
        
        # --------- TMPL_CASE
        elsif ($tname eq T_CASE) {
            my $val = $attr->{NAME};
            #$val =~ s/^\s+//;
            if ( $switches[$#switches] ) {

                # we aren't the first case
                $code .= qq#${indent}last SWITCH;\n${indent}\}\n#;
            }
            else {
                $switches[$#switches] = 1;
            }
            if ( !length $val or uc $val eq 'DEFAULT' ) {
                $code .= qq#${indent}if (1) \{\n#;
            }
            else {
                $val =~ tr/'//d;
                my @splitted = split /,/, $val;
                my $is_default = '';
                @splitted = grep {
                    uc $_ eq 'DEFAULT'
                        ? do {
                            $is_default = ' or 1 ';
                            0;
                        }
                        : 1
                } @splitted;
                my $values = join ",", map { qq#'$_'# } @splitted;
                if ($is_default or @splitted > 1) {
                    $code .=
qq#${indent}if (grep \{ \$_switch eq \$_ \} $values $is_default) \{\n#;
                }
                else {
                    $code .=
qq#${indent}if ( \$_switch eq $values) \{\n#;
                }
            }
        }

        # --------- TMPL_INCLUDE_STRING
        elsif ($tname eq T_INCLUDE_STRING) {
            my $var = $attr->{NAME};
            my $varstr = $class->parse_var($self,
                %var_args,
                var   => $var,
                context => $token,
                compiler => $class,
                expr   => $attr->{EXPR},
            );
            my $ref = ref $self;
            $code .= <<"EOM";
\{
my \$scalar = $varstr;
my \$new = \$t->new_scalar_from_object(\$scalar);
$globalstack
$output \$new->get_code()->(\$new,\$P,\$C@{[$out_fh ? ",\$OFH" : '']});
\}
EOM

        }

        # --------- TMPL_INCLUDE_VAR
        elsif ($tname eq T_INCLUDE_VAR or $tname eq T_INCLUDE or $tname eq T_WRAPPER) {
            my $filename;
            my $varstr;
            my $path = $self->get_path();
            my $dir;
            my $dynamic = $tname eq T_INCLUDE_VAR ? 1 : 0;
            my $fullpath = "''";

            my $cwd;
            unless ($self->get_scalar) {
                $dir      = dirname($fname);
                if ($self->get_search_path == 1) {
                }
                elsif ($self->get_search_path == 2) {
                    $cwd = $dir;
                }
                else {
                    $path = [ $dir ] ;
                }
            }
            if ($dynamic) {
                # dynamic filename
                my $dfilename = $attr->{NAME};
                if ($self->get_use_query) {
                    $info_stack->[-1]->{lc $dfilename}->{type} = $tname;
                }
                $varstr = $class->parse_var($self,
                    %var_args,
                    var   => $dfilename,
                    context => $token,
                    compiler => $class,
                    expr   => $attr->{EXPR},
                );
            }
            else {
                # static filename
                $filename = $attr->{NAME};
                $fullpath = $self->createFilename( [@$path], \$filename, $cwd );
                if ($self->get_use_query) {
                    $info_stack->[-1]->{lc $filename}->{type} = $tname;
                }
                $varstr   = $self->quote_file($filename);
                # generate included template
                {
                    D && $self->log("compile include $filename!!");
                    my $recursed = ++$HTML::Template::Compiled::COMPILE_STACK{$fullpath};
                    if ($recursed <= 1) {
                        my $cached_or_new;
                        $self->compile_early() and $cached_or_new
                            = $self->new_from_object(
                                #[@$path, \$self->get_file], $filename, '', $self->get_cache_dir
                              $path, $filename, '', $self->get_cache_dir
                          );
                        $self->get_includes()->{$fullpath}
                            = [$path, $filename, $cached_or_new];
                    }
                    --$HTML::Template::Compiled::COMPILE_STACK{$fullpath};
                    $fullpath = $self->quote_file($fullpath);
                }
            }
            #print STDERR "include $varstr\n";
            my $cache = $self->get_cache_dir;
            $path = defined $path
              ? '['
              . join( ',', map { $self->quote_file($_) } @$path ) . ']'
              : 'undef';
            $cwd = defined $cwd ? $self->quote_file($cwd) : 'undef';
            $cache = defined $cache ? $self->quote_file($cache) : 'undef';
            if ($dynamic) {
                $code .= <<"EOM";
# ---------- INCLUDE_VAR
\{
  if (defined (my \$file = $varstr)) \{
    my \$fullpath = \$t->createFilename( $path, \\\$file, $cwd );
    my \$recursed = ++\$HTML::Template::Compiled::FILESTACK{\$fullpath};
    \$HTML::Template::Compiled::FILESTACK{\$fullpath} = 0, die "HTML::Template: recursive include of " . \$fullpath . " \$recursed times (max \$HTML::Template::Compiled::MAX_RECURSE)"
      if \$recursed > \$HTML::Template::Compiled::MAX_RECURSE;
    my \$include = \$t->get_includes()->{\$fullpath};
    my \$new = \$include ? \$include->[2] : undef;
    if (!\$new || HTML::Template::Compiled::needs_new_check($cache||'',\$file,\$t->get_expire_time)) \{
      \$new = \$t->new_from_object($path,\$file,\$fullpath,$cache);
    \}
    $globalstack
    $output \$new->get_code()->(\$new,\$P,\$C@{[$out_fh ? ",\$OFH" : '']});
    --\$HTML::Template::Compiled::FILESTACK{\$fullpath} or delete \$HTML::Template::Compiled::FILESTACK{\$fullpath};
  \}
\}
EOM
            }
            elsif ($tname eq T_WRAPPER) {
                push @outputs, '$OUT' . (1 + scalar @outputs) . ' .= ';
                $output = $outputs[-1];
                my $wrapped = '';
                $code .= <<"EOM";
# ---------- WRAPPER
\{
  my \$OUT@{[ scalar @outputs ]};
EOM
                my $argument_fh = 'undef';
                if ($out_fh) {
                    $wrapped .= <<"EOM";
my \$tmp_var = '';
open my \$tmp_fh, '>', \\\$tmp_var;
EOM
                    $argument_fh = "\$tmp_fh";
                }
                $wrapped .= <<"EOM";
  my \$_WRAPPED = \$OUT@{[ scalar @outputs ]};
  my \$recursed = ++\$HTML::Template::Compiled::FILESTACK{$fullpath};
  \$HTML::Template::Compiled::FILESTACK{$fullpath} = 0, die "HTML::Template: recursive include of " . $fullpath . " \$recursed times (max \$HTML::Template::Compiled::MAX_RECURSE)"
  if \$recursed > \$HTML::Template::Compiled::MAX_RECURSE;
    my \$include = \$t->get_includes()->{$fullpath};
    my \$new = \$include ? \$include->[2] : undef;
    if (!\$new) {
      \$new = \$t->new_from_object($path,$varstr,$fullpath,$cache);
    }
    $globalstack
    $outputs[-2] \$new->get_code()->(\$new,\$P,\$C, $argument_fh, { wrapped => \$_WRAPPED });
    --\$HTML::Template::Compiled::FILESTACK{$fullpath} or delete \$HTML::Template::Compiled::FILESTACK{$fullpath};
  \$OUT@{[ scalar @outputs ]} = '';
EOM
                if ($out_fh) {
                    $wrapped .= <<"EOM";
$outputs[-2] \$tmp_var;
EOM
                }
                $wrapped .= <<"EOM";
\}
EOM
                push @wrapped, $wrapped;
            }
            else {
                $code .= <<"EOM";
# ---------- INCLUDE
\{
  my \$recursed = ++\$HTML::Template::Compiled::FILESTACK{$fullpath};
  \$HTML::Template::Compiled::FILESTACK{$fullpath} = 0, die "HTML::Template: recursive include of " . $fullpath . " \$recursed times (max \$HTML::Template::Compiled::MAX_RECURSE)"
  if \$recursed > \$HTML::Template::Compiled::MAX_RECURSE;
    my \$include = \$t->get_includes()->{$fullpath};
    my \$new = \$include ? \$include->[2] : undef;
    if (!\$new) {
      \$new = \$t->new_from_object($path,$varstr,$fullpath,$cache);
    }
    $globalstack
    $output \$new->get_code()->(\$new,\$P,\$C@{[$out_fh ? ",\$OFH" : '']});
    --\$HTML::Template::Compiled::FILESTACK{$fullpath} or delete \$HTML::Template::Compiled::FILESTACK{$fullpath};
\}
EOM
            }
        }
        else {
            # user defined
            #warn Data::Dumper->Dump([\$token], ['token']);
            #warn Data::Dumper->Dump([\$tags], ['tags']);
            my $subs = $tags->{$tname};
            if ($subs && $subs->{open}) {
                $code .= $subs->{open}->($self, $token, {
                        out => $output,
                });
            }
        }
        }
        elsif ($token->is_close) {
        # --------- / TMPL_IF TMPL UNLESS TMPL_WITH
        if ($tname =~ m/^(?:IF|UNLESS|WITH|IF_DEFINED)$/) {
            my $var = $attr->{NAME};
            $var = '' unless defined $var;
            #print STDERR "============ IF ($text)\n";
            $code .= "\}" ;
            if ($self->get_global_vars && $tname eq 'WITH') {
                $code .= qq{\n} . $indent . qq#\$t->popGlobalstack;\n#;
            }
            $code .= ($tname eq 'WITH' ? "\}" : '') . qq{\n};
        }

        # --------- / TMPL_SWITCH
        elsif ($tname eq T_SWITCH) {
            if ( $switches[$#switches] ) {

                # we had at least one CASE, so we close the last if
                $code .= "\} # last case\n";
            }
            $code .= "\}\n";
            pop @switches;
        }
        
        # --------- / TMPL_LOOP TMPL_WHILE
        elsif ($tname eq T_LOOP || $tname eq T_WHILE || $tname eq T_EACH) {
            pop @lexicals;
            if ($self->get_use_query) {
                pop @$info_stack;
            }
            $code .= "\}";
            if ($self->get_global_vars) {
                $code .= qq{\n} . $indent . qq#\$t->popGlobalstack;\n#;
            }
            $code .= "\} # end loop\n";
        }
        elsif ($tname eq T_WRAPPER) {
            $code .= $wrapped[-1];
            pop @wrapped;
pop @outputs;
$output = $outputs[-1];
            $code .= <<"EOM";
EOM
        }
        else {
            # user defined
            #warn Data::Dumper->Dump([\$token], ['token']);
            #warn Data::Dumper->Dump([\$tags], ['tags']);
            my $subs = $tags->{$tname};
            if ($subs && $subs->{close}) {
                $code .= $subs->{close}->($self, $token, {
                        out => $output,
                });
            }
        }
        }

    }
    if ($self->get_use_query) {
        $self->set_parse_tree($info);
    }
    my @use_vars = grep length, keys %use_vars;
    if (@use_vars) {
#        $header .= qq#use vars qw/ @{[ map { '$_lexi_'.$_ } @use_vars ]} /;\n#;
    }
    #warn Data::Dumper->Dump([\$info], ['info']);
    $code .= qq#return \$OUT;\n#;
    $code = $header . $code . "\n} # end of sub\n";

    #$code .= "\n} # end of sub\n";
    print STDERR "# ----- code \n$code\n# end code\n" if $self->get_debug->{options} & HTML::Template::Compiled::DEBUG_COMPILED();

    # untaint code
    if ( $code =~ m/(\A.*\z)/ms ) {
        # we trust our template
        $code = $1;
    }
    else {
        $code = "";
    }
    my $l = length $code;
    #print STDERR "length $fname: $l\n";
    my $sub = eval $code;
    #die "code: $@ ($code)" if $@;
    die "code: $@" if $@;
    return $code, $sub;
}
sub _compile_OPEN_VAR {
    my ($self, $htc, $args) = @_;
    #print STDERR "===== VAR ($text)\n";
    my $token = $args->{context};
    my $attr = $token->get_attributes;
    my $var = $attr->{NAME};
    #my $expr = $attr->{EXPR};
    my $expr;

    my $varstr = $self->parse_var($htc,
        %$args,
        var   => $var,
        context => $token,
        compiler => $self,
        expr   => $attr->{EXPR},
    );

    #print "line: $text var: $var ($varstr)\n";
    my $exp = $varstr;
    # ---- default
    my $default;
    if (defined $attr->{DEFAULT}) {
        $default = $self->dump_string($attr->{DEFAULT});
        $exp = _expr_ternary(
            _expr_defined($exp),
            $exp,
            $default,
        )->to_string;
    }
    # ---- escapes
    my $escape = $htc->get_default_escape;
    if (exists $attr->{ESCAPE}) {
        $escape = $attr->{ESCAPE};
    }
    $exp = $self->_escape_expression($exp, $escape) if $escape;
    return $exp;
}

sub _compile_OPEN_IF {
    my ($self, $htc, $args) = @_;
    #print STDERR "============ IF ($text)\n";
    my $var = $args->{context}->get_attributes->{NAME};
    my $token = $args->{context};
    my $attr = $token->get_attributes;
    my $varstr = $self->parse_var($htc,
        %$args,
        var   => $var,
        compiler => $self,
        expr   => $attr->{EXPR},
    );
    return "if ($varstr) \{";
}
sub _compile_OPEN_UNLESS {
    my ($self, $htc, $args) = @_;
    #print STDERR "============ IF ($text)\n";
    my $var = $args->{context}->get_attributes->{NAME};
    my $token = $args->{context};
    my $attr = $token->get_attributes;
    my $varstr = $self->parse_var($htc,
        %$args,
        var   => $var,
        compiler => $self,
        expr   => $attr->{EXPR},
    );
    return "unless ($varstr) \{";
}
sub _compile_OPEN_IF_DEFINED {
    my ($self, $htc, $args) = @_;
    #print STDERR "============ IF ($text)\n";
    my $var = $args->{context}->get_attributes->{NAME};
    my $token = $args->{context};
    my $attr = $token->get_attributes;
    my $varstr = $self->parse_var($htc,
        %$args,
        var   => $var,
        compiler => $self,
        expr   => $attr->{EXPR},
    );
    return "if (defined ($varstr)) \{";
}

1;

__END__

=pod

=head1 NAME

HTML::Template::Compiled::Compiler - Compiler class for HTC

=cut

