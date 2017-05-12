package Markapl::TagHandlers;

use strict;
use warnings;
use Devel::Declare ();
use B::Hooks::EndOfScope;
use HTML::Entities;

our $VERSION = 0.03;

our ($Declarator, $Offset);

sub skip_declarator {
    $Offset += Devel::Declare::toke_move_past_token($Offset);
}

sub skipspace {
    $Offset += Devel::Declare::toke_skipspace($Offset);
}

sub strip_name {
    skipspace;
    if (my $len = Devel::Declare::toke_scan_word($Offset, 1)) {
        my $linestr = Devel::Declare::get_linestr();
        my $name = substr($linestr, $Offset, $len);
        substr($linestr, $Offset, $len) = '';
        Devel::Declare::set_linestr($linestr);
        return $name;
    }
    return;
}

sub strip_proto {
    skipspace;

    my $linestr = Devel::Declare::get_linestr();
    if (substr($linestr, $Offset, 1) eq '(') {
        my $length = Devel::Declare::toke_scan_str($Offset);
        my $proto = Devel::Declare::get_lex_stuff();
        Devel::Declare::clear_lex_stuff();
        $linestr = Devel::Declare::get_linestr();
        substr($linestr, $Offset, $length) = '';
        Devel::Declare::set_linestr($linestr);
        return $proto;
    }
    return;
}

sub shadow {
    my $pack = Devel::Declare::get_curstash_name;
    Devel::Declare::shadow_sub("${pack}::${Declarator}", $_[0]);
}

sub make_proto_unwrap {
    my ($proto) = @_;
    return (defined($proto) && length($proto)) ? "($proto);" : "";
}

sub inject_if_block {
    my $inject = shift;
    skipspace;
    my $linestr = Devel::Declare::get_linestr;
    if (substr($linestr, $Offset, 1) eq '{') {
        substr($linestr, $Offset+1, 0) = $inject;
        Devel::Declare::set_linestr($linestr);
    }
}

sub inject_before_block {
    my $inject = shift;
    skipspace;
    my $linestr = Devel::Declare::get_linestr;
    if (substr($linestr, $Offset, 1) eq '{') {
        substr($linestr, $Offset, 0) = $inject;
        Devel::Declare::set_linestr($linestr);
    }
}

sub inject_empty_block {
    my $inject = "{}";
    skipspace;
    my $linestr = Devel::Declare::get_linestr;
    if (substr($linestr, $Offset, 1) eq ';') {
        substr($linestr, $Offset, 0) = $inject;
        Devel::Declare::set_linestr($linestr);
    }
}

sub inject_scope {
    on_scope_end {
        my $linestr = Devel::Declare::get_linestr;
        my $offset = Devel::Declare::get_linestr_offset;
        substr($linestr, $offset, 0) = ';';
        Devel::Declare::set_linestr($linestr);
    };
}

my %alt = (
    'cell'      => 'td',
    'row'       => 'tr',
    'html_base' => 'base',
    'html_link' => 'link',
    'html_map'  => 'map',
    'html_q'    => 'q',
    'html_s'    => 's',
    'html_sub'  => 'sub',
    'html_tr'   => 'tr',
);

use String::BufferStack;

sub _tag {
    my ($tag, $attr, $block, $in_closure) = @_;

    my $original_buffer;

    if ($in_closure) {
        $original_buffer = Markapl->buffer;
        Markapl->buffer( String::BufferStack->new( out_method => sub { join("", @_) }) );
        Markapl->buffer->push;
    }

    if (grep { $tag eq $_ } Markapl::Tags->html_inline) {
        Markapl->buffer->append("<${tag}${attr}>");
    }
    else {
        Markapl->buffer->append("<${tag}${attr}>");
        Markapl->buffer->append(
            join '', map {
                ref($_) && $_->isa('Markapl::Tag') ? $_->() : ($_||"")
            } $block->()
        ) if defined $block && ref($block) eq 'CODE';
        Markapl->buffer->append("</$tag>");
    }

    if ($original_buffer) {
        my $output = Markapl->buffer->pop;
        Markapl->buffer($original_buffer);
        return $output;
    }

    return '';
}

sub tag_parser_for {
    my ($tag) = @_;
    $tag = $alt{$tag} if defined($alt{$tag});

    return sub {
        local ($Declarator, $Offset) = @_;

        my $offset_before = $Offset;
        skip_declarator;

        # This means that current declarator is in a hash key.
        # Don't shadow sub in this case
        return if $Offset == $offset_before;

        my $name = strip_name;
        my $proto = strip_proto;

        inject_if_block("BEGIN { Markapl::TagHandlers::inject_scope };");
        inject_empty_block;

        if (defined($proto)) {
            inject_before_block("$proto, sub");
        }
        else {
            inject_before_block("sub");
        }

        shadow(
            sub {
                my $block = pop;
                my @attr = @_;

                my $attr = "";

                if (@attr == 1) {
                    my $css = $attr[0];
                    while ($css =~ /([\#\.])([A-Za-z][-:\.\w]*)/g) {
                        if ($1 eq '#') {
                            $attr .= qq{ id="$2"};
                        } else {
                            $attr .= qq{ class="$2"};
                        }
                    }
                } else {
                    my ($k, $v) = (shift @attr, shift @attr);
                    while ($k) {
			if (defined $v) {
			    $v = encode_entities($v, '<>&"');
			    $attr .= " $k=\"$v\"";
			} else {
			    $attr .= " $k";
			}

                        ($k, $v) = (shift @attr, shift @attr);
                    }
                }

                if (defined wantarray and not wantarray) {
                    my $sub = sub {
                        _tag($tag, $attr, $block, 1);
                    };
                    bless $sub, 'Markapl::Tag';
                    return $sub;
                }
                _tag($tag, $attr, $block);
                return '';
            }
        );

    }
}

1;
