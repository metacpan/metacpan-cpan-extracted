package Google::reCAPTCHA::v3;

our $VERSION = '0.1.0';
use warnings; 
use strict;

use Carp qw(croak carp);
use LWP; 
use HTTP::Request::Common qw(POST);
use JSON qw( decode_json );

use vars qw($AUTOLOAD);
my %allowed = ( 
	request_url => 'https://www.google.com/recaptcha/api/siteverify',
	secret      => undef, 
);

sub new {

    my $that = shift;
    my $class = ref($that) || $that;

    my $self = {
        _permitted => \%allowed,
        %allowed,
    };

    bless $self, $class;

    my ($args) = @_;

    $self->_init($args);
    return $self;
}

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self)
      or croak "$self is not an object";
	  
    my $name = $AUTOLOAD;
       $name =~ s/.*://;    #strip fully qualifies portion

    unless ( exists $self->{_permitted}->{$name} ) {
        croak "Can't access '$name' field in object of class $type";
    }
    if (@_) {
        return $self->{$name} = shift;
    }
    else {
        return $self->{$name};
    }
}

sub _init {
    my $self = shift;
    my ($args) = @_;
	
	if(exists($args->{-secret})){ 
		$self->secret($args->{-secret}); 
	}
	else {
		carp "You'll need to pass the Google reCAPTCHA v3 secret key to new()";
	}
	
}

sub request { 
	my $self = shift; 
	my ($args) = @_; 
	
	my $ua = LWP::UserAgent->new;
	
	if(!exists($args->{-response})){ 
		carp 'you will need to pass your response in -response to request()';
		return undef; 
	}
	
	my $req_params = { 
		response => $args->{-response},
	};
	
	if(exists($args->{-remoteip})){ 
    	$req_params->{remoteip} = $args->{-remoteip}; 
	}
	if(defined($self->secret)){ 
		$req_params->{secret} = $self->secret; 
	}
	my $req = POST $self->request_url(), [%{$req_params}];
		
	my $json = JSON->new->allow_nonref;
	
	return $json->decode(
		$ua->request($req)->decoded_content
	);	
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Google::reCAPTCHA::v3 - A simple Perl API for Google reCAPTCHA v3

=head1 SYNOPSIS

	use Google::reCAPTCHA::v3;

	my $grc = Google::reCAPTCHA::v3->new(
		{
			-secret => 'Google reCAPTCHA v3 site secret key',
		}
	);

	my $r = $grc->request(
		{ 
			-response => 'response_token',
			-remoteip => $remote_ip, # optional 
		}
	); 

=head1 DESCRIPTION

Google reCAPTCHA v3 is a simple module that is used to verify the reCAPTCHA response token generated from the front end 
of your app.

See: L<https://developers.google.com/recaptcha/docs/verify>. 

=head1 METHODS

=head2 new

	my $grc = Google::reCAPTCHA::v3->new(
		{
			-secret => 'Google reCAPTCHA v3 site secret key',
		}
	);

Requires one paramater, C<-secret>, which should be your Google reCAPTCHA v3 site secret key. 
Returns a new Google::reAPTCHA::v3 object. 
	
=head2 request

	my $r = $grc->request(
		{ 
			-response => 'response_token',
			-remoteip => $remote_ip, # optional 
		}
	); 

	if($r->{success} == 1){ 
		# do useful things, like check the score
	}
	else { 
		# well, that didn't work. 
	}

Requires one paramater, C<-response>, which should be the reCAPTCHA response token generated from the front end 
of your app. 

Optionally, you can pass, C<-remoteip>, which should be your user's IP address.

request returns a hashref of what's return from the service, with the following keys: 

=over

=item * success

C<1> (valid) or C<0> (invalid). 

Whether this request was a valid reCAPTCHA token for your site

=item * score

C<number> 

The score for this request (0.0 - 1.0)

=item * action 

The action name for this request (important to verify)

=item * challenge_ts

Timestamp of the challenge load (ISO format yyyy-MM-dd'T'HH:mm:ssZZ)

=item * hostname

The hostname of the site where the reCAPTCHA was solved

=item * error-codes

=back

=head1 LICENSE

Copyright (C) Justin Simoni

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

Please file any bugs/issues within the github repo: L<https://github.com/justingit/Google-reCAPTCHA-v3/issues>

=head1 AUTHOR

Justin Simoni

=cut