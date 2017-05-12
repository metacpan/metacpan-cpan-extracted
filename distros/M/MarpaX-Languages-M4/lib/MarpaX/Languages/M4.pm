use Moops;
use MarpaX::Languages::M4::Impl::Default;

# PODNAME: MarpaX::Languages::M4

# ABSTRACT: M4 pre-processor

class MarpaX::Languages::M4 {
    extends 'MarpaX::Languages::M4::Impl::Default';

    our $VERSION = '0.017'; # VERSION

    our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

    #
    # We are lazy and just explicitely proxy all Impl methods
    #
    method quote (@args)            { $self->impl_quote(@args) }
    method unquote (@args)          { $self->impl_unquote(@args) }
    method appendValue (@args)      { $self->impl_appendValue(@args) }
    method value (@args)            { $self->impl_value(@args) }
    method valueRef (@args)         { $self->impl_valueRef(@args) }
    method parseIncremental (@args) { $self->impl_parseIncremental(@args) }
    method parse (@args)            { $self->impl_parse(@args) }
    method unparsed (@args)         { $self->impl_unparsed(@args) }
    method setEoi (@args)           { $self->impl_setEoi(@args) }
    method eoi (@args)              { $self->impl_eoi(@args) }
    method raiseException (@args)   { $self->impl_raiseException(@args) }
    method file (@args)             { $self->impl_file(@args) }
    method line (@args)             { $self->impl_line(@args) }
    method rc (@args)               { $self->impl_rc(@args) }
    method isImplException (@args)  { $self->impl_isImplException(@args) }
    method macroExecute (@args)     { $self->impl_macroExecute(@args) }
    method macroCallId (@args)      { $self->impl_macroCallId(@args) }
    method nbInputProcessed (@args) { $self->impl_nbInputProcessed(@args) }
    method readFromStdin (@args)    { $self->impl_readFromStdin(@args) }
    method canLog (@args)           { $self->impl_canLog(@args) }
    method debugFile (@args)        { $self->impl_debugFile(@args) }
    method defaultWarnMacroSequence (ClassName $class: @args) { $class->impl_defaultWarnMacroSequence(@args) }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::M4 - M4 pre-processor

=head1 VERSION

version 0.017

=head1 SYNOPSIS

     use POSIX qw/EXIT_SUCCESS/;
     use MarpaX::Languages::M4;
     use Log::Any;
     use Log::Any::Adapter;
     use Log::Any::Adapter::Callback;

     Log::Any::Adapter->set('Callback', min_level => 'trace', logging_cb => \&_logging_cb);

     my $m4 = MarpaX::Languages::M4->new_with_options();
     $m4->parse('debugmode(`V\')m4wrap(`test\')');
     print "Value: " . $m4->value . "\n";
     print "Rc: " . $m4->rc . "\n";

     sub _logging_cb {
         my ($method, $self, $format, @params) = @_;
         printf STDERR  "$format\n", @args;
     }

=head1 DESCRIPTION

This package is an implementation of M4.

=head1 METHODS

=head2 $class->new(%options --> ConsumerOf[M4Impl])

Please do m4pp --help for a list of all options. Returns a new M4 object instance.

=head2 $self->quote(Str $string --> Str)

Returns $string enclosed by current quote start and quote end.

=head2 $self->unquote(Str $string --> Str)

Returns the unquoted $string.

=head2 $self->appendValue(Str $result --> ConsumerOf[M4Impl])

Append string $result to M4 preprocessing output.

=head2 $self->value(--> Str)

Return M4 preprocessing output.

=head2 $self->valueRef(--> Ref['SCALAR'])

Return a reference to the M4 preprocessing output.

=head2 $self->parseIncremental(Str $input --> ConsumerOf[M4Impl])

Parses $input. Can be called any number of times.

=head2 $self->parse(Str $input --> Str)

Wrapper on parseIncremental(). Calling this method parses a single input and disable any later call to parseIncremental().

=head2 $self->unparsed(--> Str)

Returns the input not yet parsed. For example, when input ends with a macro call that requires parameters, and the parameters list is not complete.

=head2 $self->setEoi(--> ConsumerOf[M4Impl])

Turns on end-of-input flag. Then no call to parseIncremental() or parse() will be possible.

=head2 $self->eoi(--> Bool)

Get current end-of-input flag.

=head2 $self->raiseException(Str $message --> Undef)

Log $message to error stream and throw an exception of class ImplException.

=head2 $self->file(--> Str)

Get current file name. See NOTES.

=head2 $self->line(--> PositiveOrZeroInt)

Get current line number. See NOTES.

=head2 $self->rc(--> Int)

Get current parse return code. Should be POSIX::EXIT_SUCCESS() or POSIX::EXIT_FAILURE().

=head2 $self->isImplException(Any $obj --> Bool)

Return a boolean saying if $obj argument is an ImplException consumer.

=head2 $self->macroExecute(ConsumerOf[M4Macro] $macro, @args --> Str|M4Macro)

Execute macro $macro with arguments @args. Output is dependent of current parsing context, and can return an internal token instead of a string.

=head2 $self->macroCallId(--> PositiveOrZeroInt)

Return current macro internal call identifier. This number increases every time a macro is called.

=head2 $self->nbInputProcessed(--> PositiveOrZeroInt)

Return number of input processed so far.

=head2 $self->readFromStdin(--> ConsumerOf[M4Impl])

Enters interactive mode.

=head2 $self->debugFile(--> Undef|Str)

Return debug file, undef if none.

=head2 $class->defaultWarnMacroSequence(--> Str)

Return default --warn-macro-sequence option value (used by m4pp to handle MooX::Option non support of optional value on the command-line)

=head1 NOTES

file() and line() methods, nor synchronisation output, are currently not supported. This is on the TODO list for this package.

M4 is a MooX::Role::Logger consumer, using explicitely Log::Any's "f" functions in all its logging methods. This mean that the message, in case you would use something like e.g. Log::Any::Adapter::Callback, is always formatted, with no additional parameter.

=head1 SEE ALSO

L<Marpa::R2>, L<Moops>, L<MooX::Role::Logger>, L<Log::Any>, L<Log::Any::Adapter::Callback>, L<POSIX>, L<M4 POSIX|http://pubs.opengroup.org/onlinepubs/9699919799/utilities/m4.html>, L<M4 GNU|https://www.gnu.org/software/m4/manual/m4.html>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
