package Mail::TLSRPT;
# ABSTRACT: TLSRPT object
our $VERSION = '1.20200305.1'; # VERSION
use 5.20.0;
use Moo;
use Carp;
use Types::Standard qw{Str HashRef ArrayRef};
use Type::Utils qw{class_type};
use Mail::TLSRPT::Pragmas;

1;

