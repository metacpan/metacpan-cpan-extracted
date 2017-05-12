package Email::Stuff;

=head1 NAME

Email::Stuff - A more casual approach to creating and sending Email:: emails

=head1 ACHTUNG!

B<Email::Stuff is deprecated in favor of L<Email::Stuffer>.>

Email::Stuffer should be a drop-in replacement for almost all users.  It uses
L<Email::Sender> in place of L<Email::Send>.  This won't usually cause a
noticeable change, but will be a lot easier to test.

You will need to be careful if:

=over

=item *

you use the C<using> or C<mailer> methods, which are replaced by C<transport>
in Stuffer

=item *

you inspect the false Return::Value object provided by Stuff in case of failure

=item *

you pass extra arguments to the C<send> method

=back

=head1 SYNOPSIS

  # Prepare the message
  my $body = <<'AMBUSH_READY';
  Dear Santa
  
  I have killed Bun Bun.
  Yes, I know what you are thinking... but it was actually a total accident.  I
  was in a crowded line at a BayWatch signing, and I tripped, and stood on his
  head.
  I know. Oops! :/

  So anyways, I am willing to sell you the body for $1 million dollars.  Be
  near the pinhole to the Dimension of Pain at midnight.

  Alias

  AMBUSH_READY

  # Create and send the email in one shot, and send via sendmail
  Email::Stuff->from     ('cpan@ali.as'                      )
              ->to       ('santa@northpole.org'              )
              ->bcc      ('bunbun@sluggy.com'                )
              ->text_body($body                              )
              ->attach   (io('dead_bunbun_faked.gif')->all,
                          filename => 'dead_bunbun_proof.gif')
              ->send;

   # Construct email before sending and send with SMTP.

   my $mail = Email::Stuff->from('cpan@ali.as');
   $mail->to('santa@northpole.org')
   # and so on ...
   my $mailer = Email::Send->new({mailer => 'SMTP'});
   $mailer->mailer_args([Host => 'smtp.example.com:465', ssl => 1]);
   $mail->send($mailer);

=head1 DESCRIPTION

B<The basics should all work, but this module is still subject to
name and/or API changes>

Email::Stuff, as its name suggests, is a fairly casual module used
to email "stuff" to people using the most common methods. It is a 
high-level module designed for ease of use when doing a very specific
common task, but implemented on top of the tight and correct Email::
modules.

Email::Stuff is typically used to build emails and send them in a single
statement, as seen in the synopsis. And it is certain only for use when
creating and sending emails. As such, it contains no email parsing
capability, and little to no modification support.

To re-iterate, this is very much a module for those "slap it together and
fire it off" situations, but that still has enough grunt behind the scenes
to do things properly.

=head2 Default Mailer

Email::Stuff uses L<Email::Send> to send messages.  Although it cannot be
relied upon to work, the default behaviour is to use sendmail to send mail, if
you don't provide the mail send channel with either the C<using> method, or as
an argument to C<send>.

The use of sendmail as the default mailer is consistent with the behaviour
of the L<Email::Send> module itself.

=head2 Why use this?

Why not just use L<Email::Simple> or L<Email::MIME>? After all, this just adds
another layer of stuff around those. Wouldn't using them directly be better?

Certainly, if you know EXACTLY what you are doing. The docs are clear enough,
but you really do need to have an understanding of the structure of MIME
emails. This structure is going to be different depending on whether you have
text body, HTML, both, with or without an attachment etc.

Then there's brevity... compare the following roughly equivalent code.

First, the Email::Stuff way.

  Email::Stuff->to('Simon Cozens<simon@somewhere.jp>')
              ->from('Santa@northpole.org')
              ->text_body("You've been a good boy this year. No coal for you.")
              ->attach_file('choochoo.gif')
              ->send;

And now doing it directly with a knowledge of what your attachment is, and
what the correct MIME structure is.

  use Email::MIME;
  use Email::Send;
  use IO::All;
  
  send SMTP => Email::MIME->create(
    header => [
        To => 'simon@somewhere.jp',
        From => 'santa@northpole.org',
    ],
    parts => [
        Email::MIME->create(
          body => "You've been a good boy this year. No coal for you."
        ),
        Email::MIME->create(
          body => io('choochoo.gif'),
          attributes => {
              filename => 'choochoo.gif',
              content_type => 'image/gif',
          },
       ),
    ],
  );

Again, if you know MIME well, and have the patience to manually code up
the L<Email::MIME> structure, go do that.

Email::Stuff, as the name suggests, solves one case and one case only.

Generate some stuff, and email it to somewhere. As conveniently as
possible. DWIM, but do it as thinly as possible and use the solid
Email:: modules underneath.

=head1 COOKBOOK

Here is another example (maybe plural later) of how you can use
Email::Stuff's brevity to your advantage.

=head2 Custom Alerts

  package SMS::Alert;
  use base 'Email::Stuff';
  
  sub new {
          shift()->SUPER::new(@_)
                 ->from('monitor@my.website')
                 # Of course, we could have pulled these from
                 # $MyConfig->{support_tech} or something similar.
                 ->to('0416181595@sms.gateway')
                 ->using('SMTP', Host => '123.123.123.123');
  }

  package My::Code;
  
  unless ( $Server->restart ) {
          # Notify the admin on call that a server went down and failed
          # to restart.
          SMS::Alert->subject("Server $Server failed to restart cleanly")
                    ->send;
  }

=head1 METHODS

As you can see from the synopsis, all methods that B<modify> the
Email::Stuff object returns the object, and thus most normal calls are
chainable.

However, please note that C<send>, and the group of methods that do not
change the Email::Stuff object B<do not> return the  object, and thus
B<are not> chainable.

=cut

use 5.005;
use strict;
use Carp                   ();
use File::Basename         ();
use Params::Util           '_INSTANCE';
use Email::MIME            ();
use Email::MIME::Creator   ();
use Email::Send            ();
use prefork 'File::Type';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '2.105';
}

#####################################################################
# Constructor and Accessors

=head2 new

Creates a new, empty, Email::Stuff object.

=cut

sub new {
	my $class = ref $_[0] || $_[0];

	my $self = bless {
		send_using => [ 'Sendmail' ],
		# mailer   => undef,
		parts      => [],
		email      => Email::MIME->create(
			header => [],
			parts  => [],
			),
		}, $class;

	$self;
}

sub _self {
	my $either = shift;
	ref($either) ? $either : $either->new;
}

=head2 header_names

Returns, as a list, all of the headers currently set for the Email
For backwards compatibility, this method can also be called as B[headers].

=cut

sub header_names {
	shift()->{email}->header_names;
}

sub headers {
	shift()->{email}->header_names; ## This is now header_names, headers is depreciated
}

=head2 parts

Returns, as a list, the L<Email::MIME> parts for the Email

=cut

sub parts {
	grep { defined $_ } @{shift()->{parts}};
}





#####################################################################
# Header Methods

=head2 header $header => $value

Adds a single named header to the email. Note I said B<add> not set,
so you can just keep shoving the headers on. But of course, if you
want to use to overwrite a header, you're stuffed. Because B<this module
is not for changing emails, just throwing stuff together and sending it.>

=cut

sub header {
	my $self = shift()->_self;
	$self->{email}->header_str_set(ucfirst shift, shift) ? $self : undef;
}

=head2 to $address

Adds a To: header to the email

=cut

sub to {
	my $self = shift()->_self;
	$self->{email}->header_str_set(To => shift) ? $self : undef;
}

=head2 from $address

Adds (yes ADDS, you only do it once) a From: header to the email

=cut

sub from {
	my $self = shift()->_self;
	$self->{email}->header_str_set(From => shift) ? $self : undef;
}

=head2 cc $address

Adds a Cc: header to the email

=cut

sub cc {
	my $self = shift()->_self;
	$self->{email}->header_str_set(Cc => shift) ? $self : undef;
}

=head2 bcc $address

Adds a Bcc: header to the email

=cut

sub bcc {
	my $self = shift()->_self;
	$self->{email}->header_str_set(Bcc => shift) ? $self : undef;
}

=head2 subject $text

Adds a subject to the email

=cut

sub subject {
	my $self = shift()->_self;
	$self->{email}->header_str_set(Subject => shift) ? $self : undef;
}

#####################################################################
# Body and Attachments

=head2 text_body $body [, $header => $value, ... ]

Sets the text body of the email. Unless specified, all the appropriate
headers are set for you. You may override any as needed. See
L<Email::MIME> for the actual headers to use.

If C<$body> is undefined, this method will do nothing.

=cut

sub text_body {
	my $self = shift()->_self;
	my $body = defined $_[0] ? shift : return $self;
	my %attr = (
		# Defaults
		content_type => 'text/plain',
		charset      => 'utf-8',
		encoding     => 'quoted-printable',
		format       => 'flowed',
		# Params overwrite them
		@_,
		);

	# Create the part in the text slot
	$self->{parts}->[0] = Email::MIME->create(
		attributes => \%attr,
		body_str   => $body,
		);

	$self;
}

=head2 html_body $body [, $header => $value, ... ]

Set the HTML body of the email. Unless specified, all the appropriate
headers are set for you. You may override any as needed. See
L<Email::MIME> for the actual headers to use.

If C<$body> is undefined, this method will do nothing.

=cut

sub html_body {
	my $self = shift()->_self;
	my $body = defined $_[0] ? shift : return $self;
	my %attr = (
		# Defaults
		content_type => 'text/html',
		charset      => 'utf-8',
		encoding     => 'quoted-printable',
		# Params overwrite them
		@_,
		);

	# Create the part in the HTML slot
	$self->{parts}->[1] = Email::MIME->create(
		attributes => \%attr,
		body_str   => $body,
		);

	$self;
}

=head2 attach $contents [, $header => $value, ... ]

Adds an attachment to the email. The first argument is the file contents
followed by (as for text_body and html_body) the list of headers to use.
Email::Stuff should TRY to guess the headers right, but you may wish
to provide them anyway to be sure. Encoding is Base64 by default.

=cut

sub attach {
	my $self = shift()->_self;
	my $body = defined $_[0] ? shift : return undef;
	my %attr = (
		# Cheap defaults
		encoding => 'base64',
		# Params overwrite them
		@_,
		);

	# The more expensive defaults if needed
	unless ( $attr{content_type} ) {
		require File::Type;
		$attr{content_type} = File::Type->checktype_contents($body);
	}

	### MORE?

	# Determine the slot to put it at
	my $slot = scalar @{$self->{parts}};
	$slot = 3 if $slot < 3;

	# Create the part in the attachment slot
	$self->{parts}->[$slot] = Email::MIME->create(
		attributes => \%attr,
		body       => $body,
		);

	$self;
}

=head2 attach_file $file [, $header => $value, ... ]

Attachs a file that already exists on the filesystem to the email. 
C<attach_file> will auto-detect the MIME type, and use the file's
current name when attaching.

=cut

sub attach_file {
	my $self = shift;
  my $body_arg = shift;
	my $name = undef;
	my $body = undef;

	# Support IO::All::File arguments
	if ( Params::Util::_INSTANCE($body_arg, 'IO::All::File') ) {
		$name = $body_arg->name;
		$body = $body_arg->all;

	# Support file names
	} elsif ( defined $body_arg and -f $body_arg ) {
		$name = $body_arg;
		$body = _slurp( $body_arg ) or return undef;

	# That's it
	} else {
		return undef;
	}

	# Clean the file name
	$name = File::Basename::basename($name) or return undef;

	# Now attach as normal
	$self->attach( $body, name => $name, filename => $name, @_ );
}

# Provide a simple _slurp implementation
sub _slurp {
	my $file = shift;
	local $/ = undef;
	local *SLURP;
	open( SLURP, "<$file" ) or return undef;
	my $source = <SLURP>;
	close( SLURP ) or return undef;
	\$source;
}

=head2 using $drivername, @options

The C<using> method specifies the L<Email::Send> driver that you want to use to
send the email, and any options that need to be passed to the driver at the
time that we send the mail.

Alternatively, you can pass a complete mailer object (which must be an
L<Email::Send> object) and it will be used as is.

=cut

sub using {
	my $self = shift;

	if ( @_ ) {
		# Change the mailer
		if ( _INSTANCE($_[0], 'Email::Send') ) {
			$self->{mailer} = shift;
			delete $self->{send_using};
		} else {
			$self->{send_using} = [ @_ ];
			delete $self->{mailer};
			$self->mailer;
		}
	}

	$self;
}





#####################################################################
# Output Methods

=head2 email

Creates and returns the full L<Email::MIME> object for the email.

=cut

sub email {
	my $self  = shift;
	my @parts = $self->parts;

        ### Lyle Hopkins, code added to Fix single part, and multipart/alternative problems
        if ( scalar( @{ $self->{parts} } ) >= 3 ) {
                ## multipart/mixed
                $self->{email}->parts_set( \@parts );
        }
        ## Check we actually have any parts
        elsif ( scalar( @{ $self->{parts} } ) ) {
                if ( _INSTANCE($parts[0], 'Email::MIME') && _INSTANCE($parts[1], 'Email::MIME') ) {
                        ## multipart/alternate
                        $self->{email}->header_set( 'Content-Type' => 'multipart/alternative' );
                        $self->{email}->parts_set( \@parts );
                }
                ## As @parts is $self->parts without the blanks, we only need check $parts[0]
                elsif ( _INSTANCE($parts[0], 'Email::MIME') ) {
                        ## single part text/plain
                        _transfer_headers( $self->{email}, $parts[0] );
                        $self->{email} = $parts[0];
                }
        }

	$self->{email};
}

# Support coercion to an Email::MIME
sub __as_Email_MIME { shift()->email }

# Quick any routine
sub _any (&@) {
        my $f = shift;
        return if ! @_;
        for (@_) {
                return 1 if $f->();
        }
        return 0;
}

# header transfer from one object to another
sub _transfer_headers {
        # $_[0] = from, $_[1] = to
        my @headers_move = $_[0]->header_names;
        my @headers_skip = $_[1]->header_names;
        foreach my $header_name (@headers_move) {
                next if _any { $_ eq $header_name } @headers_skip;
                my @values = $_[0]->header($header_name);
                $_[1]->header_str_set( $header_name, @values );
        }
}

=head2 as_string

Returns the string form of the email. Identical to (and uses behind the
scenes) Email::MIME-E<gt>as_string.

=cut

sub as_string {
	shift()->email->as_string;
}

=head2 send

Sends the email via L<Email::Send>.  Optionally pass in a Mail:Send object to
override the default mailer.

=cut

sub send {
	my $self = shift;
	$self->using(@_) if @_; # Arguments are passed to ->using
	my $email = $self->email or return undef;
	$self->mailer->send( $email );
}

sub _driver {
	my $self = shift;
	$self->{send_using}->[0];
}

sub _options {
	my $self = shift;
	my $options = $#{$self->{send_using}};
	@{$self->{send_using}}[1 .. $options];
}

=head2 mailer

If you need to interact with it directly, the C<mailer> method
returns the L<Email::Send> mailer object that will be used to
send the email.

Returns an L<Email::Send> object, or dies if the driver is not
available.

=cut

sub mailer { 
	my $self = shift;
	return $self->{mailer} if $self->{mailer};

	my $driver = $self->_driver;
	$self->{mailer} = Email::Send->new( {
		mailer      => $driver,
		mailer_args => [ $self->_options ],
		} );
	unless ( $self->{mailer}->mailer_available($driver, $self->_options) ) {
		Carp::croak("Driver $driver is not available");
	}

	$self->{mailer};
}





#####################################################################
# Legacy compatibility

sub To      { shift->to(@_)      }
sub From    { shift->from(@_)    }
sub CC      { shift->cc(@_)      }
sub BCC     { shift->bcc(@_)     }
sub Subject { shift->subject(@_) }
sub Email   { shift->email(@_)   }

1;

=head1 TO DO

=over 4

=item * Fix a number of bugs still likely to exist

=item * Write more tests.

=item * Add any additional small bit of automation that arn't too expensive

=back

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<https://github.com/rjbs/Email-Stuff/issues>

=head1 AUTHORS

B<Current maintainer>: Ricardo Signes C<rjbs@cpan.org>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Email::MIME>, L<Email::Send>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2004 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
