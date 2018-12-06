package Log::Dispatch::ToTk;

use warnings;
use strict;

use base qw(Log::Dispatch::Output);
use fields qw/widget/ ;

our $VERSION = '2.01';

sub new
  {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my %params = @_;

    my $self = bless {} , $class;

    $self->{hide_label} = delete $params{-hide_label} || delete $params{hide_label} || 0;

    $self->{widget} = delete $params{-widget} || delete $params{widget} ;

    # remove leading '-' (Tk style)
    map { my $k = $_ ; s/^-//; $params{$_} = delete $params{$k} }
      grep /^-/,keys %params ;

    $self->_basic_init(%params);
    return $self ;
  }

sub log_message
  {
    my $self = shift;
    my %params = @_;

    map {my $k = $_ ; s/^-//; $params{$_} = delete $params{$k}}
      grep /^-/,keys %params ;

    return unless $self->_should_log($self->_level_as_number($params{level}));
    
    chomp $params{message};
    my $nb = $self->_level_as_number($params{level}) ;
    $params{level} = $self->{level_names}[$nb] ;
    $params{hide_label} = $self->{hide_label} ;
    $self->{widget}->log(%params);
}

sub all_levels
  {
    my $self = shift;
    #print "From level $self->{min_level} to $self->{max_level}\n";
   
    return @{$self->{level_names}}[$self->{min_level} .. $self->{max_level}] ;
  }


__END__

=head1 NAME

Log::Dispatch::ToTk - Class to redirect Log::Dispatch to Tk widgets

=head1 SYNOPSIS

 # Log::Dispatch::ToTk must be used in a composite widget

 Tk::Widget->Construct('LogText');

 sub InitObject
  {
    my ($dw,$args) = @_ ;
    
    # retrieve parameters specific to Log::Dispatch::*
    my %params ;
    foreach my $key (qw/name min_level max_level/)
      {
        $params{$key} = delete $args->{$key} 
           if defined $args->{$key};
      } 
    
    # create the TkTk buddy class
    $dw->{logger} = Log::Dispatch::ToTk->
      new(%params, widget => $dw) ;

    # initiaze the widget
    $dw->SUPER::InitObject($args) ;
  }

 # mandatory method in Tk widget using Log::Dispatch::ToTk
 sub logger
  {
    my $dw = shift;
    return $dw->{logger} ;
  }


__END__

=head1 DESCRIPTION

Most users will only need to use L<Log::Dispatch::TkText> widget to
have Log::Dispatch messages written on a text widget. 

For more fancy uses, this module can be used by a composite widget
dedicated to handle Log::Dispatch logs.

This module is the interface class between L<Log::Dispatch> and Tk
widgets.  This class is derived from L<Log::Dispatch::Output>.

One ToTk object will be created for each Log::Dispatch::Tk* widget and
the user must register the ToTk object to the log dispatcher.


=head1 METHODS

=head2 new(...)

Create a new ToTk object. Parameter are :

=over 4

=item * widget ($)

The buddy widget object

=item * name ($)

The name of the object (not the filename!).  Required.

=item * min_level ($)

The minimum logging level this object will accept.  See the
Log::Dispatch documentation for more information.  Required.

=item * max_level ($)

The maximum logging level this obejct will accept.  See the
Log::Dispatch documentation for more information.  This is not
required.  By default the maximum is the highest possible level (which
means functionally that the object has no maximum).

=back

=head2 log_message( level => $, message => $ )

Sends a message if the level is greater than or equal to the object's
minimum level.

=head1 AUTHOR

Dominique Dumont <ddumont@cpan.org> using L<Log::Dispatch> and
L<Log::Dispatch::Output> from Dave Rolsky, autarch@urth.org

Copyright (c) 2000, 2003, 2017 Dominique Dumont
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Log::Dispatch>, L<Log::Dispatch::Email>, L<Log::Dispatch::Email::MailSend>,
L<Log::Dispatch::Email::MailSendmail>, L<Log::Dispatch::Email::MIMELite>,
L<Log::Dispatch::File>, L<Log::Dispatch::Handle>, L<Log::Dispatch::Screen>,
L<Log::Dispatch::Syslog>, L<Log::Dispatch::TkText>

=cut
