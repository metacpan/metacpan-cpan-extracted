package HTTP::Cookies::PhantomJS;

use strict;
use HTTP::Cookies;
use HTTP::Response;
use HTTP::Request;
use HTTP::Headers::Util qw/split_header_words join_header_words/;
use HTTP::Date qw/time2str/;

our @ISA = 'HTTP::Cookies';
our $VERSION = '0.02';

use constant MAGIC => 'cookies="@Variant(\0\0\0\x7f\0\0\0\x16QList<QNetworkCookie>\0\0\0\0\x1';
my %ESCAPES = (
	'b'  => "\b",
	'f'  => "\f",
	'n'  => "\n",
	'r'  => "\r",
	't'  => "\t",
	'\\' => '\\',
);

sub _read_length_block {
	my $str_ref = shift;
	
	my $bytes;
	for (1..4) {
		my $c = substr($$str_ref, 0, 1, '');
		if ($c ne '\\') {
			$bytes .= sprintf '%x', ord($c);
			next;
		}
		
		$c = substr($$str_ref, 0, 1, '');
		if ($c ne 'x') {
			if (exists $ESCAPES{$c}) {
				$bytes .= sprintf '%x', ord($ESCAPES{$c});
			}
			else {
				$bytes .= sprintf '%x', int $c;
			}
			next;
		}
		
		$c = substr($$str_ref, 0, 1, '');
		if (substr($$str_ref, 0, 1) =~ /[a-f0-9]/) {
			$c .= substr($$str_ref, 0, 1, '');
		}
		if (length($c) == 1 && $bytes && substr($bytes, -2) ne '\0') {
			# \0\0\x1\x4 -> 00104
			$c = '0'.$c;
		}
		$bytes .= $c;
	}
	
	hex($bytes);
}

sub load {
	my $self = shift;
	my $file = shift || $self->{'file'} || return;
	
	open my $fh, '<', $file or return;
	<$fh>; # omit header
	my $data = <$fh>;
	$data =~ s/\\"/"/g;
	close $fh;
	unless (substr($data, 0, length(MAGIC), '') eq MAGIC) {
		warn "$file does not seem to contain cookies";
		return;
	}
	
	my $cnt = _read_length_block(\$data);
	my ($len, $cookie, $cookie_str);
	for (my $i=0; $i<$cnt; $i++) {
		$len = _read_length_block(\$data);
		$cookie_str = substr($data, 0, $len, '');
		
		# beginning may be in hex notation
		my $additional = 0;
		while ((my $c = substr($cookie_str, $additional, 4)) =~ /\\x[a-f0-9]{2}/) {
			substr($cookie_str, $additional, 4) = chr hex substr $c, 2;
			$additional++;
		}
		$cookie_str .= substr($data, 0, $additional*3, '');
		
		if ($additional = $cookie_str =~ s/\\\\/\\/g) {
			$cookie_str .= substr($data, 0, $additional, '');
		}
		#print $cookie_str, "\n";
		
		unless ($cookie_str) {
			warn "Ooops, looks like we can't read cookie. Please report this bug with cookies file attached to author of ".__PACKAGE__;
		}
		
		# properly process quoted values
		# however anyway it is broken in HTTP::Cookies 6.01 - rt70721
		my ($key_val) = split_header_words($cookie_str);
		$key_val = join_header_words($key_val->[0], $key_val->[1]);
		my $tmp = $cookie_str;
		#                        value inside key_val may be quoted, but original may be not, so check it
		substr($tmp, 0, substr($tmp, length($key_val), 1) eq ';' ? length($key_val)+1 : length($key_val)-1) = '';
		my @cookie_parts = split ';', $tmp;
		
		my ($domain, $path);
		for (my $i=0; $i<@cookie_parts; $i++) {
			last if $path && $domain;
			if (!$domain and ($domain) = $cookie_parts[$i] =~ /domain=(.+)/) {
				next;
			}
			if (!$path) {
				($path) = $cookie_parts[$i] =~ /path=(.+)/
			}
		}
		
		# generate fake request, so we can reuse extract_cookies() method
		my $req  = HTTP::Request->new(GET => "http://".(substr($domain, 0, 1) eq '.' ? 'www' : '')."$domain$path");
		my $resp = HTTP::Response->new(200, 'OK', ['Set-Cookie', $cookie_str]);
		$resp->request($req);
		
		$self->extract_cookies($resp);
	}
	
	1;
}

sub _generate_length_block {
	my $length = shift;
	
	my $normalize = sub {
		my $str = shift;
		return $str if length($str) != 2;
		$str =~ s/^0//;
		$str;
	};
	
	my $bytes;
	my $hex = sprintf '%x', $length;
	my $part;
	for (1..4) {
		$bytes = (length($hex) ? '\x'.$normalize->(substr($hex, -2, 2, '')) : '\0'). $bytes;
	}
	
	$bytes;
}

sub save {
	my $self = shift;
	my $file = shift || $self->{'file'} || return;
	open my $fh, '>', $file or die "Can't open $file: $!";
	
	my $res = MAGIC;
	my @cookies;
	
	$self->scan(sub {
		my ($version,$key,$val,$path,$domain,$port,
		    $path_spec,$secure,$expires,$discard,$rest) = @_;
		
		return if $discard && !$self->{ignore_discard};
		my @cookie_parts;
		
		push @cookie_parts, $val =~ /^"/ ? "$key=$val" : join_header_words($key, $val);
		push @cookie_parts, 'secure' if $secure;
		push @cookie_parts, keys %$rest;
		push @cookie_parts, 'expires='.time2str($expires) if $expires;
		push @cookie_parts, 'domain='.$domain;
		push @cookie_parts, 'path='.$path;
		
		push @cookies, join '; ', @cookie_parts;
	});
	
	$res .= _generate_length_block(scalar @cookies);
	for my $cookie (@cookies) {
		$res .= _generate_length_block(length $cookie);
		$cookie =~ s/\\/\\\\/g;
		$cookie =~ s/"/\\"/g;
		# any valid hex symbol at the beginning should be replaced with \x notation
		my $i = 0;
		while ((my $c = substr($cookie, $i, 1)) =~ /[A-Fa-f0-9]/) {
			substr($cookie, $i, 1) = sprintf '\x%x', ord($c);
			$i += 4;
		}
		$res .= $cookie;
	}
	$res .= ')"';
	
	print $fh "[General]\n";
	print $fh $res, "\n";
	close $fh;
	
	1;
}

1;

__END__

=pod

=head1 NAME

HTTP::Cookies::PhantomJS - read and write PhantomJS cookies file

=head1 SYNOPSIS

	use strict;
	use HTTP::Cookies::PhantomJS;
	use WWW::Mechanize::PhantomJS;
	use LWP::UserAgent;
	
	my $phantom = WWW::Mechanize::PhantomJS->new(cookie_file => 'cookies.txt');
	$phantom->get('https://www.google.com/');
	
	my $lwp = LWP::UserAgent->new(cookie_jar => HTTP::Cookies::PhantomJS->new(file => 'cookies.txt'));
	# will reuse cookies received by PhantomJS!
	$lwp->get('https://www.google.com/');

=head1 DESCRIPTION

This is just L<HTTP::Cookies> subclass, so it has all same methods, but reloads C<load()> and C<save()>
to make available reading and writing of PhantomJS cookies file. You can easily transform (if you need)
C<HTTP::Cookies> object to C<HTTP::Cookies::PhantomJS> or vice versa by reblessing (dirty way) or with
code like this:

	use strict;
	use HTTP::Cookies;
	use HTTP::Cookies::PhantomJS;
	
	 my $plain_cookies = HTTP::Cookies->new;
	 # fill it with LWP or other way
	 ....
	 # transform
	 my $phantom_cookies = HTTP::Cookies::PhantomJS->new;
	 $plain_cookies->scan(sub {
		$phantom_cookies->set_cookie(@_);
	 });

=head1 SEE ALSO

L<HTTP::Cookies>

=head1 AUTHOR

Oleg G, E<lt>oleg@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=cut
