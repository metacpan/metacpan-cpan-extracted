package JavaScript::Swell;

use strict;

our $VERSION = '0.01';

my @RE = qw(! != !== % %= & && &&= &= \( *= + += - -= -> . .. ... / /= : :: ; < << <<= <= = == === > >= >> >>= >>> >>>= ? @ \[ ^ ^= ^^ ^^= \{ | |= || ||= ~ abstract break case catch const continue debugger default delete do else enum export extends final finally for function goto if implements import in instanceof interface is namespace native new package return static switch synchronized throw throws transient try typeof use var volatile while with);
my @TS = qw(* ! != !== % %= & && &&= &= *= + += - -= -> .. ... / /= : :: < << <<= <= = == === > >= >> >>= >>> >>>= ? @ ^ ^= ^^ ^^= | |= || ||= ~);
my %RegularExpression;
my %RegularExpression_shortcut;
foreach (@RE) {
    s/^\\//o;
    my $word;
    $RegularExpression{$_}++;
    foreach (split(//)) {
	$word .= $_;
	$RegularExpression_shortcut{$word}++;
    }
    $RegularExpression_shortcut{'#'}++;
    $RegularExpression_shortcut{','}++;
    $RegularExpression{'#'}++;
    $RegularExpression{','}++;
}
my %TERMSPACE;
foreach (@TS) {
    s/^\\//o;
    $TERMSPACE{$_}++;
}
$TERMSPACE{'#'}++;

sub new {
    my $class = shift;
    bless {
	source => '',
	split_source => undef,
	return_source => '',
	parser_state => {
	    line => 0,
	    method => '',
	    re_word => '',
	    quote => '',
	    indent => 0,
	    cursor => 0,
	    parentheses_nest => 0,
	    is_linehead => 0,
	    squishmode => 0,
	    charlast => '',
	},
    }, $class;
}


#setter or getter
sub source {
    my $self = shift;
    if (@_) {
	$self->{source} = shift;
	$self->{source} =~ s/\r\n/\n/go;
	my @ss = split(//, $self->{source});
	$self->{split_source} = \@ss;
	$self->{return_source} = '';
    }
    $self->{return_source};
}
sub split_source {@{shift->{split_source}}}
sub get_char {
    my $self = shift;

    return $self->{split_source}[$self->cursor] unless @_;
    if ($_[0] =~ m/^\-{0,1}\d+$/) {
	if ((0 <= ($self->cursor + $_[0]) && ($self->split_source + 0) > ($self->cursor + $_[0]))) {
	    return $self->{split_source}[$self->cursor + $_[0]];
	} else {
	    return '';
	}
    } else {
	return $self->{split_source}[$self->cursor];
    }
}
sub get_charlast {shift->{parser_state}->{charlast}}
sub set_char {
    my $self = shift;
    my $c = shift;

    $self->{parser_state}->{charlast} = $1
	if $c =~ /(.)$/;

    $self->set_re_word($c) unless @_;
    $self->{return_source} .= $c;
}
sub set_lf {
    my $self = shift;
    return if $self->squishmode;
    $self->set_char("\n" . (' ' x $self->indent));
    $self->is_linehead(1);
}
sub set_re_word {
    my $self = shift;
    my $c = shift;

    return if $c =~ /\s/o;

    unless ($RegularExpression_shortcut{$self->re_word . $c}) {
	$self->re_word($c);
    } else {
	$self->re_word($self->re_word . $c);
    }
}
sub is_re_before {$RegularExpression{shift->re_word}}
sub is_linehead {my $self = shift;@_ ? $self->{parser_state}->{is_linehead} = shift:$self->{parser_state}->{is_linehead}}
sub squishmode {my $self = shift;@_ ? $self->{parser_state}->{squishmode} = shift:$self->{parser_state}->{squishmode}}

sub indent {my $self = shift;@_ ? $self->{parser_state}->{indent} = shift:$self->{parser_state}->{indent}}
sub cursor {my $self = shift;@_ ? $self->{parser_state}->{cursor} = shift:$self->{parser_state}->{cursor}}
sub method {my $self = shift;@_ ? $self->{parser_state}->{method} = shift:$self->{parser_state}->{method}}
sub quote {my $self = shift;@_ ? $self->{parser_state}->{quote} = shift:$self->{parser_state}->{quote}}
sub parentheses_nest {my $self = shift;@_ ? $self->{parser_state}->{parentheses_nest} = shift:$self->{parser_state}->{parentheses_nest}}
sub re_word {my $self = shift;@_ ? $self->{parser_state}->{re_word} = shift:$self->{parser_state}->{re_word}}

sub add_cursor {shift->{parser_state}->{cursor}++}
sub add_indent {shift->{parser_state}->{indent} += 2}
sub dec_indent {shift->{parser_state}->{indent} -= 2}
sub add_parentheses_nest {shift->{parser_state}->{parentheses_nest}++}
sub dec_parentheses_nest {shift->{parser_state}->{parentheses_nest}--}


#parser
sub init_parser {
    my $self = shift;

    $self->quote('');
    $self->indent(0);
    $self->cursor(0);
    $self->parentheses_nest(0);
    $self->method('default');
    $self->re_word('{');
    $self->is_linehead(0);
}

sub term_spacer {
    my $self = shift;
    my $c = @_ ? shift : $self->get_char;
    my $c2 = @_ ? shift : $self->get_char(1);
    my $c3 = @_ ? shift : $self->get_char(2);
    my $c4 = @_ ? shift : $self->get_char(3);
    my $cb = $self->get_char(-1);
    my $cl = $self->get_charlast;

    my ($s1, $s2) = (1, 1);
    ($s1, $s2) = (0, 0) if $self->squishmode;
    my $m  = '';
#    $s1 = 0 if $cb =~ /[\s\(\[]/;
    $s1 = 0 if $cl =~ /[\s\(\[]/;

    my $cc4 = "$c$c2$c3$c4";
    my $cc3 = "$c$c2$c3";
    my $cc2 = "$c$c2";

    if ($TERMSPACE{$cc4}) {
	$m = $cc4;
	$self->add_cursor;
	$self->add_cursor;
	$self->add_cursor;
#	$s2 = 0 if $self->get_char(4) =~ /[\s\)\]]/ && $self->squishmode;
    } elsif ($TERMSPACE{$cc3}) {
	$m = $cc3;
	$self->add_cursor;
	$self->add_cursor;
##	$s2 = 0 if $c4 =~ /[\s\)\]]/;
    } elsif ($TERMSPACE{$cc2}) {
	$m = $cc2;
	$self->add_cursor;
#	$s2 = 0 if $c3 =~ /[\s\)\]]/ && $self->squishmode;
    } elsif ($cc2 eq '++' || $cc2 eq '--') {
	$m = $cc2;
	($s1, $s2) = (0, 0);
	$self->add_cursor;
##	$s2 = 0 if $c3 =~ /[\s\)\]]/;
    } elsif (((($self->re_word eq '=' || $self->re_word eq '(') && ($c eq '+' || $c eq '-') && $c2 =~ /^\d$/) || ($TERMSPACE{$c} && $TERMSPACE{$c2}))) {
	$m = $c;
	$s2 = 0;
#	$s2 = 0 if $c2 =~ /[\s\)\]]/ && $self->squishmode;
    } elsif ($TERMSPACE{$c}) {
	$m = $c;
#	$s2 = 0 if $c2 =~ /[\s\)\]]/ && $self->squishmode;
    } elsif ($c eq ',') {
	$m = $c;
	$s1 = 0;
    } else {
	return 0;
    }
    $self->set_char(' ') if $s1;
    $self->set_char($m);
    $self->set_char(' ') if $s2;
		     
    return 1;
}

sub parser_default {
    my $self = shift;
    my $c = $self->get_char;
    my $c2 = $self->get_char(1);

    return if $c =~ /\s/o && ($self->get_charlast =~ /\s/ || $c2 !~ /[_a-zA-Z0-9]/);

    if ($c eq '/') {
	if ($c2 eq '*') {
	    $self->method('comment');
	    $self->add_cursor;
	    $self->add_indent;
	    $self->set_char('/*', 1);
	    $self->set_lf;
	    return;
	} elsif ($c2 eq '/') {
	    $self->method('comment_line');
	    $self->add_cursor;
	    $self->set_char('//', 1) unless $self->squishmode;
	    return;
	} elsif ($self->is_re_before) {
	    $self->method('regularexpression');
	    $self->set_char('/');
	    return;
	}
    }

    my $bword = $self->re_word;
    if ($c =~ /\s/o && $c2 =~ /\s/o) {
	$self->add_cursor;
    } elsif ($c eq '"' || $c eq '\'') {
	$self->method('quote');
	$self->set_char($c, 1);
	$self->quote($c);


    } elsif ($c eq '(') {
	$self->set_char(' ', 1)
	    if $bword =~ /^(case|catch|do|for|function|if|import|switch|throw|try|while|with)$/o && !$self->squishmode;
  	$self->set_char('(');
	$self->add_parentheses_nest;
    } elsif ($c eq ')') {
	if ($self->parentheses_nest) {
	    $self->set_char(')');
	    $self->dec_parentheses_nest;
	} else {
	    $self->set_char(')');
	}
	$self->set_char(' ') if $c2 =~ /[\_a-z-A-Z0-9]/;
    } elsif ($c eq '{') {
	$self->set_char(' ', 1)
	    if $bword =~ /^(case|catch|do|try|else|\))$/o && !$self->squishmode;
	$self->add_indent;
	$self->set_char('{');
	$self->set_lf unless $c2 eq '}';
    } elsif ($c eq '}') {
	$self->dec_indent;
	$self->set_lf;
	$self->set_char('}');
	if ($c2 eq ';') {
	    $self->add_cursor;
	    $self->set_char(';');
	}
	if ($c2 ne '}') {
	    $self->set_lf;
	}
    } elsif ($c eq ';') {
	$self->set_char(';');
	if ($self->parentheses_nest && !$self->squishmode) {
	    $self->set_char(' ');
	} elsif ($c2 ne '}') {
	    $self->set_lf;
	}
    } elsif ($self->squishmode && $c eq 'i' && $bword eq 'else') {
	$self->set_char(' ');
	$self->set_char('i');
    } elsif ($self->term_spacer($c, $c2)) {
    } elsif ($self->squishmode && $c =~ /\s/o && ($self->get_charlast !~ /[_a-zA-Z0-9]/ || $c2 !~ /[_a-zA-Z0-9]/)) {
    } elsif ($c ne "\n") {
	$self->set_char($c);
    }
}
sub parser_comment {
    my $self = shift;
    my $c = $self->get_char;
    my $c2 = $self->get_char(1);

    if ($c eq '*' && $c2 eq '/') {
	$self->method('default');
	$self->add_cursor;
	$self->dec_indent;
	$self->set_lf;
  	$self->set_char('*/', 1);
	$self->set_lf;
    } elsif ($c eq "\n") {
	$self->set_lf;
    } else {
	$self->set_char($c, 1);
    }
}
sub parser_comment_line {
    my $self = shift;
    my $c = $self->get_char;

    if ($c eq "\n") {
	$self->set_lf;
	$self->method('default');
    } else {
	$self->set_char($c, 1) unless $self->squishmode;
    }
}
sub parser_quote {
    my $self = shift;
    my $c = $self->get_char;

    $self->set_char($c, 1);
    if ($c eq $self->quote) {
	$self->quote('');
	$self->method('default');
    }
}
sub parser_regularexpression {
    my $self = shift;
    my $c = $self->get_char;

    if ($c eq '/' || $c eq "\n") {
	$self->set_char($c);
	$self->method('default');
    } else {
	$self->set_char($c, 1);
    }
}

sub parser {
    my $self = shift;;
    $self->source(shift) if @_;

    $self->init_parser;

    while ($self->cursor < $self->split_source) {
	my $c = $self->get_char;
	if ($c eq '\\') {
	    $self->set_char($c, 1);
	    $self->set_char($self->get_char(1), 1);
	    $self->add_cursor;	    
	} elsif ($self->is_linehead && ($c =~ /\s/)) {
	} else {
	    $self->is_linehead(0);
	    my $method = 'parser_' . $self->method;
	    $self->$method();
	}
	$self->add_cursor;
    }

    $self->source;
}

sub swell {
    my $self;
    if (ref($_[0]) eq __PACKAGE__) {
	$self = shift;
    } else {
	$self = shift->new;
    }
    $self->squishmode(0);
    $self->parser(@_);
}

sub squish {
    my $self;
    if (ref($_[0]) eq __PACKAGE__) {
	$self = shift;
    } else {
	$self = shift->new;
    }
    $self->squishmode(1);
    $self->parser(@_);
}

1;
__END__
=head1 NAME

JavaScript::Swell - The source of JavaScript that accident Yoca is done is shown easily. 

=head1 SYNOPSIS

  use JavaScript::Swell;
  #it is easy to see and converts it.
  my $swelled = JavaScript::Swell->swell($javascript_code);

  #it is not easy to see and converts it.
  #it was easily coded. JavaScript::Squish is not used.
  my $squished = JavaScript::Swell->squish($javascript_code);


=head1 DESCRIPTION

JavaScript that accident Yoca is done is made legible to some degree.

The compression of the variable identifier and the function name is not developed.

Only the code format is progressed.

please use JavaScript::Squish for how for being using real squish separately.

=head1 Methods

=over 4

=item swell($javascript_code)

it is easy to see and converts it.

=item squish($javascript_code)

it is not easy to see and converts it.

=back


=head1 SEE ALSO

JavaScript::Squish

=head1 AUTHOR

Kazuhiro, Osawa<lt>ko@yappo.ne.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Kazuhiro, Osawa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
