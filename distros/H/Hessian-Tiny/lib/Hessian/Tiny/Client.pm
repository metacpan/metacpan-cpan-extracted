package Hessian::Tiny::Client;

use warnings;
use strict;

require 5.006;

use URI ();
use IO::File ();
use LWP::UserAgent ();
use HTTP::Headers ();
use HTTP::Request ();
use File::Temp ();

use Hessian::Tiny::ConvertorV1 ();
use Hessian::Tiny::ConvertorV2 ();

=head1 NAME

Hessian::Tiny::Client - Hessian RPC Client implementation in pure Perl

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';
our $Error;


=head1 SYNOPSIS

    use Hessian::Tiny::Client;

    my $foo = Hessian::Tiny::Client->new(
        url => 'http://hessian.service.com/serviceName',
        version => 2, # hessian protocol version
    );
    my($stat,$res) = $foo->call('add',2,4);
    if($stat == 0){ # success
        print "2 + 4 = $res";
    }else{
        print "error: $Hessian::Tiny::Client::Error";
    }

=head1 DESCRIPTION

Hessian is a compact binary protocol for web communication in form of client/server RPC.

This module allows you to write Hessian clients in Perl.

This module supports Hessian Protocol 1.0 and 2.0

Perl 5.6.0 or later is required to install this modle.

=head1 SUBROUTINES/METHODS

=head2 new

    my $foo = Hessian::Tiny::Client->new(
        url => 'http://hessian.service.com/serviceName', # mandatory
        version => 2, # default is 1
        debug => 1,   # add some debugging output (to STDERR)
        auth => [$http_user,$http_pass], # http basic auth, if needed
        hessian_flag => 1, # if you need strong typing in return value
    );

=over

=item 'url'

hessian server url, need to be a valid url, otherwise the constructor will return undef.

=item 'version'

hessian protocol version, 1 or 2.

=item 'debug'

for debugging, you probably don't need to set this flag.

=item 'auth'

if http server requires authentication. (passed on to LWP request)

=item 'hessian_flag'

default off, that means return value are automatically converted into native perl data;
if set to true, you will get Hessian::Type::* object as return.

=back

=cut

sub new {
  my($class,@params) = @_;
  my $self = {@params};
  my $u = URI->new($self->{url});
  unless(defined $u and $u->scheme and $u->scheme =~ /^http/){
    $Error = qq[Hessian url not valid: '$$self{url}'];
    return;
  }
  $self->{version} ||= 1; #default v1.0
  return bless $self, $class;
}


=head2 call

    # for convinience, simple types can be passed directly
    ($stat,$res) = $foo->call('addInt',1,2);

    # or use Hessian::Type::* for precise typing
    ($stat,$res) = $foo->call('method1',
        Hessian::Type::Date( Math::BigInt->new( $milli_sec ) ),
        Hessian::Type::Double( 3.14 ),
        Hessian::Type::List( length=>2,
                             data=>[
                                    Hessian::Type::String->new('unicode_stream'),
                                    Hessian::Type::Binary->new('bytes')
                             ] );
        Hessian::Type::Map( type=>'Car',
                            data=>{
                                   'Make' => 'Toto',
                                   'Modle' => 'XYZ'
                            } );
                                                
    ); # end call

    if($stat == 0){
        # success

    }elsif($stat == 1){
        # Hessian Fault
        print "Exception: $res->{code}, $res->{message}";
    }else{
        # communication failure
        print "error: $res";
    }

=over

=item return values:

B<$stat>: 0 for success, 1 for Hessian level Fault, 2 for other errors such as http communication error or parsing anomaly;

B<$res>: will hold the hessian call result if call was successful, or will hold error (Hessian::Fault or string) in case of unsuccessful call;

normally Hessian types are converted to perl data directly, if you want strong typing in return value, you can set (hessian_flag => 1) in the constructor call new().

=cut

sub call {
  my($self,$method_name,@hessian_params) = @_;

  $Error = ''; # reset, probably not needed
# open fh to write call
  my $call_fh = File::Temp::tempfile();
  return 2, $self->_elog("call, open temp call file failed $!") unless defined $call_fh;

# write call to fh
  eval{
    my $wtr = Hessian::Tiny::Type::_make_writer($call_fh);
    if( $self->{version} and $self->{version} == 2 ){
      Hessian::Tiny::ConvertorV2::write_call($wtr,$method_name,@hessian_params);
    }else{
      Hessian::Tiny::ConvertorV1::write_call($wtr,$method_name,@hessian_params);
    }
    1;
  }or return 2, $self->_elog("write_call: $@");

# write call successful, rewind & read
  $call_fh->flush();
  seek $call_fh,0,0;

# make LWP client
  my $ua = LWP::UserAgent->new;
  $ua->agent("Perl Hessian::Tiny::Client $$self{version}");
  my $header = HTTP::Headers->new();

  if('ARRAY' eq ref $self->{auth} and
    length $self->{auth}->[0] > 0 and
    length $self->{auth}->[1] > 0 
  ){
    $header->authorization;
    $header->authorization_basic($self->{auth}->[0],$self->{auth}->[1]);
  }
  my $buf = '';
  binmode $call_fh,':bytes';
  my $http_request = HTTP::Request->new(POST => $self->{url}, $header,sub{
    read $call_fh,$buf,255; $buf
  });

# send http request
  my $reply_fh = File::Temp::tempfile();
  return 2, $self->_elog("call, open temp reply file failed $!") unless defined $reply_fh;
  binmode $reply_fh,':bytes';
  my $http_response = $ua->request($http_request, sub{
    my($chunk,$res,$lwp) = @_; print $reply_fh $chunk;
  });
  $call_fh->close;

  unless($http_response->is_success){ # http level failure
    $reply_fh->close;
    return 2, $self->_elog('Hessian http response unsuccessful: ',
      $http_response->status_line, $http_response->error_as_HTML)
    ;
  }

  my($st,$re);
  $reply_fh->flush();
  seek $reply_fh,0,0;
  eval{
    ($st,$re) = _read_reply( Hessian::Tiny::Type::_make_reader($reply_fh),$self->{hessian_flag});
    1;
  } or return 2, $self->_elog("Hessian parse reply: $@");
  $self->_elog("Fault: $re->{code}; $re->{message}") if $st && 'Hessian::Type::Fault' eq ref $re;
  $self->_elog($re) if $st == 2;
  return $st,$re;
}

sub _elog { my $self=shift;$Error=join'',@_;print STDERR @_,"\n" if $self->{debug}; join '',@_ }
sub _read_reply {
  my($reader,$hessian_flag) = @_;
  my $buf = $reader->(3);
  my($or,$m,$obj);
  if($buf =~ /^(f|r\x01\x00)/){ # 1.0 reply
    $or = Hessian::Tiny::ConvertorV1::_make_object_reader($hessian_flag);
    eval{
      if($buf =~ /^f/){ # 2.0 compatible mode return fault directly
        $reader->(-3); # rewind
          $obj = $or->($reader,0);
          bless $obj,'Hessian::Type::Fault';
      }else{ # pure 1.0 reply
        do{$obj = $or->($reader)}
        while('Hessian::Type::Header' eq ref $obj); # discard headers
      }
      1;
    } or return 2, $@;
    return ('Hessian::Type::Fault' eq ref $obj ? 1 : 0), $obj;
  }elsif($buf =~ /^H\x02\x00/){ # 2.0 reply
    $m = $reader->(1);
    $or = Hessian::Tiny::ConvertorV2::_make_object_reader($hessian_flag);
    eval{
      if($m eq 'R'){
        $obj = $or->($reader);
      }elsif($m eq 'F'){
        $obj = $or->($reader,0);
        bless $obj,'Hessian::Type::Fault';
      }else{ # others not implemented
        die "response is neither H2 Reply nor H2 Fault: $m" unless $m =~ /^[RF]/;
      }
      1;
    } or return 2, $@;
    return ('Hessian::Type::Fault' eq ref $obj ? 1 : 0), $obj;
  }else{ # anomaly
    return 2,"_read_reply: unexpected beginning($buf)";
  }
}

=back

=head1 HESSIAN DATA TYPES

=head2 Null

    $foo->call('argNull', Hessian::Type::Null->new() );

As return value, by default, you will get undef;
when 'hessian_flag' is set to true, you will get Hessian::Type::Null.

=head2 True/False

    $foo->call('argTrue',  Hessian::Type::True->new() );
    $foo->call('argFalse', Hessian::Type::False->new() );

As return value, by default, you will get 1 (true) or undef (false);
when 'hessian_flag' is set to true, you will get Hessian::Type::True
or Hessian::Type::False as return value.

=head2 Integer

    $foo->call('argInt', 250 );

No extra typing for Integer type.
Note, if the number passed in falls outside the range of signed 32-bit integer,
it will be passed as a Long type parameter (64-bit) instead.

=head2 Long

    $foo->call('argLong', Math::BigInt->new(100000) ); # core module
    $foo->call('argLong', Hessian::Type::Long->new('100000') ); # same as above

As return value, by default, you will get string representation of the number;
when 'hessian_flag' is set to true, you will get Math::BigInt.

=head2 Double

    $foo->call('argDouble', -2.50 ); # pass directly, if looks like floating point number
    $foo->call('argDouble', Hessian::Type::Double(-2.50) ); # equivalent

As return value, by default, you will get the number directly;
when 'hessian_flag' is set to true, you will get Hessian::Type::Double.
Note, floating point numbers may appear slightly inaccurate, due to the binary nature of machines (not the fault of protocol itself, or Perl even).

=head2 Date

    $foo->call('argDate', Hessian::Type::Date->new($milli_sec) );
    $foo->call('argDate', DateTime->now() ); # if you have this module installed

As return value, by default, you will get epoch seconds;
when 'hessian_flag' is set to true, you will get Hessian::Type::Date (milli sec inside).

=head2 Binary/String

    $foo->call('argBinary', Hessian::Type::Binary->new("hello world\n") );
    $foo->call('argString', Hessian::Type::String->new("hello world\n") );
    $foo->call('argString', Unicode::String->new("hello world\n") );

As return value, by default, you will get the perl string;
when 'hessian_flag' is set to true, you will get Hessian::Type::Binary or
Hessian::Type::String object. (Binary means byte stream, while String is UTF-8)

=head2 XML

    $foo->call('argXML', Hessian::Type::XML->new( $xml_string ) );

As return value, by default, you will get xml string;
when 'hessian_flag' is set to true, you will get Hessian::Type::XML.
Note, XML type is removed from Hessian 2.0 spec.

=head2 List

    $foo->call('argList', [1,2,3] ); # untyped fixed length list
    $foo->call('argList', Hessian::Type::List->new([1,2,3]); # same as above
    $foo->call('argList', Hessian::Type::List->new(length=>3,data=>[1,2,3],type=>'Triplet');

As return value, by default, you will get array ref;
when 'hessian_flag' is set to true, you will get Hessian::Type::List.

=head2 Map

    $foo->call('argMap', {a=>1,b=>2,c=>3} ); # untyped map
    $foo->call('argMap', Hessian::Type::Map->new({a=>1,b=>2,c=>3} ); # same as above
    $foo->call('argMap', Hessian::Type::Map->new(type=>'HashTable',data=>{a=>1,b=>2,c=>3} ); # typed

As return value, by default, you will get hash ref (Tie::RefHash is used to allow non-string keys);
when 'hessian_flag' is set to true, you will get Hessian::Type::Map.

=head2 Object

    my $x = Hessian::Type::Object->new(
                type => 'my.package.LinkedList',
                data => {_value => 1, _rest => undef}
            );
    my $y = Hessian::Type::Object->new(
                type => 'my.package.LinkedList',
                data => {_value => 2, _rest => $x}
            );
    $foo->call('argObject',$y);

As return value, by default, you will get hash_ref (Tie::RefHash is used to allow non-string keys);
when 'hessian_flag' is set to true, you will get Hessian::Type::Object.
Note, Object is essentially a typed Map.

=head1 AUTHOR

Ling Du, C<< <ling.du at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hessian-tiny-client at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hessian-Tiny-Client>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 TODO

Hessian::Tiny::Server, not sure if anyone will need to use the server part, except for testing maybe.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hessian::Tiny::Client


For information on the wonderful protocol itself, take a look at:
	http://hessian.caucho.com/

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hessian-Tiny-Client>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hessian-Tiny-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hessian-Tiny-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/Hessian-Tiny-Client/>

=back


=head1 ACKNOWLEDGEMENTS

Algo LLC.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Ling Du.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Hessian::Tiny::Client
