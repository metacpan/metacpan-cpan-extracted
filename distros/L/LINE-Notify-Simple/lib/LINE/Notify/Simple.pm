package LINE::Notify::Simple;

use strict;
use warnings;
use utf8;
use feature qw(say);
use parent qw(Class::Accessor);
use JSON;
use Encode;
use Encode::Guess qw(euc-jp shiftjis 7bit-jis);
use LWP::UserAgent;
use HTTP::Request::Common;
use LINE::Notify::Simple::Response;

__PACKAGE__->mk_accessors(qw(access_token));

our $LINE_NOTIFY_URL    = 'https://notify-api.line.me/api/notify';
our $VERSION            = '1.02';

sub notify {

	my($self, $message) = @_;

	my $data = { message => $message };
	return $self->notify_detail($data);
}

sub notify_detail {

	my($self, $data) = @_;

	my %headers = (
			'Authorization' => sprintf('Bearer %s', $self->access_token)
		);

	# drop utf8 flag
	$self->_drop_utf8_flag_hashref($data);

	if (exists $data->{imageFile}) {
		my $image_file = ref($data->{imageFile}) eq "ARRAY" ? $data->{imageFile}->[0] : $data->{imageFile};
		if (!-e $image_file) {
			die "$image_file is not exists.";
		}
		$data->{imageFile} = [$image_file];
		$headers{'Content-type'} = "form-data";
	} else {
		$headers{'Content-type'} = "application/x-www-form-urlencoded";
	}

	my $ua  = LWP::UserAgent->new;
	my $req = POST $LINE_NOTIFY_URL, %headers, Content => [%{$data}];
	my $res = $ua->request($req);

	my $rate_limit_headers = {};
	my @names = $res->header_field_names;
	foreach my $name (@names) {
		if ($name =~ /^X\-.*/) {
			$rate_limit_headers->{lc($name)} = $res->header($name);
		}
	}

	my $ref = JSON->new->decode($res->content);

	return LINE::Notify::Simple::Response->new({ rate_limit_headers => $rate_limit_headers, status => $ref->{status}, message => $ref->{message}, status_line => $res->status_line });
}

sub _drop_utf8_flag_hashref {

	my($self, $data) = @_;

	foreach my $key (keys %{$data}) {
		my $val = $data->{$key};
		if (ref($val)) {
			next;
		}
		if (utf8::is_utf8($val)) {
			my $enc   = guess_encoding($val);
			my $guess = ref($enc) ? $enc->name : "UTF-8";
			$data->{$key} = encode($guess, $val);
		}
	}
}

1;

__END__

=pod

=head1 NAME

LINE::Notify::Simple

=head1 VERSION

1.02

=head1 SYNOPSIS

  #!/usr/bin/env perl
  
  use strict;
  use warnings;
  use utf8;
  use feature qw(say);
  use LINE::Notify::Simple;
  
  my $access_token = 'your line access token';
  my $message = "\nThis is test message.";
  my $line = LINE::Notify->new({access_token => $access_token});
  
  my $res = $line->notify($message);
  if ($res->is_success) {
      say $res->message;
  } else {
      say $res->status_line . ". ". $res->message;
  }
  
  exit;

=head1 DESCRIPTION

L<LINE Notify API|https://notify-api.line.me/api/notify> simple & easy POST request module.

=head1 METHOD

=head2 notify

POST https://notify-api.line.me/api/notify.
Return LINE::Notify::Simple::Response.

  my $message = "\nThis is test message.";
  my $res = $line->notify($message);
  if ($res->is_success) {
      say $res->message;
  } else {
      say $res->status_line . ". ". $res->message;
  }

=over

=item *

message(required)

=back

=head2 notify_detail

Hashref keys are message, imageThumbnail, imageFullsize, imageFile, stickerPackageId, stickerId and notificationDisabled

  # see https://developers.line.biz/ja/docs/messaging-api/sticker-list/
  my $data = {
      message          => "\nThis is test message.",
      stickerPackageId => 11539,
      stickerId        => 52114110
  };
  my $res = $line->notify_detail($data);
  if ($res->is_success) {
      say $res->message;
  } else {
      say $res->status_line . ". ". $res->message;
  }

Using imageFile

  my $data = {
      message   => "\nThis is test message.",
      imageFile => "/path/to/image.png"
  };
  my $res = $line->notify_detail($data);


=over 4

=item *

message(required)

=item *

stickerPackageId(optional)

=item *

stickerId(optional)

=item *

notificationDisabled(optional).

=item *

imageThumbnail(optional)

=item *

imageFullsize(optional)

=item *

imageFile(optional). file type is must be png or jpg

=back

=head1 AUTHOR

Akira Horimoto E<lt>emperor.kurt _at_ gmail.comE<gt>

=head1 SEE ALSO

L<https://notify-bot.line.me/doc/ja/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

