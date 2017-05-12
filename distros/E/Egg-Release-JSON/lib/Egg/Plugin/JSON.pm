package Egg::Plugin::JSON;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: JSON.pm 189 2007-08-08 01:43:47Z lushe $
#
use strict;
use warnings;
use FileHandle;
use JSON;
use Carp qw/croak/;

our $VERSION = '0.01';

=head1 NAME

Egg::Release::JSON - JSON for Egg::Plugin.

=head1 SYNOPSIS

Controller.

  use Egg qw/ JSON /;

Example code.

  my $json_data = {
    aaaaa => 'bbbbb',
    ccccc => 'ddddd',
    };
  
  #
  # Mutual conversion of JSON data.
  #
  my $json_js   = $e->obj2json($json_data);
  my $json_hash = $e->json2obj($json_js);
  
  #
  # The JSON module object is acquired.
  #
  my $json= $e->json;

=head1 DESCRIPTION

It is a plugin to treat JSON.

L<JSON> module is used.
Please refer to the document of L<JSON> for details.

=head1 METHODS

=head2 obj2json ( [JSON_DATA] )

It is wraper to the 'objToJson' function of L<JSON> module.

HASH and ARRAY are given to JSON_DATA.

  my $js= $e->obj2json($local_data);

=cut
sub json2obj { shift; JSON::jsonToObj(@_) }

=head2 json2obj ( [JSON_JS] )

It is wraper to the 'jsonToObj' function of L<JSON > module.

The JSON data is given to JSON_JS.

  my $local_data= $e->json2obj($json_js);

=cut
sub obj2json { shift; JSON::objToJson(@_) }

=head2 json

The object of L<JSON> module is returned.

  my $json= $e->json;

=cut
sub json { shift->{json_handler} ||= JSON->new(@_) }

=head2 get_json ( [FILE_PATH] || [REQUEST_METHOD], [URL], [LWP_OPTION])

The JSON code is acquired by the file and URL and the Egg::Plugin::JSON::Result
object is returned.

The occurrence of the error can be confirmed by is_success and the is_error
method of the returned object.

* When URL is specified, the thing that L<Egg::Plugin::LWP> can be used.

  my $result= $e->get_json( GET=> 'http://domain/json_code' );
  
  my $json_obj;
  if ($result->is_success and $json_obj= $result->obj) {
    $e->view->param('json_text', $json_obj->{message});
  } else {
    $e->debug_out('JSON ERROR : '. $result->is_error);
    $e->finished(500);
  }

=cut
sub get_json {
	my $e = shift;
	my $sc= shift || croak q{ I want argument. };
	my $result_class= 'Egg::Plugin::JSON::Result';
	my $data;
	if (my $url= shift) {
		my $res= $e->ua->request($sc, $url, @_);
		if ($res->is_success) {
			return $result_class->new(1, $e->json2obj($res->content));
		} else {
			my $error= $res
			  ? do { $res->status_line || 'Internal error(1).' }
			  : 'Internal error(2).';
			return $result_class->new(0, $error);
		}
	} else {
		my $fh= FileHandle->new($sc)
		   || return $result_class->new(0, "$! - $sc");
		my $js_code= join '', $fh->getlines;
		$fh->close;
		return $result_class->new(1, $e->json2obj($js_code));
	}
}

package Egg::Plugin::JSON::Result;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

=head1 RESULT METHODS

It is a method of Egg::Plugin::JSON::Result that get_json returns.

=cut

__PACKAGE__->mk_accessors(qw/is_success is_error obj/);

sub new {
	my $class  = shift;
	my $success= shift || 0;
	my $obj= shift || do { $success= 0; 'There is no data.' };
	bless {
	  is_success=> $success,
	  %{ $success ? { obj => $obj }: { is_error => $obj } },
	  }, $class;
}

=head2 new

Constructor

=head2 is_success

When the data conversion of the obtained JSON code succeeds, true is restored.

=head2 obj

Data returns when is_success is true.

=head2 is_error

The error message returns when is_success is false.

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
