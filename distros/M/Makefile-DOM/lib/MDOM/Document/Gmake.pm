package MDOM::Document::Gmake;

use strict;
use warnings;

#use Smart::Comments;
#use Smart::Comments '###', '####';

use Text::Balanced qw( gen_extract_tagged );
use Makefile::DOM;
#use Data::Dump::Streamer;
use base 'MDOM::Node';
use List::MoreUtils qw( before all any );
use List::Util qw( first );

my %_map;
BEGIN {
    %_map = (
        COMMENT => 1,  # context for parsing multi-line comments
        COMMAND => 2,  # context for parsing multi-line commands
        RULE    => 3,  # context for parsing rules
        VOID    => 4,  # void context
        UNKNOWN => 5,  # context for parsing unexpected constructs
    );
}

use constant \%_map;

my %_rev_map = reverse %_map;

my @keywords = qw(
    vpath include sinclude
    ifdef ifndef else endif 
    define endef export unexport
);

my $extract_interp_1 = gen_extract_tagged('\$[(]', '[)]', '');
my $extract_interp_2 = gen_extract_tagged('\$[{]', '[}]', '');

sub extract_interp {
    my ($res) = $extract_interp_1->($_[0]);
    if (!$res) {
        ($res) = $extract_interp_2->($_[0]);
    }
    $res;
}

my ($context, $saved_context);

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    my $input = shift;
    return undef if !defined $input;
    my $in;
    if (ref $input) {
        open $in, '<', $input or die;
    } else {
        open $in, $input or
            die "Can't open $input for reading: $!";
    }
    my $self = $class->SUPER::new;
    $self->_tokenize($in);
    $self;
}

sub _tokenize {
    my ($self, $fh) = @_;
    $context = VOID;
    my @tokens;
    while (<$fh>) {
        ### Tokenizing : $_
        ### ...with context : $_rev_map{$context}
        s/\r\n/\n/g;
        $_ .= "\n" if !/\n$/s;
        if ($context == VOID || $context == RULE) {
            if ($context == VOID && s/(?x) ^ (\t\s*) (?= \# ) //) {
                ### Found comment in VOID context...
                @tokens = (
                    MDOM::Token::Whitespace->new($1),
                    _tokenize_comment($_)
                );
                if ($tokens[-1]->isa('MDOM::Token::Continuation')) {
                    ### Switching context to COMMENT...
                    $saved_context = $context;
                    $context = COMMENT;
                    $tokens[-2]->add_content("\\\n");
                    pop @tokens;
                }
                $self->__add_elements( @tokens );
            }
            elsif ($context == RULE and s/^\t//) {
                ### Found a command in RULE context...
                @tokens = _tokenize_command($_);
                #warn "*@tokens*";
                ### Tokens for the command: @tokens
                unshift @tokens, MDOM::Token::Separator->new("\t");
                if ($tokens[-1]->isa('MDOM::Token::Continuation')) {
                    ### Switching context to COMMAND...
                    $saved_context = $context;
                    $context = COMMAND;
                    pop @tokens;
                    if ($tokens[-1]->class =~ /Bare$/) {
                        $tokens[-1]->add_content("\\\n");
                    } else {
                        push @tokens, MDOM::Token::Bare->new("\\\n");
                    }
                }
                my $cmd = MDOM::Command->new;
                $cmd->__add_elements(@tokens);
                $self->__add_element($cmd);
                ### command (post): $cmd
                next;
            } else {
                @tokens = _tokenize_normal($_);
                if (@tokens >= 2 &&
                        $tokens[-1]->isa('MDOM::Token::Continuation') &&
                        $tokens[-2]->isa('MDOM::Token::Comment')) {
                    ### Found a trailing comment...
                    ### Switching conext to COMMENT...
                    $saved_context = $context;
                    $context = COMMENT;
                    $tokens[-2]->add_content("\\\n");
                    pop @tokens;
                    $self->__add_elements( _parse_normal(@tokens) );
                } elsif ($tokens[-1]->isa('MDOM::Token::Continuation')) {
                    ### Found a line continuation...
                    ### Switching context to UNKNOWN...
                    $saved_context = $context;
                    $context = UNKNOWN;
                } else {
                    ### Parsing it as a normal line...
                    $self->__add_elements( _parse_normal(@tokens) );
                }
            }
        } elsif ($context == COMMENT) {
            @tokens = _tokenize_comment($_);
            if ($tokens[-1]->isa('MDOM::Token::Continuation')) {
                ### Slurping one more continued comment line...
                $tokens[-2]->add_content("\\\n");
                pop @tokens;
                $self->last_token->add_content(join '', @tokens);
           } else {
                ### Completing comment slurping...
                ### Switching back to context: _state_str($saved_context)
                $context = $saved_context;
                my $last = pop @tokens;
                $self->last_token->add_content(join '', @tokens);
                $self->last_token->parent->__add_element($last);
           }
        } elsif ($context == COMMAND) {
            @tokens = _tokenize_command($_);
            ### more tokens for the cmd: @tokens
            if ($tokens[-1]->isa('MDOM::Token::Continuation')) {
                ### Slurping one more continued command line...
                $tokens[-2]->add_content("\\\n");
                pop @tokens;
                for my $token (@tokens) {
                    if ($token->class =~ /Interpolation/ or
                            $self->last_token->class =~ /Interpolation/) {
                        $self->last_token->parent->__add_element($token);
                    } else {
                        $self->last_token->add_content($token);
                    }
                }
          } else {
                ### Completing command slurping: @tokens
                ### Switching back to context: _state_str($saved_context)
                $context = RULE;
                my $last = pop @tokens;
                ### last_token: $self->last_token
                for my $token (@tokens) {
                    if ($token->class =~ /Interpolation/ or
                            $self->last_token->class =~ /Interpolation/) {
                        $self->last_token->parent->__add_element($token);
                    } else {
                        $self->last_token->add_content($token);
                    }
                }
                $self->last_token->parent->__add_element($last);
            }
        } elsif ($context == UNKNOWN) {
            push @tokens, _tokenize_normal($_);
            if (@tokens >= 2 && $tokens[-1]->isa('MDOM::Token::Continuation') &&
                    $tokens[-2]->isa('MDOM::Token::Comment')) {
                $context = COMMENT;
                $tokens[-2]->add_content("\\\n");
                pop @tokens;
                $self->__add_elements( _parse_normal(@tokens) );
            } elsif ($tokens[-1]->isa('MDOM::Token::Continuation')) {
                ### Do nothing here...stay in the UNKNOWN context...
            } else {
                $self->__add_elements( _parse_normal(@tokens) );
                $context = $saved_context;
            }
        } else {
            die "Unkown state: $context";
        }
    }
    if ($context != RULE && $context != VOID) {
        warn "unexpected end of input at line $.";
    }
}

sub _tokenize_normal {
    local $_ = shift;
    my @tokens;
    my $pending_token = '';
    my $next_token;
    ### TOKENIZING: $_
    while (1) {
        # "token = $pending_token";
        #warn pos;
        #warn '@tokens = ', _dump_tokens2(@tokens);
        if (/(?x) \G [\s\n]+ /gc) {
            $next_token = MDOM::Token::Whitespace->new($&);
            #push @tokens, $next_token;
        }
        elsif (/(?x) \G (?: :: | := | \?= | \+= | [=:;] )/gc) {
            $next_token = MDOM::Token::Separator->new($&);
        }
        elsif (/(?x) \G \| /gc) {
            # XXX This should be a separator...
            $next_token = MDOM::Token::Bare->new($&);
        }
        elsif (my $res = extract_interp($_)) {
            $next_token = MDOM::Token::Interpolation->new($res);
        }
        elsif (/(?x) \G \$. /gc) {
            $next_token = MDOM::Token::Interpolation->new($&);
        }
        elsif (/(?x) \G \\ ([\#\\\n:]) /gcs) {
            my $c = $1;
            if ($c eq "\n") {
                push @tokens, MDOM::Token::Bare->new($pending_token)
                    if $pending_token ne '';
                push @tokens, MDOM::Token::Continuation->new("\\\n");
                return @tokens;
            } else {
                $pending_token .= "\\$c";
            }
        }
        elsif (/(?x) \G (\# [^\n]*) \\ \n/sgc) {
            my $s = $1;
            push @tokens, MDOM::Token::Bare->new($pending_token) if $pending_token ne '';
            push @tokens, MDOM::Token::Comment->new($s);
            push @tokens, MDOM::Token::Continuation->new("\\\n");
            return @tokens;
        } elsif (/(?x) \G \# [^\n]* /gc) {
            $next_token = MDOM::Token::Comment->new($&);
        } elsif (/(?x) \G . /gc) {
            $pending_token .= $&;
        } else {
            last;
        }
        if ($next_token) {
            if ($pending_token ne '') {
                push @tokens, MDOM::Token::Bare->new($pending_token);
                $pending_token = '';
            }
            push @tokens, $next_token;
            $next_token = undef;
        }
    }
    ### parse_normal result: @tokens
    @tokens;
}

sub _tokenize_command {
    my $s = shift;
    my @tokens;
    my $pending_token = '';
    my $next_token;
    my $strlen = length $s;
    while ($s =~ /(?x) \G (\s*) ([\@+\-]) /gc) {
        my ($whitespace, $modifier) = ($1, $2);
        if ($whitespace) {
            push @tokens, MDOM::Token::Whitespace->new($whitespace);
        }
        push @tokens, MDOM::Token::Modifier->new($modifier);
    }
    while (1) {
        my $last = 0;
        if ($s =~ /(?x) \G \n /gc) {
            $next_token = MDOM::Token::Whitespace->new("\n");
            #push @tokens, $next_token;
        }
        elsif (my $res = extract_interp($s)) {
            $next_token = MDOM::Token::Interpolation->new($res);
        }
        elsif ($s =~ /(?x) \G \$. /gc) {
            $next_token = MDOM::Token::Interpolation->new($&);
        }
        elsif ($s =~ /(?x) \G \\ ([\#\\\n:]) /gcs) {
            my $c = $1;
            if ($c eq "\n" && pos $s == $strlen) {
                $next_token = MDOM::Token::Continuation->new("\\\n");
            } else {
                $pending_token .= "\\$c";
            }
        }
        elsif ($s =~ /(?x) \G . /gc) {
            $pending_token .= $&;
        } else {
            $last = 1;
        }
        if ($next_token) {
            if ($pending_token) {
                push @tokens, MDOM::Token::Bare->new($pending_token);
                $pending_token = '';
            }
            push @tokens, $next_token;
            $next_token = undef;
        }
        last if $last;
    }
    if ($pending_token) {
        push @tokens, MDOM::Token::Bare->new($pending_token);
        $pending_token = '';
    }
    @tokens;
}

sub _tokenize_comment {
    local $_ = shift;
    my @tokens;
    my $pending_token = '';
    while (1) {
        if (/(?x) \G \n /gc) {
            push @tokens, MDOM::Token::Comment->new($pending_token) if $pending_token ne '';
            push @tokens, MDOM::Token::Whitespace->new("\n");
            return @tokens;
            #push @tokens, $next_token;
        }
        elsif (/(?x) \G \\ ([\\\n#:]) /gcs) {
            my $c = $1;
            if ($c eq "\n") {
                push @tokens, MDOM::Token::Comment->new($pending_token) if $pending_token ne '';
                push @tokens, MDOM::Token::Continuation->new("\\\n");
                return @tokens;
            } else {
                $pending_token .= "\\$c";
            }
        }
        elsif (/(?x) \G . /gc) {
            $pending_token .= $&;
        }
        else {
            last;
        }
    }
    @tokens;
}

sub _parse_normal {
    my @tokens = @_;
    ### fed to _parse_normal: @tokens
    my @sep = grep { $_->isa('MDOM::Token::Separator') } @tokens;
    #### Separators: @sep
    if (@tokens == 1) {
        return $tokens[0];
    }
    # filter out significant tokens:
    my ($fst, $snd) = grep { $_->significant } @tokens;
    my $is_directive;
    if ($fst) {
        if ($fst eq '-include') {
            $fst->set_content('include');
            unshift @tokens, MDOM::Token::Modifier->new('-');
            $is_directive = 1;
        }
        elsif ($fst eq 'override' && $snd && $snd eq 'define' ||
                _is_keyword($fst)) {
            $is_directive = 1;
        }
        if ($is_directive) {
            ##### Found directives...
            my $node = MDOM::Directive->new;
            $node->__add_elements(@tokens);
            return $node;
        }
    }
    if (@sep >= 2 && $sep[0] =~ /^::?$/ and $sep[1] eq ';') {
        #### Found simple rule with inlined command...
        my $rule = MDOM::Rule::Simple->new;
        my @t = before { $_ eq ';' } @tokens;
        $rule->__add_elements(@t);
        splice @tokens, 0, scalar(@t);

        my @prefix = shift @tokens;
        if ($tokens[0] && $tokens[0]->isa('MDOM::Token::Whitespace')) {
            push @prefix, shift @tokens;
        }

        @tokens = (@prefix, _tokenize_command(join '', @tokens));
        if ($tokens[-1]->isa('MDOM::Token::Continuation')) {
            $saved_context = $context;
            $context = COMMAND;
        }
        my $cmd = MDOM::Command->new;
        $cmd->__add_elements(@tokens);
        $rule->__add_elements($cmd);
        $saved_context = RULE;
        $context = RULE if $context == VOID;
        return $rule;
    }
    elsif (@sep >= 2 && $sep[0] eq ':' and $sep[1] =~ /^::?$/) {
        #### Found static pattern rule...
        my $rule = MDOM::Rule::StaticPattern->new;
        my @t = before { $_ eq ';' } @tokens;
        $rule->__add_elements(@t);
        splice @tokens, 0, scalar(@t);
        if (@tokens) {
            my @prefix = shift @tokens;
            if ($tokens[0] && $tokens[0]->isa('MDOM::Token::Whitespace')) {
                push @prefix, shift @tokens;
            }

            @tokens = (@prefix, _tokenize_command(join '', @tokens));
            if ($tokens[-1]->isa('MDOM::Token::Continuation')) {
                $saved_context = $context;
                $context = COMMAND;
            }
            my $cmd = MDOM::Command->new;
            $cmd->__add_elements(@tokens);
            $rule->__add_elements($cmd);
        }
        $saved_context = RULE;
        $context = RULE if $context == VOID;
        return $rule;
    }
    elsif (@sep == 1 && $sep[0] =~ /^::?$/) {
        #### Found simple rule without inlined command...
        my $rule = MDOM::Rule::Simple->new;
        $rule->__add_elements(@tokens);
        $saved_context = RULE;
        $context = RULE if $context == VOID;
        return $rule;
    }
    elsif (@sep && $sep[0] =~ /(?x) ^ (?: = | := | \+= | \?= ) $/) {
        my $assign = MDOM::Assignment->new;
        ### Assignment tokens: @tokens
        $assign->__add_elements(@tokens);
        $saved_context = VOID;
        $context = VOID if $context == RULE;
        return $assign;
    }
    elsif (all {
                $_->isa('MDOM::Token::Comment')    ||
                $_->isa('MDOM::Token::Whitespace') 
            } @tokens) {
        @tokens;
    }
    else {
        #### Found unkown token sequence: @tokens
        @tokens = _tokenize_command(join '', @tokens);
        my $node = MDOM::Unknown->new;
        $node->__add_elements(@tokens);
        $node;
    }
}

sub _dump_tokens {
    my @tokens = map { $_->clone } @_;
    warn "??? ", (join ' ',
        map { s/\\/\\\\/g; s/\n/\\n/g; s/\t/\\t/g; "[$_]" } @tokens
    ), "\n";
}

sub _state_str {
    $_rev_map{$saved_context}
}

sub _is_keyword {
    any { $_[0] eq $_ } @keywords;
}

1;

__END__

=encoding utf-8

=head1 NAME

MDOM::Gmake - Represents a GNU makefile for Makefile::DOM

=head1 DESCRIPTION

Represents a GNU Makefile.

=head1 METHODS

=head2 C<extract_interp>

Extract interpolated make variables like C<$(foo)> and C<${bar}>.

=head1 AUTHOR

Yichun "agentzh" Zhang (章亦春) E<lt>agentzh@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2006-2014 by Yichun "agentzh" Zhang (章亦春).

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<MDOM::Document>, L<MDOM::Document::Gmake>, L<PPI>, L<Makefile::Parser::GmakeDB>, L<makesimple>.

