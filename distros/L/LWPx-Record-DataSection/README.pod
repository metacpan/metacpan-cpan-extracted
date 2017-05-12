package LWPx::Record::DataSection;
use strict;
use warnings;
use LWP::Protocol;
use Data::Section::Simple;
use B::Hooks::EndOfScope;
use HTTP::Response;
use CGI::Simple;
use CGI::Simple::Cookie;

our $VERSION = '0.01';

our $Data;
our ($Pkg, $File, $Fh);

our $Option = {
    decode_content         => 1,
    record_response_header => undef,
    record_request_cookie  => undef,
    record_post_param      => undef,
    append_data_section    => !!$ENV{LWPX_RECORD_APPEND_DATA},
};

# From HTTP::Headers
our @CommonHeaders = qw(
    Cache-Control Connection Date Pragma Trailer Transfer-Encoding Upgrade
    Via Warning
    Accept-Ranges Age ETag Location Proxy-Authenticate Retry-After Server
    Vary WWW-Authenticate
    Allow Content-Encoding Content-Language Content-Length Content-Location
    Content-MD5 Content-Range Content-Type Expires Last-Modified
);

sub import {
    my ($class, %args) = @_;

    while (my ($key, $value) = each %args) {
        $key =~ s/^-//;
        $Option->{$key} = $value;
    }

    for (my $level = 0; ; $level++) {
        my ($pkg, $file) = caller($level) or last;
        next unless $file eq $0;

        if (defined $Pkg && $pkg ne $Pkg) {
            require Carp;
            Carp::croak("only one class can use $class");
        }

        ($Pkg, $File) = ($pkg, $file);
        on_scope_end {
            $class->load_data;

            # append __DATA__ section only when direct import
            if ($level == 0 && not defined $Data) {
                __PACKAGE__->append_to_file("\n__DATA__\n\n");
                $Data = {};
            }

            LWP::Protocol::Fake->fake;
        };
        return;
    }

    require Carp;
    Carp::croak "Suitable file not found: $0";
}

sub load_data {
    my $class = shift;
    $Data = Data::Section::Simple->new($Pkg)->get_data_section;
    return $Data;
}

sub append_to_file {
    my $class = shift;
    return unless $Option->{append_data_section};
    unless ($Fh && fileno $Fh) {
        open $Fh, '>>', $File or die $!;
    }
    print $Fh @_;
}

sub request_to_key {
    my ($class, $req) = @_;

    my @keys = ( $req->method, $req->uri );
    if (my $cookie_keys = $Option->{record_request_cookie}) {
        my $cookie  = $req->header('Cookie');
        my %cookies = CGI::Simple::Cookie->parse($cookie);
        push @keys, 'Cookie:' . join ',', map { "$_=" . $cookies{$_}->value } grep { $cookies{$_} } sort @$cookie_keys;
    }
    if (my $post_params = $Option->{record_post_param}) {
        my $q = CGI::Simple->new($req->content);
        push @keys, 'Post:' . join ',', map { my $key = $_; map { "$key=$_" } $q->param($_) } grep { $q->param($_) } sort @$post_params;
    }

    return join ' ', @keys;
}

sub restore_response {
    my ($class, $req) = @_;

    my $key = $class->request_to_key($req);
    if (my $string = $Data && $Data->{$key}) {
        $string =~ s/\n\z//;
        utf8::encode $string if utf8::is_utf8 $string;
        my $res = HTTP::Response->parse($string);
        $res->request($req);
        return $res;
    }
}

sub store_response {
    my ($class, $res, $req) = @_;
    my $key = $class->request_to_key($req);

    my $res_to_store = $res->clone;
    if ($Option->{decode_content}) {
        my $content = $res_to_store->decoded_content;
        utf8::encode $content if utf8::is_utf8 $content;
        $res_to_store->content($content);
        $res_to_store->content_length(length $content);
        $res_to_store->remove_header('Content-Encoding');
    }

    my $record_response_header = $Option->{record_response_header} || [];
    unless ($record_response_header eq ':all') {
        my %header_to_keep = map { uc $_ => 1 } ( @CommonHeaders, @$record_response_header );
        foreach ($res_to_store->header_field_names) {
            $res_to_store->remove_header($_) unless $header_to_keep{ uc $_ };
        }
    }

    $class->append_to_file("@@ $key\n");
    $class->append_to_file($res_to_store->as_string("\n"), "\n");

    $Data->{$key} = $res_to_store->as_string;
}

package #
    LWP::Protocol::Fake;

our $ORIGINAL_LWP_Protocol_create = \&LWP::Protocol::create;

sub fake {
    my $class = shift;
    no warnings 'redefine';
    *LWP::Protocol::create = sub { LWP::Protocol::Fake->new(@_) };
}

sub unfake {
    my $class = shift;
    no warnings 'redefine';
    *LWP::Protocol::create = $ORIGINAL_LWP_Protocol_create;
}

sub new {
    my ($class, $scheme, $ua) = @_;
    bless { scheme => $scheme, ua => $ua, real => &$ORIGINAL_LWP_Protocol_create($scheme, $ua) }, $class;
}

sub request {
    my ($self, $request, $proxy, $arg, $size, $timeout) = @_;

    if (my $res = LWPx::Record::DataSection->restore_response($request)) {
        return $res;
    } else {
        my $res = $self->{real}->request($request, $proxy, $arg, $size, $timeout);
        LWPx::Record::DataSection->store_response($res, $request);
        return $res;
    }
}

1;

__END__

=head1 NAME

LWPx::Record::DataSection - Record/restore LWP response using __DATA__ section

=head1 SYNOPSIS

  use Test::More;
  use LWPx::Record::DataSection;
  use LWP::Simple qw($ua);

  my $res = $ua->get('http://www.example.com/'); # does not access to the internet actually
  is $res->code, 200;

  __DATA__

  @@ GET http://www.example.com/
  HTTP/1.0 200 OK
  Content-Type: text/html
  ... # HTTP response

=head1 DESCRIPTION

LWPx::Record::DataSection overrides LWP::Protocol and creates response object from __DATA__ section.
The response should be recorded as below:

  __DATA__

  @@ [method] [url]
  [raw response]

  @@ [method] [url]
  [raw response]

  ...

=head1 RECORDING RESPONSES

When LWP try to send request without corresponding data section,
LWPx::Record::DataSection allows actual connection and records the response to the test file's __DATA__ section.

Example:

  # test.t
  use strict;
  use Test::More;
  use LWPx::Record::DataSection;
  use LWP::Simple qw($ua);

  my $res = $ua->get('http://www.example.com/');
  is $res->code, 200;

  # No __END__ please, LWPx::Record::DataSection confuses
  __DATA__

Running this test with environment variable LWPX_RECORD_APPEND_DATA=1 
appends the actual response to the test file itself, thus produces such:

  # test.t
  use strict;
  use Test::More;
  use LWPx::Record::DataSection;
  use LWP::Simple qw($ua);

  my $res = $ua->get('http://www.example.com/');
  is $res->code, 200;

  # No __END__ please, LWPx::Record::DataSection confuses
  __DATA__
  @@ GET http://www.example.com/
  HTTP/1.0 302 Found
  Connection: Keep-Alive
  Location: http://www.iana.org/domains/example/
  ...
  
  @@ GET http://www.iana.org/domains/example/
  HTTP/1.1 200 OK
  ...

After that running the test does not require internet connection.

=head1 CLASS METHODS

=over 4

=item LWPx::Record::DataSection->load_data

Load __DATA__ section into $LWPx::Record::DataSection::Data.
LWPx::Record::DataSection->import implies this,
so if you do not C<< use >> this module, explicitly call this.

Example:

  use Test::Requires 'LWPx::Record::DataSection';
  LWPx::Record::DataSection->load_data;

=back

=head1 OPTIONS

  You can specify option when C<< use >> this module.

  use LWPx::Record::DataSection %option;

=over 4

=item decode_content => 1 | 0

By default, responses are recorded as decoded so that you will not see
unreadable bytes in your file. If this behavior is not desired,
turn this option off.

=item record_response_header => \@headers | ':all'

By default, uncommon headers like "X-Framework" are dropped when recording.
Specify this option to record extra headers.

=item record_post_param => \@params

Use POSTed parameters as extra key. Post keys are recorded as:

  @@ POST http://localhost/ Post:foo=1,foo=2

=item record_request_cookie => \@keys

By default, only request method and request uri are used to identify request.
Specify this option to use certain cookie as key. Cookie keys are recorded as:

  @@ GET http://localhost/ Cookie:foo=1,bar=2

=item append_data_section => $ENV{LWPX_RECORD_APPEND_DATA};

Automatically record responses to __DATA__ section if not recorded.
You can specify this by LWPX_RECORD_APPEND_DATA environment variable.

=back

=head1 CAVEATS

If the file contains __END__ section, storing response will not work.

L<< LWPx::Record::DataSection >> appends __DATA__ section only files that
directly C<< use >> this module. This is to avoid accidents.

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=head1 SEE ALSO

L<< Data::Section::Simple >>, L<< LWP::Protocol >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
