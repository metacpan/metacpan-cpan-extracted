package Erlang::Interface;

use 5.008008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;
our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Erlang::Interface ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    erl_msg_free
    ERL_ATOM
    ERL_BIG
    ERL_BINARY
    ERL_COMPOUND
    ERL_CONS
    ERL_EMPTY_LIST
    ERL_FLOAT
    ERL_FUNCTION
    ERL_INTEGER
    ERL_LIST
    ERL_LONGLONG
    ERL_NIL
    ERL_PID
    ERL_PORT
    ERL_REF
    ERL_SMALL_BIG
    ERL_TUPLE
    ERL_UNDEF
    ERL_U_INTEGER
    ERL_U_LONGLONG
    ERL_U_SMALL_BIG
    ERL_VARIABLE
    MAXREGLEN

	erl_set_compat_rel
	erl_connect_init
	erl_connect_xinit
	erl_connect
	erl_xconnect
	erl_close_connection
	erl_receive
	erl_receive_msg
	erl_xreceive_msg
	erl_send
	erl_reg_send
	erl_rpc
	erl_rpc_to
	erl_rpc_from

	erl_publish
	erl_accept

	erl_thiscookie
	erl_thisnodename
	erl_thishostname
	erl_thisalivename
	erl_thiscreation

	erl_init

	erl_length
	erl_mk_atom
	erl_mk_binary
	erl_mk_empty_list
	erl_mk_estring
	erl_mk_float
	erl_mk_int
	erl_mk_longlong
	erl_mk_list
	erl_mk_pid
	erl_mk_port
	erl_mk_ref
	erl_mk_long_ref
	erl_mk_string
	erl_mk_tuple
	erl_mk_uint
	erl_mk_ulonglong
	erl_mk_var

	erl_print_term
	erl_sprint_term
	erl_size
	erl_tl
	erl_var_content

	erl_format
	erl_match

	erl_global_names
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.03';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Erlang::Interface::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
    no strict 'refs';
    # Fixed between 5.005_53 and 5.005_61
#XXX    if ($] >= 5.00561) {
#XXX        *$AUTOLOAD = sub () { $val };
#XXX    }
#XXX    else {
        *$AUTOLOAD = sub { $val };
#XXX    }
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Erlang::Interface', $VERSION);

INIT{
  erl_init(0, 0);
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Erlang::Interface - Perl interface for erl_interface

=head1 SYNOPSIS

  use Erlang::Interface;

=head1 DESCRIPTION

Erlang Interface is Perl interface for erl_interface

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Tsukasa Hamano, E<lt>hamano@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tsukasa Hamano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
