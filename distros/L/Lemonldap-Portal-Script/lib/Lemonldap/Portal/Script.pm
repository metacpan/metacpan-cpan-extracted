package Lemonldap::Portal::Script;

our $VERSION = '0.1';

{

    package  Lemonldap::Portal::Script::Exchange;

    sub new {
        my $class = shift;
        my %args  = @_;
        my $self;
        $self = \%args;
        $self->{line} = [];
        bless $self, $class;
        return $self;
    }

    sub set_method {
        my $self  = shift;
        my $_line = shift;
        if ( $_line =~ /^GET/ ) {
            $self->{method} = 'GET';
        }
        else {
            $self->{method} = 'POST';

        }
    }

    sub set_ResponseCode {
        my $self  = shift;
        my $_line = shift;
        ( $self->{responsecode} ) = $_line =~ /(\d\d\d)/;
    }

    sub set_tirade {
        my $self      = shift;
        my $_table    = shift;
        my $_question = shift;
        $self->{$_table} = $_question;
    }

    sub set_status {
        my $self   = shift;
        my $_value = shift;
        $self->{require} = $_value;
    }

    sub add_string {
        my $self   = shift;
        my $_value = shift;
        push @{ $self->{line} }, $_value;
    }

    sub as_string {
        my $self = shift;
        my $a .= $self->{requete} . "\n";
        for ( @{ $self->{line} } ) {
            $a .= $_ . "\n";
        }
        return $a;
    }

    1;

    package Lemonldap::Portal::Script::Response;

    sub new {
        my $class = shift;
        my %args  = @_;
        my $self;
        $self                  = \%args;
        $self->{headers}       = [];
        $self->{headers_test}  = [];
        $self->{headers_model} = [];
        bless $self, $class;
        return $self;
    }

    sub add_header {
        my $self  = shift;
        my $_line = shift;
        my %STORE = ( 'content-type' => 1, );

        my %TEST_STORE = (
            'location'   => "%LOCATION%",
            'set-cookie' => "%SETCOOKIE%",
        );
        ( my $_header, my $_value ) = $_line =~ /(^.+?):\s(.+)/;

        $_value =~ s/^ +//;
        if ( $TEST_STORE{ lc($_header) } ) {
            push @{ $self->{headers_test} }, $_header . "#" . $_value;
            push @{ $self->{headers_model} },
              $_header . "#" . $TEST_STORE{ lc($_header) };
        }
        if ( $STORE{ lc($_header) } ) {
            push @{ $self->{headers} }, $_header . "#" . $_value;
        }

    }

    1;

    package Lemonldap::Portal::Script::Question;

    sub new {
        my $class = shift;
        my %args  = @_;
        my $self;
        $self                  = \%args;
        $self->{headers}       = [];
        $self->{headers_test}  = [];
        $self->{headers_model} = [];
        bless $self, $class;
        return $self;
    }

    sub add_header {
        my $self     = shift;
        my $_line    = shift;
        my %NO_STORE = (
            'accept-encoding' => 1,
            'keep-alive'      => 1,
            'connection'      => 1,
            'host'            => 1,
        );
        my %TEST_STORE = (
            'user-agent' => "%AGENT%",
            'cookie'     => "%COOKIE%",
        );
        ( my $_header, my $_value ) = $_line =~ /(^.+?):\s(.+)/;
        if ( !$_header ) {    ## it is value
            push @{ $self->{DATA} }, $_line;
            return;
        }

        return if $NO_STORE{ lc($_header) };
        $_value =~ s/^ +//;
        if ( $TEST_STORE{ lc($_header) } ) {
            push @{ $self->{headers_test} }, $_header . "#" . $_value;
            push @{ $self->{headers_model} },
              $_header . "#" . $TEST_STORE{ lc($_header) };
        }
        else {
            push @{ $self->{headers} }, $_header . "#" . $_value;
        }
    }

    1;

}
1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lemonldap::Portal::Script - Perl extension for Lemonldap websso framework

=head1 SYNOPSIS

  use Lemonldap::Portal::Script
  $exchange = Lemonldap::Portal::Script::Exchange->new( numero => $cp, requete => $line );
  $question = Lemonldap::Portal::Script::Question->new();
  $response = Lemonldap::Portal::Script::Response->new();

=head1 DESCRIPTION

This module implementes 3 objects class : Exchange, Question ,Response 

An Exchange is composed of one question and one response.

The parsing_example.pl shows how it works. 

=over

=item First use firefox plugin in order to have client-server dialog in plain text file. 
 I use  The LiveHTTPHeaders  for Firefox in order to recording  connection on web site.

=cut

=item Second ,the text dialog  file is parsed by te program. It may split exchange in two groups. 
 One for true exchange (authentication form) second for useless  exchange : jpeg, css .

=cut


The complet_parsing_example.pl extends the previous example , with the generation of perl program able to connect at web site. You can use LWP and Template modules for this.

This example generates 3 things :


=over

=item filtered dialog

=item apache virtual configuration  file

=item perl script or handler processing connection on web server

=back

=cut

=head2 Methods 

 $line means a line of dialog file recording.

=over

=item Exchange->new( numero => $cp, requete => $line );

=item Exchange->set_tirade('response',$response);

=item Exchange->set_tirade('question',$question);

=item Exchange->add_string("--------Fin echange $echange->{numero}");

=item Exchange->set_method($line);# GET /POST 

=item Exchange->set_ResponseCode($line);# 200, 302 ..

=item Exchange->as_string;

=item Exchange->set_status (required , y/n  ) 

=back

=cut 

With Question / Response


$question = Lemonldap::Portal::Script::Question->new();
$response = Lemonldap::Portal::Script::Response->new();

        $self->{headers}       = [];
        $self->{headers_test}  = []; # force header to get a value 
        $self->{headers_model} = []; # use partern 

   add_header { # this method  add  headers  exept if their are present in NO_STORE hash.
                # Headers in TEST_STORE are replaced by the patern after subtitution 
        my $self     = shift;
        my $_line    = shift;
        my %NO_STORE = (
            'accept-encoding' => 1,
            'keep-alive'      => 1,
            'connection'      => 1,
            'host'            => 1,
        );
        my %TEST_STORE = (
            'user-agent' => "%AGENT%",
            'cookie'     => "%COOKIE%",
        );

=cut

=head1 EXPORT

None 







=head1 SEE ALSO

Lemonldap(3), Lemonldap::Portal::Standard

http://lemonasso.org/


=over 1

=item Eric German, E<lt>germanlinux@yahoo.frE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Eric German 

Lemonldap originaly written by Eric german who decided to publish him in 2003
under the terms of the GNU General Public License version 2.

=over 1

=item This package is under the GNU General Public License, Version 2.

=item The primary copyright holder is Eric German.

=item Portions are copyrighted under the same license as Perl itself.

=item Portions are copyrighted by Doug MacEachern and Lincoln Stein.
This library is under the GNU General Public License, Version 2.


=back

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; version 2 dated June, 1991.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  A copy of the GNU General Public License is available in the source tree;
  if not, write to the Free Software Foundation, Inc.,
  59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut
