use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Grammar::Base;
use MarpaX::Languages::ECMAScript::AST::Util qw/:all/;
use MarpaX::Languages::ECMAScript::AST::Impl qw//;
use Log::Any qw/$log/;
use constant SEARCH_KEYWORD_IN_GRAMMAR => '# DO NOT REMOVE NOR MODIFY THIS LINE';
use MarpaX::Languages::ECMAScript::AST::Exceptions qw/:all/;

# ABSTRACT: ECMAScript, grammars base package

our $VERSION = '0.020'; # VERSION

#
# Note: because this module is usually subclasses, internal methods are called
# using _method($self, ...) instead of $self->_method(...)
#


sub new {
  my ($class, $spec) = @_;

  InternalError(error => 'Missing ECMAScript specification') if (! defined($spec));

  my $self  = {
      _content        => $class->make_content($spec),
      _grammar_option => $class->make_grammar_option($spec),
      _recce_option   => $class->make_recce_option($spec),
  };

  bless($self, $class);

  return $self;
}


sub content {
    my ($self) = @_;
    return $self->{_content};
}


sub make_content {
    my ($class, $spec) = @_;

    my $content = $class->make_grammar_content;

    #
    # Too painful to write MarpaX::Languages::ECMAScript::AST::Grammar::${spec}::CharacterClasses::IsSomething
    # so I change it on-the-fly here
    #
    if ($spec eq 'ECMAScript-262-5') {
	$spec = 'ECMAScript_262_5';
    }
    my $characterClass = "\\p{MarpaX::Languages::ECMAScript::AST::Grammar::${spec}::CharacterClasses::Is";
    $content =~ s/\\p\{Is/$characterClass/g;

    return $content;
}


sub extract {
    my ($self) = @_;
    my $rc = '';

    my $content = $self->content;
    my $index = index($content, SEARCH_KEYWORD_IN_GRAMMAR);
    if ($index >= 0) {
      $rc = substr($content, $index);
      $rc =~ s/\baction[ \t]*=>[ \t]*\w+//g;
      $rc =~ s/(__\w+)[ \t]*::=[ \t]*/$1 ~ /g;
    }

    return $rc;
}


sub make_grammar_option {
    my ($class, $spec) = @_;
    return {bless_package => $class->make_bless_package,
	    source        => \$class->make_content($spec, $class->make_grammar_content)};
}


sub make_grammar_content {
    my ($class) = @_;
    return undef;
}


sub make_bless_package {
    my ($class) = @_;
    return $class;
}


sub grammar_option {
    my ($self) = @_;
    return $self->{_grammar_option};
}


sub recce_option {
    my ($self) = @_;
    return $self->{_recce_option};
}


sub make_recce_option {
    my ($class, $spec) = @_;
    return {ranking_method => $class->make_ranking_method,
            semantics_package => $class->make_semantics_package,
            too_many_earley_items => $class->make_too_many_earley_items};
}


sub make_ranking_method {
    my ($class) = @_;
    return 'high_rule_only';
}


sub make_semantics_package {
    my ($class) = @_;
    return join('::', __PACKAGE__, 'DefaultSemanticsPackage');
}


sub make_too_many_earley_items {
    my ($class) = @_;
    return 0;
}


sub _callback {
  my ($self, $source, $pos, $max, $impl, $callbackp, $originalErrorString, @args) = @_;

  my $rc = $pos;

  eval {$rc = &$callbackp(@args, $source, $pos, $max, $impl)};
  if ($@) {
    my $callbackErrorString = $@;
    my $line_columnp;
    eval {$line_columnp = lineAndCol($impl)};
    my $context = _context($self, $impl);
    #
    # Now we can destroy the recognizer
    #
    $impl->destroy_R;
    if (! $@) {
      if (defined($originalErrorString) && $originalErrorString) {
        SyntaxError(error => sprintf("%s\n%s\n\n%s%s", $originalErrorString, $callbackErrorString, showLineAndCol(@{$line_columnp}, $source), $context));
      } else {
        SyntaxError(error => sprintf("%s\n\n%s%s", $callbackErrorString, showLineAndCol(@{$line_columnp}, $source), $context));
      }
    } else {
      if (defined($originalErrorString) && $originalErrorString) {
        SyntaxError(error => sprintf("%s\n%s\n%s", $originalErrorString, $callbackErrorString, $context));
      } else {
        SyntaxError(error => sprintf("%s\n%s", $callbackErrorString, $context));
      }
    }
  }

  return $rc;
}

sub parse {
  my ($self, $source, $impl, $optionsp, $start, $length) = @_;

  $optionsp //= {};
  my $callbackp = $optionsp->{callback};
  my $callbackargsp = $optionsp->{callbackargs} // [];
  my @callbackargs = @{$callbackargsp};
  my $failurep = $optionsp->{failure};
  my $failureargsp = $optionsp->{failureargs} // [];
  my @failureargs = @{$failureargsp};
  my $endp = $optionsp->{end};
  my $endargsp = $optionsp->{endargs} // [];
  my @endargs = @{$endargsp};

  $start //= 0;
  $length //= -1;

  my $sourceMaxPos = length($source) - 1;
  if ($start < 0) {
      $start += $sourceMaxPos + 1;
  }
  my $max = ($length < 0) ? ($length + $sourceMaxPos + 1) : ($start + $length);

  my $pos = $start;
  my $stop;
  my $newpos;

  #
  # Create a recognizer
  #
  $impl->make_R;
  #
  # Lexer can fail
  #
  eval {$newpos = $impl->read(\$source, $pos, $length)};
  if ($@) {
    #
    # Failure callback
    #
    if (defined($failurep)) {
      $pos = _callback($self, $source, $pos, $max, $impl, $failurep, $@, @failureargs);
    } else {
      my $line_columnp = lineAndCol($impl);
      my $context = _context($self, $impl);
      $impl->destroy_R;
      SyntaxError(error => sprintf("%s\n\n%s%s", $@, showLineAndCol(@{$line_columnp}, $source), $context));
    }
  } else {
    $pos = $newpos;
  }
  do {
    #
    # Events
    #
    if (defined($callbackp)) {
      $pos = _callback($self, $source, $pos, $max, $impl, $callbackp, undef, @callbackargs);
    }
    #
    # Lexer can fail
    #
    eval {$newpos = $impl->resume($pos)};
    if ($@) {
      if (defined($failurep)) {
        #
        # Failure callback
        #
        $pos = _callback($self, $source, $pos, $max, $impl, $failurep, $@, @failureargs);
      } else {
        my $line_columnp = lineAndCol($impl);
	my $context = _context($self, $impl);
	$impl->destroy_R;
        SyntaxError(error => sprintf("%s\n\n%s%s", $@, showLineAndCol(@{$line_columnp}, $source), $context));
      }
    } else {
      $pos = $newpos;
    }
  } while ($pos <= $max);

  if (defined($endp)) {
    #
    # End callback
    #
      _callback($self, $source, $pos, $max, $impl, $endp, undef, @endargs);
  }

  return $self;
}


sub value {
  my ($self, $impl, $optionsp) = @_;

  $optionsp //= {};
  my $traverserp = $optionsp->{traverser};
  my $traverserscratchpadp = $optionsp->{traverserscratchpad} // {};

  my $asf = defined($traverserp) ? Marpa::R2::ASF->new({slr => $impl->R}) : undef;
  my $rc = (defined($asf) ? $asf->traverse($traverserscratchpadp, $traverserp) : $impl->value()) || do {
    my $lastExpression = _show_last_expression($self, $impl);
    $impl->destroy_R;
    InternalError(error => sprintf('%s', $lastExpression))
  };

  if (! defined($rc)) {
      $impl->destroy_R;
      InternalError(error => 'Undefined parse tree value');
  }
  if ((! defined($asf)) && defined(my $rc2 = $impl->value())) {
      $impl->destroy_R;
      InternalError(error => 'More than one parse tree value');
  }
  $impl->destroy_R;

  return ${$rc};
}

# ----------------------------------------------------------------------------------------

sub _context {
    my ($self, $impl) = @_;

    my $context = $log->is_debug ?
	sprintf("\n\nContext:\n\n%s", $impl->show_progress()) :
	'';

    return $context;
}


# ----------------------------------------------------------------------------------------

sub getLexeme {
  my ($self, $lexemeHashp, $impl) = @_;

  my $rc = 0;
  #
  # Get paused lexeme
  #
  my $lexeme = $impl->pause_lexeme();
  if (defined($lexeme)) {
    $lexemeHashp->{name} = $lexeme;
    ($lexemeHashp->{start}, $lexemeHashp->{length}) = $impl->pause_span();
    ($lexemeHashp->{line}, $lexemeHashp->{column}) = $impl->line_column($lexemeHashp->{start});
    $lexemeHashp->{value} = $impl->literal($lexemeHashp->{start}, $lexemeHashp->{length});
    $rc = 1;
  }

  return $rc;
}

# ----------------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------------

sub getLastLexeme {
  my ($self, $lexemeHashp, $impl) = @_;

  my $rc = 0;
  #
  # Get last lexeme span
  #
  my ($start, $length) = lastLexemeSpan($impl);
  if (defined($start)) {
    ($lexemeHashp->{start}, $lexemeHashp->{length}) = ($start, $length);
    $lexemeHashp->{value} = $impl->literal($lexemeHashp->{start}, $lexemeHashp->{length});
    $rc = 1;
  }

  return $rc;
}

# ----------------------------------------------------------------------------------------

sub _show_last_expression {
  my ($self, $impl) = @_;

  my ($start, $end) = $impl->last_completed_range('SourceElement');
  return 'No source element was successfully parsed' if (! defined($start));
  my $lastExpression = $impl->range_to_string($start, $end);
  return "Last SourceElement successfully parsed was: $lastExpression";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Grammar::Base - ECMAScript, grammars base package

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use MarpaX::Languages::ECMAScript::AST::Grammar::Base;

    my $grammar = MarpaX::Languages::ECMAScript::AST::Grammar::Base->new("grammar", "My::Package", "ECMAScript_262_5");

    my $grammar_content = $grammar->content();
    my $grammar_option = $grammar->grammar_option();
    my $recce_option = $grammar->recce_option();

=head1 DESCRIPTION

This modules returns a base package for all the ECMAScript grammars written in Marpa BNF.

=head1 SUBROUTINES/METHODS

=head2 new($class, $spec)

Instance a new object. Takes an ECMAScript specification $spec as required parameter.

=head2 content($self)

Returns the content of the grammar.

=head2 make_content($class, $spec)

Class method that return the default content of the grammar writen for specification $spec. Grammars are typically use Posix user-defined classes without the full classname; this method is making sure full classname is used; using $spec.

=head2 extract($self)

Returns the part of the grammar that can be safely extracted and injected in another.

=head2 make_grammar_option($class, $spec)

Class method that returns default grammar options for a given ECMA specification $spec.

=head2 make_grammar_content($class)

Class method that returns the grammar content. This class must be overwriten by the any package providing a grammar.

=head2 make_bless_package($class)

Class method that returns recommended bless_package grammar options.

=head2 grammar_option($self)

Returns recommended option for Marpa::R2::Scanless::G->new(), returned as a reference to a hash.

=head2 recce_option($self)

Returns recommended option for Marpa::R2::Scanless::R->new(), returned as a reference to a hash.

=head2 make_recce_option($class, $spec)

Class method that returns default recce options for a given ECMA specification $spec.

=head2 make_ranking_method($class)

Class method that returns recommended recce ranking_method

=head2 make_semantics_package($class)

Class method that returns a default recce semantics_package, doing nothing else but a new().

=head2 make_too_many_earley_items($class)

Class method that returns a default recce too_many_earley_items option, default is 0 i.e. disable them.

=head2 parse($self, $source, $impl, [$optionsp], [$start], [$length])

Parse the source given as reference to a scalar, using implementation $impl, an optional reference to a hash that can contain:

=over

=item callback

Callbak Code Reference. Default is undef.

=item callbackargs

Reference to an array of callback routine arguments. Default is [].

=item failure

Failure callback Code Reference. Default is undef.

=item failureargs

Reference to an array of failure routine arguments. Default is [].

=item end

End callback Code Reference. Default is undef.

=item endargs

Reference to an array of end routine arguments. Default is [].

=back

This method must be called as a super method by grammar using this package as a parent. $self must be a reference to a grammar instantiated via MarpaX::Languages::ECMAScript::AST::Grammar. The callback code will always be called with: per-callback arguments, $source, $pos (i.e. current position), $max (i.e. max position), $impl (i.e. a MarpaX::Languages::ECMAScript::AST::Impl instance). The default and failure callbacks must always return the new position in the stream, and raise a MarpaX::Languages::ECMAScript::AST::Exception::SyntaxError exception if there is an error. In the 'end' and 'failure' callbacks, $pos is not meaningful: this is the last position where external scanning restarted. You might want to look to the getLastLexeme() method. Output of the 'end' callback is ignored. Please note that this method explicitely creates a recognizer using $impl->make_R(), destroyed in case of error.

=head2 value($self, $impl, $optionsp)

Return the parse tree (unique) value. $impl is the recognizer instance for the grammar. Will raise an InternalError exception if there is no parse tree value, or more than one parse tree value. Please note that this method explicity destroys the recognizer using $impl->destroy_R. Value itself is an AST where every string is a perl string.

An optional reference to a hash that can contain:

=over

=item traverser

CODE traverser callback. If setted, and ASF will be performed using this callback. Default is to called Marpa::R2's value() directly.

=item traverserscratchpad

Reference to a scratchpad for the traverse. Default is {}.

=back

=head2 getLexeme($self, $lexemeHashp, $impl)

Fills a hash with latest paused lexeme:

=over

=item name

Lexeme name

=item start

Start position

=item length

Length

=item line

Line number as per Marpa

=item column

Column number as per Marpa

=item value

Lexeme value

=back

Returns a true value if a lexeme pause information is available.

=head2 getLastLexeme($self, $lexemeHashp, $impl)

Fills a hash with latest lexeme (whatever it is, its name is unknown):

=over

=item start

Start position

=item length

Length

=item value

Lexeme value

=back

Returns a true value if a lexeme pause information is available.

=head1 SEE ALSO

L<MarpaX::Languages::ECMAScript::AST::Impl>

L<MarpaX::Languages::ECMAScript::AST::Util>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
