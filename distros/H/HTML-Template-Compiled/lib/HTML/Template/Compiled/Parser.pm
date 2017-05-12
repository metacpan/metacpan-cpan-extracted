package HTML::Template::Compiled::Parser;
use Carp qw(croak carp confess);
use strict;
use warnings;
use base qw(Exporter);
use HTML::Template::Compiled::Token qw(:tagtypes);
use Scalar::Util;
our $VERSION = '1.003'; # VERSION
my @vars;
BEGIN {
@vars = qw(
    $CASE_SENSITIVE_DEFAULT
    $NEW_CHECK
    $ENABLE_SUB
    $DEBUG_DEFAULT
    $SEARCHPATH
    %FILESTACK %COMPILE_STACK %PATHS $DEFAULT_ESCAPE $DEFAULT_QUERY
    $UNTAINT $DEFAULT_TAGSTYLE $MAX_RECURSE
);
}
our @EXPORT_OK = @vars;
use vars @vars;
$MAX_RECURSE = 10;

$NEW_CHECK              = 60 * 10; # 10 minutes default
$DEBUG_DEFAULT          = 0;
$CASE_SENSITIVE_DEFAULT = 1; # set to 0 for H::T compatibility
$ENABLE_SUB             = 0;
$SEARCHPATH             = 0;
$DEFAULT_ESCAPE         = 0;
$UNTAINT                = 0;
$DEFAULT_QUERY          = 0;
$DEFAULT_TAGSTYLE       = [qw(classic comment asp)];

use constant ATTR_TAGSTYLE   => 0;
use constant ATTR_TAGNAMES   => 1;
use constant ATTR_PERL       => 2;
use constant ATTR_EXPRESSION => 3;
use constant ATTR_CHOMP      => 4;
use constant ATTR_STRICT     => 5;

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
use constant T_INCLUDE_VAR => 'INCLUDE_VAR';

use constant CHOMP_NONE     => 0;
use constant CHOMP_ONE      => 1;
use constant CHOMP_COLLAPSE => 2;
use constant CHOMP_GREEDY   => 3;

# under construction (sic!)
sub new {
    my $class = shift;
    my %args = @_;
    my $self = [];
    bless $self, $class;
    $self->init(%args);
    $self;
}

sub set_tagstyle { $_[0]->[ATTR_TAGSTYLE] = $_[1] }
sub get_tagstyle { $_[0]->[ATTR_TAGSTYLE] }

sub set_tagnames { $_[0]->[ATTR_TAGNAMES] = $_[1] }
sub get_tagnames { $_[0]->[ATTR_TAGNAMES] }

sub set_perl   { $_[0]->[ATTR_PERL] = $_[1] }
sub get_perl   { $_[0]->[ATTR_PERL] }

sub set_expressions { $_[0]->[ATTR_EXPRESSION] = $_[1] }
sub get_expressions { $_[0]->[ATTR_EXPRESSION] }

sub set_chomp { $_[0]->[ATTR_CHOMP] = $_[1] }
sub get_chomp { $_[0]->[ATTR_CHOMP] }

sub set_strict { $_[0]->[ATTR_STRICT] = $_[1] }
sub get_strict { $_[0]->[ATTR_STRICT] }

sub add_tagnames {
    my ($self, $hash) = @_;
    my $open = $hash->{OPENING_TAG()};
    my $close = $hash->{CLOSING_TAG()};
    @{ $_[0]->[ATTR_TAGNAMES]->{OPENING_TAG()} }{keys %$open} = values %$open;
    @{ $_[0]->[ATTR_TAGNAMES]->{CLOSING_TAG()} }{keys %$close} = values %$close;
}

sub remove_tags {
    my ($self, @tags) = @_;
    my $open = $self->[ATTR_TAGNAMES]->{OPENING_TAG()};
    my $close = $self->[ATTR_TAGNAMES]->{CLOSING_TAG()};
    delete @$open{@tags};
    delete @$close{@tags};
}

my $_default_tags = {
    classic => ['<TMPL_'      ,'>',     '</TMPL_',      '>',  ],

    comment => ['<!--\s*TMPL_','\s*-->','<!--\s*/TMPL_','\s*-->',],

    asp     => ['<%'          ,'%>',    '<%/',          '%>',   ],

    php     => ['<\?'         ,'\?>',    '<\?/',          '\?>', ],

    tt      => ['\[%'         ,'%\]',   '\[%/',         '%\]'  , ],
};
sub default_tags {
    return $_default_tags;
}

my $default_validation = sub {
    my ($p, $attr) = @_;
    my $test = $p->get_expressions;
    exists $attr->{NAME} or
    ($p->get_expressions and exists $attr->{EXPR})
};
my %allowed_tagnames = (
    OPENING_TAG() => {
        VAR         => [$default_validation, qw(NAME ESCAPE DEFAULT EXPR)],
        # just an alias for VAR
        '='         => [$default_validation, qw(NAME ESCAPE DEFAULT EXPR)],
        IF_DEFINED  => [$default_validation, qw(NAME EXPR)],
        IF          => [$default_validation, qw(NAME EXPR)],
        UNLESS      => [$default_validation, qw(NAME EXPR)],
        ELSIF       => [$default_validation, qw(NAME EXPR)],
        ELSE        => [undef, qw(NAME)],
        WITH        => [$default_validation, qw(NAME EXPR)],
        COMMENT     => [undef, qw(NAME)],
        VERBATIM    => [undef, qw(NAME)],
        NOPARSE     => [undef, qw(NAME)],
        LOOP        => [$default_validation, qw(NAME ALIAS JOIN BREAK EXPR CONTEXT)],
        WHILE       => [$default_validation, qw(NAME ALIAS BREAK EXPR)],
        EACH        => [$default_validation, qw(NAME BREAK EXPR SORT SORTBY REVERSE CONTEXT)],
        SWITCH      => [$default_validation, qw(NAME EXPR)],
        CASE        => [undef, qw(NAME)],
        INCLUDE_VAR => [$default_validation, qw(NAME EXPR)],
        INCLUDE_STRING => [$default_validation, qw(NAME EXPR)],
        INCLUDE     => [$default_validation, qw(NAME)],
        USE_VARS    => [$default_validation, qw(NAME)],
        SET_VAR     => [$default_validation, qw(NAME VALUE EXPR)],
        WRAPPER     => [$default_validation, qw(NAME)],
    },
    CLOSING_TAG() => {
        IF_DEFINED  => [undef, qw(NAME)],
        IF          => [undef, qw(NAME)],
        UNLESS      => [undef, qw(NAME)],
        ELSIF       => [undef, qw(NAME)],
        WITH        => [undef, qw(NAME)],
        COMMENT     => [undef, qw(NAME)],
        VERBATIM    => [undef, qw(NAME)],
        NOPARSE     => [undef, qw(NAME)],
        LOOP        => [undef, qw(NAME)],
        WHILE       => [undef, qw(NAME)],
        EACH        => [undef, qw(NAME)],
        SWITCH      => [undef, qw(NAME)],
        WRAPPER     => [undef, qw(NAME)],
    }
);


sub init {
    my ( $self, %args ) = @_;
    my $tagnames = $args{tagnames} || {};
    my $tagstyle = $self->_create_tagstyle( $args{tagstyle} );
    $self->[ATTR_TAGSTYLE] = $tagstyle;
    $self->[ATTR_EXPRESSION] = $args{use_expressions};
    $self->[ATTR_CHOMP] = $args{chomp};
    $self->[ATTR_STRICT] = $args{strict};
    $self->[ATTR_TAGNAMES] = {
        OPENING_TAG() => {
            %{ $allowed_tagnames{ OPENING_TAG() } },
            %{ $tagnames->{ OPENING_TAG() }||{} },
        },
        CLOSING_TAG() => {
            %{ $allowed_tagnames{ CLOSING_TAG() } },
            %{ $tagnames->{ CLOSING_TAG() }||{} },
        },
    };
} ## end sub init

sub _create_tagstyle {
    my ($self, $tagstyle_def) = @_;
    $tagstyle_def ||= [];
    my $tagstyle;
    my $named_styles = {
        map {
            ($_ => $self->default_tags->{$_})
        } @$DEFAULT_TAGSTYLE
    };
    for my $def (@$tagstyle_def) {
        if (ref $def eq 'ARRAY' && @$def == 4) {
            # we got user defined regexes
            push @$tagstyle, $def;
        }
        elsif (!ref $def) {
            # strings
            if ($def =~ m/^-(.*)/) {
                # deactivate style
                delete $named_styles->{"$1"};
            }
            elsif ($def =~ m/^\+?(.*)/) {
                # activate style
                $named_styles->{"$1"} = $self->default_tags->{"$1"};
            }
        }
    }
    push @$tagstyle, values %$named_styles;
    return $tagstyle;
}

sub find_start_of_tag {
    my ($self, $arg) = @_;
    my $re = $arg->{start_close_re};
    if ($arg->{template} =~ s/^($re)//) {
        my %open_close_map = %{$arg->{open_close_map}};
        # $open contains <TMPL_ or <% or </TMPL_...
        $arg->{open} = $1;
        $arg->{token} .= $1;
        # check which type of tag we got
        TYPES: for my $key (keys %open_close_map) {
            #print STDERR "try $key '$arg->{open}'\n";
            if ($arg->{open} =~ m/^$key$/i) {
                my $val = $open_close_map{$key};
                $arg->{close_match} = $val->[1];
                $arg->{open_or_close} = $val->[0];
                #print STDERR "=== tag type $key, searching for $arg->{close_match}\n";
                last TYPES;
            }
        }
        #print STDERR "got start_close_re\n";
        return 1;
    }
    else {
        return;
    }
}

sub find_attributes {
    my ($self, $arg) = @_;
    #warn Data::Dumper->Dump([\%args], ['args']);
    my $allowed = [@{ $arg->{allowed_names} }, 'PRE_CHOMP', 'POST_CHOMP'];
    my $attr    = $arg->{attr};
    my $fname   = $arg->{fname};
    my $line    = $arg->{line};

    my ($validate_sub, @allowed) = @$allowed;
    my $allowed_names = [ sort {
        length($b) <=> length($a)
    } @allowed ];
    my $re = join '|', @$allowed_names;
    ATTR: while (1) {
        last if $arg->{template} =~ m/^($arg->{close_match})/;
        my ($name, $val, $orig) = $self->find_attribute( $arg, $re );
        last unless defined $name;
        my $key = uc $name;
        if ($key =~ m/^(?:PRE|POST)_CHOMP\z/ and $val !~ m/^(?:0|1|2|3)\z/) {
            $self->_error_wrong_tag_syntax(
                $arg,
                $orig.$arg->{template}, '(PRE|POST)_CHOMP=(0|1|2|3)',
            );
        }
        if (exists $attr->{$key}) {
            $self->_error_wrong_tag_syntax(
                $arg,
                $orig.$arg->{template}, 'duplicate attribute',
            );
        }
        $attr->{$key} = $val;
        $arg->{token} .= $orig;
    }
    my $ok = $validate_sub ? $validate_sub->($self, $attr) : 1;
    $self->_error_wrong_tag_syntax(
        $arg, $arg->{template}
    ) unless $ok;
    return $ok;
}

{
    my $callbacks_found_text;
    my $encode_tag = sub {
        my ( $p, $arg ) = @_;
        $arg->{token} = HTML::Template::Compiled::Utils::escape_html($arg->{token});
        $callbacks_found_text->[0]->($p, $arg);
        $arg->{token} = "";
    };

    my $ignore_tag = sub {
        my ( $p, $arg ) = @_;
        $arg->{token} = "";
    };
    my $default_callback_text = sub {
        my ($self, $arg) = @_;
        $arg->{line} += $arg->{token} =~ tr/\n//;
        #print STDERR "we found text: '$arg->{token}}'\n";
        push @{$arg->{tags}},
        HTML::Template::Compiled::Token::Text->new([
            $arg->{token}, $arg->{line},
            undef, undef, undef, $arg->{fname}, $arg->{level}
        ]);
        $arg->{token} = "";
    };
    my $default_callback_tag = sub {
        my ($self, $arg) = @_;
        #print STDERR "####found tag $arg->{name}, $arg->{open_or_close}\n";
        $arg->{line} += $arg->{token} =~ tr/\n//;
        my $class = 'HTML::Template::Compiled::Token::' .
            ($arg->{open_or_close} == OPENING_TAG
                ? 'open'
                : 'close');

        my $token = $class->new([
            $arg->{token}, $arg->{line},
            [$arg->{open}, $arg->{close}], $arg->{name},
            { %{ $arg->{attr} } },
            $arg->{fname}, $arg->{level},
        ]);
        push @{$arg->{tags}}, $token;
        if ($token->is_open &&
            exists
                $self->get_tagnames->{CLOSING_TAG()}->{ $arg->{name} }) {
            $arg->{level}++
        }
        elsif ($token->is_close) {
            $arg->{level}--
        }
        $self->checkstack( $arg );
        $arg->{token} = "";
    };
    $callbacks_found_text = [ $default_callback_text ];

    sub parse {
        my ($self, $fname, $template) = @_;
        my $tagnames = $self->get_tagnames;
        my %allowed_ident;
        $allowed_ident{OPENING_TAG()} = "(?i:" . join("|", sort {
            length $b <=> length $a
        } keys %{ $tagnames->{OPENING_TAG()} }) . ")";
        $allowed_ident{CLOSING_TAG()} = "(?i:" . join("|", sort {
            length $b <=> length $a
        } keys %{ $tagnames->{CLOSING_TAG()} }) . ")";
        my $tagstyle = $self->get_tagstyle;
        # make (?i:IF_DEFINED|LOOP|IF|=|...) out of the list of identifiers
        my $start_close_re = '(?i:' . join("|", sort {
                length($b) <=> length($a)
            } map {
                $_->[0], $_->[2]
            } @$tagstyle) . ")";
        my $close_re = '(?i:' . join("|", sort {
                length($b) <=> length($a)
            } map {
                $_->[1], $_->[3]
            } @$tagstyle) . ")";
        my %open_close = map {
            (
                $_->[0] => [
                    OPENING_TAG, $_->[1]
                ],
                $_->[2] => [
                    CLOSING_TAG, $_->[3]
                ],
            ),
        } @$tagstyle;

        my $comment_info;
        my $callback_found_tag = [ $default_callback_tag ];

        my $callback = sub {
            my ( $p, $arg ) = @_;
            my $name = $arg->{name};
            #print STDERR "callback found tag $name\n";
            if ( $name eq 'COMMENT' ) {
                if ( $arg->{open_or_close} == OPENING_TAG ) {
                    ++$comment_info->{$name} == 1
                        and push @$callbacks_found_text, $ignore_tag;
                }
                elsif ( $arg->{open_or_close} == CLOSING_TAG ) {
                    --$comment_info->{$name} == 0
                        and pop @$callbacks_found_text;
                }
                $arg->{token} = "";
            }
            elsif ( $comment_info->{COMMENT} ) {
                $arg->{token} = "";
            }
            elsif ($name eq 'NOPARSE') {
                if ( $arg->{open_or_close} == OPENING_TAG ) {
                    if (++$comment_info->{$name} == 1) {
                        $arg->{token} = "";
                    }
                    else {
                        $callbacks_found_text->[0]->(@_);
                    }
                }
                elsif ( $arg->{open_or_close} == CLOSING_TAG ) {
                    if (--$comment_info->{$name} == 0) {
                        $arg->{token} = "";
                    }
                    else {
                        $callbacks_found_text->[0]->(@_);
                    }
                }
            }
            elsif ( $comment_info->{NOPARSE} ) {
                $callbacks_found_text->[0]->(@_);
            }
            elsif ($name eq 'VERBATIM') {
                if ( $arg->{open_or_close} == OPENING_TAG ) {
                    if (++$comment_info->{$name} == 1) {
                        $arg->{token} = "";
                    }
                    else {
                        $encode_tag->(@_);
                    }
                }
                elsif ( $arg->{open_or_close} == CLOSING_TAG ) {
                    if (--$comment_info->{$name} == 0) {
                        $arg->{token} = "";
                    }
                    else {
                        $encode_tag->(@_);
                    }
                }
            }
            elsif ( $comment_info->{VERBATIM} ) {
                $encode_tag->(@_);
            }
            else {
                $callback_found_tag->[-2]->(@_);
            }
        };
        push @$callback_found_tag, $callback;

        my $arg = {
            fname          => $fname,
            level          => 0,
            line           => 1,
            name           => '',
            template       => $template,
            token          => '',
            open_or_close  => undef,
            open           => undef,
            open_close_map => \%open_close,
            start_close_re => qr{$start_close_re},
            close_match    => qr{close_re},
            attr           => {},
            allowed_names => [],
            tags      => [],
            close     => undef,
            stack     => [T_END],
        };
        while (length $arg->{template}) {
            #warn Data::Dumper->Dump([\@tags], ['tags']);
            #print STDERR "TEXT: $template ($start_close_re)\n";
            #print STDERR "TOKEN: '$arg->{token}'\n";
            my $found_tag = 0;
            $arg->{attr} = {};
            MATCH_TAGS: {
                last MATCH_TAGS unless $self->find_start_of_tag($arg);
                # at this point we have a start of a tag. everything
                # that does not look like correct tag content generates
                # a die!
                my $re = $allowed_ident{$arg->{open_or_close}};
                if ($arg->{template} =~ s/^(($re)\s*)//) {
                    $arg->{name} = uc $2;
                    $arg->{token} .= $1;
                    if ($arg->{name} eq '=') { $arg->{name} = 'VAR' }
                }
                elsif ($comment_info->{NOPARSE}) {
                    $callbacks_found_text->[0]->($self, $arg);
                    last MATCH_TAGS;
                }
                elsif ($comment_info->{VERBATIM}) {
                    $encode_tag->($self, $arg);
                    last MATCH_TAGS;
                }
                elsif ($comment_info->{COMMENT}) {
                    last MATCH_TAGS;
                }
                elsif ($self->get_strict) {
                        $self->_error_wrong_tag_syntax(
                            $arg, $arg->{template}, "Unknown tag"
                        );
                        last MATCH_TAGS;
                }
                else {
                    $arg->{template} =~ s/^(\w+)//;
                    $arg->{token} .= $1;
                    $callbacks_found_text->[0]->($self, $arg);
                    last MATCH_TAGS;
                }
                #print STDERR "got ident $arg->{name} ('$arg->{template}')\n";
                $arg->{allowed_names}
                    = $tagnames->{ $arg->{open_or_close} }->{ $arg->{name} };
                if ($arg->{name} eq 'PERL' && $self->get_perl) {
                    last MATCH_TAGS unless $self->find_perlcode($arg);
                }
                else {
                    last MATCH_TAGS unless $self->find_attributes($arg);
                }

                if ($arg->{template} =~ s/^($arg->{close_match})//) {
                    $arg->{close} = $1;
                    $arg->{token} .= $1;
                }
                else {
                    $self->_error_wrong_tag_syntax( $arg, "" );
                    last MATCH_TAGS;
                }
                $found_tag = 1;
            }
            if ($found_tag) {
                my $pre_chomp = $self->get_chomp->[0];
                my $attr = $arg->{attr};
                $pre_chomp = $attr->{PRE_CHOMP} if exists $attr->{PRE_CHOMP};
                my $post_chomp = $self->get_chomp->[1];
                $post_chomp = $attr->{POST_CHOMP} if exists $attr->{POST_CHOMP};
                if (@{$arg->{tags}} > 0 and $pre_chomp) {
                    my $text = $arg->{tags}->[-1]->get_text;
                    if ($pre_chomp == CHOMP_ONE) {
                        $text =~ s/ +\z//;
                    }
                    elsif ($pre_chomp == CHOMP_COLLAPSE) {
                        $text =~ s/\s+\z/ /;
                    }
                    elsif ($pre_chomp == CHOMP_GREEDY) {
                        $text =~ s/\s+\z//;
                    }
                    $arg->{tags}->[-1]->set_text($text);
                }
                if (length $arg->{template} and $post_chomp) {
                    if ($post_chomp == CHOMP_ONE) {
                        $arg->{template} =~ s/^ +//;
                    }
                    elsif ($post_chomp == CHOMP_COLLAPSE) {
                        $arg->{template} =~ s/^\s+/ /;
                    }
                    elsif ($post_chomp == CHOMP_GREEDY) {
                        $arg->{template} =~ s/^\s+//;
                    }
                }
                #print STDERR "found tag $arg->{name}\n";
                #my $test = $callback_found_tag->[-1];
                #print STDERR "(found_tags: @$callback_found_tag) $test\n";
                ( $callback_found_tag->[-1] || sub { } )->(
                    $self,
                    $arg,
                );
                #print STDERR "===== ($open, $line, $ident, $close)\n";
                #warn Data::Dumper->Dump([\@tags], ['tags']);
            }
            elsif ($arg->{template} =~ s/^(.+?)(?=($start_close_re|\Z))//s) {
                $arg->{token} .= $1;
                ($callbacks_found_text->[-1] || sub {} )->(
                    $self,
                    $arg,
                );
                #print "got no tag: '$arg->{token}'\n";
            }

        }
        Scalar::Util::weaken($callback_found_tag);
        $self->checkstack({
                %$arg, name => T_END, open_or_close => CLOSING_TAG
            } );
        return @{$arg->{tags} };
    }
}

use HTML::Template::Compiled::Exception;
sub _error_wrong_tag_syntax {
    my ($self, $arg, $text, $add_info) = @_;
    my ($substr) = $text =~ m/^(.{0,10})/s;
    my $class = ref $self || $self;
    my $info = "$class : Syntax error in <TMPL_*> tag at $arg->{fname} :"
        . "$arg->{line} near '$arg->{token}$substr...'";
    $info .= " $add_info" if defined $add_info;
    my $ex = HTML::Template::Compiled::Exception->new(
        text => $info,
        parser => $self,
        tokens => $arg->{tags},
        near => $text,
    );
    croak $ex;
}

sub find_perlcode {
    my ($self, $arg) = @_;
    my $attr    = $arg->{attr};
    if ($arg->{template} =~ s{^ (.*?)
            (?=$arg->{close_match})
        }{}xs) {
        $attr->{PERL} = "$1";
        $arg->{token} .= $1;
        return 1;
    }
    return;
}

sub find_attribute {
    my ($self, $arg, $re) = @_;
    my ($name, $var, $orig);
    #print STDERR "=====(($arg->{template}))\n";
    if ($arg->{template} =~ s/^(\s*($re)=)//i) {
        $name = "$2";
        $orig .= $1;
    }
    #print STDERR "match '$$text' (?=$until|\\s)\n";
    if ($arg->{template} =~ s{^ (\s* (['"]) (.+?) \2 \s*) }{}x) {
        #print STDERR qq{matched $2$3$2\n};
        $var = "$3";
        $orig .= $1;
    }
    elsif ($arg->{template} =~ s{^ (\s* (\S+?) \s*)
            (?=$arg->{close_match} | \s) }{}x) {
        #print STDERR qq{matched <$2>\n};
        $var = "$2";
        $orig .= $1;
    }
    else { return }
    unless (defined $name) {
        $name = "NAME";
    }
    return ($name, $var, $orig);
}

{
    my @map;
    $map[OPENING_TAG] = {
        ELSE       => [ T_IF, T_UNLESS, T_ELSIF, T_IF_DEFINED ],
        T_CASE()   => [T_SWITCH],
    };
    $map[CLOSING_TAG] = {
        IF         => [ T_IF, T_UNLESS, T_ELSE, T_IF_DEFINED ],
        T_IF_DEFINED() => [ T_ELSE, T_IF_DEFINED ],
        UNLESS     => [T_UNLESS, T_ELSE, T_IF_DEFINED],
        ELSIF      => [ T_IF, T_UNLESS, T_IF_DEFINED ],
        LOOP       => [T_LOOP],
        WHILE      => [T_WHILE],
        WITH       => [T_WITH],
        T_SWITCH() => [T_SWITCH],
        T_END()    => [T_END],
    };

    sub validate_stack {
        my ( $self, $arg ) = @_;
        if (defined( my $allowed
                = $map[$arg->{open_or_close}]->{$arg->{name}})) {
            return 1 if @{ $arg->{stack} } == 0 and @$allowed == 0;
            die "Closing tag 'TMPL_$arg->{name}' does not have opening tag"
                . "at $arg->{fname} line $arg->{line}\n"
                unless @{ $arg->{stack} };
            if ( $allowed->[0] eq T_END and $arg->{stack}->[-1] ne T_END ) {
                # we hit the end of the template but still have an opening tag to close
                die "Missing closing tag for '$arg->{stack}->[-1]' at"
                    . "end of $arg->{fname} line $arg->{line}\n";
            }
            for (@$allowed) {
                return 1 if $_ eq $arg->{stack}->[-1];
            }
            croak "'TMPL_$arg->{name}' does not match opening tag ($arg->{stack}->[-1])"
            . "at $arg->{fname} line $arg->{line}\n";
        }
    }

    sub checkstack {
        my ( $self, $arg ) = @_;
        my $ok = $self->validate_stack($arg );
        if ($arg->{open_or_close} == OPENING_TAG) {
            if (
                grep { $arg->{name} eq $_ } (
                    T_WITH, T_LOOP, T_WHILE, T_IF, T_UNLESS, T_SWITCH, T_IF_DEFINED
                )
                ) {
                push @{ $arg->{stack} }, $arg->{name};
            }
            elsif ($arg->{name} eq T_ELSE) {
                pop @{ $arg->{stack} };
                push @{ $arg->{stack} }, T_ELSE;
            }
        }
        elsif ($arg->{open_or_close} == CLOSING_TAG) {
            if (grep { $arg->{name} eq $_ } (
                    T_IF, T_IF_DEFINED, T_UNLESS, T_WITH, T_LOOP, T_WHILE, T_SWITCH
                )) {
                pop @{ $arg->{stack} };
            }
        }
        return $ok;
    }

}

{
    my $default_parser = __PACKAGE__->new;
    sub default { return bless [@$default_parser], __PACKAGE__ }
}

1;

__END__

=pod

=head1 NAME

HTML::Template::Compiled::Parser - Parser module for HTML::Template::Compiled

=head1 SYNOPSIS

This module is used internally by HTML::Template::Compiled. The API is
not fixed (yet), so this is just for understanding at the moment.

    my $parser = HTML::Template::Compiled::Parser->new(
        tagstyle => [
            # -name deactivates style
            # +name activates style
            qw(-classic -comment +asp +php),
            # define own regexes
            # e.g. for tags like
            # {{if foo}}{{var bar}}{{/if foo}}
            [
            qr({{), start of opening tag
            qr(}}), # end of opening tag
            qr({{/), # start of closing tag
            qr(}}), # end of closing tag
            ],
        ],
    );

=head1 AUTHOR

Tina Mueller


=cut


