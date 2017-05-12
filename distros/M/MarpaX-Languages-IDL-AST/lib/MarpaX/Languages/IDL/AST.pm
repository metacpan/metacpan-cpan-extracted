use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::IDL::AST;
use MarpaX::Languages::IDL::AST::Value;
use MarpaX::Languages::IDL::AST::Util;
use Scalar::Util qw/blessed reftype refaddr/;
use Data::Dumper;
use Template;
use Template::Constants qw/:chomp :debug/;
use File::ShareDir qw/dist_dir/;
use Config;
use Data::Scan;

# ABSTRACT: Translate an IDL source to an AST

our $VERSION = '0.007'; # VERSION


use Carp qw/carp croak/;
use Marpa::R2 qw//;
use File::Basename qw/basename fileparse/;
use File::Spec::Functions qw/case_tolerant rel2abs catdir/;

our $BLESS_PACKAGE = 'IDL::AST';
our $DATA = do {local $/; <DATA>};
our $G = Marpa::R2::Scanless::G->new({source => \$DATA, bless_package => $BLESS_PACKAGE});
# Marpa follows Unicode recommendation, i.e. perl's \R, that cannot be in a character class
our $NEWLINE_REGEXP = qr/(?>\x0D\x0A|\v)/;


sub new {
  my ($class) = @_;

  my $self = {
  };

  bless($self, $class);

  return $self;
}


sub parse {
    my ($self, $input, $hashOptPtr) = @_;
    #
    # Parameters check
    #
    $hashOptPtr //= {};
    if (ref($hashOptPtr) ne 'HASH') {
	croak '3rd argument must be a pointer to HASH containing any Marpa::R2::Scanles::R option, except the grammar option';
    }
    foreach (qw/grammar semantics_package/) {
      if (exists($hashOptPtr->{$_})) {
        delete($hashOptPtr->{$_});
      }
    }
    my $datap;
    if (! ref($input)) {
      #
      # Assume this is a filename
      # IDL wants the filename to end with .idl
      #
      my ($filename, $directories, $suffix) = fileparse($input, qr/\.[^.]*/);
      if ((  case_tolerant() && (lc($suffix) ne '.idl')) ||
          (! case_tolerant() && (   $suffix  ne '.idl'))) {
        carp "$input does not end with .idl";
      }
      #
      # Load data
      #
      open(my $fh, '<', $input) || croak "Failed to open $input, $!";
      my $data = do { local $/; <$fh> };
      close($fh) || warn "Failed to close $input, $!";
      $datap = \$data;
    } else {
      #
      # Assume this is the data to parse
      #
      $datap = $input;
    }
    #
    # Recognizer
    #
    my $recce = Marpa::R2::Scanless::R->new({grammar => $G,
                                             # trace_terminals => 1,
                                             semantics_package => 'MarpaX::Languages::IDL::AST::Value',
                                             %{$hashOptPtr}});
    $recce->read($datap);
    #
    # AST value
    #
    my $value = $recce->value();
    croak 'Undefined AST value' if (! defined($value) || ! defined(${$value}));
    #
    # We want a single value
    #
    my $nextValue = $recce->value();
    croak 'Ambiguous AST' if (defined($nextValue));
    #
    # Let's remember the latest AST
    #
    $self->{_ast} = ${$value};

    return $self;
}


sub ast {
    my ($self) = @_;

    return $self->{_ast};
}


sub output {
    my ($self) = @_;

    return $self->{_output};
}


sub generate {
  my ($self, $ast, $template, $targetOptionHashp) = @_;

    $ast               //= $self->ast();
    $template          //= 'perl5.tt2';
    $targetOptionHashp //= {};
    #
    # We provide a default style only if this is a template we know about
    #
    my $style  = $targetOptionHashp->{style};
    my $addDefaultStyleInIncludePath = '';
    my $packageDist = __PACKAGE__;
    $packageDist =~ s/::/-/g;
    my $distDir = dist_dir($packageDist);
    if (! defined($style)) {
      if ($template eq 'perl5.tt2') {
        $style = 'Moose';
        $addDefaultStyleInIncludePath = catdir($distDir, 'perl5', 'style', $style);
      }
    }

    if (ref($targetOptionHashp) ne 'HASH') {
	croak '3rd argument must be a pointer to HASH';
    }

    my $ttOptionHashp = $targetOptionHashp->{tt};
    $ttOptionHashp->{STRICT} //= 1;
    $ttOptionHashp->{DELIMITER} //= $Config{path_sep};
    $ttOptionHashp->{INCLUDE_PATH} //= '';
    $ttOptionHashp->{INCLUDE_PATH} .= $ttOptionHashp->{DELIMITER} . $distDir;
    if ($addDefaultStyleInIncludePath) {
      $ttOptionHashp->{INCLUDE_PATH} .= $ttOptionHashp->{DELIMITER} . $addDefaultStyleInIncludePath;
    }
    $ttOptionHashp->{INTERPOLATE} //= 1;
    $ttOptionHashp->{EVAL_PERL} //= 1;
    $ttOptionHashp->{PRE_CHOMP} //= CHOMP_NONE;
    $ttOptionHashp->{POST_CHOMP} //= CHOMP_NONE;
    $ttOptionHashp->{RELATIVE} //= 1;
    local $Template::Directive::WHILE_MAX = 1000000000;
    my $tt = Template->new($ttOptionHashp) || croak "$Template::ERROR";

    #
    # The semantics for our TT templates is to provide a hash with
    # a reference to a scratchpad hash (free to use) and the AST
    #
    my $ttVarsHashp = $targetOptionHashp->{vars};
    #
    # Our hooks
    #
    $ttVarsHashp->{ast} //= $ast;
    $ttVarsHashp->{nativeFloat} = $targetOptionHashp->{nativeFloat} // 1;
    $ttVarsHashp->{style} = $style;

    $self->{_output} = '';
    $tt->process($template, $ttVarsHashp, \$self->{_output}) || croak $tt->error();

    return $self;
}



1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::IDL::AST - Translate an IDL source to an AST

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use MarpaX::Languages::IDL::AST;

    my $idlPath = 'source.idl';
    my $ast = MarpaX::Languages::IDL::AST->new()->parse($idlPath)->validate();

=head2 $class->new()

Instantiate a new object. Returns a reference to it, denoted $self hereafter.

=head2 $self->parse($path, $hashOptPtr)

Parse the IDL and produce an AST out of it, then a meta-AST that is more useful representation for further processing. Takes as parameters:

=over

=item $path

A required IDL pathname.

=item $hashOptPtr

An optional reference to a hash containing Marpa::R2::Scanless::R() parameters, except the grammar and semantics_package options.

=back

The AST is an exact representation of the parse tree value of the IDL grammar contained in this package, except:

=over

=item scopedName

Original grammar rule is:

 <scopedName> ::= <identifier> | '::' <identifier> | <scopedName> '::' <identifier>

and has been rewriten to:

 <scopedName> ::= <identifier>+ separator => <coloncolon>

A dedicated action rule will concatenate all identifiers into a single string, giving the impression that scopedName is a token (accurate terminology is a lexeme). I.e. the scopedName value in the AST is in the form:

bless([start,totalLength,concatenatedValue], 'IDL::AST::scopedName')

alike the identifier.

=back

This method returns $self.

=head2 $self->ast()

Returns the latest AST produced by $self->parse().

=head2 $self->output()

Returns the latest output produced by $self->generate().

=head2 $self->generate($ast, $template, $targetOptionHashp)

Generate files for the given AST $ast.

=over

=item $ast

AST as produced by the method $self->parse(). Default to $self->ast().

=item $template

Template-Toolkit template name. Default to 'perl5.tt2', available in this distribution.

=item $targetOptionHashp

Hash reference of options specific to target $target.

=back

This method returns $self.

=head1 DESCRIPTION

This module provide and manage an AST of an IDL file, as per OMG's IDL 3.5 grammar specification.

=head1 NOTES

IDL version is 3.5 as of L<OMG IDL3.5 Specification|http://www.omg.org/spec/IDL35/3.5/>.

This specification imposes input to come from a filename, with suffix '.idl'.

Any preprocessing feature is ignored, and eventual multi-line proprocessing directives are likely to cause failure. Since the most expected preprocessing tokens are #include, #ifdef, and al., the user is expected to have already run a preprocessor before using this package.

=head1 SEE ALSO

L<Marpa::R2>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX-Languages-IDL-AST>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/jddurand/marpax-languages-idl-ast>

  git clone git://github.com/jddurand/marpax-languages-idl-ast.git

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
:default ::= action => [values] bless => ::lhs
lexeme default = action => [ start, length, value ] latm => 1 bless => ::name

:start ::= <specification>

<specification>              ::= <supportedCppCommandAny> <importAny> <definitionMany> <supportedCppCommandAny>
<supportedCppCommandAny>     ::= <supportedCppCommand>*
<supportedCppCommand>        ::= CPPSTYLEDIRECTIVE
<definition>                 ::= <typeDcl> SEMICOLON
                             |   <constDcl> SEMICOLON
                             |   <exceptDcl> SEMICOLON
                             |   <interface> SEMICOLON
                             |   <module> SEMICOLON
                             |   <value> SEMICOLON
                             |   <typeIdDcl> SEMICOLON
                             |   <typePrefixDcl> SEMICOLON
                             |   <event> SEMICOLON
                             |   <component> SEMICOLON
                             |   <homeDcl> SEMICOLON
<module>                     ::= MODULE <identifier> LCURLY <definitionMany> RCURLY
<interface>                  ::= <interfaceDcl>
                             |   <forwardDcl>
<interfaceDcl>               ::= <interfaceHeader> LCURLY <interfaceBody> RCURLY
<forwardDcl>                 ::= <abstractOrLocalMaybe> INTERFACE <identifier>
<interfaceHeader>            ::= <abstractOrLocalMaybe> INTERFACE <identifier> <interfaceInheritanceSpecMaybe>
<interfaceBody>              ::= <export>*
<export>                     ::= <typeDcl> SEMICOLON
                             |   <constDcl> SEMICOLON
                             |   <exceptDcl> SEMICOLON
                             |   <attrDcl> SEMICOLON
                             |   <opDcl> SEMICOLON
                             |   <typeIdDcl> SEMICOLON
                             |   <typePrefixDcl> SEMICOLON
<interfaceInheritanceSpec>   ::= COLON <interfaceNameListMany>
<interfaceName>              ::= <scopedName>
#<scopedName>                 ::= <identifier>
#                             |   COLONCOLON <identifier>
#                             |   <scopedName> COLONCOLON <identifier>
<scopedName>                 ::= <identifier>+ separator => <coloncolon>               action => _scopedName
<value>                      ::= <valueDcl>
                             |   <valueAbsDcl>
                             |   <valueBoxDcl>
                             |   <valueForwardDcl>
<valueForwardDcl>            ::= <abstractMaybe> VALUETYPE <identifier>
<valueBoxDcl>                ::= VALUETYPE <identifier> <typeSpec>
<valueAbsDcl>                ::= ABSTRACT VALUETYPE <identifier> <valueInheritanceSpecMaybe> LCURLY <exportAny> RCURLY
<valueDcl>                   ::= <valueHeader> LCURLY <valueElementAny> RCURLY
<valueHeader>                ::= <customMaybe> VALUETYPE <identifier> <valueInheritanceSpecMaybe>
<valueInheritanceSpec>       ::= <valueInheritanceSpec1ValuesMaybe> <valueInheritanceSpec2InterfacesMaybe>
<valueName>                  ::= <scopedName>
<valueElement>               ::= <export>
                             |   <stateMember>
                             |   <initDcl>
<stateMember>                ::= <publicOrPrivate> <typeSpec> <declarators> SEMICOLON
<initDcl>                    ::= FACTORY <identifier> LPAREN <initParamDeclsMaybe> RPAREN <raisesExprMaybe> SEMICOLON
<initParamDecls>             ::= <initParamDeclListMany>
<initParamDecl>              ::= <initParamAttribute> <paramTypeSpec> <simpleDeclarator>
<initParamAttribute>         ::= IN
<constDcl>                   ::= CONST <constType> <identifier> EQUAL <constExp>
<constType>                  ::= <integerType>
                             |   <charType>
                             |   <wideCharType>
                             |   <booleanType>
                             |   <floatingPtType>
                             |   <stringType>
                             |   <wideStringType>
                             |   <fixedPtConstType>
                             |   <scopedName>
                             |   <octetType>
<constExp>                   ::= <orExpr>
<orExpr>                     ::= <xorExpr>
                             |   <orExpr> OR <xorExpr>
<xorExpr>                    ::= <andExpr>
                             |   <xorExpr> XOR <andExpr>
<andExpr>                    ::= <shiftExpr>
                             |   <andExpr> AND <shiftExpr>
<shiftExpr>                  ::= <addExpr>
                             |   <shiftExpr> RSHIFT <addExpr>
                             |   <shiftExpr> LSHIFT <addExpr>
<addExpr>                    ::= <multExpr>
                             |   <addExpr> PLUS <multExpr>
                             |   <addExpr> MINUS <multExpr>
<multExpr>                   ::= <unaryExpr>
                             |   <multExpr> MUL <unaryExpr>
                             |   <multExpr> DIV <unaryExpr>
                             |   <multExpr> MOD <unaryExpr>
<unaryExpr>                  ::= <unaryOperator> <primaryExpr>
                             | <primaryExpr>
<unaryOperator>              ::= MINUS
                             | PLUS
                             | TILDE
<primaryExpr>                ::= <scopedName>
                             |   <literal>
                             |   LPAREN <constExp> RPAREN
<literal>                    ::= <integerLiteral>
                             |   <stringLiteral>
                             |   <wideStringLiteral>
                             |   <characterLiteral>
                             |   <wideCharacterLiteral>
                             |   <fixedPtLiteral>
                             |   <floatingPtLiteral>
                             |   <booleanLiteral>
<booleanLiteral>             ::= TRUE
                             |   FALSE
<positiveIntConst>           ::= <constExp>
<typeDcl>                    ::= TYPEDEF <typeDeclarator>
                             |   <structType>
                             |   <unionType>
                             |   <enumType>
                             |   NATIVE <simpleDeclarator>
                             |   <constrForwardDecl>
<typeDeclarator>             ::= <typeSpec> <declarators>
<typeSpec>                   ::= <simpleTypeSpec>
                             |   <constrTypeSpec>
<simpleTypeSpec>             ::= <baseTypeSpec>
                             |   <templateTypeSpec>
                             |   <scopedName>
<baseTypeSpec>               ::= <floatingPtType>
                             |   <integerType>
                             |   <charType>
                             |   <wideCharType>
                             |   <booleanType>
                             |   <octetType>
                             |   <anyType>
                             |   <objectType>
                             |   <valueBaseType>
<templateTypeSpec>           ::= <sequenceType>
                             |   <stringType>
                             |   <wideStringType>
                             |   <fixedPtType>
<constrTypeSpec>             ::= <structType>
                             |   <unionType>
                             |   <enumType>
<declarators>                ::= <declaratorListMany>
<declarator>                 ::= <simpleDeclarator>
                             |   <complexDeclarator>
<simpleDeclarator>           ::= <identifier>
<complexDeclarator>          ::= <arrayDeclarator>
<floatingPtType>             ::= FLOAT
                             |   DOUBLE
                             |   LONG DOUBLE
<integerType>                ::= <signedInt>
                             |   <unsignedInt>
<signedInt>                  ::= <signedShortInt>
                             |   <signedLongInt>
                             |   <signedLonglongInt>
<signedShortInt>             ::= SHORT
<signedLongInt>              ::= LONG
<signedLonglongInt>          ::= LONG LONG
<unsignedInt>                ::= <unsignedShortInt>
                             |   <unsignedLongInt>
                             |   <unsignedLonglongInt>
<unsignedShortInt>           ::= UNSIGNED SHORT
<unsignedLongInt>            ::= UNSIGNED LONG
<unsignedLonglongInt>        ::= UNSIGNED LONG LONG
<charType>                   ::= CHAR
<wideCharType>               ::= WCHAR
<booleanType>                ::= BOOLEAN
<octetType>                  ::= OCTET
<anyType>                    ::= ANY
<objectType>                 ::= OBJECT
<structType>                 ::= STRUCT <identifier> LCURLY <memberList> RCURLY
<memberList>                 ::= <member>+
<member>                     ::= <typeSpec> <declarators> SEMICOLON
<unionType>                  ::= UNION <identifier> SWITCH LPAREN <switchTypeSpec> RPAREN LCURLY <switchBody> RCURLY
<switchTypeSpec>             ::= <integerType>
                             |   <charType>
                             |   <booleanType>
                             |   <enumType>
                             |   <scopedName>
<switchBody>                 ::= <case>+
<case>                       ::= <caseLabelMany> <elementSpec> SEMICOLON
<caseLabel>                  ::= CASE <constExp> COLON
                             |   DEFAULT COLON
<elementSpec>                ::= <typeSpec> <declarator>
<enumType>                   ::= ENUM <identifier> LCURLY <enumeratorListMany> RCURLY
<enumerator>                 ::= <identifier>
<sequenceType>               ::= SEQUENCE LT <simpleTypeSpec> COMMA <positiveIntConst> GT
                             |   SEQUENCE LT <simpleTypeSpec> GT
<stringType>                 ::= STRING LT <positiveIntConst> GT
                             |   STRING
<wideStringType>             ::= WSTRING LT <positiveIntConst> GT
                             |   WSTRING
<arrayDeclarator>            ::= <identifier> <fixedArraySizeMany>
<fixedArraySize>             ::= LBRACKET <positiveIntConst> RBRACKET
<attrDcl>                    ::= <readonlyAttrSpec>
                             |   <attrSpec>
<exceptDcl>                  ::= EXCEPTION <identifier> LCURLY <memberAny> RCURLY
<opDcl>                      ::= <opAttributeMaybe> <opTypeSpec> <identifier> <parameterDcls> <raisesExprMaybe> <contextExprMaybe>
<opAttribute>                ::= ONEWAY
<opTypeSpec>                 ::= <paramTypeSpec>
                             | VOID
<parameterDcls>              ::= LPAREN <paramDclListMany> RPAREN
                             |   LPAREN RPAREN
<paramDcl>                   ::= <paramAttribute> <paramTypeSpec> <simpleDeclarator>
<paramAttribute>             ::= IN
                             |   OUT
                             |   INOUT
<raisesExpr>                 ::= RAISES LPAREN <scopedNameListMany> RPAREN
<contextExpr>                ::= CONTEXT LPAREN <stringLiteralListMany> RPAREN
<paramTypeSpec>              ::= <baseTypeSpec>
                             | <stringType>
                             | <wideStringType>
                             | <scopedName>
<fixedPtType>                ::= FIXED LT <positiveIntConst> COMMA <positiveIntConst> GT
<fixedPtConstType>           ::= FIXED
<valueBaseType>              ::= VALUEBASE
<constrForwardDecl>          ::= STRUCT <identifier>
                             |   UNION <identifier>
<import>                     ::= IMPORT <importedScope> SEMICOLON
<importedScope>              ::= <scopedName>
                             |   <stringLiteral>
<typeIdDcl>                  ::= TYPEID <scopedName> <stringLiteral>
<typePrefixDcl>              ::= TYPEPREFIX <scopedName> <stringLiteral>
<readonlyAttrSpec>           ::= READONLY ATTRIBUTE <paramTypeSpec> <readonlyAttrDeclarator>
<readonlyAttrDeclarator>     ::= <simpleDeclarator> <raisesExpr>
                             |   <simpleDeclaratorListMany>
<attrSpec>                   ::= ATTRIBUTE <paramTypeSpec> <attrDeclarator>
<attrDeclarator>             ::= <simpleDeclarator> <attrRaisesExpr>
                             |   <simpleDeclaratorListMany>
<attrRaisesExpr>             ::= <getExcepExpr> <setExcepExprMaybe>
                             |   <setExcepExpr>
<getExcepExpr>               ::= GETRAISES <exceptionList>
<setExcepExpr>               ::= SETRAISES <exceptionList>
<exceptionList>              ::= LPAREN <scopedNameListMany> RPAREN

# NOTE: Grammar rules 1 through 111 with the exception of the last three lines of rule 2 constitutes the portion of IDL that
# is not related to components.

<component>                  ::= <componentDcl>
                             |   <componentForwardDcl>
<componentForwardDcl>        ::= COMPONENT <identifier>
<componentDcl>               ::= <componentHeader> LCURLY <componentBody> RCURLY
<componentHeader>            ::= COMPONENT <identifier> <componentInheritanceSpecMaybe> <supportedInterfaceSpecMaybe>
<supportedInterfaceSpec>     ::= SUPPORTS <scopedNameListMany>
<componentInheritanceSpec>   ::= COLON <scopedName>
<componentBody>              ::= <componentExport>*
<componentExport>            ::= <providesDcl> SEMICOLON
                             |   <usesDcl> SEMICOLON
                             |   <emitsDcl> SEMICOLON
                             |   <publishesDcl> SEMICOLON
                             |   <consumesDcl> SEMICOLON
                             |   <attrDcl> SEMICOLON
<providesDcl>                ::= PROVIDES <interfaceType> <identifier>
<interfaceType>              ::= <scopedName>
                             |   OBJECT
<usesDcl>                    ::= USES <multipleMaybe> <interfaceType> <identifier>
<emitsDcl>                   ::= EMITS <scopedName> <identifier>
<publishesDcl>               ::= PUBLISHES <scopedName> <identifier>
<consumesDcl>                ::= CONSUMES <scopedName> <identifier>
<homeDcl>                    ::= <homeHeader> <homeBody>
<homeHeader>                 ::= HOME <identifier> <homeInheritanceSpecMaybe> <supportedInterfaceSpecMaybe> MANAGES <scopedName> <primaryKeySpecMaybe>
<homeIinheritanceSpec>       ::= COLON <scopedName>
<primaryKeySpec>             ::= PRIMARYKEY <scopedName>
<homeBody>                   ::= LCURLY <homeExportAny> RCURLY
<homeExport>                 ::= <export>
                             |   <factoryDcl> SEMICOLON
                             |   <finderDcl> SEMICOLON
<factoryDcl>                 ::= FACTORY <identifier> LPAREN [ <initParamDecls> ] RPAREN  <raisesExprMaybe>
<finderDcl>                  ::= FINDER <identifier>  LPAREN [ <initParamDecls> ] RPAREN  <raisesExprMaybe>
<event>                      ::= <eventDcl>
                             |   <eventAbsDcl>
                             |   <eventForwardDcl>
<eventForwardDcl>            ::= <abstractMaybe> EVENTTYPE <identifier>
<eventAbsDcl>                ::= ABSTRACT EVENTTYPE <identifier> <valueInheritanceSpecMaybe> LCURLY <exportAny> RCURLY
<eventDcl>                   ::= <eventHeader> LCURLY <valueElementAny> RCURLY
<eventHeader>                ::= <customMaybe> EVENTTYPE <identifier> <valueInheritanceSpecMaybe>

<importAny> ::= <import>*
<definitionMany> ::= <definition>+
<abstractOrLocal> ::= ABSTRACT | LOCAL
<abstractOrLocalMaybe> ::= <abstractOrLocal>
<abstractOrLocalMaybe> ::=
<interfaceInheritanceSpecMaybe> ::= <interfaceInheritanceSpec>
<interfaceInheritanceSpecMaybe> ::=
<interfaceNameListMany> ::= <interfaceName>+ separator => <comma>
<abstractMaybe> ::= ABSTRACT
<abstractMaybe> ::=
<valueInheritanceSpecMaybe> ::= <valueInheritanceSpec>
<valueInheritanceSpecMaybe> ::=
<exportAny> ::= <export>*
<valueElementAny> ::= <valueElement>*
<customMaybe> ::= CUSTOM
<customMaybe> ::=
<valueNameListMany> ::= <valueName>+ separator => <comma>
<truncatableMaybe> ::= TRUNCATABLE
<truncatableMaybe> ::=
<valueInheritanceSpec1Values> ::= COLON <truncatableMaybe> <valueNameListMany>
<valueInheritanceSpec1ValuesMaybe> ::= <valueInheritanceSpec1Values>
<valueInheritanceSpec1ValuesMaybe> ::=
<valueInheritanceSpec2Interfaces>   ::= SUPPORTS <interfaceNameListMany>
<valueInheritanceSpec2InterfacesMaybe> ::= <valueInheritanceSpec2Interfaces>
<valueInheritanceSpec2InterfacesMaybe> ::=
<publicOrPrivate> ::= PUBLIC | PRIVATE
<initParamDeclsMaybe> ::= <initParamDecls>
<initParamDeclsMaybe> ::=
<raisesExprMaybe> ::= <raisesExpr>
<raisesExprMaybe> ::=
<initParamDeclListMany> ::= <initParamDecl>+ separator => <comma>
<declaratorListMany> ::= <declarator>+ separator => <comma>
<caseLabelMany> ::= <caseLabel>+
<enumeratorListMany> ::= <enumerator>+ separator => <comma>
<fixedArraySizeMany> ::= <fixedArraySize>+
<memberAny> ::= <member>*
<opAttributeMaybe> ::= <opAttribute>
<opAttributeMaybe> ::=
<contextExprMaybe> ::= <contextExpr>
<contextExprMaybe> ::=
<paramDclListMany> ::= <paramDcl>+ separator => <comma>
<scopedNameListMany> ::= <scopedName>+ separator => <comma>
<stringLiteralListMany> ::= <stringLiteral>+ separator => <comma>
<simpleDeclaratorListMany> ::= <simpleDeclarator>+ separator => <comma>
<setExcepExprMaybe> ::= <setExcepExpr>
<setExcepExprMaybe> ::=
<componentInheritanceSpecMaybe> ::= <componentInheritanceSpec>
<componentInheritanceSpecMaybe> ::=
<supportedInterfaceSpecMaybe> ::= <supportedInterfaceSpec>
<supportedInterfaceSpecMaybe> ::=
<multipleMaybe> ::= MULTIPLE
<multipleMaybe> ::=
<homeInheritanceSpecMaybe> ::= <homeIinheritanceSpec>
<homeInheritanceSpecMaybe> ::=
<primaryKeySpecMaybe> ::= <primaryKeySpec>
<primaryKeySpecMaybe> ::=
<homeExportAny> ::= <homeExport>*
<comma> ::= COMMA
<coloncolon> ::= COLONCOLON

#
# Everything hardcoded is a lexeme, we want to have it blessed into an array
# The following is an exhaustive list of all IDL 3.5 keywords
#
SEMICOLON   ~ ';'
MODULE      ~ 'module'
LCURLY      ~ '{'
RCURLY      ~ '}'
INTERFACE   ~ 'interface'
COLON       ~ ':'
COLONCOLON  ~ '::'
VALUETYPE   ~ 'valuetype'
ABSTRACT    ~ 'abstract'
FACTORY     ~ 'factory'
LPAREN      ~ '('
RPAREN      ~ ')'
IN          ~ 'in'
CONST       ~ 'const'
EQUAL       ~ '='
OR          ~ '|'
XOR         ~ '^'
AND         ~ '&'
RSHIFT      ~ '>>'
LSHIFT      ~ '<<'
PLUS        ~ '+'
MINUS       ~ '-'
TILDE       ~ '~'
MUL         ~ '*'
DIV         ~ '/'
MOD         ~ '%'
TRUE        ~ 'TRUE'
FALSE       ~ 'FALSE'
TYPEDEF     ~ 'typedef'
NATIVE      ~ 'native'
FLOAT       ~ 'float'
DOUBLE      ~ 'double'
LONG        ~ 'long'
SHORT       ~ 'short'
UNSIGNED    ~ 'unsigned'
CHAR        ~ 'char'
WCHAR       ~ 'wchar'
BOOLEAN     ~ 'boolean'
OCTET       ~ 'octet'
ANY         ~ 'any'
OBJECT      ~ 'Object'
STRUCT      ~ 'struct'
UNION       ~ 'union'
CASE        ~ 'case'
DEFAULT     ~ 'default'
ENUM        ~ 'enum'
SEQUENCE    ~ 'sequence'
LT          ~ '<'
GT          ~ '>'
SWITCH      ~ 'switch'
COMMA       ~ ','
STRING      ~ 'string'
WSTRING     ~ 'wstring'
LBRACKET    ~ '['
RBRACKET    ~ ']'
EXCEPTION   ~ 'exception'
ONEWAY      ~ 'oneway'
VOID        ~ 'void'
OUT         ~ 'out'
INOUT       ~ 'inout'
RAISES      ~ 'raises'
CONTEXT     ~ 'context'
FIXED       ~ 'fixed'
VALUEBASE   ~ 'ValueBase'
IMPORT      ~ 'import'
TYPEID      ~ 'typeid'
TYPEPREFIX  ~ 'typeprefix'
READONLY    ~ 'readonly'
ATTRIBUTE   ~ 'attribute'
GETRAISES   ~ 'getraises'
SETRAISES   ~ 'setraises'
COMPONENT   ~ 'component'
SUPPORTS    ~ 'supports'
PROVIDES    ~ 'provides'
USES        ~ 'uses'
EMITS       ~ 'emits'
PUBLISHES   ~ 'publishes'
CONSUMES    ~ 'consumes'
HOME        ~ 'home'
MANAGES     ~ 'manages'
PRIMARYKEY  ~ 'primarykey'
FINDER      ~ 'finder'
EVENTTYPE   ~ 'eventtype'
LOCAL       ~ 'local'
CUSTOM      ~ 'custom'
TRUNCATABLE ~ 'truncatable'
PUBLIC      ~ 'public'
PRIVATE     ~ 'private'
MULTIPLE    ~ 'multiple'
#
# Copied from C language
#
<stringLiteral> ::= STRINGLITERALUNIT+
:lexeme ~ <STRINGLITERALUNIT>
STRING_LITERAL_INSIDE ~ [^"\\\n]
STRING_LITERAL_INSIDE ~ ES
STRING_LITERAL_INSIDE_any ~ STRING_LITERAL_INSIDE*
STRINGLITERALUNIT ~ SP_maybe '"' STRING_LITERAL_INSIDE_any '"' WS_any

<wideStringLiteral> ::= WIDESTRINGLITERALUNIT+
:lexeme ~ <WIDESTRINGLITERALUNIT>
WIDESTRINGLITERALUNIT ~ SP_maybe 'L"' STRING_LITERAL_INSIDE_any '"' WS_any

<integerLiteral> ::= ICONSTANT
:lexeme ~ <ICONSTANT>
ICONSTANT ~ HP H_many IS_maybe
          | BP B_many IS_maybe   # Gcc extension: binary constants
          | NZ D_any IS_maybe
          | '0' O_any IS_maybe
I_CONSTANT_INSIDE ~ [^'\\\n]
I_CONSTANT_INSIDE ~ ES
I_CONSTANT_INSIDE_many ~ I_CONSTANT_INSIDE+

<identifier> ::= IDENTIFIER
:lexeme ~ <IDENTIFIER> priority => -1

IDENTIFIER          ~ L A_any

#
# Original C includes this definition in ICONSTANT
#
<characterLiteral> ::= CHARACTERLITERAL
:lexeme ~ <CHARACTERLITERAL>
CHARACTERLITERAL ~ CP_maybe QUOTE I_CONSTANT_INSIDE_many QUOTE

<wideCharacterLiteral> ::= WIDECHARACTERLITERAL
:lexeme ~ <WIDECHARACTERLITERAL>
WIDECHARACTERLITERAL ~ 'L' QUOTE I_CONSTANT_INSIDE_many QUOTE

dD ~ [dD]
<fixedPtLiteral> ::= FIXEDPTLITERAL
:lexeme ~ <FIXEDPTLITERAL>
FIXEDPTLITERAL ~ D_many '.' D_many dD
                 |        '.' D_many dD
                 | D_many '.'        dD

<floatingPtLiteral> ::= FCONSTANT
:lexeme ~ <FCONSTANT>
FCONSTANT ~ D_many E FS_maybe
          | D_any '.' D_many E_maybe FS_maybe
          | D_many '.' E_maybe FS_maybe
          | HP H_many P FS_maybe
          | HP H_any '.' H_many P FS_maybe
          | HP H_many '.' P FS_maybe

#
# G0 helpers
#
O          ~ [0-7]
O_any      ~ O*
D          ~ [0-9]
D_any      ~ D*
D_many     ~ D+
NZ         ~ [1-9]
L          ~ [a-zA-Z_]
A          ~ [a-zA-Z_0-9]
A_any      ~ A*
H          ~ [a-fA-F0-9]
H_any      ~ H*
H_many     ~ H+
HP         ~ '0' [xX]
B          ~ [0-1]
B_many     ~ B+
BP         ~ '0' [bB]
SIGN_maybe ~ [+-]
SIGN_maybe ~
E          ~ [Ee] SIGN_maybe D_many
E_maybe    ~ E
E_maybe    ~
P          ~ [Pp] SIGN_maybe D_many
FS         ~ [fFlL]
FS_maybe   ~ FS
FS_maybe   ~
LL         ~ 'll' | 'LL' | [lL]
LL_maybe   ~ LL
LL_maybe   ~
U          ~ [uU]
U_maybe    ~ U
U_maybe    ~
IS         ~ U LL_maybe | LL U_maybe
IS_maybe   ~ IS
IS_maybe   ~
CP         ~ [uU]    # L extracted - c.f. WIDECHARACTERLITERAL
CP_maybe   ~ CP
CP_maybe   ~
SP         ~ 'u8' | [uUL]
SP_maybe   ~ SP
SP_maybe   ~
ES_AFTERBS ~ [\'\"\?\\abfnrtv]
           | O
           | O O
           | O O O
           | 'x' H_many
ES         ~ BS ES_AFTERBS
WS         ~ [ \t\v\n\f]
WS_any     ~ WS*
WS_many    ~ WS+
QUOTE     ~ [']
BS        ~ '\'

#
# discards of the C language
#
############################################################################
# Discard of a C comment, c.f. https://gist.github.com/jeffreykegler/5015057
############################################################################
<C style comment> ~ '/*' <comment interior> '*/'
<comment interior> ~
    <optional non stars>
    <optional star prefixed segments>
    <optional pre final stars>
<optional non stars> ~ [^*]*
<optional star prefixed segments> ~ <star prefixed segment>*
<star prefixed segment> ~ <stars> [^/*] <optional star free text>
<stars> ~ [*]+
<optional star free text> ~ [^*]*
<optional pre final stars> ~ [*]*
:discard ~ <C style comment>

##########################
# Discard of a C++ comment
##########################
<Cplusplus style comment> ~ '//' <Cplusplus comment interior>
<Cplusplus comment interior> ~ [^\n]*
:discard ~ <Cplusplus style comment>

###########################
# TAKE CARE: preprocessor commands are IGNORED in this version
# Discard of a Perl comment
###########################
<_Cpp style directive> ~ '#' <_Cpp style directive interior>
<_Cpp style directive interior> ~ [^\n]*
CPPSTYLEDIRECTIVE ~ <_Cpp style directive>
:discard ~ <_Cpp style directive>

####################
# WhiteSpace discard
####################
:discard ~ WS_many       # whitespace separates tokens

