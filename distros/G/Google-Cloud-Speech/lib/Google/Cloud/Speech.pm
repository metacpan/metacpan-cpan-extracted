package Google::Cloud::Speech;

use Mojo::Base -base;

use Google::Cloud::Speech::Auth;
use Mojo::UserAgent;
use MIME::Base64;
use Mojo::File;
use Carp;

$Google::Cloud::Speech::VERSION = '0.03';

has secret_file => sub { };
has ua          => sub { Mojo::UserAgent->new() };
has file        => sub { croak 'you must specify the audio file'; };
has samplerate  => '16000';
has language    => 'en-IN';
has baseurl  => 'https://speech.googleapis.com/v1';
has encoding => 'linear16';
has async_id => undef;
has results  => undef;

has config => sub {
    my $self = shift;

    return {
        encoding        => $self->encoding,
        sampleRateHertz => $self->samplerate,
        languageCode    => $self->language,
        profanityFilter => 'false',
    };
};

has auth_class  => sub {
	my $self = shift; 
	Google::Cloud::Speech::Auth->new(from_json => $self->secret_file);
};

sub token {
	my $self = shift;

	my $auth_obj = $self->auth_class;
	unless ($auth_obj->has_valid_token) {
		return $auth_obj->request_token->token();
	}

	return $auth_obj->token;
}

sub syncrecognize {
    my $self = shift;

    my $audio_raw = Mojo::File->new( $self->file )->slurp();

    my $audio = { "content" => encode_base64( $audio_raw, "" ) };
    my $header = {
        'Content-Type'  => "application/json",
        'Authorization' => $self->token,
    };

    my $hash_ref = {
        config => $self->config,
        audio  => $audio,
    };

    my $url = $self->baseurl . "/speech:recognize";
    my $tx = $self->ua->post( $url => $header => json => $hash_ref );

    my $response = $self->handle_errors($tx)->json;
    if ( my $results = $response->{'results'} ) {
        return $self->results($results);
    }
    return $self->results( [] );

}

sub asyncrecognize {
    my $self = shift;

    my $audio_raw = Mojo::File->new( $self->file )->slurp();
    my $audio     = { "content" => encode_base64( $audio_raw, "" ) };
    my $header    = {
        'Content-Type'  => "application/json",
        'Authorization' => $self->token,
    };

    my $hash_ref = {
        config => $self->config,
        audio  => $audio,
    };

    my $url = $self->url . "/speech:longrunningrecognize";
    my $tx = $self->ua->post( $url => $header => json => $hash_ref );

    my $res = $self->handle_errors($tx)->json;
    if ( my $name = $res->{'name'} ) {
        $self->async_id($name);

        return $self;
    }

    croak 'there was an error';
}

sub is_done {
    my $self = shift;

    my $async_id = $self->async_id;
    return unless $async_id;

    my $url = $self->url . "/operations/" . $async_id;
    my $tx = $self->ua->get( $url => { 'Authorization' => $self->token } );

    my $res     = $self->handle_errors($tx)->json;
    my $is_done = $res->{'done'};

    if ($is_done) {
        $self->{'results'} = $res->{'response'}->{'results'};
        return 1;
    }

    return 0;
}

sub handle_errors {
    my ( $self, $tx ) = @_;
    my $res = $tx->res;

    unless ( $tx->success ) {
        my $error_ref = $tx->error;
        croak( "invalid response: " . $error_ref->{'message'} );
    }

    return $res;
}

1;

=encoding utf8

=head1 NAME

Google::Cloud::Speech - An interface to Google cloud speech service

=head1 SYNOPSIS

	use Data::Dumper;
	use Google::Cloud::Speech;

	my $speech = Google::Cloud::Speech->new(
		file        => 'test.wav',
		secret_file => 'my/google/app/project/sa/json/file'
	);

	# long running process
	my $operation = $speech->asyncrecognize();
	my $is_done = $operation->is_done;
	until($is_done) {
		if ($is_done = $operation->is_done) {
			print Dumper $operation->results;
		}
	}

=head1 DESCRIPTION

This module lets you access Google cloud speech service.

=head1 ATTRIBUTES

=head2 C<secret_file>

Loads the JSON file from Google with the client ID informations.

	$speech->secret_file('/my/google/app/project/sp/json/file');

To create, Google Service Account Key:

	1) Login to Google Apps Console and select your project
	2) Click on create credentials-> service account key. 
	4) Select a service account and key type as JSON and click on create and downlaoded the JSON file.
	
	See L<Google API Doc|https://developers.google.com/identity/protocols/application-default-credentials> for more details about API authentication.

=head2 encoding

	my $encoding = $speech->encoding('linear16');

Encoding of audio data to be recognized.
Acceptable values are:
        
		* linear16 - Uncompressed 16-bit signed little-endian samples.
			(LINEAR16)
		* flac - The [Free Lossless Audio
			Codec](http://flac.sourceforge.net/documentation.html) encoding.
			Only 16-bit samples are supported. Not all fields in STREAMINFO
			are supported. (FLAC)
		* mulaw - 8-bit samples that compand 14-bit audio samples using
			G.711 PCMU/mu-law. (MULAW)
		* amr - Adaptive Multi-Rate Narrowband codec. (`sample_rate` must
			be 8000 Hz.) (AMR)
		* amr_wb - Adaptive Multi-Rate Wideband codec. (`sample_rate` must
			be 16000 Hz.) (AMR_WB)
		* ogg_opus - Ogg Mapping for Opus. (OGG_OPUS)
			Lossy codecs do not recommend, as they result in a lower-quality
			speech transcription.
		* speex - Speex with header byte. (SPEEX_WITH_HEADER_BYTE)
        
        
=head2 file
	
	my $file = $speech->file;
	my $file = $speech->('path/to/audio/file.wav');


=head2 language

	my $lang = $speech->language('en-IN');

The language of the supplied audio as a BCP-47 language tag. 
Example: "en-IN" for English (United States), "en-GB" for English (United
Kingdom), "fr-FR" for French (France). See Language Support for a list of the currently supported language codes. 
L<Language codes|https://cloud.google.com/speech/docs/languages>

=head2 samplrate

	my $sample_rate = $speech->samplerate('16000');

Sample rate in Hertz of the audio data to be recognized. Valid values
are: 8000-48000. 16000 is optimal. For best results, set the sampling
rate of the audio source to 16000 Hz. If that's not possible, use the
native sample rate of the audio source (instead of re-sampling).


=head1 METHODS

=head2 asyncrecognize

Performs asynchronous speech recognition: 
receive results via the google.longrunning.Operations interface. 

	my $operation = $speech->asyncrecognize();
	my $is_done = $operation->is_done;
	until($is_done) {
		if ($is_done = $operation->is_done) {
			print Dumper $operation->results;
		}
	}


=head2 syncrecognize

Performs synchronous speech recognition: receive results after all audio has been sent and processed.
	
	my $operation = $speech->syncrecognize;
	print $operation->results;

=head2 is_done

Checks if the speech-recognition processing of the audio data is complete.
return 1 when complete, 0 otherwise.

=head2 results

returns the transcribed data as Arrayref.

	print Dumper $speech->syncrecognize->results;

=head1 AUTHOR

Prajith P C<me@prajith.in>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017, Prajith P.

This is free software, you can redistribute it and/or modify it under
the same terms as Perl language system itself.


=head1 SEE ALSO

=over

=item * L<Google Cloud Speech API|https://cloud.google.com/speech/reference/rest/>

=back

=cut

=head1 DEVELOPMENT

This project is hosted on Github, at
L<https://github.com/Prajithp/p5-google-cloud-speech>

=cut
