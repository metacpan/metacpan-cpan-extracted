package Furl::Cookies;
use strict;
use warnings;
use Time::Local;
#use Data::Dumper::Concise;

our $VERSION = '0.03';

my $month = {
	Jan =>  1,Feb =>  2,Mar =>  3,Apr =>  4,May =>  5,Jun =>  6,
	Jul =>  7,Aug =>  8,Sep =>  9,Oct => 10,Nov => 11,Dec => 12,
};

sub new{
	return bless({COOKIES => {},},shift);
}

sub extract_cookies{
	my ($self,$res,$req) = @_;
	$req->uri =~ /^http[s]*:\/\/([^:\/]*)[:]*[0-9]*/;
	my $default_domain = $1;
	for my $cookie (@{$res->headers->{'set-cookie'}}){
		#print $cookie . "\n";
		my ($expires,$domain,$path,$secure,$key,$value);
		for (split(/;/,$cookie)){
			$_ =~ s/^[\s]*//;
			$secure = ($_ =~ /secure/)?1:0;
			if($_ =~ /domain/){
				my @tmp = split(/=/,$_);
				$domain = $tmp[1];
			}
			if($_ =~ /path/){
				my @tmp = split(/=/,$_);
				$path = $tmp[1];
			}
			if($_ =~ /expires/){
				my @tmp = split(/=/,$_);
				$tmp[1] =~ /([a-zA-Z]*), ([\w]*)-([\w]*)-([\w]*) ([\w]*):([\w]*):([\w]*) GMT/;
				my ($w,$D,$M,$Y,$h,$m,$s) = ($1,$2,$3,$4,$5,$6,$7);
				$expires = timegm($s,$m,$h,$D,$month->{$M}-1,$Y);
			}
			if($_ !~ /expires|path|domain|secure/){
				my @tmp = split(/=/,$_);
				$key = $tmp[0];
				$value = $tmp[1];
			}
		}
		$domain = $domain?$domain:$default_domain;
		$path = $path?$path:'/';
		$expires = $expires?$expires:undef;
		#next if($expires lt time() && $expires);
		#next if($default_domain !~ /$domain/ && $domain);

		$self->{COOKIES}->{$domain}->{$path}->{$key} = {
			value => $value,
			expires => $expires,
			secure => $secure,
		};
	}
}

sub add_cookie_header{
	my ($self,$req) = @_;
	my $cookies;
	for my $domain (keys %{$self->{COOKIES}}){
		for my $path (keys %{$self->{COOKIES}->{$domain}}){
			$req->headers->{cookie} = join('; ',
				map{$_ . '=' . $self->{COOKIES}->{$domain}->{$path}->{$_}->{value}}
					(keys %{$self->{COOKIES}->{$domain}->{$path}}));
		}
	}
}
1;
__END__

=head1 NAME

Furl::Cookies - HTTP Cookie jars for Furl.

=head1 SYNOPSIS

 use strict;
 use warnings;
 use Furl;
 use Furl::Cookies;
 use HTTP::Request::Common qw/GET/;

 my $furl = new Furl;
 my $cookies = new Furl::Cookies;

 my $req = GET('http:://search.cpan.org');
 $cookis->add_cookie_header($req);
 my $res = $furl->request($req);

 $cookis->extract_cookies($res,$req);
 
 # and use $res

=head1 DESCRIPTION

This is HTTP Cookie jars for Furl.

=head1 Copyright

Kazunori Minoda (c)2012

=cut

