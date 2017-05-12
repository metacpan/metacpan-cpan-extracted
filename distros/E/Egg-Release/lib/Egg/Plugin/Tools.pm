package Egg::Plugin::Tools;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Tools.pm 340 2008-05-19 11:50:24Z lushe $
#
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '3.03';

{
	require URI::Escape;
	require HTML::Entities;
	no warnings 'redefine';
	sub encode_entities {
		shift; my $args= $_[1] || q{'"&<>@};
		&HTML::Entities::encode_entities($_[0], $args);
	}
	sub encode_entities_numeric {
		shift; &HTML::Entities::encode_entities_numeric(@_);
	}
	sub decode_entities {
		shift; &HTML::Entities::decode_entities(@_);
	}
	sub uri_escape {
		shift; &URI::Escape::uri_escape(@_);
	}
	sub uri_escape_utf8 {
		shift; &URI::Escape::uri_escape_utf8(@_);
	}
	sub uri_unescape {
		shift; &URI::Escape::uri_unescape(@_);
	}
	*escape_html   = \&encode_entities;
	*eHTML         = \&encode_entities;
	*unescape_html = \&decode_entities;
	*ueHTML        = \&decode_entities;
	*escape_uri    = \&uri_escape;
	*eURI          = \&uri_escape;
	*unescape_uri  = \&uri_unescape;
	*ueURI         = \&uri_unescape;
  };

{
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	for my $accessor (qw/sha1 md5/) {
		my $pkg= "Digest::". uc($accessor);
		*{__PACKAGE__."::${accessor}_hex"}= sub {
			$pkg->require;
			shift;
			&{"${pkg}::${accessor}_hex"}(ref($_[0]) ? ${$_[0]}: @_);
		  };
	}
  };

sub create_id {
	my $e= shift;
	my $len= shift || 32;
	my $method= (lc(shift) || 'sha1'). '_hex';
	substr( $e->$method(
	  $e->$method( $$. $e->gettimeofday. rand(1000) ) ), 0, $len );
}
sub comma {
	my $num= $_[1] || return 0;
	my($a, $b, $c)= $num=~/^([\+\-])?(\d+)(\.\d+)?/;
	$b || return 0;
	1 while $b=~s{(.*\d)(\d{3})} [$1,$2];
	($a || ""). $b. ($c || "");
}
sub shuffle_array {
	# Quotation from perlfaq.
	my $surf= shift;
	my $deck= $_[0] ? (ref($_[0]) eq 'ARRAY' ? $_[0]: [@_])
	                : croak q{ I want array. };
	my $i = @$deck;
	while ($i--) {
		my $j = int rand ($i+1);
		@$deck[$i,$j] = @$deck[$j,$i];
	}
	wantarray ? @$deck: $deck;
}
sub filefind {
	require File::Find;
	my $e= shift;
	my $regex= shift || croak q{ I want File Regexp };
	@_ || croak q{ I want Find PATH. };
	my @files;
	my $wanted= sub {
		push @files, $File::Find::name if $File::Find::name=~m{$regex};
	  };
	File::Find::find($wanted, ref($_[0]) eq 'ARRAY' ? @{$_[0]}: @_ );
	@files ? \@files: (undef);
}
sub referer_check {
	my $e= shift;
	if ($_[0]) { $e->req->is_post || return 0 }
	my $refer= $e->req->referer   || return 1;
	my $regex= $e->global->{referer_check_regexp} ||= do {
		$e->config->{allow_referer_regex} || do {
			$e->req->host_name
			  ? "^https?\://@{[ quotemeta($e->req->host_name) ]}"
			  : die '$e->request->host_name is empty.';
		  };
	  };
	$refer=~m{$regex} ? 1: 0;
}
sub gettimeofday {
	require Time::HiRes;
	Time::HiRes::gettimeofday();
}
sub mkpath {
	require File::Path;
	shift; File::Path::mkpath(@_);
}
sub rmtree {
	require File::Path;
	shift; File::Path::rmtree(@_);
}
sub jfold {
	require Jcode;
	my $e   = shift;
	my $str = shift || croak q{ I want string. };
	[ Jcode->new($str)->jfold(@_) ];
}
sub timelocal {
	my $e  = shift;
	my $arg= shift || croak q{ I want argument. };
	require Time::Local;
	my($yer, $mon, $day, $hou, $min, $sec);
	if ($arg=~m{^(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})(.*)}) {
		($arg, $yer, $mon, $day)= ($4, $1, $2, $3);
		if ($arg and $arg=~m{^.+?(\d{1,2})\:(\d{1,2})(.*)}) {
			($arg, $hou, $min)= ($3, $1, $2);
			if ($arg and $arg=~m{^\:(\d{1,2})}) { $sec= $1 }
		}
		$hou ||= 0;  $min ||= 0;  $sec ||= 0;
	} else {
		$arg= [$arg, @_] if defined($_[0]);
		$yer= $arg->[0]; $yer=~m{\D} and croak q{ Bad argument. };
		$mon= $arg->[1] || 0;
		$day= $arg->[2] || croak q{ I want Day. };
		$hou= $arg->[3] || 0; $min= $arg->[4] || 0; $sec= $arg->[5] || 0;
	}
	if (length($yer)== 4) { $yer-= 1900; --$mon }
	Time::Local::timelocal($sec, $min, $hou, $day, $mon, $yer);
}

1;

__END__

=head1 NAME

Egg::Plugin::Tools - Convenient method collection for Egg.

=head1 SYNOPSIS

  use Egg qw/ Tools /;
  
  $e->escape_html($html);
  
  $e->unescape_html($plain);
  
  $e->sha1_hex('abcdefg');
  
  $e->comma('12345.123');
  
  my @array= (1..100);
  $e->shuffle_array(\@array);

=head1 DESCRIPTION

It is a plugin that collects convenient methods.

=head1 METHODS

=head2 encode_entities ([HTML_STR], [ARG])

encode_entities of L<HTML::Entities> is done.

  my $plain = $e->encode_entities($html);

=over 4

=item * Alias = escape_html, eHTML

=back

=head2 encode_entities_numeric ([HTML_STR], [ARG])

encode_entities_numeric of HTML::Entities is done.

=head2 decode_entities ([HTML_STR], [ARG])

decode_entities of L<HTML::Entities> is done.

  my $html = $e->decode_entities($plain);

=over 4

=item * Alias = unescape_html, ueHTML

=back

=head2 uri_escape ([URI_STR])

uri_escape of L<URI::Escape> is done.

  my $escape= $e->uri_escape($uri);

=over 4

=item * Alias = escape_uri, eURI

=back

=head2 uri_escape_utf8 ([URI_STR])

uri_escape_utf8 of L<URI::Escape> is done. 

=head2 uri_unescape ([URI_STR])

uri_unescape of L<URI::Escape> is done.

=over 4

=item * Alias = unescape_uri, ueURI

=back

=head2 sha1_hex ([TEXT])

sha1_hex of L<Digest::SHA1> is done.

  my $hex= $e->sha1_hex($text);

=head2 md5_hex ([TEXT])

md5_hex of L<Digest::MD5> is done.

  my $hex= $e->md5_hex($text);

=head2 create_id ([LENGTH], [METHOD])

A unique HEX value to use it as general ID is returned.

LENGTH is length of the returned HEX value. It disappears when it is too short
in unique.  Default is 32.

METHOD is a method for the generation of the HEX value. Sha1 or md5 can be
specified.  Default is sha1.

  my $id= $e->create_id;

=head2 comma ([NUMBER])

The comma is put in NUMBER in each treble.

  my $price= $e->comma($number);

=head2 shuffle_array ([ARRAY])

The result of mixing ARRAY is returned. 

  my $shuffle= $e->shuffle_array($array);

=head2 filefind ([REGEXP], [PATH_LIST])

The result of L<File::Find> is returned.

The regular expression of the retrieved file is passed to REGEXP.

The retrieved passing is passed to PATH_LIST.

When anything doesn't become a hit to the retrieval, undefined is returned.

  if (my $files= $e->filefind(qr{\.pm$}, '/path/to/find')) {
     ............
     .....
  }

=head2 referer_check ([BOOL])

If environment variable 'HTTP_REFERER' is the one of the site, true is returned.

If REQUEST_METHOD is POST and doesn't exist, it becomes false if BOOL is given.

True is returned when there is no value in HTTP_REFERER.

$e-E<gt>request-E<gt>host_name is used for the site judgment.

  if ($e->referer_check(1)) {
      ..............
      ......
  }

=head2 gettimeofday

Gettimeofday of L<Time::HiRes> is returned.

  my $elabor = $e->gettimeofday;

=head2 mkpath ([PATH_LIST])

mkpath of L<File::Path> is done.

  $e->mkpath(qw{ /path/to/create });

=head2 rmtree ([PATH_LIST])

rmtree of File::Path is done.

  $e->rmtree(qw{ /path/to/create });

=head2 jfold ([STRING])

jfold of L<Jcode> is done.

The return value is ARRAY reference.

  my $cutstr= $e->jfold($string);

=head2 timelocal ([DATE_STRING or TIME_ARRAY])

L<Time::Local> is done.

If it is DATE_STRING, the character string of the form such as '2008/01/01 01:01:01'
 and '2008-01-01 01:01:01' can be passed.

When TIME_ARRAY is passed, ARRAY with the value that starts from the age is passed.
Please note reversing completely with the argument passed to L<Time::Local>.

  my $time_var= $e->timelocal('2008/01/01 01:01:01');
    or
  my $time_var= $e->timelocal(qw/ 2008 01 01 01 01 01 /);

=head1 SEE ALSO

L<Egg::Release>,
L<URI::Escape>,
L<HTML::Entities>,
L<Digest::SHA1>,
L<Digest::MD5>,
L<File::Find>,
L<Time::HiRes>,
L<File::Path>,
L<Jcode>,
L<Time::Local>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

