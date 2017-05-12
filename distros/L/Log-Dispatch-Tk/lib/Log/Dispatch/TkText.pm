package Log::Dispatch::TkText;

use strict;
use vars qw($VERSION);

use Tk;
use Tk::ROText ;
use Log::Dispatch::ToTk;
use base qw(Tk::Derived Tk::ROText);

$VERSION = '1.8';

Tk::Widget->Construct('LogText');

sub InitObject
  {
    my ($dw,$args) = @_ ;

    my %params ;
    foreach my $key (qw/name min_level max_level hide_label/)
      {
        $params{$key} = delete $args->{$key} if defined $args->{$key} ;
        $params{$key} = delete $args->{'-'.$key} if defined $args->{'-'.$key} ;
      }

    # 
    $dw->{logger} = Log::Dispatch::ToTk->new(%params, -widget => $dw) ;

    $dw->tagConfigure('label', 
                      -underline => 1,
                      -spacing1 => 3 , 
#                      -spacing3 => 3 ,
#                      -justify => 'center',
#                      -relief => 'raised' ,
#                      -borderwidth => 1
                     ) ;
    $dw->tagConfigure('message',
                      -spacing3 => 3 ,
                      -lmargin1 => 20 ,
                      -lmargin2 => 20
                     ) ;

    $dw->SUPER::InitObject($args) ;

  }

sub logger
  {
    my $dw = shift;
    return $dw->{logger} ;
  }

# Check "The perl/Tk widget extended mdethods" section in 
# "mastering Perl/Tk" for (some) explanations on Text menus

sub MenuLabels
  {
    my $dw = shift;
    return (qw[Fil~ter],$dw->SUPER::MenuLabels() ) ;
  }

sub FilterMenuItems
  {
     my ($dw) = @_;

     my @buttons ;

     #print "Tags are ",$dw->tagNames,"\n";

     foreach my $level ($dw->{logger}->accepted_levels())
       {
         # find if the tag exists or not
         my @ranges = $dw->tagRanges($level);
         my $value = scalar @ranges ? $dw->tagCget($level => '-elide') : 0;

         #print "Adding level $level in menu\n";
         my $cb = sub 
           {
             #print "value $level is $value\n";
             $dw->tagConfigure($level, -elide => $value) ;
           };

         push @buttons,  
         [
          checkbutton => $level eq 'err' ? 'e~rr' : '~'.$level, 
          -variable => \$value,
          -onvalue =>  0, # want button set when level is not hidden
          -offvalue => 1, # hence the inversion
          -command => $cb
         ] ;
       } ;

     return \@buttons ;
   }

sub log {
    my ($dw,%params) = @_;

    if (not $params{hide_label}) {
        $dw->insert('end',"$params{level}\n", [$params{level}, 'label' ]);
    }
    $dw->insert('end',"$params{message}\n", [$params{level}, 'message' ]);
}

__END__

=head1 NAME

Log::Dispatch::TkText - Text widget for Log::Dispatch 

=head1 SYNOPSIS

 use Tk ;
 use Log::Dispatch;
 use Log::Dispatch::TkText ;

 my $dispatch = Log::Dispatch->new;

 my $mw = MainWindow-> new ;

 my $tklog = $mw->Scrolled(
   'LogText',
   name => 'tk',
   min_level => 'debug',
   hide_label => 1 , # optional
 );

 $tklog -> pack ;

 # add the logger object to $dispatch (not the widget !!)
 $dispatch->add($tklog->logger) ;

 $dispatch -> log 
  (
   level => 'info',
   message => "Quaquacomekiki ? (so says Averell Dalton)"
  ) ;


=head1 DESCRIPTION

This widget provide a read-only text widget (based on
L<Tk::ROText>) for logging through the L<Log::Dispatch> module.

Note that this widget works with a buddy L<Log::Dispatch::ToTk> object
which will be created by the widget's constructor.  The reference to
this buddy object must be added to the main log dispatcher.

=head1 Parameters

=head2 hide_label

By default, log levels are shown in the widget. You can set this
parameter to one to hide them.

=head1 Filters

By clicking on <button-3> within the text widget, you get access to a
filter menu which can hide specific levels of logging.

For instance if you text widget is cluttered with 'info' message and
you are looking for only 'error' messages, you can hide all 'info'
messages by disabling the 'info' level in the Filter menu so only the
'error' messages will be left on the screen.

Note that the filter hides the text. They can be displaying again if
you switch back the 'info' level in the Filter menu.

=head1 METHODS

The following methods were added to the L<Tk::ROText> widget:

=head2 logger()

Returns the buddy ToTk object.

=head2 log_message( level => $, message => $ )

Sends a message if the level is greater than or equal to the object's
minimum level.

=head1 AUTHOR

Dominique Dumont <ddumont@cpan.org> using L<Log::Dispatch> from
Dave Rolsky, <autarch@urth.org>

Copyright (c) 2000-2004, 2017 Dominique Dumont
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 CONTRIBUTORS

 Tom McMeekin

=head1 SEE ALSO

L<Log::Dispatch>, L<Log::Dispatch::Email>, L<Log::Dispatch::Email::MailSend>,
L<Log::Dispatch::Email::MailSendmail>, L<Log::Dispatch::Email::MIMELite>,
L<Log::Dispatch::File>, L<Log::Dispatch::Handle>, L<Log::Dispatch::Screen>,
L<Log::Dispatch::Syslog>, L<Log::Dispatch::ToTk>

=cut
