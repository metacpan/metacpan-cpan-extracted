# Hey emacs, this is -*-perl-*- !
#
# $Id: HTTP.pm,v 1.1 2001/01/09 12:08:46 cmdjb Exp $
#
# Metadata::HTTP - HTTP request 'metadata' class
#
# Copyright (C) 1997-2001 Dave Beckett - http://purl.org/net/dajobe/
# All rights reserved.
#
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#

package Metadata::HTTP;

require 5.004;

use strict;
use vars qw(@ISA $VERSION $Debug %Default_Options %month_name_to_month_number);

use Carp;

use Metadata::Base;

@ISA     = qw( Metadata::Base );
$VERSION = sprintf("%d.%02d", ('$Revision: 1.1 $ ' =~ /\$Revision:\s+(\d+)\.(\d+)/));

%Default_Options=(
  SPLIT => '0',
  DEBUG => '0',
  RAW => '',
);

%month_name_to_month_number=qw(Jan 1 Feb 2 Mar 3 Apr 4 May 5 Jun 6 Jul 7 Aug 8 Sep 9 Oct 10 Nov 11 Dec 12);


# Class debugging
$Debug = 0;

sub debug { 
  my $self=shift;
  # Object debug - have an object reference
  if (ref ($self)) { 
    my $old=$self->{DEBUG};
    $self->{DEBUG}=@_ ? shift : 1;
    $self->SUPER::debug($self->{DEBUG});
    return $old;
  }

  # Class debug (self is debug level)
  return $Debug if !defined $self; # Careful, could be debug(0)

  my $old=$Debug;
  $Default_Options{DEBUG}=$Debug=$self;
  Metadata::Base::debug($Debug);
  $old;
}

sub whowasi { (caller(1))[3] }


# Constructor
sub new {
  my $proto =shift;
  my $class = ref($proto) || $proto;
  my $options= { @_ };
  $options->{ORDERED}=1;
  for (keys %Default_Options) {
    $options->{$_}=$Default_Options{$_} unless defined $options->{$_};
  }

  my $self = $class->SUPER::new($options);
  bless $self, $class;
  return $self;
}


sub read ($$) {
  my $self = shift;
  my $fh=shift;

  $self->clear;

  return undef if eof($fh);

  my $raw=<$fh>;
  chomp $raw;
  $self->{RAW}=$raw;

  # Handle Combined & Extended log files lines look like this
  #HOST IDENT AUTHUSER [01/Apr/1998:12:00:00 +0100] "GET / HTTP/1.0" STATUS BYTES "REFERER" "BROWSER"
  
  # Strip start of line to beginning of request (COMMON TO ALL)
  $raw =~ s/^(\S+) (\S+) (\S+) \[([^:]+):(\d\d:\d\d:\d\d) ([^]]+)\] "//;
  $self->set('host',lc $1) if $1 ne '-';
  $self->set('ident',$2) if $2 ne '-';
  $self->set('authuser',$3) if $3 ne '-';
  my $date=$4;
  $self->set('date',$date);
  my $time=$5;
  $self->set('time',$time);
  $self->set('timezone',$6);

  # Strip from end of line referer/agent stuff (OPTIONAL)
  if ($raw =~ s/ "([^"]+)" "([^"]+)"$//) {
    $self->set('referer',$1) if $1 ne '-';
    $self->set('agent',$2) if $2 ne '-';
  }  

  # Strip end from end of line
  $raw =~ s/" (-|\d+) (-|\d+)$//;
  $self->set('status',$1) if $1 ne '-';
  $self->set('bytes',$2) if $2 ne '-';

  # Request is rest - GET /path[ HTTP/..]
  $self->set('request',$raw);

  my($dom,$mname,$year)=split(m%/%, $date);
  my $month=$month_name_to_month_number{$mname} || '0';
  $self->set('day',$dom);
  $self->set('month',$month);
  $self->set('year',$year);
  my($hour,$min,$sec)=split(/:/,$time);
  $self->set('hour', $hour);
  $self->set('min', $min);
  $self->set('sec', $sec);

  # Split request into GET/POST/... /path/to/file (optional version)
  if ($raw =~ s%\s+http/([.\d+])$%%i) {
    $self->set('http-version', $1);
  }

  # Finally store the command & parameter if possible
  if ($raw =~ /^(\S+) (.*)$/) {
    $self->set('command', $1);
    $self->set('path', $2);
  }

  return 1;
}


sub format ($;$) {
  my $self=shift;
  return $self->{RAW}."\n";
}



1;
__END__

=head1 NAME

Metadata::HTTP - metadata class for HTTP log records

=head1 SYNOPSIS

  use Metadata::HTTP
  ...
  $i=new Metadata::HTTP;
  open(IN, $logfile);
  while($i->read('IN')) {
    print $i->get('agent'),"\n";
  }
  ...

=head1 DESCRIPTION

The Metadata::HTTP class allows the handling of HTTP log records as
metadata objects using the L<Metadata::Base> class.

The following fields are set after using the B<read> method:

  host ident authuser
  date day month year time hour min sec
  timezone (in format +/-NNNN)
  status bytes
  request - 'GET /foo' etc

Optionally set:
  referer (if supported by log)
  agent (if supported by log)
  http-version (if present)
  command - GET, POST, etc.
  path    - operand to command

=head1 CONSTRUCTOR

=over 4

=item new [OPTIONS]

An optional hash of options can be given to the constructor to set
various options.  There is only one I<Metadata::HTTP>
options defined:

=over 6

=item I<DEBUG>

This class has a separate I<debug> class / object method that works
in the same fashion as the I<Metadata::Base> method B<debug>.
Setting it here also sets the debugging on the base I<Metadata::Base>
object too.

=back

=head1 METHODS

The methods here describe the differences from the L<Metadata::Base> class
methods.

=over 4

=item read HANDLE

Reads a single line from the file descriptor and uses it to fill the
fields of the HTTP metadata object.

=item format [URL]

Returns the original HTTP line used in the parsing.

=back 4

=head1 SEE ALSO

L<Metadata::Base>

=head1 AUTHOR

By Dave Beckett - http://purl.org/net/dajobe/

=head1 COPYRIGHT

Copyright (C) 1997-2001 Dave Beckett - http://purl.org/net/dajobe/
All rights reserved.

=cut

