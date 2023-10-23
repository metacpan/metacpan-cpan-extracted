package Devel::Declare::Parser;
use strict;
use warnings;

require Devel::Declare::Interface;
use Devel::Declare;
use B::Compiling;
use B::Hooks::EndOfScope;
use Scalar::Util qw/blessed/;
use Carp;

our $VERSION = '0.021';

sub new {
    my $class = shift;
    my ( $name, $dec, $offset ) = @_;
    return bless( [ $name, $dec, $offset, $offset ], $class );
}

sub process {
    my $self = shift;
    return unless $self->pre_parse();
    return unless $self->parse();
    return unless $self->post_parse();
    return unless $self->rewrite();
    return unless $self->write_line();
    return unless $self->edit_line();
    return 1;
}

###############
# Abstractable
#

sub quote_chars {( qw/ [ ( ' " / )};
sub end_chars {( qw/ { ; / )};

sub inject {()}

sub pre_parse {
    my $self = shift;
    $self->skip_declarator;
    $self->skipspace;

    return if $self->is_defenition;
    return if $self->is_contained;
    return if $self->is_arrow_contained;
    return 1;
}

sub parse {
    my $self = shift;
    $self->parts( $self->strip_remaining_items );
    $self->end_char( $self->peek_num_chars(1));
    $self->strip_length(1) if $self->end_char eq '{';
    return 1;
}

sub post_parse { 1 }

sub rewrite {
    my $self = shift;
    $self->new_parts( $self->parts );
    1;
}

sub write_line {
    my $self = shift;
    my $newline = $self->open_line();

    $newline .= join( ', ',
        map { $self->format_part($_) }
            @{ $self->new_parts || [] }
    );

    $newline .= $self->close_line();

    my $line = $self->line;
    substr( $line, $self->offset, 0 ) = $newline;
    $self->line( $line );
    $self->diag( "New Line: " . $line . "\n" )
        if $self->DEBUG;

    1;
}

sub edit_line { 1 }

sub open_line { "(" }

sub close_line {
    my $self = shift;
    my $end = $self->end_char();
    return ")" if $end ne '{';
    return ( @{$self->new_parts || []} ? ', ' : '' )
         . 'sub'
         . ( $self->prototype ? $self->prototype : '' )
         .' { '
         . join( '; ',
            $self->inject,
            $self->_block_end_injection,
         )
         . '; ';
}

##############
# Stash
#

our %STASH;

sub _stash {
    my ( $item ) = @_;
    my $id = "$item";
    $STASH{$id} = $item;
    return $id;
}

sub _unstash {
    my ( $id ) = @_;
    return delete $STASH{$id};
}

##############
# Accessors
#

my @ACCESSORS = qw/parts new_parts end_char prototype contained/;

{
    my $count = 0;
    for my $accessor ( qw/name declarator original_offset offset/, @ACCESSORS ) {
        my $idx = $count++;
        no strict 'refs';
        *$accessor = sub {
            my $self = shift;
            ( $self->[$idx] ) = @_ if @_;
            return $self->[$idx];
        };
    }
    no strict 'refs';
    *{ __PACKAGE__ . '::_last_index' } = sub { $count };
}

sub add_accessor {
    my $class = shift;
    my ( $accessor ) = @_;
    no strict 'refs';
    my $idx = $class->_last_index + ${ $class . '::_LAST_INDEX' }++;
    *{ $class . '::' . $accessor } = sub {
        my $self = shift;
        ( $self->[$idx] ) = @_ if @_;
        return $self->[$idx];
    };
}

###############
# Informational
#

our %QUOTEMAP = (
    '(' => ')',
    '{' => '}',
    '[' => ']',
    '<' => '>',
);

sub end_quote {
    my $self = shift;
    my ( $start ) = @_;
    return $QUOTEMAP{ $start } || $start;
}

sub linenum  { PL_compiling->line }
sub filename { PL_compiling->file }

sub has_comma {
    my $self = shift;
    grep { $_ eq ',' } $self->has_non_string_or_quote_parts;
}

sub has_fat_comma {
    my $self = shift;
    grep { $_ eq '=>' } $self->has_non_string_or_quote_parts;
}

sub has_non_string_or_quote_parts {
    my $self = shift;
    grep { !ref($_) } @{ $self->parts };
}

sub has_string_or_quote_parts {
    my $self = shift;
    grep { ref($_) } @{ $self->parts };
}

sub has_keyword {
    my $self = shift;
    my ( $word ) = @_;
    return unless $word;
    grep {
        ref( $_ ) ? ($_->[1] eq $word) : ($_ eq $word)
    } @{ $self->parts };
}

################
# Debug
#

our $DEBUG = 0;
sub DEBUG {shift; ( $DEBUG ) = @_ if @_; $DEBUG }

sub diag { warn( _debug(@_)) }
sub bail { die( _debug(@_))  }

sub _debug {
    shift if blessed( $_[0] );

    my @caller = caller(1);
    my @msgs = (
        @_,
        DEBUG() ? (
            "\nCaller:      " . $caller[0] . "\n",
            "Caller file: " . $caller[1] . "\n",
            "Caller Line: " . $caller[2] . "\n",
        ) : (),
    );
    return ( @msgs, " at " . filename() . " line " . linenum() . "\n" );
}

################
# Line manipulation and advancement
#

sub line {
    my $self = shift;
    Devel::Declare::set_linestr($_[0]) if @_;
    return Devel::Declare::get_linestr();
}

sub advance {
    my $self = shift;
    my ( $len ) = @_;
    return unless $len;
    $self->offset( $self->offset + $len );
}

sub strip_length {
    my $self = shift;
    my ($len) = @_;
    return unless $len;

    my $linestr = $self->line();
    substr($linestr, $self->offset, $len) = '';
    $self->line($linestr);
}

sub skip_declarator {
    my $self = shift;
    my $item = $self->peek_is_other;
    my $name = $self->name;
    if ( $item =~ m/^(.*)$name/ ) {
        $self->original_offset(
            $self->original_offset + length($1)
        );
    }
    $self->advance( length($item) );
}

sub skipspace {
    my $self = shift;
    $self->advance(
        Devel::Declare::toke_skipspace( $self->offset )
    );
}

################
# Public parsing interface
#

sub is_defenition {
    my $self = shift;
    my $name = $self->declarator;
    return 1 if $self->line =~ m/sub[\s\n]+$name/sm;
    return 0;
}

sub is_contained {
    my $self = shift;
    return 0 unless $self->peek_num_chars(1);
    return 0 if $self->peek_num_chars(1) ne '(';
    $self->contained(1);
    return 1;
}

sub is_arrow_contained {
    my $self = shift;
    $self->skipspace;

    #Strip first item
    my $first = $self->strip_item;
    my $offset = $self->offset;

    # look at whats next
    $self->skipspace;
    my $stuff = $self->peek_remaining();

    # Put first back.
    my $line = $self->line;
    substr( $line, $offset, 0 ) = $self->format_part( $first, 1 ) || "";
    $self->offset( $offset );
    $self->line( $line );

    return 1 if $stuff =~ m/^=>[\s\n]*\(/sm;
}

sub peek_item_type {
    my $self = shift;
    $self->skipspace;
    return 'quote' if $self->peek_is_quote;
    return 'word'  if $self->peek_is_word;
    return 'block' if $self->peek_is_block;
    return 'end'   if $self->peek_is_end;
    return 'other' if $self->peek_is_other;
    return undef;
}

sub peek_item {
    my $self = shift;
    $self->skipspace;

    my $type = $self->peek_item_type;
    return unless $type;

    my $method = "peek_$type";
    return unless $self->can( $method );

    my $item = $self->$method();
    return unless $item;

    return $item unless wantarray;
    return ( $item, $type );
}

sub peek_quote {
    my $self = shift;
    $self->skipspace;

    my $start = substr($self->line, $self->offset, 3);
    my $charstart = substr($start, 0, 1);
    return unless $self->peek_is_quote( $start, $charstart );

    my ( $length, $quoted ) = $self->_quoted_from_dd();

    return [ $quoted, $charstart ];
}

sub peek_word {
    my $self = shift;
    $self->skipspace;
    my $len = $self->peek_is_word;
    return unless $len;

    my $linestr = $self->line();
    my $name = substr($linestr, $self->offset, $len);
    return [ $name, undef ];
}

sub peek_other {
    my $self = shift;
    $self->skipspace;
    return if $self->peek_is_word;
    return if $self->peek_is_quote;
    return if $self->peek_is_end;
    return if $self->peek_is_block;
    return $self->peek_is_other;
}

sub peek_is_quote {
    my $self = shift;
    my ( $start ) = $self->peek_num_chars(1);
    return (grep { $_ eq $start } $self->quote_chars )
        || undef;
}

sub peek_is_word {
    my $self = shift;
    return $self->_peek_is_package
        || $self->_peek_is_word;
}

sub peek_is_block {
    my $self = shift;
    my ( $start ) = $self->peek_num_chars(1);
    return ($start eq '{')
        || undef;
}

sub peek_is_end {
    my $self = shift;
    my ( $start ) = $self->peek_num_chars(1);
    my ($end) = grep { $start eq $_ } $self->end_chars;
    return $end
        || $self->peek_is_block;
}

sub peek_is_other {
    my $self = shift;
    my $linestr = $self->line;
    substr( $linestr, 0, $self->offset ) = '';
    my $quote = join( '', $self->quote_chars );
    return unless $linestr =~ m/^([^\s;{$quote]+)/;
    return $1;
}

sub peek_num_chars {
    my $self = shift;
    my @out = map { substr($self->line, $self->offset, $_) } @_;
    return @out if wantarray;
    return $out[0];
}

sub strip_item {
    my $self = shift;
    return $self->_item_via_( 'strip_length' );
}

sub strip_remaining_items {
    my $self = shift;
    my @parts;
    while ( my $part = $self->strip_item ) {
        push @parts => $part;
    }
    return \@parts;
}

sub peek_remaining {
    my $self = shift;
    return substr( $self->line, $self->offset );
}

###############
# Private parser interface
#

sub _peek_is_word {
    my $self = shift;
    return Devel::Declare::toke_scan_word($self->offset, 1)
        || undef;
}

sub _peek_is_package {
    my $self = shift;
    my $start = $self->peek_num_chars(1);
    return unless $start =~ m/^[A-Za-z_]$/;
    return unless $self->peek_remaining =~ m/^(\w+::[\w:]+)/;
    return length($1);
}

sub _linestr_offset_from_dd {
    my $self = shift;
    return Devel::Declare::get_linestr_offset()
}

sub _quoted_from_dd {
    my $self = shift;
    my $length = Devel::Declare::toke_scan_str($self->offset);
    my $quoted = Devel::Declare::get_lex_stuff();
    Devel::Declare::clear_lex_stuff();

    return ( $length, $quoted );
}

sub _item_via_ {
    my $self = shift;
    my ( $move_method ) = @_;

    my ( $item, $type ) = $self->peek_item;
    return unless $item;

    $self->_move_via_( $move_method, $type, $item );
    return $item;
}

sub _move_via_ {
    my $self = shift;
    my ( $method, $type, $item ) = @_;

    croak( "$method is not a valid move method" )
        unless $self->can( $method );

    if ( $type eq 'word' ) {
        $self->$method( $self->peek_is_word );
    }
    elsif ( $type eq 'quote' ) {
        my ( $len ) = $self->_quoted_from_dd();
        $self->$method( $len );
    }
    elsif ( $type eq 'other' ) {
        $self->$method( length( $item ));
    }
}

#############
# Rewriting interface
#

sub format_part {
    my $self = shift;
    my ( $part, $no_added_quotes ) = @_;
    return unless $part;
    return $part unless ref($part);
    return $part->[0] if $no_added_quotes && !$part->[1];
    return "'" . $part->[0] . "'"
        unless $part->[1];
    return $part->[1] . $part->[0] . $self->end_quote( $part->[1] );
}

#############
# Codeblock munging
#

sub _block_end_injection {
    my $self = shift;
    my $class = blessed( $self );

    my $id = _stash( $self );

    return "BEGIN { $class\->_edit_block_end('$id') }";
}

sub _edit_block_end {
    my $class = shift;
    my ( $id ) = @_;

    on_scope_end {
        $class->_scope_end($id);
    };
}

sub _scope_end {
    my $class = shift;
    my ( $id ) = @_;
    my $self = _unstash( $id );

    my $oldlinestr = $self->line;
    my $linestr = $oldlinestr;
    $self->offset( $self->_linestr_offset_from_dd() );
    if ( $linestr =~ m/}\s*$/ ) {
        substr($linestr, $self->offset, 0) = ' );';
    }
    else {
        substr($linestr, $self->offset, 0) = ' ) ';
    }
    $self->line($linestr);
    $self->diag(
        "Old Line: " . $oldlinestr . "\n",
        "New Line: " . $linestr . "\n",
    ) if $self->DEBUG;

}

1;

__END__

=head1 NAME

Devel::Declare::Parser - Higher level interface to Devel-Declare

=head1 DESCRIPTION

Devel-Declare-Parser is a higher-level API sitting on top of L<Devel::Declare>.
It is used by L<Devel::Declare::Exporter> to simplify exporting of
L<Devel::Declare> magic. Writing custom parsers usually only requires
subclassing this module and overriding a couple methods.

=head1 DOCUMENTATION

=over 4

=item L<Devel::Declare::Interface>

This is the primary interface for those who want to use Devel-Declare-Parser
magic, and don't want to use Exporter-Declare.

=item L<Devel::Declare::Parser>

This Document covers the API for Devel::Declare::Parser. This API is a useful
reference when writing or modifying a custom parser.

=back

=head1 SYNOPSIS

    package Devel::Declare::Parser::MyParser;
    use strict;
    use warnings;

    use base 'Devel::Declare::Parser';
    use Devel::Declare::Interface;

    # Create an accessor (See INTERNALS WARNING below)
    __PACKAGE__->add_accessor( 'my_accessor' );

    # Register the parser for use.
    Devel::Declare::Interface::register_parser( 'myparser' );

    # Override the rewrite() method to take the parsed bits (parts) and put the
    # ones you want into new_parts.
    sub rewrite {
        my $self = shift;

        my $parts = $self->parts;

        $new_parts = $self->process_parts( $parts );

        $self->new_parts( $new_parts );
        1;
    }

    1;

=head1 OVERVIEW

This is a brief overview of how a parser is used.

=head2 WORKFLOW

=over 4

=item Parser is constructed

Name, Declarator, and Offset are provided by Devel::Declare.

=item The process() method is called

The process method calls all of the following in sequence, if any returns
false, process() will return.

=over 8

=item pre_parse()

Check if we want to process the line at all.

=item parse()

Turn the line into 'parts' (see below).

=item post_parse()

Hook, currently does nothing.

=item rewrite()

Hook, currently takes all the arguments between the declarator and the
codeblock/semicolon (which have been turned into 'parts' structures in the
parts() attribute) and puts them into the new_parts() attribute.

This is usually the method you want to override.

=item write_line()

Opens, fills in, and closes the line as a string, then rewrites the actual
line using Devel::Declare.

=item edit_line()

Hook, currently does nothing.

=back

=back

=head2 "PARTS"

'Parts' are datastructures created by the parse() method. Every argument on the
line (space separated) up until an opening curly brace ({) or a semicolon (;)
will be turned into a part. Here are the parts to expect:

Parts will either be a plain string, or an arrayref containing a string and the
quote character used to define the string. "String" or [ "String", '"' ].
Variables and operators (excluding those containing only string characters) are
typically the only parts left in a plain string form.

See the format_parts() method for an easy way to get what you need from a
'part' datastructure.

=over 4

=item Bareword or Package Name

A bareword name is anything that starts with [a-zA-z] and contains only
alpha-numerics plus underscore. It is also not quoted. Examples include
my_name, something5, etc.

The structure will be an arrayref, the first element will be the string form of
the bareword name, the second element will be undef.

Example:

    # my_keyword My::Package;
    $part = [
        'My::Package',
        undef,
    ];

    # my_keyword some_name;
    $part = [
        "some_name",
        undef,
    ];

=item Quoted or Enclosed Element

A quoted or enclosed element includes strings quoted with single or double
quotes, and text contained within opening and closing brackets, braces or
parens (excluding the curly brace '{').

Example Structures:

    # my_keyword "double quoted string";
    $part = [
        'double quoted string',
        '"',
    ];

    # my_keyword 'single quoted string';
    $part = [
        'double quoted string',
        '"',
    ];

    # my_keyword ... ( a => 'b', c => 'd' );
    $part = [
        " a => 'b', c => 'd' ",
        "(",
    ];

=item Variable or Operator

Anything starting with a non-alphanumeric, non-quoting character will be placed
as-is (not interpolated) into a string. This catches most variables and
operators, the exception are alpha-numeric operators such as 'eq', 'gt', 'cmp',
etc. Eventually I plan to add logic to catch all operators, but it appears I
will have to hard-code them.

    # my_keyword $variable
    $part = '$variable';

    # my_keyword <=>
    $part = '<=>';

=back

=head2 EVENTUAL OUTPUT

Parser is designed such that it will transform any and all uses of your keyword
into proper function calls.

That is this:

    function x { ... }

Will become this:

    function( 'x', sub { ... });

B<Note> Parser does not read in the entire codeblock, rather it injects a
statement into the start of the block that uses a callback to attach the ');'
to the end of the statement. This is per the documentation of
L<Devel::Declare>. Reading in the entire sub is not a desirable scenario.

=head1 DEVEL-DECLARE-PARSER API

=head2 INTERNALS WARNING

B<Parser objects are blessed arrays, not hashrefs.>

If you want to create a new accessor use the add_accessor() class method. It
will take care of assigning an unused array element to the attribute, and will
create a read/write accessor sub for you.

    __PACKAGE__->add_accessor( 'my_accessor' );

There are many public and private methods on the parser base class. Only the
public methods are fully documented. Be sure to refer often to the list of
private methods at the end of this document, accidently overriding a private
method could have devastating consequences.

=head2 CLASS METHODS

=over 4

=item $class->new( $name, $declarator, $offset )

The constructor, L<DO NOT OVERRIDE THIS!>

=item $class->DEBUG($bool)

Turn debugging on/off. This will output the line after it has been modified, as
well as some context information.

B<NOTE:> This has a global effect, all parsers will start debugging.

=back

=head2 UTILITY METHODS

=over 4

=item bail( @messages )

Like croak, dies providing you context information. Since any death occurs
inside the parser, carp provides useless information.

=item diag( @message )

Like carp, warns providing you context information. Since the warn occurs
inside the parser carp provides useless information.

=item end_quote($start_char)

Find the end-character for the provide starting quote character. As in '{'
returns '}' and '(' returns ')'. If there is no counter-part the start
character is returned: "'" returns "'".

=item filename()

Filename the rewrite is occurring against.

=item linenum()

Linenum the rewrite is occurring on.

=item format_part()

Returns the stringified form of a part datastructure. For variables and
operators that is just the item itself as a string. For barewords or package
names it is the item itself with single quotes wrapped around it. For quoted
items it is the string wrapped in its proper quoting characters. If a second
parameter is provided (and true) no single quotes will be added to barewords.

=back

=head2 ACCESSORS

These are the read/write accessors used by Parser. B<Not all of these act on an
array element, some will directly alter the current line.>

=over 4

=item line()

This will retrieve the current line from Devel-Declare. If given a value, that
value will be set as the current line using Devel-Declare.

=item name()

Name of the declarator as provided via the parser.

=item declarator()

Name of the declarator as provided via the Devel-Declare.

=item original_offset()

Offset on the line when the parsing was started.

=item offset()

Current line offset.

=item parts()

Arrayref of parts (may be undef)

=item new_parts()

Arrayref of new parts (may be undef)

=item end_char()

Will be set to the character just after the completely parsed line (usually '{'
or ';')

=item prototype()

Used internally for prototype tracking.

=item contained()

True if the parser determined this was a contained call. This means your
keyword was followed by an opening paren, and the statement ended with a
closing paren and semicolon. By default Parser will not modify such lines.

=back

=head2 OVERRIDABLE METHODS

These are methods you can, should, or may override in your baseclass.

=over 4

=item quote_chars()

Specify the starting characters for quoted strings. (returns a list)

=item end_chars()

Characters to recognise as end of statement characters (';' and '{') (returns a
list)

=item inject()

Code to inject into functions enhanced by this parser.

=item pre_parse()

Check if we want to process the line at all.

=item parse()

Turn the line into 'parts'.

=item post_parse()

Hook, currently does nothing.

=item rewrite()

Hook, currently takes all the arguments between the declarator and the
codeblock/semicolon (which have been turned into 'parts' structures in the
parts() attribute) and puts them into the new_parts() attribute.

This is usually the method you want to override.

=item write_line()

Opens, fills in, and closes the line as a string, then rewrites the actual
line using Devel::Declare.

=item edit_line()

Hook, currently does nothing.

=item open_line()

Usually returns '('. This is how to start a line following your keyword

=item close_line()

End the line, this means either re-inserting the opening '{' on the codeblock,
along with any injections, or returning ');'

=back

=head2 POSITION TRACKING

=over 4

=item advance( $num_chars )

Advances the offset by $num_chars.

=item skip_declarator()

Skips the declarator at the start of the line.

=item skipspace()

Advances the offset past any whitespace.

=back

=head2 LINE EXAMINATION (NON-MODIFYING)

These are used by pre_parse() to examine the line prior to any modification.

=over 4

=item is_contained()

True if the line is of the format:

    keyword( ... );

=item is_arrow_contained()

True if the line is of the format:

    keyword word_or_string => ( ... );

=item is_defenition()

True if the line matches the regex m/sub[\s\n]+$name/sm

=back

=head2 PART EXAMINATION

These are methods that let you investigate the parts already parsed and placed
in the parts() attribute.

=over 4

=item has_non_string_or_quote_parts()

Returns a list of parts that are not strings, quotes, or barewords.

=item has_string_or_quote_parts()

Returns a list of parts that are strings, quotes, or barewords.

=item has_keyword( $word )

Check for a keyword in the parts

=item has_comma()

=item has_fat_comma()

=back

=head2 LINE EXAMINATION (MODIFYING)

This examines the line returning part structures and removing elements from the
line each time they are called.

=over 4

=item strip_item()

=item strip_length()

=item strip_remaining_items()

=back

=head2 LOOKING AHEAD

These methods help the parser determine what comes next in a line. In most
cases these are non-modifying.

=over 4

=item peek_is_block()

=item peek_is_end()

=item peek_is_other()

=item peek_is_quote()

=item peek_is_word()

=item peek_item()

=item peek_item_type()

=item peek_num_chars()

=item peek_other()

=item peek_quote()

=item peek_remaining()

=item peek_word()

=back

=head2 PRIVATE METHODS

Do not use these, and definitely do not override them in a subclass.

=over 4

=item _block_end_injection()

=item _debug()

=item _edit_block_end()

=item _item_via_()

=item _linestr_offset_from_dd()

=item _move_via_()

=item _peek_is_package()

=item _peek_is_word()

=item _quoted_from_dd()

=item _scope_end()

=item _stash()

=item _unstash()

=back

=head1 FENNEC PROJECT

This module is part of the Fennec project. See L<Fennec> for more details.
Fennec is a project to develop an extendable and powerful testing framework.
Together the tools that make up the Fennec framework provide a potent testing
environment.

The tools provided by Fennec are also useful on their own. Sometimes a tool
created for Fennec is useful outside the greator framework. Such tools are
turned into their own projects. This is one such project.

=over 2

=item L<Fennec> - The core framework

The primary Fennec project that ties them all together.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Devel-Declare-Parser is free software; Standard perl licence.

Devel-Declare-Parser is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.
