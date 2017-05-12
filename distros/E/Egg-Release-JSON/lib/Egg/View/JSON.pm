package Egg::View::JSON;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: JSON.pm 189 2007-08-08 01:43:47Z lushe $
#
use strict;
use warnings;
use Carp qw/croak/;
use base qw/Egg::View/;
use JSON;

our $VERSION = '0.01';

=head1 NAME

Egg::Release::JSON - JSON for Egg::View.

=head1 SYNOPSIS

Configuration.

  VIEW => [
    .....
    [ JSON => {
      content_type => 'text/javascript+json',
      charset => 'UTF-8',
      option  => { pretty => 1, indent => 2 },
      } ],
    ],

Example code.

  $e->default_view('JSON')->obj({
    hoge=> 'boo',
    baaa=> 'wii',
    });

* It leaves it to the operation of Egg now.

=head1 DESCRIPTION

It is VIEW to output JSON.

JSON is output by the 'objToJson' function of L<JSON > module.

see L<JSON>.

=head1 CONFIGURATION

Please add JSON to the setting of VIEW.

  VIEW => [
    ......
    ...
    [ JSON => {
      .......
      ...
      } ],
    ],

=head2 content_type

Contents type when JSON is output.

Default is 'text/javascript+json'.

=head2 charset

Character set when JSON is output.

Default is 'UTF-8'.

=head2 option

Option to pass to objToJson function of L<JSON> module.

  option=> { pretty => 1, indent => 2 },

see L<JSON>;

* When following 'x_json' is made effective, the inconvenience is generated
  because the JSON code is molded when option is set.

=head2 x_json

When an effective value is set, it comes always to output the JSON data to
'X-JSON' of the response header.
When the JSON data is treated with Prototype.js, this is convenient.

* This value invalidates and is good at the thing individually made effective
  by the 'x_json' method.

Default is 0.

=head1 METHODS

=head2 obj ( {[HASH or ARRAY or etc.]} )

The data to give it to the objToJson function of L<JSON> module is maintained.

It is necessary to define some values like being undefined the first stage.

The value set to call it without giving anything is returned.

  # ARRAY is defined.
  my $array= $e->view('JSON')->obj([]);
  
  # HASH is defined.
  my $hash= $e->view('JSON')->obj({});

=head2 x_json ( [BOOL] )

Response header (X-JSON) contains the JSON code.

* Please refer to 'x_json' of CONFIGURATION.

  $e->view('JSON')->x_json(1);
  
  # Output response header.
  Content-Type: text/javascript+json; charset=utf-8
  X-JSON: ({"hoge":11111,"boo":22222})

When 'x_json' is effective, the contents header comes to be output it always
followed.

  <div>JSON sees in the response header.</div>

=cut
__PACKAGE__->mk_accessors(qw/obj x_json/);

sub _setup {
	my($class, $e, $conf)= @_;
	$conf->{content_type} ||= 'text/javascript+json';
	$conf->{charset}      ||= 'utf-8';
	$conf->{option}       ||= {};
}

=head2 render

The result of the objToJson function of L<JSON> module is returned.

  my $view= $e->view('JSON');
  my $obj= $view->obj({});
  $obj->{hoge}= '11111';
  $obj->{booo}= '22222';
  
  my $json_js= $view->render($obj);

=cut
sub render {
	my $view= shift;
	my $obj = shift || return(undef);
	objToJson($obj, $view->config->{option});
}

=head2 output

It is not necessary to call it from the project code because it is called by 
the operation of Egg usually.

=cut
sub output {
	my $view= shift;
	my $obj= shift || $view->obj || croak q{ I want json data. };
	my($e, $c)= ($view->e, $view->config);
	$e->res->content_type
	  ("$c->{content_type}; charset=$c->{charset}");
	my $json= $view->render($obj, @_);
	if ($view->x_json or $c->{x_json}) {
		$e->res->headers->header('X-JSON'=> "($json)");
		$json= "<div>JSON sees in the response header.</div>";
	}
	$e->response->body(\$json);
}

=head1 SEE ALSO

L<JSON>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>http://egg.bomcity.com/E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
