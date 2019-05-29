#!/usr/bin/perl

use strict;
use warnings;

use GRNOC::WebService::Dispatcher;
use GRNOC::WebService::Method;

my $web_svc = GRNOC::WebService::Dispatcher->new();

sub get_image {

  my ($method, $args) = @_;

  my $raw_data;
  my $buf;

  open(IMAGE, "image.jpg");

  while (read(IMAGE, $buf, 1024)) {

    $raw_data .= $buf;
  }

  close(IMAGE);

  return $raw_data;
}

my $method = GRNOC::WebService::Method->new(name => 'get_image',
                                            description => 'return raw image data',
                                            expires => "-1d",
                                            output_type => "image/jpeg",
                                            output_formatter => sub { return shift; },
                                            callback => \&get_image);

$web_svc->register_method($method);


sub put_image {
    my ($method, $params, $state) = @_;

    my $handle = $params->{'image'}{'value'};

    my $data;
    my $buffer;

    while (read($handle, $buffer, 1024)){
        $data .= $buffer;
    }

    my $success = 0;

    # length of image.jpg in testing
    if (length($data) == 23479){
        $success = 1;
    }

    return {'results' => [{'success' => $success}]};
}


$method = GRNOC::WebService::Method->new(name => 'put_image',
                                         description => 'uploads an image',
                                         expires => "-1d",
                                         callback => \&put_image);


$method->add_input_parameter( name => 'image',
                              pattern => '^(.*)',
                              required => 1,
                              multiple => 0,
                              attachment => 1,
                              description => 'the image to upload' );

$web_svc->register_method($method);

$web_svc->handle_request();
