package Exception::FFI::ErrorCode 0.02 {

  use warnings;
  use 5.020;
  use constant 1.32 ();
  use experimental qw( signatures postderef );
  use Ref::Util qw( is_plain_arrayref );

  # ABSTRACT: Exception class based on integer error codes common in C code


  my %human_codes;

  sub import ($, %args)
  {
    my $class       = delete $args{class}       || caller;
    my $const_class = delete $args{const_class} || $class;
    my $codes       = delete $args{codes}       || {};

    if(%args) {
      require Carp;
      Carp::croak("Unknown options: @{[ sort keys %args ]}");
    }

    {
      no strict 'refs';
      push @{ "$class\::ISA" }, 'Exception::FFI::ErrorCode::Base';
    }


    foreach my $name (keys $codes->%*)
    {
      my($code, $human) = do {
        my $v = $codes->{$name};
        is_plain_arrayref $v ? @$v : ($v,$name);
      };
      constant->import("$const_class\::$name", $code);
      $human_codes{$class}->{$code} = $human;
    }
  }

  sub detect ($class)
  {
    my $sub;
    if(Carp::Always->can('import'))
    {
      require Sub::Identify;
      $Carp::CarpInternal{"Exception::FFI::ErrorCode::Base"}++;
      $sub = sub {
        [Sub::Identify::get_code_info($SIG{__WARN__})]->[0] eq 'Carp::Always'
      };
    }
    else
    {
      $sub = sub { 0 };
    }
    no warnings 'redefine';
    *Exception::FFI::ErrorCode::Base::_carp_always = $sub;
  }

  __PACKAGE__->detect;

  package Exception::FFI::ErrorCode::Base 0.02 {

    sub _carp_always;

    use Class::Tiny qw( package filename line code trace _longmess );
    use Ref::Util qw( is_blessed_ref );
    use overload
        '""' => sub ($self,@) {
          if(_carp_always)
          {
            return $self->_longmess;
          }
          else
          {
            return $self->as_string . "\n";
          }
        },
        bool => sub { 1 }, fallback => 1;

    sub throw ($proto, @rest)
    {
      my($package, $filename, $line) = caller;

      my $self;
      if(is_blessed_ref $proto)
      {
        $self = $proto;
        $self->package($package);
        $self->filename($filename);
        $self->line($line);
      }
      else
      {
        $self = $proto->new(
          @rest,
          package  => $package,
          filename => $filename,
          line     => $line,
        );
      }
      my $trace = $self->get_stack_trace;
      $self->trace($trace) if $trace;
      $self->_longmess(Carp::longmess($self->strerror)) if _carp_always;
      die $self;
    }

    sub get_stack_trace ($)
    {
      if($ENV{EXCEPTION_FFI_ERROR_CODE_STACK_TRACE})
      {
        require Devel::StackTrace;
        return Devel::StackTrace->new(
          ignore_package => 'Exception::FFI::ErrorCode::Base',
        );
      }
      else
      {
        return undef;
      }
    }

    sub strerror ($self)
    {
      my $code = $self->code;
      $code = 0 unless defined $code;
      my $str = $human_codes{ref $self}->{$code};
      $str = sprintf "%s error code %s", ref $self, $self->code unless defined $str;
      return $str;
    }

    sub as_string ($self)
    {
      sprintf "%s at %s line %s.", $self->strerror, $self->filename, $self->line;
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Exception::FFI::ErrorCode - Exception class based on integer error codes common in C code

=head1 VERSION

version 0.02

=head1 SYNOPSIS

Throwing:

 # realish world example for use with libcurl
 package Curl::Error {
   use Exception::FFI::ErrorCode
     code => {
       CURLE_OK                   => 0,
       CURLE_UNKNOWN_OPTION       => 48
       ...
     };
   $ffi->attach( [ curl_easy_strerror => strerror ] => ['enum'] => 'string' => sub {
     my($xsub, $self) = @_;
     $xsub->($self->code);
   });
 }
 
 # foo is an unknown option, so this will return 48
 my $code = $curl->setopt( "foo" => "bar" );
 # throw as an exception
 Curl::Error->throw( code => $code ) if $code != Curl::Error::CURLE_OK;

Defining error class without a strerror

 package Curl::<Error {
   use Exception::FFI::ErrorCode
     code => {
       CURLE_OK                   => [ 0,  'no error'                        ],
       CURLE_UNKNOWN_OPTION       => [ 48, 'unknown option passed to setopt' ],
       ...
     };
 }
 ...

Catching:

 try {
   might_die;
 }
 catch ($ex) {
   if($ex isa Curl::Error) {
     my $package  = $ex->package;   # the package where thrown
     my $filename = $ex->filename;  # the filename where thrown
     my $line     = $ex->line;      # the linenumber where thrown
     my $code     = $ex->code;      # the error code
     my $human    = $ex->strerror;  # human readable error
     my $diag     = $ex->as_string; # human readable error at filename.pl line xxx
     my $diag     = "$ex";          # same as $ex->as_string
 
     if($ex->code == Curl::Error::UNKNOWN_OPTION) {
       # handle the unknown option variant of this error
     }
   }
 }

=head1 DESCRIPTION

A common pattern in C libraries is to return an integer error code to classify an error.
When translating those APIs to Perl you often want to instead throw an exception.  This
class provides an interface for building exception classes that help with that pattern.

For APIs that provide a C<strerror> or similar function that converts the error code into
a human readable diagnostic, you can simply attach it.  If not you can provide human
readable diagnostics for each error code using an array reference, as shown above.

The base class for your exception class will be set to
L<Exception::FFI::ErrorCode::Base|/Exception::FFI::ErrorCode::Base>.  The base class
handles determining the location of where the exception was thrown and will stringify
in a way to look like a regular Perl string exception with the filename and line number
you would expect.

A stack trace can be generated, either on a per-subclass basis, or globally via an
environment variable.  This is not done by default due to the overhead involved.
See the L<trace method|/trace> for details.

This class will attempt to detect if L<Carp::Always> is running and produce a long message
when stringified, as it already does for regular string exceptions.  By default it will
B<only> do this if L<Carp::Always> is running when this module is loaded.  Since
typically L<Carp::Always> is loaded via the command line C<-MCarp::Always> or via
C<PERL5OPT> environment variable this should cover all of the typical use cases, but if
for some reason L<Carp::Always> does get loaded after this module, you can force
redetection by calling the L<detect method|/detect>.

=head1 METHODS

=head2 detect

 Exception::FFI::ErrorCode->detect;

This will redetect if L<Carp::Always> has been loaded yet.  You do not need to call this
method if L<Carp::Always> has been enabled or disabled (we check for that when the
exception is thrown and stringified), just if the module has been loaded.

=head2 import

 use Exception::FFI::ErrorCode
   %options;

The C<import> method will set the base class, and set up any specific error codes.
Options include:

=over 4

=item class

The exception class.  If not provided this will be determined using C<caller>.

=item codes

The error codes.  This is a hash reference.  The keys are the constant names, in C and
Perl these are usually all upper case like C<FOO_BAD_FILENAME>.  The values can be either
an integer constant, or an array reference with the integer constant and human readable
diagnostic.  The former is intended for when there is a C<strerror> type function that
will convert the error code into a diagnostic for you.

=item const_class

Where to put the constants.  If not provided, these will be be the same as C<class>.

=back

=head1 Exception::FFI::ErrorCode::Base

The base class uses L<Class::Tiny>, so feel free to add additional attributes.
The base class provides these attributes and methods:

=head2 throw

 Exception::FFI::ErrorCode::Base->throw( code => $code );

Throws the exception with the given code.  Obviously you would throw the subclass, not the
base class.

=head2 strerror

 my $string = $ex->strerror;

Returns a human readable message for the exception.  If available this should be overridden
by attaching the appropriate C function.

=head2 as_string

 my $string = $ex->as_string;
 my $string = "$ex";

Returns a human readable diagnostic.  This is in the form of a familiar Perl warning or
string exception, including the filename and line number where the exception was thrown.
If you stringify the exception it will use this method, adding a new line.

=head2 package

 my $package = $ex->package;

The package where the exception happened.

=head2 filename

 my $filename = $ex->filename;

The filename where the exception happened.

=head2 line

 my $line = $ex->line;

The line number where the exception happened.

=head2 code

 my $code = $ex->code;

The integer error code.

=head2 trace

 my $trace = $ex->trace;

This will return a L<Devel::StackTrace> trace, if it was recorded when the exception was
thrown.  Generally the trace will only be generated if C<EXCEPTION_FFI_ERROR_CODE_STACK_TRACE>
set to a true value.  Individual subclasses may also choose to always generate a stack
trace.

=head2 get_stack_trace

 my $trace = $ex->get_stack_trace;

This is the method that is called internally to generate a stack trace.  By default this
is only done if C<EXCEPTION_FFI_ERROR_CODE_STACK_TRACE> is set to true.  If you want
a stack trace to B<always> be generated, you can override this method in your subclass.

=head1 CAVEATS

The L<Carp::Always> detection is pretty solid, but if L<Carp::Always> is off when the
exception is thrown but on when it is stringified then strange things might happen.

=head1 ENVIRONMENT

=over 4

=item C<EXCEPTION_FFI_ERROR_CODE_STACK_TRACE>

If this environment variable is set to a true value, then a stack trace will be generated
and attached to all exceptions managed by L<Exception::FFI::ErrorCode>.

=back

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

=item L<Exception::Class>

=item L<Class:Tiny>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
