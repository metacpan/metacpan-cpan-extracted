package Mail::SendGrid::SmtpApiHeader;

use strict;
use warnings;

use JSON;

our $VERSION = '0.02';

sub new {
  my $class = shift;
  return bless { 'data' => { } },  ref $class || $class;
}


sub addTo {
  my $self = shift;
  push @{ $self->{data}{to} }, @_;
}


sub addSubVal {
  my $self = shift;
  my $var = shift;
  push @{ $self->{data}{sub}{$var} }, @_;
}


sub setUniqueArgs {
  my $self = shift;
  my $val = shift;
  $self->{data}{unique_args} = $val if ref $val eq 'HASH';
}


sub setCategory {
  my $self = shift;
  my $cat = shift;
  $self->{data}{category} = $cat;
}


sub addFilterSetting {
  my $self = shift;
  my $filter = shift;

  my ($settings) = ( $self->{data}{filters}{$filter}{settings} ||= {} );

  while (@_) {
    my $setting = shift;
    my $value = shift;
    $settings->{$setting} = $value;
  }
}


sub addUniqueArgs {
  my $self = shift;

  my ($unique_args) = ( $self->{data}{unique_args} ||= {} );

  while (@_) {
    my $name = shift;
    my $value = shift;
    $unique_args->{$name} = $value;
  }
}


my $JSON;
sub asJSON {
  my $self = shift;
  $JSON ||= _build_json();
  return $JSON->encode($self->{data});
}


my $JSON_PRETTY;
sub asJSONPretty {
  my $self = shift;
  $JSON_PRETTY ||=  _build_json()->pretty(1);
  return $JSON_PRETTY->encode($self->{data});
}


sub as_string {
  my $self = shift;
  my $json = $self->asJSON;
  $json =~ s/(.{1,72})(\s)/$1\n   /g;
  my $str = "X-SMTPAPI: $json";
  return $str;
}


sub _build_json {
    my $json = JSON->new;
    $json->space_before(1);
    $json->space_after(1);
    $json->ascii(1);
    return $json;
}

1;


=head1 NAME

Mail::SendGrid::SmtpApiHeader - generate SendGrid's SMTP extension header

=head1 SYNOPSIS

	use Mail::SendGrid::SmtpApiHeader;

	# Use AnyEvent as usual
	my $cond = AnyEvent->condvar;
	http_get "http://search.cpan.org/", sub { $cond->send(); };
	$cond->recv();

=head1 DESCRIPTION

This module generates the custom SMTP extension header used to configure SendGrid's SMTP
platform.

=head1 METHODS

=head2 new

Used to create a new instance. The constructor takes no arguments.

    my $headers = Mail::SendGrid::SmtpApiHeader->new();

=head2 addTo

Adds the given email address to the list of recipients (i.e. I<To>).

    $headers->addTo(
        'me@example.com',
        'you@example.com',
    );

=head2 addSubVal

Specify substitution variables for multi recipient e-mails. This would allow you to, for
example, substitute the string with a recipient's name. 'val' can be either a scalar or an
array. It is the user's responsibility to ensure that there are an equal number of
substitution values as there are recipients.

    $headers->addSubVal(names => "Me", "You");

=head2 setUniqueArgs

Specify any unique argument values.

    $headers->setUniqueArgs(
        {
            test => 1,
            foo  => 2,
        }
    );

=head2 setCategory

Sets a category for an e-mail to be logged as. You may use any category name you like.

    $header->setCategory('send-001');

=head2 addFilterSetting

Adds/changes a setting for a filter. Settings specified in the header will override
configured settings.

    # Enable a text footer and set it
    $header->addFilterSetting(footer =>
        'enable', 1,
        'text/plain', "Thank you for your business",
    );

=head2 addUniqueArgs

Add unique argument values to the existing unique arguments.

    $headers->addUniqueArgs(
        test => 1,
        foo  => 2,
    );

=head2 as_string

Returns the full header which can be inserted into an e-mail.

=head2 asJSON

Returns the JSON version of the requested data.

=head2 asJSONPretty

Returns the JSON version of the requested data in a more human readable way.

=head1 AUTHOR

SendGrid

Booking.com

Emmanuel Rodriguez <potyl@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2010 by SendGrid

Copyright (C) 2011 by Booking.com

Copyright (C) 2012 by Emmanuel Rodriguez

=cut
