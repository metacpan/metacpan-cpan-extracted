#!/usr/bin/perl -w

# Copyright (c) 2002, Sam Vilain.  All rights reserved. This program
# is free software; you may use it under the same terms as Perl
# itself.

package Lingua::Translate::SysTran;

use strict;
use Carp;

# package globals:
# %config is default values to use for new objects
# %servers is a hash from a translation pair to a hostname/port number
# %one_letter_codes is actually a constant, it is for default port
# number calculation
use vars qw($VERSION %config %servers %one_letter_codes);

# WARNING: Some constants have their default values extracted from the
# POD.  See the Pod::Constants man page.

=head1 NAME

Lingua::Translate::SysTrans - Translation back-end for SysTran's
                              enterprise translation server, version
                              0.01 (European languages only)

=head1 SYNOPSIS

 use Lingua::Translate;

 Lingua::Translate::config
     (
       back_end => "SysTran",
       host => "babelfish.mydomainname.com",
     );

 my $xl8r = Lingua::Translate->new(src => "de", dest => "en");

 # prints "My hovercraft is full of eels"
 print $xl8r->translate("Mein Luftkissenfahrzeug ist voll von den Aalen");

=head1 DESCRIPTION

Lingua::Translate::SysTran is a translation back-end for
Lingua::Translate that contacts a SysTran translation server to do the
real work.

You should try to avoid putting the config() command that sets the
location of the server in all of your scripts; make a little
configuration module or put it in a script you can `require'.

=head1 CONSTRUCTOR

=head2 new(src => $lang, dest => lang, option => $value)

Creates a new translation handle.  This won't initiate a connection
until you try to translate something.

=over

=item src

Source language, in RFC-3066 form.  See L<I18N::LangTags> for a
discussion of RFC-3066 language tags.

=item dest

Destination Language

=item host

Specify the host to contact

=item port

Specify the port number

=back

=cut

use I18N::LangTags qw(is_language_tag);

sub new {
    my ($class, %options) = (@_);

    my $self = bless { %config }, $class;

    croak "Must supply source and destination language"
	unless (defined $options{src} and defined $options{dest});

    is_language_tag($self->{src} = delete $options{src})
	or croak "$self->{src} is not a valid RFC3066 language tag";

    is_language_tag($self->{dest} = delete $options{dest})
	or croak "$self->{dest} is not a valid RFC3066 language tag";

    $self->config(%options);

    $self->{pair} = $self->{src} . "_" . $self->{dest};

    my $custom_port = $servers{$self->{pair}};

    if ( defined $custom_port ) {
	($self->{host}, $self->{port})
	    = ($custom_port =~ m/^(.*)(?: (:\d+) )$/);
    }

    $self->{port} ||= _default_port($self->{pair});

    return $self;
}

=head1 METHODS

The following methods may be called on Lingua::Translate::SysTran
objects.

=head2 translate($text) : $translated

Translates the given text.  die's on any kind of error.

=cut

use IO::Socket;
BEGIN {
    # use Unicode::MapUTF8 if it is available
    eval "use Unicode::MapUTF8 qw(from_utf8 to_utf8);";
    if ( $@ ) {
	eval 'no strict; sub from_utf8 { %a=(@_); $a{"-string"} } '.
	    '*{to_utf8} = \&from_utf8';
    }
};

sub translate {
    my $self = shift;
    UNIVERSAL::isa($self, __PACKAGE__)
	    or croak __PACKAGE__."::translate() called as function";

    # every back-end we know of speaks ISO-8859-1
    my $text = from_utf8( -string => (shift),
			  -charset => "iso-8859-1" );

    my $translated;

    my $request = (
		"METHOD=SOCKET\n".
		"ACTION=TRANSLATE\n".
		"SOURCE-CONTENT=".length($text)."\n".
		"$text\n"
	       );

    my $socket = IO::Socket::INET->new
	(
	 Proto    => 'tcp',
	 PeerAddr => $self->{host},
	 PeerPort => $self->{port},
	 Reuse    => 1,
	);

    $self->_barf("Connection failed; $!") unless $socket;

    ## Sending request
    $socket->write($request, length($request))
	|| $self->_barf ('write failed; '.$!);

    $socket->flush;

    ## Then waiting for answer
    my ($error, $error_message, $time);
    while ($_ = $socket->getline()) {
	my ($command, $value) = (m/^([\w\-]+)=(.*)$/)
	    or $self->_barf("protocol error");

	if ( $command eq "ERR" ) {
	    $error = $value;
	} elsif ( $command eq "TIME" ) {
	    $time = $value;
	} elsif ( $command eq "EMSG" ) {
	    $error_message = $value;
	} elsif ( $command eq "OUTPUT-CONTENT" ) {
	    # data always follows
	    my $bytes_read = $socket->read($translated, $value);
	    ($bytes_read == $value)
		or $self->_barf("short read");
	    last;
	} else {
	    $self->_barf("protocol mismatch; $command");
	}
    }

    # close connection
    $socket->close;

    $self->_barf($error_message) if $error;

    # trim excess line feeds at end of string
    $translated =~ s/\n*$//;

    return to_utf8( -string => $translated,
		    -charset => "iso-8859-1" );
}

sub _barf {
    my $self = shift;
    my $message = shift;

    die ($message . " talking to $self->{host}:$self->{port} "
	 .$self->{pair} );

}

=head2 available() : @list

Returns a list of available language pairs, in the form of "XX_YY",
where XX is the source language and YY is the destination.  If you
want the english name of a language tag, call
I18N::LangTags::List::name() on it.  See L<I18N::LangTags::List>.

If you call this function without configuring the package, it returns
all of the languages that there are known back-ends for.

=cut

sub available {

    my $self = shift;
    UNIVERSAL::isa($self, __PACKAGE__)
	    or croak __PACKAGE__."::available() called as function";

    my @a = keys %one_letter_codes;

    # English; "the new universal language?"
    # mi spitu fo le bango pe le glico
    return (
	    keys %servers ||
	    grep /en/, ( map { my $a=$_; map{"${_}_$a"} my @a } @a )
	   );

}

=head1 CONFIGURATION FUNCTIONS

=head2 config(option => $value)

This function sets defaults for use when constructing objects.

=cut

sub config {

    my $self;
    if ( UNIVERSAL::isa($_[0], __PACKAGE__) ) {
        $self = shift;
    } else {
	$self = \%config;
    }

    while ( my ($option, $value) = splice @_, 0, 2 ) {

	if ( $option eq "pairs" ) {

	    # configure a pair
	    while ( my ($pair, $server) = each %$value ) {
		$servers{$pair} = $server;
	    }

	} elsif ( $option =~ m/^(host|port)$/) {

	    # configure host/port
	    $self->{$option} = $value;

	} else {

	    croak "Unknown configuration option $option";
	}
    }
}

=over

=item host

Defines the hostname to use if no hostname/port is defined for a
language pair.  The default value is "localhost".  Do not specify a
port number.

=item servers

The value to this configuration option must be a hash reference from a
language pair (in XX_YY form) to a hostname, optionally followed by a
colon and a port number.

If this configuration option is defined, then attempts to translate
undefined languages will fail.  There is no default value for this
option.

=back

=head1 A Note on default port numbers

Returns the host name and port number for the given language pair.

To determine the default port number, take the one-letter code for the
language from the below table, express as a number in base 25 (A=0,
B=1, etc) and then add 10000 decimal.  Eg en => de would be EG, which
is 106 decimal, or port 10106.

=head2 ONE LETTER LANGUAGE CODES

 en => E
 de => G
 it => I
 fr => F
 pt => P
 es => S
 el => K

=cut

sub _default_port {
    my $pair = shift;

    my ($src, $tgt) =
	($pair =~ m/^(..)_(..)/)
	    or croak "$pair is not a valid language pair";

    # FIXME - won't work on EBCDIC systems
    my $A = ord("A");
    my $num = ( (ord($one_letter_codes{$src}) - $A) * 25
		+ord($one_letter_codes{$tgt}) - $A       );

    return $num + 10000;
}

# extract configuration options from the POD
use Pod::Constants
    'NAME' => sub { ($VERSION) = (m/(\d+\.\d+)/); },
    'CONFIGURATION FUNCTIONS' => sub {
	Pod::Constants::add_hook
		('*item' => sub {
		     my ($varname) = m/(\w+)/;
		     #my ($default) = m/The default value is\s+"(.*)"\./s;
		     my ($default) = m/The default value is\s+"(.*)"/s;
		     config($varname => $default) if $default;
		 }
		);
	Pod::Constants::add_hook
		(
		 '*back' => sub {

		     # an ugly hack?
		     $config{agent} .= $VERSION;

		     Pod::Constants::delete_hook('*item');
		     Pod::Constants::delete_hook('*back');
		 }
		);
    },
    'ONE LETTER LANGUAGE CODES' => \%one_letter_codes;

=head1 BUGS/TODO

No support for non-ISO-8859-1 character sets - with the software I
have, there is no option.

=head1 SEE ALSO

L<Lingua::Translate>, L<LWP::UserAgent>, L<Unicode::MapUTF8>

=head1 AUTHOR

Sam Vilain, <enki@snowcra.sh>

=cut

1;
