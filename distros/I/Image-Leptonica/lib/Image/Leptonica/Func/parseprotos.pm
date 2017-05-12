package Image::Leptonica::Func::parseprotos;
$Image::Leptonica::Func::parseprotos::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::parseprotos

=head1 VERSION

version 0.04

=head1 C<parseprotos.c>

 parseprotos.c

       char             *parseForProtos()

    Static helpers
       static l_int32    getNextNonCommentLine()
       static l_int32    getNextNonBlankLine()
       static l_int32    getNextNonDoubleSlashLine()
       static l_int32    searchForProtoSignature()
       static char      *captureProtoSignature()
       static char      *cleanProtoSignature()
       static l_int32    skipToEndOfFunction()
       static l_int32    skipToMatchingBrace()
       static l_int32    skipToSemicolon()
       static l_int32    getOffsetForCharacter()
       static l_int32    getOffsetForMatchingRP()

=head1 FUNCTIONS

=head2 parseForProtos

char * parseForProtos ( const char *filein, const char *prestring )

  parseForProtos()

      Input:  filein (output of cpp)
              prestring (<optional> string that prefaces each decl;
                        use NULL to omit)
      Return: parsestr (string of function prototypes), or NULL on error

  Notes:
      (1) We parse the output of cpp:
              cpp -ansi <filein>
          Three plans were attempted, with success on the third.
      (2) Plan 1.  A cursory examination of the cpp output indicated that
          every function was preceeded by a cpp comment statement.
          So we just need to look at statements beginning after comments.
          Unfortunately, this is NOT the case.  Some functions start
          without cpp comment lines, typically when there are no
          comments in the source that immediately precede the function.
      (3) Plan 2.  Consider the keywords in the language that start
          parts of the cpp file.  Some, like 'typedef', 'enum',
          'union' and 'struct', are followed after a while by '{',
          and eventually end with '}, plus an optional token and a
          final ';'  Others, like 'extern' and 'static', are never
          the beginnings of global function definitions.   Function
          prototypes have one or more sets of '(' followed eventually
          by a ')', and end with ';'.  But function definitions have
          tokens, followed by '(', more tokens, ')' and then
          immediately a '{'.  We would generate a prototype from this
          by adding a ';' to all tokens up to the ')'.  So we use
          these special tokens to decide what we are parsing.  And
          whenever a function definition is found and the prototype
          extracted, we skip through the rest of the function
          past the corresponding '}'.  This token ends a line, and
          is often on a line of its own.  But as it turns out,
          the only keyword we need to consider is 'static'.
      (4) Plan 3.  Consider the parentheses and braces for various
          declarations.  A struct, enum, or union has a pair of
          braces followed by a semicolon.  They cannot have parentheses
          before the left brace, but a struct can have lots of parentheses
          within the brace set.  A function prototype has no braces.
          A function declaration can have sets of left and right
          parentheses, but these are followed by a left brace.
          So plan 3 looks at the way parentheses and braces are
          organized.  Once the beginning of a function definition
          is found, the prototype is extracted and we search for
          the ending right brace.
      (5) To find the ending right brace, it is necessary to do some
          careful parsing.  For example, in this file, we have
          left and right braces as characters, and these must not
          be counted.  Somewhat more tricky, the file fhmtauto.c
          generates code, and includes a right brace in a string.
          So we must not include braces that are in strings.  But how
          do we know if something is inside a string?  Keep state,
          starting with not-inside, and every time you hit a double quote
          that is not escaped, toggle the condition.  Any brace
          found in the state of being within a string is ignored.
      (6) When a prototype is extracted, it is put in a canonical
          form (i.e., cleaned up).  Finally, we check that it is
          not static and save it.  (If static, it is ignored).
      (7) The @prestring for unix is NULL; it is included here so that
          you can use Microsoft's declaration for importing or
          exporting to a dll.  See environ.h for examples of use.
          Here, we set: @prestring = "LEPT_DLL ".  Note in particular
          the space character that will separate 'LEPT_DLL' from
          the standard unix prototype that follows.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
